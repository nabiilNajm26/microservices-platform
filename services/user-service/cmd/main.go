package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/nabiilNajm26/microservices-platform/services/user-service/internal/handler"
	"github.com/nabiilNajm26/microservices-platform/services/user-service/internal/repository"
	"github.com/nabiilNajm26/microservices-platform/services/user-service/internal/service"
	pb "github.com/nabiilNajm26/microservices-platform/proto/user"
	"github.com/nabiilNajm26/microservices-platform/pkg/database"
)

func main() {
	// Configuration from environment
	httpPort := getEnv("HTTP_PORT", "8080")
	grpcPort := getEnv("GRPC_PORT", "9090")
	dbURL := getEnv("DATABASE_URL", "postgresql://userservice:userservice_dev_pass@localhost:5432/userdb?sslmode=disable")
	jwtSecret := getEnv("JWT_SECRET", "dev-jwt-secret-key-change-in-production")

	// Database connection
	db, err := database.NewPostgresConnection(dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Repository layer
	userRepo := repository.NewUserRepository(db)

	// Service layer
	userService := service.NewUserService(userRepo, jwtSecret)

	// gRPC server
	grpcServer := grpc.NewServer()
	userHandler := handler.NewUserHandler(userService)
	pb.RegisterUserServiceServer(grpcServer, userHandler)
	
	// Enable reflection for development (grpcurl, Evans)
	reflection.Register(grpcServer)

	// Start gRPC server
	go func() {
		lis, err := net.Listen("tcp", ":"+grpcPort)
		if err != nil {
			log.Fatalf("Failed to listen on gRPC port %s: %v", grpcPort, err)
		}
		log.Printf("gRPC server listening on :%s", grpcPort)
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("Failed to serve gRPC: %v", err)
		}
	}()

	// HTTP server for health checks
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	httpServer := &http.Server{
		Addr:    ":" + httpPort,
		Handler: http.DefaultServeMux,
	}

	// Start HTTP server
	go func() {
		log.Printf("HTTP server listening on :%s", httpPort)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to serve HTTP: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down servers...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	grpcServer.GracefulStop()
	httpServer.Shutdown(ctx)
	log.Println("Servers stopped")
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
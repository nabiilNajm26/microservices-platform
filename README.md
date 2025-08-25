# Microservices E-Commerce Platform

A cloud-native microservices platform built with Go, demonstrating modern distributed system patterns. This project simulates an e-commerce backend with full observability, monitoring, and Kubernetes deployment.

## What I Built

This is my take on building a production-grade microservices architecture. Instead of just another CRUD API, I wanted to showcase real-world distributed system patterns that you'd see at scale.

**Core Services:**
- **User Service** - Authentication, user management, JWT tokens
- **Product Service** - Product catalog, inventory management, search
- **Order Service** - Shopping cart, order processing, payment simulation
- **API Gateway** - Request routing, rate limiting, authentication middleware

**Tech Stack:**
- **Go 1.23** - High-performance backend services
- **gRPC** - Inter-service communication with Protocol Buffers
- **PostgreSQL** - Database per service pattern
- **Docker + Kubernetes** - Container orchestration
- **Prometheus + Grafana** - Metrics and monitoring
- **Jaeger** - Distributed tracing
- **JWT Authentication** - Stateless auth with RSA256

## Architecture

```
External Client
       ↓
   API Gateway (Go)
   ├── JWT Validation
   ├── Rate Limiting  
   └── Request Routing
       ↓ gRPC
┌──────────────────────┐
│   Service Mesh       │
├─ User Service        │
├─ Product Service     │  
└─ Order Service       │
└──────────────────────┘
       ↓
   PostgreSQL per service
```

## Quick Start

### Prerequisites
- Go 1.23+
- Docker & Docker Compose
- kubectl (for Kubernetes deployment)

### Local Development

1. **Start Infrastructure**
   ```bash
   make dev-infra          # Start databases + monitoring
   ```

2. **Run Services** (in separate terminals)
   ```bash
   make run-user          # User service on :8080
   make run-product       # Product service on :8081  
   make run-order         # Order service on :8082
   make run-gateway       # API Gateway on :8000
   ```

3. **Test the API**
   ```bash
   # Health check
   curl http://localhost:8000/health
   
   # Register user
   curl -X POST http://localhost:8000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}'
   ```

### Production Deployment

I've set this up to run on Kubernetes with full monitoring stack:

```bash
# Build and push images
make build-images

# Deploy to k8s cluster
kubectl apply -f k8s/

# Access monitoring
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

## Key Features

### Production Patterns
- **Circuit Breaker Pattern** - Graceful failure handling between services
- **Distributed Tracing** - Request correlation across service boundaries
- **Metrics Collection** - Custom application metrics with Prometheus
- **Health Checks** - Kubernetes liveness and readiness probes
- **Rate Limiting** - DDoS protection and API abuse prevention

### Security
- **JWT Authentication** with RSA256 signing
- **Input Validation** and sanitization
- **Database Connection Pooling** with proper limits
- **CORS Configuration** for web clients

### Observability
- **Structured Logging** with request correlation IDs
- **Custom Metrics** for business and technical KPIs
- **Distributed Tracing** with Jaeger integration
- **Grafana Dashboards** for system monitoring

## API Examples

### Authentication
```bash
# Register
POST /api/v1/auth/register
{
  "email": "user@example.com",
  "password": "secure123",
  "first_name": "John",
  "last_name": "Doe"
}

# Login  
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "secure123"
}
```

### Shopping Flow
```bash
# Browse products
GET /api/v1/products?page=1&limit=20

# Add to cart (requires auth)
POST /api/v1/cart/items
Authorization: Bearer <token>
{
  "product_id": "uuid-here",
  "quantity": 2
}

# Create order
POST /api/v1/orders
Authorization: Bearer <token>
{
  "payment_method": "credit_card"
}
```

## Development

### Project Structure
```
├── services/           # Microservices
│   ├── user-service/
│   ├── product-service/
│   ├── order-service/
│   └── api-gateway/
├── proto/             # gRPC definitions
├── k8s/               # Kubernetes manifests
├── pkg/               # Shared packages
└── scripts/           # Build and deployment scripts
```

### Make Commands
```bash
make dev              # Start full dev environment
make proto            # Generate protobuf code
make test             # Run all tests
make lint             # Code linting
make build            # Build all services
```

## Monitoring

When running locally, monitoring services are available at:
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686

## What's Next

This project demonstrates the fundamentals of building scalable microservices. Some areas I'm considering for future iterations:

- Event-driven architecture with NATS/Kafka
- Service mesh with Istio
- Advanced deployment strategies (blue/green, canary)
- More sophisticated caching layers

## Contributing

This is a personal portfolio project, but I'm open to feedback and suggestions. Feel free to open issues or reach out if you have questions about the implementation.

---
# ECommerceSystem (ASP.NET Core Microservices)

**Quick Open:** Double‑click `ECommerceSystem.sln` in the repo root to open all projects in Visual Studio.

This repository contains a simplified microservices system that follows your assignment and mirrors your teacher's sample structure at a lightweight level.

## Projects
- **ProductService**: CRUD for products (Id, Name, Price, Quantity). Stores `CreatedByUserId`. Calls `UserService` to fetch creator info with HttpClientFactory + Polly.
- **UserService**: CRUD for users (Id, Name, Email) + a simple **/auth/token** endpoint that issues JWTs to test auth.
- **ApiGateway**: Ocelot routes to both services. Gateway validates JWT too.
- **Shared.Contracts**: DTOs shared between services.

## Tech
- .NET 8, ASP.NET Core Web API
- EF Core (SQL Server)
- JWT Bearer Authentication
- Ocelot API Gateway
- HttpClientFactory + Polly retry
- Swagger
- Docker Compose

---

## Quick Start (Local without Docker)

> Requires: .NET 8 SDK, SQL Server (localdb or SQL Server). By default, we use SQL Server in Docker via `docker-compose`.  
> For local dev without Docker, edit the connection strings in each service's `appsettings.Development.json` to point to your SQL Server.

1. Open the **ECommerceSystem** folder in Visual Studio (or `code .` with VS Code).
2. Restore packages (`dotnet restore`) once.
3. Create migrations (first time only):
   ```bash
   cd ProductService
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   cd ../UserService
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   ```
4. Run **UserService** and **ProductService** (F5). Swagger will be available on `/swagger`.

5. Get a token:
   - POST `UserService` → `/auth/token`
   - Body JSON (any non-empty name/email accepted for demo):
     ```json
     { "name": "Minh", "email": "minh@example.com" }
     ```
   - Copy the returned `access_token`.

6. Use token on both APIs via Swagger `Authorize` (Bearer).

7. Test Product → User call:
   - Create a user at `POST /users` (UserService) → returns `id`.
   - Create a product at `POST /products` with `createdByUserId`: that user's `id`.
   - GET `/products/{id}` will include `createdBy` info (fetched from `UserService` with retries).

---

## Quick Start (with Docker + Docker Compose)

> This spins up:
> - `sqlserver` (mcr.microsoft.com/mssql/server:2022-latest)
> - `userservice` (port 5002)
> - `productservice` (port 5001)
> - `apigateway` (port 5000)

1. Install Docker Desktop and enable Linux containers.
2. From the repo root:
   ```bash
   docker compose up --build
   ```
3. Wait until services are `Healthy`. Databases auto-migrate on start (if migrations exist) and seed sample data.
4. Visit:
   - Gateway Swagger: http://localhost:5000/swagger
   - ProductService Swagger: http://localhost:5001/swagger
   - UserService Swagger: http://localhost:5002/swagger

5. Get a token at `UserService → POST /auth/token` and use it at the Gateway.

---

## Notes
- For simplicity, migrations are **not** pre-generated in this zip. Create them once as shown above (or generate at design-time in VS). The services call `Database.Migrate()` on startup, so subsequent runs will apply migrations automatically.
- The JWT secret is in `appsettings.json` of each project. For production, move to environment variables.
- Connection strings are set to the Docker SQL Server by default. For local dev, use `(localdb)\MSSQLLocalDB` or your instance.

Happy coding!

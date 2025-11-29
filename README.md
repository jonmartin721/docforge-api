# DocForge

Stop fighting with PDF libraries. Write HTML templates, get PDFs back.

DocForge is a .NET 8 API + React frontend for generating PDFs from templates. You write HTML with Handlebars variables, POST your JSON data, get a PDF. That's it.

Good for invoices, reports, certificates - anything where the layout stays the same but the data changes.

## Architecture

DocForge follows a clean architecture pattern with **4 projects**:

```
DocForge/
├── DocumentGenerator.API/          # Web API layer (Controllers, endpoints)
├── DocumentGenerator.Core/         # Business logic (Entities, DTOs, Validators)
├── DocumentGenerator.Infrastructure/ # Data access & services (EF Core, PDF generation)
└── DocumentGenerator.Tests/        # Unit and integration tests
└── DocumentGenerator.Client/       # React frontend (separate folder)
```

- **API**: Web controllers, authentication, Swagger documentation
- **Core**: Domain models, business rules, validation logic
- **Infrastructure**: Entity Framework, PuppeteerSharp PDF generation, external services
- **Tests**: xUnit tests with in-memory database for integration testing

## When to use DocForge

✅ You need PDFs with consistent layouts (invoices, certificates, reports)
✅ You want to write templates in HTML instead of fighting PDF libraries
✅ You need a visual editor for non-developers

❌ You need pixel-perfect print layouts (use LaTeX)
❌ You're generating simple text-only PDFs (use a simpler library)

## The Concept

```html
<!-- 1. Write a template -->
<h1>Invoice #{{invoiceNumber}}</h1>
<p>Total: ${{total}}</p>
```

```json
// 2. Send JSON data
{
  "invoiceNumber": "12345",
  "total": "250.00"
}
```

```bash
# 3. Call the API
curl -X POST http://localhost:5257/api/documents/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "templateId": "your-template-id",
    "data": {
      "invoiceNumber": "12345",
      "total": "250.00"
    }
  }'
```

**Result:** A formatted PDF invoice in the response.

## What it looks like

(Need to grab a screenshot of the visual editor here - drag/drop in action)

## Super Quick Start (TUI)

We have a text-based user interface to help you manage everything.

```bash
# Linux / macOS / WSL
# First time only: make scripts executable
chmod +x docforge.sh scripts/setup-linux.sh

# Run the TUI
./docforge.sh

# Windows (PowerShell)
.\docforge.ps1
```

### TUI Menu Options

The TUI provides an interactive menu with the following options:

**🔧 Setup & Dependencies**
- Install .NET 8 SDK
- Install Node.js and npm
- Install Chrome/Chromium for PDF generation (Linux/WSL)
- Setup development environment

**🚀 Development**
- Start Backend API (.NET)
- Start Frontend (React/Vite)
- Start Both Services (recommended)
- Stop All Services

**🧪 Testing**
- Run Backend Tests
- Run Frontend Tests
- Run All Tests with Coverage
- Test Report Generation

**📦 Database**
- Initialize Database
- Reset Database (development only)
- View Database Status
- Migrate Database (production)

**🐳 Docker**
- Build Docker Image
- Run with Docker Compose
- Stop Docker Services
- Clean Docker Resources

**📊 Project Management**
- View Project Status
- Check Dependencies
- Clean Build Artifacts
- Generate Documentation

**❓ Help & Info**
- Show Port Information
- Display API Endpoints
- View Configuration Guide
- About DocForge

### Platform-Specific Setup

**Linux / WSL Requirements:**
```bash
# Run this once to install PDF generation dependencies
sudo ./scripts/setup-linux.sh
```
This installs Chrome/Chromium and required libraries for PuppeteerSharp.

**Windows Requirements:**
- PowerShell 5.1+
- Windows 10/11 with Microsoft Edge (Chrome-based)
- No additional setup required for PDF generation

**macOS Requirements:**
- macOS 10.15+ with Safari 13+
- Google Chrome recommended for PDF generation
- Homebrew for dependency management

## Quick Start (Manual)

(Requires Docker OR .NET 8 SDK + Node.js 18+)

**With Docker** (runs API only):
```bash
git clone https://github.com/jonmartin721/docforge-api.git
cd docforge-api
docker-compose up -d

# Then start the frontend separately
cd DocumentGenerator.Client
npm install
npm run dev
```

Then open:
- **Frontend**: http://localhost:5173
- **API**: http://localhost:5000/swagger (Docker exposes API on port 5000)

### Docker Configuration Details

**Container Setup:**
- **Image**: `documentgenerator-api` (built from source)
- **Port Mapping**: `5000:8080` (external:internal)
- **Environment**: Development mode
- **Database**: SQLite with persistent storage

**Volume Mounts:**
```yaml
volumes:
  - ./data:/app/data              # Database persistence
  - ./GeneratedDocuments:/app/GeneratedDocuments  # PDF output
```

**Chrome Dependencies:**
The Dockerfile includes PuppeteerSharp Chrome dependencies:
```dockerfile
# Install Chrome dependencies for PuppeteerSharp
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
```

**Environment Variables in Docker:**
The container uses the same `.env` file configuration. Create a `.env` file before running:
```bash
cp .env.example .env
# Edit .env with your configuration
```

**Data Persistence:**
- **Database**: Stored in `./data/documentgenerator.db`
- **Generated PDFs**: Stored in `./GeneratedDocuments/`
- Both directories are automatically created if they don't exist

**Production Docker Usage:**
```bash
# For production, build and run with production settings
docker-compose -f docker-compose.prod.yml up -d
```

### Linux / WSL Setup
If running locally on Linux or WSL, you need to install dependencies for the PDF generator (Chrome/Puppeteer).

Run the setup script:
```bash
sudo ./scripts/setup-linux.sh
```

**Local development** (without Docker):
```bash
# Backend (runs on port 5257)
dotnet run --project DocumentGenerator.API

# Frontend (separate terminal)
cd DocumentGenerator.Client
npm install
npm run dev
```

Then open:
- **Frontend**: http://localhost:5173
- **API**: http://localhost:5257/swagger (local dev runs on port 5257)

**Port Reference:**
- **Local API**: `localhost:5257` (development)
- **Docker API**: `localhost:5000` (container)
- **Frontend**: `localhost:5173` (Vite dev server)

## Features

- **No PDF library wrestling** - Just write HTML/CSS like you already know
- **Visual editor included** - Build templates with drag-and-drop, see changes instantly
- **Works offline** - No external API calls, runs entirely on your infrastructure
- **Handles the hard parts** - Chrome rendering, proper fonts, page breaks that don't suck
- **Multi-user ready** - JWT auth built in, not bolted on later
- **Docker support** - API runs in container, frontend runs locally (Vite)



## Template Syntax

Templates use Handlebars. If you've used Mustache, it's basically that.

**Variables**:
```html
<!-- Your template -->
<h1>Invoice #{{invoiceNumber}}</h1>
<p>Customer: {{customerName}}</p>
```

```json
// Your data
{
  "invoiceNumber": "INV-2024-001",
  "customerName": "Acme Corp"
}
```

**Result in PDF:**
```
Invoice #INV-2024-001
Customer: Acme Corp
```

**Loops**:
```html
<ul>
{{#each items}}
  <li>{{name}}: ${{price}}</li>
{{/each}}
</ul>
```

**Conditionals**:
```html
{{#if isPaid}}
  <span class="paid">✓ Paid</span>
{{else}}
  <span class="unpaid">Pending</span>
{{/if}}
```

Test your templates in the frontend editor first - it catches syntax errors before you hit the API.

## Tech Stack

**Backend:**
- .NET 8 Web API with clean architecture
- Entity Framework Core 8.0.0 (SQLite for dev, PostgreSQL/SQL Server ready)
- PuppeteerSharp (headless Chrome for PDF generation)
- Handlebars.NET (templating engine)
- FluentValidation (input validation)
- AutoMapper (object mapping)
- Serilog (structured logging)
- BCrypt.Net-Next (password hashing)
- JWT authentication with refresh tokens
- xUnit + FluentAssertions + Moq for testing

**Frontend:**
- React 19.2.0 with Vite 7.2.2
- React Router DOM 7.9.6 for navigation
- Axios for API calls with JWT interceptors
- @dnd-kit 6.3.1 for drag-and-drop template editor
- Lucide React for icons
- Vitest 4.0.14 + Testing Library for testing
- Vanilla CSS with Google Fonts (Inter)

## API Endpoints

### Authentication (`/api/auth`)
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

Both endpoints return `AuthResponseDto` with JWT and refresh tokens.

### Documents (`/api/documents`) - **Authentication Required**
```http
POST /api/documents/generate
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "templateId": "template-guid",
  "data": {
    "invoiceNumber": "INV-2024-001",
    "customerName": "Acme Corp",
    "total": "250.00"
  }
}
```

```http
GET /api/documents
Authorization: Bearer {jwt_token}
```

```http
GET /api/documents/{id}
Authorization: Bearer {jwt_token}
```

```http
GET /api/documents/{id}/download
Authorization: Bearer {jwt_token}
```

```http
DELETE /api/documents/{id}
Authorization: Bearer {jwt_token}
```

### Templates (`/api/templates`) - **Authentication Required**
```http
GET /api/templates
Authorization: Bearer {jwt_token}
```

```http
GET /api/templates/{id}
Authorization: Bearer {jwt_token}
```

```http
POST /api/templates
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "Invoice Template",
  "description": "Standard invoice layout",
  "htmlContent": "<h1>Invoice #{{invoiceNumber}}</h1>",
  "styles": "h1 { color: blue; }"
}
```

```http
PUT /api/templates/{id}
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "Updated Invoice Template",
  "description": "Updated description",
  "htmlContent": "<h1>Invoice #{{invoiceNumber}}</h1>",
  "styles": "h1 { color: green; }"
}
```

```http
DELETE /api/templates/{id}
Authorization: Bearer {jwt_token}
```

**Interactive Documentation**: Available at `/swagger` when running the application.

## Environment Configuration

Copy `.env.example` to `.env` and configure the following variables:

### Database
```bash
DATABASE_CONNECTION_STRING=Data Source=documentgenerator.db
```
- Default: SQLite database file in project root
- Can be changed to PostgreSQL or SQL Server connection strings

### JWT Authentication
```bash
JWT_SECRET=your-super-secret-key-minimum-32-characters
JWT_ISSUER=DocForge
JWT_AUDIENCE=DocForge
JWT_EXPIRATION_MINUTES=60
REFRESH_TOKEN_EXPIRATION_DAYS=7
```

### CORS Configuration
```bash
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

### Environment
```bash
ASPNETCORE_ENVIRONMENT=Development
```

**Production Considerations:**
- Use a strong JWT_SECRET (minimum 32 characters)
- Configure secure database connection strings
- Set appropriate CORS origins for your domain
- Use `ASPNETCORE_ENVIRONMENT=Production` for production deployments

## Learn More

- 📖 **API Documentation** - Available at `/swagger` when running the application
- 🎨 **Template Examples** - Check `DocumentGenerator.Client` for sample templates
- 🏗️ **Architecture** - .NET 8 API + React frontend, uses PuppeteerSharp for PDF rendering

## Testing

### Backend Testing (.NET)

Run all backend tests:
```bash
dotnet test
```

Run tests with coverage:
```bash
dotnet test --collect:"XPlat Code Coverage"
```

**Testing Stack:**
- **xUnit** 2.9.3 - Test framework
- **FluentAssertions** 8.8.0 - Readable assertions
- **Moq** 4.20.72 - Mocking framework
- **Microsoft.AspNetCore.Mvc.Testing** - Integration testing
- **Entity Framework Core InMemory** - Database testing
- **Coverlet Collector** 6.0.4 - Code coverage

**Test Structure:**
- Unit tests for business logic in Core layer
- Integration tests for API endpoints
- In-memory database for isolated testing
- JWT authentication testing

### Frontend Testing (React)

Run frontend tests:
```bash
cd DocumentGenerator.Client
npm test
```

Run tests in watch mode:
```bash
npm run test:watch
```

Generate coverage report:
```bash
npm run test:coverage
```

**Testing Stack:**
- **Vitest** 4.0.14 - Fast test runner
- **Testing Library** 16.2.0 - React component testing
- **Testing Library User Event** 14.6.1 - User interaction simulation
- **Jest DOM** 6.6.3 - Custom DOM matchers
- **jsdom** - Browser environment simulation

**Test Structure:**
- Component testing for UI elements
- Hook testing for state management
- Integration testing for user workflows
- API mocking for isolated testing

### Running All Tests

Run complete test suite (both frontend and backend):
```bash
# Backend
dotnet test

# Frontend (in separate terminal)
cd DocumentGenerator.Client && npm test
```

## Security Notes

- Passwords hashed with BCrypt (cost factor 12)
- JWT tokens for stateless auth
- Refresh tokens allow long-lived sessions without exposing credentials
- FluentValidation prevents injection attacks
- CORS properly configured for local dev

## Roadmap

Things I might add:
- Template versioning (save history)
- Bulk generation (process 100s of PDFs from a CSV)
- Cloud storage (S3/Azure instead of local disk)
- Template sharing (if there's interest)

## Contributing

This is a portfolio project, but I'm happy to review PRs!

**Quick contribution ideas:**
- Add template examples (invoices, tickets, certificates)
- Improve error messages
- Add tests for edge cases

**Standard workflow:**
1. Fork it
2. Create your feature branch (`git checkout -b feature/cool-thing`)
3. Commit your changes (`git commit -am 'Add cool thing'`)
4. Push to the branch (`git push origin feature/cool-thing`)
5. Open a Pull Request

## License

MIT - do whatever you want with it.


---

Made by [@jonmartin721](https://github.com/jonmartin721). PRs welcome.

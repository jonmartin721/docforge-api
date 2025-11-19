# DocForge

Stop fighting with PDF libraries. Write HTML templates, get PDFs back.

*[Dashboard screenshot coming soon]*

Perfect for invoices, reports, certificates, or any document that changes based on data. Includes a REST API (.NET 8) and React frontend for managing templates and generating documents.

## Quick Start

**With Docker** (easiest):
```bash
git clone https://github.com/yourusername/docforge-api.git
cd docforge-api
docker-compose up
```

Then open:
- **Frontend**: http://localhost:5173
- **API**: http://localhost:5257/swagger

**Local development**:
```bash
# Backend
dotnet run --project DocumentGenerator.API

# Frontend (separate terminal)
cd DocumentGenerator.Client
npm install
npm run dev
```

## Features

- **React Frontend**: Dashboard, template editor, document library - no Swagger needed for daily use
- **HTML templates**: Use Handlebars syntax you already know, no weird DSL to learn
- **Bulk generation**: Process hundreds of documents from JSON arrays
- **JWT auth**: Secure multi-user support with refresh tokens
- **Docker ready**: One command to run everything locally

## How It Works

1. **Create a template** using HTML + Handlebars variables
2. **POST your data** to the generation endpoint
3. **Get a PDF back** - that's it

The frontend makes this even easier with a visual template editor and JSON input form.

## Frontend UI

*[Login screenshot coming soon - Dark-themed auth with gradient backgrounds]*

*[Template management screenshot coming soon - Template management with preview]*

*[Document generation screenshot coming soon - Document generation with JSON input]*

### What You Get

The React SPA includes:
- Template editor with syntax highlighting
- Document generation with live JSON validation
- Download generated PDFs with one click
- Dashboard showing recent activity
- Dark theme with gradients because why not

Built with Vite + React Router. Fast, clean, no bloat.

See it in action:
*[Demo video coming soon]*

## Example: Generate an Invoice

```bash
# 1. Register a user
curl -X POST http://localhost:5257/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "demo",
    "email": "demo@example.com",
    "password": "password123"
  }'

# Response includes your token
# {
#   "token": "eyJhbGc...",
#   "refreshToken": "...",
#   "expiration": "2025-11-20T00:00:00Z"
# }

# 2. Create a template
curl -X POST http://localhost:5257/api/templates \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Invoice Template",
    "content": "<h1>Invoice #{{invoiceNumber}}</h1><p>Customer: {{customer}}</p><p>Total: ${{total}}</p>",
    "description": "Standard invoice"
  }'

# 3. Generate PDF
curl -X POST http://localhost:5257/api/documents/generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "templateId": "YOUR_TEMPLATE_ID",
    "data": {
      "invoiceNumber": "12345",
      "customer": "Acme Corp",
      "total": "250.00"
    }
  }'

# Returns document metadata with download link
```

Or just use the frontend - it's way easier.

## Template Syntax

Templates use Handlebars. If you've used Mustache, it's basically that.

**Variables**: 
```html
<h1>Hello {{name}}</h1>
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

**Pro tip**: Test your templates in the frontend editor - it'll show you syntax errors before you try to generate.

## Tech Stack

**Backend:**
- .NET 8 Web API
- Entity Framework Core (SQLite for dev, easy to swap)
- PuppeteerSharp (headless Chrome for PDF generation)
- Handlebars.NET (templating engine)
- FluentValidation (input validation)
- Serilog (structured logging)
- JWT authentication

**Frontend:**
- React 18 with Vite
- React Router for navigation
- Axios with interceptors for JWT
- Vanilla CSS (no framework bloat)
- Google Fonts (Inter)

## API Reference

### Authentication

**Register**
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "user1",
  "email": "user1@example.com",
  "password": "password123"
}
```

**Login**
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "user1",
  "password": "password123"
}
```

### Templates

**Create Template** (requires auth)
```http
POST /api/templates
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Invoice Template",
  "content": "<html>...{{variable}}...</html>",
  "description": "Standard invoice"
}
```

**List Templates**
```http
GET /api/templates
Authorization: Bearer {token}
```

**Delete Template**
```http
DELETE /api/templates/{id}
Authorization: Bearer {token}
```

### Documents

**Generate Document** (requires auth)
```http
POST /api/documents/generate
Authorization: Bearer {token}
Content-Type: application/json

{
  "templateId": "guid-here",
  "data": {
    "companyName": "Acme Corp",
    "items": [...]
  }
}
```

**Download PDF**
```http
GET /api/documents/{id}/download
Authorization: Bearer {token}
```

Full API docs available at `/swagger` when running locally.

## Development Setup

### Prerequisites
- .NET 8 SDK
- Node.js 18+ (for frontend)
- Docker (optional but recommended)

### Running Locally

1. **Clone and restore**:
   ```bash
   git clone https://github.com/yourusername/docforge-api.git
   cd docforge-api
   dotnet restore
   ```

2. **Run migrations** (if needed):
   ```bash
   dotnet tool install --global dotnet-ef
   dotnet ef database update --project DocumentGenerator.Infrastructure --startup-project DocumentGenerator.API
   ```

3. **Start backend**:
   ```bash
   dotnet run --project DocumentGenerator.API
   # API running at http://localhost:5257
   ```

4. **Start frontend** (new terminal):
   ```bash
   cd DocumentGenerator.Client
   npm install
   npm run dev
   # Frontend at http://localhost:5173
   ```

### Docker Setup

```bash
docker-compose up --build
```

Access:
- Frontend: http://localhost:5173
- API: http://localhost:5000/swagger

## Testing

Run the full test suite:
```bash
dotnet test
```

Includes unit tests and integration tests with in-memory database.

## Security Notes

- Passwords hashed with BCrypt (cost factor 12)
- JWT tokens for stateless auth
- Refresh tokens allow long-lived sessions without exposing credentials
- FluentValidation prevents injection attacks
- CORS properly configured for local dev

## What's Next

- [ ] Template versioning
- [ ] CSS support in templates (currently HTML only)
- [ ] Batch job processing
- [ ] S3/Azure Blob storage option
- [ ] Template marketplace?

## Contributing

Found a bug? Want to add a feature? PRs welcome.

1. Fork it
2. Create your feature branch (`git checkout -b feature/cool-thing`)
3. Commit your changes (`git commit -am 'Add cool thing'`)
4. Push to the branch (`git push origin feature/cool-thing`)
5. Open a Pull Request

## License

MIT - do whatever you want with it.

---

Built with ☕ because generating PDFs shouldn't be this hard.

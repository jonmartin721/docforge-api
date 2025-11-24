# DocForge

Stop fighting with PDF libraries. Write HTML templates, get PDFs back.

DocForge is a .NET 8 API + React frontend for generating PDFs from templates. You write HTML with Handlebars variables, POST your JSON data, get a PDF. That's it.

Good for invoices, reports, certificates - anything where the layout stays the same but the data changes.

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

**Result:** A formatted PDF invoice.

## Quick Start

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
- **API**: http://localhost:5000/swagger (Docker runs on port 5000)

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

## Features

- **Templates are just HTML + CSS** - Uses Handlebars (same as Mustache)
- **Visual builder** - Drag-and-drop editor with invoice/contract/letter presets
- **React frontend** - Dashboard, template editor, document library
- **Multi-user** - JWT auth with refresh tokens
- **Docker support** - API runs in container, frontend runs locally (Vite)

<!-- TODO: Add a screenshot of the dashboard here to show the visual builder -->



## Template Syntax

Templates use Handlebars. If you've used Mustache, it's basically that.

**Variables**:
```html
<!-- Template -->
<h1>Hello {{name}}</h1>

<!-- With { "name": "Alice" } you get: -->
<h1>Hello Alice</h1>
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
- Vanilla CSS
- Google Fonts (Inter)

## API Reference

Full API documentation is available at `/swagger` when running the application.




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

## Roadmap

Things I might add:
- Template versioning (save history)
- Bulk generation (process 100s of PDFs from a CSV)
- Cloud storage (S3/Azure instead of local disk)
- Template sharing (if there's interest)

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

Made by [@jonmartin721](https://github.com/jonmartin721). PRs welcome.

# DocForge

Stop fighting with PDF libraries. Write HTML templates, get PDFs back.

DocForge is a .NET 8 API + React frontend for generating PDFs from templates. You write HTML with Handlebars variables, POST your JSON data, get a PDF. That's it.

Good for invoices, reports, certificates - anything where the layout stays the same but the data changes.

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

**Result:** A formatted PDF invoice.

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
This will open a menu where you can install dependencies, start the backend/frontend, and run tests.

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
- **API**: http://localhost:5000/swagger (Docker runs on port 5000)

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

```html
<!-- Result in PDF -->
<h1>Invoice #INV-2024-001</h1>
<p>Customer: Acme Corp</p>
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

## Learn More

- 📖 **API Documentation** - Available at `/swagger` when running the application
- 🎨 **Template Examples** - Check `DocumentGenerator.Client` for sample templates
- 🏗️ **Architecture** - .NET 8 API + React frontend, uses PuppeteerSharp for PDF rendering

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

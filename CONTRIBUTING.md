# Contributing to DocForge

First off, thanks for taking the time to contribute! 🎉

DocForge is a portfolio project, but I welcome contributions from the community. Whether it's fixing a bug, improving documentation, or adding a cool new feature, your help is appreciated.

## How to Contribute

### 1. Fork and Clone
Fork the repository to your own GitHub account and clone it locally:

```bash
git clone https://github.com/YOUR_USERNAME/docforge-api.git
cd docforge-api
```

### 2. Create a Branch
Create a new branch for your feature or fix:

```bash
git checkout -b feature/amazing-new-feature
# or
git checkout -b fix/annoying-bug
```

### 3. Make Your Changes
- Write clean, readable code.
- Follow the existing coding style (check `.editorconfig` if available, or just match the existing code).
- **Add tests** for any new functionality.
- Ensure all existing tests pass.

### 4. Commit Your Changes
We use **Conventional Commits** for commit messages. This helps us generate changelogs and keep history clean.

Format: `<type>(<scope>): <description>`

Examples:
- `feat(auth): add google oauth support`
- `fix(pdf): resolve rendering issue with custom fonts`
- `docs: update setup instructions`
- `style: fix indentation in template editor`
- `refactor: simplify document generation service`

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries

### 5. Push and Pull Request
Push your changes to your fork and open a Pull Request against the `main` branch of this repository.

```bash
git push origin feature/amazing-new-feature
```

## Development Setup

See the [README.md](README.md) for detailed setup instructions using Docker or local environment.

## Reporting Bugs

If you find a bug, please open an issue and include:
- A clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Environment details (OS, browser, etc.)

## License

By contributing, you agree that your contributions will be licensed under its MIT License.

import { render } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import App from './App';
import { authService } from './services/authService';

// Mock authService
vi.mock('./services/authService', () => ({
  authService: {
    isAuthenticated: vi.fn()
  }
}));

// Mock pages to simplify testing
vi.mock('./pages/AuthPage', () => ({
  default: () => <div data-testid="auth-page">Auth Page</div>
}));

vi.mock('./pages/Dashboard', () => ({
  default: () => <div data-testid="dashboard">Dashboard</div>
}));

vi.mock('./pages/TemplatesPage', () => ({
  default: () => <div data-testid="templates-page">Templates</div>
}));

vi.mock('./pages/TemplateForm', () => ({
  default: () => <div data-testid="template-form">Template Form</div>
}));

vi.mock('./pages/GeneratePage', () => ({
  default: () => <div data-testid="generate-page">Generate</div>
}));

vi.mock('./pages/DocumentsPage', () => ({
  default: () => <div data-testid="documents-page">Documents</div>
}));

describe('App', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders without crashing when unauthenticated', () => {
    authService.isAuthenticated.mockReturnValue(false);

    expect(() => render(<App />)).not.toThrow();
    expect(authService.isAuthenticated).toHaveBeenCalled();
  });

  it('renders without crashing when authenticated', () => {
    authService.isAuthenticated.mockReturnValue(true);

    expect(() => render(<App />)).not.toThrow();
    expect(authService.isAuthenticated).toHaveBeenCalled();
  });

  it('checks authentication status on initial render', () => {
    authService.isAuthenticated.mockReturnValue(false);

    render(<App />);

    expect(authService.isAuthenticated).toHaveBeenCalled();
  });
});

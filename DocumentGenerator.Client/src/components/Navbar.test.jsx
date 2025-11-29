import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import Navbar from './Navbar';
import { authService } from '../services/authService';

// Mock authService
vi.mock('../services/authService', () => ({
    authService: {
        getCurrentUser: vi.fn(),
        logout: vi.fn(),
    },
}));

// Mock useNavigate
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
    const actual = await vi.importActual('react-router-dom');
    return {
        ...actual,
        useNavigate: () => mockNavigate,
    };
});

describe('Navbar', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders brand and links', () => {
        authService.getCurrentUser.mockReturnValue({ username: 'test@example.com' });

        render(
            <MemoryRouter>
                <Navbar />
            </MemoryRouter>
        );

        expect(screen.getByText('DocForge')).toBeInTheDocument();
        expect(screen.getByText('Dashboard')).toBeInTheDocument();
        expect(screen.getByText('Templates')).toBeInTheDocument();
        expect(screen.getByText('Documents')).toBeInTheDocument();
    });

    it('displays current user email', () => {
        authService.getCurrentUser.mockReturnValue({ username: 'test@example.com' });

        render(
            <MemoryRouter>
                <Navbar />
            </MemoryRouter>
        );

        expect(screen.getByText('test@example.com')).toBeInTheDocument();
    });

    it('handles logout correctly', () => {
        authService.getCurrentUser.mockReturnValue({ username: 'test@example.com' });

        render(
            <MemoryRouter>
                <Navbar />
            </MemoryRouter>
        );

        const logoutButton = screen.getByText('Logout');
        fireEvent.click(logoutButton);

        expect(authService.logout).toHaveBeenCalled();
        expect(mockNavigate).toHaveBeenCalledWith('/login');
    });
});

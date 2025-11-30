import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { authService } from './authService';
import api from './api';

vi.mock('./api');

describe('authService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('register', () => {
    it('should register user and store token', async () => {
      const mockResponse = {
        data: {
          token: 'mock-token',
          refreshToken: 'mock-refresh-token',
          expiration: '2025-12-01T00:00:00Z',
        },
      };
      api.post.mockResolvedValue(mockResponse);

      const result = await authService.register('testuser', 'test@example.com', 'password123');

      expect(api.post).toHaveBeenCalledWith('/auth/register', {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      });
      expect(localStorage.getItem('token')).toBe('mock-token');
      expect(JSON.parse(localStorage.getItem('user'))).toEqual({
        username: 'testuser',
        email: 'test@example.com',
      });
      expect(result.token).toBe('mock-token');
    });

    it('should not store token when registration fails', async () => {
      api.post.mockRejectedValue(new Error('Registration failed'));

      await expect(authService.register('testuser', 'test@example.com', 'password123'))
        .rejects.toThrow('Registration failed');
      expect(localStorage.getItem('token')).toBeNull();
    });
  });

  describe('login', () => {
    it('should login user and store token', async () => {
      const mockResponse = {
        data: {
          token: 'mock-token',
          refreshToken: 'mock-refresh-token',
        },
      };
      api.post.mockResolvedValue(mockResponse);

      const result = await authService.login('testuser', 'password123');

      expect(api.post).toHaveBeenCalledWith('/auth/login', {
        username: 'testuser',
        password: 'password123',
      });
      expect(localStorage.getItem('token')).toBe('mock-token');
      expect(result.token).toBe('mock-token');
    });
  });

  describe('logout', () => {
    it('should clear token and user from localStorage', () => {
      localStorage.setItem('token', 'mock-token');
      localStorage.setItem('user', JSON.stringify({ username: 'testuser' }));

      const dispatchSpy = vi.spyOn(window, 'dispatchEvent');

      authService.logout();

      expect(localStorage.getItem('token')).toBeNull();
      expect(localStorage.getItem('user')).toBeNull();
      expect(dispatchSpy).toHaveBeenCalledWith(expect.any(Event));
    });
  });

  describe('getCurrentUser', () => {
    it('should return user from localStorage', () => {
      const user = { username: 'testuser', email: 'test@example.com' };
      localStorage.setItem('user', JSON.stringify(user));

      const result = authService.getCurrentUser();

      expect(result).toEqual(user);
    });

    it('should return null when no user in localStorage', () => {
      const result = authService.getCurrentUser();

      expect(result).toBeNull();
    });
  });

  describe('isAuthenticated', () => {
    it('should return true when token exists', () => {
      localStorage.setItem('token', 'mock-token');

      expect(authService.isAuthenticated()).toBe(true);
    });

    it('should return false when token does not exist', () => {
      expect(authService.isAuthenticated()).toBe(false);
    });
  });
});

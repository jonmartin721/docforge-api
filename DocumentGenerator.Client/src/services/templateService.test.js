import { describe, it, expect, vi, beforeEach } from 'vitest';
import { templateService } from './templateService';
import api from './api';

vi.mock('./api');

describe('templateService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAll', () => {
    it('should fetch all templates and return items array', async () => {
      const mockTemplates = [
        { id: '1', name: 'Template 1', content: '<h1>Test</h1>' },
        { id: '2', name: 'Template 2', content: '<p>Content</p>' },
      ];
      api.get.mockResolvedValue({
        data: { items: mockTemplates, page: 1, pageSize: 20, totalCount: 2, totalPages: 1 },
      });

      const result = await templateService.getAll();

      expect(api.get).toHaveBeenCalledWith('/templates', { params: { page: 1, pageSize: 20 } });
      expect(result).toEqual(mockTemplates);
    });

    it('should support pagination parameters', async () => {
      api.get.mockResolvedValue({
        data: { items: [], page: 2, pageSize: 10, totalCount: 0, totalPages: 0 },
      });

      await templateService.getAll(2, 10);

      expect(api.get).toHaveBeenCalledWith('/templates', { params: { page: 2, pageSize: 10 } });
    });
  });

  describe('getAllPaginated', () => {
    it('should return full paginated response', async () => {
      const mockResponse = {
        items: [{ id: '1', name: 'Template 1' }],
        page: 1,
        pageSize: 20,
        totalCount: 1,
        totalPages: 1,
      };
      api.get.mockResolvedValue({ data: mockResponse });

      const result = await templateService.getAllPaginated();

      expect(result).toEqual(mockResponse);
    });
  });

  describe('getById', () => {
    it('should fetch template by id', async () => {
      const mockTemplate = { id: '123', name: 'Test Template', content: '<h1>Test</h1>' };
      api.get.mockResolvedValue({ data: mockTemplate });

      const result = await templateService.getById('123');

      expect(api.get).toHaveBeenCalledWith('/templates/123');
      expect(result).toEqual(mockTemplate);
    });
  });

  describe('create', () => {
    it('should create a new template', async () => {
      const templateData = { name: 'New Template', content: '<p>Content</p>' };
      const mockResponse = { id: '456', ...templateData };
      api.post.mockResolvedValue({ data: mockResponse });

      const result = await templateService.create(templateData);

      expect(api.post).toHaveBeenCalledWith('/templates', templateData);
      expect(result).toEqual(mockResponse);
    });
  });

  describe('update', () => {
    it('should update an existing template', async () => {
      const templateData = { name: 'Updated Template' };
      const mockResponse = { id: '123', ...templateData };
      api.put.mockResolvedValue({ data: mockResponse });

      const result = await templateService.update('123', templateData);

      expect(api.put).toHaveBeenCalledWith('/templates/123', templateData);
      expect(result).toEqual(mockResponse);
    });
  });

  describe('delete', () => {
    it('should delete a template', async () => {
      api.delete.mockResolvedValue({});

      await templateService.delete('123');

      expect(api.delete).toHaveBeenCalledWith('/templates/123');
    });
  });
});

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { documentService } from './documentService';
import api from './api';

vi.mock('./api');

describe('documentService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('generate', () => {
    it('should generate a document from template', async () => {
      const mockResponse = {
        id: 'doc-123',
        templateId: 'tmpl-456',
        downloadUrl: '/api/documents/doc-123/download',
      };
      api.post.mockResolvedValue({ data: mockResponse });

      const result = await documentService.generate('tmpl-456', { name: 'Test' });

      expect(api.post).toHaveBeenCalledWith('/documents/generate', {
        templateId: 'tmpl-456',
        data: { name: 'Test' },
      });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('getAll', () => {
    it('should fetch all documents and return items array', async () => {
      const mockDocuments = [
        { id: 'doc-1', templateName: 'Template 1' },
        { id: 'doc-2', templateName: 'Template 2' },
      ];
      api.get.mockResolvedValue({
        data: { items: mockDocuments, page: 1, pageSize: 20, totalCount: 2, totalPages: 1 },
      });

      const result = await documentService.getAll();

      expect(api.get).toHaveBeenCalledWith('/documents', { params: { page: 1, pageSize: 20 } });
      expect(result).toEqual(mockDocuments);
    });

    it('should support pagination parameters', async () => {
      api.get.mockResolvedValue({
        data: { items: [], page: 2, pageSize: 10, totalCount: 0, totalPages: 0 },
      });

      await documentService.getAll(2, 10);

      expect(api.get).toHaveBeenCalledWith('/documents', { params: { page: 2, pageSize: 10 } });
    });
  });

  describe('getAllPaginated', () => {
    it('should return full paginated response', async () => {
      const mockResponse = {
        items: [{ id: 'doc-1', templateName: 'Template 1' }],
        page: 1,
        pageSize: 20,
        totalCount: 1,
        totalPages: 1,
      };
      api.get.mockResolvedValue({ data: mockResponse });

      const result = await documentService.getAllPaginated();

      expect(result).toEqual(mockResponse);
    });
  });

  describe('getById', () => {
    it('should fetch document by id', async () => {
      const mockDocument = { id: 'doc-123', templateName: 'Test Template' };
      api.get.mockResolvedValue({ data: mockDocument });

      const result = await documentService.getById('doc-123');

      expect(api.get).toHaveBeenCalledWith('/documents/doc-123');
      expect(result).toEqual(mockDocument);
    });
  });

  describe('download', () => {
    it('should download document as blob', async () => {
      const mockBlob = new Blob(['PDF content'], { type: 'application/pdf' });
      api.get.mockResolvedValue({ data: mockBlob });

      const result = await documentService.download('doc-123');

      expect(api.get).toHaveBeenCalledWith('/documents/doc-123/download', {
        responseType: 'blob',
      });
      expect(result).toEqual(mockBlob);
    });
  });

  describe('delete', () => {
    it('should delete a document', async () => {
      api.delete.mockResolvedValue({});

      await documentService.delete('doc-123');

      expect(api.delete).toHaveBeenCalledWith('/documents/doc-123');
    });
  });
});

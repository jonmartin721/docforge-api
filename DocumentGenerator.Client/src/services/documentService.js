import api from './api';

export const documentService = {
  async generate(templateId, jsonData) {
    const response = await api.post('/documents/generate', {
      templateId,
      data: jsonData,
    });
    return response.data;
  },

  async generateBatch(templateId, dataItems) {
    const response = await api.post('/documents/generate-batch', {
      templateId,
      dataItems,
    });
    return response.data;
  },

  async getAll(page = 1, pageSize = 20) {
    const response = await api.get('/documents', { params: { page, pageSize } });
    // API returns paginated result: { items, page, pageSize, totalCount, totalPages }
    return response.data.items || response.data;
  },

  async getAllPaginated(page = 1, pageSize = 20) {
    const response = await api.get('/documents', { params: { page, pageSize } });
    return response.data;
  },

  async getById(id) {
    const response = await api.get(`/documents/${id}`);
    return response.data;
  },

  async download(id) {
    const response = await api.get(`/documents/${id}/download`, {
      responseType: 'blob',
    });
    return response.data;
  },

  async delete(id) {
    await api.delete(`/documents/${id}`);
  },
};

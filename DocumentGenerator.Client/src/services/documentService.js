import api from './api';

export const documentService = {
  async generate(templateId, jsonData) {
    const response = await api.post('/documents/generate', {
      templateId,
      data: jsonData,
    });
    return response.data;
  },

  async getAll() {
    const response = await api.get('/documents');
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

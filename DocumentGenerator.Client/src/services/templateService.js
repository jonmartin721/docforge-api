import api from './api';

export const templateService = {
  async getAll(page = 1, pageSize = 20) {
    const response = await api.get('/templates', { params: { page, pageSize } });
    // API returns paginated result: { items, page, pageSize, totalCount, totalPages }
    return response.data.items || response.data;
  },

  async getAllPaginated(page = 1, pageSize = 20) {
    const response = await api.get('/templates', { params: { page, pageSize } });
    return response.data;
  },

  async getById(id) {
    const response = await api.get(`/templates/${id}`);
    return response.data;
  },

  async create(templateData) {
    const response = await api.post('/templates', templateData);
    return response.data;
  },

  async update(id, templateData) {
    const response = await api.put(`/templates/${id}`, templateData);
    return response.data;
  },

  async delete(id) {
    await api.delete(`/templates/${id}`);
  },
};

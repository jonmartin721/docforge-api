import api from './api';

export const templateService = {
  async getAll() {
    const response = await api.get('/templates');
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

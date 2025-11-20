import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

const apiService = {
  /**
   * Upload DOCX and CSV files to the Flask API
   * @param {File} docxFile - The DOCX file to upload
   * @param {File} csvFile - The CSV file to upload
   * @param {Function} onUploadProgress - Callback for upload progress
   * @returns {Promise<Blob>} - The XLSX file as a blob
   */
  uploadFiles: async (docxFile, csvFile, onUploadProgress) => {
    const formData = new FormData();
    formData.append('docx_file', docxFile);
    formData.append('csv_file', csvFile);

    try {
      const response = await axios.post(`${API_BASE_URL}/api/upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        responseType: 'blob',
        onUploadProgress: (progressEvent) => {
          if (onUploadProgress) {
            const percentCompleted = Math.round(
              (progressEvent.loaded * 100) / progressEvent.total
            );
            onUploadProgress(percentCompleted);
          }
        },
      });

      return response.data;
    } catch (error) {
      if (error.response && error.response.data instanceof Blob) {
        // Try to parse error message from blob
        const text = await error.response.data.text();
        try {
          const errorData = JSON.parse(text);
          throw new Error(errorData.error || 'Upload failed');
        } catch {
          throw new Error('Upload failed: ' + text);
        }
      }
      throw error;
    }
  },

  /**
   * Check API health
   * @returns {Promise<Object>} - Health status
   */
  checkHealth: async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/`);
      return response.data;
    } catch (error) {
      throw new Error('Cannot connect to server');
    }
  },
};

export default apiService;

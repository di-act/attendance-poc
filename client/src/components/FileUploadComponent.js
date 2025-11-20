import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import {
  Box,
  Paper,
  Typography,
  Button,
  LinearProgress,
  Alert,
  Chip,
  IconButton,
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon,
  InsertDriveFile as FileIcon,
  Close as CloseIcon,
  Description as DocIcon,
  TableChart as CsvIcon,
} from '@mui/icons-material';

const FileUploadZone = ({ file, onFileDrop, accept, label, fileType }) => {
  const onDrop = useCallback(
    (acceptedFiles) => {
      if (acceptedFiles && acceptedFiles.length > 0) {
        onFileDrop(acceptedFiles[0]);
      }
    },
    [onFileDrop]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept,
    maxFiles: 1,
    multiple: false,
  });

  const getFileIcon = () => {
    if (fileType === 'docx') return <DocIcon sx={{ fontSize: 40 }} />;
    if (fileType === 'csv') return <CsvIcon sx={{ fontSize: 40 }} />;
    return <FileIcon sx={{ fontSize: 40 }} />;
  };

  return (
    <Paper
      {...getRootProps()}
      sx={{
        p: 3,
        border: '2px dashed',
        borderColor: isDragActive ? 'primary.main' : 'grey.300',
        backgroundColor: isDragActive ? 'action.hover' : 'background.paper',
        cursor: 'pointer',
        transition: 'all 0.3s ease',
        textAlign: 'center',
        '&:hover': {
          borderColor: 'primary.main',
          backgroundColor: 'action.hover',
        },
      }}
    >
      <input {...getInputProps()} />
      {file ? (
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 1 }}>
            {getFileIcon()}
          </Box>
          <Typography variant="body1" fontWeight={500}>
            {file.name}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {(file.size / 1024).toFixed(2)} KB
          </Typography>
          <Chip
            label="Click to change"
            size="small"
            color="primary"
            sx={{ mt: 1 }}
          />
        </Box>
      ) : (
        <Box>
          <CloudUploadIcon sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
          <Typography variant="h6" gutterBottom>
            {label}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {isDragActive
              ? 'Drop the file here'
              : 'Drag & drop or click to select file'}
          </Typography>
        </Box>
      )}
    </Paper>
  );
};

const FileUploadComponent = ({ onUploadComplete, onError }) => {
  const [docxFile, setDocxFile] = useState(null);
  const [csvFile, setCsvFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const handleDocxDrop = (file) => {
    setDocxFile(file);
    setError(null);
    setSuccess(null);
  };

  const handleCsvDrop = (file) => {
    setCsvFile(file);
    setError(null);
    setSuccess(null);
  };

  const handleRemoveDocx = (e) => {
    e.stopPropagation();
    setDocxFile(null);
  };

  const handleRemoveCsv = (e) => {
    e.stopPropagation();
    setCsvFile(null);
  };

  const handleUpload = async () => {
    if (!docxFile || !csvFile) {
      setError('Please select both DOCX and CSV files');
      return;
    }

    setUploading(true);
    setUploadProgress(0);
    setError(null);
    setSuccess(null);

    try {
      const apiService = require('../services/apiService').default;
      
      const blob = await apiService.uploadFiles(
        docxFile,
        csvFile,
        (progress) => {
          setUploadProgress(progress);
        }
      );

      // Create download link
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `output_${new Date().getTime()}.xlsx`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      setSuccess('Files processed successfully! Download started.');
      setDocxFile(null);
      setCsvFile(null);
      setUploadProgress(0);
      
      if (onUploadComplete) {
        onUploadComplete();
      }
    } catch (err) {
      const errorMessage = err.response?.data?.error || err.message || 'Upload failed';
      setError(errorMessage);
      if (onError) {
        onError(errorMessage);
      }
    } finally {
      setUploading(false);
    }
  };

  const handleReset = () => {
    setDocxFile(null);
    setCsvFile(null);
    setUploadProgress(0);
    setError(null);
    setSuccess(null);
  };

  return (
    <Box>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3, mb: 3 }}>
        <FileUploadZone
          file={docxFile}
          onFileDrop={handleDocxDrop}
          accept={{
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
          }}
          label="Upload DOCX File"
          fileType="docx"
        />

        <FileUploadZone
          file={csvFile}
          onFileDrop={handleCsvDrop}
          accept={{
            'text/csv': ['.csv'],
          }}
          label="Upload CSV File"
          fileType="csv"
        />
      </Box>

      {uploading && (
        <Box sx={{ mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Upload Progress
            </Typography>
            <Typography variant="body2" color="text.secondary" fontWeight={500}>
              {uploadProgress}%
            </Typography>
          </Box>
          <LinearProgress variant="determinate" value={uploadProgress} />
        </Box>
      )}

      <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center' }}>
        <Button
          variant="contained"
          size="large"
          startIcon={<CloudUploadIcon />}
          onClick={handleUpload}
          disabled={!docxFile || !csvFile || uploading}
          sx={{ minWidth: 200 }}
        >
          {uploading ? 'Processing...' : 'Upload & Process'}
        </Button>

        <Button
          variant="outlined"
          size="large"
          onClick={handleReset}
          disabled={uploading}
        >
          Reset
        </Button>
      </Box>
    </Box>
  );
};

export default FileUploadComponent;

import React, { useState, useEffect } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Container,
  Box,
  Card,
  CardContent,
  Chip,
  Alert,
  IconButton,
  Tooltip,
  Paper,
} from '@mui/material';
import {
  Assessment as AssessmentIcon,
  Info as InfoIcon,
  FiberManualRecord as StatusIcon,
} from '@mui/icons-material';
import FileUploadComponent from './components/FileUploadComponent';
import apiService from './services/apiService';

function App() {
  const [serverStatus, setServerStatus] = useState('checking');
  const [uploadCount, setUploadCount] = useState(0);

  useEffect(() => {
    checkServerHealth();
  }, []);

  const checkServerHealth = async () => {
    try {
      await apiService.checkHealth();
      setServerStatus('online');
    } catch (error) {
      setServerStatus('offline');
    }
  };

  const handleUploadComplete = () => {
    setUploadCount((prev) => prev + 1);
  };

  const getStatusColor = () => {
    switch (serverStatus) {
      case 'online':
        return 'success';
      case 'offline':
        return 'error';
      default:
        return 'default';
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', backgroundColor: 'background.default' }}>
      {/* App Bar */}
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <AssessmentIcon sx={{ mr: 2, fontSize: 32 }} />
          <Typography variant="h5" component="div" sx={{ flexGrow: 1, fontWeight: 600 }}>
            Attendance Analysis Portal
          </Typography>
          <Tooltip title={`Server Status: ${serverStatus}`}>
            <Chip
              icon={<StatusIcon />}
              label={serverStatus === 'checking' ? 'Checking...' : serverStatus.toUpperCase()}
              color={getStatusColor()}
              size="small"
              sx={{ fontWeight: 500 }}
            />
          </Tooltip>
        </Toolbar>
      </AppBar>

      {/* Main Content */}
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {/* Info Banner */}
        <Alert
          severity="info"
          icon={<InfoIcon />}
          sx={{ mb: 3, borderRadius: 2 }}
        >
          Upload your DOCX and CSV files to generate a comprehensive XLSX report with document
          content, CSV data, and processing summary.
        </Alert>

        {serverStatus === 'offline' && (
          <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
            Cannot connect to the server. Please ensure the Flask API is running on{' '}
            <strong>{process.env.REACT_APP_API_URL || 'http://localhost:5000'}</strong>
          </Alert>
        )}

        {/* Main Card */}
        <Card elevation={2}>
          <CardContent sx={{ p: 4 }}>
            <Box sx={{ mb: 4, textAlign: 'center' }}>
              <Typography variant="h4" component="h1" gutterBottom fontWeight={600}>
                Document Upload & Processing
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Upload your documents to process and generate comprehensive reports
              </Typography>
            </Box>

            <FileUploadComponent onUploadComplete={handleUploadComplete} />
          </CardContent>
        </Card>

        {/* Stats Section */}
        {uploadCount > 0 && (
          <Paper
            elevation={1}
            sx={{
              mt: 3,
              p: 3,
              textAlign: 'center',
              backgroundColor: 'success.light',
              color: 'success.contrastText',
            }}
          >
            <Typography variant="h6" fontWeight={500}>
              Files Processed: {uploadCount}
            </Typography>
          </Paper>
        )}

        {/* Instructions */}
        <Box sx={{ mt: 4 }}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom fontWeight={500}>
                How to Use
              </Typography>
              <Box component="ol" sx={{ pl: 2, '& li': { mb: 1 } }}>
                <li>
                  <Typography variant="body2">
                    Select or drag & drop a <strong>DOCX</strong> file containing your document content
                  </Typography>
                </li>
                <li>
                  <Typography variant="body2">
                    Select or drag & drop a <strong>CSV</strong> file containing your data
                  </Typography>
                </li>
                <li>
                  <Typography variant="body2">
                    Click <strong>"Upload & Process"</strong> to generate the XLSX report
                  </Typography>
                </li>
                <li>
                  <Typography variant="body2">
                    The processed XLSX file will automatically download to your device
                  </Typography>
                </li>
              </Box>
            </CardContent>
          </Card>
        </Box>
      </Container>

      {/* Footer */}
      <Box
        component="footer"
        sx={{
          py: 3,
          px: 2,
          mt: 'auto',
          backgroundColor: 'background.paper',
          borderTop: '1px solid',
          borderColor: 'divider',
        }}
      >
        <Container maxWidth="lg">
          <Typography variant="body2" color="text.secondary" align="center">
            © {new Date().getFullYear()} Attendance Analysis Portal. All rights reserved.
          </Typography>
        </Container>
      </Box>
    </Box>
  );
}

export default App;

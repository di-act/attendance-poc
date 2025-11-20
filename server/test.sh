curl -X POST http://localhost:5000/api/upload \
  -F "docx_file=@..\input\agreement.docx" \
  -F "csv_file=@..\input\attendance.csv" \
  -o output.xlsx
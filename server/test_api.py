import requests

# API endpoint
url = 'http://localhost:5000/api/upload'

# Files to upload
files = {
    'docx_file': open('agreement.docx', 'rb'),
    'csv_file': open('attendance.csv', 'rb')
}

# Send request
response = requests.post(url, files=files)

# Save the response
if response.status_code == 200:
    with open('result.xlsx', 'wb') as f:
        f.write(response.content)
    print('✓ XLSX file generated successfully!')
else:
    print(f' Error: {response.json()}')
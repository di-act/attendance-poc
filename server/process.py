# TASK-1:: Extract data from DOCX agreement file
import os
import re
from typing import Any, Dict

from docx import Document
import pandas as pd


def extract_agreement_data(docx_filepath: str) -> Dict[str, Any]:
    """
    Extract structured data from a DOCX agreement file and return as JSON.
    
        UID: 88888888
        system hours: 7
        services performed: electrical, engineering, plumbing

    Args:
        docx_filepath: Path to the DOCX file
        
    Returns:
        Dictionary with extracted data in the required format
    """
     # Check file exists
    if not os.path.exists(docx_filepath) or not os.path.isfile(docx_filepath):
        raise FileNotFoundError(f"DOCX file not found: {docx_filepath}")
    
    
    # Read the DOCX file
    doc = Document(docx_filepath)
    
    # Extract all text from the document
    full_text = "\n".join([para.text for para in doc.paragraphs])
    
    # Split records by UID pattern
    records = []
    uid_pattern = r"UID:\s*(\d+)"
    hours_pattern = r"system\s+hours:\s*(\d+)"
    services_pattern = r"services\s+performed:\s*(.*\n)"
    
    # Find all UID positions
    uid_matches = list(re.finditer(uid_pattern, full_text, re.IGNORECASE))
    
    for i, uid_match in enumerate(uid_matches):
        # Get the text section for this record
        start_pos = uid_match.start()
        end_pos = uid_matches[i + 1].start() if i + 1 < len(uid_matches) else len(full_text)
        record_text = full_text[start_pos:end_pos]
        
        # Extract fields for this record
        uid_match_obj = re.search(uid_pattern, record_text, re.IGNORECASE)
        hours_match_obj = re.search(hours_pattern, record_text, re.IGNORECASE)
        services_match_obj = re.search(services_pattern, record_text, re.IGNORECASE)
        
        if uid_match_obj:
            record = {
                "uid": int(uid_match_obj.group(1)),
                "systemHours": int(hours_match_obj.group(1)) if hours_match_obj else None,
                "servicesPerformed": services_match_obj.group(1) if services_match_obj else None
            }
            if record["systemHours"] is not None and record["servicesPerformed"] is not None:
                record["servicesPerformed"] = record["servicesPerformed"].strip() # clean up whitespace
                records.append(record)
    
    # Create the final JSON structure
    result = {
        "documentName": "agreement.docx",
        "totalRecord": len(records),
        "records": records
    }
    
    return result

# TASK-2:: Extract data from CSV attendance file
def extract_attendance_data(csv_filepath: str) -> Dict[str, Any]:
    """
    Extract structured data from a CSV attendance file and return as JSON.
    """
    # Check file exists
    if not os.path.exists(csv_filepath) or not os.path.isfile(csv_filepath):
        raise FileNotFoundError(f"CSV file not found: {csv_filepath}")

    # Read the CSV file to data frame
    df = pd.read_csv(csv_filepath)

    # Validate required columns
    required_columns = ["uid", "punchInDateTime", "punchOutDateTime", "servicesPerformed"]
    for col in required_columns:
        if col not in df.columns:
            raise ValueError(f"Missing required column in CSV: {col}")

    # Convert DataFrame to list of records
    records = df.to_dict(orient="records")

    # constructing document summary
    doc_summary = {
        "documentName": "attendance",
        "totalRecord": len(records),
        "records": records
    }

    # Ensure datetime columns are parsed correctly
    df["punchInDateTime"] = pd.to_datetime(df["punchInDateTime"].str.strip())
    df["punchOutDateTime"] = pd.to_datetime(df["punchOutDateTime"].str.strip())

    # Calculate hours worked
    df["hoursWorked"] = (df["punchOutDateTime"] - df["punchInDateTime"]).dt.total_seconds() / 3600

    # Extract attendance date
    df["attendanceDate"] = df["punchInDateTime"].dt.date

    # Group by UID and attendanceDate
    grouped = df.groupby(["uid", "attendanceDate"]).agg({
        "hoursWorked": "sum",
        "servicesPerformed": lambda x: ", ".join(x.str.strip())
    }).reset_index()

    # Rename columns
    grouped.rename(columns={
        "hoursWorked": "totalHoursWorked"
    }, inplace=True)

    return grouped

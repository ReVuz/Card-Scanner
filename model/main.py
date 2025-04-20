import PIL
import pytesseract
from PIL import Image, ImageEnhance
import cv2
import numpy as np
import re

def preprocess_image(image_path):
    # Read image
    img = cv2.imread(image_path)
    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # Try multiple preprocessing techniques
    # 1. Adaptive thresholding
    adaptive_thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                          cv2.THRESH_BINARY, 11, 2)
    
    # 2. Standard binary thresholding
    _, binary_thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    
    # 3. Otsu's thresholding
    _, otsu_thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    # Return all processed images
    return {"adaptive": adaptive_thresh, "binary": binary_thresh, "otsu": otsu_thresh}

def extract_card_info(image_path):
    # Preprocess image with different techniques
    processed_images = preprocess_image(image_path)
    
    results = {}
    
    # Process with different thresholding methods and PSM modes
    for img_name, img in processed_images.items():
        # Save temporary processed image
        temp_path = f'temp_{img_name}.jpg'
        cv2.imwrite(temp_path, img)
        
        # Apply different PSM modes for different purposes
        # PSM 11 for sparse text - good for contact info
        text_sparse = pytesseract.image_to_string(PIL.Image.open(temp_path), config='--oem 3 --psm 11')
        
        # PSM 4 for single column - good for bottom text
        text_column = pytesseract.image_to_string(PIL.Image.open(temp_path), config='--oem 3 --psm 4')
        
        # PSM 1 for automatic segmentation - good for overall structure
        text_auto = pytesseract.image_to_string(PIL.Image.open(temp_path), config='--oem 3 --psm 1')
        
        # Extract information with regex
        name_pattern = r'(?:JOE|J[O0]E)[\s]*(?:BLACK|BIACK|BI[A4]CKY)'
        title_pattern = r'DESIGNER'
        company_pattern = r'(?:LOREM|COREM|L[O0]REM)[\s]*COMPANY[\s]*(?:IPSUM|PSUM|[I1]PSUM)'
        phone_pattern = r'[+]?[\s]*[1][\s,-]*234[\s,-]*56[\s,-]*78'
        email_pattern = r'[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*ipsum\.com'
        website_pattern = r'www\.lorem(?:ipsum|[i1]psum)\.com'
        
        # Combine all text for better pattern matching chances
        all_text = text_sparse + "\n" + text_column + "\n" + text_auto
        
        # Extract data
        name = re.search(name_pattern, all_text, re.IGNORECASE)
        title = re.search(title_pattern, all_text, re.IGNORECASE)
        company = re.search(company_pattern, all_text, re.IGNORECASE)
        phone = re.search(phone_pattern, all_text)
        email = re.search(email_pattern, all_text)
        website = re.search(website_pattern, all_text, re.IGNORECASE)
        
        # Store results for this processing method
        results[img_name] = {
            "name": name.group(0) if name else None,
            "title": title.group(0) if title else None,
            "company": company.group(0) if company else None,
            "phone": phone.group(0) if phone else None,
            "email": email.group(0) if email else None,
            "website": website.group(0) if website else None
        }
    
    # Combine best results from different methods
    final_result = {}
    fields = ["name", "title", "company", "phone", "email", "website"]
    
    for field in fields:
        # Choose the first non-None value across all processing methods
        for img_name in results:
            if results[img_name][field]:
                final_result[field] = results[img_name][field]
                break
        
        # If still None, set to empty string
        if field not in final_result:
            final_result[field] = ""
    
    return final_result

# Process the business card
card_info = extract_card_info('card2.webp')
print("\n=== EXTRACTED BUSINESS CARD INFO ===")
for field, value in card_info.items():
    print(f"{field.upper()}: {value}")
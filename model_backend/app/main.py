# app/main.py
from fastapi import FastAPI, File, UploadFile
import torch
from PIL import Image
import io
import numpy as np
import pickle
import os

# Initialize FastAPI app with proper configurations for Lambda
app = FastAPI(
    title="IRIS Eye Diagnostic API",
    description="API for eye disease classification",
    root_path="/prod" # Important for API Gateway stage name
)

# Load models at initialization time (cold start)
@app.on_event("startup")
async def load_model():
    global model, support_features, support_labels
    
    # Lambda will use the models in the deployment package
    model_path = os.path.join(os.path.dirname(__file__), "models/densenet121_encoder_traced.pt")
    support_set_path = os.path.join(os.path.dirname(__file__), "models/support_set.pkl")
    
    # Load traced model
    model = torch.jit.load(model_path)
    model.eval()
    
    # Load support set
    with open(support_set_path, 'rb') as f:
        support_data = pickle.load(f)
        support_features = support_data['features']
        support_labels = support_data['labels']

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    # Read image
    image_data = await file.read()
    image = Image.open(io.BytesIO(image_data)).convert('RGB')
    
    # Preprocess image
    # ... (your preprocessing code)
    
    # Generate prediction
    with torch.no_grad():
        image_features = model(image_tensor)
    
    # Compare with support set
    # ... (your comparison code)
    
    # Enhanced response with detailed information
    return {
        "success": True,
        "prediction": {
            "classId": best_class_idx,
            "className": support_labels[best_class_idx],
            "confidence": float(similarity[0][best_class_idx]),
            "severity": calculate_severity(image_features, best_class_idx),
            "diagnosis": get_diagnosis_text(best_class_idx),
            "recommendations": get_recommendations(best_class_idx)
        }
    }

# Health check endpoint
@app.get("/health")
def health_check():
    return {"status": "ok"}

# Implement helper functions
def calculate_severity(features, class_idx):
    # Logic to determine severity
    return "moderate"

def get_diagnosis_text(class_idx):
    diagnoses = {
        0: "Cataract detected. This is characterized by clouding of the eye's lens...",
        1: "Healthy eye. No significant issues detected...",
        # More conditions...
    }
    return diagnoses.get(class_idx, "Unknown condition")

def get_recommendations(class_idx):
    recommendations = {
        0: [  # Cataract
            {"recommendation": "Schedule an appointment with an ophthalmologist", "priority": 1},
            {"recommendation": "Avoid driving at night", "priority": 2},
            # More recommendations...
        ],
        # More conditions...
    }
    return recommendations.get(class_idx, [])
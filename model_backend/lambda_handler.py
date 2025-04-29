# lambda_handler.py
import base64
import json
from mangum import Mangum
from app.main import app

# Create Mangum handler to convert between AWS Lambda and FastAPI
handler = Mangum(app)
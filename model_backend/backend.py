from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from torchvision import transforms
from PIL import Image
import torch
import io
from sklearn.metrics.pairwise import cosine_similarity

app = FastAPI()

# Load the model (DenseNet feature extractor)
model = torch.jit.load("densenet121_encoder_traced.pt")
model.eval()

# Load precomputed support set embeddings and labels
support_embeddings = torch.load("support_embeddings.pt")  # Shape: [num_classes, 1024]
support_labels = [
    "cataract", "healthy", "pterygium", "glaucoma", "keratoconus", "strabismus",
    "pink_eye", "stye", "trachoma", "uveitis"
]  # Adjust based on your actual dataset classes

# Transformation for input images
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor()
])

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    # Read image file and preprocess
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    input_tensor = transform(image).unsqueeze(0)  # Shape: [1, 3, 224, 224]

    # Get feature embedding from model
    with torch.no_grad():
        features = model(input_tensor)  # Shape: [1, 1024]

    predicted_embedding = features.squeeze(0).cpu().numpy()  # Shape: [1024]
    support_embeddings_np = support_embeddings.cpu().numpy()  # Shape: [num_classes, 1024]

    # Cosine similarity
    similarities = cosine_similarity(predicted_embedding.reshape(1, -1), support_embeddings_np)

    # Get class ID with highest similarity
    predicted_class_id = int(similarities.argmax())  # Cast to Python int
    predicted_class_label = support_labels[predicted_class_id]

    # Optional debug prints
    print("Predicted embedding shape:", predicted_embedding.shape)
    print("Support embeddings shape:", support_embeddings_np.shape)
    print("Cosine Similarities:", similarities)
    print("Predicted class ID:", predicted_class_id)
    print("Predicted label:", predicted_class_label)

    return JSONResponse(content={
        "predicted_class_id": predicted_class_id,
        "predicted_class_label": predicted_class_label
    })

@app.get("/")
def read_root():
    return {"message": " Classification API!"}

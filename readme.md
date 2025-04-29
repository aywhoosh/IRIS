# 👁️ IRIS – Intelligent Retinal Imaging System 👁️

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)  
[![FastAPI](https://img.shields.io/badge/FastAPI-0.95+-009688?logo=fastapi)](https://fastapi.tiangolo.com)  
[![Supabase](https://img.shields.io/badge/Supabase-1.0+-3ECF8E?logo=supabase)](https://supabase.com)  
[![AWS](https://img.shields.io/badge/AWS-EC2%20%2F%20Lambda-orange?logo=amazonaws)](https://aws.amazon.com)

An end-to-end, **AI-powered** Flutter app for **few-shot ocular disease** screening. Capture or upload a retinal image, authenticate via Supabase, then call your AWS EC2 model back-end to get a real-time diagnosis—with history, profiles, and beautiful shader effects along the way!

---

## 📋 Table of Contents

1. [✨ Key Features](#-key-features)  
2. [🚀 Getting Started](#-getting-started)  
   - [Prerequisites](#prerequisites)  
   - [Installation](#installation)  
   - [Environment Variables](#environment-variables)  
3. [🏗️ Project Structure](#️-project-structure)  
4. [📐 Architecture Overview](#️-architecture-overview)  
5. [💾 Database Schema](#-database-schema)  
6. [📡 API Endpoints](#-api-endpoints)  
7. [📸 Screenshots](#-screenshots)  
8. [⚙️ Deployment](#️-deployment)  
9. [🤝 Contributing](#-contributing)  
10. [📄 License](#-license)

---

## ✨ Key Features

- 🔐 **Authentication & Profiles**  
  – Secure sign-up / login via Supabase Auth  
  – User profiles (name, DOB, medical history)

- 📷 **Guided Scanning & Upload**  
  – `camera_screen.dart` for quick snaps  
  – `enhanced_camera_screen.dart` with focus guides  
  – `gallery_upload_screen.dart` for imports

- 📑 **Scan History**  
  – View past scans & results in `history_screen.dart`

- ⚡ **Real-Time AI Diagnostics**  
  – Images stored in Supabase Storage  
  – Processed on your AWS EC2 FastAPI server  
  – Model: TorchScript-traced DenseNet121 + Prototypical Network

- 📊 **Detailed Results & Recommendations**  
  – Disease label, confidence, severity, next steps  
  – Crop & highlight affected region

- 🎨 **Stunning UI Effects**  
  – `pulsating_orb.dart`, shader backgrounds, smooth transitions

---

## 🚀 Getting Started

### Prerequisites

- **Flutter** 3.0+ & **Dart** 2.17+  
- **Node.js** 16+ & npm (for any JS tooling / supabase functions)  
- **Python** 3.8+ & `pip` (for FastAPI back-end)  
- **AWS CLI** (configured with EC2 or Lambda access)  
- **Supabase CLI** (optional, for local emulation)  

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/aywhoosh/IRIS-Ocular-Diagnostics.git
cd IRIS-Ocular-Diagnostics

# 2. Install Node tooling (if you have any package.json here)
npm install

# 3. Flutter dependencies
cd app
flutter pub get
cd ..

# 4. Python back-end deps
cd backend
pip install -r requirements.txt
cd ..

# 5. Model service deps (if separate)
cd model_backend
pip install -r requirements.txt
cd ..

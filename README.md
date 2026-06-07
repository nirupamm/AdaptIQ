# 🎯 AdaptIQ – Adaptive Quiz Application

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Django](https://img.shields.io/badge/Django-REST%20Framework-green?logo=django)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql)
![JWT](https://img.shields.io/badge/JWT-Authentication-orange)
![OpenCV](https://img.shields.io/badge/OpenCV-Face%20Detection-red?logo=opencv)

## 📖 Overview

AdaptIQ is an adaptive mobile quiz application developed as a Final Year Project. The system dynamically adjusts quiz difficulty based on user performance and includes a camera-based monitoring system using OpenCV.

The application aims to provide a more personalized and engaging learning experience compared to traditional static quiz platforms.

---

## 🚀 Features

### 🔐 Authentication

* JWT-based authentication
* User registration and login
* Persistent login using SharedPreferences

### 🧠 Adaptive Learning

* Rule-based adaptive difficulty system
* Difficulty increases after consecutive correct answers
* Difficulty decreases after consecutive incorrect answers
* Dynamic score calculation

### 👶 Kid Mode

* Child-friendly interface
* Simplified quiz experience
* Independent timer management

### 📊 Dashboard

* Quiz statistics
* User performance tracking
* Session history

### 👁️ Monitoring System

* OpenCV integration
* Haar Cascade face detection
* Warning system
* Quiz integrity monitoring

---

## 🏗️ System Architecture

Flutter Mobile App
↓
REST API (HTTP/JSON)
↓
Django REST Framework
↓
PostgreSQL Database

Monitoring Module:
Flutter Camera
↓
MethodChannel
↓
Kotlin
↓
OpenCV + Haar Cascade

---

## 🛠️ Technologies Used

### Frontend

* Flutter
* Dart
* Provider State Management

### Backend

* Django
* Django REST Framework
* SimpleJWT

### Database

* PostgreSQL

### Computer Vision

* OpenCV
* Haar Cascade Classifier

---

## 📂 Project Structure

frontend/
├── lib/
│ ├── screens/
│ ├── services/
│ ├── providers/
│ └── main.dart

backend/
├── AdaptIQ/
│ ├── views.py
│ ├── models.py
│ ├── urls.py
│ └── admin.py
└── manage.py

---

## 🔑 Key Learning Outcomes

* Mobile application development with Flutter
* REST API development using Django
* JWT authentication implementation
* Database design with PostgreSQL
* Adaptive learning algorithms
* OpenCV integration for monitoring

---

## 🔮 Future Improvements

* AI-powered adaptive learning
* MediaPipe-based monitoring
* Cloud deployment
* Advanced analytics dashboard
* Leaderboard system

---

## 👨‍💻 Author

**Nirupam Aryal**

Final Year Project – BSc (Hons) Computing

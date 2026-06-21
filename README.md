# 🎯 Agesense – Real-time Age & Gender Prediction

**Agesense** is a Flutter-powered mobile application that performs **real-time age and gender prediction** directly from your device's camera stream. Using cutting-edge on-device machine learning, it analyzes faces frame-by-frame as they appear in the live preview — delivering instant, continuous predictions without network latency.

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 📹 **Real-time Detection** | Continuous analysis of the live camera feed, processing frames on-the-fly |
| 🧠 **On-Device ML Inference** | TFLite models run locally – no internet required, full privacy preserved |
| 🔄 **Multi-Face Support** | Detects and analyzes multiple faces simultaneously in a single frame |
| 📸 **Gallery Analysis** | Pick images from your gallery for static analysis |
| 💾 **History & Persistence** | Saves predictions to local SQLite database with image storage |
| 🔐 **User Authentication** | Firebase Auth with Email/Password and Google Sign-In support |
| 🌙 **Dark Mode** | Fully themed dark/light mode support |
| 🌍 **Localization** | Multi-language support via Flutter Localizations |

---

## 🔬 How It Works

Agesense employs a sophisticated real-time processing pipeline that bridges the camera hardware, face detection, and machine learning inference layers.

### 1. 📷 Camera Analysis Pipeline

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      REAL-TIME PROCESSING FLOW                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Camera Stream ──► Frame Capture ──► Face Detection ──► ML Inference  │
│        │                  │                 │                  │        │
│        ▼                  ▼                 ▼                  ▼        │
│   30+ FPS           YUV/BGRA          MLKit Faces      Age & Gender    │
│   Preview           Raw Bytes         Bounding Box     Predictions      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Frame Capture & Streaming:**
- The `camera` package provides raw image streams via `startImageStream()`
- Each frame arrives as a `CameraImage` containing YUV420 or BGRA8888 plane data
- Frames are processed asynchronously to maintain UI responsiveness
- A throttle mechanism ensures balanced CPU usage without frame drops

**Coordinate Transformation:**
- Raw face coordinates from the detector are transformed to match the screen preview
- Handles sensor orientation, camera mirroring (front vs. back), and aspect ratio scaling
- The `_mapRectToScreen()` function performs `BoxFit.cover` calculations for accurate overlay positioning

### 2. 👤 Face Detection (Google ML Kit)

```dart
// Face detector configured for real-time performance
FaceDetector(
  options: FaceDetectorOptions(
    performanceMode: FaceDetectorMode.fast,
    enableLandmarks: false,
    enableContours: false,
  ),
)
```

- **Engine:** `google_mlkit_face_detection` — Google's on-device ML Kit
- **Performance Mode:** Optimized for speed over accuracy for smooth real-time UX
- **Output:** Bounding box coordinates (`Rect`) for each detected face
- **Multi-face:** Handles multiple faces per frame simultaneously

### 3. 🧠 TFLite Model Integration

Agesense uses two custom TensorFlow Lite models for inference:

| Model | Input | Output | File |
|-------|-------|--------|------|
| **Age Model** | 200×200 RGB normalized | Age value (0-100+) | `assets/age_model.tflite` |
| **Gender Model** | 128×128 RGB normalized | Binary classification | `assets/gender_model.tflite` |

**Inference Pipeline:**

1. **Face Cropping:** Extract the face region from the full frame using bounding box coordinates
2. **Preprocessing:** Resize to model input dimensions, normalize pixel values to `[0, 1]` range
3. **Isolate Processing:** Heavy computation offloaded via `compute()` for background thread execution
4. **Inference:** TFLite interpreter runs forward pass on preprocessed tensor
5. **Post-processing:** Extract predictions and format for UI display

```dart
// Simplified inference flow
final faceImage = cropFaceFromFrame(frame, boundingBox);
final resized = img.copyResize(faceImage, width: 200, height: 200);
final input = normalizePixels(resized);
_ageInterpreter.run([input], output);
```

### 4. 🖼️ Real-time UI Rendering

- **FacePainter:** Custom `CustomPainter` draws bounding boxes and labels over the camera preview
- **Stack Layout:** Camera preview sits beneath a transparent overlay layer
- **Continuous Updates:** `setState()` triggers UI refresh with each new prediction batch
- **Smooth Experience:** Async processing prevents UI jank during heavy inference

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.10+ (Dart) |
| **Face Detection** | `google_mlkit_face_detection` ^0.11.0 |
| **ML Inference** | `tflite_flutter` ^0.11.0 |
| **Camera** | `camera` ^0.10.5 |
| **Image Processing** | `image` ^4.1.3 |
| **State Management** | `provider` ^6.1.1 |
| **Local Database** | `sqflite` ^2.3.0 |
| **Authentication** | Firebase Auth + Google Sign-In |
| **Cloud Storage** | Firebase Storage |
| **Persistence** | `shared_preferences` ^2.2.2 |

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point & Firebase init
├── camera_analysis_screen.dart  # Core real-time analysis engine
├── face_painter.dart            # Custom painter for bounding boxes
├── home_screen.dart             # Main navigation hub
├── history_screen.dart          # Past predictions browser
├── analysis_details_screen.dart # Detailed prediction view
├── core/
│   ├── database_helper.dart     # SQLite operations
│   └── image_isolate_processor.dart # Background processing
├── providers/
│   └── history_provider.dart    # State management for history
├── services/
│   └── auth_service.dart        # Firebase authentication
├── settings/                    # App settings & preferences
└── widgets/                     # Reusable UI components
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Android Studio / Xcode
- Firebase project configured

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd flutter_application_1

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add Android/iOS apps and download config files
3. Place `google-services.json` in `android/app/`
4. Place `GoogleService-Info.plist` in `ios/Runner/`

---

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| Android | ✅ Fully Supported |
| iOS | ✅ Fully Supported |

---

## 🔒 Privacy

All machine learning inference happens **entirely on-device**. No facial data, images, or biometric information ever leaves your phone. Your privacy is fully preserved.

---

## 📄 License

This project is private and not published to pub.dev.

---

<p align="center">
  Made with ❤️ using Flutter
</p>
# AgesenesV3

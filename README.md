# 🩺 Smart Health Tracker

<div align="center">

[![Flutter Version](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-blue?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-%3E%3D3.3.0-blue?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/priyanshi-devOps11/Smart-Health-Tracker/pulls)

**A comprehensive, cross-platform Flutter application for tracking and monitoring vital health metrics with beautiful Material 3 design.**

[Features](#-features) • [Demo](#-demo) • [Installation](#-installation) • [Tech Stack](#-tech-stack) • [Contributing](#-contributing)

</div>

---

## 📱 Demo

<div align="center">

| Home Screen | Water Tracking | Sleep Tracker |
|:-----------:|:--------------:|:-------------:|
| ![Home](https://github.com/priyanshi-devOps11/Smart-Health-Tracker/blob/main/demo_video/Screenshot_20251227_001235.jpg) | ![Water](https://github.com/priyanshi-devOps11/Smart-Health-Tracker/blob/main/demo_video/Screenshot_20251227_001316.jpg) | ![Sleep](https://github.com/priyanshi-devOps11/Smart-Health-Tracker/blob/main/demo_video/Screenshot_20251227_001330.jpg) |

### 🎥 [Watch Full Demo Video](https://github.com/priyanshi-devOps11/Smart-Health-Tracker/blob/main/demo_video/demo_video_sr.mp4)

### 🌐 [Try Live Web Demo](https://smart-health-tracker-mvp.web.app)

</div>

---

## ✨ Features

### Health Tracking
- **👣 Step Tracker** — Real-time step counting with daily goals and calorie calculation
- **❤️ Heart Rate Monitor** — Camera-based BPM detection with visual pulse animation
- **💧 Water Tracker** — Beautiful water bottle animation with hydration reminders
- **😴 Sleep Monitor** — Track sleep sessions with bedtime scheduling and analytics
- **⚖️ BMI Calculator** — Instant calculation with health category and personalized tips

### UI/UX
- Modern Material 3 Design with gradient backgrounds
- Smooth animations and transitions
- Fully responsive layout for all screen sizes
- Interactive charts with fl_chart library
- Color-coded health status indicators

### Data & Analytics
- Weekly trend visualization with interactive charts
- Persistent local data storage
- Progress tracking for all metrics
- Custom notification reminders

---

## 🛠 Tech Stack

### Core
```yaml
Framework:  Flutter 3.3.0+
Language:   Dart 3.3.0+
```

### Key Dependencies
```yaml
# Sensors & Hardware
pedometer: ^4.0.1                      # Step counting
camera: ^0.10.5+5                      # Heart rate detection
permission_handler: ^11.0.1            # Runtime permissions

# Data & Storage
shared_preferences: ^2.2.2             # Local persistence

# UI & Charts
fl_chart: ^0.66.0                      # Analytics visualization

# Notifications
flutter_local_notifications: ^17.0.0   # Reminders
timezone: ^0.9.2                       # Timezone handling
```

---

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.3.0 or higher
- Dart SDK 3.3.0 or higher
- Android Studio / VS Code
- Physical device (recommended for sensor features)

### Quick Start

```bash
# Clone repository
git clone https://github.com/priyanshi-devOps11/Smart-Health-Tracker.git
cd Smart-Health-Tracker

# Install dependencies
flutter pub get

# Run application
flutter run
```

### Platform Setup

<details>
<summary><b>Android Configuration</b></summary>

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Permissions -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <application>
        <!-- Notification receivers -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" 
            android:exported="false" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```
</details>

<details>
<summary><b>iOS Configuration</b></summary>

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access required for heart rate monitoring</string>
<key>NSMotionUsageDescription</key>
<string>Motion access required for step tracking</string>
```
</details>

---

## 📂 Project Structure

```
lib/
├── main.dart                      # Application entry point
└── screens/
    ├── home_screen.dart           # Dashboard with navigation
    ├── step_tracker_screen.dart   # Step counting & analytics
    ├── water_tracker_screen.dart  # Hydration tracking
    ├── sleep_tracker_screen.dart  # Sleep monitoring
    ├── heart_rate_screen.dart     # Heart rate detection
    └── bmi_screen.dart            # BMI calculation
```

---

## 🎯 Roadmap

- [x] Step tracking with pedometer sensor
- [x] Camera-based heart rate detection
- [x] Water intake logging with reminders
- [x] Sleep session tracking
- [x] BMI calculator with health tips
- [x] Weekly analytics charts
- [ ] Cloud sync with Firebase
- [ ] Dark mode theme
- [ ] Export data (PDF/CSV)
- [ ] Social challenges
- [ ] Workout routines
- [ ] Meal tracking

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please ensure your code follows Flutter best practices and includes appropriate documentation.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
Copyright (c) 2026 Priyanshi Srivastava

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 👩‍💻 Author

**Priyanshi Srivastava**

[![GitHub](https://img.shields.io/badge/GitHub-priyanshi--devOps11-181717?logo=github)](https://github.com/priyanshi-devOps11)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Priyanshi_Srivastava-0077B5?logo=linkedin)](https://www.linkedin.com/in/priyanshi-srivastava8119/)
[![Email](https://img.shields.io/badge/Email-srivastavapriyanshi8081-D14836?logo=gmail)](mailto:srivastavapriyanshi8081@gmail.com)

---

## ⭐ Support

If this project helped you, please consider giving it a ⭐️!

<div align="center">

**Made with ❤️ and Flutter**

[⬆ Back to Top](#-smart-health-tracker)

</div>

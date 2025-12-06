# SnapFix - Civic Complaint Management App

Transform your city into a smarter, more responsive community. SnapFix empowers citizens to report civic issues instantly with photos, GPS location, and real-time tracking.

## Why SnapFix?

In today's fast-paced urban landscape, civic issues like potholes, broken streetlights, and waste management problems often go unreported or untracked. SnapFix bridges the gap between citizens and local authorities with a seamless mobile experience.

**Key Highlights:**
- **Instant Reporting**: Snap a photo, add location, and submit complaints in seconds
- **Real-Time GPS**: Automatic location capture with interactive map visualization
- **Smart Image Storage**: Cloud-powered image management with Supabase Storage
- **Complete Transparency**: Track complaint status from submission to resolution
- **User-Friendly**: Intuitive Material Design UI with smooth animations
- **Secure Authentication**: JWT-based user authentication system

## Features

### For Citizens
- **Quick Complaint Submission**: Camera integration for instant photo capture
- **Auto-Location Detection**: GPS-powered precise location tagging
- **Complaint History**: View all your submitted complaints with status updates
- **Status Tracking**: Monitor complaints through Pending → Approved → Rejected workflow
- **Secure Login**: Email/password authentication with token management

### Technical Excellence
- **Modern Architecture**: Clean code with service-layer separation
- **State Management**: Efficient Flutter state handling
- **Cloud Storage**: Supabase integration for scalable image storage
- **RESTful API**: FastAPI backend with comprehensive endpoints
- **Responsive Design**: Adaptive layouts for all screen sizes
- **Error Handling**: Robust validation and user feedback

## Tech Stack

- **Framework**: Flutter 3.x with Dart
- **State Management**: Provider pattern
- **Backend**: FastAPI (Python)
- **Database**: PostgreSQL
- **Storage**: Supabase Storage
- **Authentication**: JWT tokens
- **Maps**: Google Maps / OpenStreetMap integration
- **Image Handling**: image_picker package
- **HTTP Client**: http package with custom service layer

## Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart 2.19 or higher
- Android Studio / VS Code
- Active internet connection

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rishithayanidhi/Snapfix_Frontend.git
cd Snapfix_Frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your API endpoints and credentials
```

4. Run the app:
```bash
flutter run
```

## Environment Configuration

Create a `.env` file with:
```env
API_BASE_URL=https://your-backend-url.com
DEBUG=false
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_BUCKET=complaint-images
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── auth.dart              # Authentication service
├── home.dart              # Home screen with complaint form
├── history.dart           # Complaint history view
├── complaint_service.dart # API integration layer
└── location_service.dart  # GPS and location handling
```

## API Integration

The app communicates with a production-ready FastAPI backend:
- User registration and authentication
- Complaint submission with image upload
- Real-time status updates
- Complaint history retrieval
- Secure token-based authorization

## Screenshots

| Feature | Description |
|---------|-------------|
| Login Screen | Secure authentication with email/password |
| Complaint Form | Quick submission with photo and location |
| Map View | Interactive location selection |
| History | Track all your submitted complaints |

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

The built APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

## Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Roadmap

- [ ] Dark mode support
- [ ] Multi-language support
- [ ] Push notifications for status updates
- [ ] Complaint categories with icons
- [ ] Community voting on complaints
- [ ] Admin mobile interface
- [ ] Offline mode with sync

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Flutter and love for civic engagement
- Powered by Supabase for scalable storage
- Inspired by the need for better city management

## Contact

**Project Maintainer**: Rishitha Yanidhi

**Backend Repository**: [Snapfix_backend](https://github.com/rishithayanidhi/Snapfix_backend)

**Admin Dashboard**: [snapfix_admin](https://github.com/rishithayanidhi/snapfix_admin)

---

Made with ❤️ for smarter cities and empowered citizens

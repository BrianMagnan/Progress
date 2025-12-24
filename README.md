# Progress - Skill Tracking App

A Flutter-based skill tracking application that helps you organize and track your learning progress across different categories, skills, and goals.

## Features

- **Hierarchical Organization**: Organize your learning into Categories → Skills → Sub-Skills → Goals
- **Progress Logging**: Track your practice sessions with notes, duration, and attachments
- **Context Recovery**: Quick access to your last session summary for each goal
- **Drag & Drop Reordering**: Easily rearrange categories to match your priorities
- **Persistent Storage**: Data persists across browser sessions using Hive/IndexedDB
- **Material 3 Design**: Beautiful, modern UI with light and dark theme support

## Tech Stack

- **Flutter**: Cross-platform framework
- **Hive**: Local database with IndexedDB support for web
- **Material 3**: Modern design system

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Chrome browser (for web development)

### Installation

1. Clone the repository:

```bash
git clone <your-repo-url>
cd Progress/progress
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run -d chrome --web-port=5555
```

Or use the provided script:

```bash
./run_web.sh
```

## Project Structure

```
progress/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   ├── category.dart
│   │   ├── skill.dart
│   │   ├── sub_skill.dart
│   │   ├── goal.dart
│   │   └── progress_log.dart
│   ├── screens/               # UI screens
│   │   ├── home_screen.dart
│   │   ├── categories_screen.dart
│   │   ├── skills_screen.dart
│   │   ├── sub_skills_screen.dart
│   │   ├── goals_screen.dart
│   │   └── goal_detail_screen.dart
│   ├── services/              # Business logic
│   │   └── database_service.dart
│   ├── theme/                 # App theming
│   │   └── app_theme.dart
│   └── utils/                 # Utilities
│       └── helpers.dart
└── web/                       # Web-specific files
```

## Data Model

The app uses a hierarchical structure:

- **Category**: Broad areas (e.g., Art, Music, Coding)
- **Skill**: Within a category (e.g., Drawing, Web Development)
- **Sub-Skill**: Within a skill (e.g., Anatomy, Algorithms)
- **Goal**: Actionable learning targets
- **Progress Log**: Session records with notes, duration, and attachments

## Development Notes

- The app uses a fixed port (5555) for web development to ensure IndexedDB persistence
- Data is stored locally in the browser using IndexedDB
- Hot reload works for most changes, but full restart may be needed for initialization changes

## License

[Add your license here]

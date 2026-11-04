# My Todo List

A feature-rich and responsive Flutter Todo application designed to make everyday task management simple, organized, and productive. Built with Firebase Authentication and Cloud Firestore, the application provides secure user access, cloud-based task synchronization, productivity tracking, and a visually engaging user interface.

## Features

### Authentication and Cloud Storage
- **Firebase Authentication:** Secure user registration and login.
- **Cloud Firestore:** Store and synchronize user-specific tasks in the cloud.
- **User-specific Data:** Keep each user's tasks securely separated.
- **Cloud Synchronization:** Access task data across supported platforms.

### Task Management
- **Task Operations:** Create, edit, delete, pin, and complete tasks.
- **Priority Management:** Organize tasks by Low, Medium, and High priority.
- **Task Categories:** Classify tasks into Work, Study, Personal, Health, Finance, and Other.
- **Smart Filtering:** Filter tasks by status, priority, due date, and completion.
- **Recurring Tasks:** Manage daily, weekly, and monthly recurring tasks.
- **Subtasks:** Break larger tasks into smaller, manageable activities.
- **Time Tracking:** Track the time spent on individual tasks.

### Productivity and Notifications
- **Task Reminders:** Receive notifications for scheduled tasks.
- **Daily Productivity Summary:** Stay informed about daily task progress.
- **Insights and Analytics:** Monitor task completion and productivity trends.
- **Progress Tracking:** View completed, pending, overdue, and pinned tasks.

### User Interface and Experience
- **Bioluminescent Background:** Ocean-inspired visuals featuring glowing plankton and jellyfish.
- **Animated Background Effects:** Subtle floating bubble animations.
- **Authentication Interface:** Custom-designed login and registration screens.
- **Responsive Layout:** Adaptable interface for different screen sizes.
- **Reusable Widgets:** Organized and reusable UI components.
- **Material Design 3:** Modern Flutter interface with a clean visual experience.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database and synchronization |
| Provider | State management |
| SharedPreferences | Local preference storage |
| Flutter Local Notifications | Task reminders and notifications |
| Video Player | Animated video backgrounds |

## Project Structure

```text
todoapp/
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── firebase_options.dart
│   │
│   ├── assets/
│   │   ├── images/
│   │   │   └── bioluminescent_plankton.jpeg
│   │   └── videos/
│   │       └── pink_sparkling_water.mp4
│   │
│   ├── models/
│   │   └── todo.dart
│   │
│   ├── painters/
│   │   └── pie_painter.dart
│   │
│   ├── providers/
│   │   └── todo_provider.dart
│   │
│   ├── screens/
│   │   ├── auth_screen.dart
│   │   ├── calender_page.dart
│   │   ├── insights_page.dart
│   │   └── todo_screen.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_todo_service.dart
│   │   ├── notification_service.dart
│   │   └── shared_preferences_services.dart
│   │
│   ├── utils/
│   │   ├── constants.dart
│   │   └── todo_utils.dart
│   │
│   └── widgets/
│       ├── animated_card.dart
│       ├── common_widgets.dart
│       ├── task_card.dart
│       ├── task_form.dart
│       └── video_background.dart
│
└── test/
    └── widget_test.dart


## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Firebase account
- Git

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/angela2002thommana-ship-it/todoapp.git
   ```

2. Navigate to the project directory:

   ```bash
   cd todoapp
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Configure Firebase for your own Firebase project using FlutterFire CLI:

   ```bash
   flutterfire configure
   ```

5. Run the application:

   ```bash
   flutter run
   ```

**Note:** Configure Firebase Authentication and Cloud Firestore in your Firebase project before running the application. The generated `firebase_options.dart` must correspond to your Firebase project.

## Project Objective

To develop a practical, secure, and user-friendly productivity application that simplifies everyday task management. The application combines task organization, reminders, recurring activities, time tracking, cloud synchronization, and productivity insights within a visually engaging and responsive interface.

## Author

Developed as a Flutter application project.
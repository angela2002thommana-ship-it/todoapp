# My Todo List

A feature-rich, responsive Todo application built using **Flutter and Dart**, with Firebase Authentication, Cloud Firestore, REST API integration, task management, reminders, time tracking, and productivity insights.

The application provides a user-friendly interface with an ocean-inspired visual design and supports both Android and Web platforms.

---

## Features

### 1. User Authentication
- User registration and login using Firebase Authentication.
- Email and password authentication.
- Secure user-specific access.
- Sign-out functionality.

### 2. Cloud Database and Synchronization
- Firebase Cloud Firestore integration.
- Store and retrieve user-specific tasks.
- Synchronize task data with the cloud.
- Organize tasks under individual user accounts.
- SharedPreferences support for local storage.

### 3. Task Management
- Create, edit, and delete tasks.
- Mark tasks as completed or pending.
- Pin important tasks.
- Set task priorities:
  - Low
  - Medium
  - High
- Organize tasks using categories:
  - Work
  - Study
  - Personal
  - Health
  - Finance
  - Other

### 4. Task Filtering and Sorting
- Filter tasks based on completion status.
- Filter by priority.
- View important and pinned tasks.
- Identify overdue and today's tasks.
- Sort tasks by:
  - Smart sorting
  - Due date
  - Priority
  - Alphabetical order
  - Newest first

### 5. Recurring Tasks and Subtasks
- Create recurring tasks.
- Supported repetition options:
  - Daily
  - Weekly
  - Monthly
- Add subtasks to organize larger activities.

### 6. Time Tracking
- Track time spent on individual tasks.
- Start and pause task timers.
- Maintain tracked time.
- Record task completion information.

### 7. Notifications and Reminders
- Local notifications for task reminders.
- Schedule reminders for tasks.
- Daily productivity summaries.

### 8. API Tasks
A separate API Tasks screen provides task management through the Firestore REST API.

Supported operations:
- **GET:** Retrieve tasks.
- **POST:** Create new tasks.
- **PATCH:** Update existing tasks.
- **DELETE:** Delete tasks.

Additional functionality:
- Create and edit tasks through dialogs.
- Delete tasks with confirmation.
- Mark tasks as completed.
- Pin and mark tasks as important.
- Filter tasks by status and priority.
- Sort tasks by newest, alphabetical order, and priority.
- Refresh task data.
- Display loading, empty, and error states.
- Handle API errors with user-friendly messages.

### 9. Productivity Insights
- View completed tasks.
- Track pending and overdue tasks.
- Monitor pinned tasks.
- View productivity progress.
- Analyze task completion statistics.

### 10. User Interface
- Ocean-inspired visual theme.
- Bioluminescent plankton background image.
- Animated water background video.
- Floating bubble animations.
- Custom login and registration interface.
- Responsive layouts for different screen sizes.
- Reusable widgets.
- Material Design 3.

---

## 11. Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Firestore REST API | API-based task operations |
| Provider | State management |
| SharedPreferences | Local data storage |
| Flutter Local Notifications | Task reminders |
| Video Player | Background video playback |
| Material Design 3 | User interface design |

---

### 12. Firebase Setup

In the Firebase Console:

1. Enable Email/Password authentication under Authentication.
2. Create a Cloud Firestore database.
3. Configure Firestore security rules to restrict access to each user's data.
4. Ensure the Firebase configuration matches the application.

The application's user-specific task data is stored under:

```text
users/
   └── {uid}/
       └── todos/
           └── {todoId}
```


## 13. Application Objective

The objective of this project is to develop a practical and secure productivity application that helps users organize daily activities, manage tasks, track time, receive reminders, and monitor their productivity.

By combining Flutter, Firebase, REST API integration, and Provider state management, the application demonstrates the implementation of modern cross-platform application development concepts.

---

## 14. Author

Developed as a Flutter application project.
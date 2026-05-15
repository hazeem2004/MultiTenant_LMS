# DevCohort LMS (Multi-Tenant Learning Management System)

DevCohort is a modern, mobile-first Learning Management System built with **Flutter** and **Firebase**. It is designed for independent coding bootcamps and academies to manage multi-tenant classrooms, curriculum, and student feedback loops with ease.

---

## 🚀 User Workflows

### 👨‍🏫 Instructor (Teacher) Workflow
The Instructor is the primary content creator and manager of the classroom.

1.  **Onboarding & Login**:
    *   Sign in securely via **GitHub OAuth**.
    *   System automatically identifies the user as an `instructor` (or sets default role).
2.  **Classroom Setup**:
    *   **Create a Cohort**: Define a new batch (e.g., "Fullstack Web Dev - Winter 2024").
    *   **Curriculum Building**: Add "Weeks" and "Assignments" to the cohort.
    *   **Markdown Support**: Write rich assignment descriptions using GitHub-flavored Markdown.
3.  **Student Enrollment**:
    *   **Generate Invite Tokens**: Create secure, time-limited TTL (Time-To-Live) tokens for students.
    *   **Share Links**: Distribute the invite link/token to students for secure self-enrollment.
4.  **Grading & Feedback**:
    *   **Review Matrix**: View a grid of all student submissions for each assignment.
    *   **Interactive Feedback**: Open a submission to view GitHub/Live links and leave comments.
    *   **Grading**: Assign grades (e.g., "Pass", "Redo", "Excellent") which sync in real-time.

### 👨‍🎓 Student Workflow
The Student focuses on learning and submission tracking across multiple enrolled cohorts.

1.  **Onboarding & Enrollment**:
    *   Sign in via **GitHub OAuth**.
    *   **Join Cohort**: Enter an invite token provided by the instructor to instantly join a classroom.
    *   **Multi-Cohort Support**: Students can switch between different bootcamps or classes they are enrolled in.
2.  **Learning & Progress**:
    *   **Dashboard View**: See the current week's assignments and curriculum progress.
    *   **Assignment Details**: Read assignment instructions rendered in Markdown.
3.  **Submission**:
    *   **Hand-in Work**: Submit assignments by providing GitHub repository URLs and Live Demo links.
    *   **Submission Status**: Track whether a submission is "Pending", "Reviewed", or needs "Revision".
4.  **Notifications**:
    *   Receive real-time push notifications (FCM) when an instructor grades an assignment or leaves feedback.

### 🔑 Admin (Planned)
The Admin role is designed for institutional management.
*   **User Management**: Monitor instructor activity and platform-wide enrollment stats.
*   **Global Settings**: Manage multi-tenant configurations and high-level platform branding.

---

## 🛠 Technical Stack
*   **Frontend**: Flutter (Web, Android, iOS)
*   **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
*   **State Management**: Riverpod (AsyncNotifier, Provider)
*   **Architecture**: Layered architecture (Presentation, Application, Domain, Data)
*   **Security**: Firestore Security Rules for data isolation and TTL-based enrollment.

---

## 🏗 Setup & Installation
1.  **Clone the Repo**: `git clone ...`
2.  **Install Dependencies**: `flutter pub get`
3.  **Firebase Config**: 
    *   Run `flutterfire configure` to link your Firebase project.
    *   Enable **GitHub Auth** in the Firebase Console.
    *   Create a **Firestore Database** in the Firebase Console.
4.  **Run the App**: `flutter run -d chrome`

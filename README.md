# DevCohort LMS 🚀
### A Powerful, Multi-Tenant Learning Management System


DevCohort is a professional-grade Learning Management System built with **Flutter** and **Firebase**. It provides a robust "Teaching Engine" for instructors and a "God Mode" for administrators to manage large-scale coding bootcamps and educational cohorts.

---

## ✨ Key Features

### 🛡️ Admin "God Mode"
*   **Approval System**: Secure registration with a strict Admin Approval flow.
*   **User Management**: Instant role reassignment and approval toggles via interactive DataTables.
*   **System Analytics**: Real-time aggregation of active cohorts, students, and instructor distribution.
*   **Platform Overview**: High-level visualization of system performance using `fl_chart`.

### 👨‍🏫 Instructor "Teaching Engine"
*   **Curriculum Management**: Build multi-week syllabuses with rich Markdown assignments.
*   **Assignment Templates**: Upload template files and boilerplate code directly to Firebase Storage.
*   **Attendance Tracking**: Daily digital roll calls with persistent records in Firestore.
*   **Performance Analytics**: Visualize student success with average grade bar charts and completion pie charts.
*   **Cohort Security**: Dynamic join codes with manual regeneration and expiration settings.

### 👨‍🎓 Student Dashboard
*   **Unified View**: Track assignments, deadlines, and grades across multiple enrolled cohorts.
*   **Submission Pipeline**: Submit GitHub repositories, live demos, and file attachments.
*   **Real-time Feedback**: Receive grading updates and instructor comments instantly.

---

## 🛠 Tech Stack
*   **Frontend**: Flutter 3.x (Web, Android, iOS)
*   **State Management**: Riverpod 3.0 (AsyncNotifier Pattern)
*   **Backend**: Firebase (Auth, Firestore, Storage)
*   **Analytics**: `fl_chart`
*   **Styling**: Material 3 with Premium Custom Theming

---

## 🚀 Setup & Installation

### Prerequisites
*   Flutter SDK installed
*   Firebase CLI installed

### Steps
1.  **Clone the Repository**
    ```powershell
    git clone https://github.com/hazeem2004/MultiTenant_LMS.git
    cd MultiTenant_LMS
    ```

2.  **Install Dependencies**
    ```powershell
    flutter pub get
    ```

3.  **Firebase Configuration**
    *   Initialize Firebase in the project: `flutterfire configure`
    *   Enable **Email/Password** Auth in Firebase Console.
    *   Create a **Firestore** database and **Storage** bucket.
    *   Apply Firestore Rules (see `firestore.rules` in repo).

4.  **Run the Application**
    ```powershell
    flutter run -d chrome
    ```

---

## 📸 Demo
*Check out the latest Instructor Dashboard walkthrough:*
(https://drive.google.com/file/d/1JoPMrjCGiIEtVoinojJDTOBznsxBfwHo/view?usp=drivesdk)

---

## 📄 License
Internal use for DevCohort Academies.

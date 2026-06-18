# Project Progress Dashboard: Secured Mobile Telemedicine Platform

## Academic Information
* **Project Title:** Design and Implementation of a Secured Mobile Telemedicine Platform
* **Student Name:** ABILATEZIE VIN-WILSON ANU
* **Matriculation Number:** FE22A132
* **Department:** Department of Computer Engineering, Faculty of Engineering and Technology (FET)
* **Institution:** University of Buea, Cameroon
* **Supervisor:** Prof. ELIE FUTE T.
* **Academic Year:** 2025/2026

---

## 📊 Statistics Dashboard

| Metric | Status / Value |
| :--- | :--- |
| **Overall Project Progress** | **46%** |
| **Completed Modules / Phases** | **4 / 9** |
| **Completed Features** | **27 / 59** |
| **Open Issues / Blockers** | **2** |
| **Current Git Branch** | `feature/auth` |
| **Last Merged Feature** | `feat: add authentication module structure` (`fa50069`) |

```mermaid
gantt
    title Telemedicine Platform Project Timeline
    dateFormat  YYYY-MM-DD
    section Completed
    Phase 1: Project Foundation        :done, des1, 2026-05-20, 2026-05-23
    Phase 2: Authentication Module     :done, des2, 2026-05-24, 2026-05-28
    Phase 3: Healthcare Verification    :done, des3, 2026-05-29, 2026-06-05
    section Current/Future
    Phase 4: Appointment Management    :active, des4, 2026-06-08, 2026-06-12
    Phase 5: Video Consultation        :after des4, 5d
    Phase 6: Medical Records           : 4d
    Phase 7: Admin Dashboard           : 3d
    Phase 8: Security & Polish         : 5d
    Phase 9: Testing & Documentation   : 5d
```

---

## 🛠️ Technology Stack

* **Frontend Framework:** Flutter (Dart SDK ^3.11.4)
* **State Management:** Riverpod (`flutter_riverpod` ^3.3.1)
* **Routing & Navigation:** GoRouter (`go_router` ^17.2.3)
* **Authentication:** Firebase Authentication (`firebase_auth` ^6.5.1)
* **Database / Backend:** Cloud Firestore (`cloud_firestore` ^6.4.1)
* **Push Notifications:** Firebase Cloud Messaging
* **Media & Cloud Storage:** Cloudinary (`cloudinary_public` ^0.23.1) & Firebase Storage (`firebase_storage` ^13.4.1)
* **Video Consultation:** Jitsi Meet SDK
* **Network & Utilities:** Dio, Flutter Secure Storage, Connectivity Plus, Image Picker

---

## 📌 Project Overview
This project targets the development of a secured, cross-platform mobile telemedicine application designed for low-bandwidth environments in Cameroon. By integrating verified doctor credentials via an admin review workflow, dynamically routing traffic, and utilizing the lightweight Jitsi Meet SDK, the platform guarantees private, authentic, and fast virtual consultations between patients and certified healthcare practitioners.

---

## 🗺️ Implementation Roadmap

### Phase 1 — Project Foundation
* **Objectives:** Establish the core project structure, state management patterns, environment handling, routing, and Firebase connectivity.
* **Features:**
  * Initialize Flutter project with clean, feature-first architecture `[x]`
  - Setup GitHub repository and branching workflow `[x]`
  - Configure environment files (`.env`) and dotenv loader `[x]`
  - Setup base styling and Material 3 theme in `app_theme.dart` `[x]`
  - Configure `GoRouter` for routes and root paths `[x]`
  - Integrate Firebase Core and Firestore configuration `[x]`
* **Deliverables:**
  - Initialized Flutter codebase `[x]`
  - Connected Firebase projects `[x]`
  - Base UI components (`custom_button`, `custom_textfield`, `loading_indicator`) `[x]`
  - Setup routing module `[x]`
* **Acceptance Criteria:**
  - App compiles on target platforms `[x]`
  - Firebase initializes successfully on app startup `[x]`
  - Environment variables load correctly `[x]`
  - Routing handles transitions between Splash, Login, and Home `[x]`
* **Progress:** 100%
* **Completion Status:** Completed

---

### Phase 2 — Authentication Module
* **Objectives:** Build a secure email/password authentication flow with role-based routing (patient, doctor, admin) and access controls.
* **Features:**
  - Firebase Authentication integration `[x]`
  - User registration logic `[x]`
  - User login logic `[x]`
  - Forgot password (password reset email) `[x]`
  - Session persistence configuration `[x]`
  - User profile creation on Firestore `[x]`
  - User role storage (`patient`, `doctor`, `admin`) `[x]`
  - Login screen implementation `[x]`
  - Registration screen with role selection `[x]`
  - Forgot password screen `[x]`
  - Auth state change notifier `[x]`
  - Route guards to restrict unauthenticated access `[x]`
* **Deliverables:**
  - Working Auth views and text inputs `[x]`
  - User profiles saved in Firestore collection `/users` `[x]`
  - Riverpod auth notifier state machine `[x]`
* **Acceptance Criteria:**
  - Users can sign up, login, and reset password `[x]`
  - Authenticated sessions persist across app restarts `[x]`
  - Role-based properties are written correctly to user documents `[x]`
  - Unauthenticated users are redirected to login `[x]`
* **Progress:** 100%
* **Completion Status:** Completed

---

### Phase 3 — Healthcare Professional Verification
* **Objectives:** Design a document submission and approval workflow for doctors to ensure only certified practitioners consult on the app.
* **Features:**
  - Upload National ID document `[x]`
  - Upload Medical License document `[x]`
  - Cloudinary service integration `[x]`
  - Verification request creation in Firestore `/verification_requests` `[x]`
  - Real-time verification status monitoring (`pending`, `verified`, `rejected`) `[x]`
  - Restrict unverified doctors from accessing core app features via router guard `[x]`
  - Admin pending requests list view `[x]`
  - Verification review screen with image/document viewer `[x]`
  - Request approval workflow (updates status to 'approved' and updates user status) `[x]`
  - Request rejection workflow with custom reason text field `[x]`
* **Deliverables:**
  - Cloudinary upload service `[x]`
  - Submissions screen for doctors `[x]`
  - Verification review screen for admin `[x]`
  - Security route guards blocking unverified doctors `[x]`
* **Acceptance Criteria:**
  - Doctors can pick and upload national ID and license images `[x]`
  - Uploaded files are hosted on Cloudinary and urls saved to Firestore `[x]`
  - Admin can view, approve, and reject requests in real time `[x]`
  - Verification status changes trigger immediate role changes and route redirections `[x]`
* **Progress:** 100%
* **Completion Status:** Completed

---

### Phase 4 — Appointment Management
* **Objectives:** Enable patients to find doctors and request bookings; doctors to manage requests.
* **Features:**
  - View list of verified doctors `[x]`
  - Request/book appointment (Firestore `/appointments`) `[x]`
  - Doctor dashboard to view incoming requests `[x]`
  - Approve appointment booking `[x]`
  - Reject appointment booking `[x]`
  - Real-time appointment status tracking (Pending, Approved, Rejected, Completed) `[x]`
  - Push notifications on status change `[ ]`
* **Deliverables:**
  - Doctor search & selection interface `[x]`
  - Booking form dialog `[x]`
  - Appointment list and status views `[x]`
  - Service for notification triggers `[ ]`
* **Acceptance Criteria:**
  - Patients can see list of verified doctors only `[x]`
  - Patients can create appointment requests `[x]`
  - Doctors receive real-time updates and can approve/reject `[x]`
  - Appointment states are updated atomically in Firestore `[x]`
* **Progress:** 85%
* **Completion Status:** Near completion (core booking and doctor-management flow implemented; reminder/FCM notification integration remains)

---

### Phase 5 — Video Consultation
* **Objectives:** Integrate Jitsi Meet SDK for high-quality video/audio consulting between doctor and patient.
* **Features:**
  - Jitsi Meet SDK integration in Flutter `[ ]`
  - Initiate/start consultation room from appointment `[ ]`
  - Join meeting interface for both parties `[ ]`
  - End meeting trigger and duration logging `[ ]`
  - Audio-only mode fallback `[ ]`
  - Consultation history log `[ ]`
* **Deliverables:**
  - Jitsi Meet integration wrapper `[ ]`
  - Active call UI overlay `[ ]`
  - Call logs collection `/consultations` in Firestore `[ ]`
* **Acceptance Criteria:**
  - Secure room names are generated dynamically using UUIDs `[ ]`
  - Users can join audio/video rooms with correct permissions `[ ]`
  - Graceful connection recovery and clean exit `[ ]`
  - Session metadata written to Firestore on call completion `[ ]`
* **Progress:** 0%
* **Completion Status:** Planned

---

### Phase 6 — Medical Records
* **Objectives:** Allow doctors to document diagnoses, treatment plans, and upload prescriptions securely.
* **Features:**
  - Medical record entry form for doctors `[ ]`
  - Write diagnosis and treatment plan details `[ ]`
  - Prescription upload to Cloudinary (image or PDF) `[ ]`
  - Secure Firestore metadata entry `/medical_records` `[ ]`
  - Patient personal health record viewing page `[ ]`
* **Deliverables:**
  - Record creation form UI `[ ]`
  - Medical records dashboard (separated by patient/doctor views) `[ ]`
  - Cloudinary secure storage paths for health documents `[ ]`
* **Acceptance Criteria:**
  - Doctors can create records only for their patients `[ ]`
  - Patients can view their own history but cannot edit records `[ ]`
  - Prescriptions are uploaded successfully and downloadable `[ ]`
* **Progress:** 0%
* **Completion Status:** Planned

---

### Phase 7 — Admin Dashboard
* **Objectives:** System-level administration, user management, and activity monitoring.
* **Features:**
  - Dashboard home with system statistics `[ ]`
  - User management (search, view details, suspend, reactivate users) `[ ]`
  - Activity monitoring and access logs `[ ]`
  - General analytics and system reports (total bookings, active consultations) `[ ]`
* **Deliverables:**
  - Admin-only home interface `[ ]`
  - User management sub-screens `[ ]`
  - System logs and analytics charts `[ ]`
* **Acceptance Criteria:**
  - Only users with role `admin` can load the dashboard `[ ]`
  - Admins can query and filter users by role and status `[ ]`
  - Admin actions (e.g., suspension) are applied immediately and securely `[ ]`
* **Progress:** 0%
* **Completion Status:** Planned

---

### Phase 8 — Security Hardening & Polish
* **Objectives:** Restrict database access via Firestore security rules, encrypt data, handle errors, and polish UI.
* **Features:**
  - Firestore Security Rules development and deployment `[ ]`
  - Secure Cloudinary access and upload restrictions `[ ]`
  - Field-level validation on all text fields `[ ]`
  - Universal error handling and network status notification `[ ]`
  - Responsive screen layouts for various screen sizes `[ ]`
  - App state loading skeleton screens `[ ]`
* **Deliverables:**
  - `firestore.rules` configuration file `[ ]`
  - Error catching wrappers for Firebase/Cloudinary service calls `[ ]`
  - Responsive layout helper class `[ ]`
* **Acceptance Criteria:**
  - All database reads/writes are blocked unless verified by security rules `[ ]`
  - Cloudinary folder credentials are obfuscated and secured `[ ]`
  - Dynamic responsiveness verified across multiple device profiles `[ ]`
* **Progress:** 0%
* **Completion Status:** Planned

---

### Phase 9 — Testing & Documentation
* **Objectives:** Code verification, validation for thesis Chapter 4 (evidence), and creation of project user manuals.
* **Features:**
  - Unit tests for repositories, models, and providers `[ ]`
  - Widget and Integration tests for routing and auth flows `[ ]`
  - User Acceptance Testing (UAT) documentation and sign-off `[ ]`
  - Complete application user guide with screenshots `[ ]`
  - Preparation of Chapter 4 implementation evidence `[ ]`
  - Final project presentation defense slides `[ ]`
* **Deliverables:**
  - Unit and integration test suite `[ ]`
  - User Guide PDF `[ ]`
  - Thesis Chapter 4 screenshots and logs `[ ]`
  - Project defense slide deck `[ ]`
* **Acceptance Criteria:**
  - All unit/widget tests pass successfully `[ ]`
  - Integration tests successfully emulate complete end-to-end user flows `[ ]`
  - All document deliverables match the university thesis formatting guidelines `[ ]`
* **Progress:** 0%
* **Completion Status:** Planned

---

## 📝 Detailed Feature Tracking

### 1. Project Foundation
- [x] Flutter project initialized (feature-first modular structure)
- [x] GitHub repository setup and branching strategy configured
- [x] Firebase integration configured (Core and Firestore options)
- [x] Directory structure setup (`core/`, `features/`, `routes/`)
- [x] Base styling and app typography defined in `app_theme.dart`
- [x] Environment configs configured (`.env` file loader via `flutter_dotenv`)
- [x] Base routing configured using `GoRouter` in `app_router.dart`

---

### 2. Authentication Module
#### Backend
- [x] Firebase Authentication configured
- [x] User registration logic implemented
- [x] User login logic implemented
- [x] Forgot password (reset link email) implemented
- [x] Session persistence configured (handled by Firebase Auth)
#### Database
- [x] User profile creation (saving profiles under Firestore `/users`)
- [x] Role storage (storing roles: `patient`, `doctor`, `admin`)
#### UI
- [x] Login screen (with validation, error messages, and loading state)
- [x] Registration screen (with role selection toggle)
- [x] Forgot password screen
#### Security
- [x] Route guards (protecting routes based on authenticated states)
- [x] Role-based access control (differentiating patient, doctor, and admin navigations)

---

### 3. Healthcare Professional Verification
- [x] Upload National ID (using file/image picker)
- [x] Upload Medical License
- [x] Cloudinary integration (unsigned preset uploads in `CloudinaryService`)
- [x] Verification request creation (Firestore collection `/verification_requests`)
- [x] Admin review (UI list screen for pending requests)
- [x] Approval workflow (batch updates: updates requests to `approved`, updates user status to `approved`)
- [x] Rejection workflow (batch updates: updates requests to `rejected`, records rejection reasons)
- [x] Verification status updates (real-time stream listeners for doctor interfaces)
- [x] Restrict unverified doctors (GoRouter guard redirecting unverified doctors to `/verification-status`)

---

### 4. Appointments Module
- [4] View verified doctors list
- [4] Book appointment
- [4] Approve appointment booking
- [4] Reject appointment booking
- [4] Appointment status tracking (Pending, Approved, Rejected, Completed)
- [ ] Notifications integration (FCM) on status changes

---

### 5. Video Consultation Module
- [ ] Jitsi Meet SDK integration in Flutter
- [ ] Initiate/Start consultation room
- [ ] Join meeting (dynamic token generation / room names)
- [ ] End meeting workflow (cleans resources, terminates calls)
- [ ] Audio-only fallback mode
- [ ] Consultation history log (storing duration, timestamps, and doctor-patient details)

---

### 6. Medical Records Module
- [ ] Create record form
- [ ] Add diagnosis
- [ ] Add treatment plan
- [ ] Prescription upload (to Cloudinary)
- [ ] Patient medical record viewing screen

---

### 7. Admin Dashboard Module
- [ ] Verification request management (Admin review, approvals, rejections)
- [ ] User management (View profiles, search, suspend/activate accounts)
- [ ] Activity monitoring (Security auditing and login logging)
- [ ] Analytics reports (consultation totals, appointment counts)

---

### 8. Security Module
- [ ] Firestore Security Rules (restricting reads/writes based on auth role)
- [ ] Cloudinary security configuration (obfuscating preset directories)
- [ ] Role restrictions on API and database layers
- [ ] Client validation checks (strict email patterns, strong passwords)
- [ ] Universal error handling framework and user-friendly offline alerts

---

### 9. Testing Module
- [ ] Unit tests for auth & verification models and providers
- [ ] Integration tests for login, registration, and verification flow
- [ ] User Acceptance Testing (UAT) documentation and signing

---

### 10. Documentation
- [ ] Code walkthrough screenshots
- [ ] Chapter 4 implementation evidence compilation
- [ ] Defense presentation slides
- [ ] User guide and application manuals

---

## 🐙 GitHub Section

* **Current Branch:** `feature/auth`
* **Last Merged Feature:** `feat: add authentication module structure` (Commit `fa50069`)
* **Open Features (Working Area):**
  - Healthcare professional verification workflow integration (currently untracked files in local repository `lib/features/verification/`).
  - Appointment scheduling, Consultation call workflows, and Medical record modules.
* **Completed Features (Staged/Committed):**
  - Phase 1: Clean architecture project scaffold, routing, and Firebase integration.
  - Phase 2: User email/password signup, signin, password resets, role definition, and persistent sessions.

---

## 🏆 Project Milestones

1. **Milestone 1: Authentication Complete** `[x]`
   - Users can register, log in, define roles, and maintain authenticated sessions securely.
2. **Milestone 2: Healthcare Professional Verification Complete** `[x]`
   - Doctors can upload credentials to Cloudinary, admins can review and update statuses, and GoRouter blocks unverified doctors.
3. **Milestone 3: Appointments Complete** `[x]`
   - Patients can view active doctors and book slots; doctors can accept or reject bookings.
4. **Milestone 4: Consultation Complete** `[ ]`
   - Real-time video/audio call functionality is fully integrated using the Jitsi SDK.
5. **Milestone 5: Medical Records Complete** `[ ]`
   - Doctors can record sessions, write diagnoses, and securely upload prescription PDFs.
6. **Milestone 6: Admin Dashboard Complete** `[ ]`
   - System admins can manage users, view activity logs, and extract usage analytics.
7. **Milestone 7: Project Ready for Defense** `[ ]`
   - Testing complete, Chapter 4 evidence logged, User Guide written, and slides compiled.

---

## ⚠️ Risks & Blockers

### Current Blockers
1. **Android Gradle & Jitsi Meet SDK Dependency Compatibility:**
   - Jitsi Meet SDK has strict Minimum SDK and Kotlin version requirements. Integrating it might lead to dependency mismatches with current Android configuration.
2. **Unsigned Upload Preset Security:**
   - Since we are using client-side Cloudinary uploads (unsigned presets), there is a risk of unauthorized uploads if the preset name is exposed. Unsigned folders must be locked down to allow images/PDFs only.

### Pending Integrations
* Jitsi Meet SDK (Video Consultations)
* Firebase Cloud Messaging (FCM) (Push notifications)
* Cloudinary API configuration validator

### Technical Debt
* **Test Suite:** No unit or widget tests have been written for the auth repository or state notifier yet.
* **i18n Localization:** The application supports i18n hooks, but string resources need translation to French.

### Future Improvements (Academic Scope expansion)
* Multi-Factor Authentication (MFA)
* Biometric authentication (Fingerprint, FaceID)
* SSL/Certificate pinning for API data in transit

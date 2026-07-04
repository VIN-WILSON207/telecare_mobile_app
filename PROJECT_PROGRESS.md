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
| **Overall Project Progress** | **96%** |
| **Completed Modules / Phases** | **8 / 9** |
| **Completed Features** | **58 / 66** |
| **Open Issues / Blockers** | **1** |
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
    Phase 4: Appointment Management    :done, des4, 2026-06-08, 2026-06-12
    Phase 5: Video Consultation        :done, des5, 2026-06-13, 2026-06-17
    Phase 6: Medical Records           :done, des6, 2026-06-18, 2026-06-22
    Phase 7: Admin Dashboard           :done, des7, 2026-06-23, 2026-06-28
    section Current/Future
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
  - Push notifications on status change `[x]`
* **Deliverables:**
  - Doctor search & selection interface `[x]`
  - Booking form dialog `[x]`
  - Appointment list and status views `[x]`
  - Service for notification triggers `[x]`
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
  - Jitsi Meet SDK integration in Flutter `[x]`
  - Initiate/start consultation room from appointment `[x]`
  - Join meeting interface for both parties `[x]`
  - End meeting trigger and duration logging `[x]`
  - Audio-only mode fallback `[x]`
  - Consultation history log `[x]`
* **Deliverables:**
  - Jitsi Meet integration wrapper `[x]`
  - Active consultation room controls `[x]`
  - Call logs collection `/consultations` in Firestore `[x]`
* **Acceptance Criteria:**
  - Secure room names are generated dynamically using UUIDs `[x]`
  - Users can join audio/video rooms with correct permissions `[x]`
  - Graceful connection recovery and clean exit `[x]`
  - Session metadata written to Firestore on call completion `[x]`
* **Progress:** 100%
* **Completion Status:** Completed

---

### Phase 6 — Medical Records
* **Objectives:** Allow doctors to document diagnoses, treatment plans, and upload prescriptions securely.
* **Features:**
  - Medical record entry form for doctors `[x]`
  - Write diagnosis and treatment plan details `[x]`
  - Symptoms and prescription capture `[x]`
  - Medical record attachment upload to Cloudinary (image or PDF) `[x]`
  - Secure Firestore metadata entry `/medical_records` `[x]`
  - Patient personal health record viewing page `[x]`
  - Patient prescription viewing tab `[x]`
  - Search/filter records by diagnosis, clinician, symptoms, and medicine `[x]`
* **Deliverables:**
  - Record creation form UI `[x]`
  - Medical records dashboard (separated by patient/doctor views) `[x]`
  - Cloudinary secure storage paths for health documents `[x]`
  - Firestore model, repository, and Riverpod providers `[x]`
  - Firestore rules for doctor create/update, patient read-only access, and admin audit reads `[x]`
* **Acceptance Criteria:**
  - Doctors can create records from approved/completed appointments `[x]`
  - Patients can view their own history but cannot edit records `[x]`
  - Prescriptions are stored and shown in a dedicated patient tab `[x]`
  - Supporting PDF/image attachments are uploaded successfully and saved as URLs `[x]`
* **Progress:** 100%
* **Completion Status:** Completed

---

### Phase 7 — Admin Dashboard
* **Objectives:** System-level administration, user management, and activity monitoring.
* **Features:**
  - Dashboard home with system statistics `[x]`
  - User management (search, view details, suspend, reactivate users) `[x]`
  - Doctor verification request management `[x]`
  - Appointment management `[x]`
  - Activity monitoring and access logs `[x]`
  - General analytics and system reports (total bookings, active consultations) `[x]`
* **Deliverables:**
  - Admin-only home interface `[x]`
  - User management sub-screens `[x]`
  - Verification and appointment management screens `[x]`
  - System logs and analytics/report views `[x]`
* **Acceptance Criteria:**
  - Only users with role `admin` can load the dashboard `[x]`
  - Admins can query and filter users by role and status `[x]`
  - Admin actions (e.g., suspension) are applied immediately and securely `[x]`
* **Progress:** 100%
* **Completion Status:** Completed

---

### Phase 8 — Security Hardening & Polish
* **Objectives:** Restrict database access via Firestore security rules, encrypt data, handle errors, and polish UI.
* **Features:**
  - Firestore Security Rules development and deployment `[x]`
  - Secure Cloudinary access and upload restrictions `[x]`
  - Field-level validation on all text fields `[x]`
  - Universal error handling and network status notification `[x]`
  - Responsive screen layouts for various screen sizes `[x]`
  - App state loading skeleton screens `[ ]`
* **Deliverables:**
  - `firestore.rules` configuration file `[x]`
  - Error catching wrappers for Firebase/Cloudinary service calls `[x]`
  - Responsive layout helper class `[x]`
* **Acceptance Criteria:**
  - All database reads/writes are blocked unless verified by security rules `[x]`
  - Cloudinary folder credentials are obfuscated and secured `[x]`
  - Dynamic responsiveness verified across multiple device profiles `[x]`
* **Progress:** 100%
* **Completion Status:** Completed (Polishing UI and Skeletons as part of final polish)

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
* **Progress:** 25%
* **Completion Status:** In Progress (Testing suite started; Unit tests for Auth and Models created)

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
- [x] View verified doctors list
- [x] Book appointment
- [x] Approve appointment booking
- [x] Reject appointment booking
- [x] Appointment status tracking (Pending, Approved, Rejected, Completed)
- [x] Notifications integration (FCM) on status changes

---

### 5. Video Consultation Module
- [x] Jitsi Meet SDK integration in Flutter
- [x] Initiate/Start consultation room
- [x] Join meeting (dynamic room names)
- [x] End meeting workflow (cleans resources, terminates calls)
- [x] Audio-only fallback mode
- [x] Consultation history log (storing duration, timestamps, and doctor-patient details)

---

### 6. Medical Records Module
- [x] Create record form
- [x] Add diagnosis
- [x] Add symptoms
- [x] Add treatment plan
- [x] Add prescriptions
- [x] Upload supporting files to Cloudinary
- [x] Store medical record metadata in Firestore `/medical_records`
- [x] Patient medical record viewing screen
- [x] Patient prescription viewing screen
- [x] Search/filter records
- [x] Firestore role-based medical record rules

---

### 7. Admin Dashboard Module
- [x] Verification request management (Admin review, approvals, rejections)
- [x] User management (View profiles, search, suspend/activate accounts)
- [x] Appointment management
- [x] Activity monitoring (Security auditing and login logging)
- [x] Analytics reports (consultation totals, appointment counts)

---

### 8. Security Module
- [x] Firestore Security Rules (restricting reads/writes based on auth role)
- [x] Cloudinary security configuration (obfuscating preset directories)
- [x] Role restrictions on API and database layers
- [x] Client validation checks (strict email patterns, strong passwords)
- [x] Universal error handling framework and user-friendly offline alerts

---

### 9. Testing Module
- [x] Unit tests for auth & verification models and providers
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
4. **Milestone 4: Consultation Complete** `[x]`
   - Real-time video/audio call functionality is fully integrated using the Jitsi SDK.
5. **Milestone 5: Medical Records Complete** `[x]`
   - Doctors can record sessions, write diagnoses, add prescriptions, and securely upload supporting PDF/image documents.
6. **Milestone 6: Admin Dashboard Complete** `[x]`
   - System admins can manage users, view activity logs, and extract usage analytics.
7. **Milestone 7: Project Ready for Defense** `[ ]`
   - Testing complete, Chapter 4 evidence logged, User Guide written, and slides compiled.

---

## ⚠️ Risks & Blockers

### Current Blockers
1. **Unsigned Upload Preset Security:**
   - Since we are using client-side Cloudinary uploads (unsigned presets), there is a risk of unauthorized uploads if the preset name is exposed. Unsigned folders must be locked down to allow images/PDFs only.

### Pending Integrations
* Firebase Cloud Messaging (FCM) (Push notifications)
* Cloudinary API configuration validator

### Technical Debt
* **Test Suite:** No unit or widget tests have been written for the auth repository or state notifier yet.
* **i18n Localization:** The application supports i18n hooks, but string resources need translation to French.

### Future Improvements (Academic Scope expansion)
* Multi-Factor Authentication (MFA)
* Biometric authentication (Fingerprint, FaceID)
* SSL/Certificate pinning for API data in transit

---

## 2026-06-27 Implementation Update

### Accessibility and UI Readability
- [x] Increased global Material text theme sizes for older users.
- [x] Increased reusable auth/button/text-field component font sizes.
- [x] Enlarged bottom-navigation icons and labels.
- [x] Updated TeleCare header branding to use the green brand color.

### Auth, Firestore, and Verification Stability
- [x] Added explicit timeouts around Firebase Auth login/register calls.
- [x] Added explicit timeouts around Firestore user-profile reads/writes.
- [x] Added explicit timeouts around HP verification Firestore submission.
- [x] Changed verification status update to merge into the doctor profile instead of failing if the user document is missing.
- [x] Kept audit-log writes non-blocking so login/register do not stay loading forever if audit logging fails.

### Navigation Fixes
- [x] Added a shared home-back scope so Android/system back from bottom-navigation pages returns users to `/home`.
- [x] Added `/prescriptions` route and wired the quick-service Prescriptions tile to open the prescriptions tab instead of the general records page.

### Search and Booking
- [x] Replaced the read-only dashboard search field with an editable HP search field.
- [x] Added patient booking search by HP name, specialty, email, or hospital.
- [x] Added specialty filter chips on the Book Doctor tab.

### Still Pending From SRS / Security Recommendation
- [ ] Firestore security rules must be reviewed in Firebase Console if writes still fail after these client fixes.
- [ ] Biometric/PIN app unlock after inactivity.
- [ ] Step-up authentication before sensitive actions such as medical records, payments, profile edits, and prescriptions.
- [ ] Trusted device management and login notifications.
- [ ] Full JWT/refresh-token backend session layer if a custom backend is introduced; Firebase currently manages client sessions.
- [ ] End-to-end encrypted messaging and full video consultation security hardening.

---

## 2026-06-29 Auth, Accessibility, and Documentation Update

### Registration and Auth Stability
- [x] Confirmed registration is a two-step flow: role selection first, then personal information and password.
- [x] Added strict role-based DOB enforcement: patients must be 18+ and healthcare professionals must be 23+.
- [x] Hardened Firebase registration order: create Auth user, verify active uid/token, then write `users/{uid}`.
- [x] Added Firestore retry/backoff handling for transient `unavailable`, `deadline-exceeded`, and `aborted` failures.
- [x] Added a dev-admin fallback after successful Firebase Auth when Firestore profile reads are temporarily unavailable.

### UI Readability and Reuse
- [x] Confirmed shared readable input styling uses dark typed text and larger font sizes.
- [x] Confirmed chat messaging uses the reusable `MessageInputField`.
- [x] Updated registration gender dropdown to use a light green readable surface.

### Documentation
- [x] Reviewed Phase 1 through Phase 6 completion status and marked the implemented consultation phase complete.
- [x] Marked the implemented admin dashboard section complete.
- [x] Added `FIREBASE_COLLECTIONS.md` documenting Firestore collections, fields, and data types.

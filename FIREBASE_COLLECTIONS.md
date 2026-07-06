# TeleCare Firebase Collections and Data Types

This file documents the Firestore collections used by the Flutter app. Firestore `Timestamp` means a `Timestamp` value written by Cloud Firestore or `Timestamp.fromDate(...)`.

## `users/{uid}`

User profile document. The document id must match the Firebase Authentication user `uid`.

| Field | Type | Required | Notes |
| :--- | :--- | :--- | :--- |
| `uid` | string | Yes | Same value as the document id and Firebase Auth uid. |
| `fullName` | string | Yes | User display name. |
| `email` | string | Yes | Firebase Auth email. |
| `phone` | string | Yes | Include country code where possible. |
| `role` | string | Yes | `patient`, `doctor`, or `admin`. |
| `dateOfBirth` | Timestamp or null | Recommended | Patients must be 18+; doctors/HPs must be 23+. |
| `gender` | string or null | Recommended | `female`, `male`, `other`, `prefer_not_to_say`. |
| `verificationStatus` | string | Yes | Common values: `unverified`, `pending`, `approved`, `rejected`. |
| `profileImage` | string or null | No | URL to profile image. |
| `createdAt` | Timestamp | Yes | Prefer `FieldValue.serverTimestamp()` on create. |
| `specialty` | string or null | Doctor only | Filled after HP verification submission/approval. |
| `licenseNumber` | string or null | Doctor only | Filled after HP verification submission/approval. |
| `hospital` | string or null | Doctor only | Doctor workplace/clinic. |
| `isActive` | boolean | Yes | Admin suspend/reactivate flag. |

## `verification_requests/{requestId}`

Healthcare professional credential review requests.

| Field | Type | Required | Notes |
| :--- | :--- | :--- | :--- |
| `id` | string | Yes | Same value as document id. |
| `doctorId` | string | Yes | References `users/{uid}`. |
| `doctorName` | string | Yes | Snapshot of doctor name at submission. |
| `nationalIdUrl` | string | Yes | Cloudinary URL. |
| `licenseUrl` | string | Yes | Cloudinary URL. |
| `status` | string | Yes | `pending`, `approved`, or `rejected`. |
| `submittedAt` | Timestamp | Yes | Submission time. |
| `reviewedAt` | Timestamp or null | No | Set when approved/rejected. |
| `reviewedBy` | string or null | No | Admin user id or name. |
| `rejectionReason` | string or null | No | Required when rejected. |
| `specialty` | string | Yes | Doctor specialty. |
| `licenseNumber` | string | Yes | Professional license number. |
| `hospital` | string | Yes | Workplace/clinic. |

## `appointments/{appointmentId}`

Appointment booking documents.

| Field | Type | Required | Notes |
| :--- | :--- | :--- | :--- |
| `patientId` | string | Yes | References patient `users/{uid}`. |
| `doctorId` | string | Yes | References doctor `users/{uid}`. |
| `patientName` | string | Yes | Snapshot for display. |
| `doctorName` | string | Yes | Snapshot for display. |
| `patientEmail` | string | Yes | Snapshot for display/notifications. |
| `doctorEmail` | string | Yes | Snapshot for display/notifications. |
| `reason` | string | Yes | Appointment reason. |
| `status` | string | Yes | `pending`, `approved`, `rejected`, `completed`, or `cancelled`. |
| `appointmentDate` | Timestamp | Yes | Requested consultation date/time. |
| `createdAt` | Timestamp | Yes | Creation timestamp. |
| `updatedAt` | Timestamp or null | No | Last status/detail update. |
| `notes` | string or null | No | Doctor/admin notes. |

## `consultations/{consultationId}`

Video/audio consultation session metadata.

| Field | Type | Required | Notes |
| :--- | :--- | :--- | :--- |
| `appointmentId` | string | Yes | References `appointments/{appointmentId}`. |
| `doctorId` | string | Yes | References doctor `users/{uid}`. |
| `patientId` | string | Yes | References patient `users/{uid}`. |
| `roomId` | string | Yes | Jitsi/meeting room id. |
| `status` | string | Yes | `scheduled`, `active`, `completed`, or `cancelled`. |
| `mode` | string | Yes | `video` or `audio_only`. |
| `startedAt` | Timestamp or null | No | Set when joined/started. |
| `endedAt` | Timestamp or null | No | Set when ended. |
| `duration` | number | Yes | Duration in minutes. |
| `createdAt` | Timestamp | Yes | Creation timestamp. |

## `medical_records/{recordId}`

Protected clinical record documents.

| Field | Type | Required | Notes |
| :--- | :--- | :--- | :--- |
| `appointmentId` | string | Yes | Related appointment. |
| `consultationId` | string or null | No | Related consultation if available. |
| `doctorId` | string | Yes | Treating doctor. |
| `doctorName` | string | Yes | Snapshot for display. |
| `nurseName` | string | No | Defaults in app if absent. |
| `patientId` | string | Yes | Patient owner. |
| `patientName` | string | Yes | Snapshot for display. |
| `diagnosis` | string | Yes | Diagnosis summary. |
| `symptoms` | array<string> | Yes | Symptoms captured by doctor. |
| `treatmentPlan` | string | Yes | Treatment plan. |
| `prescription` | array<map> | Yes | Each item: `medicine` string, `dosage` string, `duration` string. |
| `notes` | string | Yes | Additional clinical notes. |
| `attachments` | array<string> | Yes | Cloudinary URLs for images/PDFs. |
| `status` | string | Yes | Default `submitted`. |
| `createdAt` | Timestamp | Yes | Creation timestamp. |
| `updatedAt` | Timestamp | Yes | Last update timestamp. |
| `createdBy` | string | Yes | Usually same as doctor uid. |

## `audit_logs/{logId}`

Admin/security activity log.

| Field | Type | Required | Notes |
| :--- | :--- | :--- | :--- |
| `id` | string | Yes | Same value as document id. |
| `action` | string | Yes | Examples: `login`, `registration`, `profile_update`, `verification_approved`. |
| `userId` | string | Yes | Acting user id. |
| `userName` | string | Yes | Acting user display name. |
| `details` | string | Yes | Human-readable action details. |
| `timestamp` | Timestamp | Yes | Prefer `FieldValue.serverTimestamp()`. |

## Recommended Minimum Rules Shape

For user profile creation under strict rules, keep this pattern:

```js
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

The app registration code must create the Firebase Auth account, verify the returned `User.uid`, refresh an ID token, and only then write `users/{uid}`.

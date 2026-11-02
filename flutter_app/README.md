# Northfield Parent App

Parent-only Flutter client for the School ERP API. It uses server responses for the signed-in parent, children, attendance, notices, account settings, and leave requests. No demo accounts, sample records, fixture providers, or mock data are included.

## API configuration

The default host is `https://northfield.200-141-4-40.sslip.io`, with API routes under `/api/v1/`. Override the host at build time with `--dart-define=API_BASE_URL=https://your-school-host`.

The native client persists the school's session, CSRF, and device cookies using secure storage. It sends the required CSRF and Origin headers, refreshes and retries once after a CSRF failure, and displays backend problem titles when a request fails. TLS certificate validation remains enabled.

The parent navigation contains Home, Attendance, Notices, and More. The API reference has no parent fee route; fees, assignments, marks, staff screens, and demo settings have been removed.

## Build

This workspace does not include Flutter/Dart tooling or generated Android/iOS platform folders. With a current Flutter SDK installed, run from this directory:

```powershell
flutter create --platforms=android,ios .
flutter pub get
flutter build appbundle --release --dart-define=API_BASE_URL=https://northfield.200-141-4-40.sslip.io
```

For iOS, build on macOS after configuring signing:

```powershell
flutter build ipa --release --dart-define=API_BASE_URL=https://northfield.200-141-4-40.sslip.io
```

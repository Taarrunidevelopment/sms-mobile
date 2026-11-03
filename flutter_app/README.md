# School Parent Portal

Flutter parent app for the School ERP API. The app obtains the school name, signed-in parent, children, child profiles, attendance, calendar, leave requests, notices, alert preferences, and active sessions from the backend. Fees, assignments, and marks are not shown because the parent API does not provide those routes.

The app does not include seeded accounts or sample records. Failed API requests appear as errors in the relevant view.

## Backend

The default API host is `https://northfield.200-141-4-40.sslip.io`, with routes under `/api/v1/`. Override the host at build time:

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://your-school-host
```

The native client fetches a CSRF cookie before login, sends its token on API requests, and keeps TLS certificate validation enabled.

## Android APK

The GitHub Actions workflow at `.github/workflows/dart.yml` builds the Android platform from `flutter_app`, ensures internet permission is present, and uploads the release APK as the `release-apk` artifact. It runs on pushes to `main` that change this app or the workflow, and can also be started manually.

For a local build, install Flutter 3.24.5 or newer and run:

```sh
flutter create --platforms=android .
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://northfield.200-141-4-40.sslip.io
```

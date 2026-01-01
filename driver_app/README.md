# Delivery App (Stage 3) — Driver

This Flutter project is the **Stage 3 Driver/Delivery app** for the WestBank Marketplace MVP.

## Features (MVP)
- OTP login (same backend as Customer app)
- Driver **Online/Offline** toggle
- **Receive delivery requests** (polling every 5 seconds)
- **Accept / Reject** request
- View **Active delivery** details
- **Pickup** action (enabled when store marks order `READY`)
- **Mark delivered** (enabled after pickup)
- Shows **Smart dispatch** suggested move time (if provided by backend)

## Setup
1. Open `lib/core/constants/endpoints.dart` and change `baseUrl` to your backend URL (LAN IP when testing on a real device).
2. Run:
   ```
   flutter pub get
   flutter run
   ```

## Driver accounts
- The backend seeds a demo DRIVER account: `970599000002`.
- For any new driver, an Admin must set the user's role to `DRIVER` (see backend `POST /admin/users/set-role`).

## Backend endpoints used
- `POST /auth/request-otp`
- `POST /auth/verify-otp`
- `GET /auth/me`
- `GET /driver/status`
- `POST /driver/online`
- `POST /driver/offline`
- `GET /driver/deliveries/available`
- `GET /driver/deliveries/active`
- `POST /driver/deliveries/:id/accept`
- `POST /driver/deliveries/:id/reject` (MVP: client-side rejection)
- `POST /driver/deliveries/:id/pickup`
- `POST /driver/deliveries/:id/delivered`

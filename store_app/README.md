# Stage 2 — Store App (Flutter)

This is the **Store/Merchant app (Stage 2)** for the West Bank Marketplace + Delivery MVP.

## What’s implemented (MVP)
- OTP login (same backend as customer app)
- **Role guard:** only `STORE_OWNER` can enter (checked via `/auth/me`)
- Orders inbox (backend `PENDING_STORE` orders)
- Order details (items + notes)
- Actions:
  - Accept order + set prep time
  - Reject order
  - Mark READY
- Auto refresh every 10s + pull-to-refresh

## Backend endpoints used
- `POST /auth/request-otp`
- `POST /auth/verify-otp`
- `GET /auth/me`
- `GET /store/orders/inbox`
- `POST /store/orders/accept`
- `POST /store/orders/reject`
- `POST /store/orders/ready`

## Quick start (local)
1) Run backend:
```bash
cd backend
npm i
npm run prisma:migrate
npm run seed
npm run dev
```
2) Run store app:
```bash
flutter pub get
flutter run
```
3) Use demo store owner phone (seed): **970599000001**
- The backend prints OTP in terminal:
  - `[OTP][MOCK] phone=... code=1234 ...`

## Important note about accepting orders (Taxi confirmation)
In this MVP backend, when you press **Accept**, the backend waits for a taxi office WhatsApp reply (up to **60 seconds** per office, sequentially).

To simulate acceptance quickly (dev):
- From the Store app order details screen press:
  - **DEV: simulate taxi accept (office 970599111111)**

Or call the webhook manually:
```bash
curl -X POST http://localhost:4000/taxi/whatsapp-reply \
  -H 'Content-Type: application/json' \
  -d '{"from":"970599111111","text":"1"}'
```

## Configure API base URL
Edit: `lib/core/constants/endpoints.dart`

- Android emulator: `http://10.0.2.2:4000`
- iOS simulator: `http://localhost:4000`
- Real device: `http://<YOUR_PC_IP>:4000`

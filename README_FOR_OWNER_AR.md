# دليل التشغيل (مبسّط) — WestBank Marketplace MVP

هذا المشروع عبارة عن **MVP كامل**: (Backend API + قاعدة بيانات + تطبيق العميل + تطبيق المتجر).  
التطبيقات مبنية بـ Flutter وتتصل بالـ Backend.

## 1) متطلبات على جهازك
- Node.js (إصدار 18 أو أحدث)
- Docker Desktop (لتشغيل PostgreSQL بسهولة) **أو** PostgreSQL مثبت يدويًا
- Flutter SDK (لتشغيل التطبيقات)
- Git (اختياري)

## 2) تشغيل قاعدة البيانات (الأبسط)
من داخل مجلد المشروع:
```bash
docker compose up -d
```
هذا سيشغل PostgreSQL على:
- Host: `localhost`
- Port: `5432`
- User: `postgres`
- Password: `postgres`
- DB: `appdb`

## 3) تشغيل الـ Backend API
ادخل إلى مجلد backend:
```bash
cd backend
```

انسخ ملف البيئة:
```bash
copy .env.example .env
```
(على mac/linux استخدم: `cp .env.example .env`)

ثبت الحزم:
```bash
npm install
```

شغّل المايجريشن (يبني الجداول):
```bash
npx prisma migrate dev
```

شغّل Seed (يدخل بيانات تجريبية: متجر + منيو + مكاتب تكاسي):
```bash
npm run seed
```

شغّل السيرفر:
```bash
npm run dev
```

الآن الـ API شغال على:
- `http://localhost:4000/health`

## 4) تشغيل تطبيق العميل (Customer App)
ادخل إلى مجلد customer_app:
```bash
cd customer_app
flutter pub get
flutter run
```
سيشغل التطبيق على محاكي أو جهاز متصل.

## 5) تشغيل تطبيق المتجر (Store App)
ادخل إلى مجلد store_app:
```bash
cd store_app
flutter pub get
flutter run
```
سيشغل التطبيق على محاكي أو جهاز متصل.

> ملاحظة: حساب المتجر التجريبي برقم `970599000001` (OTP في Console).

## 6) تشغيل تطبيق السائق (Driver App)
ادخل إلى مجلد driver_app:
```bash
cd driver_app
flutter pub get
flutter run
```
سيشغل التطبيق على محاكي أو جهاز متصل.

## 7) تشغيل الـ Backend للسائقين
ادخل إلى مجلد stage3driver:
```bash
cd stage3driver
npm install
npx prisma generate
npm run dev
```

الآن الـ API للسائقين شغال على:
- `http://localhost:4001/health`

## 8) تجربة سريعة (بدون تطبيق)
يمكنك استخدام Postman أو أي عميل HTTP:

### طلب OTP
POST:
`http://localhost:4000/auth/request-otp`
Body:
```json
{ "phone": "970599123456" }
```
سيظهر OTP في نافذة الـ Console (لأننا الآن Mock).

### تحقق OTP وإصدار Token
POST:
`http://localhost:4000/auth/verify-otp`
Body:
```json
{ "phone": "970599123456", "code": "123456" }
```
(استبدل code بالقيمة التي ظهرت في Console)

ستحصل على `token`.

### إضافة عنوان افتراضي
POST:
`http://localhost:4000/addresses`
Header:
`Authorization: Bearer <token>`
Body:
```json
{ "label": "البيت", "lat": 31.9, "lng": 35.2, "isDefault": true }
```

### عرض المتاجر
GET:
`http://localhost:4000/stores`

### جلب المنيو
GET:
`http://localhost:4000/menu/store/<storeId>`

### إنشاء طلب
POST:
`http://localhost:4000/orders`
Header:
`Authorization: Bearer <token>`
Body (مثال):
```json
{
  "storeId": "<storeId>",
  "branchId": "<branchId>",
  "items": [
    { "itemId": "<menuItemId>", "qty": 1, "optionIds": [] }
  ]
}
```

### قبول الطلب من المتجر (قبول مشروط ثم يبدأ تأكيد التوصيل)
POST:
`http://localhost:4000/store/orders/accept`
Header: `Authorization: Bearer <token_store_owner>`
Body:
```json
{ "orderId": "<orderId>", "prepMinutes": 40 }
```

> ملاحظة: حساب المتجر التجريبي موجود في seed برقم `970599000001` لكن OTP سيظهر في Console عند طلبه.

## 9) مكاتب التاكسي (واتس)
حالياً الإرسال Mock (يظهر في Console).  
لربط WhatsApp Business API الحقيقي:
- نستخدم Endpoint:
`POST /taxi/whatsapp-reply`  
بـ body مثل:
```json
{ "from": "970599111111", "text": "1" }
```
وهذا يحاكي رد المكتب (قبول/رفض).

## 10) ما الذي ينفذه هذا الـ MVP？
- تسجيل دخول OTP (Mock)
- عناوين + عنوان افتراضي
- استعراض متاجر + فروع
- منيو + تخصيص
- إنشاء طلب
- قبول المتجر (قبول مشروط)
- تأكيد التوصيل عبر **Taxi Sequential Dispatch** (واحد واحد مع مؤقت)
- التوقيت الذكي: يثبت وقت تحرك التاكسي (Mock إشعار)
- تطبيق السائق (Driver App) لإدارة التوصيلات

## 11) القادم
- تطبيق Flutter كامل (Customer + Store) محسن
- Admin Panel ويب
- ربط WhatsApp API الحقيقي
- ربط خرائط + ذكاء محلي للإغلاقات

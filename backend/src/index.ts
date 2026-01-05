import express from "express";
import cors from "cors";
import dotenv from "dotenv";

// import { authRouter } from "./auth/auth.routes";
// import { addressesRouter } from "./addresses/addresses.routes";
// import { storesRouter } from "./stores/stores.routes";
// import { menuRouter } from "./menu/menu.routes";
// import { ordersRouter } from "./orders/orders.routes";
// import { storeRouter } from "./store/store.routes";
// import { adminRouter } from "./admin/admin.routes";
// import { taxiWebhookRouter } from "./taxi/taxi.webhook";
// import { driverRouter } from "./driver/driver.routes";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  console.log("Health check received");
  res.json({ ok: true });
});

// app.use((req, _res, next) => {
//   console.log(`${req.method} ${req.path}`, req.body);
//   next();
// });

// app.use("/auth", authRouter);
// app.use("/addresses", addressesRouter);
// app.use("/stores", storesRouter);
// app.use("/menu", menuRouter);
// app.use("/orders", ordersRouter);
// app.use("/store", storeRouter);
// app.use("/admin", adminRouter);
// app.use("/taxi", taxiWebhookRouter);
// app.use("/driver", driverRouter);

const port = Number(process.env.PORT || 4000);
console.log(`Attempting to start server on port ${port}`);

process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`API running on http://localhost:${port}`);
  console.log('Server started successfully');
}).on('error', (err) => {
  console.error('Server error:', err);
});

-- CreateEnum
CREATE TYPE "DriverContractStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'SUSPENDED', 'TERMINATED');

-- CreateTable
CREATE TABLE "DriverContract" (
    "id" TEXT NOT NULL,
    "driverUserId" TEXT NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "autoRenew" BOOLEAN NOT NULL DEFAULT false,
    "commissionRate" INTEGER NOT NULL DEFAULT 0,
    "status" "DriverContractStatus" NOT NULL DEFAULT 'ACTIVE',
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DriverContract_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DriverStatus" (
    "userId" TEXT NOT NULL,
    "isOnline" BOOLEAN NOT NULL DEFAULT false,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastLat" DOUBLE PRECISION,
    "lastLng" DOUBLE PRECISION,

    CONSTRAINT "DriverStatus_pkey" PRIMARY KEY ("userId")
);

-- CreateIndex
CREATE INDEX "DriverContract_driverUserId_idx" ON "DriverContract"("driverUserId");

-- CreateIndex
CREATE INDEX "DriverContract_status_endDate_idx" ON "DriverContract"("status", "endDate");

-- CreateIndex
CREATE INDEX "DriverStatus_isOnline_idx" ON "DriverStatus"("isOnline");

-- AddForeignKey
ALTER TABLE "DriverContract" ADD CONSTRAINT "DriverContract_driverUserId_fkey" FOREIGN KEY ("driverUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverStatus" ADD CONSTRAINT "DriverStatus_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Delivery" ADD CONSTRAINT "Delivery_driverUserId_fkey" FOREIGN KEY ("driverUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

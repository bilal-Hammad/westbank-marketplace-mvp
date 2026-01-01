import { PrismaClient, StoreType, FulfillmentType, UserRole } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  // Admin user
  const adminPhone = "970599000000";
  await prisma.user.upsert({
    where: { phone: adminPhone },
    update: { role: UserRole.ADMIN },
    create: { phone: adminPhone, role: UserRole.ADMIN, name: "Admin" },
  });

  // Store owner demo
  const ownerPhone = "970599000001";
  await prisma.user.upsert({
    where: { phone: ownerPhone },
    update: { role: UserRole.STORE_OWNER },
    create: { phone: ownerPhone, role: UserRole.STORE_OWNER, name: "Store Owner" },
  });

  // Taxi offices
  await prisma.taxiOffice.createMany({
    data: [
      { name: "مكتب تكاسي رام الله 1", whatsapp: "970599111111", city: "رام الله", area: "المنارة", priority: 1, isActive: true },
      { name: "مكتب تكاسي رام الله 2", whatsapp: "970599222222", city: "رام الله", area: "البلد", priority: 2, isActive: true },
    ],
    skipDuplicates: true,
  });

  // Store + branch
  const store = await prisma.store.create({
    data: {
      name: "Pizza Roma",
      type: StoreType.RESTAURANT,
      fulfillmentType: FulfillmentType.INSTANT,
      isActive: true,
      branches: {
        create: {
          name: "فرع رام الله",
          city: "رام الله",
          area: "المنارة",
          lat: 31.9038,
          lng: 35.2034,
          isOpen: true,
          prepTimeMinutes: 30,
        },
      },
    },
    include: { branches: true },
  });

  const menu = await prisma.menu.create({
    data: { storeId: store.id, title: "Main Menu" },
  });

  const pizza = await prisma.menuItem.create({
    data: {
      menuId: menu.id,
      name: "بيتزا مارجريتا",
      basePrice: 3000,
      prepMinutes: 20,
    },
  });

  const sizeGroup = await prisma.optionGroup.create({
    data: { itemId: pizza.id, name: "الحجم", minSelect: 1, maxSelect: 1 },
  });

  await prisma.optionItem.createMany({
    data: [
      { groupId: sizeGroup.id, name: "Small", priceAdd: 0, isActive: true },
      { groupId: sizeGroup.id, name: "Large", priceAdd: 1500, isActive: true },
    ],
  });

  console.log("✅ Seed done");
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });

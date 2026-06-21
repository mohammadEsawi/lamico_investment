import "dotenv/config";
import bcrypt from "bcrypt";
import { ProductType, UserRole } from "../src/config/generated/prisma/client";
import { prisma } from "../src/config/lib/prisma";

const DEFAULT_PASSWORD  = "Pass1234!";
const BCRYPT_SALT_ROUNDS = 12;

const users = [
  {
    nationalId : "100000001",
    fullName   : "مدير النظام",
    username   : "admin",
    phone      : "0599000001",
    email      : "admin@lamico.local",
    role       : UserRole.ADMIN,
  },
  {
    nationalId : "100000002",
    fullName   : "المهندس",
    username   : "engineer",
    phone      : "0599000002",
    email      : "engineer@lamico.local",
    role       : UserRole.ENGINEER,
    shiftName  : "B",
  },
  {
    nationalId : "100000003",
    fullName   : "المحاسب",
    username   : "accountant",
    phone      : "0599000003",
    email      : "accountant@lamico.local",
    role       : UserRole.ACCOUNTANT,
  },
  {
    nationalId : "100000004",
    fullName   : "العامل",
    username   : "worker",
    phone      : "0599000004",
    email      : "worker@lamico.local",
    role       : UserRole.WORKER,
    shiftName  : "B",
  },
  {
    nationalId : "100000005",
    fullName   : "مندوب المبيعات",
    username   : "salesrep",
    phone      : "0599000005",
    email      : "salesrep@lamico.local",
    role       : UserRole.SALES_REP,
  },
];

async function seedShifts() {
  const now  = new Date();
  const make = (h: number, m: number) => {
    const d = new Date(now);
    d.setHours(h, m, 0, 0);
    return d;
  };

  const shifts = [
    { name: "A", startTime: make(0,  0), endTime: make(8,  0) },
    { name: "B", startTime: make(8,  0), endTime: make(16, 0) },
    { name: "C", startTime: make(16, 0), endTime: make(23, 59) },
  ];

  for (const s of shifts) {
    const existing = await prisma.shift.findFirst({
      where : { name: s.name },
      select: { id: true },
    });
    if (existing) {
      await prisma.shift.update({ where: { id: existing.id }, data: s });
    } else {
      await prisma.shift.create({ data: s });
    }
    console.log(`Shift: ${s.name}`);
  }
}

async function seedUsers() {
  const hash = await bcrypt.hash(DEFAULT_PASSWORD, BCRYPT_SALT_ROUNDS);

  for (const u of users) {
    const shift = u.shiftName
      ? await prisma.shift.findFirst({
          where : { name: u.shiftName },
          select: { id: true },
        })
      : null;

    await prisma.user.upsert({
      where : { username: u.username },
      update: {
        nationalId: u.nationalId,
        fullName  : u.fullName,
        phone     : u.phone,
        email     : u.email,
        role      : u.role,
        shiftId   : shift?.id ?? null,
        isActive  : true,
        password  : hash,
      },
      create: {
        nationalId: u.nationalId,
        fullName  : u.fullName,
        username  : u.username,
        phone     : u.phone,
        email     : u.email,
        role      : u.role,
        shiftId   : shift?.id ?? null,
        isActive  : true,
        password  : hash,
      },
    });

    console.log(`User: ${u.username} (${u.role})`);
  }
}

async function seedMachines() {
  const machines = [
    { name: "ماكينة الأغطية", type: "CAPS"    },
    { name: "ماكينة المخال",  type: "PREFORM" },
  ];

  for (const m of machines) {
    const existing = await prisma.machine.findFirst({ where: { type: m.type } });
    if (!existing) {
      await prisma.machine.create({ data: { name: m.name, type: m.type } });
    }
    console.log(`Machine: ${m.name} (${m.type})`);
  }
}

async function seedProductionSettings() {
  const settings = [
    { productType: ProductType.CAPS,    piecesPerCarton: 1000 },
    { productType: ProductType.PREFORM, piecesPerCarton: 1    },
  ];

  for (const s of settings) {
    await prisma.productionSetting.upsert({
      where : { productType: s.productType },
      update: {},
      create: s,
    });
    console.log(`ProductionSetting: ${s.productType} (${s.piecesPerCarton} pcs/carton)`);
  }
}

async function seedRawMaterials() {
  const materials = [
    { name: 'راتنج HDPE',         unit: 'كيلوغرام',  currentQuantity: 500,  minQuantity: 100 },
    { name: 'راتنج LDPE',         unit: 'كيلوغرام',  currentQuantity: 300,  minQuantity: 80  },
    { name: 'راتنج PET',          unit: 'كيلوغرام',  currentQuantity: 600,  minQuantity: 150 },
    { name: 'كراتين تعبئة',       unit: 'كرتونة',    currentQuantity: 1000, minQuantity: 200 },
    { name: 'ماستر باتش ألوان',  unit: 'كيلوغرام',  currentQuantity: 50,   minQuantity: 20  },
    { name: 'لاصق',               unit: 'كيلوغرام',  currentQuantity: 30,   minQuantity: 10  },
  ];
  for (const m of materials) {
    const existing = await prisma.rawMaterial.findFirst({ where: { name: m.name } });
    if (!existing) {
      await prisma.rawMaterial.create({ data: m });
    }
    console.log(`RawMaterial: ${m.name}`);
  }
}

async function seedElectricityPrice() {
  const existing = await prisma.electricityKwhPrice.findFirst();
  if (!existing) {
    const admin = await prisma.user.findFirst({ where: { role: UserRole.ADMIN } });
    if (admin) {
      await prisma.electricityKwhPrice.create({
        data: {
          price    : 1.5,
          notes    : "السعر الابتدائي",
          setById  : admin.id,
        },
      });
      console.log("ElectricityKwhPrice: 1.5 ج.م/كيلوواط");
    }
  } else {
    console.log(`ElectricityKwhPrice: already set (${existing.price} ج.م/كيلوواط)`);
  }
}

async function main() {
  console.log("\n🌱 Seeding Lamico Investment...\n");
  await seedShifts();
  await seedUsers();
  await seedMachines();
  await seedProductionSettings();
  await seedRawMaterials();
  await seedElectricityPrice();
  console.log("\n✅ Done.");
  console.log(`Password for all accounts: ${DEFAULT_PASSWORD}\n`);
}

main()
  .catch((e) => { console.error("Seed failed:", e); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());

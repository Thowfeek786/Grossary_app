/**
 * Firestore Seed Script for Grocery Platform
 * 
 * Prerequisites:
 *   npm install firebase-admin
 * 
 * Usage:
 *   1. Download your service account key from Firebase Console:
 *      Project Settings > Service Accounts > Generate new private key
 *   2. Save it as tools/serviceAccountKey.json
 *   3. Run: node tools/seed.js
 */

const admin = require('firebase-admin');
const path = require('path');

// ── Initialize Admin SDK ──────────────────────────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (e) {
  console.error('❌ serviceAccountKey.json not found in tools/ directory.');
  console.error('   Download it from: Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const now = admin.firestore.Timestamp.now();

// ── Seed Data ─────────────────────────────────────────────────────────────────

const categories = [
  { id: 'cat_001', name: 'Fruits', description: 'Fresh seasonal fruits from local farms', imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400', sortOrder: 1, isActive: true },
  { id: 'cat_002', name: 'Vegetables', description: 'Organic vegetables direct from farmers', imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', sortOrder: 2, isActive: true },
  { id: 'cat_003', name: 'Dairy & Eggs', description: 'Farm-fresh dairy products and eggs', imageUrl: 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400', sortOrder: 3, isActive: true },
  { id: 'cat_004', name: 'Grains & Pulses', description: 'Premium grains, lentils, and legumes', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400', sortOrder: 4, isActive: true },
  { id: 'cat_005', name: 'Beverages', description: 'Juices, teas, and healthy drinks', imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400', sortOrder: 5, isActive: true },
  { id: 'cat_006', name: 'Snacks', description: 'Healthy and tasty snack options', imageUrl: 'https://images.unsplash.com/photo-1616684000067-36952fde56ec?w=400', sortOrder: 6, isActive: true },
  { id: 'cat_007', name: 'Bakery', description: 'Fresh-baked breads, cakes, and pastries', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400', sortOrder: 7, isActive: true },
  { id: 'cat_008', name: 'Spices & Condiments', description: 'Aromatic spices and flavorful condiments', imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400', sortOrder: 8, isActive: true },
];

const banners = [
  { id: 'banner_001', title: 'Fresh Fruits Sale', subtitle: 'Up to 40% off on all fruits', imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800&h=300&fit=crop', actionUrl: '/home/category/cat_001', isActive: true, sortOrder: 1 },
  { id: 'banner_002', title: 'Organic Vegetables', subtitle: 'Farm to table freshness guaranteed', imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&h=300&fit=crop', actionUrl: '/home/category/cat_002', isActive: true, sortOrder: 2 },
  { id: 'banner_003', title: 'Free Delivery', subtitle: 'On all orders above ₹500', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=300&fit=crop', actionUrl: null, isActive: true, sortOrder: 3 },
];

const products = [
  {
    id: 'prod_001', name: 'Fresh Red Apples',
    description: 'Crisp and juicy red apples sourced from Himachal Pradesh. Rich in fiber and antioxidants. Perfect for snacking, baking, or adding to salads.',
    price: 120.0, discountPrice: 89.0, categoryId: 'cat_001', categoryName: 'Fruits',
    imageUrls: ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400'],
    unit: '1 kg', stockQuantity: 50.0, isActive: true, isFeatured: true, rating: 4.5, reviewCount: 124,
    tags: ['fresh', 'fruit', 'apple', 'seasonal'],
  },
  {
    id: 'prod_002', name: 'Alphonso Mangoes',
    description: 'Premium Alphonso mangoes from Ratnagiri, Maharashtra. Known for their rich, creamy texture and sweet aroma. Limited seasonal availability.',
    price: 250.0, discountPrice: 199.0, categoryId: 'cat_001', categoryName: 'Fruits',
    imageUrls: ['https://images.unsplash.com/photo-1553279768-865429fa0078?w=400'],
    unit: '1 dozen', stockQuantity: 30.0, isActive: true, isFeatured: true, rating: 4.8, reviewCount: 89,
    tags: ['mango', 'alphonso', 'seasonal', 'premium'],
  },
  {
    id: 'prod_003', name: 'Organic Spinach',
    description: 'Freshly harvested organic spinach leaves. Rich in iron, vitamins, and minerals. Perfect for salads, smoothies, and cooking.',
    price: 45.0, discountPrice: null, categoryId: 'cat_002', categoryName: 'Vegetables',
    imageUrls: ['https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400'],
    unit: '250 g', stockQuantity: 100.0, isActive: true, isFeatured: false, rating: 4.2, reviewCount: 56,
    tags: ['organic', 'spinach', 'green', 'healthy'],
  },
  {
    id: 'prod_004', name: 'Farm Fresh Tomatoes',
    description: 'Locally grown, vine-ripened tomatoes bursting with natural flavor. Ideal for cooking, making sauces, and salads.',
    price: 40.0, discountPrice: 32.0, categoryId: 'cat_002', categoryName: 'Vegetables',
    imageUrls: ['https://images.unsplash.com/photo-1558818498-28c1e002b655?w=400'],
    unit: '500 g', stockQuantity: 75.0, isActive: true, isFeatured: true, rating: 4.3, reviewCount: 78,
    tags: ['tomato', 'farm', 'fresh', 'vegetable'],
  },
  {
    id: 'prod_005', name: 'Amul Full Cream Milk',
    description: 'Fresh pasteurized full cream milk with 6% fat content. Ideal for tea, coffee, and direct consumption. Packed hygienically.',
    price: 30.0, discountPrice: null, categoryId: 'cat_003', categoryName: 'Dairy & Eggs',
    imageUrls: ['https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400'],
    unit: '500 ml', stockQuantity: 200.0, isActive: true, isFeatured: false, rating: 4.6, reviewCount: 210,
    tags: ['milk', 'dairy', 'amul', 'full-cream'],
  },
  {
    id: 'prod_006', name: 'Desi Ghee',
    description: 'Pure desi cow ghee, traditionally prepared using bilona method. Rich in saturated fats and fat-soluble vitamins. Enhances every dish.',
    price: 450.0, discountPrice: 399.0, categoryId: 'cat_003', categoryName: 'Dairy & Eggs',
    imageUrls: ['https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400'],
    unit: '500 ml', stockQuantity: 40.0, isActive: true, isFeatured: true, rating: 4.9, reviewCount: 142,
    tags: ['ghee', 'dairy', 'pure', 'traditional'],
  },
  {
    id: 'prod_007', name: 'Free-Range Brown Eggs',
    description: 'Eggs from free-range hens fed on natural diet. Higher in Omega-3 and vitamins compared to regular eggs. Fresh pack of 12.',
    price: 90.0, discountPrice: 75.0, categoryId: 'cat_003', categoryName: 'Dairy & Eggs',
    imageUrls: ['https://images.unsplash.com/photo-1587486913049-53fc88980cfc?w=400'],
    unit: '12 pieces', stockQuantity: 60.0, isActive: true, isFeatured: false, rating: 4.4, reviewCount: 98,
    tags: ['eggs', 'free-range', 'protein', 'organic'],
  },
  {
    id: 'prod_008', name: 'Basmati Rice (1121)',
    description: 'Premium long-grain Basmati rice aged for 2 years. Aromatic, fluffy, and perfect for biryani, pulao, and daily meals.',
    price: 180.0, discountPrice: 155.0, categoryId: 'cat_004', categoryName: 'Grains & Pulses',
    imageUrls: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400'],
    unit: '1 kg', stockQuantity: 150.0, isActive: true, isFeatured: true, rating: 4.7, reviewCount: 312,
    tags: ['rice', 'basmati', 'grain', 'premium'],
  },
  {
    id: 'prod_009', name: 'Red Masoor Dal',
    description: 'Split red lentils (masoor dal) rich in protein and dietary fiber. Cooks quickly and makes delicious dals, soups, and curries.',
    price: 95.0, discountPrice: null, categoryId: 'cat_004', categoryName: 'Grains & Pulses',
    imageUrls: ['https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=400'],
    unit: '500 g', stockQuantity: 80.0, isActive: true, isFeatured: false, rating: 4.1, reviewCount: 45,
    tags: ['dal', 'lentil', 'protein', 'pulse'],
  },
  {
    id: 'prod_010', name: 'Real Orange Juice',
    description: '100% natural cold-pressed orange juice with no added sugar or preservatives. Packed with Vitamin C and natural goodness.',
    price: 85.0, discountPrice: 70.0, categoryId: 'cat_005', categoryName: 'Beverages',
    imageUrls: ['https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400'],
    unit: '1 litre', stockQuantity: 45.0, isActive: true, isFeatured: false, rating: 4.3, reviewCount: 67,
    tags: ['juice', 'orange', 'natural', 'beverage'],
  },
  {
    id: 'prod_011', name: 'Whole Wheat Bread',
    description: 'Freshly baked whole wheat bread with no preservatives. High in dietary fiber, perfect for sandwiches, toast, and healthy breakfasts.',
    price: 55.0, discountPrice: null, categoryId: 'cat_007', categoryName: 'Bakery',
    imageUrls: ['https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400'],
    unit: '400 g loaf', stockQuantity: 35.0, isActive: true, isFeatured: false, rating: 4.2, reviewCount: 83,
    tags: ['bread', 'wheat', 'bakery', 'fresh'],
  },
  {
    id: 'prod_012', name: 'Turmeric Powder',
    description: 'Pure organic turmeric powder with high curcumin content. Certified organic, no artificial colors or additives. Perfect for cooking and health.',
    price: 65.0, discountPrice: 55.0, categoryId: 'cat_008', categoryName: 'Spices & Condiments',
    imageUrls: ['https://images.unsplash.com/photo-1516824711718-517f642e5fc7?w=400'],
    unit: '200 g', stockQuantity: 90.0, isActive: true, isFeatured: false, rating: 4.6, reviewCount: 156,
    tags: ['turmeric', 'spice', 'organic', 'condiment'],
  },
];

// ── Seed Functions ─────────────────────────────────────────────────────────────

async function seedCategories() {
  console.log('🌿 Seeding categories...');
  const batch = db.batch();
  for (const cat of categories) {
    const { id, ...data } = cat;
    const ref = db.collection('categories').doc(id);
    batch.set(ref, { ...data, createdAt: now }, { merge: true });
  }
  await batch.commit();
  console.log(`   ✅ ${categories.length} categories seeded`);
}

async function seedBanners() {
  console.log('🖼️  Seeding banners...');
  const batch = db.batch();
  for (const banner of banners) {
    const { id, ...data } = banner;
    const ref = db.collection('banners').doc(id);
    batch.set(ref, { ...data, createdAt: now }, { merge: true });
  }
  await batch.commit();
  console.log(`   ✅ ${banners.length} banners seeded`);
}

async function seedProducts() {
  console.log('📦 Seeding products...');
  const batch = db.batch();
  for (const prod of products) {
    const { id, ...data } = prod;
    const ref = db.collection('products').doc(id);
    batch.set(ref, { ...data, dealerId: null, dealerName: null, createdAt: now }, { merge: true });
  }
  await batch.commit();
  console.log(`   ✅ ${products.length} products seeded`);
}

async function seedProductReviews() {
  console.log('⭐ Seeding product reviews...');
  const reviews = [
    { productId: 'prod_001', reviewId: 'rev_001', userId: 'demo_customer', userName: 'Priya Sharma', userPhotoUrl: null, rating: 5.0, comment: 'Excellent quality apples! Super crispy and sweet. Will buy again.' },
    { productId: 'prod_001', reviewId: 'rev_002', userId: 'demo_user2', userName: 'Amit Verma', userPhotoUrl: null, rating: 4.0, comment: 'Good quality, freshly packed. Slight bruise on one apple but overall great.' },
    { productId: 'prod_002', reviewId: 'rev_003', userId: 'demo_customer', userName: 'Priya Sharma', userPhotoUrl: null, rating: 5.0, comment: 'Absolutely delicious! The best Alphonso mangoes I have had. Super creamy and sweet.' },
    { productId: 'prod_006', reviewId: 'rev_004', userId: 'demo_customer', userName: 'Priya Sharma', userPhotoUrl: null, rating: 5.0, comment: 'Best desi ghee I have tasted! Authentic aroma and flavor. Highly recommended.' },
    { productId: 'prod_008', reviewId: 'rev_005', userId: 'demo_user2', userName: 'Ramesh Patel', userPhotoUrl: null, rating: 5.0, comment: 'Long grains, perfect aroma. Great for biryani!' },
  ];

  const batch = db.batch();
  for (const r of reviews) {
    const { productId, reviewId, ...data } = r;
    const ref = db.collection('products').doc(productId).collection('reviews').doc(reviewId);
    batch.set(ref, { ...data, createdAt: now }, { merge: true });
  }
  await batch.commit();
  console.log(`   ✅ ${reviews.length} reviews seeded`);
}

async function seedOrders() {
  console.log('🛒 Seeding sample orders...');
  const orders = [
    {
      id: 'order_001', userId: 'demo_customer', userName: 'Priya Sharma', userEmail: 'priya@example.com', userPhone: '9876543210',
      items: [
        { productId: 'prod_001', productName: 'Fresh Red Apples', quantity: 2, price: 89.0, totalPrice: 178.0, unit: '1 kg', imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400' },
        { productId: 'prod_004', productName: 'Farm Fresh Tomatoes', quantity: 1, price: 32.0, totalPrice: 32.0, unit: '500 g', imageUrl: 'https://images.unsplash.com/photo-1558818498-28c1e002b655?w=400' }
      ],
      deliveryAddress: { fullName: 'Priya Sharma', phone: '9876543210', flatNo: '402', area: 'Green Park', city: 'New Delhi', state: 'Delhi', pincode: '110016', label: 'Home' },
      status: 'pending', subtotal: 210.0, deliveryFee: 40.0, discount: 0.0, total: 250.0, paymentMethod: 'Cash on Delivery', isPaid: false,
      dealerId: 'demo_dealer', dealerName: 'Fresh Mart Delhi', createdAt: now
    },
    {
      id: 'order_002', userId: 'demo_customer', userName: 'Priya Sharma', userEmail: 'priya@example.com', userPhone: '9876543210',
      items: [
        { productId: 'prod_008', productName: 'Basmati Rice (1121)', quantity: 5, price: 155.0, totalPrice: 775.0, unit: '1 kg', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400' }
      ],
      deliveryAddress: { fullName: 'Priya Sharma', phone: '9876543210', flatNo: '402', area: 'Green Park', city: 'New Delhi', state: 'Delhi', pincode: '110016', label: 'Home' },
      status: 'processing', subtotal: 775.0, deliveryFee: 0.0, discount: 50.0, total: 725.0, paymentMethod: 'UPI', isPaid: true,
      dealerId: 'demo_dealer', dealerName: 'Fresh Mart Delhi', createdAt: now
    },
    {
      id: 'order_003', userId: 'demo_user2', userName: 'Amit Verma', userEmail: 'amit@example.com', userPhone: '9988776655',
      items: [
        { productId: 'prod_006', productName: 'Desi Ghee', quantity: 2, price: 399.0, totalPrice: 798.0, unit: '500 ml', imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400' }
      ],
      deliveryAddress: { fullName: 'Amit Verma', phone: '9988776655', flatNo: 'B-12', area: 'Saket', city: 'New Delhi', state: 'Delhi', pincode: '110017', label: 'Office' },
      status: 'delivered', subtotal: 798.0, deliveryFee: 0.0, discount: 0.0, total: 798.0, paymentMethod: 'Card', isPaid: true,
      dealerId: 'demo_dealer', dealerName: 'Fresh Mart Delhi', deliveryPartnerId: 'demo_delivery', deliveryPartnerName: 'Rahul Delivery',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)), // yesterday
      deliveredAt: now
    }
  ];

  const batch = db.batch();
  for (const o of orders) {
    const { id, ...data } = o;
    const ref = db.collection('orders').doc(id);
    batch.set(ref, data, { merge: true });
  }
  await batch.commit();
  console.log(`   ✅ ${orders.length} orders seeded`);
}

async function main() {
  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║  Grocery Platform — Firestore Seeder     ║');
  console.log('╚══════════════════════════════════════════╝\n');

  try {
    await seedCategories();
    await seedBanners();
    await seedProducts();
    await seedProductReviews();
    await seedOrders();

    console.log('\n╔══════════════════════════════════════════╗');
    console.log('║  ✅ ALL DATA SEEDED SUCCESSFULLY!        ║');
    console.log('║                                          ║');
    console.log('║  Next steps:                             ║');
    console.log('║  1. Create Auth users in Firebase Console║');
    console.log('║  2. Register via each app to create user ║');
    console.log('║     docs in Firestore                    ║');
    console.log('║  3. Use Admin app to set roles           ║');
    console.log('╚══════════════════════════════════════════╝\n');
  } catch (err) {
    console.error('❌ Error seeding data:', err);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();

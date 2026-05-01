// Firestore Data Seeder
// Run with: dart run tools/seed_firestore.dart
// This populates your Firestore with reference/demo data for local testing.
//
// NOTE: This script uses the Firebase Admin SDK via a service-account or
// the client-side SDK. Since Flutter apps use the client SDK, and this
// is a standalone Dart script, you should paste these values directly
// in the Firebase console (Firestore > Data > + Add document) OR use
// the Firebase CLI with firestore:emulator to import this seed JSON.
//
// ─────────────────────────────────────────────────────────────────────────────
// USAGE: Copy the JSON documents below and import them into Firestore manually
// via the Firebase console, OR use the firebase-admin npm package.
// ─────────────────────────────────────────────────────────────────────────────

// =============================================================================
// FIRESTORE SEED DATA — Collections & Documents
// =============================================================================

// ──────────────── COLLECTION: categories ────────────────
// Document ID is auto-generated — use any unique ID here

/*
categories/cat_001:
{
  "name": "Fruits",
  "description": "Fresh seasonal fruits from local farms",
  "imageUrl": "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400",
  "sortOrder": 1,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_002:
{
  "name": "Vegetables",
  "description": "Organic vegetables direct from farmers",
  "imageUrl": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400",
  "sortOrder": 2,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_003:
{
  "name": "Dairy & Eggs",
  "description": "Farm-fresh dairy products and eggs",
  "imageUrl": "https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400",
  "sortOrder": 3,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_004:
{
  "name": "Grains & Pulses",
  "description": "Premium grains, lentils, and legumes",
  "imageUrl": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400",
  "sortOrder": 4,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_005:
{
  "name": "Beverages",
  "description": "Juices, teas, and healthy drinks",
  "imageUrl": "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400",
  "sortOrder": 5,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_006:
{
  "name": "Snacks",
  "description": "Healthy and tasty snack options",
  "imageUrl": "https://images.unsplash.com/photo-1616684000067-36952fde56ec?w=400",
  "sortOrder": 6,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_007:
{
  "name": "Bakery",
  "description": "Fresh-baked breads, cakes, and pastries",
  "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400",
  "sortOrder": 7,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}

categories/cat_008:
{
  "name": "Spices & Condiments",
  "description": "Aromatic spices and flavorful condiments",
  "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400",
  "sortOrder": 8,
  "isActive": true,
  "createdAt": "<server-timestamp>"
}
*/

// ──────────────── COLLECTION: banners ────────────────
/*
banners/banner_001:
{
  "title": "Fresh Fruits Sale",
  "subtitle": "Up to 40% off on all fruits",
  "imageUrl": "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800&h=300&fit=crop",
  "actionUrl": "/home/category/cat_001",
  "isActive": true,
  "sortOrder": 1,
  "createdAt": "<server-timestamp>"
}

banners/banner_002:
{
  "title": "Organic Vegetables",
  "subtitle": "Farm to table freshness guaranteed",
  "imageUrl": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&h=300&fit=crop",
  "actionUrl": "/home/category/cat_002",
  "isActive": true,
  "sortOrder": 2,
  "createdAt": "<server-timestamp>"
}

banners/banner_003:
{
  "title": "Free Delivery",
  "subtitle": "On all orders above ₹500",
  "imageUrl": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=300&fit=crop",
  "actionUrl": null,
  "isActive": true,
  "sortOrder": 3,
  "createdAt": "<server-timestamp>"
}
*/

// ──────────────── COLLECTION: products ────────────────
/*
products/prod_001:
{
  "name": "Fresh Red Apples",
  "description": "Crisp and juicy red apples sourced from Himachal Pradesh. Rich in fiber and antioxidants. Perfect for snacking, baking, or adding to salads.",
  "price": 120.0,
  "discountPrice": 89.0,
  "categoryId": "cat_001",
  "categoryName": "Fruits",
  "imageUrls": ["https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400"],
  "unit": "1 kg",
  "stockQuantity": 50.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": true,
  "rating": 4.5,
  "reviewCount": 124,
  "tags": ["fresh", "fruit", "apple", "seasonal"],
  "createdAt": "<server-timestamp>"
}

products/prod_002:
{
  "name": "Alphonso Mangoes",
  "description": "Premium Alphonso mangoes from Ratnagiri, Maharashtra. Known for their rich, creamy texture and sweet aroma. Limited seasonal availability.",
  "price": 250.0,
  "discountPrice": 199.0,
  "categoryId": "cat_001",
  "categoryName": "Fruits",
  "imageUrls": ["https://images.unsplash.com/photo-1553279768-865429fa0078?w=400"],
  "unit": "1 dozen",
  "stockQuantity": 30.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": true,
  "rating": 4.8,
  "reviewCount": 89,
  "tags": ["mango", "alphonso", "seasonal", "premium"],
  "createdAt": "<server-timestamp>"
}

products/prod_003:
{
  "name": "Organic Spinach",
  "description": "Freshly harvested organic spinach leaves. Rich in iron, vitamins, and minerals. Perfect for salads, smoothies, and cooking.",
  "price": 45.0,
  "discountPrice": null,
  "categoryId": "cat_002",
  "categoryName": "Vegetables",
  "imageUrls": ["https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400"],
  "unit": "250 g",
  "stockQuantity": 100.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.2,
  "reviewCount": 56,
  "tags": ["organic", "spinach", "green", "healthy"],
  "createdAt": "<server-timestamp>"
}

products/prod_004:
{
  "name": "Farm Fresh Tomatoes",
  "description": "Locally grown, vine-ripened tomatoes bursting with natural flavor. Ideal for cooking, making sauces, and salads.",
  "price": 40.0,
  "discountPrice": 32.0,
  "categoryId": "cat_002",
  "categoryName": "Vegetables",
  "imageUrls": ["https://images.unsplash.com/photo-1558818498-28c1e002b655?w=400"],
  "unit": "500 g",
  "stockQuantity": 75.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": true,
  "rating": 4.3,
  "reviewCount": 78,
  "tags": ["tomato", "farm", "fresh", "vegetable"],
  "createdAt": "<server-timestamp>"
}

products/prod_005:
{
  "name": "Amul Full Cream Milk",
  "description": "Fresh pasteurized full cream milk with 6% fat content. Ideal for tea, coffee, and direct consumption. Packed hygienically.",
  "price": 30.0,
  "discountPrice": null,
  "categoryId": "cat_003",
  "categoryName": "Dairy & Eggs",
  "imageUrls": ["https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400"],
  "unit": "500 ml",
  "stockQuantity": 200.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.6,
  "reviewCount": 210,
  "tags": ["milk", "dairy", "amul", "full-cream"],
  "createdAt": "<server-timestamp>"
}

products/prod_006:
{
  "name": "Desi Ghee",
  "description": "Pure desi cow ghee, traditionally prepared using bilona method. Rich in saturated fats and fat-soluble vitamins. Enhances every dish.",
  "price": 450.0,
  "discountPrice": 399.0,
  "categoryId": "cat_003",
  "categoryName": "Dairy & Eggs",
  "imageUrls": ["https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400"],
  "unit": "500 ml",
  "stockQuantity": 40.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": true,
  "rating": 4.9,
  "reviewCount": 142,
  "tags": ["ghee", "dairy", "pure", "traditional"],
  "createdAt": "<server-timestamp>"
}

products/prod_007:
{
  "name": "Free-Range Brown Eggs",
  "description": "Eggs from free-range hens fed on natural diet. Higher in Omega-3 and vitamins compared to regular eggs. Fresh pack of 12.",
  "price": 90.0,
  "discountPrice": 75.0,
  "categoryId": "cat_003",
  "categoryName": "Dairy & Eggs",
  "imageUrls": ["https://images.unsplash.com/photo-1587486913049-53fc88980cfc?w=400"],
  "unit": "12 pieces",
  "stockQuantity": 60.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.4,
  "reviewCount": 98,
  "tags": ["eggs", "free-range", "protein", "organic"],
  "createdAt": "<server-timestamp>"
}

products/prod_008:
{
  "name": "Basmati Rice (1121)",
  "description": "Premium long-grain Basmati rice aged for 2 years. Aromatic, fluffy, and perfect for biryani, pulao, and daily meals.",
  "price": 180.0,
  "discountPrice": 155.0,
  "categoryId": "cat_004",
  "categoryName": "Grains & Pulses",
  "imageUrls": ["https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400"],
  "unit": "1 kg",
  "stockQuantity": 150.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": true,
  "rating": 4.7,
  "reviewCount": 312,
  "tags": ["rice", "basmati", "grain", "premium"],
  "createdAt": "<server-timestamp>"
}

products/prod_009:
{
  "name": "Red Masoor Dal",
  "description": "Split red lentils (masoor dal) rich in protein and dietary fiber. Cooks quickly and makes delicious dals, soups, and curries.",
  "price": 95.0,
  "discountPrice": null,
  "categoryId": "cat_004",
  "categoryName": "Grains & Pulses",
  "imageUrls": ["https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=400"],
  "unit": "500 g",
  "stockQuantity": 80.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.1,
  "reviewCount": 45,
  "tags": ["dal", "lentil", "protein", "pulse"],
  "createdAt": "<server-timestamp>"
}

products/prod_010:
{
  "name": "Real Orange Juice",
  "description": "100% natural cold-pressed orange juice with no added sugar or preservatives. Packed with Vitamin C and natural goodness.",
  "price": 85.0,
  "discountPrice": 70.0,
  "categoryId": "cat_005",
  "categoryName": "Beverages",
  "imageUrls": ["https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400"],
  "unit": "1 litre",
  "stockQuantity": 45.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.3,
  "reviewCount": 67,
  "tags": ["juice", "orange", "natural", "beverage"],
  "createdAt": "<server-timestamp>"
}

products/prod_011:
{
  "name": "Whole Wheat Bread",
  "description": "Freshly baked whole wheat bread with no preservatives. High in dietary fiber, perfect for sandwiches, toast, and healthy breakfasts.",
  "price": 55.0,
  "discountPrice": null,
  "categoryId": "cat_007",
  "categoryName": "Bakery",
  "imageUrls": ["https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400"],
  "unit": "400 g loaf",
  "stockQuantity": 35.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.2,
  "reviewCount": 83,
  "tags": ["bread", "wheat", "bakery", "fresh"],
  "createdAt": "<server-timestamp>"
}

products/prod_012:
{
  "name": "Turmeric Powder",
  "description": "Pure organic turmeric powder with high curcumin content. Certified organic, no artificial colors or additives. Perfect for cooking and health.",
  "price": 65.0,
  "discountPrice": 55.0,
  "categoryId": "cat_008",
  "categoryName": "Spices & Condiments",
  "imageUrls": ["https://images.unsplash.com/photo-1516824711718-517f642e5fc7?w=400"],
  "unit": "200 g",
  "stockQuantity": 90.0,
  "dealerId": null,
  "dealerName": null,
  "isActive": true,
  "isFeatured": false,
  "rating": 4.6,
  "reviewCount": 156,
  "tags": ["turmeric", "spice", "organic", "condiment"],
  "createdAt": "<server-timestamp>"
}
*/

// ──────────────── COLLECTION: users ────────────────
// Create these after registering via the app — use the Firebase Auth UID as doc ID
// OR create manually with these sample user IDs for testing

/*
users/<ADMIN_UID>:    (create via Firebase Auth first)
{
  "name": "Admin User",
  "email": "admin@freshmart.com",
  "phone": "+91-9900000001",
  "photoUrl": null,
  "role": "admin",
  "isActive": true,
  "isApproved": true,
  "fcmToken": null,
  "createdAt": "<server-timestamp>",
  "shopName": null,
  "shopAddress": null,
  "rating": null,
  "totalDeliveries": 0,
  "totalEarnings": 0.0
}

users/<DEALER_UID>:
{
  "name": "Ravi's Fresh Mart",
  "email": "dealer@freshmart.com",
  "phone": "+91-9900000002",
  "photoUrl": null,
  "role": "dealer",
  "isActive": true,
  "isApproved": true,
  "fcmToken": null,
  "createdAt": "<server-timestamp>",
  "shopName": "Ravi's Fresh Mart",
  "shopAddress": "123, Market Street, Bangalore",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "rating": 4.5,
  "totalDeliveries": 0,
  "totalEarnings": 0.0
}

users/<DELIVERY_UID>:
{
  "name": "Suresh Kumar",
  "email": "delivery@freshmart.com",
  "phone": "+91-9900000003",
  "photoUrl": null,
  "role": "deliveryPartner",
  "isActive": true,
  "isApproved": true,
  "fcmToken": null,
  "createdAt": "<server-timestamp>",
  "shopName": null,
  "shopAddress": null,
  "rating": 4.8,
  "totalDeliveries": 47,
  "totalEarnings": 2350.0
}

users/<CUSTOMER_UID>:
{
  "name": "Priya Sharma",
  "email": "customer@freshmart.com",
  "phone": "+91-9900000004",
  "photoUrl": null,
  "role": "customer",
  "isActive": true,
  "isApproved": true,
  "fcmToken": null,
  "createdAt": "<server-timestamp>",
  "shopName": null,
  "shopAddress": null,
  "rating": null,
  "totalDeliveries": 0,
  "totalEarnings": 0.0
}
*/

// ──────────────── SUBCOLLECTION: users/<CUSTOMER_UID>/addresses ────────────────
/*
users/<CUSTOMER_UID>/addresses/addr_001:
{
  "id": "addr_001",
  "userId": "<CUSTOMER_UID>",
  "label": "Home",
  "fullName": "Priya Sharma",
  "phone": "+91-9900000004",
  "addressLine1": "42, 3rd Cross, Indiranagar",
  "addressLine2": "Near Brigade Road",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560038",
  "isDefault": true
}

users/<CUSTOMER_UID>/addresses/addr_002:
{
  "id": "addr_002",
  "userId": "<CUSTOMER_UID>",
  "label": "Work",
  "fullName": "Priya Sharma",
  "phone": "+91-9900000004",
  "addressLine1": "UB City, Vittal Mallya Road",
  "addressLine2": "Floor 8, Tower A",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560001",
  "isDefault": false
}
*/

// ──────────────── COLLECTION: orders ────────────────
/*
orders/order_001:
{
  "userId": "<CUSTOMER_UID>",
  "userName": "Priya Sharma",
  "userEmail": "customer@freshmart.com",
  "userPhone": "+91-9900000004",
  "items": [
    {
      "productId": "prod_001",
      "productName": "Fresh Red Apples",
      "unit": "1 kg",
      "price": 89.0,
      "quantity": 2,
      "imageUrl": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400"
    },
    {
      "productId": "prod_003",
      "productName": "Organic Spinach",
      "unit": "250 g",
      "price": 45.0,
      "quantity": 1,
      "imageUrl": "https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400"
    }
  ],
  "deliveryAddress": {
    "id": "addr_001",
    "userId": "<CUSTOMER_UID>",
    "label": "Home",
    "fullName": "Priya Sharma",
    "phone": "+91-9900000004",
    "addressLine1": "42, 3rd Cross, Indiranagar",
    "addressLine2": "Near Brigade Road",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560038",
    "isDefault": true
  },
  "status": "delivered",
  "subtotal": 223.0,
  "deliveryFee": 0.0,
  "discount": 0.0,
  "total": 223.0,
  "paymentMethod": "Cash on Delivery",
  "isPaid": true,
  "deliveryPartnerId": "<DELIVERY_UID>",
  "deliveryPartnerName": "Suresh Kumar",
  "deliveryPartnerPhone": "+91-9900000003",
  "dealerId": "<DEALER_UID>",
  "dealerName": "Ravi's Fresh Mart",
  "cancellationReason": null,
  "notes": null,
  "createdAt": "<server-timestamp>",
  "deliveredAt": "<server-timestamp>"
}

orders/order_002:
{
  "userId": "<CUSTOMER_UID>",
  "userName": "Priya Sharma",
  "userEmail": "customer@freshmart.com",
  "userPhone": "+91-9900000004",
  "items": [
    {
      "productId": "prod_006",
      "productName": "Desi Ghee",
      "unit": "500 ml",
      "price": 399.0,
      "quantity": 1,
      "imageUrl": "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400"
    },
    {
      "productId": "prod_008",
      "productName": "Basmati Rice (1121)",
      "unit": "1 kg",
      "price": 155.0,
      "quantity": 2,
      "imageUrl": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400"
    }
  ],
  "deliveryAddress": {
    "id": "addr_001",
    "userId": "<CUSTOMER_UID>",
    "label": "Home",
    "fullName": "Priya Sharma",
    "phone": "+91-9900000004",
    "addressLine1": "42, 3rd Cross, Indiranagar",
    "addressLine2": "Near Brigade Road",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560038",
    "isDefault": true
  },
  "status": "processing",
  "subtotal": 709.0,
  "deliveryFee": 0.0,
  "discount": 0.0,
  "total": 709.0,
  "paymentMethod": "UPI",
  "isPaid": true,
  "deliveryPartnerId": null,
  "deliveryPartnerName": null,
  "deliveryPartnerPhone": null,
  "dealerId": "<DEALER_UID>",
  "dealerName": "Ravi's Fresh Mart",
  "cancellationReason": null,
  "notes": "Please deliver before 6 PM",
  "createdAt": "<server-timestamp>",
  "deliveredAt": null
}

orders/order_003:
{
  "userId": "<CUSTOMER_UID>",
  "userName": "Priya Sharma",
  "userEmail": "customer@freshmart.com",
  "userPhone": "+91-9900000004",
  "items": [
    {
      "productId": "prod_002",
      "productName": "Alphonso Mangoes",
      "unit": "1 dozen",
      "price": 199.0,
      "quantity": 1,
      "imageUrl": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=400"
    }
  ],
  "deliveryAddress": {
    "id": "addr_001",
    "userId": "<CUSTOMER_UID>",
    "label": "Home",
    "fullName": "Priya Sharma",
    "phone": "+91-9900000004",
    "addressLine1": "42, 3rd Cross, Indiranagar",
    "addressLine2": "Near Brigade Road",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560038",
    "isDefault": true
  },
  "status": "pending",
  "subtotal": 199.0,
  "deliveryFee": 25.0,
  "discount": 0.0,
  "total": 224.0,
  "paymentMethod": "Cash on Delivery",
  "isPaid": false,
  "deliveryPartnerId": null,
  "deliveryPartnerName": null,
  "deliveryPartnerPhone": null,
  "dealerId": null,
  "dealerName": null,
  "cancellationReason": null,
  "notes": null,
  "createdAt": "<server-timestamp>",
  "deliveredAt": null
}

orders/order_004:
{
  "userId": "<CUSTOMER_UID>",
  "userName": "Priya Sharma",
  "userEmail": "customer@freshmart.com",
  "userPhone": "+91-9900000004",
  "items": [
    {
      "productId": "prod_005",
      "productName": "Amul Full Cream Milk",
      "unit": "500 ml",
      "price": 30.0,
      "quantity": 4,
      "imageUrl": "https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400"
    },
    {
      "productId": "prod_007",
      "productName": "Free-Range Brown Eggs",
      "unit": "12 pieces",
      "price": 75.0,
      "quantity": 1,
      "imageUrl": "https://images.unsplash.com/photo-1587486913049-53fc88980cfc?w=400"
    }
  ],
  "deliveryAddress": {
    "id": "addr_002",
    "userId": "<CUSTOMER_UID>",
    "label": "Work",
    "fullName": "Priya Sharma",
    "phone": "+91-9900000004",
    "addressLine1": "UB City, Vittal Mallya Road",
    "addressLine2": "Floor 8, Tower A",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560001",
    "isDefault": false
  },
  "status": "accepted",
  "subtotal": 195.0,
  "deliveryFee": 25.0,
  "discount": 0.0,
  "total": 220.0,
  "paymentMethod": "Cash on Delivery",
  "isPaid": false,
  "deliveryPartnerId": null,
  "deliveryPartnerName": null,
  "deliveryPartnerPhone": null,
  "dealerId": "<DEALER_UID>",
  "dealerName": "Ravi's Fresh Mart",
  "cancellationReason": null,
  "notes": null,
  "createdAt": "<server-timestamp>",
  "deliveredAt": null
}
*/

// ──────────────── SUBCOLLECTION: products/<id>/reviews ────────────────
/*
products/prod_001/reviews/rev_001:
{
  "userId": "<CUSTOMER_UID>",
  "userName": "Priya Sharma",
  "userPhotoUrl": null,
  "rating": 5.0,
  "comment": "Excellent quality apples! Super crispy and sweet. Will buy again.",
  "createdAt": "<server-timestamp>"
}

products/prod_001/reviews/rev_002:
{
  "userId": "user_002",
  "userName": "Amit Verma",
  "userPhotoUrl": null,
  "rating": 4.0,
  "comment": "Good quality, freshly packed. Slight bruise on one apple but overall great.",
  "createdAt": "<server-timestamp>"
}

products/prod_006/reviews/rev_003:
{
  "userId": "<CUSTOMER_UID>",
  "userName": "Priya Sharma",
  "userPhotoUrl": null,
  "rating": 5.0,
  "comment": "Best desi ghee I have tasted! Authentic aroma and flavor. Highly recommended.",
  "createdAt": "<server-timestamp>"
}
*/

void main() {
  print('''
╔════════════════════════════════════════════════════╗
║       GROCERY PLATFORM — FIRESTORE SEED DATA       ║
╠════════════════════════════════════════════════════╣
║  This file contains all seed data as comments.     ║
║                                                    ║
║  To seed your Firestore database:                  ║
║                                                    ║
║  OPTION 1: Firebase Console                        ║
║    1. Go to https://console.firebase.google.com    ║
║    2. Navigate to Firestore Database               ║
║    3. Create the collections and documents above   ║
║                                                    ║
║  OPTION 2: Firebase Emulator                       ║
║    1. Export JSON using emulator                   ║
║    2. Import via: firebase emulators:start         ║
║                                                    ║
║  OPTION 3: Admin SDK (Node.js script)              ║
║    node scripts/seed.js                            ║
║                                                    ║
║  DEMO ACCOUNTS:                                    ║
║    Admin:    admin@freshmart.com / Admin@123       ║
║    Dealer:   dealer@freshmart.com / Dealer@123     ║
║    Delivery: delivery@freshmart.com / Deliver@123  ║
║    Customer: customer@freshmart.com / User@123     ║
╚════════════════════════════════════════════════════╝
  ''');
}

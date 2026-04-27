require('dotenv').config();
const express = require('express');
const axios = require('axios');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();

// 🛠️ 1. GLOBAL SETTINGS
app.use(cors());
app.use(express.json());

// 🔑 2. FIREBASE INITIALIZATION
try {
  if (!process.env.FIREBASE_CONFIG) {
    throw new Error("FIREBASE_CONFIG environment variable is missing!");
  }
  const firebaseConfig = JSON.parse(process.env.FIREBASE_CONFIG);
  admin.initializeApp({
    credential: admin.credential.cert(firebaseConfig)
  });
  console.log("🚀 Firebase Admin initialized!");
} catch (e) {
  console.error("❌ Firebase Init Error:", e.message);
}
const db = admin.firestore();

// 🛡️ 3. CASHFREE CONFIG
const CASHFREE_APP_ID = process.env.CASHFREE_APP_ID;
const CASHFREE_SECRET = process.env.CASHFREE_SECRET_KEY || process.env.CASHFREE_SECRET;
const IS_PROD = true;
const BASE_URL = IS_PROD ? "https://api.cashfree.com/pg" : "https://sandbox.cashfree.com/pg";

// ✅ 4. HEALTH CHECKS
app.get('/', (req, res) => res.status(200).send("Swayam Server v3.0 is LIVE!"));

// 🚀 5. CREATE ORDER ENDPOINT
app.post('/create-order', async (req, res) => {
  console.log("📩 Received order request for user:", req.body.customerId);
  try {
    const { amount, customerId, customerPhone, days } = req.body;

    // 🛡️ MASTER FIX: Use the full ID (The SDK Bridge can handle it now!)
    const cleanPhone = customerPhone.replace(/[^0-9]/g, "").slice(-10);
    
    console.log(`📱 Phone: ${cleanPhone} | 🆔 Customer: ${customerId}`);
    
    const response = await axios.post(`${BASE_URL}/orders`, {
      order_id: `OR_${Date.now()}`,
      order_amount: amount,
      order_currency: "INR",
      customer_details: {
        customer_id: customerId, // 🚀 Back to Full ID
        customer_phone: cleanPhone,
        customer_name: "Swayam Driver",
        customer_email: "driver@swayam.com" 
      },
      order_meta: {
        payment_methods: "upi,cc,dc,nb",
        return_url: "https://swayam-universal-backend.onrender.com/",
        notify_url: "https://swayam-universal-backend.onrender.com/webhook"
      },
      order_note: `Subscription: ${days} days`
    }, {
      headers: {
        'x-api-version': '2023-08-01',
        'x-client-id': CASHFREE_APP_ID,
        'x-client-secret': CASHFREE_SECRET,
        'Content-Type': 'application/json'
      }
    });

    console.log("✅ Cashfree Full Response:", JSON.stringify(response.data, null, 2));
    
    // 🛡️ SDK BRIDGE: Point the app to our own server's payment page
    const paymentLink = `https://swayam-universal-backend.onrender.com/pay/${response.data.payment_session_id}`;
    
    res.status(200).json({
      ...response.data,
      payment_link: paymentLink
    });
  } catch (error) {
    const errorData = error.response ? error.response.data : error.message;
    console.error("❌ Order Creation Failed:", JSON.stringify(errorData, null, 2));
    res.status(500).json({ error: errorData });
  }
});

// 🚀 6. SDK BRIDGE ENDPOINT (The "Magic" Page)
app.get('/pay/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Swayam Secure Payment</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
        <style>
            body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background: #121212; color: white; }
            .loader { border: 4px solid #f3f3f3; border-top: 4px solid #f39c12; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin-bottom: 20px; }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        </style>
    </head>
    <body>
        <div class="loader"></div>
        <p>Opening Secure Payment...</p>
        <script>
            const cashfree = Cashfree({ mode: "production" });
            cashfree.checkout({ paymentSessionId: "${sessionId}" });
        </script>
    </body>
    </html>
  `);
});

// 🔔 7. WEBHOOK ENDPOINT
app.post('/webhook', async (req, res) => {
  res.status(200).send("OK");
  try {
    const { data } = req.body;
    if (!data || !data.order || !data.payment) return;

    const paymentStatus = data.payment.payment_status;
    const customerId = data.customer_details.customer_id;
    const amount = data.order.order_amount;

    if (paymentStatus === "SUCCESS") {
      let daysToAdd = 1;
      if (amount >= 99) daysToAdd = 30;
      else if (amount >= 49) daysToAdd = 15;

      const userRef = db.collection('users').doc(customerId);
      const userDoc = await userRef.get();

      let currentExpiry = new Date();
      if (userDoc.exists && userDoc.data().expiry) {
        const oldExpiry = userDoc.data().expiry.toDate();
        if (oldExpiry > currentExpiry) currentExpiry = oldExpiry;
      }

      const newExpiry = new Date(currentExpiry.getTime() + (daysToAdd * 24 * 60 * 60 * 1000));
      await userRef.set({
        expiry: admin.firestore.Timestamp.fromDate(newExpiry),
        active: true,
        lastPaymentAmount: Number(amount),
        lastPaymentDate: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now()
      }, { merge: true });
      console.log(`✅ Successfully added ${daysToAdd} days to user ${customerId}`);
    }
  } catch (error) {
    console.error("❌ Webhook Error:", error.message);
  }
});

// 🚀 Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`-------------------------------------------`);
  console.log(`🚀 SWAYAM SERVER v3.0 - MASTER FIX ACTIVE`);
  console.log(`🔗 Health Check: http://localhost:${PORT}/`);
  console.log(`-------------------------------------------`);
});

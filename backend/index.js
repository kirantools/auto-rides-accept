const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// --- CONFIGURATION ---
// Get these from your Cashfree Dashboard or .env file
const CASHFREE_APP_ID = process.env.CASHFREE_APP_ID || "TEST11058277323481b361dfc59fcb8577285011";
const CASHFREE_SECRET_KEY = process.env.CASHFREE_SECRET_KEY || "cfsk_ma_test_d6d0431fe60f76f3ba05bef41344adeb_e0360c0c";
const CASHFREE_ENV = "sandbox"; // Set to "sandbox" for testing with APK

const CASHFREE_BASE_URL = CASHFREE_ENV === "sandbox"
    ? "https://sandbox.cashfree.com/pg"
    : "https://api.cashfree.com/pg";
app.post('/create-order', async (req, res) => {
    try {
        const { amount, customerId, customerPhone } = req.body;
        const orderId = `order_${Date.now()}`;
        console.log(`Creating order: ${orderId} for amount: ${amount}`);

        const response = await axios.post(`${CASHFREE_BASE_URL}/orders`, {
            order_id: orderId,
            order_amount: amount,
            order_currency: "INR",
            customer_details: {
                customer_id: customerId || `dev_${Date.now()}`,
                customer_phone: customerPhone || "9999999999"
            }
        }, {
            headers: {
                'x-client-id': CASHFREE_APP_ID,
                'x-client-secret': CASHFREE_SECRET_KEY,
                'x-api-version': '2023-08-01',
                'Content-Type': 'application/json'
            }
        });

        console.log("Cashfree Success Response:", response.data);

        if (!response.data.payment_session_id) {
            throw new Error("Cashfree did not return a payment_session_id");
        }

        res.json({
            payment_session_id: response.data.payment_session_id,
            order_id: response.data.order_id
        });

    } catch (error) {
        const errorData = error.response ? error.response.data : { message: error.message };
        console.error("Cashfree Error Detail:", errorData);
        res.status(500).json({ 
            error: "Failed to create order", 
            message: errorData.message || "Unknown Error",
            details: errorData
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ Payment Server running on port ${PORT}`);
});

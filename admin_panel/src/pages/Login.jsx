import React, { useState } from 'react';
import { RecaptchaVerifier, signInWithPhoneNumber } from 'firebase/auth';
import { auth } from '../firebase';
import { ShieldAlert, Phone, Lock } from 'lucide-react';

export default function Login() {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otp, setOtp] = useState('');
  const [confirmationResult, setConfirmationResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const setupRecaptcha = () => {
    if (!window.recaptchaVerifier) {
      window.recaptchaVerifier = new RecaptchaVerifier(auth, 'recaptcha-container', {
        'size': 'invisible'
      });
    }
  };

  const handleSendOTP = async () => {
    if (!phoneNumber) return alert("Enter phone number");
    setLoading(true);
    setupRecaptcha();
    
    const appVerifier = window.recaptchaVerifier;
    const formatPhone = phoneNumber.startsWith('+') ? phoneNumber : `+91${phoneNumber}`;
    
    try {
      const result = await signInWithPhoneNumber(auth, formatPhone, appVerifier);
      setConfirmationResult(result);
      alert("OTP Sent!");
    } catch (error) {
      console.error(error);
      alert("Error sending OTP. Make sure phone number is correct.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOTP = async () => {
    if (!otp) return alert("Enter OTP");
    setLoading(true);
    try {
      await confirmationResult.confirm(otp);
    } catch (error) {
      console.error(error);
      alert("Invalid OTP");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-dark flex items-center justify-center p-6">
      <div id="recaptcha-container"></div>
      
      <div className="bg-card p-10 rounded-3xl border border-white/5 w-full max-w-md text-center shadow-2xl">
        <div className="w-16 h-16 bg-primary rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg shadow-primary/20">
          <ShieldAlert className="text-black" size={32} />
        </div>
        <h1 className="text-3xl font-bold mb-2">SWAYAM <span className="text-primary">ADMIN</span></h1>
        <p className="text-gray-400 mb-8">Sign in with your admin mobile number.</p>
        
        {!confirmationResult ? (
          <div className="space-y-4">
            <div className="relative">
              <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={20} />
              <input 
                type="text" 
                placeholder="Mobile Number" 
                className="w-full bg-white/5 border border-white/10 rounded-2xl pl-12 pr-4 py-4 focus:border-primary outline-none transition-all"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
              />
            </div>
            <button 
              onClick={handleSendOTP}
              disabled={loading}
              className="w-full bg-primary text-black font-bold py-4 rounded-2xl hover:scale-105 transition-all active:scale-95 disabled:opacity-50"
            >
              {loading ? "SENDING..." : "SEND OTP"}
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={20} />
              <input 
                type="text" 
                placeholder="6-Digit OTP" 
                className="w-full bg-white/5 border border-white/10 rounded-2xl pl-12 pr-4 py-4 focus:border-primary outline-none transition-all"
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
              />
            </div>
            <button 
              onClick={handleVerifyOTP}
              disabled={loading}
              className="w-full bg-primary text-black font-bold py-4 rounded-2xl hover:scale-105 transition-all active:scale-95 disabled:opacity-50"
            >
              {loading ? "VERIFYING..." : "LOGIN NOW"}
            </button>
            <button 
              onClick={() => setConfirmationResult(null)}
              className="text-gray-500 text-sm hover:text-white"
            >
              Change Phone Number
            </button>
          </div>
        )}
        
        <p className="mt-8 text-xs text-gray-500 uppercase tracking-widest font-bold">
          Authorized Personnel Only
        </p>
      </div>
    </div>
  );
}

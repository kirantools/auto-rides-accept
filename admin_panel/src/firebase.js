import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyCdLrdWaq5MFYPXnqSgdiOn7AhZ4TtQbbU",
  authDomain: "swayam-universal.firebaseapp.com",
  projectId: "swayam-universal",
  storageBucket: "swayam-universal.firebasestorage.app",
  messagingSenderId: "1090207905074",
  appId: "1:1090207905074:web:admin_panel"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);

import React, { useState } from 'react';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { Megaphone, Send, History, Trash2 } from 'lucide-react';

export default function Broadcast() {
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSend = async () => {
    if (!message.trim()) return alert("Enter a message");
    if (!window.confirm("Send this message to ALL drivers?")) return;
    
    setLoading(true);
    try {
      await setDoc(doc(db, 'app_settings', 'announcement'), {
        message: message.trim(),
        active: true,
        timestamp: serverTimestamp()
      });
      alert("Announcement sent! Every driver will see it when they open the app.");
      setMessage('');
    } catch (e) {
      console.error(e);
      alert("Failed to send message.");
    } finally {
      setLoading(false);
    }
  };

  const handleClear = async () => {
    if (!window.confirm("Remove the current announcement?")) return;
    await setDoc(doc(db, 'app_settings', 'announcement'), { active: false });
    alert("Announcement cleared.");
  };

  return (
    <div className="max-w-3xl space-y-8">
      <div>
        <h2 className="text-3xl font-bold mb-2 text-white">Broadcast</h2>
        <p className="text-gray-400">Send instant announcements to all driver devices.</p>
      </div>

      <div className="bg-card p-8 rounded-3xl border border-white/5 space-y-6">
        <div className="flex items-center gap-3 text-primary mb-2">
          <Megaphone size={24} />
          <h3 className="text-xl font-bold">New Announcement</h3>
        </div>

        <div className="space-y-2">
          <label className="text-sm text-gray-400">Message to Drivers</label>
          <textarea 
            rows="4"
            placeholder="Type your message here..."
            className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 focus:border-primary outline-none transition-all text-white resize-none"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          ></textarea>
        </div>

        <div className="flex gap-4">
          <button 
            onClick={handleSend}
            disabled={loading}
            className="flex-1 bg-primary text-black font-bold py-4 rounded-2xl flex items-center justify-center gap-3 hover:scale-105 transition-all active:scale-95 disabled:opacity-50"
          >
            <Send size={20} />
            {loading ? "SENDING..." : "SEND TO ALL DRIVERS"}
          </button>
          
          <button 
            onClick={handleClear}
            className="px-6 bg-white/5 text-red-500 font-bold rounded-2xl border border-red-500/20 hover:bg-red-500/10 transition-all"
            title="Clear Current Message"
          >
            <Trash2 size={20} />
          </button>
        </div>

        <div className="pt-6 border-t border-white/5">
          <h4 className="text-gray-400 text-sm font-bold uppercase tracking-widest mb-4">How it works</h4>
          <ul className="space-y-3 text-sm text-gray-500">
            <li className="flex gap-2">
              <span className="text-primary">•</span>
              When you send a message, a popup or banner will appear on the Home Screen of every driver's app.
            </li>
            <li className="flex gap-2">
              <span className="text-primary">•</span>
              Use this for price changes, system updates, or holiday wishes.
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}

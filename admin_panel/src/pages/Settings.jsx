import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, getDocs, doc, updateDoc, Timestamp } from 'firebase/firestore';

export default function Settings() {
  const [prices, setPrices] = useState({
    plan1: 10,
    plan15: 49,
    plan30: 99,
    tutorialLink: '',
    requiredVersion: '1.0.0',
    updateLink: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const fetchSettings = async () => {
      const snap = await getDocs(collection(db, 'app_settings'));
      const pricingDoc = snap.docs.find(d => d.id === 'pricing');
      if (pricingDoc) setPrices(pricingDoc.data());
      setLoading(false);
    };
    fetchSettings();
  }, []);

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateDoc(doc(db, 'app_settings', 'pricing'), prices);
      alert('Settings saved successfully!');
    } catch (e) {
      alert('Error saving settings: ' + e.message);
    }
    setSaving(false);
  };

  if (loading) return <div className="p-8 text-white">Loading Settings...</div>;

  return (
    <div className="p-8 max-w-4xl">
      <h1 className="text-3xl font-bold text-white mb-8">App Configuration</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Pricing Section */}
        <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
          <h2 className="text-xl font-bold text-orange-500 mb-6 flex items-center">
            <span className="mr-2">💰</span> Subscription Prices
          </h2>
          <div className="space-y-4">
            <div>
              <label className="text-slate-400 text-sm block mb-1">1 Day Plan (₹)</label>
              <input 
                type="number" 
                value={prices.plan1}
                onChange={(e) => setPrices({...prices, plan1: parseInt(e.target.value)})}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white outline-none focus:border-orange-500"
              />
            </div>
            <div>
              <label className="text-slate-400 text-sm block mb-1">15 Days Plan (₹)</label>
              <input 
                type="number" 
                value={prices.plan15}
                onChange={(e) => setPrices({...prices, plan15: parseInt(e.target.value)})}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white outline-none focus:border-orange-500"
              />
            </div>
            <div>
              <label className="text-slate-400 text-sm block mb-1">30 Days Plan (₹)</label>
              <input 
                type="number" 
                value={prices.plan30}
                onChange={(e) => setPrices({...prices, plan30: parseInt(e.target.value)})}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white outline-none focus:border-orange-500"
              />
            </div>
          </div>
        </div>

        {/* Update & Version Section */}
        <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
          <h2 className="text-xl font-bold text-orange-500 mb-6 flex items-center">
            <span className="mr-2">🚀</span> Version Control
          </h2>
          <div className="space-y-4">
            <div>
              <label className="text-slate-400 text-sm block mb-1">Required App Version (e.g. 1.0.0)</label>
              <input 
                type="text" 
                value={prices.requiredVersion}
                onChange={(e) => setPrices({...prices, requiredVersion: e.target.value})}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white outline-none focus:border-orange-500"
              />
            </div>
            <div>
              <label className="text-slate-400 text-sm block mb-1">App Update Link (APK Link)</label>
              <input 
                type="text" 
                value={prices.updateLink}
                onChange={(e) => setPrices({...prices, updateLink: e.target.value})}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white outline-none focus:border-orange-500"
              />
            </div>
            <div>
              <label className="text-slate-400 text-sm block mb-1">Tutorial Video Link</label>
              <input 
                type="text" 
                value={prices.tutorialLink}
                onChange={(e) => setPrices({...prices, tutorialLink: e.target.value})}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white outline-none focus:border-orange-500"
              />
            </div>
          </div>
        </div>
      </div>

      <button 
        onClick={handleSave}
        disabled={saving}
        className="mt-8 w-full bg-orange-500 hover:bg-orange-600 text-black font-bold py-4 rounded-xl transition-all shadow-lg shadow-orange-500/20 disabled:opacity-50"
      >
        {saving ? 'SAVING CHANGES...' : 'SAVE ALL SETTINGS'}
      </button>
    </div>
  );
}

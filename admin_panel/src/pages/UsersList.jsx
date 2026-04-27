import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, getDocs, doc, updateDoc, Timestamp, deleteDoc } from 'firebase/firestore';

export default function UsersList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    const snap = await getDocs(collection(db, 'users'));
    setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  };

  const toggleBan = async (user) => {
    const newStatus = !user.isBanned;
    await updateDoc(doc(db, 'users', user.id), { isBanned: newStatus });
    fetchUsers();
  };

  const handleAddSubscription = async (user, days, price) => {
    const now = user.expiry ? user.expiry.toDate() : new Date();
    const baseDate = now > new Date() ? now : new Date();
    const newExpiry = new Date(baseDate.getTime() + (days * 24 * 60 * 60 * 1000));
    
    await updateDoc(doc(db, 'users', user.id), { 
      expiry: Timestamp.fromDate(newExpiry),
      lastPaymentAmount: price,
      lastPaymentDate: Timestamp.now()
    });
    alert(`Added ${days} days to ${user.phone || user.id}`);
    fetchUsers();
  };

  const adjustExpiry = async (user, hours) => {
    const now = user.expiry ? user.expiry.toDate() : new Date();
    const baseDate = now > new Date() ? now : new Date();
    const newExpiry = new Date(baseDate.getTime() + (hours * 60 * 60 * 1000));
    
    await updateDoc(doc(db, 'users', user.id), { 
      expiry: Timestamp.fromDate(newExpiry),
      updated_at: Timestamp.now()
    });
    alert(`${hours > 0 ? 'Added' : 'Subtracted'} ${Math.abs(hours)} hour(s)`);
    fetchUsers();
  };

  const deleteUser = async (id) => {
    if (window.confirm("Delete this user permanently?")) {
      await deleteDoc(doc(db, 'users', id));
      fetchUsers();
    }
  };

  const filteredUsers = users.filter(u => 
    (u.phone?.includes(searchTerm)) || (u.id.includes(searchTerm))
  );

  if (loading) return <div className="p-8 text-white">Loading Drivers...</div>;

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-white">Driver Management</h1>
        <input 
          type="text" 
          placeholder="Search by phone..." 
          className="bg-slate-800 border border-slate-700 text-white px-4 py-2 rounded-lg outline-none focus:border-orange-500"
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      <div className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-slate-900/50 text-slate-400 text-sm">
            <tr>
              <th className="p-4">Driver (Phone/UID)</th>
              <th className="p-4">Status</th>
              <th className="p-4">Expiry</th>
              <th className="p-4">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-700">
            {filteredUsers.map(user => {
              const isSubscribed = user.expiry && user.expiry.toDate() > new Date();
              return (
                <tr key={user.id} className="hover:bg-slate-700/30 transition-colors">
                  <td className="p-4">
                    <div className="text-white font-medium">{user.phone || 'No Phone'}</div>
                    <div className="text-slate-500 text-xs truncate w-32">{user.id}</div>
                  </td>
                  <td className="p-4">
                    {user.isBanned ? (
                      <span className="px-2 py-1 bg-red-500/10 text-red-500 rounded text-xs">BANNED</span>
                    ) : isSubscribed ? (
                      <span className="px-2 py-1 bg-green-500/10 text-green-500 rounded text-xs">ACTIVE</span>
                    ) : (
                      <span className="px-2 py-1 bg-slate-700 text-slate-400 rounded text-xs">EXPIRED</span>
                    )}
                  </td>
                  <td className="p-4 text-slate-300 text-sm">
                    {user.expiry ? user.expiry.toDate().toLocaleDateString() : 'Never'}
                  </td>
                  <td className="p-4">
                    <div className="flex space-x-2">
                      <button 
                        onClick={() => handleAddSubscription(user, 1, 10)}
                        className="px-2 py-1 bg-blue-500/10 text-blue-500 hover:bg-blue-500 hover:text-white rounded text-xs transition-all"
                      >
                        +1 Day (₹10)
                      </button>
                      <button 
                        onClick={() => handleAddSubscription(user, 15, 49)}
                        className="px-2 py-1 bg-orange-500/10 text-orange-500 hover:bg-orange-500 hover:text-white rounded text-xs transition-all"
                      >
                        +15 Days (₹49)
                      </button>
                      <button 
                        onClick={() => handleAddSubscription(user, 30, 99)}
                        className="px-2 py-1 bg-purple-500/10 text-purple-500 hover:bg-purple-500 hover:text-white rounded text-xs transition-all"
                      >
                        +30 Days
                      </button>
                      <button 
                        onClick={() => adjustExpiry(user, 1)}
                        className="px-2 py-1 bg-green-500/10 text-green-500 hover:bg-green-500 hover:text-white rounded text-xs transition-all"
                      >
                        +1 Hour
                      </button>
                      <button 
                        onClick={() => adjustExpiry(user, -1)}
                        className="px-2 py-1 bg-yellow-500/10 text-yellow-500 hover:bg-yellow-500 hover:text-white rounded text-xs transition-all"
                      >
                        -1 Hour
                      </button>
                      <button 
                        onClick={() => toggleBan(user)}
                        className={`px-2 py-1 rounded text-xs transition-all ${user.isBanned ? 'bg-green-500/10 text-green-500' : 'bg-red-500/10 text-red-500'}`}
                      >
                        {user.isBanned ? 'UNBAN' : 'BAN'}
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

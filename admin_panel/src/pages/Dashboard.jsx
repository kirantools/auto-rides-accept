import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { 
  Users, 
  IndianRupee, 
  UserCheck, 
  Clock,
  TrendingUp,
  AlertCircle
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer
} from 'recharts';

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeUsers: 0,
    totalRevenue: 0,
    pendingSupport: 0
  });
  const [recentUsers, setRecentUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const usersSnap = await getDocs(collection(db, 'users'));
      const ticketsSnap = await getDocs(collection(db, 'support_tickets'));
      
      const users = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
      const openTickets = ticketsSnap.docs.filter(d => d.data().status === 'open').length;

      const now = new Date();
      let revenue = 0;
      let activeCount = 0;

      users.forEach(u => {
        // 💰 Calculate Total Revenue from all time payments
        if (u.lastPaymentAmount) {
          revenue += Number(u.lastPaymentAmount);
        }
        
        // ✅ Count Active Subscriptions
        if (u.expiry && u.expiry.toDate() > now) {
          activeCount++;
        }
      });

      setStats({
        totalUsers: users.length,
        activeUsers: activeCount,
        totalRevenue: revenue,
        pendingSupport: openTickets
      });

      // Fetch 5 most recent drivers
      const q = query(collection(db, 'users'), orderBy('lastLogin', 'desc'), limit(5));
      const recentSnap = await getDocs(q);
      setRecentUsers(recentSnap.docs.map(d => ({ id: d.id, ...d.data() })));
      
      setLoading(false);
    } catch (e) {
      console.error(e);
      setLoading(false);
    }
  };

  const statCards = [
    { title: 'Total Drivers', value: stats.totalUsers, icon: Users, color: 'text-blue-500', bg: 'bg-blue-500/10' },
    { title: 'Active Plans', value: stats.activeUsers, icon: UserCheck, color: 'text-green-500', bg: 'bg-green-500/10' },
    { title: 'Total Revenue', value: `₹${stats.totalRevenue}`, icon: IndianRupee, color: 'text-orange-500', bg: 'bg-orange-500/10' },
    { title: 'Open Tickets', value: stats.pendingSupport, icon: AlertCircle, color: 'text-red-500', bg: 'bg-red-500/10' },
  ];

  if (loading) return <div className="p-8 text-white">Loading Dashboard...</div>;

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-white mb-8">Dashboard Overview</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat, i) => (
          <div key={i} className="bg-slate-800 p-6 rounded-2xl border border-slate-700 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className={`p-3 rounded-xl ${stat.bg}`}>
                <stat.icon className={`w-6 h-6 ${stat.color}`} />
              </div>
              <span className="text-xs font-bold text-slate-500">LIVE DATA</span>
            </div>
            <div className="text-2xl font-bold text-white">{stat.value}</div>
            <div className="text-sm text-slate-400">{stat.title}</div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Recent Activity */}
        <div className="lg:col-span-1 bg-slate-800 p-6 rounded-2xl border border-slate-700 shadow-xl">
          <h2 className="text-xl font-bold text-white mb-6 flex items-center">
            <Clock className="w-5 h-5 mr-2 text-orange-500" /> Recent Activity
          </h2>
          <div className="space-y-4">
            {recentUsers.map((user, i) => (
              <div key={i} className="flex items-center p-3 rounded-xl bg-slate-900/50 border border-slate-700/50">
                <div className="w-10 h-10 rounded-full bg-slate-700 flex items-center justify-center text-white font-bold mr-3">
                  {user.phone ? user.phone.slice(-2) : '?'}
                </div>
                <div className="flex-1 overflow-hidden">
                  <div className="text-white text-sm font-medium truncate">{user.phone || 'New User'}</div>
                  <div className="text-slate-500 text-xs">Logged in recently</div>
                </div>
                <div className={`w-2 h-2 rounded-full ${user.expiry && user.expiry.toDate() > new Date() ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]' : 'bg-slate-600'}`}></div>
              </div>
            ))}
          </div>
        </div>

        {/* Placeholder for Revenue Trend */}
        <div className="lg:col-span-2 bg-slate-800 p-6 rounded-2xl border border-slate-700 shadow-xl">
          <h2 className="text-xl font-bold text-white mb-6 flex items-center">
            <TrendingUp className="w-5 h-5 mr-2 text-green-500" /> Revenue Flow
          </h2>
          <div className="h-[300px] w-full flex items-center justify-center text-slate-500 border-2 border-dashed border-slate-700 rounded-xl">
            Charts will update as more payments arrive.
          </div>
        </div>
      </div>
    </div>
  );
}

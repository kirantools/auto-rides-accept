import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation, Navigate } from 'react-router-dom';
import { LayoutDashboard, Users, MessageSquare, ShieldAlert, LogOut, Settings as SettingsIcon, Megaphone } from 'lucide-react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { auth } from './firebase';
import Dashboard from './pages/Dashboard';
import UsersList from './pages/UsersList';
import SupportTickets from './pages/SupportTickets';
import Settings from './pages/Settings';
import Broadcast from './pages/Broadcast';
import Login from './pages/Login';

function Sidebar() {
  const location = useLocation();
  
  const menuItems = [
    { name: 'Dashboard', path: '/', icon: LayoutDashboard },
    { name: 'Drivers', path: '/users', icon: Users },
    { name: 'Support', path: '/support', icon: MessageSquare },
    { name: 'Broadcast', path: '/broadcast', icon: Megaphone },
    { name: 'Settings', path: '/settings', icon: SettingsIcon },
  ];

  return (
    <div className="w-64 bg-card h-screen fixed left-0 top-0 border-r border-white/5 p-6 flex flex-col">
      <div className="flex items-center gap-3 mb-10 px-2">
        <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
          <ShieldAlert className="text-black w-5 h-5" />
        </div>
        <h1 className="font-bold text-xl tracking-tight">SWAYAM <span className="text-primary">ADMIN</span></h1>
      </div>

      <nav className="flex-1 space-y-2 overflow-y-auto">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                isActive 
                ? 'bg-primary text-black font-bold shadow-lg shadow-primary/20' 
                : 'text-gray-400 hover:bg-white/5 hover:text-white'
              }`}
            >
              <Icon size={20} />
              <span>{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="pt-6 border-t border-white/5">
        <button 
          onClick={() => signOut(auth)}
          className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-red-500 hover:bg-red-500/10 transition-all"
        >
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
}

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  if (loading) return null;

  if (!user) return <Login />;

  return (
    <Router>
      <div className="min-h-screen bg-dark">
        <Sidebar />
        <main className="ml-64 p-8">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/users" element={<UsersList />} />
            <Route path="/support" element={<SupportTickets />} />
            <Route path="/broadcast" element={<Broadcast />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;

import React, { useState, useEffect } from 'react';
import { collection, getDocs, updateDoc, doc, query, orderBy, onSnapshot, arrayUnion, Timestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { MessageSquare, CheckCircle, Clock, User, Send, Tag } from 'lucide-react';

export default function SupportTickets() {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [replyText, setReplyText] = useState({});

  useEffect(() => {
    const q = query(collection(db, 'support_tickets'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snap) => {
      setTickets(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const handleResolve = async (ticket) => {
    const status = ticket.status === 'resolved' ? 'pending' : 'resolved';
    await updateDoc(doc(db, 'support_tickets', ticket.id), { status });
  };

  const handleSendReply = async (ticketId) => {
    const text = replyText[ticketId];
    if (!text || !text.trim()) return;

    await updateDoc(doc(db, 'support_tickets', ticketId), {
      messages: arrayUnion({
        text: text.trim(),
        sender: 'admin',
        timestamp: Date.now()
      })
    });

    setReplyText({ ...replyText, [ticketId]: '' });
  };

  if (loading) return <div className="p-8 text-center text-gray-500">Loading Tickets...</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-3xl font-bold mb-2 text-white">Support Inbox</h2>
          <p className="text-gray-400">Respond to driver issues and feedback.</p>
        </div>
        <div className="text-right">
          <div className="text-2xl font-bold text-primary">{tickets.filter(t => t.status !== 'resolved').length}</div>
          <div className="text-xs text-gray-500 uppercase tracking-wider">Open Tickets</div>
        </div>
      </div>

      <div className="grid gap-6">
        {tickets.length === 0 ? (
          <div className="bg-card p-12 text-center rounded-2xl border border-white/5 border-dashed">
            <MessageSquare className="mx-auto text-gray-600 mb-4" size={48} />
            <p className="text-gray-500">No support tickets found.</p>
          </div>
        ) : (
          tickets.map((ticket) => (
            <div 
              key={ticket.id} 
              className={`bg-card rounded-2xl border transition-all overflow-hidden ${
                ticket.status === 'resolved' ? 'border-white/5 opacity-80' : 'border-primary/20 shadow-lg shadow-primary/5'
              }`}
            >
              {/* Header */}
              <div className="p-6 border-b border-white/5 flex justify-between items-center bg-white/[0.02]">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center text-primary">
                    <User size={20} />
                  </div>
                  <div>
                    <h4 className="font-bold text-white flex items-center gap-2">
                      {ticket.userPhone || 'Unknown User'}
                      <span className={`text-[10px] px-2 py-0.5 rounded ${
                        ticket.status === 'resolved' ? 'bg-green-500/10 text-green-500' : 'bg-orange-500/10 text-orange-500'
                      }`}>
                        {ticket.status?.toUpperCase()}
                      </span>
                    </h4>
                    <div className="flex items-center gap-3 text-xs text-gray-500">
                      <span className="flex items-center gap-1"><Tag size={10}/> {ticket.category || 'General'}</span>
                      <span className="flex items-center gap-1"><Clock size={10}/> {ticket.createdAt?.toDate().toLocaleString()}</span>
                    </div>
                  </div>
                </div>
                <button 
                  onClick={() => handleResolve(ticket)}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    ticket.status === 'resolved' 
                    ? 'bg-white/5 text-gray-400 hover:bg-white/10' 
                    : 'bg-primary text-black hover:scale-105'
                  }`}
                >
                  {ticket.status === 'resolved' ? 'RE-OPEN' : 'MARK RESOLVED'}
                </button>
              </div>

              {/* Chat Body */}
              <div className="p-6 max-h-60 overflow-y-auto bg-black/20 space-y-4">
                {ticket.messages?.map((msg, i) => (
                  <div key={i} className={`flex ${msg.sender === 'admin' ? 'justify-end' : 'justify-start'}`}>
                    <div className={`max-w-[80%] p-3 rounded-2xl text-sm ${
                      msg.sender === 'admin' 
                      ? 'bg-primary text-black rounded-tr-none' 
                      : 'bg-white/10 text-white rounded-tl-none'
                    }`}>
                      {msg.imageUrl && (
                        <a href={msg.imageUrl} target="_blank" rel="noreferrer" className="block mb-2 overflow-hidden rounded-lg">
                          <img src={msg.imageUrl} alt="Attachment" className="max-w-full hover:scale-105 transition-transform" />
                        </a>
                      )}
                      {msg.text}
                      <div className={`text-[9px] mt-1 opacity-50 ${msg.sender === 'admin' ? 'text-black' : 'text-white'}`}>
                        {new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Reply Footer */}
              {ticket.status !== 'resolved' && (
                <div className="p-4 bg-white/[0.03] flex gap-3">
                  <input 
                    type="text" 
                    placeholder="Type your reply..."
                    value={replyText[ticket.id] || ''}
                    onChange={(e) => setReplyText({ ...replyText, [ticket.id]: e.target.value })}
                    onKeyDown={(e) => e.key === 'Enter' && handleSendReply(ticket.id)}
                    className="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:border-primary/50"
                  />
                  <button 
                    onClick={() => handleSendReply(ticket.id)}
                    className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-black hover:scale-105 transition-all"
                  >
                    <Send size={18} />
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

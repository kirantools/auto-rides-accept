import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'ticket_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  String _selectedCategory = "Payment Issues";
  bool _isSubmitting = false;

  final List<String> _categories = [
    "Payment Issues",
    "App Related Issues",
    "Account Problems",
    "Other Issues"
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Support Center", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppTheme.safetyOrange,
            tabs: [
              Tab(text: "New Ticket"),
              Tab(text: "My Tickets"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewTicketTab(),
            _buildMyTicketsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("How can we help you?", 
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Select a category and describe your issue.", 
            style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 30),
          
          const Text("ISSUE CATEGORY", style: TextStyle(color: AppTheme.safetyOrange, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: AppTheme.darkCard,
                items: _categories.map((c) => DropdownMenuItem(
                  value: c, 
                  child: Text(c, style: const TextStyle(color: Colors.white))
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
          ),
          
          const SizedBox(height: 25),
          const Text("MESSAGE", style: TextStyle(color: AppTheme.safetyOrange, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: "Describe your problem in detail...",
              filled: true,
              fillColor: AppTheme.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safetyOrange,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text("SUBMIT TICKET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: AuthService.getMyTickets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final tickets = snapshot.data!.docs;
        // Sort locally to avoid index errors
        tickets.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined, size: 60, color: Colors.grey[800]),
                const SizedBox(height: 10),
                const Text("No tickets found", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: tickets.length,
          separatorBuilder: (c, i) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            final data = ticket.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final lastUpdate = (data['lastUpdatedAt'] as Timestamp?)?.toDate();

            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (c) => TicketChatScreen(ticketId: ticket.id, ticketData: data)
              )),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'resolved' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(status.toUpperCase(), 
                                  style: TextStyle(
                                    color: status == 'resolved' ? Colors.green : Colors.orange, 
                                    fontSize: 10, fontWeight: FontWeight.bold
                                  )),
                              ),
                              const SizedBox(width: 10),
                              Text(data['category'] ?? "Issue", 
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(data['message'] ?? "", 
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(lastUpdate != null ? "${lastUpdate.day}/${lastUpdate.month} ${lastUpdate.hour}:${lastUpdate.minute}" : "",
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitTicket() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthService.sendDetailedSupportTicket(_selectedCategory, msg);
      _messageController.clear();
      DefaultTabController.of(context).animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket submitted successfully!"), backgroundColor: Colors.green)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission failed. Try again."), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

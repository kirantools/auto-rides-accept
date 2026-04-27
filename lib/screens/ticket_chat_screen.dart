import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class TicketChatScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> ticketData;

  const TicketChatScreen({super.key, required this.ticketId, required this.ticketData});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Support Chat", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.ticketData['category'] ?? "Ticket", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final messages = (data?['messages'] as List?) ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg['sender'] == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.safetyOrange : AppTheme.darkCard,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg['imageUrl'] != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  msg['imageUrl'],
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                              Text(msg['text'] ?? "", 
                                style: TextStyle(color: isUser ? Colors.black : Colors.white, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Text(
                              isUser ? "You" : "Swayam Support",
                              style: TextStyle(color: isUser ? Colors.black54 : Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: AppTheme.safetyOrange),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.add_a_photo_rounded, color: AppTheme.safetyOrange),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: AppTheme.safetyOrange,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.black, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await AuthService.addMessageToTicket(widget.ticketId, text);
    _scrollToBottom();
  }

  void _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isUploading = true);
      final url = await AuthService.uploadTicketImage(widget.ticketId, File(image.path));
      if (url != null) {
        await AuthService.addMessageToTicket(widget.ticketId, "Shared a screenshot", imageUrl: url);
      }
      setState(() => _isUploading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

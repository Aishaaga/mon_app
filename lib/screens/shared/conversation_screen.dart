import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String? artisanId;
  final String? clientId;
  final String? contactType;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    this.artisanId,
    this.clientId,
    this.contactType,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final conversationDoc = await firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (conversationDoc.exists) {
        final conversationData = conversationDoc.data()!;
        
        // Charger les messages de la sous-collection
        final messagesSnapshot = await firestore
            .collection('conversations')
            .doc(widget.conversationId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .get();

        setState(() {
          _messages.clear();
          for (var messageDoc in messagesSnapshot.docs) {
            _messages.add(messageDoc.data()!);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de la conversation: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) return;

      final messageData = {
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Utilisateur',
        'content': _messageController.text.trim(),
        'createdAt': Timestamp.now(),
        'participants': [widget.artisanId, widget.clientId],
      };

      await firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(messageData);

      // Mettre à jour la conversation
      await firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
            'lastMessage': _messageController.text.trim(),
            'lastMessageTime': Timestamp.now(),
          });

      _messageController.clear();
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactType == 'call' ? 'Appeler l\'artisan' : 'Messagerie'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'information
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation ID: ${widget.conversationId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (widget.artisanId != null) ...[
                  Text('Artisan ID: ${widget.artisanId}'),
                ],
                if (widget.clientId != null) ...[
                  Text('Client ID: ${widget.clientId}'),
                ],
                Text('Type de contact: ${widget.contactType ?? "message"}'),
              ],
            ),
          ),
          
          // Zone de messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, size: 20),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[100] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['senderName'] ?? 'Utilisateur',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? Colors.blue[800] : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['content'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.blue[800] : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(message['createdAt']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Zone d'envoi de message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final dateTime = timestamp!.toDate();
    final now = DateTime.now();
    
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

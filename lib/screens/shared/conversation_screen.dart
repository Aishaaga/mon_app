import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

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
  Map<String, dynamic>? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) return;
      
      // Déterminer l'ID de l'autre utilisateur
      final otherUserId = widget.artisanId == user.uid ? widget.clientId : widget.artisanId;
      
      if (otherUserId != null) {
        // Charger les informations de l'autre utilisateur
        final userDoc = await firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            setState(() {
              _otherUser = {
                'id': otherUserId,
                'name': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
                'email': userData['email'] ?? '',
                'avatar': userData['profileImage'],
              };
            });
          }
        }
      }
      
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
        title: _otherUser != null 
            ? Text('Chat avec ${_otherUser!['name']}')
            : const Text('Messagerie'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Retour automatique selon le type d'utilisateur
              context.go('/client/my-requests');
            }
          },
        ),
        actions: [
          if (_otherUser != null && _otherUser!['isOnline'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'En ligne',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Zone de messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun message pour le moment',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Soyez le premier à envoyer un message !',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                          
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          
          // Zone d'envoi de message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blue,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: _otherUser != null && _otherUser!['avatar'] != null
                  ? ClipOval(
                      child: Image.network(
                        _otherUser!['avatar'],
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 20);
                        },
                      ),
                    )
                  : const Icon(Icons.person, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      _otherUser?['name'] ?? 'Utilisateur',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message['createdAt']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, size: 20, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes == 0) {
      return 'À l\'instant';
    } else if (difference.inHours == 0) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays == 0) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

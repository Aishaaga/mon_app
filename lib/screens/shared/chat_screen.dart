import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String? returnRoute; // Route de retour optionnelle

  const ChatScreen({super.key, required this.userId, this.returnRoute});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  Map<String, dynamic>? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;
  String? _conversationId;
  String? _returnRoute; // Variable locale pour returnRoute

  @override
  void initState() {
    super.initState();
    _extractUrlParameters();
    _loadChatData();
  }

  void _extractUrlParameters() {
    // Le returnRoute est déjà passé par le routeur via le constructeur
    _returnRoute = widget.returnRoute;
    
    print('🔙 Widget returnRoute: ${widget.returnRoute}');
    print('🔙 Final returnRoute: $_returnRoute');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    try {
      print('🔍 Chargement données chat pour: ${widget.userId}');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      print('👤 User ID: $currentUserId');
      
      if (currentUserId == null) {
        print('❌ User ID null');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      print('📡 Firestore initialisé');

      // Charger les informations de l'autre utilisateur
      print('📄 Chargement utilisateur: ${widget.userId}');
      final userDoc = await firestore.collection('users').doc(widget.userId).get();
      
      print('📄 Document existe: ${userDoc.exists}');
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        print('📊 Données utilisateur: $userData');
        
        if (userData != null) {
          String firstName = userData['firstName']?.toString() ?? '';
          String lastName = userData['lastName']?.toString() ?? '';
          String fullName = '$firstName $lastName'.trim();
          
          if (fullName.isEmpty) {
            fullName = userData['email'] ?? 'Utilisateur inconnu';
          }

          print('👤 Nom complet: "$fullName"');

          setState(() {
            _otherUser = {
              'id': widget.userId,
              'name': fullName,
              'email': userData['email'] ?? '',
              'avatar': userData['profileImage'],
              'isOnline': userData['isOnline'] ?? false,
            };
          });
          print('✅ Utilisateur chargé: ${_otherUser!['name']}');
        }
      }

      // Chercher ou créer une conversation
      print('🔍 Recherche conversation...');
      await _findOrCreateConversation(currentUserId);

      // Charger les messages
      print('💬 Chargement messages...');
      _loadMessages();
    } catch (e) {
      print('❌ Erreur chargement chat: $e');
      print('📍 Type d\'erreur: ${e.runtimeType}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _findOrCreateConversation(String currentUserId) async {
    try {
      print('🔍 Recherche conversation entre: $currentUserId et ${widget.userId}');
      
      final firestore = FirebaseFirestore.instance;
      
      // Chercher une conversation existante
      print('📄 Recherche conversation existante...');
      final conversationQuery = await firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      print('📊 Conversations trouvées: ${conversationQuery.docs.length}');
      
      String? existingConversationId;
      
      for (var doc in conversationQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(widget.userId)) {
          print('✅ Conversation existante trouvée: ${doc.id}');
          existingConversationId = doc.id;
          break;
        }
      }

      if (existingConversationId != null) {
        setState(() {
          _conversationId = existingConversationId;
        });
        print('✅ Conversation ID: $_conversationId');
      } else {
        print('🆕 Création nouvelle conversation...');
        // Créer une nouvelle conversation
        final conversationDoc = await firestore.collection('conversations').add({
          'participants': [currentUserId, widget.userId],
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });

        setState(() {
          _conversationId = conversationDoc.id;
        });
        print('✅ Nouvelle conversation créée: $_conversationId');
      }
    } catch (e) {
      print('❌ Erreur recherche/création conversation: $e');
      print('📍 Type erreur: ${e.runtimeType}');
      rethrow; // Propager l'erreur pour voir où elle se produit
    }
  }

  void _loadMessages() {
    if (_conversationId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    
    if (currentUserId == null) return;

    print('📨 Chargement messages pour conversation: $_conversationId');
    print('👤 Current user: $currentUserId');
    print('👤 Other user: ${widget.userId}');

    // Charger les messages envoyés par l'utilisateur courant
    FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: widget.userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((sentSnapshot) {
      print('📨 Messages envoyés: ${sentSnapshot.docs.length}');
      
      // Charger les messages reçus par l'utilisateur courant
      FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: widget.userId)
          .where('receiverId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((receivedSnapshot) {
        print('📨 Messages reçus: ${receivedSnapshot.docs.length}');
        
        // Combiner les deux listes
        List<Message> allMessages = [
          ...sentSnapshot.docs.map((doc) => Message.fromFirestore(doc)),
          ...receivedSnapshot.docs.map((doc) => Message.fromFirestore(doc)),
        ];
        
        // Trier par timestamp
        allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (mounted) {
          setState(() {
            _messages = allMessages.reversed.toList();
            _isLoading = false;
          });
        }

        // Marquer les messages comme lus
        _markMessagesAsRead();

        // Scroller vers le bas
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }, onError: (error) {
        print('❌ Erreur stream messages reçus: $error');
      });
    }, onError: (error) {
      print('❌ Erreur stream messages envoyés: $error');
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId == null || _conversationId == null) return;

      final firestore = FirebaseFirestore.instance;
      final unreadMessages = await firestore
          .collection('messages')
          .where('conversationId', isEqualTo: _conversationId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Erreur marquage messages lus: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId == null || _conversationId == null) return;

      final firestore = FirebaseFirestore.instance;
      final messageContent = _messageController.text.trim();

      // Créer le message
      final messageDoc = await firestore.collection('messages').add({
        'conversationId': _conversationId,
        'senderId': currentUserId,
        'receiverId': widget.userId,
        'content': messageContent,
        'type': 'text',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'status': 'sent',
      });

      // Mettre à jour la conversation
      await firestore.collection('conversations').doc(_conversationId).update({
        'lastMessage': messageContent,
        'lastMessageTime': Timestamp.now(),
      });

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur envoi message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _otherUser != null
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: _otherUser!['avatar'] != null
                        ? NetworkImage(_otherUser!['avatar'])
                        : null,
                    backgroundColor: Colors.green[100],
                    child: _otherUser!['avatar'] == null
                        ? Text(
                            _otherUser!['name'].isNotEmpty
                                ? _otherUser!['name'][0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otherUser!['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_otherUser!['isOnline'] == true)
                          const Text(
                            'En ligne',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : Text('Chat avec ${widget.userId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('🔙 Back button pressed');
            print('🔙 _returnRoute: $_returnRoute');
            print('🔙 context.canPop(): ${context.canPop()}');
            
            if (_returnRoute != null) {
              print('🔙 Navigating to: $_returnRoute');
              // Utiliser pushReplacement pour éviter les problèmes de navigation
              context.pushReplacement(_returnRoute!);
            } else if (context.canPop()) {
              print('🔙 Using context.pop()');
              context.pop();
            } else {
              print('🔙 No returnRoute, using default');
              context.go('/client/messages');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _makeCall(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyChat()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green[100],
            backgroundImage: _otherUser?['avatar'] != null
                ? NetworkImage(_otherUser!['avatar'])
                : null,
            child: _otherUser?['avatar'] == null
                ? Text(
                    _otherUser?['name'].isNotEmpty == true
                        ? _otherUser!['name'][0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _otherUser?['name'] ?? 'Utilisateur',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez votre premier message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final isFromMe = message.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: _otherUser?['avatar'] != null
                  ? NetworkImage(_otherUser!['avatar'])
                  : null,
              backgroundColor: Colors.green[100],
              child: _otherUser?['avatar'] == null
                  ? Text(
                      _otherUser?['name'].isNotEmpty == true
                          ? _otherUser!['name'][0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFromMe ? Colors.green : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isFromMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Text(
                'Moi',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _attachFile,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _sendImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isSending ? null : _sendMessage,
            backgroundColor: Colors.green,
            mini: true,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _makeCall() {
    if (_otherUser?['email'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appel à ${_otherUser!['email']}')),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Voir le profil'),
            onTap: () {
              Navigator.pop(context);
              context.go('/client/artisan/${widget.userId}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Bloquer'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Utilisateur bloqué')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Signaler'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Utilisateur signalé')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _attachFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
    );
  }

  void _sendImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
    );
  }
}

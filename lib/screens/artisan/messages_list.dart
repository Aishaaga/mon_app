import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';

class ArtisanMessagesListScreen extends StatefulWidget {
  const ArtisanMessagesListScreen({super.key});

  @override
  State<ArtisanMessagesListScreen> createState() => _ArtisanMessagesListScreenState();
}

class _ArtisanMessagesListScreenState extends State<ArtisanMessagesListScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId == null) return;

      final firestore = FirebaseFirestore.instance;
      
      // Approche 1: Chercher les messages où l'utilisateur est impliqué
      print('Chargement messages pour utilisateur: $currentUserId');
      
      // Messages envoyés par l'utilisateur
      final sentMessagesSnapshot = await firestore
          .collection('messages')
          .where('senderId', isEqualTo: currentUserId)
          .get();
      
      print('Messages envoyes: ${sentMessagesSnapshot.docs.length}');
      
      // Messages reçus par l'utilisateur
      final receivedMessagesSnapshot = await firestore
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      
      print('Messages recus: ${receivedMessagesSnapshot.docs.length}');
      
      // Combiner tous les messages
      final allMessages = [
        ...sentMessagesSnapshot.docs,
        ...receivedMessagesSnapshot.docs,
      ];
      
      print('Total messages: ${allMessages.length}');
      
      // Extraire les IDs uniques des autres participants
      final Set<String> otherParticipantIds = {};
      for (var doc in allMessages) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        final receiverId = data['receiverId'] as String?;
        
        if (senderId != null && senderId != currentUserId) {
          otherParticipantIds.add(senderId);
        }
        if (receiverId != null && receiverId != currentUserId) {
          otherParticipantIds.add(receiverId);
        }
      }
      
      print('Autres participants: ${otherParticipantIds.length}');
      
      List<Conversation> conversations = [];
      
      // Pour chaque participant, créer une conversation
      for (String participantId in otherParticipantIds) {
        try {
          // Charger les infos du participant
          final userDoc = await firestore
              .collection('users')
              .doc(participantId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              String firstName = userData['firstName']?.toString() ?? '';
              String lastName = userData['lastName']?.toString() ?? '';
              String fullName = '$firstName $lastName'.trim();
              
              if (fullName.isEmpty) {
                fullName = userData['email'] ?? 'Utilisateur inconnu';
              }

              // Compter les messages non lus
              final unreadSnapshot = await firestore
                  .collection('messages')
                  .where('receiverId', isEqualTo: currentUserId)
                  .where('senderId', isEqualTo: participantId)
                  .where('isRead', isEqualTo: false)
                  .get();

              // Récupérer le dernier message - approche alternative
              String lastMessage = '';
              DateTime lastMessageTime = DateTime.now();
              
              // Essayer avec senderId = currentUserId, receiverId = participantId
              try {
                final lastMessageSent = await firestore
                    .collection('messages')
                    .where('senderId', isEqualTo: currentUserId)
                    .where('receiverId', isEqualTo: participantId)
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();
                
                if (lastMessageSent.docs.isNotEmpty) {
                  final lastData = lastMessageSent.docs.first.data();
                  lastMessage = lastData['content'] ?? '';
                  lastMessageTime = (lastData['timestamp'] as Timestamp).toDate();
                }
              } catch (e) {
                // Si ça échoue, essayer avec l'autre sens
                try {
                  final lastMessageReceived = await firestore
                      .collection('messages')
                      .where('senderId', isEqualTo: participantId)
                      .where('receiverId', isEqualTo: currentUserId)
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .get();
                  
                  if (lastMessageReceived.docs.isNotEmpty) {
                    final lastData = lastMessageReceived.docs.first.data();
                    lastMessage = lastData['content'] ?? '';
                    lastMessageTime = (lastData['timestamp'] as Timestamp).toDate();
                  }
                } catch (e2) {
                  print('Erreur recuperation dernier message: $e2');
                }
              }

              conversations.add(Conversation(
                id: 'conversation_${currentUserId}_$participantId', // ID temporaire
                participantId: participantId,
                participantName: fullName,
                participantEmail: userData['email'] ?? '',
                participantAvatar: userData['profileImage'],
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadSnapshot.docs.length,
                isOnline: userData['isOnline'] ?? false,
              ));
            }
          }
        } catch (e) {
          print('Erreur chargement participant $participantId: $e');
        }
      }

      // Trier par lastMessageTime
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
      
      print('Conversations chargees: ${conversations.length}');
    } catch (e) {
      print('Erreur chargement conversations: $e');
      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/artisan/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      return _buildConversationTile(_conversations[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les clients vous contacteront pour vos services',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: conversation.participantAvatar != null
                ? NetworkImage(conversation.participantAvatar!)
                : null,
            backgroundColor: Colors.blue[100],
            child: conversation.participantAvatar == null
                ? Text(
                    conversation.participantName.isNotEmpty
                        ? conversation.participantName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (conversation.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.participantName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            conversation.lastMessage,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      onTap: () => _openChat(conversation),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _openChat(Conversation conversation) {
    context.go('/chat/${conversation.participantId}?returnRoute=/artisan/messages');
  }

  void _searchConversations() {
    showSearch(
      context: context,
      delegate: ConversationSearchDelegate(_conversations),
    );
  }
}

class ConversationSearchDelegate extends SearchDelegate<String> {
  final List<Conversation> conversations;

  ConversationSearchDelegate(this.conversations);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = conversations.where((conversation) {
      return conversation.participantName.toLowerCase().contains(query.toLowerCase()) ||
             conversation.participantEmail.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].participantName),
          subtitle: Text(results[index].participantEmail),
          onTap: () {
            close(context, results[index].participantId);
            context.go('/chat/${results[index].participantId}?returnRoute=/artisan/messages');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = conversations.where((conversation) {
      return conversation.participantName.toLowerCase().contains(query.toLowerCase()) ||
             conversation.participantEmail.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index].participantName),
          subtitle: Text(suggestions[index].participantEmail),
          onTap: () {
            close(context, suggestions[index].participantId);
            context.go('/chat/${suggestions[index].participantId}?returnRoute=/artisan/messages');
          },
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final MessageStatus status;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.status = MessageStatus.sent,
  });

  // Créer un message depuis Firestore
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${data['status']}',
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
    };
  }

  // Créer une copie avec des champs modifiés
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
    );
  }

  // Vérifier si le message est envoyé par l'utilisateur actuel
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  // Formater l'heure pour l'affichage
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Conversation {
  final String id;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final String? participantAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantEmail,
    this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  // Créer une conversation depuis Firestore
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantId: data['participantId'] ?? '',
      participantName: data['participantName'] ?? '',
      participantEmail: data['participantEmail'] ?? '',
      participantAvatar: data['participantAvatar'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      isOnline: data['isOnline'] ?? false,
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      'participantEmail': participantEmail,
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
    };
  }
}
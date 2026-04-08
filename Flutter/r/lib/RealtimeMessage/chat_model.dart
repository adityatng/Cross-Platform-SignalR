/// Represents a chat message in the application
class ChatModel {
  /// Unique identifier for the message
  final int id;

  /// Name or identifier of the user who sent the message
  final String user;

  /// Text content of the message
  String text;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Optional URL for an image attached to the message
  String? imageUrl;

  /// Indicates whether the message has been read
  bool isRead;

  /// Optional unique identifier for the client/device
  String? clientId;

  /// Current status of the message (e.g., sent, read)
  String? status;

  ChatModel({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
    this.imageUrl,
    this.isRead = false,
    this.clientId,
    this.status,
  });

  /// Creates a ChatModel instance from a JSON map
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      user: json['user'],
      text: json['text'] ?? "",
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] ?? false,
      clientId: json['clientId'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
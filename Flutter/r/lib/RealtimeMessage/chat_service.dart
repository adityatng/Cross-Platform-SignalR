import 'package:r/RealtimeMessage/chat_model.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:uuid/uuid.dart';

/// Service for managing chat operations and SignalR communication
class ChatService {
  /// SignalR hub connection
  final hubConnection = HubConnectionBuilder()
      .withUrl('http://localhost:5284/chatHub')
      .withAutomaticReconnect()
      .build();

  /// List of chat messages
  final List<ChatModel> messages = [];

  /// Unique identifier for the client/device
  final String clientId = const Uuid().v4();

  /// Callback invoked when messages are updated
  void Function()? onUpdate;

  /// Callback invoked when a user is typing
  void Function(String user, bool isTyping)? onTyping;

  /// Starts the SignalR connection and sets up message handlers
  Future<void> start() async {
    // Receive new message
    hubConnection.on('ReceiveMessage', (data) {
      final msg = ChatModel.fromJson(Map<String, dynamic>.from(data![0]));
      messages.add(msg);
      onUpdate?.call();
    });

    // Update an existing message
    hubConnection.on('MessageUpdated', (data) {
      final updated = ChatModel.fromJson(Map<String, dynamic>.from(data![0]));
      final index = messages.indexWhere((e) => e.id == updated.id);

      if (index != -1) {
        messages[index] = updated;
        onUpdate?.call();
      }
    });

    // Delete a message
    hubConnection.on('MessageDeleted', (data) {
      final id = data![0] as int;
      messages.removeWhere((e) => e.id == id);
      onUpdate?.call();
    });

    // Typing indicator from other users
    hubConnection.on('UserTyping', (data) {
      final map = Map<String, dynamic>.from(data![0]);
      onTyping?.call(map['user'], map['isTyping']);
    });

    // Mark message as read
    hubConnection.on('MessageRead', (data) {
      final messageId = data![0] as int;

      final msg = messages.firstWhere(
        (e) => e.id == messageId,
        orElse: () => messages.first,
      );

      msg.isRead = true;
      msg.status = "read";

      onUpdate?.call();
    });

    await hubConnection.start();
  }

  /// Load all chat messages from the server
  Future<void> loadMessages() async {
    await ensureConnected();

    final result = await hubConnection.invoke('GetMessages');

    messages.clear();
    messages.addAll(
      (result as List).map(
        (e) => ChatModel.fromJson(Map<String, dynamic>.from(e)),
      ),
    );

    onUpdate?.call();
  }

  /// Send a text message to the server
  Future<void> send(String user, String text) async {
    await ensureConnected();
    await hubConnection.invoke('SendMessage', args: [user, text, clientId]);
  }

  /// Send an image message to the server
  Future<void> sendImage(String user, String imageUrl) async {
    await ensureConnected();
    await hubConnection.invoke('SendImage', args: [user, imageUrl, clientId]);
  }

  /// Update an existing message
  Future<void> update(int id, String text) async {
    await ensureConnected();
    await hubConnection.invoke('UpdateMessage', args: [id, text]);
  }

  /// Delete a message by ID
  Future<void> delete(int id) async {
    await ensureConnected();
    await hubConnection.invoke('DeleteMessage', args: [id]);
  }

  /// Notify the server that the user is typing
  Future<void> typing(String user, bool isTyping) async {
    await ensureConnected();
    await hubConnection.invoke('Typing', args: [user, isTyping]);
  }

  /// Mark a message as read
  Future<void> markAsRead(int messageId) async {
    await ensureConnected();
    await hubConnection.invoke('MarkAsRead', args: [messageId]);
  }

  /// Ensure the SignalR connection is active before performing operations
  Future<void> ensureConnected() async {
    if (hubConnection.state != HubConnectionState.connected) {
      await hubConnection.start();
    }
  }
}

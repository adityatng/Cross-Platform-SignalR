import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:r/RealtimeMessage/chat_model.dart';
import 'chat_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _service = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _deviceName = "Loading...";
  String? typingUser;

  @override
  void initState() {
    super.initState();

    _service.onUpdate = () {
      setState(() {});
      _scrollToBottom();
    };

    _service.onTyping = (user, isTyping) {
      setState(() {
        typingUser = isTyping ? user : null;
      });
    };

    _getDeviceName();
    _init();
  }

  Future<void> _init() async {
    await _service.start();
    await _service.loadMessages();
  }

  Future<void> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      _deviceName = "${android.brand} ${android.model}";
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      _deviceName = ios.name;
    }

    setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() async {
    if (_controller.text.trim().isEmpty) return;

    await _service.send(_deviceName, _controller.text.trim());
    _controller.clear();
    _service.typing(_deviceName, false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      await _service.sendImage(_deviceName, file.path);
    }
  }

  bool _isMe(ChatModel msg) => msg.clientId == _service.clientId;

  String _formatTime(DateTime t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Widget _buildMessage(ChatModel msg) {
    final isMe = _isMe(msg);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showOptions(msg),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg.user,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),

            Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blue
                    : (isDark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(msg.imageUrl!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                  if (msg.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 4),

                      if (isMe)
                        Icon(
                          msg.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: msg.isRead
                              ? Colors.lightBlueAccent
                              : Colors.grey,
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(ChatModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(context);
              _edit(msg);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () {
              Navigator.pop(context);
              _service.delete(msg.id);
            },
          ),
        ],
      ),
    );
  }

  void _edit(ChatModel msg) async {
    final c = TextEditingController(text: msg.text);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Save")),
        ],
      ),
    );

    if (result != null) {
      await _service.update(msg.id, result);
    }
  }

  Widget _buildTyping() {
    if (typingUser == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Text("$typingUser is typing...",
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  Widget _buildInput() {
    return Column(
      children: [
        _buildTyping(),
        Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (v) =>
                      _service.typing(_deviceName, v.isNotEmpty),
                  decoration: InputDecoration(
                    hintText: "Message...",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _send,
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _service.messages;

    return Scaffold(
      appBar: AppBar(title: Text(_deviceName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];

                // mark as read
                if (!_isMe(msg) && !msg.isRead) {
                  _service.markAsRead(msg.id);
                }

                return _buildMessage(msg);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }
}
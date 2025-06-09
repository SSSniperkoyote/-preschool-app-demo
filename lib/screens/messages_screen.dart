import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String _userName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('users')
            .select('full_name')
            .eq('id', user.id)
            .single();

        setState(() {
          _userName = userData['full_name'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final messagesData = await Supabase.instance.client
            .from('messages')
            .select('*, sender:users!messages_sender_id_fkey(full_name), receiver:users!messages_receiver_id_fkey(full_name)')
            .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
            .order('created_at', ascending: true);

        setState(() {
          _messages = List<Map<String, dynamic>>.from(messagesData);
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // For demo purposes, we'll send to the first available user of opposite role
        final currentUserData = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();

        String targetRole = currentUserData['role'] == 'parent' ? 'teacher' : 'parent';

        final targetUsers = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('role', targetRole)
            .limit(1);

        if (targetUsers.isNotEmpty) {
          await Supabase.instance.client.from('messages').insert({
            'sender_id': user.id,
            'receiver_id': targetUsers[0]['id'],
            'content': _messageController.text.trim(),
          });

          _messageController.clear();
          _loadMessages();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages - $_userName'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['sender_id'] ==
                    Supabase.instance.client.auth.currentUser?.id;

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCurrentUser
                              ? 'You'
                              : message['sender']['full_name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(message['content']),
                        SizedBox(height: 4),
                        Text(
                          DateTime.parse(message['created_at'])
                              .toLocal()
                              .toString()
                              .split('.')[0],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

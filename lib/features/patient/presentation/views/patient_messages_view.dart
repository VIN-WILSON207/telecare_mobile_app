import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/widgets/message_input_field.dart';
import '../../../../core/theme/app_theme.dart';

class PatientMessagesView extends ConsumerStatefulWidget {
  final UserModel user;

  const PatientMessagesView({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<PatientMessagesView> createState() => _PatientMessagesViewState();
}

class _PatientMessagesViewState extends ConsumerState<PatientMessagesView> {
  _MockThread? _activeThread;

  final List<_MockThread> _threads = [
    _MockThread(
      id: 'thread_1',
      doctorName: 'Dr. Sarah Chen',
      specialty: 'Cardiologist',
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=80&h=80&fit=crop&auto=format',
      lastMessage: 'Hi Alex, your blood pressure values look stable. Keep up the low-sodium diet.',
      time: '10:45 AM',
      unreadCount: 1,
      messages: [
        _MockMessage(sender: 'doctor', text: 'Hello Alex, I reviewed your daily vitals logs.', timestamp: '10:40 AM'),
        _MockMessage(sender: 'patient', text: 'Thanks Dr. Sarah, I feel much better since starting the new plan.', timestamp: '10:42 AM'),
        _MockMessage(sender: 'doctor', text: 'Hi Alex, your blood pressure values look stable. Keep up the low-sodium diet.', timestamp: '10:45 AM'),
      ],
      replyOptions: [
        'Thank you, Doctor!',
        'Should I continue the daily measurements?',
        'Can I schedule a quick follow-up call?',
      ],
    ),
    _MockThread(
      id: 'thread_2',
      doctorName: 'Dr. Marcus Webb',
      specialty: 'Neurologist',
      avatarUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=80&h=80&fit=crop&auto=format',
      lastMessage: 'Let\'s check your symptoms during our video consultation tomorrow.',
      time: 'Yesterday',
      unreadCount: 0,
      messages: [
        _MockMessage(sender: 'patient', text: 'Hi doctor, I wanted to ask about the mild headaches I reported.', timestamp: 'Yesterday 2:30 PM'),
        _MockMessage(sender: 'doctor', text: 'Let\'s check your symptoms during our video consultation tomorrow.', timestamp: 'Yesterday 2:45 PM'),
      ],
      replyOptions: [
        'Perfect, I will be ready.',
        'Is there any medication I should avoid today?',
      ],
    ),
    _MockThread(
      id: 'thread_3',
      doctorName: 'Dr. Priya Nair',
      specialty: 'Dermatologist',
      avatarUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=80&h=80&fit=crop&auto=format',
      lastMessage: 'Apply the prescribed ointment twice daily for two weeks.',
      time: '3 days ago',
      unreadCount: 0,
      messages: [
        _MockMessage(sender: 'doctor', text: 'Apply the prescribed ointment twice daily for two weeks.', timestamp: '3 days ago'),
      ],
      replyOptions: [
        'Understood, will do.',
        'Should I report back if I see irritation?',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_activeThread != null) {
      return _ChatDetailScreen(
        thread: _activeThread!,
        onBack: () {
          setState(() {
            _activeThread = null;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primarySurface,
                    backgroundImage: NetworkImage(thread.avatarUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    thread.doctorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  Text(
                    thread.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.neutralLight,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.lastMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: thread.unreadCount > 0
                              ? AppTheme.neutralDark
                              : AppTheme.neutralMedium,
                          fontWeight: thread.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (thread.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  thread.unreadCount = 0;
                  _activeThread = thread;
                });
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final _MockThread thread;
  final VoidCallback onBack;

  const _ChatDetailScreen({
    required this.thread,
    required this.onBack,
  });

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      widget.thread.messages.add(_MockMessage(
        sender: 'patient',
        text: text.trim(),
        timestamp: 'Just now',
      ));
      widget.thread.lastMessage = text.trim();
      widget.thread.time = 'Just now';
    });
    _messageController.clear();
    _scrollToBottom();

    // Trigger dynamic doctor reply after a short delay
    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        widget.thread.messages.add(_MockMessage(
          sender: 'doctor',
          text: 'Understood. Thank you for the update, Alex. Let\'s review this in our next scheduled call.',
          timestamp: 'Just now',
        ));
        widget.thread.lastMessage = 'Understood. Thank you for the update...';
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: widget.onBack,
        ),
        titleSpacing: 0,
        backgroundColor: AppTheme.primaryColor,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.thread.avatarUrl),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thread.doctorName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  widget.thread.specialty,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting telehealth video call setup...'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.thread.messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.thread.messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }

                final message = widget.thread.messages[index];
                final isPatient = message.sender == 'patient';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isPatient) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(widget.thread.avatarUrl),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isPatient ? AppTheme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isPatient ? 16 : 4),
                              bottomRight: Radius.circular(isPatient ? 4 : 16),
                            ),
                            border: isPatient ? null : Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isPatient ? Colors.white : AppTheme.neutralDark,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.timestamp,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isPatient ? Colors.white70 : AppTheme.neutralLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isPatient) const SizedBox(width: 20),
                    ],
                  ),
                );
              },
            ),
          ),

          // Suggested quick reply pills
          if (widget.thread.replyOptions.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.thread.replyOptions.length,
                itemBuilder: (context, index) {
                  final reply = widget.thread.replyOptions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                    child: ActionChip(
                      label: Text(reply),
                      labelStyle: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      backgroundColor: AppTheme.primarySurface,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () {
                        _sendMessage(reply);
                      },
                    ),
                  );
                },
              ),
            ),

          MessageInputField(
            controller: _messageController,
            onSend: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(widget.thread.avatarUrl),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                ),
                SizedBox(width: 8),
                Text(
                  'Doctor is typing...',
                  style: TextStyle(fontSize: 11, color: AppTheme.neutralMedium, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockThread {
  final String id;
  final String doctorName;
  final String specialty;
  final String avatarUrl;
  String lastMessage;
  String time;
  int unreadCount;
  final List<_MockMessage> messages;
  final List<String> replyOptions;

  _MockThread({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.messages,
    required this.replyOptions,
  });
}

class _MockMessage {
  final String sender; // 'doctor' or 'patient'
  final String text;
  final String timestamp;

  _MockMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

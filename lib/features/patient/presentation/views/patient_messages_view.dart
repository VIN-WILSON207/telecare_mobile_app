import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/message_input_field.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../consultation/data/models/message_model.dart';
import '../../../consultation/providers/consultation_providers.dart';
import '../../../verification/services/cloudinary_service.dart';

bool isWithinAvailability(Map<String, dynamic>? availability) {
  if (availability == null || availability.isEmpty) return false;
  final now = DateTime.now();
  final dayName = DateFormat('EEEE').format(now).toLowerCase(); // e.g. "tuesday"
  if (!availability.containsKey(dayName)) return false;

  final slots = availability[dayName];
  if (slots is! List) return false;

  for (final slot in slots) {
    if (slot is! Map) continue;
    final startStr = slot['start'] as String?;
    final endStr = slot['end'] as String?;
    if (startStr == null || endStr == null) continue;

    final startParts = startStr.split(':');
    final endParts = endStr.split(':');
    if (startParts.length < 2 || endParts.length < 2) continue;

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMin = int.tryParse(startParts[1]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMin = int.tryParse(endParts[1]) ?? 0;

    final startTime = DateTime(now.year, now.month, now.day, startHour, startMin);
    final endTime = DateTime(now.year, now.month, now.day, endHour, endMin);

    if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return true;
    }
  }
  return false;
}

class PatientMessagesView extends ConsumerStatefulWidget {
  final UserModel user;

  const PatientMessagesView({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<PatientMessagesView> createState() =>
      _PatientMessagesViewState();
}

class _PatientMessagesViewState extends ConsumerState<PatientMessagesView> {
  UserModel? _activeOtherUser;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _startNewChat() {
    final isPatient = widget.user.role == UserRole.patient;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final title = isPatient
                ? 'Start Chat with Professional'
                : 'Start Chat with Patient';

            if (isPatient) {
              final doctorsAsync = ref.watch(verifiedDoctorsProvider);
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: doctorsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryColor),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: $e'),
                        ),
                        data: (doctors) {
                          final hps = doctors
                              .where((d) => d.uid != widget.user.uid)
                              .toList();

                          if (hps.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No verified healthcare professionals available.'),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: hps.length,
                            itemBuilder: (context, index) {
                              final hp = hps[index];
                              final prefix = hp.prefix ?? hp.role.displayPrefix;
                              final name = prefix.isNotEmpty ? '$prefix ${hp.fullName}' : hp.fullName;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: hp.profileImage != null && hp.profileImage!.isNotEmpty
                                      ? NetworkImage(hp.profileImage!)
                                      : null,
                                  child: hp.profileImage == null || hp.profileImage!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(hp.specialty ?? hp.role.label),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _activeOtherUser = hp;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // HP side: Start chat with their consulted patients
              final appointmentsAsync = ref.watch(doctorAppointmentsProvider(widget.user.uid));
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: appointmentsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryColor),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: $e'),
                        ),
                        data: (appointments) {
                          final uniquePatientIds = <String>{};
                          final uniquePatients = <UserModel>[];
                          for (final app in appointments) {
                            if (!uniquePatientIds.contains(app.patientId)) {
                              uniquePatientIds.add(app.patientId);
                              uniquePatients.add(UserModel(
                                uid: app.patientId,
                                fullName: app.patientName,
                                email: app.patientEmail,
                                phone: '',
                                role: UserRole.patient,
                                verificationStatus: 'approved',
                                createdAt: DateTime.now(),
                                isActive: true,
                              ));
                            }
                          }

                          if (uniquePatients.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No patients with previous appointments found.'),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: uniquePatients.length,
                            itemBuilder: (context, index) {
                              final patient = uniquePatients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primarySurface,
                                  child: Text(
                                    patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(patient.email),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _activeOtherUser = patient;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_activeOtherUser != null) {
      return _GeneralChatView(
        user: widget.user,
        otherUser: _activeOtherUser!,
        onBack: () => setState(() => _activeOtherUser = null),
      );
    }

    final chatRepo = ref.watch(chatRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'New Chat',
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralLight),
                fillColor: AppTheme.cardWhite,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatRepo.watchUserChatRooms(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }
                if (snapshot.hasError) {
                  return _MessageState(
                    icon: Icons.error_outline_rounded,
                    message: snapshot.error.toString(),
                  );
                }

                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty) {
                  return const _MessageState(
                    icon: Icons.chat_bubble_outline_rounded,
                    message: 'No active chat conversations. Click the top-right button to start a new chat!',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final roomId = room['id'] as String? ?? '';
                    final participants = List<String>.from(room['participants'] as List? ?? []);
                    final otherId = participants.firstWhere((id) => id != widget.user.uid, orElse: () => '');

                    if (otherId.isEmpty) return const SizedBox.shrink();

                    return Consumer(
                      builder: (context, ref, _) {
                        final otherProfileAsync = ref.watch(userProfileProvider(otherId));

                        return otherProfileAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(color: AppTheme.primaryColor),
                          ),
                          error: (e, _) => ListTile(title: Text('Error loading user: $e')),
                          data: (UserModel? otherUser) {
                            if (otherUser == null) return const SizedBox.shrink();

                            final prefix = otherUser.prefix ?? otherUser.role.displayPrefix;
                            final name = prefix.isNotEmpty ? '$prefix ${otherUser.fullName}' : otherUser.fullName;

                            if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }

                            final lastMsg = room['lastMessage'] as String? ?? 'No messages yet';
                            final lastMsgAtVal = room['lastMessageAt'];
                            String timeStr = '';
                            if (lastMsgAtVal is Timestamp) {
                              timeStr = DateFormat('dd MMM, jm').format(lastMsgAtVal.toDate());
                            }

                            final isOnline = otherUser.isOnline == true;
                            final inCall = otherUser.inCall == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: otherUser.profileImage != null && otherUser.profileImage!.isNotEmpty
                                          ? NetworkImage(otherUser.profileImage!)
                                          : null,
                                      child: otherUser.profileImage == null || otherUser.profileImage!.isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: inCall
                                              ? Colors.red
                                              : (isOnline ? Colors.green : Colors.grey),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
                                ),
                                subtitle: Text(
                                  lastMsg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (timeStr.isNotEmpty)
                                      Text(
                                        timeStr,
                                        style: const TextStyle(color: AppTheme.neutralLight, fontSize: 10),
                                      ),
                                    const SizedBox(height: 4),
                                    // Show unread indicator
                                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('chat_rooms')
                                          .doc(roomId)
                                          .collection('messages')
                                          .where('senderId', isEqualTo: otherId)
                                          .where('isRead', isEqualTo: false)
                                          .snapshots(),
                                      builder: (context, notifSnap) {
                                        final unreadCount = notifSnap.data?.docs.length ?? 0;
                                        if (unreadCount == 0) return const SizedBox.shrink();
                                        return Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _activeOtherUser = otherUser;
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralChatView extends ConsumerStatefulWidget {
  final UserModel user;
  final UserModel otherUser;
  final VoidCallback onBack;

  const _GeneralChatView({
    required this.user,
    required this.otherUser,
    required this.onBack,
  });

  @override
  ConsumerState<_GeneralChatView> createState() => _GeneralChatViewState();
}

class _GeneralChatViewState extends ConsumerState<_GeneralChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final Future<String> _roomFuture;

  @override
  void initState() {
    super.initState();
    _roomFuture = _ensureRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _ensureRoom() {
    final isPatient = widget.user.role == UserRole.patient;
    final doctorId = isPatient ? widget.otherUser.uid : widget.user.uid;
    final patientId = isPatient ? widget.user.uid : widget.otherUser.uid;

    return ref.read(chatRepositoryProvider).getOrCreateRoom(
          doctorId: doctorId,
          patientId: patientId,
          appointmentId: '',
          consultationId: '',
        );
  }

  Future<void> _sendMessage(String roomId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await ref.read(chatRepositoryProvider).sendRoomMessage(
          roomId: roomId,
          senderId: widget.user.uid,
          senderName: widget.user.fullName,
          text: text,
        );
    _scrollToBottom();

    // Conditional push notification to HP based on availability and online status
    if (widget.user.role == UserRole.patient && widget.otherUser.role.isHealthcareProfessional) {
      try {
        final hpDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.otherUser.uid)
            .get();

        if (hpDoc.exists) {
          final hp = UserModel.fromFirestore(hpDoc);
          final isAvailable = isWithinAvailability(hp.availability);
          if (hp.isOnline == true && isAvailable) {
            await ref.read(notificationServiceProvider).sendNotification(
              targetUserId: hp.uid,
              title: 'New Message',
              body: '${widget.user.fullName}: $text',
              data: {
                'type': 'new_chat_message',
                'roomId': roomId,
                'senderId': widget.user.uid,
              },
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to send conditional notification: $e');
      }
    }
  }

  Future<void> _handleAttachmentSelection(AttachmentType type, String roomId) async {
    String? localPath;
    String? attachmentType;

    try {
      if (type == AttachmentType.camera) {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
        if (image != null) {
          localPath = image.path;
          attachmentType = 'image';
        }
      } else if (type == AttachmentType.gallery) {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
        if (image != null) {
          localPath = image.path;
          attachmentType = 'image';
        }
      } else if (type == AttachmentType.document) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
        );
        if (result != null && result.files.single.path != null) {
          localPath = result.files.single.path;
          final ext = localPath!.split('.').last.toLowerCase();
          if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif') {
            attachmentType = 'image';
          } else {
            attachmentType = 'document';
          }
        }
      }

      if (localPath == null || attachmentType == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 12),
                  Text(
                    'Uploading attachment...',
                    style: TextStyle(color: AppTheme.neutralDark, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload file using CloudinaryService
      final url = await CloudinaryService().uploadFile(
        localPath,
        folder: 'chat_attachments',
      );

      if (mounted) Navigator.of(context).pop();

      await ref.read(chatRepositoryProvider).sendRoomMessage(
            roomId: roomId,
            senderId: widget.user.uid,
            senderName: widget.user.fullName,
            text: attachmentType == 'image' ? '[Image Attachment]' : '[Document Attachment]',
            attachmentUrl: url,
            attachmentType: attachmentType,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loader if still open
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _markIncomingRead(String roomId, List<MessageModel> messages) {
    for (final message in messages) {
      if (message.senderId != widget.user.uid &&
          message.status != 'read' &&
          !message.isRead) {
        ref.read(chatRepositoryProvider).markMessageRead(
              roomId: roomId,
              messageId: message.id,
            );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showDeleteDialog(String roomId, MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message for yourself?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(chatRepositoryProvider).deleteForSender(
                    roomId: roomId,
                    messageId: message.id,
                    senderId: widget.user.uid,
                  );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.otherUser.prefix ?? widget.otherUser.role.displayPrefix;
    final otherName = prefix.isNotEmpty ? '$prefix ${widget.otherUser.fullName}' : widget.otherUser.fullName;

    return FutureBuilder<String>(
      future: _roomFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _MessageState(
            icon: Icons.error_outline_rounded,
            message: snapshot.error?.toString() ?? 'Could not open chat.',
          );
        }

        final roomId = snapshot.data!;
        final messagesAsync = ref.watch(
          chatRoomMessagesProvider(
            ChatRoomMessagesQuery(
              roomId: roomId,
              viewerId: widget.user.uid,
            ),
          ),
        );

        return Scaffold(
          backgroundColor: AppTheme.neutralBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: widget.onBack,
            ),
            titleSpacing: 0,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            title: Text(
              otherName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  error: (error, _) => _MessageState(
                    icon: Icons.error_outline_rounded,
                    message: error.toString(),
                  ),
                  data: (messages) {
                    _markIncomingRead(roomId, messages);
                    _scrollToBottom();

                    if (messages.isEmpty) {
                      return const _MessageState(
                        icon: Icons.mark_chat_unread_outlined,
                        message: 'Start the conversation.',
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _MessageBubble(
                          message: message,
                          isMine: message.senderId == widget.user.uid,
                          onLongPress: () => _showDeleteDialog(roomId, message),
                        );
                      },
                    );
                  },
                ),
              ),
              MessageInputField(
                controller: _messageController,
                onSend: () => _sendMessage(roomId),
                onAttachment: (type) => _handleAttachmentSelection(type, roomId),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.timestamp);
    final hasAttachment = message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMine ? AppTheme.primaryColor : AppTheme.cardWhite,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            border: isMine ? null : Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAttachment) ...[
                if (message.attachmentType == 'image') ...[
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.attachmentUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image link copied to clipboard.')),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.attachmentUrl!,
                        fit: BoxFit.cover,
                        width: 220,
                        height: 150,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 220,
                            height: 150,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 220,
                            height: 150,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.attachmentUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File download link copied to clipboard.')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMine ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_rounded,
                            color: isMine ? Colors.white : AppTheme.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Document File',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isMine ? Colors.white : AppTheme.neutralDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to copy link',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine ? Colors.white70 : AppTheme.neutralMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (message.text.isNotEmpty &&
                  message.text != '[Image Attachment]' &&
                  message.text != '[Document Attachment]') ...[
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isMine ? Colors.white : AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                isMine ? '$time - ${message.status}' : time,
                style: TextStyle(
                  fontSize: 9,
                  color: isMine ? Colors.white70 : AppTheme.neutralLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppTheme.neutralLight),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.neutralMedium),
            ),
          ],
        ),
      ),
    );
  }
}

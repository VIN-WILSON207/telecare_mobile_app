import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'telecare_ui.dart';

enum AttachmentType { camera, gallery, document }

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final Function(AttachmentType)? onAttachment;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Type your message...',
    this.onAttachment,
  });

  void _showAttachmentBottomSheet(BuildContext context) {
    if (onAttachment == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Send Attachment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.neutralDark,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primarySurface,
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                ),
                title: const Text('Take Photo', style: TextStyle(color: AppTheme.neutralDark)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAttachment!(AttachmentType.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primarySurface,
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.primaryColor),
                ),
                title: const Text('Photo Gallery', style: TextStyle(color: AppTheme.neutralDark)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAttachment!(AttachmentType.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primarySurface,
                  child: Icon(Icons.description_rounded, color: AppTheme.primaryColor),
                ),
                title: const Text('Document', style: TextStyle(color: AppTheme.neutralDark)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAttachment!(AttachmentType.document);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (onAttachment != null)
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppTheme.primaryColor,
                size: 26,
              ),
              onPressed: () => _showAttachmentBottomSheet(context),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TeleCareInputStyles.formTextStyle,
              cursorColor: TeleCareInputStyles.cursorColor,
              decoration: TeleCareInputStyles.decoration(
                hintText: hintText,
                dense: true,
              ).copyWith(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.send_rounded, size: 20),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

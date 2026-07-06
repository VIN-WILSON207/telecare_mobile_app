import 'dart:io';
import 'package:flutter/material.dart';

class DocumentUploadCard extends StatelessWidget {
  final String title;
  final String description;
  final String? filePath;
  final double progress;
  final bool isUploading;
  final VoidCallback onPickPressed;
  final VoidCallback onClearPressed;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.description,
    this.filePath,
    this.progress = 0.0,
    this.isUploading = false,
    required this.onPickPressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = filePath != null && filePath!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  hasFile ? Icons.task_alt_rounded : Icons.cloud_upload_outlined,
                  color: hasFile ? theme.colorScheme.secondary : theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Upload content area
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: hasFile
                ? _buildFilePreview(context)
                : _buildDottedPlaceholder(context),
          ),

          // Upload progress bar if active
          if (isUploading) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uploading...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDottedPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isUploading ? null : onPickPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid, // Fallback for dotted in standard flutter
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Select Document',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG, or PNG (Max 5MB)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(filePath!);
    final fileName = filePath!.split(Platform.pathSeparator).last;
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Left side: icon or image thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              bottomLeft: Radius.circular(11),
            ),
            child: Container(
              width: 80,
              height: 80,
              color: isPdf ? const Color(0xFFFFEBEE) : Colors.white,
              child: isPdf
                  ? const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFC62828),
                      size: 36,
                    )
                  : Image.file(
                      file,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 32,
                          color: Colors.grey,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: file.length(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final sizeInMb = snapshot.data! / (1024 * 1024);
                      return Text(
                        '${sizeInMb.toStringAsFixed(2)} MB',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Remove action
          if (!isUploading) ...[
            IconButton(
              onPressed: onClearPressed,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFC62828),
              ),
              tooltip: 'Remove document',
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

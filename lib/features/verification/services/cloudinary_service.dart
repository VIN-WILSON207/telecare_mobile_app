import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryException implements Exception {
  final String message;
  final dynamic originalError;

  const CloudinaryException(this.message, [this.originalError]);

  @override
  String toString() => 'CloudinaryException: $message (${originalError ?? ""})';
}

/// A service to upload files to Cloudinary.
///
/// Uses unsigned upload presets defined in the `.env` file.
class CloudinaryService {
  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || cloudName.isEmpty) {
      throw const CloudinaryException(
        'CLOUDINARY_CLOUD_NAME is missing or empty in .env file.',
      );
    }
    if (uploadPreset == null || uploadPreset.isEmpty) {
      throw const CloudinaryException(
        'CLOUDINARY_UPLOAD_PRESET is missing or empty in .env file.',
      );
    }

    _cloudinary = CloudinaryPublic(
      cloudName,
      uploadPreset,
      cache: false,
    );
  }

  /// Uploads a file (image or PDF) to Cloudinary.
  ///
  /// [filePath] is the absolute local path to the file.
  /// [folder] is the directory structure inside Cloudinary.
  /// [onProgress] is an optional callback that yields a value between 0.0 and 1.0.
  Future<String> uploadFile(
    String filePath, {
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw CloudinaryException('File does not exist at path: $filePath');
    }

    try {
      // Determine the extension of the file
      final extension = filePath.split('.').last.toLowerCase();
      final isPdf = extension == 'pdf';

      // CloudinaryPublic uses CloudinaryFile for upload parameters.
      // Unsigned upload is supported.
      final cloudinaryFile = CloudinaryFile.fromFile(
        filePath,
        folder: folder,
        // For PDFs, we must use raw or auto resource type so it preserves format.
        resourceType: isPdf
            ? CloudinaryResourceType.Auto
            : CloudinaryResourceType.Image,
      );

      final response = await _cloudinary.uploadFile(
        cloudinaryFile,
        onProgress: (count, total) {
          if (total > 0 && onProgress != null) {
            onProgress(count / total);
          }
        },
      );

      final url = response.secureUrl;
      if (url.isEmpty) {
        throw const CloudinaryException('Upload completed but secureUrl was empty.');
      }

      return url;
    } catch (e) {
      throw CloudinaryException(
        'Failed to upload file to Cloudinary. Check your internet connection.',
        e,
      );
    }
  }

  /// Convenience method to upload a National ID.
  Future<String> uploadNationalId(
    String filePath, {
    void Function(double progress)? onProgress,
  }) {
    return uploadFile(
      filePath,
      // Obfuscated folder path for security
      folder: 'u_v_nd',
      onProgress: onProgress,
    );
  }

  /// Convenience method to upload a Medical License.
  Future<String> uploadLicense(
    String filePath, {
    void Function(double progress)? onProgress,
  }) {
    return uploadFile(
      filePath,
      // Obfuscated folder path for security
      folder: 'u_v_lc',
      onProgress: onProgress,
    );
  }

  /// Uploads a medical record supporting document.
  Future<String> uploadMedicalRecordAttachment(
    String filePath, {
    void Function(double progress)? onProgress,
  }) {
    return uploadFile(
      filePath,
      // Obfuscated folder path for security
      folder: 'u_m_rc',
      onProgress: onProgress,
    );
  }
}

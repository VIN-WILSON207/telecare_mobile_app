import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telecare_mobile_app/features/verification/providers/submit_verification_notifier.dart';
import 'package:telecare_mobile_app/features/verification/presentation/widgets/document_upload_card.dart';
import 'package:telecare_mobile_app/core/widgets/telecare_ui.dart';

class SubmitVerificationScreen extends ConsumerStatefulWidget {
  const SubmitVerificationScreen({super.key});

  @override
  ConsumerState<SubmitVerificationScreen> createState() =>
      _SubmitVerificationScreenState();
}

class _SubmitVerificationScreenState
    extends ConsumerState<SubmitVerificationScreen> {
  String? _nationalIdPath;
  String? _licensePath;

  final _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _specialtyController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _hospitalController = TextEditingController();

  String _selectedHpType = 'doctor';
  String _selectedHpPrefix = 'Dr.';
  String _selectedSpecialty = 'General Doctor';
  bool _showCustomSpecialty = false;

  @override
  void initState() {
    super.initState();
    _specialtyController.text = 'General Doctor';
  }

  // Maximum allowed size: 5 MB in bytes
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _specialtyController.dispose();
    _licenseNumberController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submissionState = ref.watch(submitVerificationProvider);
    final progressNotifier = ref.watch(submitVerificationProgressProvider);
    final isSubmitting = submissionState.isLoading;

    // Listen to submission status for success / failure reactions
    ref.listen<AsyncValue<void>>(submitVerificationProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification documents submitted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission failed: ${error.toString()}'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    final canSubmit =
        _nationalIdPath != null && _licensePath != null && !isSubmitting;

    return ValueListenableBuilder<double>(
      valueListenable: progressNotifier,
      builder: (context, overallProgress, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Submit Credentials'),
            leading: isSubmitting
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/verification-status');
                      }
                    },
                  ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Professional Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedHpType,
                      style: TeleCareInputStyles.formTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Type of Healthcare Professional',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'doctor', child: Text('Medical Doctor (Dr.)')),
                        DropdownMenuItem(value: 'nurse', child: Text('Registered Nurse (Nurse)')),
                        DropdownMenuItem(value: 'pharmacist', child: Text('Pharmacist (Pharm.)')),
                        DropdownMenuItem(value: 'physiotherapist', child: Text('Physiotherapist (Physio.)')),
                        DropdownMenuItem(value: 'lab_technician', child: Text('Lab Technician (Lab Tech)')),
                      ],
                      onChanged: isSubmitting ? null : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedHpType = val;
                            if (val == 'doctor') {
                              _selectedHpPrefix = 'Dr.';
                            } else if (val == 'nurse') {
                              _selectedHpPrefix = 'Nurse';
                            } else if (val == 'pharmacist') {
                              _selectedHpPrefix = 'Pharm.';
                            } else if (val == 'physiotherapist') {
                              _selectedHpPrefix = 'Physio.';
                            } else {
                              _selectedHpPrefix = 'HP.';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialty,
                      style: TeleCareInputStyles.formTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Medical Specialty',
                        prefixIcon: Icon(Icons.star_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'General Doctor', child: Text('General Doctor')),
                        DropdownMenuItem(value: 'General Practitioner', child: Text('General Practitioner')),
                        DropdownMenuItem(value: 'Cardiologist', child: Text('Cardiologist')),
                        DropdownMenuItem(value: 'Pediatrician', child: Text('Pediatrician')),
                        DropdownMenuItem(value: 'Dermatologist', child: Text('Dermatologist')),
                        DropdownMenuItem(value: 'Gynecologist', child: Text('Gynecologist')),
                        DropdownMenuItem(value: 'Neurologist', child: Text('Neurologist')),
                        DropdownMenuItem(value: 'Psychiatrist', child: Text('Psychiatrist')),
                        DropdownMenuItem(value: 'General Nurse', child: Text('General Nurse')),
                        DropdownMenuItem(value: 'Clinical Pharmacist', child: Text('Clinical Pharmacist')),
                        DropdownMenuItem(value: 'Physiotherapist', child: Text('Physiotherapist')),
                        DropdownMenuItem(value: 'Other Specialty', child: Text('Other Specialty (Specify)')),
                      ],
                      onChanged: isSubmitting ? null : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSpecialty = val;
                            _showCustomSpecialty = val == 'Other Specialty';
                            if (!_showCustomSpecialty) {
                              _specialtyController.text = val;
                            } else {
                              _specialtyController.text = '';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_showCustomSpecialty) ...[
                      TextFormField(
                        controller: _specialtyController,
                        enabled: !isSubmitting,
                        style: TeleCareInputStyles.formTextStyle,
                        decoration: const InputDecoration(
                          labelText: 'Specify Custom Specialty',
                          hintText: 'e.g. Cardiothoracic Surgeon',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please specify your specialty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _licenseNumberController,
                      enabled: !isSubmitting,
                      style: TeleCareInputStyles.formTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Medical License Number',
                        hintText: 'e.g. LIC-998877-CAM',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your license number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hospitalController,
                      enabled: !isSubmitting,
                      style: TeleCareInputStyles.formTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Primary Hospital/Clinic Affiliation',
                        hintText: 'e.g. Buea General Hospital',
                        prefixIcon: Icon(Icons.local_hospital_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your affiliated clinic/hospital';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Upload Documents',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please upload clear copies of your government-issued identity card and your active medical license. PDF, JPG, and PNG files are accepted.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. National ID Upload Card
                    DocumentUploadCard(
                      title: 'National Identity Document (ID)',
                      description:
                          'Upload a scanned copy or photo of your passport, national ID card, or driver license.',
                      filePath: _nationalIdPath,
                      isUploading: isSubmitting,
                      progress: overallProgress, // Linked to submission progress
                      onPickPressed: () => _showPickerOptions(
                        onSelected: (path) =>
                            setState(() => _nationalIdPath = path),
                      ),
                      onClearPressed: () =>
                          setState(() => _nationalIdPath = null),
                    ),
                    const SizedBox(height: 20),

                    // 2. Medical License Upload Card
                    DocumentUploadCard(
                      title: 'Medical Practice License',
                      description:
                          'Upload your active registration certificate or professional medical license document.',
                      filePath: _licensePath,
                      isUploading: isSubmitting,
                      progress: overallProgress,
                      onPickPressed: () => _showPickerOptions(
                        onSelected: (path) => setState(() => _licensePath = path),
                      ),
                      onClearPressed: () => setState(() => _licensePath = null),
                    ),
                    const SizedBox(height: 32),

                    // Submission action
                    if (isSubmitting) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Uploading files... ${(overallProgress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: canSubmit ? _handleSubmit : null,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Submit Verification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Picker options sheet
  // ---------------------------------------------------------------------------

  void _showPickerOptions({required void Function(String path) onSelected}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo (Camera)'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    _validateAndSelectFile(image.path, onSelected);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose Image (Gallery)'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    _validateAndSelectFile(image.path, onSelected);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded),
                title: const Text('Upload PDF or Document'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null && result.files.single.path != null) {
                    _validateAndSelectFile(
                      result.files.single.path!,
                      onSelected,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // File size validation helper
  // ---------------------------------------------------------------------------

  void _validateAndSelectFile(
    String path,
    void Function(String path) onSelected,
  ) async {
    final file = File(path);
    final size = await file.length();

    if (size > _maxFileSizeBytes) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Too Large'),
            content: const Text(
              'The selected document exceeds the 5 MB limit. Please compress the document or select a smaller file.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    onSelected(path);
  }

  // ---------------------------------------------------------------------------
  // Submit action handler
  // ---------------------------------------------------------------------------

  void _handleSubmit() {
    if (_nationalIdPath == null || _licensePath == null) return;
    if (!_formKey.currentState!.validate()) return;

    ref.read(submitVerificationProvider.notifier).submit(
          nationalIdPath: _nationalIdPath!,
          licensePath: _licensePath!,
          specialty: _specialtyController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
          hospital: _hospitalController.text.trim(),
          prefix: _selectedHpPrefix,
          hpType: _selectedHpType,
        );
  }
}

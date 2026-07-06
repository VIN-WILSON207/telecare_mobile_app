import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/bottom_nav_bar.dart';
import '../../../../core/widgets/telecare_ui.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/providers/auth_state.dart';

class UploadSafetyMeasuresScreen extends ConsumerStatefulWidget {
  const UploadSafetyMeasuresScreen({super.key});

  @override
  ConsumerState<UploadSafetyMeasuresScreen> createState() =>
      _UploadSafetyMeasuresScreenState();
}

class _UploadSafetyMeasuresScreenState
    extends ConsumerState<UploadSafetyMeasuresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSaving = false;

  final List<String> _categories = [
    'General',
    'Hygiene',
    'Nutrition',
    'Mental Health',
    'Physical Health',
    'Medication Safety',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    final doctor = authState.user;
    final prefix = doctor.prefix ?? doctor.role.displayPrefix;
    final doctorName = prefix.isNotEmpty ? '$prefix ${doctor.fullName}' : doctor.fullName;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('safety_measures').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'hpName': doctorName,
        'doctorId': doctor.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safety tip published successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish tip: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeleCareHomeBackScope(
      currentPath: '/upload-safety',
      child: Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        appBar: AppBar(
          title: const Text('Publish Health Safety Measure'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Share valuable safety guidelines or hygienic measures that can help all patients in the system.',
                  style: TextStyle(
                    color: AppTheme.neutralMedium,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: TeleCareInputStyles.formTextStyle,
                  decoration: InputDecoration(
                    hintText: 'e.g. Handwashing Best Practices',
                    filled: true,
                    fillColor: AppTheme.cardWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppTheme.cardWhite,
                  style: TeleCareInputStyles.formTextStyle,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.cardWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Safety Instructions / Tips',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  style: TeleCareInputStyles.formTextStyle,
                  decoration: InputDecoration(
                    hintText: 'Provide detailed instructions or recommendations...',
                    filled: true,
                    fillColor: AppTheme.cardWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the instructions';
                    }
                    if (value.trim().length < 10) {
                      return 'Instructions should be at least 10 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publish to Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

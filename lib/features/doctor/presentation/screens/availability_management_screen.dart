import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/bottom_nav_bar.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/providers/auth_state.dart';

class AvailabilityManagementScreen extends ConsumerStatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  ConsumerState<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends ConsumerState<AvailabilityManagementScreen> {
  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  Map<String, List<Map<String, String>>> _availability = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  void _loadAvailability() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final raw = user.availability;
      if (raw != null) {
        final Map<String, List<Map<String, String>>> parsed = {};
        raw.forEach((day, slots) {
          if (slots is List) {
            parsed[day] = slots.map((s) {
              if (s is Map) {
                return {
                  'start': s['start']?.toString() ?? '09:00',
                  'end': s['end']?.toString() ?? '17:00',
                };
              }
              return {'start': '09:00', 'end': '17:00'};
            }).toList();
          }
        });
        setState(() {
          _availability = parsed;
        });
      }
    }
  }

  Future<void> _saveAvailability() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(authState.user.uid).update({
        'availability': _availability,
      });

      // Reload profile inside AuthNotifier
      final updatedProfile = await ref.read(authRepositoryProvider).getUserProfile(authState.user.uid);
      if (updatedProfile != null) {
        ref.read(authNotifierProvider.notifier).updateAuthenticatedUser(updatedProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability schedule saved successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save availability: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSlot(String day) {
    setState(() {
      final daySlots = _availability[day] ?? [];
      daySlots.add({'start': '09:00', 'end': '12:00'});
      _availability[day] = daySlots;
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      final daySlots = _availability[day] ?? [];
      if (index >= 0 && index < daySlots.length) {
        daySlots.removeAt(index);
      }
      if (daySlots.isEmpty) {
        _availability.remove(day);
      } else {
        _availability[day] = daySlots;
      }
    });
  }

  Future<void> _pickTime(BuildContext context, String day, int index, bool isStart) async {
    final slots = _availability[day] ?? [];
    if (index < 0 || index >= slots.length) return;

    final currentStr = isStart ? slots[index]['start'] : slots[index]['end'];
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);

    if (currentStr != null) {
      final parts = currentStr.split(':');
      if (parts.length >= 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';

      setState(() {
        if (isStart) {
          slots[index]['start'] = timeStr;
        } else {
          slots[index]['end'] = timeStr;
        }
        _availability[day] = slots;
      });
    }
  }

  String _formatDayLabel(String day) {
    return day[0].toUpperCase() + day.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TeleCareHomeBackScope(
      currentPath: '/availability',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Availability'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final dayLabel = _formatDayLabel(day);
                  final slots = _availability[day] ?? [];
                  final isAvailable = slots.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        dayLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? AppTheme.primaryColor : Colors.black87,
                        ),
                      ),
                      leading: Icon(
                        Icons.calendar_today_rounded,
                        color: isAvailable ? AppTheme.primaryColor : Colors.grey,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isAvailable,
                            onChanged: (val) {
                              if (val) {
                                _addSlot(day);
                              } else {
                                setState(() {
                                  _availability.remove(day);
                                });
                              }
                            },
                          ),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (slots.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Offline / Unavailable this day',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                )
                              else
                                ...slots.asMap().entries.map((entry) {
                                  final slotIdx = entry.key;
                                  final slot = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _pickTime(context, day, slotIdx, true),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(slot['start'] ?? '09:00', style: const TextStyle(color: Colors.black87)),
                                                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('to', style: TextStyle(color: Colors.black87)),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _pickTime(context, day, slotIdx, false),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(slot['end'] ?? '17:00', style: const TextStyle(color: Colors.black87)),
                                                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                          onPressed: () => _removeSlot(day, slotIdx),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              if (isAvailable)
                                TextButton.icon(
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Time Slot'),
                                  onPressed: () => _addSlot(day),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAvailability,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Availability'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

import 'package:flutter/material.dart';
import '../../data/models/user_role.dart';

/// A segmented-button-style role picker for registration.
///
/// Only [UserRole.patient] and [UserRole.doctor] are offered during
/// self-registration; admin accounts are created separately.
class RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final bool enabled;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.enabled = true,
  });

  static const _selectableRoles = [UserRole.patient, UserRole.doctor];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _selectableRoles.map((role) {
            final isSelected = role == selectedRole;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: role == _selectableRoles.first ? 6 : 0,
                  left: role == _selectableRoles.last ? 6 : 0,
                ),
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: enabled ? () => onRoleChanged(role) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            role == UserRole.patient
                                ? Icons.person_outline
                                : Icons.medical_services_outlined,
                            size: 20,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            role.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

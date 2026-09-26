import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../model/select_option.dart';

/// Dropdown over options loaded from the API, showing each option's label
/// and reporting its id. Shows a loading/error state while [options] resolve.
class OptionDropdownField extends StatelessWidget {
  const OptionDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.onRetry,
    this.noneLabel,
    this.fallbackLabel,
    this.requiredMessage,
  });

  final String label;
  final IconData icon;
  final AsyncValue<List<SelectOption>> options;
  final int? value;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRetry;

  /// When set, adds a first item with this label that selects null.
  final String? noneLabel;

  /// Label for [value] if it isn't in the loaded options, so the current
  /// selection still shows (e.g. the student's department name).
  final String? fallbackLabel;

  /// When set, an empty selection fails validation with this message.
  final String? requiredMessage;

  InputDecoration _decoration({Widget? suffixIcon, String? errorText}) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.navyAlpha(0.6), size: 20),
        suffixIcon: suffixIcon,
        errorText: errorText,
      );

  @override
  Widget build(BuildContext context) {
    return options.when(
      loading: () => InputDecorator(
        decoration: _decoration(
          suffixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
            ),
          ),
        ),
        child: Text('Loading…', style: TextStyle(color: AppColors.navyAlpha(0.45), fontSize: 15)),
      ),
      error: (error, _) => InputDecorator(
        decoration: _decoration(
          errorText: 'Couldn\'t load options',
          suffixIcon: IconButton(
            tooltip: 'Try again',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navy),
            onPressed: onRetry,
          ),
        ),
        child: Text('Tap retry', style: TextStyle(color: AppColors.navyAlpha(0.45), fontSize: 15)),
      ),
      data: (loaded) {
        final items = [...loaded];
        if (value != null && !items.any((o) => o.id == value)) {
          items.insert(0, SelectOption(id: value!, label: fallbackLabel ?? '#$value'));
        }

        return DropdownButtonFormField<int?>(
          initialValue: value,
          isExpanded: true,
          decoration: _decoration(),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: AppColors.white,
          style: const TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w500),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: requiredMessage == null ? null : (v) => v == null ? requiredMessage : null,
          items: [
            if (noneLabel != null)
              DropdownMenuItem<int?>(
                value: null,
                child: Text(noneLabel!, style: TextStyle(color: AppColors.navyAlpha(0.55))),
              ),
            for (final option in items)
              DropdownMenuItem<int?>(
                value: option.id,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/vibration_service.dart';

class PremiumDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final String title;
  final Function(DateTime) onDateSelected;

  const PremiumDatePicker({
    super.key,
    required this.initialDate,
    required this.title,
    required this.onDateSelected,
  });

  @override
  State<PremiumDatePicker> createState() => _PremiumDatePickerState();

  static void show(
    BuildContext context, {
    required DateTime initialDate,
    required String title,
    required Function(DateTime) onDateSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumDatePicker(
        initialDate: initialDate,
        title: title,
        onDateSelected: onDateSelected,
      ),
    );
  }
}

class _PremiumDatePickerState extends State<PremiumDatePicker> {
  late DateTime _tempDate;

  @override
  void initState() {
    super.initState();
    _tempDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.m),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Text(widget.title, style: AppTextStyles.h3),
                TextButton(
                  onPressed: () {
                    VibrationService.light();
                    widget.onDateSelected(_tempDate);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: widget.initialDate,
              onDateTimeChanged: (DateTime newDate) {
                _tempDate = newDate;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

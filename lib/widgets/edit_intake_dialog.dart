import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class EditIntakeDialog extends StatefulWidget {
  final int currentIntake;
  final int dailyTarget;
  final String userId;

  const EditIntakeDialog({
    super.key,
    required this.currentIntake,
    required this.dailyTarget,
    required this.userId,
  });

  @override
  State<EditIntakeDialog> createState() => EditIntakeDialogState();
}

class EditIntakeDialogState extends State<EditIntakeDialog> {
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  late TextEditingController _intakeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _intakeController = TextEditingController(
      text: widget.currentIntake.toString(),
    );
  }

  @override
  void dispose() {
    _intakeController.dispose();
    super.dispose();
  }

  Future<void> _saveIntake() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final intakeValue = int.tryParse(_intakeController.text);
      if (intakeValue == null || intakeValue < 0) {
        throw Exception('Érvénytelen érték');
      }

      final todayDate = _getTodayDateString();
      final dailyStatsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('dailyStats')
          .doc(todayDate);

      await dailyStatsRef.set({
        'date': todayDate,
        'intake': intakeValue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pop();
        toastification.show(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
          type: ToastificationType.success,
          context: context,
          title: const Text('Bevitel frissítve!'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba történt: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bevitel szerkesztése'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Napi cél: ${widget.dailyTarget}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _intakeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Bevitel',
              hintText: 'Add meg a bevitelt (beszívás)',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Mégse'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveIntake,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Mentés'),
        ),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '/services/auth_service.dart';

class EditGoalBottomSheet extends StatefulWidget {
  final int currentDailyTarget;

  const EditGoalBottomSheet({super.key, required this.currentDailyTarget});

  @override
  State<EditGoalBottomSheet> createState() => _EditGoalBottomSheetState();
}

class _EditGoalBottomSheetState extends State<EditGoalBottomSheet> {
  final AuthService _authService = AuthService();
  late int _dailyTarget;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dailyTarget = widget.currentDailyTarget;
  }

  Future<void> _saveDailyTarget() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Nincs bejelentkezve felhasználó');
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await userDocRef.update({
        'dailyTarget': _dailyTarget,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
          title: Text('Napi cél frissítve!'),
          autoCloseDuration: const Duration(seconds: 5),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Napi cél szerkesztése',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Állítsa be a napi célját',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // Daily target display
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_dailyTarget',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 64,
                      ),
                    ),
                    Text(
                      'Napi cél (beszívás)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Slider
              Slider(
                value: _dailyTarget.toDouble(),
                min: 0,
                max: 500,
                divisions: 500,
                label: '$_dailyTarget',
                onChanged: (double value) {
                  setState(() {
                    _dailyTarget = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Min/Max labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: Theme.of(context).textTheme.bodySmall),
                  Text('500', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 24),
              // Quick selection buttons
              Text(
                'Gyors választás:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickSelectButton(50, context),
                  _buildQuickSelectButton(100, context),
                  _buildQuickSelectButton(200, context),
                  _buildQuickSelectButton(300, context),
                  _buildQuickSelectButton(400, context),
                  _buildQuickSelectButton(500, context),
                ],
              ),
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDailyTarget,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Mentés', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Mégse'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(int value, BuildContext context) {
    final isSelected = _dailyTarget == value;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _dailyTarget = value;
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.secondary,
          width: isSelected ? 2 : 1,
        ),
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.tertiary.withOpacity(0.2)
            : null,
      ),
      child: Text('$value'),
    );
  }
}

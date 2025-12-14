import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final AuthService _authService = AuthService();
  int _dailyTarget = 200;
  bool _isLoading = false;

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

      // Create or update user document with daily target
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'dailyTarget': _dailyTarget,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Szia, ${FirebaseAuth.instance.currentUser?.displayName}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Kezdésnek állítsd be a napi célodat!',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // Daily target display
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_dailyTarget',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 72,
                      ),
                    ),
                    Text(
                      'Napi cél (beszívás)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
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
              const SizedBox(height: 24),
              // Min/Max labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: Theme.of(context).textTheme.bodySmall),
                  Text('500', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 48),
              // Quick selection buttons
              Text(
                'Gyors választás:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 48),
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
                      : const Text(
                          'Mentés és folytatás',
                          style: TextStyle(fontSize: 16),
                        ),
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

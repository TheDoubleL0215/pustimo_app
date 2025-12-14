import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/circular_progress_indicator.dart';
import '/widgets/edit_goal_bottom_sheet.dart';
import '/widgets/edit_intake_dialog.dart';
import '/widgets/weekly_chart.dart';

String _getTodayDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

Future<void> _ensureTodayStatsExists(String userId) async {
  try {
    final todayDate = _getTodayDateString();
    final dailyStatsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(todayDate);

    final doc = await dailyStatsRef.get();
    if (!doc.exists) {
      await dailyStatsRef.set({
        'date': todayDate,
        'intake': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    print('Error ensuring today stats exists: $e');
  }
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  void _showEditGoalBottomSheet(BuildContext context, int currentDailyTarget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditGoalBottomSheet(currentDailyTarget: currentDailyTarget),
    );
  }

  void _showEditIntakeDialog(
    BuildContext context,
    int currentIntake,
    int dailyTarget,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditIntakeDialog(
        currentIntake: currentIntake,
        dailyTarget: dailyTarget,
        userId: userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double lineWidth = 30;
    final double radius = 130;
    final user = FirebaseAuth.instance.currentUser;

    final displayName = FirebaseAuth.instance.currentUser?.displayName;

    final lastName = displayName?.trim().split(RegExp(r'\s+')).first;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Nincs bejelentkezve felhasználó')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Szia, ${lastName}!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const Center(
                      child: Text('Nem található felhasználói adat'),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final dailyTarget = userData?['dailyTarget'] as int? ?? 0;

                  // Ensure today's stats document exists
                  _ensureTodayStatsExists(user.uid);

                  // Stream today's stats
                  final todayDate = _getTodayDateString();
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('dailyStats')
                        .doc(todayDate)
                        .snapshots(),
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final statsData =
                          statsSnapshot.data?.data() as Map<String, dynamic>?;
                      final currentIntake = statsData?['intake'] as int? ?? 0;

                      return Column(
                        children: [
                          CircularProgressIndicatorWidget(
                            currentIntake: currentIntake,
                            dailyTarget: dailyTarget,
                            lineWidth: lineWidth,
                            radius: radius,
                            onIntakeTap: () => _showEditIntakeDialog(
                              context,
                              currentIntake,
                              dailyTarget,
                              user.uid,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showEditGoalBottomSheet(context, dailyTarget),
                            icon: const Icon(Icons.edit),
                            label: const Text('Cél szerkesztése'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          WeeklyChart(userId: user.uid),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

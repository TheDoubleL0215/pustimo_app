import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyChart extends StatelessWidget {
  final String userId;

  const WeeklyChart({super.key, required this.userId});

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<String> _getWeekDates() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final List<String> dates = [];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      dates.add(_getDateString(date));
    }
    return dates;
  }

  String _getDayName(DateTime date) {
    const dayNames = ['H', 'K', 'Sze', 'Cs', 'P', 'Szo', 'V'];
    return dayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heti áttekintés',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('dailyStats')
                .where('date', whereIn: weekDates)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Create a map of date -> intake
              final Map<String, int> intakeMap = {};
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = data['date'] as String?;
                  final intake = data['intake'] as int? ?? 0;
                  if (date != null) {
                    intakeMap[date] = intake;
                  }
                }
              }

              // Prepare bar chart data
              final barGroups = <BarChartGroupData>[];
              final bottomTitles = <String>[];
              double maxValue = 0;

              for (int i = 0; i < 7; i++) {
                final date = weekStart.add(Duration(days: i));
                final dateString = weekDates[i];
                final intake = intakeMap[dateString] ?? 0;

                if (intake > maxValue) {
                  maxValue = intake.toDouble();
                }

                barGroups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: intake.toDouble(),
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );

                bottomTitles.add(_getDayName(date));
              }

              // Add some padding to max value
              maxValue = (maxValue * 1.2).ceilToDouble();
              if (maxValue < 10) maxValue = 10;

              return SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) =>
                            Theme.of(context).colorScheme.surface,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dayName = bottomTitles[groupIndex];
                          final value = rod.toY.toInt();
                          return BarTooltipItem(
                            '$dayName\n$value beszívás',
                            TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < bottomTitles.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  bottomTitles[value.toInt()],
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.min || value == meta.max) {
                              return const Text('');
                            }
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxValue / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

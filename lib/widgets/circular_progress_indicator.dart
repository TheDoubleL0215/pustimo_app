import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CircularProgressIndicatorWidget extends StatefulWidget {
  final int currentIntake;
  final int dailyTarget;
  final double lineWidth;
  final double radius;
  final VoidCallback? onIntakeTap;

  const CircularProgressIndicatorWidget({
    super.key,
    required this.currentIntake,
    required this.dailyTarget,
    this.lineWidth = 30,
    this.radius = 130,
    this.onIntakeTap,
  });

  @override
  State<CircularProgressIndicatorWidget> createState() =>
      _CircularProgressIndicatorWidgetState();
}

class _CircularProgressIndicatorWidgetState
    extends State<CircularProgressIndicatorWidget> {
  double _lastPercent = 0.0;

  @override
  Widget build(BuildContext context) {
    final percent = widget.dailyTarget > 0
        ? (widget.currentIntake / widget.dailyTarget).clamp(0.0, 1.0)
        : 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _lastPercent = percent;
        });
      }
    });

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circular indicator for unfilled part
          CircularPercentIndicator(
            arcType: ArcType.FULL,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Theme.of(context).colorScheme.primary,
            startAngle: 0,
            percent: 1,
            lineWidth: widget.lineWidth,
            progressColor: Theme.of(context).colorScheme.primary,
            radius: widget.radius,
          ),
          // Foreground percent indicator (filled part)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: _lastPercent, end: percent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutSine,
            builder: (context, animatedPercent, _) {
              return CircularPercentIndicator(
                arcType: ArcType.FULL,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.transparent,
                startAngle: 0,
                percent: animatedPercent,
                lineWidth: widget.lineWidth,
                progressColor: percent < 1
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error,
                radius: widget.radius,
                center: GestureDetector(
                  onTap: widget.onIntakeTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${widget.currentIntake}',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 40,
                                ),
                          ),
                          Text(
                            '/${widget.dailyTarget}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 40 * 0.618,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        'BESZÍVÁS',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
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

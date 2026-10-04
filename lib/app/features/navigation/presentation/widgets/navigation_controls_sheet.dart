import 'package:flutter/material.dart';
import '../../domain/entities/animated_car_state.dart';

class NavigationControlsSheet extends StatelessWidget {
  final AnimatedCarState carState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final ValueChanged<SpeedMultiplier> onSpeedChanged;

  const NavigationControlsSheet({
    super.key,
    required this.carState,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Stats Row: Remaining Distance & Estimated Remaining Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    label: 'Remaining Distance',
                    value: _formatDistance(carState.remainingDistanceMeters),
                    icon: Icons.straighten_rounded,
                  ),
                  _StatItem(
                    label: 'Remaining Time',
                    value: _formatDuration(carState.remainingDurationSeconds),
                    icon: Icons.timer_outlined,
                  ),
                  _StatItem(
                    label: 'Progress',
                    value: '${(carState.progress * 100).toInt()}%',
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: carState.progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 16),

              // Controls & Speed Row
              Row(
                children: [
                  // Play / Pause / Resume Button
                  Expanded(
                    flex: 3,
                    child: _buildPrimaryActionButton(),
                  ),
                  const SizedBox(width: 8),

                  // Reset Button
                  IconButton.filledTonal(
                    onPressed: carState.playStatus != AnimationPlayStatus.idle
                        ? onReset
                        : null,
                    icon: const Icon(Icons.replay_rounded),
                    tooltip: 'Reset',
                  ),
                  const SizedBox(width: 8),

                  // Speed Multiplier Chips (1x, 2x, 5x)
                  ...SpeedMultiplier.values.map((speed) {
                    final isSelected = carState.speedMultiplier == speed;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text(
                          speed.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => onSpeedChanged(speed),
                        visualDensity: VisualDensity.compact,
                        selectedColor: const Color(0xFF2563EB).withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton() {
    switch (carState.playStatus) {
      case AnimationPlayStatus.idle:
        return FilledButton.icon(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Navigation', style: TextStyle(fontWeight: FontWeight.w600)),
        );
      case AnimationPlayStatus.playing:
        return FilledButton.icon(
          onPressed: onPause,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.pause_rounded),
          label: const Text('Pause', style: TextStyle(fontWeight: FontWeight.w600)),
        );
      case AnimationPlayStatus.paused:
        return FilledButton.icon(
          onPressed: onResume,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Resume', style: TextStyle(fontWeight: FontWeight.w600)),
        );
      case AnimationPlayStatus.completed:
        return FilledButton.icon(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Restart', style: TextStyle(fontWeight: FontWeight.w600)),
        );
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000.0).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatDuration(double seconds) {
    final int totalSecs = seconds.toInt();
    if (totalSecs < 60) {
      return '$totalSecs s';
    }
    final int minutes = totalSecs ~/ 60;
    final int remainingSecs = totalSecs % 60;
    if (minutes < 60) {
      return '${minutes}m ${remainingSecs}s';
    }
    final int hours = minutes ~/ 60;
    final int remMins = minutes % 60;
    return '${hours}h ${remMins}m';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

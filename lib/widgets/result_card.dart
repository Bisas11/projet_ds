import 'package:flutter/material.dart';

/// A reusable card widget to display a single result line.
/// Supply [confidence] (0.0–1.0) to show a progress bar.
class ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final double? confidence;

  const ResultCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (confidence != null)
                  Text(
                    '${(confidence! * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (confidence != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: confidence,
                  minHeight: 5,
                  backgroundColor: cs.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A simple reusable card widget to display a single result line
/// with a title and optional subtitle (e.g., label + confidence).
class ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const ResultCard({super.key, required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
      ),
    );
  }
}

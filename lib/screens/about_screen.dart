import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// About screen: displays information about the app and the ML Kit API.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App icon / title
          const Icon(Icons.visibility, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),

          // App information
          Text(l10n.appInfo, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          // API information
          const Divider(),
          const SizedBox(height: 16),
          Text('Google ML Kit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.apiInfo, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          // ML Kit services used
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Services ML Kit',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _ServiceTile(
            icon: Icons.label,
            title: l10n.imageLabeling,
            description: l10n.imageLabelingDesc,
          ),
          _ServiceTile(
            icon: Icons.face,
            title: l10n.selfieSegmentation,
            description: l10n.selfieSegmentationDesc,
          )
        ],
      ),
    );
  }
}

/// A simple tile to display a ML Kit service with icon and description.
class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
    );
  }
}

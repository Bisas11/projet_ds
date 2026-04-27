import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Landing page — the first screen non-authenticated users see.
/// Full-bleed gradient hero + feature list + CTA.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _gradientColors = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-bleed gradient background (top ~58% of screen) ───────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.58,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradientColors,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Decorative circles ─────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: _DecorCircle(size: 220, opacity: 0.07),
          ),
          Positioned(
            top: 140,
            left: -80,
            child: _DecorCircle(size: 180, opacity: 0.06),
          ),
          Positioned(
            top: 60,
            right: 30,
            child: _DecorCircle(size: 60, opacity: 0.12),
          ),

          // ── Scrollable content ─────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 52, 28, 0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_enhance_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.appTitle,
                          style: textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.landingTagline,
                          textAlign: TextAlign.center,
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _FeatureBadge(
                              icon: Icons.image_search_rounded,
                              label: l10n.imageLabeling,
                            ),
                            _FeatureBadge(
                              icon: Icons.crop_free_rounded,
                              label: l10n.selfieSegmentation,
                            ),
                            _FeatureBadge(
                              icon: Icons.sentiment_satisfied_alt_rounded,
                              label: l10n.faceDetection,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Bottom card (floats over gradient) ──────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.landingServicesTitle,
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.landingDescription,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _ServiceCard(
                          icon: Icons.image_search_rounded,
                          title: l10n.imageLabeling,
                          description: l10n.imageLabelingDesc,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 12),
                        _ServiceCard(
                          icon: Icons.crop_free_rounded,
                          title: l10n.selfieSegmentation,
                          description: l10n.selfieSegmentationDesc,
                          color: const Color(0xFF0D9488),
                        ),
                        const SizedBox(height: 12),
                        _ServiceCard(
                          icon: Icons.sentiment_satisfied_alt_rounded,
                          title: l10n.faceDetection,
                          description: l10n.faceDetectionDesc,
                          color: const Color(0xFFF97316),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.rocket_launch_rounded),
                            label: Text(l10n.landingGetStarted),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _onGetStarted(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            child: Text(
                              l10n.haveAccount,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onGetStarted(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }
}

// ── Decorative circle ─────────────────────────────────────────────────────────

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// ── Feature badge ─────────────────────────────────────────────────────────────

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

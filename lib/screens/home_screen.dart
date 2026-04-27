import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// Shared avatar widget — shows profile photo if available, else initials.
Widget _buildAvatarWidget(
  User? user,
  double size, {
  Color? initialsBackground,
}) {
  final photoURL = user?.photoURL;
  final _rawInitials = user?.displayName?.trim().isNotEmpty == true
      ? user!.displayName!
      : user?.email?.trim().isNotEmpty == true
      ? user!.email!
      : 'P';
  final initials = _rawInitials[0].toUpperCase();
  if (photoURL != null && photoURL.isNotEmpty) {
    if (!photoURL.startsWith('http')) {
      final file = File(photoURL);
      if (file.existsSync()) {
        return CircleAvatar(radius: size / 2, backgroundImage: FileImage(file));
      }
    } else {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoURL),
      );
    }
  }
  return CircleAvatar(
    radius: size / 2,
    backgroundColor: initialsBackground ?? const Color(0xFF4F46E5),
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.40,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Home screen: main hub with navigation cards to each ML feature.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  late final StreamSubscription<User?> _userSub;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    // userChanges() fires on displayName / photoURL updates
    _userSub = FirebaseAuth.instance.userChanges().listen((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  @override
  void dispose() {
    _userSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/about'),
            tooltip: l10n.about,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: l10n.history,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: l10n.settings,
          ),
          // Padding(
          //   padding: const EdgeInsets.only(right: 12),
          //   child: GestureDetector(
          //     onTap: () => Navigator.pushNamed(context, '/profile'),
          //     child: _buildAvatarWidget(_user, 36),
          //   ),
          // ),
        ],
      ),
      drawer: _AppDrawer(l10n: l10n, user: _user),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Welcome gradient banner ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcome,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _user?.displayName ??
                            _user?.email?.split('@').first ??
                            'Photographer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.chooseFeature,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 2,
                      ),
                    ),
                    child: _buildAvatarWidget(
                      _user,
                      46,
                      initialsBackground: Colors.white.withOpacity(0.25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Primary CTA ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.analyzePhoto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tapPhotoToStart,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/photo-assistant'),
                  icon: const Icon(Icons.camera_enhance_rounded),
                  label: Text(l10n.analyzePhoto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    minimumSize: const Size.fromHeight(44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Advanced Tools section header ────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.advancedTools,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Image Labeling card
          _FeatureCard(
            title: l10n.imageLabeling,
            description: l10n.imageLabelingDesc,
            icon: Icons.image_search_rounded,
            iconColor: Colors.indigo,
            route: '/image-labeling',
          ),
          const SizedBox(height: 12),

          // Selfie Segmentation card
          _FeatureCard(
            title: l10n.selfieSegmentation,
            description: l10n.selfieSegmentationDesc,
            icon: Icons.crop_free_rounded,
            iconColor: Colors.teal,
            route: '/selfie-segmentation',
          ),
          const SizedBox(height: 12),

          // Face Detection card
          _FeatureCard(
            title: l10n.faceDetection,
            description: l10n.faceDetectionDesc,
            icon: Icons.sentiment_satisfied_alt_rounded,
            iconColor: Colors.deepOrange,
            route: '/face-detection',
          ),
        ],
      ),
    );
  }
}

/// A simple card widget for navigation to a feature screen.
class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final Color? iconColor;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App Drawer ────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final AppLocalizations l10n;
  final User? user;

  const _AppDrawer({required this.l10n, required this.user});

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '';
    final displayName =
        user?.displayName ??
        (email.isNotEmpty ? email.split('@').first : l10n.appTitle);

    return Drawer(
      child: Column(
        children: [
          // ── Header with gradient ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 24,
              24,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.45),
                      width: 2.5,
                    ),
                  ),
                  child: _buildAvatarWidget(
                    user,
                    56,
                    initialsBackground: Colors.white.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // ── Nav items ────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: l10n.home,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: l10n.profile,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                _DrawerItem(
                  icon: Icons.history_rounded,
                  label: l10n.history,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/history');
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: l10n.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: l10n.about,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: l10n.logout,
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── App version footer ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Text(
              'PhotoCoach AI  •  v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';

/// Profile screen — view/edit display name, profile photo, and password reset.
/// Reads from and writes to FirebaseAuth.currentUser (no backend storage needed).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Holds the newly picked image before the user saves
  File? _pendingImage;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text =
        user?.displayName ?? user?.email?.split('@').first ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  User? get _user => FirebaseAuth.instance.currentUser;

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    const double radius = 52;

    // Show newly picked image (not saved yet)
    if (_pendingImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_pendingImage!),
      );
    }

    // Show stored photo (local path saved in photoURL)
    final photoURL = _user?.photoURL;
    if (photoURL != null && photoURL.isNotEmpty) {
      if (!photoURL.startsWith('http')) {
        final file = File(photoURL);
        if (file.existsSync()) {
          return CircleAvatar(radius: radius, backgroundImage: FileImage(file));
        }
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(photoURL),
        );
      }
    }

    // Fallback: initials
    final _rawInitials = _user?.displayName?.trim().isNotEmpty == true
        ? _user!.displayName!
        : _user?.email?.trim().isNotEmpty == true
        ? _user!.email!
        : 'P';
    final initials = _rawInitials[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF4F46E5),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
    );
    if (picked == null) return;
    setState(() => _pendingImage = File(picked.path));
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final name = _nameController.text.trim();

      // Update display name
      if (name != user.displayName) {
        await user.updateDisplayName(name);
      }

      // Copy picked image to app docs dir and store path as photoURL
      if (_pendingImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final saved = await _pendingImage!.copy('${appDir.path}/$fileName');
        await user.updatePhotoURL(saved.path);
        _pendingImage = null;
      }

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.savedSuccessfully),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _user?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.resetEmailSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildAvatar(),
                    Positioned(
                      bottom: 0,
                      right: -4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 17),
                  label: Text(l10n.changePhoto),
                  onPressed: _pickImage,
                ),
              ),
              const SizedBox(height: 24),

              // ── Account Info card ────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountInfo.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.45),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email (read-only)
                      TextFormField(
                        initialValue: _user?.email ?? '',
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display name (editable)
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.displayName,
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.nameRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Save ────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? l10n.saving : l10n.saveChanges),
              ),
              const SizedBox(height: 12),

              // ── Reset password ───────────────────────────────────────
              OutlinedButton.icon(
                onPressed: _resetPassword,
                icon: const Icon(Icons.lock_reset_rounded),
                label: Text(l10n.resetPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

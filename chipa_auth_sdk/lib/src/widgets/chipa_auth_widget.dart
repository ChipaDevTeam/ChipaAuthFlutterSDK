import 'package:flutter/material.dart';

import '../models/chipa_auth_error.dart';
import '../models/chipa_auth_result.dart';
import '../services/chipa_auth_service.dart';
import 'chipa_auth_theme.dart';

/// Drop this widget on any page to get a full Chipa login form.
///
/// Example:
///   ChipaAuthWidget(onAuthSuccess: (result) => Navigator.pop(context))
class ChipaAuthWidget extends StatefulWidget {
  final void Function(ChipaAuthResult result) onAuthSuccess;
  final void Function(ChipaAuthError error)? onAuthError;
  final VoidCallback? onSignOut;

  final bool showGoogleSignIn;
  final bool showGithubSignIn;
  final bool showRegister;
  final bool showLicenseInfo;

  final ChipaAuthTheme? theme;

  const ChipaAuthWidget({
    super.key,
    required this.onAuthSuccess,
    this.onAuthError,
    this.onSignOut,
    this.showGoogleSignIn = true,
    this.showGithubSignIn = true,
    this.showRegister = true,
    this.showLicenseInfo = true,
    this.theme,
  });

  @override
  State<ChipaAuthWidget> createState() => _ChipaAuthWidgetState();
}

class _ChipaAuthWidgetState extends State<ChipaAuthWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isRegister = false;
  String? _errorText;

  late ChipaAuthTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? const ChipaAuthTheme();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final auth = ChipaAuth.instance;
      final result = _isRegister
          ? await auth.register(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            )
          : await auth.signIn(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            );
      widget.onAuthSuccess(result);
    } on ChipaAuthError catch (e) {
      setState(() => _errorText = e.message);
      widget.onAuthError?.call(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogle() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final result = await ChipaAuth.instance.signInWithGoogle();
      widget.onAuthSuccess(result);
    } on ChipaAuthError catch (e) {
      setState(() => _errorText = e.message);
      widget.onAuthError?.call(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGithub() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final result = await ChipaAuth.instance.signInWithGithub();
      widget.onAuthSuccess(result);
    } on ChipaAuthError catch (e) {
      setState(() => _errorText = e.message);
      widget.onAuthError?.call(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _theme.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_theme.borderRadius),
      ),
      color: _theme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 24),

                // ── Email field ─────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration:
                      _inputDecoration('Email', Icons.email_outlined),
                  validator: (v) =>
                      (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                ),
                const SizedBox(height: 12),

                // ── Password field ──────────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration:
                      _inputDecoration('Password', Icons.lock_outlined),
                  validator: (v) =>
                      (v == null || v.length < 6)
                          ? 'Minimum 6 characters'
                          : null,
                ),
                const SizedBox(height: 8),

                // ── Error message ───────────────────────────────────────────
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                          color: _theme.errorColor, fontSize: 13),
                    ),
                  ),

                // ── Submit button ───────────────────────────────────────────
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _theme.primaryColor,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isRegister ? 'Create Account' : 'Sign In'),
                ),

                // ── Register toggle ─────────────────────────────────────────
                if (widget.showRegister) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister
                        ? 'Already have an account? Sign in'
                        : "Don't have an account? Register"),
                  ),
                ],

                // ── Divider ─────────────────────────────────────────────────
                if (widget.showGoogleSignIn || widget.showGithubSignIn) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('or',
                          style: TextStyle(color: Colors.grey[500])),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ── Google button ───────────────────────────────────────────
                if (widget.showGoogleSignIn)
                  _OAuthButton(
                    label: 'Continue with Google',
                    icon: const Icon(Icons.g_mobiledata, size: 22),
                    onPressed: _isLoading ? null : _onGoogle,
                  ),

                // ── GitHub button ───────────────────────────────────────────
                if (widget.showGithubSignIn) ...[
                  const SizedBox(height: 8),
                  _OAuthButton(
                    label: 'Continue with GitHub',
                    icon: const Icon(Icons.code, size: 20),
                    onPressed: _isLoading ? null : _onGithub,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_theme.primaryColor, _theme.accentColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to Chipa',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _theme.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Continue to your account',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── OAuth button helper ───────────────────────────────────────────────────────
class _OAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const _OAuthButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
}

import 'package:flutter/material.dart';

import '../models/chipa_auth_error.dart';
import '../models/chipa_auth_result.dart';
import 'chipa_auth_theme.dart';
import 'chipa_auth_widget.dart';

/// A pre-built "Sign in with Chipa" button that opens [ChipaAuthWidget]
/// as a bottom sheet.
class ChipaAuthButton extends StatelessWidget {
  final void Function(ChipaAuthResult) onAuthSuccess;
  final void Function(ChipaAuthError)? onAuthError;
  final String label;
  final ChipaAuthTheme? theme;

  const ChipaAuthButton({
    super.key,
    required this.onAuthSuccess,
    this.onAuthError,
    this.label = 'Sign in with Chipa',
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.lock_outline),
      label: Text(label),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: ColoredBox(
              color: Colors.white,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: ChipaAuthWidget(
                  onAuthSuccess: (result) {
                    Navigator.pop(context);
                    onAuthSuccess(result);
                  },
                  onAuthError: onAuthError,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

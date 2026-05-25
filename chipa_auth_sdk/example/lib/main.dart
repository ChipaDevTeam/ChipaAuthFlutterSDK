import 'package:flutter/material.dart';
import 'package:chipa_auth_flutter/chipa_auth_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SetupApp());
}

// ─── Root: waits for user to enter API key before initialising SDK ───────────
class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChipaAuth Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF667EEA),
        useMaterial3: true,
      ),
      home: const SetupPage(),
    );
  }
}

// ─── SetupPage — configure API URL + API key, then proceed ──────────────────
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController(text: 'https://auth.chipatrade.com');
  final _keyCtrl = TextEditingController();

  void _proceed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ChipaAuth.init(
      apiUrl: _urlCtrl.text.trim(),
      apiKey: _keyCtrl.text.trim(),
      callbackScheme: 'chipaauth',
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security,
                            size: 48, color: Color(0xFF667EEA)),
                        const SizedBox(height: 12),
                        const Text('ChipaAuth Test App',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        const Text('Enter your ChipaAuth credentials',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'API URL',
                            prefixIcon: Icon(Icons.link),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _keyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'License / API Key',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continue to Login'),
                          onPressed: _proceed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LoginPage — shows ChipaAuthWidget ───────────────────────────────────────
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: const Text('ChipaAuth Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ChipaAuthWidget(
              onAuthSuccess: (ChipaAuthResult result) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomePage(result: result),
                  ),
                );
              },
              onAuthError: (ChipaAuthError error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error.message),
                    backgroundColor: Colors.red[700],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HomePage — shows authenticated user + license info ──────────────────────
class HomePage extends StatelessWidget {
  final ChipaAuthResult result;
  const HomePage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final user = result.user;
    final license = result.license;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: const Text('Signed In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await ChipaAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SetupPage()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── User card ───────────────────────────────────────────────
              _InfoCard(
                icon: Icons.person_outline,
                title: 'User',
                rows: [
                  _Row('UID', user.uid),
                  if (user.email != null) _Row('Email', user.email!),
                  if (user.displayName != null)
                    _Row('Name', user.displayName!),
                  _Row('Email verified',
                      user.emailVerified ? 'Yes' : 'No'),
                ],
              ),
              const SizedBox(height: 16),

              // ── Token card ──────────────────────────────────────────────
              _InfoCard(
                icon: Icons.token_outlined,
                title: 'Firebase ID Token',
                rows: [
                  _Row('Token (first 60 chars)',
                      result.token.length > 60
                          ? '${result.token.substring(0, 60)}…'
                          : result.token),
                ],
              ),
              const SizedBox(height: 16),

              // ── License card ────────────────────────────────────────────
              if (license != null)
                _InfoCard(
                  icon: Icons.verified_outlined,
                  title: 'License',
                  rows: [
                    if (license.licenseKey != null)
                      _Row('Key', license.licenseKey!),
                    _Row('Status', license.status.name),
                    _Row('Plan', license.plan),
                    _Row('Billing', license.billingCycle),
                    if (license.expiresAt != null)
                      _Row('Expires',
                          license.expiresAt!.toLocal().toString()),
                    _Row('Active', license.isActive ? 'Yes' : 'No'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_Row> rows;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF667EEA), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const Divider(height: 20),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(r.label,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                      Expanded(
                        child: Text(r.value,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}


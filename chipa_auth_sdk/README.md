# chipa_auth_flutter

A Flutter SDK for [ChipaAuth](https://auth.chipatrade.com).  
Drop a single widget onto your login page and get email/password, Google, and GitHub sign-in — **no Firebase SDK, no Google Services JSON, no OAuth credentials needed in your app**.  
Authentication, OAuth, and license management all happen on the hosted ChipaAuth backend.

---

## How it works

```
Your Flutter app                  ChipaAuth backend                 Google / GitHub
──────────────────                ─────────────────────             ───────────────

1. ChipaAuthWidget shown
2. User taps "Sign in
   with Google"
3. POST /oauth/google/init ──────► validate X-API-Key (license)
   X-API-Key: <license key>        sign state token
◄─── { url: "https://..." } ──────
4. Open system browser ──────────────────────────────────────────► consent page
                                  ◄── code + state ────────────────
5.                       ◄─────── exchange code → Firebase token
   deep-link callback              validate license
   chipaauth://callback
   ?idToken=...
6. POST /api/auth/login ─────────► verify token, check/create
   X-API-Key: <license key>         license record
◄─── { user, token, license } ───
7. onAuthSuccess(result) called
```

**No Firebase SDK.  No `google-services.json`.  No OAuth client credentials in the app.**  
The only thing your app needs is a **ChipaLicense key** — which you get automatically the first time you call `/api/auth/login`.

---

## Requirements

- Flutter ≥ 3.10 / Dart ≥ 3.0
- A valid **ChipaLicense key** (obtained on first login — see below)
- `url_launcher` for opening the OAuth browser
- `app_links` for receiving the deep-link callback

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  chipa_auth_flutter:
    git:
      url: https://github.com/chipatrade/chipa_auth_flutter.git
      ref: main
```

Then run:

```bash
flutter pub get
```

### Android — deep-link intent filter

In `android/app/src/main/AndroidManifest.xml`:

```xml
<activity android:name=".MainActivity" ...>
  ...
  <intent-filter android:label="ChipaAuth OAuth callback">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="chipaauth" />
  </intent-filter>
</activity>
```

### iOS — URL scheme

In `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>chipaauth</string></array>
  </dict>
</array>
```

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:chipa_auth_flutter/chipa_auth_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ChipaAuth.init(
    apiUrl:         'https://auth.chipatrade.com',
    apiKey:         'YOUR_CHIPA_LICENSE_KEY',
    callbackScheme: 'chipaauth',
  );

  await ChipaAuth.instance.restoreSession();
  runApp(const MyApp());
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ChipaAuthWidget(
          onAuthSuccess: (ChipaAuthResult result) {
            Navigator.pushReplacementNamed(context, '/home');
          },
          onAuthError: (ChipaAuthError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          },
        ),
      ),
    );
  }
}
```

---

## First-time setup — getting your API key

```bash
curl -X POST https://auth.chipatrade.com/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-API-Key: BOOTSTRAP_OR_TRIAL_KEY" \
  -d '{"email":"you@example.com","password":"yourpassword"}'
# { "license": { "licenseKey": "XXXXX-XXXXX-XXXXX" } }
```

Store `license.licenseKey` and pass it to `ChipaAuth.init(apiKey: '...')`.

---

## Widget Reference

### `ChipaAuthWidget`

```dart
ChipaAuthWidget(
  onAuthSuccess: (ChipaAuthResult result) { … },
  onAuthError:   (ChipaAuthError error)   { … },
  onSignOut:     ()                       { … },
  showGoogleSignIn:  true,
  showGithubSignIn:  true,
  showRegister:      true,
  showLicenseInfo:   true,
  theme: ChipaAuthTheme(
    primaryColor:    const Color(0xFF667EEA),
    backgroundColor: Colors.white,
    cardElevation:   8,
    borderRadius:    16,
  ),
)
```

### `ChipaAuthButton`

```dart
ChipaAuthButton(
  label: 'Sign in with Chipa',
  onAuthSuccess: (result) { … },
)
```

---

## SDK API Reference

```dart
ChipaAuth.init(apiUrl: '...', apiKey: '...');
final auth = ChipaAuth.instance;

// Sign in
await auth.signIn(email: '...', password: '...');
await auth.signInWithGoogle();
await auth.signInWithGithub();
await auth.signInWithIdToken(idToken);

// Register
await auth.register(email: '...', password: '...', displayName: '...');

// Session
auth.currentUser;
auth.currentLicense;
auth.currentToken;
auth.isSignedIn;
auth.authStateChanges.listen((user) { … });

// Token
await auth.verifyToken(token);
await auth.restoreSession();

// License
await auth.getMyLicenses();
await auth.validateLicense('XXXXX-XXXXX');

// Sign out
await auth.signOut();
```

---

## Error Handling

All methods throw `ChipaAuthError` on failure:

| Field | Type | Description |
|---|---|---|
| `message` | `String` | Human-readable error |
| `statusCode` | `int?` | HTTP status (400, 401, 422 …) |
| `cause` | `Object?` | Underlying exception |

```dart
try {
  await ChipaAuth.instance.signIn(email: email, password: password);
} on ChipaAuthError catch (e) {
  if (e.statusCode == 401) { /* Wrong credentials */ }
  else if (e.statusCode == 403) { /* Invalid API key */ }
}
```

---

## License

MIT — see [LICENSE](LICENSE)


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

The plugin project was generated without specifying the `--platforms` flag, no platforms are currently supported.
To add platforms, run `flutter create -t plugin --platforms <platforms> .` in this directory.
You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/to/pubspec-plugin-platforms.

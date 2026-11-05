import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../farmer/home.dart';
import '../veterinarian/home.dart';
import '../surveillance/home.dart';
import '../admin/admin_home.dart';
import '../farmer/reporting/data/reports_api_client.dart';
import 'registration_page.dart';
import 'role_selection_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _isSigningIn = false;

  static const _adminTestEmail = String.fromEnvironment('ADMIN_TEST_EMAIL');
  static const _adminTestPassword = String.fromEnvironment('ADMIN_TEST_PASSWORD');
  static const _enableAdminTestLogin = bool.fromEnvironment(
    'ENABLE_ADMIN_TEST_LOGIN',
    defaultValue: false,
  );

  bool get _isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  bool get _showAdminTestLogin =>
      _enableAdminTestLogin && !kReleaseMode && !kProfileMode;

  @override
  void initState() {
    super.initState();
    if (!_isLinux) {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn.instance;
      _initializeGoogleSignIn();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isLinux || kIsWeb || _isInitializing || _isInitialized) return;

    final GoogleSignIn? googleSignIn = _googleSignIn;
    if (googleSignIn == null) return;

    _isInitializing = true;

    try {
      await googleSignIn.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;

    if (_isLinux) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Sign-In is unavailable on Linux. Use a demo role above.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final FirebaseAuth? auth = _auth;
    final GoogleSignIn? googleSignIn = _googleSignIn;
    if (auth == null || googleSignIn == null) return;

    setState(() => _isSigningIn = true);

    try {
      late final UserCredential credential;

      if (kIsWeb) {
        credential = await auth.signInWithPopup(GoogleAuthProvider());
      } else {
        await _initializeGoogleSignIn();

        if (!_isInitialized) {
          throw Exception(
            'Google Sign-In initialization failed. Check your configuration.',
          );
        }

        if (!googleSignIn.supportsAuthenticate()) {
          throw UnsupportedError(
            'Google Sign-In is unavailable on this platform.',
          );
        }

        final GoogleSignInAccount account =
            await googleSignIn.authenticate();

        final String? idToken = account.authentication.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw Exception(
            'Google did not return an ID token. Check your OAuth configuration.',
          );
        }

        credential = await auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Firebase did not return an authenticated user.');
      }

      final String? firebaseIdToken = await user.getIdToken();

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Could not obtain the Firebase ID token.');
      }

       final profile = await _verifyWithBackend(firebaseIdToken);

      if (!mounted) return;

        await _routeAfterAuthentication(profile);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase authentication error: ${e.code}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.message ?? e.code}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In error: ${e.code}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.code}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to sign in: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<BackendProfile> _verifyWithBackend(String firebaseIdToken) async {
    if (firebaseIdToken.isEmpty) throw Exception('Could not obtain the Firebase ID token.');
    final profile = await ReportsApiClient().verifySession(firebaseIdToken: firebaseIdToken);
    debugPrint('Backend profile loaded: roles=${profile.roles}, pending=${profile.pendingRoleRequests}');
    return profile;
  }

  Future<void> _routeAfterAuthentication(BackendProfile profile) async {
    if (!mounted) return;
    final roles = profile.roles.map((role) => role.trim().toLowerCase()).toSet();
    final Widget? destination = roles.contains('administrator')
        ? const AdminHome()
        : roles.contains('farmer')
        ? const FarmerHome()
        : roles.contains('veterinarian')
            ? const VeterinarianHome()
            : roles.contains('surveillance_officer')
                ? const SurveillanceHome()
                : null;
    debugPrint('Authentication navigation: roles=$roles, destination=${destination?.runtimeType ?? 'RoleSelectionPage'}');
    await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination ?? const RoleSelectionPage()));
  }

  // Developer-only testing helper to open a demo role dashboard or show a notice if not created yet.
  void _openDemoRole(String role) {
    FocusScope.of(context).unfocus();
    final Widget? destination = _demoDashboardForRole(role);

    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dashboard for $role has not been created yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  // Demo-only role routing. This does not authenticate the user with Firebase.
  Widget? _demoDashboardForRole(String role) {
    switch (role) {
      case 'farmer':
        return const FarmerHome();
      case 'vet':
      case 'veterinarian':
      case 'veterinary officer':
      case 'veterinary_officer':
        return const VeterinarianHome();
      case 'surveillance officer':
      case 'surveillance_officer':
      case 'officer':
      case 'government official':
      case 'government_official':
      case 'surveillance official':
         return const SurveillanceHome();
      default:
        return null;
    }
  }

  void _handleSignIn() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final emailOrRole = _emailController.text.trim();
    if (!emailOrRole.contains('@')) {
      _openDemoRole(emailOrRole.toLowerCase());
      return;
    }
    _authenticateWithEmail(emailOrRole, _passwordController.text);
  }

  Future<void> _authenticateWithEmail(
    String email,
    String password, {
    bool requireAdministrator = false,
  }) async {
    final auth = _auth;
    if (auth == null) {
      _showMessage('Firebase authentication is unavailable on this platform.');
      return;
    }
    setState(() => _isSigningIn = true);
    try {
      final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      final token = await credential.user?.getIdToken();
      if (token == null || token.isEmpty) throw Exception('Could not obtain the Firebase ID token.');
      final profile = await _verifyWithBackend(token);
      if (!mounted) return;
      if (requireAdministrator &&
          !profile.roles.any((role) => role.trim().toLowerCase() == 'administrator')) {
        await auth.signOut();
        _showMessage(
          'This account is authenticated but is not provisioned as an administrator in Neon.',
        );
        return;
      }
      _showMessage('Signed in successfully.');
       await _routeAfterAuthentication(profile);
    } on FirebaseAuthException catch (error) {
      _showMessage(_firebaseErrorMessage(error));
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _handleAdminTestLogin() async {
    if (!_showAdminTestLogin || _isSigningIn) return;
    FocusScope.of(context).unfocus();

    if (_adminTestEmail.isEmpty || _adminTestPassword.isEmpty) {
      _showMessage(
        'Admin test login is enabled, but its build configuration is incomplete. '
        'Provide ADMIN_TEST_EMAIL and ADMIN_TEST_PASSWORD.',
      );
      return;
    }

    await _authenticateWithEmail(
      _adminTestEmail,
      _adminTestPassword,
      requireAdministrator: true,
    );
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Sign in instead.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'user-disabled':
        return 'This Firebase account has been disabled.';
      case 'network-request-failed':
        return 'Firebase could not connect. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled in Firebase Console.';
      default:
        return error.message ?? 'Firebase authentication failed (${error.code}).';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Widget _buildBrandPanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 42,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 180),
              Text(
                'JeevSwasth',
                style: textTheme.displaySmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connected care for every animal, every community, and every day.',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: colors.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'A trusted space for your animal health journey.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoRoleButtons(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surfaceContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_mode_outlined, size: 20, color: colors.primary),
                const SizedBox(width: 10),
                Text(
                  'Demo access',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Explore a role without creating an account.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSigningIn ? null : () => _openDemoRole('farmer'),
                  icon: const Icon(Icons.agriculture_outlined, size: 18),
                  label: const Text('Farmer'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSigningIn ? null : () => _openDemoRole('veterinarian'),
                  icon: const Icon(Icons.medical_services_outlined, size: 18),
                  label: const Text('Veterinarian'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSigningIn ? null : () => _openDemoRole('surveillance officer'),
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: const Text('Surveillance'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue to your account.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                enabled: !_isSigningIn,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email or demo role',
                  hintText: 'you@example.com or farmer',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Please enter your email.';
                  if (email.contains('@')) {
                    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
                    if (!valid) return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                enabled: !_isSigningIn,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSignIn(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your password.';
                  if (value.length < 6) return 'Use at least 6 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSigningIn ? null : _handleSignIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(_isSigningIn ? 'Signing in...' : 'Sign in'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSigningIn
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegistrationPage(),
                          ),
                        ),
                child: const Text('Need an account? Create one'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSigningIn)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    else
                      const FaIcon(FontAwesomeIcons.google, size: 18),
                    const SizedBox(width: 10),
                    Text(_isSigningIn ? 'Signing in...' : 'Continue with Google'),
                  ],
                ),
              ),
              if (_showAdminTestLogin) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSigningIn ? null : _handleAdminTestLogin,
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Test Login',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'For administrator testing',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildDemoRoleButtons(context),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Your health information deserves privacy.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = isWide ? 40.0 : 20.0;
            final verticalPadding = isWide ? 32.0 : 20.0;
            final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, isWide ? 1180.0 : 520.0)
                .toDouble();
            final bottomPadding = mediaQuery.viewInsets.bottom > 0
                ? mediaQuery.viewInsets.bottom + 20.0
                : verticalPadding;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildBrandPanel(context)),
                            const SizedBox(width: 32),
                            SizedBox(width: 480, child: _buildLoginCard(context)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 28),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.health_and_safety_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'JeevSwasth',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildLoginCard(context),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

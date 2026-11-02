import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../farmer/home.dart';
import '../veterinarian/home.dart';
import '../surveillance/home.dart';
import '../farmer/reporting/data/reports_api_client.dart';
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
  bool _isCreateAccount = false;

  bool get _isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

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
    final Widget? destination = roles.contains('farmer')
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

  Future<void> _authenticateWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      _showMessage('Firebase authentication is unavailable on this platform.');
      return;
    }
    setState(() => _isSigningIn = true);
    try {
      final credential = _isCreateAccount
          ? await auth.createUserWithEmailAndPassword(email: email, password: password)
          : await auth.signInWithEmailAndPassword(email: email, password: password);
      final token = await credential.user?.getIdToken();
      if (token == null || token.isEmpty) throw Exception('Could not obtain the Firebase ID token.');
      final profile = await _verifyWithBackend(token);
      if (!mounted) return;
      _showMessage(_isCreateAccount ? 'Account created successfully.' : 'Signed in successfully.');
       await _routeAfterAuthentication(profile);
    } on FirebaseAuthException catch (error) {
      _showMessage(_firebaseErrorMessage(error));
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        size: 42,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'JeevSwasth',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your health, all in one place.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    _isCreateAccount ? 'Create your account' : 'Welcome back',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCreateAccount ? 'Create a farmer account to submit reports.' : 'Sign in to continue to your account.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isSigningIn,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                             labelText: 'Email${_isCreateAccount ? '' : ' or role'}',
                             hintText: _isCreateAccount ? 'you@example.com' : 'Demo role, e.g. farmer',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                               return 'Please enter your email.';
                            }
                            if (_isCreateAccount || email.contains('@')) {
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
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }
                            if (value.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _isSigningIn ? null : _handleSignIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_isCreateAccount ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSigningIn ? null : () => setState(() => _isCreateAccount = !_isCreateAccount),
                    child: Text(_isCreateAccount ? 'Already have an account? Sign in' : 'Need an account? Create one'),
                  ),
                  const SizedBox(height: 24),
                  // Developer-only testing functionality
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: colors.outlineVariant),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'DEVELOPER TESTING',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: colors.outlineVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isSigningIn ? null : () => _openDemoRole('farmer'),
                        icon: const Icon(Icons.agriculture_outlined),
                        label: const Text('Test Farmer'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          side: BorderSide(color: colors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSigningIn ? null : () => _openDemoRole('veterinarian'),
                        icon: const Icon(Icons.medical_services_outlined),
                        label: const Text('Test Veterinarian'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          side: BorderSide(color: colors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSigningIn ? null : () => _openDemoRole('surveillance officer'),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Test Surveillance Officer'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          side: BorderSide(color: colors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: colors.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: colors.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
                          const FaIcon(FontAwesomeIcons.google, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _isSigningIn
                              ? 'Signing in...'
                              : 'Continue with Google',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Your health information deserves privacy.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

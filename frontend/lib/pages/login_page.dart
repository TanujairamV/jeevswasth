import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../farmer/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (kIsWeb || _isInitializing || _isInitialized) return;

    _isInitializing = true;

    try {
      await _googleSignIn.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;

    setState(() => _isSigningIn = true);

    try {
      late final UserCredential credential;

      if (kIsWeb) {
        credential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        await _initializeGoogleSignIn();

        if (!_isInitialized) {
          throw Exception(
            'Google Sign-In initialization failed. Check your configuration.',
          );
        }

        if (!_googleSignIn.supportsAuthenticate()) {
          throw UnsupportedError(
            'Google Sign-In is unavailable on this platform.',
          );
        }

        final GoogleSignInAccount account =
            await _googleSignIn.authenticate();

        final String? idToken = account.authentication.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw Exception(
            'Google did not return an ID token. Check your OAuth configuration.',
          );
        }

        credential = await _auth.signInWithCredential(
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

      debugPrint('Firebase user authenticated: ${user.uid}');
      debugPrint('Email: ${user.email}');

      await _verifyWithBackend(firebaseIdToken);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in successful.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Future<void> _verifyWithBackend(String firebaseIdToken) async {
    debugPrint(
      'Firebase ID token obtained. NestJS verification is not connected yet.',
    );
  }

  // Demo-only role routing. This does not authenticate the user with Firebase.
  Widget? _demoDashboardForRole(String role) {
    switch (role) {
      case 'farmer':
        return const FarmerHome();
      // 'vet', 'fieldworker' and 'officer' cases belong here once their
      // dashboard screens (and classes) exist.
      default:
        return null;
    }
  }

  void _handleSignIn() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String role = _emailController.text.trim().toLowerCase();
    final Widget? destination = _demoDashboardForRole(role);

    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No demo dashboard is available for "$role" yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
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
                    'Welcome back',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
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
                            labelText: 'Email or role',
                            hintText: 'Demo role, e.g. farmer',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email or role.';
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
                    child: const Text('Sign in'),
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
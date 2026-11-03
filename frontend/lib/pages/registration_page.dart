import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../farmer/home.dart';
import '../farmer/reporting/data/reports_api_client.dart';
import '../registration/registration_location.dart';
import '../registration/registration_location_service.dart';
import 'role_selection_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _accountFormKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _farmerArea = TextEditingController();
  final _veterinaryRegistration = TextEditingController();
  final _veterinaryOrganization = TextEditingController();
  final _officerOrganization = TextEditingController();
  final _officerArea = TextEditingController();
  final _apiClient = ReportsApiClient();
  final _locationService = RegistrationLocationService();

  int _step = 0;
  String? _role;
  RegistrationLocation? _location;
  bool _locating = false;
  bool _submitting = false;
  String? _error;

  bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _email,
      _mobile,
      _password,
      _confirmPassword,
      _farmerArea,
      _veterinaryRegistration,
      _veterinaryOrganization,
      _officerOrganization,
      _officerArea,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !(_accountFormKey.currentState?.validate() ?? false)) return;
    if (_step == 1 && _role == null) {
      _showMessage('Choose a role to continue.');
      return;
    }
    if (_step < 4) {
      setState(() {
        _step += 1;
        _error = null;
      });
      return;
    }
    await _submit();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  Future<void> _detectLocation() async {
    if (_locating || _submitting) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final location = await _locationService.detect();
      if (!mounted) return;
      setState(() {
        _location = location;
        _locating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      _showMessage(error.toString().replaceFirst('RegistrationLocationException: ', ''));
    }
  }

  void _clearLocation() {
    setState(() => _location = null);
  }

  String? _normalizedMobile() {
    final value = _mobile.text.replaceAll(RegExp(r'[\s-]'), '');
    if (value.isEmpty) return null;
    if (RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) return '+91$value';
    if (RegExp(r'^0[6-9][0-9]{9}$').hasMatch(value)) return '+91${value.substring(1)}';
    if (RegExp(r'^\+91[6-9][0-9]{9}$').hasMatch(value)) return value;
    return null;
  }

  Future<void> _submit() async {
    final mobile = _normalizedMobile();
    if (_mobile.text.trim().isNotEmpty && mobile == null) {
      _showMessage('Enter a valid Indian mobile number or leave it empty.');
      return;
    }
    if (_isLinux) {
      _showMessage('Registration is unavailable on the Linux preview.');
      return;
    }
    if (_role == null) {
      _showMessage('Choose a role to continue.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final existing = FirebaseAuth.instance.currentUser;
      final credential = existing?.email == _email.text.trim()
          ? null
          : await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
      final user = credential?.user ?? existing;
      if (user == null) throw Exception('Firebase did not return the new account.');
      await user.updateDisplayName(_fullName.text.trim());
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) throw Exception('Could not obtain the Firebase ID token.');
      await _apiClient.updateProfile({
        'displayName': _fullName.text.trim(),
        'mobileNumber': mobile,
        'location': _location?.toJson(),
        'roleDetails': _roleDetails(),
      });
      final assignment = await _apiClient.requestRole(_role!);
      if (!mounted) return;
      final destination = _role == 'farmer' && assignment == 'assigned'
          ? const FarmerHome()
          : const RoleSelectionPage();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => destination),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _submitting = false);
      _showMessage(_firebaseErrorMessage(error));
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Map<String, dynamic> _roleDetails() {
    switch (_role) {
      case 'farmer':
        return {'area': _farmerArea.text.trim()};
      case 'veterinarian':
        return {
          'registrationNumber': _veterinaryRegistration.text.trim(),
          'organization': _veterinaryOrganization.text.trim(),
        };
      case 'surveillance_officer':
        return {
          'organization': _officerOrganization.text.trim(),
          'area': _officerArea.text.trim(),
        };
      default:
        return {};
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
      case 'network-request-failed':
        return 'Firebase could not connect. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled in Firebase Console.';
      default:
        return error.message ?? 'Firebase registration failed.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
        leading: IconButton(
          onPressed: _submitting ? null : _back,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = (constraints.maxWidth * 0.06).clamp(16.0, 40.0).toDouble();
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProgressHeader(step: _step),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(key: ValueKey(_step), child: _stepContent(colors)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: colors.error)),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (_step > 0) ...[
                            Expanded(child: OutlinedButton(onPressed: _submitting ? null : _back, child: const Text('Back'))),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: FilledButton(
                              onPressed: _submitting ? null : _next,
                              child: _submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(_step == 4 ? 'Create account' : 'Continue'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _stepContent(ColorScheme colors) {
    switch (_step) {
      case 0:
        return _accountStep();
      case 1:
        return _roleStep();
      case 2:
        return _detailsStep();
      case 3:
        return _locationStep(colors);
      default:
        return _reviewStep(colors);
    }
  }

  Widget _accountStep() {
    return Form(
      key: _accountFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title: 'Account details', subtitle: 'Create your JEEVSWASTH account.'),
          const SizedBox(height: 20),
          TextFormField(controller: _fullName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name *', prefixIcon: Icon(Icons.person_outline)), validator: (value) => value == null || value.trim().isEmpty ? 'Enter your full name.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)), validator: (value) => value == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()) ? 'Enter a valid email address.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number (optional)', hintText: '+91 9876543210', prefixIcon: Icon(Icons.phone_outlined)), validator: (value) => value == null || value.trim().isEmpty || _normalizedMobile() != null ? null : 'Enter a valid Indian mobile number.'),
          const SizedBox(height: 14),
          TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock_outline)), validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password *', prefixIcon: Icon(Icons.lock_reset_outlined)), validator: (value) => value != _password.text ? 'Passwords do not match.' : null),
        ],
      ),
    );
  }

  Widget _roleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(title: 'Choose your role', subtitle: 'Officer roles require approval after registration.'),
        const SizedBox(height: 20),
        _RoleChoice(title: 'Farmer', subtitle: 'Submit livestock health reports and follow updates.', icon: Icons.agriculture_outlined, selected: _role == 'farmer', onTap: () => setState(() => _role = 'farmer')),
        _RoleChoice(title: 'Veterinarian', subtitle: 'Review reports and support animal-health care.', icon: Icons.medical_services_outlined, selected: _role == 'veterinarian', onTap: () => setState(() => _role = 'veterinarian')),
        _RoleChoice(title: 'Surveillance Officer', subtitle: 'Monitor aggregated reports and public-health signals.', icon: Icons.admin_panel_settings_outlined, selected: _role == 'surveillance_officer', onTap: () => setState(() => _role = 'surveillance_officer')),
      ],
    );
  }

  Widget _detailsStep() {
    final fields = switch (_role) {
      'farmer' => [
        TextFormField(
          controller: _farmerArea,
          decoration: const InputDecoration(
            labelText: 'Village or area (optional)',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
      ],
      'veterinarian' => [
        TextFormField(
          controller: _veterinaryRegistration,
          decoration: const InputDecoration(
            labelText: 'Professional registration number (optional)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _veterinaryOrganization,
          decoration: const InputDecoration(
            labelText: 'Clinic or organization (optional)',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
      ],
      _ => [
        TextFormField(
          controller: _officerOrganization,
          decoration: const InputDecoration(
            labelText: 'Department or organization (optional)',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _officerArea,
          decoration: const InputDecoration(
            labelText: 'Assigned area (optional)',
            prefixIcon: Icon(Icons.map_outlined),
          ),
        ),
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(
          title: 'Role details',
          subtitle: 'Add details that help tailor your experience.',
        ),
        const SizedBox(height: 20),
        ...fields,
      ],
    );
  }

  Widget _locationStep(ColorScheme colors) {
    final location = _location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(
          title: 'Optional location',
          subtitle:
              'Location helps tailor local services. It is optional and is never used as proof of identity or authorization.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _locating ? null : _detectLocation,
          icon: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_outlined),
          label: Text(
            _locating
                ? 'Detecting location...'
                : location == null
                    ? 'Use current location'
                    : 'Retry location detection',
          ),
        ),
        const SizedBox(height: 12),
        if (location != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.formattedAddress ??
                        'Coordinates detected; address unavailable.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude ${location.latitude.toStringAsFixed(5)} · Longitude ${location.longitude.toStringAsFixed(5)}',
                  ),
                  if (location.state != null) Text('State: ${location.state}'),
                  if (location.district != null)
                    Text('District: ${location.district}'),
                  if (location.locality != null)
                    Text('Locality: ${location.locality}'),
                  if (location.postalCode != null)
                    Text('PIN: ${location.postalCode}'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _clearLocation,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear location'),
                  ),
                ],
              ),
            ),
          ),
        if (location == null)
          Text(
            'You can continue without sharing a location.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _reviewStep(ColorScheme colors) {
    final mobile = _normalizedMobile();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _StepTitle(title: 'Review and submit', subtitle: 'Check your details before creating the account.'),
      const SizedBox(height: 20),
      _ReviewRow(label: 'Full name', value: _fullName.text),
      _ReviewRow(label: 'Email', value: _email.text),
      _ReviewRow(label: 'Mobile', value: mobile ?? 'Not provided'),
      _ReviewRow(label: 'Role', value: _roleLabel()),
      _ReviewRow(label: 'Location', value: _location?.formattedAddress ?? 'Not provided'),
      const SizedBox(height: 16),
      Text('By creating an account, you agree that optional contact and location details are sent only when you provide them.', style: TextStyle(color: colors.onSurfaceVariant)),
    ]);
  }

  String _roleLabel() => switch (_role) { 'farmer' => 'Farmer', 'veterinarian' => 'Veterinarian', 'surveillance_officer' => 'Surveillance Officer', _ => 'Not selected' };
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final labels = ['Account', 'Role', 'Details', 'Location', 'Review'];
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: index <= step
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  foregroundColor: index <= step
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (index < labels.length - 1)
            Expanded(child: Divider(thickness: 2)),
        ],
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]);
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(color: selected ? Theme.of(context).colorScheme.secondaryContainer : null, child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked)));
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value.isEmpty ? 'Not provided' : value))]));
}

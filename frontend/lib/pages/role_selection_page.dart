import 'package:flutter/material.dart';
import '../farmer/home.dart';
import '../veterinarian/home.dart';
import '../surveillance/home.dart';
import '../farmer/reporting/data/reports_api_client.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
  @override State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final _client = ReportsApiClient();
  BackendProfile? _profile;
  String? _error;
  bool _loading = true;
  String? _saving;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final profile = await _client.profile(); debugPrint('Role profile loaded: roles=${profile.roles}, pending=${profile.pendingRoleRequests}'); if (mounted) setState(() { _profile = profile; _loading = false; }); } catch (e) { debugPrint('Role profile load failed: ${e.runtimeType}'); if (mounted) setState(() { _error = e.toString(); _loading = false; }); } }
  Widget? _dashboard(String role) => switch (role.trim().toLowerCase()) { 'farmer' => const FarmerHome(), 'veterinarian' => const VeterinarianHome(), 'surveillance_officer' => const SurveillanceHome(), _ => null };
  Future<void> _choose(String role) async {
    setState(() => _saving = role);
    try { final result = await _client.requestRole(role); if (!mounted) return; if (result == 'assigned') { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => _dashboard(role)!), (_) => false); } else { setState(() { _saving = null; _profile = BackendProfile(roles: _profile?.roles ?? const [], pendingRoleRequests: [...?_profile?.pendingRoleRequests, role]); }); } } catch (e) { if (mounted) setState(() { _saving = null; _error = e.toString(); }); }
  }
  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null && _profile == null) return Scaffold(body: _ErrorState(message: _error!, retry: _load));
    final profile = _profile!;
    final assigned = profile.roles.firstWhere((role) => _dashboard(role) != null, orElse: () => '');
    if (assigned.isNotEmpty) return _Redirecting(dashboard: _dashboard(assigned)!);
    return Scaffold(appBar: AppBar(title: const Text('Choose your role')), body: ListView(padding: const EdgeInsets.all(20), children: [Text('How will you use JEEVSWASTH?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('Choose the role that best describes you. Officer roles require approval.', style: Theme.of(context).textTheme.bodyLarge), const SizedBox(height: 24), _RoleCard(title: 'Farmer', subtitle: 'Submit livestock health reports and follow updates.', icon: Icons.agriculture_outlined, state: profile.pendingRoleRequests.contains('farmer') ? 'Requested' : null, loading: _saving == 'farmer', onTap: () => _choose('farmer')), _RoleCard(title: 'Veterinarian', subtitle: 'Review reports and support animal-health care.', icon: Icons.medical_services_outlined, state: profile.pendingRoleRequests.contains('veterinarian') ? 'Pending approval' : null, loading: _saving == 'veterinarian', onTap: () => _choose('veterinarian')), _RoleCard(title: 'Surveillance Officer', subtitle: 'Monitor aggregated reports and public-health signals.', icon: Icons.admin_panel_settings_outlined, state: profile.pendingRoleRequests.contains('surveillance_officer') ? 'Pending approval' : null, loading: _saving == 'surveillance_officer', onTap: () => _choose('surveillance_officer')), if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)), TextButton(onPressed: _load, child: const Text('Retry'))]]));
  }
}

class _Redirecting extends StatefulWidget { const _Redirecting({required this.dashboard}); final Widget dashboard; @override State<_Redirecting> createState() => _RedirectingState(); }
class _RedirectingState extends State<_Redirecting> { @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => widget.dashboard)); }); } @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator())); }
class _RoleCard extends StatelessWidget { const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.onTap, this.state, this.loading = false}); final String title, subtitle; final IconData icon; final VoidCallback onTap; final String? state; final bool loading; @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 14), child: ListTile(contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$subtitle${state == null ? '' : '\n$state'}'), trailing: loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : FilledButton(onPressed: state == null ? onTap : null, child: Text(state == null ? 'Choose' : 'Sent')))); }
class _ErrorState extends StatelessWidget { const _ErrorState({required this.message, required this.retry}); final String message; final VoidCallback retry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 44), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: retry, child: const Text('Retry'))]))); }

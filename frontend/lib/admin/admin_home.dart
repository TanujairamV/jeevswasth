import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'admin_api_client.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _client = AdminApiClient();
  int _selected = 0;
  AdminOverview? _overview;
  String? _error;

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    (Icons.assignment_outlined, Icons.assignment, 'Applications'),
    (Icons.people_outline, Icons.people, 'Users'),
    (Icons.map_outlined, Icons.map, 'Disease reports'),
    (Icons.insights_outlined, Icons.insights, 'Analytics'),
    (Icons.history_outlined, Icons.history, 'Audit logs'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  void initState() { super.initState(); _loadOverview(); }

  Future<void> _loadOverview() async {
    try {
      final overview = await _client.overview();
      if (mounted) setState(() { _overview = overview; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _select(int index) {
    setState(() => _selected = index);
    if (index == 0) _loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final page = switch (_selected) {
      0 => AdminDashboardPage(overview: _overview, error: _error, onRetry: _loadOverview, onApplications: () => _select(1)),
      1 => AdminApplicationsPage(client: _client),
      2 => AdminUsersPage(client: _client),
      3 => AdminReportsPage(client: _client),
      4 => AdminAnalyticsPage(overview: _overview, error: _error, onRetry: _loadOverview),
      5 => AdminAuditPage(client: _client),
      _ => const AdminSettingsPage(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Icon(Icons.shield_outlined), const SizedBox(width: 10), Text(_items[_selected].$3)]),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Chip(avatar: const Icon(Icons.verified_user_outlined, size: 17), label: const Text('Administrator')))],
      ),
      drawer: wide ? null : NavigationDrawer(selectedIndex: _selected, onDestinationSelected: (index) { Navigator.pop(context); _select(index); }, children: [_drawerHeader(context), ..._items.map((item) => NavigationDrawerDestination(icon: Icon(item.$1), selectedIcon: Icon(item.$2), label: Text(item.$3)))]),
      body: SafeArea(child: Row(children: [
        if (wide) NavigationRail(
          selectedIndex: _selected,
          onDestinationSelected: _select,
          labelType: NavigationRailLabelType.all,
          leading: Padding(padding: const EdgeInsets.only(bottom: 24), child: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(Icons.shield, color: Theme.of(context).colorScheme.onPrimaryContainer))),
          destinations: _items.map((item) => NavigationRailDestination(icon: Icon(item.$1), selectedIcon: Icon(item.$2), label: Text(item.$3))).toList(),
        ),
        Expanded(child: page),
      ])),
    );
  }

  Widget _drawerHeader(BuildContext context) => DrawerHeader(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
        child: Align(alignment: Alignment.bottomLeft, child: Text('JEEVSWASTH\nAdmin Console', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
      );
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.overview, required this.error, required this.onRetry, required this.onApplications});
  final AdminOverview? overview;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onApplications;

  @override
  Widget build(BuildContext context) {
    if (error != null && overview == null) return _ErrorPanel(message: error!, onRetry: onRetry);
    if (overview == null) return const Center(child: CircularProgressIndicator());
    final metrics = overview!.metrics;
    return _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _PageIntro(title: 'Good morning, administrator', subtitle: 'A live operational view of JEEVSWASTH activity and review queues.'),
      LayoutBuilder(builder: (context, constraints) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: constraints.maxWidth >= 1000 ? 4 : constraints.maxWidth >= 600 ? 2 : 1, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5, children: [
        _MetricCard(label: 'Registered users', value: metrics['users']!, icon: Icons.people_outline, color: Colors.indigo),
        _MetricCard(label: 'Active users', value: metrics['active']!, icon: Icons.verified_user_outlined, color: Colors.green),
        _MetricCard(label: 'Pending applications', value: metrics['pending']!, icon: Icons.assignment_late_outlined, color: Colors.orange, onTap: onApplications),
        _MetricCard(label: 'Reports · 7 days', value: metrics['recentReports']!, icon: Icons.monitor_heart_outlined, color: Colors.red),
        _MetricCard(label: 'Farmers', value: metrics['farmers']!, icon: Icons.agriculture_outlined, color: Colors.teal),
        _MetricCard(label: 'Veterinarians', value: metrics['veterinarians']!, icon: Icons.medical_services_outlined, color: Colors.blue),
        _MetricCard(label: 'Surveillance officers', value: metrics['officers']!, icon: Icons.visibility_outlined, color: Colors.purple),
        _MetricCard(label: 'All disease reports', value: metrics['reports']!, icon: Icons.analytics_outlined, color: Colors.deepOrange),
      ])),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 800
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _TrendCard(title: 'Report activity · last 30 days', data: overview!.reportTrend, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _RoleCard(data: overview!.roles)),
            ])
          : Column(children: [
              _TrendCard(title: 'Report activity · last 30 days', data: overview!.reportTrend, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              _RoleCard(data: overview!.roles),
            ])),
      const SizedBox(height: 20),
      _SectionCard(title: 'Review queue', icon: Icons.fact_check_outlined, child: ListTile(contentPadding: EdgeInsets.zero, title: Text('${metrics['pending']} applications waiting for review'), subtitle: const Text('Review veterinarian and surveillance officer credentials.'), trailing: FilledButton.tonal(onPressed: onApplications, child: const Text('Open queue')))),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 800
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _DistributionCard(title: 'Reports by species', labelKey: 'species', data: overview!.species, icon: Icons.pets_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _DistributionCard(title: 'Reports by region', labelKey: 'region', data: overview!.regions, icon: Icons.location_on_outlined)),
            ])
          : Column(children: [
              _DistributionCard(title: 'Reports by species', labelKey: 'species', data: overview!.species, icon: Icons.pets_outlined),
              const SizedBox(height: 16),
              _DistributionCard(title: 'Reports by region', labelKey: 'region', data: overview!.regions, icon: Icons.location_on_outlined),
            ])),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Recent activity',
        icon: Icons.bolt_outlined,
        child: overview!.recentActivity.isEmpty
            ? const _EmptyState(message: 'No recent report activity.')
            : Column(children: overview!.recentActivity.map<Widget>((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.add_alert_outlined),
                  title: Text(item['action'] as String? ?? 'Activity'),
                  subtitle: Text('${item['target'] ?? 'Report'} · ${item['created_at'] ?? ''}'),
                );
              }).toList()),
      ),
    ]));
  }
}

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key, required this.overview, required this.error, required this.onRetry});
  final AdminOverview? overview;
  final String? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (error != null && overview == null) return _ErrorPanel(message: error!, onRetry: onRetry);
    if (overview == null) return const Center(child: CircularProgressIndicator());
    return _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _PageIntro(title: 'Analytics', subtitle: 'Live aggregates calculated from registered users and submitted reports.'),
      _TrendCard(title: 'User registrations · last 30 days', data: overview!.userTrend, color: Theme.of(context).colorScheme.tertiary),
      const SizedBox(height: 16),
      _TrendCard(title: 'Disease reports · last 30 days', data: overview!.reportTrend, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 16),
      _RoleCard(data: overview!.roles),
      const SizedBox(height: 16),
      _DistributionCard(title: 'Reports by species', labelKey: 'species', data: overview!.species, icon: Icons.pets_outlined),
      const SizedBox(height: 16),
      _DistributionCard(title: 'Reports by region', labelKey: 'region', data: overview!.regions, icon: Icons.location_on_outlined),
    ]));
  }
}

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key, required this.client});
  final AdminApiClient client;
  @override State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  final _search = TextEditingController();
  AdminPage<AdminApplication>? _page;
  String? _role;
  String? _error;
  bool _loading = true;
  int _currentPage = 1;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async { setState(() => _loading = true); try { final result = await widget.client.applications(search: _search.text, role: _role, page: _currentPage); if (mounted) setState(() { _page = result; _error = null; _loading = false; }); } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); } }
  Future<void> _review(AdminApplication application, bool approve) async {
    String? reason;
    if (!approve) reason = await _reasonDialog();
    if (!approve && reason == null) return;
    try { if (approve) { await widget.client.approveApplication(application.id); } else { await widget.client.rejectApplication(application.id, reason!); } if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Application approved.' : 'Application rejected.'))); _load(); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }
  Future<String?> _reasonDialog() async { final controller = TextEditingController(); final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Reason for rejection'), content: TextField(controller: controller, maxLines: 4, autofocus: true, decoration: const InputDecoration(labelText: 'Reason', hintText: 'Explain what needs to be corrected.')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Reject'))])); controller.dispose(); return result; }
  @override Widget build(BuildContext context) => _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _PageIntro(title: 'Role applications', subtitle: 'Review identity and submitted credentials before assigning privileged roles.'), _Toolbar(search: _search, hint: 'Search applicants', onSearch: () { _currentPage = 1; _load(); }, filters: [DropdownButton<String?>(value: _role, hint: const Text('All roles'), items: const [DropdownMenuItem(value: null, child: Text('All roles')), DropdownMenuItem(value: 'veterinarian', child: Text('Veterinarians')), DropdownMenuItem(value: 'surveillance_officer', child: Text('Surveillance officers'))], onChanged: (value) { setState(() { _role = value; _currentPage = 1; }); _load(); })]), if (_loading && _page == null) const LinearProgressIndicator(), if (_error != null) _ErrorPanel(message: _error!, onRetry: _load), if (_page != null) ...[_SectionCard(title: '${_page!.total} pending applications', icon: Icons.assignment_outlined, child: _page!.items.isEmpty ? const _EmptyState(message: 'No pending applications.') : Column(children: _page!.items.map((application) => _ApplicationTile(application: application, onApprove: () => _review(application, true), onReject: () => _review(application, false))).toList())), _Pagination(page: _page!, onChanged: (page) { setState(() => _currentPage = page); _load(); })]]));
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application, required this.onApprove, required this.onReject});
  final AdminApplication application; final VoidCallback onApprove; final VoidCallback onReject;
  @override
  Widget build(BuildContext context) {
    final applicant = application.applicant;
    final role = application.requestedRole == 'veterinarian' ? 'Veterinarian' : 'Surveillance officer';
    final details = applicant['roleDetails'];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(child: Icon(application.requestedRole == 'veterinarian' ? Icons.medical_services_outlined : Icons.visibility_outlined)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(applicant['displayName'] as String? ?? 'Unnamed applicant', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(applicant['email'] as String? ?? 'No email'),
              Text('$role · ${_date(application.submittedAt)}', style: Theme.of(context).textTheme.bodySmall),
            ])),
            OutlinedButton(onPressed: onReject, child: const Text('Reject')),
            const SizedBox(width: 8),
            FilledButton(onPressed: onApprove, child: const Text('Approve')),
          ]),
          if (details is Map && details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(spacing: 8, runSpacing: 6, children: details.entries.map<Widget>((entry) => Chip(label: Text('${entry.key}: ${entry.value}'))).toList()),
            ),
        ]),
      ),
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, required this.client});
  final AdminApiClient client;
  @override State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _search = TextEditingController();
  AdminPage<Map<String, dynamic>>? _page;
  String? _role;
  String? _status;
  String? _error;
  bool _loading = true;
  int _currentPage = 1;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async { setState(() => _loading = true); try { final result = await widget.client.users(search: _search.text, role: _role, status: _status, page: _currentPage); if (mounted) setState(() { _page = result; _error = null; _loading = false; }); } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); } }
  Future<void> _toggle(Map<String, dynamic> user) async { final active = user['is_active'] as bool? ?? true; final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(active ? 'Deactivate account?' : 'Activate account?'), content: Text(active ? 'The user will no longer be able to access JEEVSWASTH.' : 'Restore access for this account?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(active ? 'Deactivate' : 'Activate'))])); if (confirmed != true) return; try { await widget.client.setUserStatus(user['id'] as String, !active); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account status updated.'))); _load(); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }
  Future<void> _details(String id) async { try { final user = await widget.client.user(id); if (!mounted) return; showDialog<void>(context: context, builder: (context) => _UserDetailsDialog(user: user)); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }
  @override Widget build(BuildContext context) => _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _PageIntro(title: 'User management', subtitle: 'Review account state and assigned roles. Privileged roles are controlled by the approval workflow.'), _Toolbar(search: _search, hint: 'Search name or email', onSearch: () { _currentPage = 1; _load(); }, filters: [DropdownButton<String?>(value: _role, hint: const Text('All roles'), items: const [DropdownMenuItem(value: null, child: Text('All roles')), DropdownMenuItem(value: 'farmer', child: Text('Farmers')), DropdownMenuItem(value: 'veterinarian', child: Text('Veterinarians')), DropdownMenuItem(value: 'surveillance_officer', child: Text('Officers')), DropdownMenuItem(value: 'administrator', child: Text('Administrators'))], onChanged: (value) { setState(() { _role = value; _currentPage = 1; }); _load(); }), DropdownButton<String?>(value: _status, hint: const Text('Any status'), items: const [DropdownMenuItem(value: null, child: Text('Any status')), DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive'))], onChanged: (value) { setState(() { _status = value; _currentPage = 1; }); _load(); })]), if (_loading && _page == null) const LinearProgressIndicator(), if (_error != null) _ErrorPanel(message: _error!, onRetry: _load), if (_page != null) ...[_SectionCard(title: '${_page!.total} users', icon: Icons.people_outline, child: _page!.items.isEmpty ? const _EmptyState(message: 'No users found.') : Column(children: _page!.items.map((user) => _UserTile(user: user, onDetails: () => _details(user['id'] as String), onToggle: () => _toggle(user))).toList())), _Pagination(page: _page!, onChanged: (page) { setState(() => _currentPage = page); _load(); })]]));
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onDetails, required this.onToggle});
  final Map<String, dynamic> user; final VoidCallback onDetails; final VoidCallback onToggle;
  @override Widget build(BuildContext context) { final active = user['is_active'] as bool? ?? true; final roles = (user['roles'] as List? ?? const []).join(', '); return ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 6), leading: CircleAvatar(child: Text(((user['display_name'] as String? ?? user['email'] as String? ?? '?').characters.first).toUpperCase())), title: Text(user['display_name'] as String? ?? 'Unnamed user', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${user['email'] ?? 'No email'}\n${roles.isEmpty ? 'No assigned role' : roles} · ${active ? 'Active' : 'Inactive'}'), isThreeLine: true, trailing: Wrap(spacing: 4, children: [IconButton(tooltip: 'View profile', onPressed: onDetails, icon: const Icon(Icons.open_in_new)), IconButton(tooltip: active ? 'Deactivate' : 'Activate', onPressed: onToggle, icon: Icon(active ? Icons.person_off_outlined : Icons.person_outline))])); }
}

class _UserDetailsDialog extends StatelessWidget {
  const _UserDetailsDialog({required this.user});
  final Map<String, dynamic> user;
  @override Widget build(BuildContext context) { final reports = user['reports'] as List? ?? const []; return AlertDialog(title: Text(user['display_name'] as String? ?? 'User profile'), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(user['email'] as String? ?? 'No email'), const SizedBox(height: 8), Text('Roles: ${(user['roles'] as List? ?? const []).join(', ')}'), Text('Status: ${(user['is_active'] as bool? ?? true) ? 'Active' : 'Inactive'}'), if (user['formatted_address'] != null) Text('Location: ${user['formatted_address']}'), const Divider(height: 28), Text('Submitted reports (${reports.length})', style: const TextStyle(fontWeight: FontWeight.w700)), ...reports.take(10).map((report) => ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text('${report['species']} · ${report['village']}'), subtitle: Text('${report['animal_count']} animals · ${_date(DateTime.tryParse(report['report_timestamp'] as String? ?? '') ?? DateTime.now())}')))]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]); }
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key, required this.client});
  final AdminApiClient client;
  @override State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _search = TextEditingController();
  AdminPage<AdminReport>? _page;
  String? _error;
  bool _loading = true;
  int _currentPage = 1;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async { setState(() => _loading = true); try { final result = await widget.client.reports(search: _search.text, page: _currentPage); if (mounted) setState(() { _page = result; _error = null; _loading = false; }); } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); } }
  Future<void> _details(AdminReport report) async { try { final full = await widget.client.report(report.id); if (!mounted) return; showDialog<void>(context: context, builder: (context) => _ReportDetailsDialog(report: full)); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }
  @override
  Widget build(BuildContext context) {
    final page = _page;
    return _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _PageIntro(title: 'Disease reports', subtitle: 'Search submitted livestock reports and inspect their privacy-safe location data.'),
      _Toolbar(search: _search, hint: 'Search report, village or farmer', onSearch: () { _currentPage = 1; _load(); }),
      if (_loading && page == null) const LinearProgressIndicator(),
      if (_error != null) _ErrorPanel(message: _error!, onRetry: _load),
      if (page != null) ...[
        _SectionCard(
          title: '${page.total} reports',
          icon: Icons.monitor_heart_outlined,
          child: page.items.isEmpty
              ? const _EmptyState(message: 'No reports found.')
              : Column(children: page.items.map<Widget>((report) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(child: Icon(Icons.pets_outlined, color: Theme.of(context).colorScheme.primary)),
                    title: Text('${report.species} · ${report.village}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${report.animalCount} animals · ${report.symptoms.isEmpty ? 'No symptoms listed' : report.symptoms.join(', ')}\n${_date(report.timestamp)}'),
                    isThreeLine: true,
                    trailing: IconButton(tooltip: 'View report', onPressed: () => _details(report), icon: const Icon(Icons.open_in_new)),
                  )).toList()),
        ),
        const SizedBox(height: 16),
        _SectionCard(title: 'Report locations', icon: Icons.map_outlined, child: _AdminReportMap(reports: page.items)),
        _Pagination(page: page, onChanged: (nextPage) { setState(() => _currentPage = nextPage); _load(); }),
      ],
    ]));
  }
}

class _ReportDetailsDialog extends StatelessWidget {
  const _ReportDetailsDialog({required this.report});
  final AdminReport report;
  @override Widget build(BuildContext context) => AlertDialog(title: Text('${report.species} report'), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Report ID: ${report.id}'), Text('Village: ${report.village}'), Text('Animals: ${report.animalCount}'), Text('Submitted: ${_date(report.timestamp)}'), if (report.ownerName != null) Text('Farmer profile: ${report.ownerName} (${report.ownerEmail ?? 'no email'})'), const SizedBox(height: 12), Text('Symptoms: ${report.symptoms.isEmpty ? 'None recorded' : report.symptoms.join(', ')}'), Text('Clinical signs: ${report.clinicalSigns.isEmpty ? 'None recorded' : report.clinicalSigns.join(', ')}'), if (report.notes != null && report.notes!.isNotEmpty) Text('Notes: ${report.notes}'), if (report.latitude != null) Text('Location: ${report.latitude}, ${report.longitude}')]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]);
}

class _AdminReportMap extends StatefulWidget {
  const _AdminReportMap({required this.reports});
  final List<AdminReport> reports;
  @override State<_AdminReportMap> createState() => _AdminReportMapState();
}

class _AdminReportMapState extends State<_AdminReportMap> {
  MapLibreMapController? _controller;
  static const _initial = CameraPosition(target: LatLng(29.6857, 76.9905), zoom: 8.5);
  @override Widget build(BuildContext context) => SizedBox(height: 300, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: MapLibreMap(styleString: 'https://tiles.openfreemap.org/styles/liberty', initialCameraPosition: _initial, gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())}, compassEnabled: false, rotateGesturesEnabled: false, scrollGesturesEnabled: true, zoomGesturesEnabled: true, dragEnabled: true, onMapCreated: (controller) => _controller = controller, onStyleLoadedCallback: _addMarkers)));
  Future<void> _addMarkers() async { final controller = _controller; if (controller == null) return; for (final report in widget.reports.where((report) => report.latitude != null && report.longitude != null)) { await controller.addCircle(CircleOptions(geometry: LatLng(report.latitude!, report.longitude!), circleColor: '#BA1A1A', circleRadius: 8, circleOpacity: .85, circleStrokeColor: '#FFFFFF', circleStrokeWidth: 2)); } }
}

class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key, required this.client});
  final AdminApiClient client;
  @override State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  final _search = TextEditingController();
  AdminPage<Map<String, dynamic>>? _page;
  String? _error;
  bool _loading = true;
  int _currentPage = 1;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async { setState(() => _loading = true); try { final result = await widget.client.auditLogs(search: _search.text, page: _currentPage); if (mounted) setState(() { _page = result; _error = null; _loading = false; }); } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); } }
  @override Widget build(BuildContext context) => _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _PageIntro(title: 'Audit logs', subtitle: 'Immutable server-recorded activity for account and application administration.'), _Toolbar(search: _search, hint: 'Search action or person', onSearch: () { _currentPage = 1; _load(); }), if (_loading && _page == null) const LinearProgressIndicator(), if (_error != null) _ErrorPanel(message: _error!, onRetry: _load), if (_page != null) ...[_SectionCard(title: '${_page!.total} events', icon: Icons.history, child: _page!.items.isEmpty ? const _EmptyState(message: 'No audit events yet.') : Column(children: _page!.items.map((event) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 5), leading: const Icon(Icons.event_note_outlined), title: Text(event['action'] as String? ?? 'Administrative action', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${event['target_name'] ?? 'System target'} · ${_date(DateTime.tryParse(event['created_at'] as String? ?? '') ?? DateTime.now())}${event['reason'] == null ? '' : '\nReason: ${event['reason']}'}'), isThreeLine: event['reason'] != null)).toList())), _Pagination(page: _page!, onChanged: (page) { setState(() => _currentPage = page); _load(); })]]));
}

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});
  @override Widget build(BuildContext context) => _PageScroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _PageIntro(title: 'Settings', subtitle: 'Operational guidance for the administrator account and production environment.'), _SectionCard(title: 'Administrator access', icon: Icons.security_outlined, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Administrator access is granted only by the trusted server-side bootstrap procedure.'), SizedBox(height: 8), Text('Administrator is intentionally absent from public registration and role selection. All dashboard APIs verify the Firebase ID token and database role on every request.')])) , const SizedBox(height: 16), _SectionCard(title: 'Notifications', icon: Icons.notifications_none, child: const ListTile(contentPadding: EdgeInsets.zero, title: Text('Approval notifications'), subtitle: Text('The review records are ready for a notification provider. Applicant notifications should be connected to the organisation’s approved messaging service.'))), const SizedBox(height: 16), _SectionCard(title: 'Data protection', icon: Icons.privacy_tip_outlined, child: const ListTile(contentPadding: EdgeInsets.zero, title: Text('Privacy-safe reporting'), subtitle: Text('Disease report coordinates are visible only to authorised administrators and are never exposed through the public cluster endpoint.')))]));
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});
  final Widget child;
  @override Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1240), child: child)));
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.title, required this.subtitle});
  final String title; final String subtitle;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))]));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});
  final String label; final int value; final IconData icon; final Color color; final VoidCallback? onTap;
  @override Widget build(BuildContext context) { final card = Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [CircleAvatar(backgroundColor: color.withValues(alpha: .14), foregroundColor: color, child: Icon(icon)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)]))]))); return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: card); }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title; final IconData icon; final Widget child;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))]), const SizedBox(height: 14), child])));
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.title, required this.data, required this.color});
  final String title; final List<Map<String, dynamic>> data; final Color color;
  @override
  Widget build(BuildContext context) {
    final values = data.map((item) => (item['count'] as num?)?.toDouble() ?? 0).toList();
    final max = values.fold<double>(0, (current, value) => value > current ? value : current);
    final chart = data.isEmpty
        ? const _EmptyState(message: 'No activity recorded in this period.')
        : Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(data.length, (index) {
            final height = max == 0 ? 4.0 : 100 * values[index] / max;
            final day = data[index]['day'] as String? ?? '';
            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${values[index].round()}', style: const TextStyle(fontSize: 10)),
              const SizedBox(height: 4),
              Container(height: height.clamp(4.0, 100.0), decoration: BoxDecoration(color: color.withValues(alpha: .78), borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
              const SizedBox(height: 5),
              Text(day.length > 5 ? day.substring(day.length - 5) : day, style: const TextStyle(fontSize: 9)),
            ])));
          }));
    return _SectionCard(title: title, icon: Icons.show_chart, child: SizedBox(height: 170, child: chart));
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.data});
  final List<Map<String, dynamic>> data;
  @override Widget build(BuildContext context) => _SectionCard(title: 'Role distribution', icon: Icons.pie_chart_outline, child: Column(children: data.map((item) { final role = item['role'] as String? ?? 'unknown'; final count = (item['count'] as num?)?.toInt() ?? 0; return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: Text(role.replaceAll('_', ' '))), Text('$count', style: const TextStyle(fontWeight: FontWeight.w700))])); }).toList()));
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.title, required this.labelKey, required this.data, required this.icon});
  final String title;
  final String labelKey;
  final List<Map<String, dynamic>> data;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: title,
        icon: icon,
        child: data.isEmpty
            ? const _EmptyState(message: 'No reports recorded.')
            : Column(children: data.map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(child: Text((item[labelKey] as String? ?? 'Unknown').replaceAll('_', ' '))),
                    Text('${(item['count'] as num?)?.toInt() ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                );
              }).toList()),
      );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.search, required this.hint, required this.onSearch, this.filters = const []});
  final TextEditingController search; final String hint; final VoidCallback onSearch; final List<Widget> filters;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [SizedBox(width: 320, child: TextField(controller: search, onSubmitted: (_) => onSearch(), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: onSearch, icon: const Icon(Icons.arrow_forward)), hintText: hint, border: const OutlineInputBorder()))), ...filters]));
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.page, required this.onChanged});
  final AdminPage<dynamic> page; final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Page ${page.page} of ${page.totalPages}'), const SizedBox(width: 8), IconButton(tooltip: 'Previous page', onPressed: page.page > 1 ? () => onChanged(page.page - 1) : null, icon: const Icon(Icons.chevron_left)), IconButton(tooltip: 'Next page', onPressed: page.page < page.totalPages ? () => onChanged(page.page + 1) : null, icon: const Icon(Icons.chevron_right))]));
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_off_outlined, size: 46, color: Theme.of(context).colorScheme.error), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.tonal(onPressed: onRetry, child: const Text('Retry'))])));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))));
}

String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

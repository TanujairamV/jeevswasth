import 'package:flutter/material.dart';

class SurveillanceProfilePage extends StatefulWidget {
  const SurveillanceProfilePage({super.key, required this.onMessage});
  final ValueChanged<String> onMessage;
  @override
  State<SurveillanceProfilePage> createState() =>
      _SurveillanceProfilePageState();
}

class _SurveillanceProfilePageState extends State<SurveillanceProfilePage> {
  bool velocityAlerts = true, rrtUpdates = true, highContrast = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: Text('Officer profile & coverage'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person),
                  ),
                  title: const Text(
                    'Surveillance Officer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'District Surveillance · Karnal Hub\nAuthorized operational account',
                  ),
                  trailing: Icon(Icons.verified),
                ),
              ),
              const SizedBox(height: 16),
              _section(colors, 'Authorized coverage', [
                const ListTile(
                  leading: Icon(Icons.map_outlined),
                  title: Text('Karnal District'),
                  subtitle: Text(
                    'Karnal Sadar · Indri · Assandh · Nilokheri · Gharaunda',
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Least-privilege access'),
                  subtitle: Text(
                    'Boundary changes require State Epidemiologist approval.',
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _section(colors, 'Sync & privacy', [
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Telemetry sync'),
                  subtitle: const Text('Connected · synced 6 minutes ago'),
                  trailing: TextButton(
                    onPressed: () => widget.onMessage(
                      'Manual sync requires a connected backend.',
                    ),
                    child: const Text('Sync now'),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy-safe map data'),
                  subtitle: Text(
                    'Coordinates aggregate into clusters of five or more reports.',
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _section(colors, 'Preferences', [
                SwitchListTile(
                  title: const Text('Syndromic velocity alerts'),
                  value: velocityAlerts,
                  onChanged: (value) => setState(() => velocityAlerts = value),
                ),
                SwitchListTile(
                  title: const Text('Response team updates'),
                  value: rrtUpdates,
                  onChanged: (value) => setState(() => rrtUpdates = value),
                ),
                SwitchListTile(
                  title: const Text('High-contrast outdoor mode'),
                  value: highContrast,
                  onChanged: (value) => setState(() => highContrast = value),
                ),
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  subtitle: Text(
                    'English · regional language support pending review',
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => widget.onMessage(
                  'Sign-out is handled by the authenticated session.',
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _section(ColorScheme colors, String title, List<Widget> children) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      );
}

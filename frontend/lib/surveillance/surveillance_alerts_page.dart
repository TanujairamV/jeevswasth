import 'package:flutter/material.dart';

class SurveillanceAlertsPage extends StatelessWidget {
  const SurveillanceAlertsPage({super.key, required this.onMessage});
  final ValueChanged<String> onMessage;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alerts & watchlists'),
              Text('Operational triage queue', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Card(
                child: const ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('18 active signals'),
                  subtitle: Text('Triage target under 4 hours'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    selected: true,
                    label: const Text('All (18)'),
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Critical (3)'),
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Watchlist (6)'),
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _alert(
                'CRITICAL · UNACKNOWLEDGED',
                'Foot & Mouth Disease signal',
                'Bilaspur · 14 reports · owner unassigned',
                colors.error,
                Icons.crisis_alert,
              ),
              _alert(
                'WATCHLIST · MONITORING',
                'Lumpy skin disease cluster',
                'Indri · 8 reports · field samples in transit',
                colors.tertiary,
                Icons.radar,
              ),
              _alert(
                'SUSPECTED SIGNAL',
                'Brucellosis anomaly',
                'Assandh · 6 reports · lab intake scheduled',
                colors.secondary,
                Icons.show_chart,
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response timeline',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '06:30  Signal ingested\n07:15  Field verification logged\n07:45  DSO acknowledgement pending',
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => onMessage(
                                'Alert acknowledgement requires authenticated backend access.',
                              ),
                              child: const Text('Acknowledge'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onMessage(
                                'Assignment workflow is not connected.',
                              ),
                              child: const Text('Assign owner'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: const ListTile(
                  leading: Icon(Icons.cloud_off),
                  title: Text('Offline actions queued'),
                  subtitle: Text(
                    '3 local triage actions will sync when connectivity returns.',
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _alert(
    String stage,
    String title,
    String detail,
    Color color,
    IconData icon,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$stage\n$detail'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onMessage('Alert details require authorized report data.'),
    ),
  );
}

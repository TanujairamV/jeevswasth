import 'package:flutter/material.dart';

import 'surveillance_risk_map.dart';

class SurveillanceMapPage extends StatelessWidget {
  const SurveillanceMapPage({super.key, required this.onMessage});
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
              Text('Disease vector map'),
              Text('Karnal Hub · Haryana', style: TextStyle(fontSize: 12)),
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
                  title: Text('GIS telemetry live'),
                  subtitle: Text('Synced 6m ago · privacy-safe cache ready'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    selected: true,
                    label: const Text('Karnal District'),
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    selected: true,
                    label: const Text('Risk clusters'),
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    selected: true,
                    label: const Text('Last 72 hours'),
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy-safe surveillance layer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Minimum 5 reports per cluster · individual farm coordinates redacted',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                       SurveillanceRiskMap(
                         height: 300,
                         onMessage: onMessage,
                       ),
                      const SizedBox(height: 10),
                      Text(
                        'High-risk signal  •  Elevated watchlist  •  Baseline',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bilaspur cluster · HR-KL-09',
                        style: TextStyle(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '14 syndromic reports · 3 km containment perimeter active',
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => onMessage(
                          'Authorized drill-down requires a connected report feed.',
                        ),
                        child: const Text('Open authorized dossier'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nearby risk clusters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _cluster(
                'Indri dairy belt',
                '08 reports · field sample in transit',
                colors.tertiary,
              ),
              _cluster(
                'Assandh Ward 4',
                '06 reports · sero-testing scheduled',
                colors.tertiary,
              ),
              _cluster(
                'Nilokheri north',
                '05 reports · monitoring only',
                colors.primary,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _cluster(String title, String subtitle, Color color) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: ListTile(
      leading: Icon(Icons.hub_outlined, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

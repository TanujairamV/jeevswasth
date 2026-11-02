import 'package:flutter/material.dart';

import 'surveillance_risk_map.dart';

class SurveillanceOverviewPage extends StatelessWidget {
  const SurveillanceOverviewPage({
    super.key,
    required this.onMessage,
    required this.onViewFullMap,
  });

  final ValueChanged<String> onMessage;
  final VoidCallback onViewFullMap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Surveillance overview'),
              Text(
                'Karnal District · 24 October 2026',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  onMessage('Notifications require a connected alert service.'),
              icon: const Icon(Icons.notifications_none),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(child: Icon(Icons.person_outline)),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Card(
                color: colors.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: colors.onErrorContainer,
                  ),
                  title: Text(
                    'Active containment zone',
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Bilaspur perimeter · 3 km radius · strict monitoring',
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                  trailing: Chip(
                    label: Text(
                      'Level 3',
                      style: TextStyle(color: colors.onError),
                    ),
                    backgroundColor: colors.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    selected: true,
                    avatar: const Icon(Icons.location_on_outlined, size: 17),
                    label: const Text('Karnal District'),
                    onSelected: (_) =>
                        onMessage('District filter is fixed for this demo.'),
                  ),
                  FilterChip(
                    selected: true,
                    avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('Last 14 days'),
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _metrics(context, colors),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disease risk map',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SurveillanceRiskMap(
                        height: 240,
                        onMessage: onMessage,
                      ),
                      const SizedBox(height: 10),
                      _legend(colors, 'Normal', colors.primary),
                      _legend(colors, 'Elevated (3)', colors.tertiary),
                      _legend(colors, 'High risk (1)', colors.error),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onViewFullMap,
                        icon: const Icon(Icons.open_in_full),
                        label: const Text('View full map'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Active alerts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _alert(
                context,
                colors,
                'Suspected Foot & Mouth Disease',
                'Bilaspur Panchayat · 6 bovine affected',
                colors.error,
              ),
              _alert(
                context,
                colors,
                'Brucellosis vector spike',
                'Assandh Block · 3 dairy herds',
                colors.tertiary,
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.primaryContainer,
                child: ListTile(
                  title: Text(
                    'Rapid Response Team at Bilaspur',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Cordon perimeter inspection in progress',
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                  trailing: const Icon(Icons.campaign_outlined),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _metrics(BuildContext context, ColorScheme colors) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.35,
    children: [
      _metric('Active alerts', '18', Icons.notifications_none, colors.error),
      _metric(
        'Reports in',
        '1,248',
        Icons.assignment_turned_in_outlined,
        colors.primary,
      ),
      _metric('Risk clusters', '04', Icons.radar, colors.tertiary),
      _metric('Villages', '422', Icons.location_searching, colors.primary),
    ],
  );
  Widget _metric(String title, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      );
  Widget _legend(ColorScheme colors, String label, Color color) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
  Widget _alert(
    BuildContext context,
    ColorScheme colors,
    String title,
    String subtitle,
    Color color,
  ) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

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
    final textTheme = Theme.of(context).textTheme;
    final compactHeader = MediaQuery.sizeOf(context).width < 600;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          titleSpacing: compactHeader ? 16 : 24,
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Text(
                compactHeader ? 'Surveillance' : 'Surveillance command',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  onMessage('Notifications require a connected alert service.'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Padding(
              padding: EdgeInsets.only(left: 4, right: compactHeader ? 8 : 20),
              child: IconButton.filledTonal(
                tooltip: 'Officer profile',
                onPressed: () => onMessage('Open the profile tab to manage coverage.'),
                icon: const Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _header(context, colors),
              const SizedBox(height: 20),
              _containmentBanner(context, colors),
              const SizedBox(height: 20),
              _filters(context, colors),
              const SizedBox(height: 20),
              _metrics(context, colors),
              const SizedBox(height: 24),
              _mapAndResponse(context, colors),
              const SizedBox(height: 24),
              _alerts(context, colors),
              const SizedBox(height: 20),
              _privacyNotice(context, colors),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, ColorScheme colors) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 580;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISTRICT SURVEILLANCE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Good morning, Officer',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor emerging animal-health signals across Karnal District.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, size: 16, color: colors.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Last synced 6 minutes ago',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            );

            final action = FilledButton.icon(
              onPressed: onViewFullMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open live map'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.onPrimaryContainer,
                foregroundColor: colors.primaryContainer,
              ),
            );

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 20), action],
              );
            }

            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 20),
                action,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _containmentBanner(BuildContext context, ColorScheme colors) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.error.withValues(alpha: .28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active containment zone',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bilaspur perimeter · 3 km radius · strict monitoring',
                    style: textTheme.bodyMedium?.copyWith(color: colors.onErrorContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'LEVEL 3',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.onError,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(BuildContext context, ColorScheme colors) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: true,
              avatar: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text('Karnal District'),
              onSelected: (_) => onMessage('District filter is fixed for this demo.'),
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: true,
              avatar: const Icon(Icons.calendar_today_outlined, size: 17),
              label: const Text('Last 14 days'),
              onSelected: (_) {},
            ),
            const SizedBox(width: 10),
            FilterChip(
              avatar: Icon(Icons.tune_rounded, size: 18, color: colors.onSurfaceVariant),
              label: const Text('All signals'),
              onSelected: (_) => onMessage('Signal filters are available in the alerts tab.'),
            ),
          ],
        ),
      );

  Widget _metrics(BuildContext context, ColorScheme colors) {
    final metrics = [
      ('Active alerts', '18', Icons.notifications_none_rounded, colors.error),
      ('Reports received', '1,248', Icons.assignment_turned_in_outlined, colors.primary),
      ('Risk clusters', '04', Icons.radar_rounded, colors.tertiary),
      ('Villages covered', '422', Icons.location_searching_rounded, colors.secondary),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        final gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _metricCard(
                    context,
                    colors,
                    title: metric.$1,
                    value: metric.$2,
                    icon: metric.$3,
                    color: metric.$4,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context,
    ColorScheme colors, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapAndResponse(BuildContext context, ColorScheme colors) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 780;
          final map = _mapCard(context, colors);
          final response = _responseCard(context, colors);

          if (!wide) {
            return Column(
              children: [map, const SizedBox(height: 16), response],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: map),
              const SizedBox(width: 16),
              SizedBox(width: 300, child: response),
            ],
          );
        },
      );

  Widget _mapCard(BuildContext context, ColorScheme colors) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disease risk map',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aggregated signals · individual farm coordinates hidden',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'View full map',
                    onPressed: onViewFullMap,
                    icon: const Icon(Icons.open_in_full_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SurveillanceRiskMap(height: 280, onMessage: onMessage),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _legend(colors, 'Normal', colors.primary),
                  _legend(colors, 'Elevated (3)', colors.tertiary),
                  _legend(colors, 'High risk (1)', colors.error),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _responseCard(BuildContext context, ColorScheme colors) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.campaign_outlined, color: colors.onSecondary),
            ),
            const SizedBox(height: 18),
            Text(
              'Response team active',
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rapid Response Team at Bilaspur is inspecting the containment perimeter.',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSecondaryContainer),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: colors.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Started 07:15 today',
                  style: textTheme.labelLarge?.copyWith(color: colors.onSecondaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onMessage('Response team updates require a connected field service.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSecondaryContainer,
                  side: BorderSide(color: colors.onSecondaryContainer.withValues(alpha: .45)),
                ),
                child: const Text('View activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alerts(BuildContext context, ColorScheme colors) {
    final heading = Row(
      children: [
        Expanded(
          child: Text(
            'Priority alerts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton.icon(
          onPressed: () => onMessage('Open the alerts tab to view the full triage queue.'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('View all'),
        ),
      ],
    );

    return Column(
      children: [
        heading,
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final first = _alert(
              context,
              colors,
              'Suspected Foot & Mouth Disease',
              'Bilaspur Panchayat · 6 bovine affected',
              colors.error,
              Icons.crisis_alert_rounded,
              'CRITICAL',
            );
            final second = _alert(
              context,
              colors,
              'Brucellosis vector spike',
              'Assandh Block · 3 dairy herds',
              colors.tertiary,
              Icons.trending_up_rounded,
              'WATCHLIST',
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: first),
                      const SizedBox(width: 12),
                      Expanded(child: second),
                    ],
                  )
                : Column(children: [first, second]);
          },
        ),
      ],
    );
  }

  Widget _alert(
    BuildContext context,
    ColorScheme colors,
    String title,
    String subtitle,
    Color color,
    IconData icon,
    String status,
  ) => Card(
        child: InkWell(
          onTap: () => onMessage('Alert details require authorized report data.'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );

  Widget _privacyNotice(BuildContext context, ColorScheme colors) => Card(
        color: colors.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.privacy_tip_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy-safe surveillance',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Map clusters contain five or more reports. Individual farm coordinates are never shown.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _legend(ColorScheme colors, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

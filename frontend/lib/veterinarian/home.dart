import 'package:flutter/material.dart';
import '../farmer/reporting/livestock_survey_page.dart';
import '../widgets/veterinarian_navbar.dart';
import 'demo_data.dart';

class VeterinarianHome extends StatefulWidget {
  const VeterinarianHome({super.key});
  @override State<VeterinarianHome> createState() => _VeterinarianHomeState();
}

class _VeterinarianHomeState extends State<VeterinarianHome> {
  int selectedIndex = 0;
  bool available = true;
  late final Map<String, bool> followups = {for (final item in demoFollowups) item.id: false};
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.light ? const Color(0xFFEDFFEA) : Theme.of(context).colorScheme.surface,
    body: SafeArea(child: IndexedStack(index: selectedIndex, children: [_dashboard(), _animals(), _surveys(), _alerts()])),
    bottomNavigationBar: VeterinarianNavBar(selectedIndex: selectedIndex, onDestinationSelected: (i) => setState(() => selectedIndex = i)),
  );

  Widget _dashboard() => LayoutBuilder(builder: (context, constraints) {
    final maxWidth = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;
    return Center(child: SizedBox(width: maxWidth, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _header()),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), sliver: SliverList(delegate: SliverChildListDelegate([
        _demoBanner(), _surveillance(), const SizedBox(height: 14), _profile(), const SizedBox(height: 18),
        _section("Today's Triage Load", 'Demo snapshot'), _metrics(), const SizedBox(height: 18),
        _section('Priority Outbreak Cases', '${demoCases.length} demo cases'), ...demoCases.map(_caseCard), const SizedBox(height: 12), _routine(),
        const SizedBox(height: 18), _section('Report and Case Actions', ''), _rapidActions(), const SizedBox(height: 18),
        _mapCard(), const SizedBox(height: 18), _followups(), const SizedBox(height: 14), _syncFooter(),
      ]))),
    ])));
  });

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
    child: Row(children: [
      Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JEEVSWASTH', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
         Text('Veterinary Review', style: Theme.of(context).textTheme.labelSmall),
      ])),
      IconButton(tooltip: 'Alerts', onPressed: () => setState(() => selectedIndex = 3), icon: const Icon(Icons.notifications_none)),
      IconButton(
        tooltip: 'Demo veterinarian profile',
        onPressed: () => _message('$demoVetName is a fictional profile. Account profiles are not connected.'),
        icon: const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
      ),
    ]),
  );
  Widget _demoBanner() => Card(color: Theme.of(context).colorScheme.secondaryContainer, child: const Padding(padding: EdgeInsets.all(11), child: Text('DEMO MODE · fictional records · static snapshot · no live alerts, GPS, identity, or sync claims.')));
  Widget _surveillance() => Card(child: Padding(
    padding: const EdgeInsets.all(10),
    child: Row(children: [
      Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SURVEILLANCE PERIMETER · DEMO', style: Theme.of(context).textTheme.labelSmall),
        Text(demoPerimeter, style: Theme.of(context).textTheme.bodySmall),
        Text('Live status not connected', style: Theme.of(context).textTheme.bodySmall),
      ])),
    ]),
  ));
  Widget _profile() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(demoVetName, style: Theme.of(context).textTheme.titleMedium),
            Text(demoCredentials, style: Theme.of(context).textTheme.bodySmall),
            Text(demoAssignedArea, style: Theme.of(context).textTheme.bodySmall),
          ])),
          const SizedBox(width: 8),
          const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
        ]),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(available ? 'On Emergency Duty' : 'Off Emergency Duty'),
          subtitle: const Text('Demo availability · resets when you leave'),
          value: available,
          onChanged: (value) => setState(() => available = value),
        ),
      ]),
    ),
  );
  Widget _section(String title, String note) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 4, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text(note, style: Theme.of(context).textTheme.labelMedium)]));
  Widget _metrics() => LayoutBuilder(builder: (context, constraints) {
    final colors = Theme.of(context).colorScheme;
    final compact = constraints.maxWidth >= 240 && MediaQuery.textScalerOf(context).scale(12) <= 18;
    final width = compact ? (constraints.maxWidth - 12) / 3 : constraints.maxWidth;
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final metric in demoMetrics)
        SizedBox(width: width, child: Card(
          color: metric.label == 'URGENT' ? colors.errorContainer : colors.primaryContainer,
          child: Padding(padding: const EdgeInsets.all(8), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.label, style: Theme.of(context).textTheme.labelSmall),
              Text(metric.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(metric.detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
        )),
    ]);
  });
  Widget _caseCard(DemoCase item) {
    final colors = Theme.of(context).colorScheme;
    final first = item == demoCases.first;
    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            _badge('${item.severity} · demo', colors.errorContainer, colors.onErrorContainer),
            _badge(item.tag, colors.secondaryContainer, colors.onSecondaryContainer),
            Text(item.elapsed, style: Theme.of(context).textTheme.labelSmall),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.pets, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item.animal} (${item.speciesSexAge})', style: Theme.of(context).textTheme.titleSmall),
              Text('${item.village} · ${item.farmer}', style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: .35), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(first ? 'REPORTED SYMPTOMS' : 'FIELD DIAGNOSTIC INDICATORS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final symptom in item.symptoms)
                  _badge(symptom, colors.errorContainer, colors.onErrorContainer),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: first ? [
            FilledButton.icon(onPressed: () => _showCase(item), icon: const Icon(Icons.fact_check_outlined, size: 16), label: const Text('Review Case')),
            FilledButton.tonalIcon(onPressed: () => _message('Navigate & Call is not connected. Demo records have no real contacts or locations.'), icon: const Icon(Icons.navigation_outlined, size: 16), label: const Text('Navigate & Call')),
          ] : [
            FilledButton.tonalIcon(onPressed: () => _message('Sample collection and laboratory referral are not connected.'), icon: const Icon(Icons.science_outlined, size: 16), label: const Text('Kit Sample')),
            FilledButton.icon(onPressed: () => _message('Paravet assignment and dispatch are not connected.'), icon: const Icon(Icons.send_outlined, size: 16), label: const Text('Dispatch Paravet')),
            TextButton(onPressed: () => _showCase(item), child: const Text('Review demo details')),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground)),
  );
  Widget _routine() => Card(child: ListTile(leading: const Icon(Icons.event_available_outlined), title: const Text('Routine visit'), subtitle: const Text(demoRoutineVisit), trailing: TextButton(onPressed: () => _message('Routine visit actions are unavailable in this demo.'), child: const Text('Details'))));
  Widget _rapidActions() => LayoutBuilder(builder: (context, c) { final width = c.maxWidth >= 240 && MediaQuery.textScalerOf(context).scale(12) <= 18 ? (c.maxWidth - 12) / 2 : c.maxWidth; return Wrap(spacing: 12, runSpacing: 12, children: [
    _action(width, Icons.assignment_outlined, 'Log Symptoms', 'Open genuine survey', () => setState(() => selectedIndex = 2)),
    _action(width, Icons.medication_outlined, 'E-Prescription', 'Demo unavailable', () => _message('E-Prescription is unavailable in this demo.')),
    _action(width, Icons.science_outlined, 'Diagnostic Kit', 'Demo unavailable', () => _message('Diagnostic kit workflow is unavailable in this demo.')),
    _action(width, Icons.route_outlined, 'Daily Route', 'Demo schedule only', () => _message('Daily route is unavailable in this demo.')),
  ]); });
  Widget _action(double width, IconData icon, String title, String subtitle, VoidCallback onTap) => SizedBox(
    width: width,
    child: Card(color: Theme.of(context).colorScheme.surface, child: Semantics(
      button: true,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ]),
      )),
    )),
  );
  Widget _mapCard() => Card(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Assigned Inspection Sector', style: Theme.of(context).textTheme.titleMedium),
        const Text('Illustrative map · not a real geographic boundary'),
        const SizedBox(height: 10),
        SizedBox(height: 150, width: double.infinity, child: ExcludeSemantics(
          child: CustomPaint(painter: _SectorPainter(Theme.of(context).colorScheme)),
        )),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 6, children: [
          Text('$demoHotspots sample hotspots'),
          const Text('GPS precision: unavailable'),
        ]),
        const Divider(),
        Text(demoNextStop),
        TextButton.icon(
          onPressed: () => _message('No real sector coordinates are connected. GPS navigation is unavailable.'),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Open GPS'),
        ),
      ]),
    ),
  );
  Widget _followups() {
    final pending = followups.values.where((value) => !value).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                const Text('Follow-ups', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$pending pending · session only'),
              ],
            ),
            for (final item in demoFollowups)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: followups[item.id],
                onChanged: (value) => setState(() => followups[item.id] = value ?? false),
                title: Text(item.title),
                subtitle: Text(item.detail),
              ),
          ],
        ),
      ),
    );
  }
  Widget _syncFooter() => Row(children: [
    const Icon(Icons.cloud_off, size: 18),
    const SizedBox(width: 8),
    Expanded(child: Text('Sync status unavailable · demo changes are not saved', style: Theme.of(context).textTheme.bodySmall)),
  ]);
  Widget _animals() => _simplePage('Animals', Icons.pets, Column(children: demoAnimals.map((a) => Card(child: ListTile(leading: const Icon(Icons.pets), title: Text(a), subtitle: const Text('Demo read-only animal record')))).toList()));
  Widget _surveys() => _simplePage(
    'Surveys',
    Icons.assignment_outlined,
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This opens the genuine livestock form. Save validates fields, stores locally, and attempts the existing report API submission.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LivestockSurveyPage()),
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open livestock survey'),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _alerts() => _simplePage('Alerts', Icons.notifications_none, const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No live alerts are connected. This is an explicit empty state, not an active alert feed.'))));
  Widget _simplePage(String title, IconData icon, Widget content) => CustomScrollView(slivers: [SliverAppBar(title: Text(title), pinned: true, automaticallyImplyLeading: false), SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(delegate: SliverChildListDelegate([CircleAvatar(radius: 30, child: Icon(icon)), const SizedBox(height: 14), content]))) ]);
  void _showCase(DemoCase item) => showDialog<void>(context: context, builder: (_) => AlertDialog(scrollable: true, title: Text('${item.severity} · ${item.tag}'), content: Text('${item.animal}\n${item.speciesSexAge}\n${item.village}\n${item.farmer}\n\n${item.details}\n\nClinical indicators: ${item.symptoms.join(', ')}\n\nRead-only fictional demo details.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
}

class _SectorPainter extends CustomPainter {
  final ColorScheme colors;
  _SectorPainter(this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final field = Paint()..color = colors.primaryContainer;
    final hot = Paint()..color = colors.error;
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.surfaceContainerHighest);
    canvas.drawRect(Rect.fromLTWH(18, 22, size.width * .32, 52), field);
    canvas.drawRect(Rect.fromLTWH(size.width * .58, 88, size.width * .32, 56), field);
    canvas.drawLine(Offset(0, size.height * .72), Offset(size.width, size.height * .22), road);
    canvas.drawLine(Offset(size.width * .42, 0), Offset(size.width * .72, size.height), road);
    canvas.drawCircle(Offset(size.width * .27, size.height * .62), 8, hot);
    canvas.drawCircle(Offset(size.width * .76, size.height * .38), 8, hot);
  }
  @override bool shouldRepaint(covariant _SectorPainter oldDelegate) => oldDelegate.colors != colors;
}

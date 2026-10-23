import 'package:flutter/material.dart';

import '../widgets/surveillance_navbar.dart';

class SurveillanceHome extends StatefulWidget {
  const SurveillanceHome({super.key});

  @override
  State<SurveillanceHome> createState() => _SurveillanceHomeState();
}

class _SurveillanceHomeState extends State<SurveillanceHome> {
  int _selectedTab = 0;
  bool _last14Days = true;

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _overview(colors),
            _placeholderTab('Map', Icons.map_outlined, 'Live map layers will appear when authorized report locations are available.'),
            _placeholderTab('Alerts', Icons.warning_amber_outlined, 'No live alerts are connected. This screen is ready for authenticated alert data.'),
            _placeholderTab('Profile', Icons.person_outline, 'Surveillance officer profile and geography permissions are not connected yet.'),
          ],
        ),
      ),
      bottomNavigationBar: SurveillanceNavBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (value) => setState(() => _selectedTab = value),
      ),
    );
  }

  Widget _overview(ColorScheme colors) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _header(colors),
              const SizedBox(height: 12),
              _perimeter(colors),
              const SizedBox(height: 14),
              _filters(colors),
              const SizedBox(height: 16),
              _metrics(colors),
              const SizedBox(height: 14),
              _riskMap(colors),
              const SizedBox(height: 18),
              _sectionTitle('Active Alerts', '3 Critical', colors),
              _alertCard(colors, 'HIGH RISK', 'Suspected Foot & Mouth Disease', 'Bilaspur Panchayat • 6 bovine affected', 'Escalated to RRT', colors.error),
              _alertCard(colors, 'ELEVATED', 'Brucellosis Vector Spike', 'Assandh Block • 3 dairy herds', 'Lab sampling pending', colors.tertiary),
              _alertCard(colors, 'ELEVATED', 'Lumpy Skin Nodular Lesions', 'Taraori Block • 4 cattle observed', 'Field monitoring active', colors.primary),
              const SizedBox(height: 14),
              _trendCard(colors),
              const SizedBox(height: 16),
              _responseCard(colors),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _header(ColorScheme colors) => Row(children: [
        CircleAvatar(backgroundColor: colors.primary, child: Icon(Icons.shield_outlined, color: colors.onPrimary)),
        const SizedBox(width: 9),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JEEVSWASTH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text('Surveillance Overview', style: TextStyle(fontSize: 11))])),
        IconButton(onPressed: () => _message('Notifications require a connected alert service.'), icon: const Icon(Icons.notifications_none)),
        CircleAvatar(backgroundColor: colors.primary, child: Icon(Icons.person_outline, color: colors.onPrimary)),
      ]);

  Widget _perimeter(ColorScheme colors) => Card(
        color: colors.tertiaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ListTile(leading: Icon(Icons.location_on_outlined, color: colors.error), title: Text('ACTIVE CONTAINMENT ZONE', style: TextStyle(color: colors.error, fontSize: 10, fontWeight: FontWeight.bold)), subtitle: const Text('Bilaspur Perimeter (3km radius) • Strict...', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Chip(label: Text('Level 3', style: TextStyle(color: colors.onError)), backgroundColor: colors.error)),
      );

  Widget _filters(ColorScheme colors) => Row(children: [
        Expanded(child: _filterChip(Icons.circle, 'Karnal District', colors)),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(Icons.calendar_today_outlined, _last14Days ? 'Last 14 Days' : 'Last 30 Days', colors, onTap: () => setState(() => _last14Days = !_last14Days))),
      ]);

  Widget _filterChip(IconData icon, String label, ColorScheme colors, {VoidCallback? onTap}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)), child: Row(children: [Icon(icon, size: 15), const SizedBox(width: 7), Expanded(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)), const Icon(Icons.expand_more, size: 16)])));

  Widget _metrics(ColorScheme colors) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5, children: [
        _metric('Active Alerts', '18', '+4 crit', Icons.notifications_none, colors.error),
        _metric('Reports In', '1,248', '+14%', Icons.assignment_turned_in_outlined, colors.primary),
        _metric('Clusters', '04', 'Hotspots flagged', Icons.radar, colors.error),
        _metric('Villages', '422', '100% telemetry sync active', Icons.location_searching, colors.primary),
      ]);

  Widget _metric(String title, String value, String detail, IconData icon, Color color) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 11)), CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: .12), child: Icon(icon, size: 16, color: color))]), const Spacer(), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Flexible(child: Text(detail, style: TextStyle(fontSize: 9, color: color)))]),])));

  Widget _riskMap(ColorScheme colors) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('Disease Risk Map', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Chip(label: Text('GIS Layer v4.2', style: TextStyle(fontSize: 9))), const Spacer(), IconButton(onPressed: () => _message('Map drill-down requires an authenticated geospatial feed.'), icon: const Icon(Icons.fullscreen, size: 18))]), const Text('Sample surveillance telemetry for demonstration • NIC Karnal Hub', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)), const SizedBox(height: 10), SizedBox(height: 180, child: CustomPaint(painter: _RiskMapPainter(colors))), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('● Normal', style: TextStyle(fontSize: 10, color: colors.primary)), Text('● Elevated (3)', style: TextStyle(fontSize: 10, color: colors.tertiary)), Text('● High Risk (1)', style: TextStyle(fontSize: 10, color: colors.error))]), const SizedBox(height: 8), Row(children: [const Icon(Icons.gps_fixed, size: 14), const SizedBox(width: 5), const Text('Auto-GPS Sync Active', style: TextStyle(fontSize: 11)), const Spacer(), TextButton(onPressed: () => _message('Hotspot drill-down is unavailable until report locations are connected.'), child: const Text('View Hotspots →'))])])));

  Widget _sectionTitle(String title, String trailing, ColorScheme colors) => Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), Chip(label: Text(trailing, style: TextStyle(fontSize: 10, color: colors.error)))]);

  Widget _alertCard(ColorScheme colors, String level, String title, String subtitle, String status, Color accent) => Card(margin: const EdgeInsets.only(top: 9), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Chip(label: Text(level, style: TextStyle(fontSize: 9, color: accent))), const Spacer(), const Text('22m ago', style: TextStyle(fontSize: 10))]), Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(fontSize: 11)), const SizedBox(height: 8), Row(children: [Icon(Icons.circle, size: 8, color: accent), const SizedBox(width: 5), Text(status, style: TextStyle(fontSize: 10, color: accent)), const Spacer(), const Icon(Icons.chevron_right)]),])));

  Widget _trendCard(ColorScheme colors) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Disease Trends', style: TextStyle(fontWeight: FontWeight.bold)), Text('Syndromic velocity', style: TextStyle(fontSize: 10))]), const Spacer(), ChoiceChip(label: const Text('7D'), selected: true, onSelected: (_) {}), const SizedBox(width: 5), const Text('30D', style: TextStyle(fontSize: 11))]), const SizedBox(height: 12), SizedBox(height: 120, child: CustomPaint(painter: _TrendPainter(colors))), const SizedBox(height: 6), Text('Alert velocity +18.4% above seasonal baseline. FMD signals in Bilaspur & Indri driving recent acceleration.', style: TextStyle(fontSize: 11, color: colors.error))])));

  Widget _responseCard(ColorScheme colors) => Card(color: colors.primaryContainer, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('● DIRECTIVE LIVE', style: TextStyle(color: colors.onPrimaryContainer, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Rapid Response Team at Bilaspur', style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold)), Text('Cordon perimeter inspection in progress', style: TextStyle(color: colors.onPrimaryContainer.withValues(alpha: .75), fontSize: 11)), const SizedBox(height: 12), FilledButton.icon(onPressed: () => _message('Biosecurity advisory workflow is not connected.'), icon: const Icon(Icons.campaign_outlined), label: const Text('Issue Biosecurity Advisory'))])));

  Widget _placeholderTab(String title, IconData icon, String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 30, child: Icon(icon)), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center)])))));
}

class _RiskMapPainter extends CustomPainter {
  const _RiskMapPainter(this.colors);
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)), Paint()..color = colors.surfaceContainerHighest);
    final line = Paint()..color = colors.outlineVariant..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * .7), Offset(size.width, size.height * .4), line);
    canvas.drawLine(Offset(size.width * .3, 0), Offset(size.width * .65, size.height), line);
    canvas.drawCircle(Offset(size.width * .56, size.height * .36), 22, Paint()..color = colors.error.withValues(alpha: .18));
    canvas.drawCircle(Offset(size.width * .56, size.height * .36), 11, Paint()..color = colors.error);
    for (final point in [Offset(size.width * .18, size.height * .55), Offset(size.width * .72, size.height * .18), Offset(size.width * .43, size.height * .72)]) {
      canvas.drawCircle(point, 4, Paint()..color = colors.primary);
    }
  }
  @override
  bool shouldRepaint(covariant _RiskMapPainter oldDelegate) => oldDelegate.colors != colors;
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.colors);
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height * .78)..cubicTo(size.width * .25, size.height * .6, size.width * .45, size.height * .8, size.width * .62, size.height * .45)..cubicTo(size.width * .78, size.height * .15, size.width * .9, size.height * .55, size.width, size.height * .12);
    final fill = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fill, Paint()..color = colors.primaryContainer);
    canvas.drawPath(path, Paint()..color = colors.primary..strokeWidth = 3..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(0, size.height * .34), Offset(size.width, size.height * .34), Paint()..color = colors.error..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.colors != colors;
}

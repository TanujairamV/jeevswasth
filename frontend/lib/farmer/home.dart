import 'package:flutter/material.dart';

import '../widgets/farmer_navbar.dart';
import 'reporting/livestock_survey_page.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int selectedIndex = 0;

  Future<void> _openHealthReport() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LivestockSurveyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: selectedIndex,
          children: [
            _FarmerDashboard(onHealthReport: _openHealthReport),
            _PlaceholderPage(
              title: 'My Animals',
              subtitle: 'View livestock records and vaccination history.',
              icon: Icons.pets,
            ),
            _PlaceholderPage(
              title: 'Surveys',
              subtitle: 'Submit livestock health and mortality reports.',
              icon: Icons.assignment,
              actionLabel: 'Start health report',
              onAction: _openHealthReport,
            ),
            _PlaceholderPage(
              title: 'Alerts',
              subtitle: 'View disease alerts and important notifications.',
              icon: Icons.notifications_active,
            ),
          ],
        ),
      ),
      bottomNavigationBar: FarmerNavBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
      ),
    );
  }
}

class _FarmerDashboard extends StatelessWidget {
  const _FarmerDashboard({required this.onHealthReport});

  final VoidCallback onHealthReport;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(context)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _greeting(context),
              SizedBox(height: 14),
              _monitoringStatus(context),
              SizedBox(height: 18),
              _reportSymptoms(context),
              SizedBox(height: 22),
              _sectionTitle(context, 'Herd Overview', 'Updated 10m ago'),
              SizedBox(height: 10),
              _herdStats(context),
              SizedBox(height: 18),
              _diseaseAlert(context),
              SizedBox(height: 24),
              _sectionTitle(context, 'My Livestock', 'See All (12)  ›'),
              SizedBox(height: 4),
              Text(
                'Tapped profiles show vaccine records & history',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 12),
              _AnimalCard(
                tag: 'Tag #HR-402',
                details: 'Murrah Buffalo • Female, 4 years',
                status: 'Action Needed',
                note: 'Mild Limping • Doctor Assigned',
                icon: Icons.warning_amber_rounded,
                warning: true,
              ),
              _AnimalCard(
                tag: 'Tag #HR-108',
                details: 'Gir Dairy Cow • Female, 3 yrs',
                status: 'Healthy',
                note: 'FMD Vaccinated: 18 Oct 2024',
                icon: Icons.check_circle_outline,
              ),
              _AnimalCard(
                tag: 'Tag #HR-883',
                details: 'Sirohi Goat • Female, 1.5 yrs',
                status: 'Healthy',
                note: 'Deworming due in 14 days',
                icon: Icons.check_circle_outline,
              ),
              SizedBox(height: 20),
              _sectionTitle(context, 'Recent Case Updates', 'Track Live'),
              SizedBox(height: 12),
              _caseCard(context),
              SizedBox(height: 12),
              _completedCard(context),
              SizedBox(height: 20),
              _helplineCard(context),
              SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 23,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JEEVSWASTH',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Surveillance Dashboard',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none)),
          CircleAvatar(
            radius: 17,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _greeting(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namaste Ramesh Ji 🌾',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Bilaspur, Karnal • Haryana',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 16),
              SizedBox(width: 5),
              Text('31°C Fair', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _monitoringStatus(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Theme.of(context).colorScheme.error,
            size: 10,
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(text: '12 Animals Monitored • '),
                  TextSpan(
                    text: '1 Needs Observation',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.verified_user_outlined, size: 17),
        ],
      ),
    );
  }

  Widget _reportSymptoms(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ϟ FAST RESPONSE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Report Animal Symptoms',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Snap photos, speak symptoms in Hindi/Haryanvi, or report via 60s tag triage.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onHealthReport,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: StadiumBorder(),
                  ),
                  icon: Icon(
                    Icons.local_fire_department_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Start Health Report',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(width: 8),
              CircleAvatar(
                radius: 23,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Voice reporting coming soon.')),
                    );
                  },
                  icon: Icon(
                    Icons.mic_none,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        Text(trailing, style: TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _herdStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.pets,
            label: 'Total',
            value: '12',
            detail: '6 Cow • 4 Bu...',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_ind_outlined,
            label: 'Live',
            value: '01',
            detail: 'Vet Assigned',
            isRed: true,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber_outlined,
            label: '',
            value: '01',
            detail: 'Tag #HR-402',
            isRed: true,
          ),
        ),
      ],
    );
  }

  Widget _diseaseAlert(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.error,
            child: Icon(
              Icons.notifications_active_outlined,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'FMD Alert: Karnal Rural',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _Pill('8 km', color: Theme.of(context).colorScheme.surface),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Keep herd quarantined from common water bodies. Free Ring Vaccination camp scheduled this Thursday at Panchayat Bhawan.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _caseCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                'Under Review',
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('Case #JVS-9821', style: TextStyle(fontSize: 11)),
              ),
              Text('2 hours ago', style: TextStyle(fontSize: 10)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Mild Limp & Reduced Rumination (HR-402)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          SizedBox(height: 14),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Neha Sharma',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Government Field Vet • On Route',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.call,
                      size: 18,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lumpy Skin Booster Administered',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Case #JVS-8410 • Completed & Logged',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text('12 Nov', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _helplineCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                size: 27,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Immediate Advice?',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Toll-free 24/7 National Kisan Helpline',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connect phone calling to your app.'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  icon: Icon(Icons.call, size: 17),
                  label: FittedBox(child: Text('Call 1800-180-1551')),
                ),
              ),
              SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                icon: Icon(Icons.chat_outlined, size: 17),
                label: Text('Sahayak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final bool isRed;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRed
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Container(
      height: 105,
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              SizedBox(width: 5),
              if (label.isNotEmpty)
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final String tag;
  final String details;
  final String status;
  final String note;
  final IconData icon;
  final bool warning;

  const _AnimalCard({
    required this.tag,
    required this.details,
    required this.status,
    required this.note,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: warning
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(17),
                ),
              ),
            ),
            SizedBox(width: 10),
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.pets,
                color: Theme.of(context).colorScheme.primary,
                size: 27,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        _Pill(
                          status,
                          color: warning
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(details, style: TextStyle(fontSize: 10)),
                    SizedBox(height: 3),
                    Text(
                      note,
                      style: TextStyle(
                        color: warning
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 4, right: 10),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer,
                child: Icon(
                  icon,
                  size: 19,
                  color: warning
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PlaceholderPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                icon,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add_circle_outline),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

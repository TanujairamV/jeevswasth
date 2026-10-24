import 'package:flutter/material.dart';

import '../widgets/surveillance_navbar.dart';
import 'surveillance_alerts_page.dart';
import 'surveillance_map_page.dart';
import 'surveillance_overview_page.dart';
import 'surveillance_profile_page.dart';

class SurveillanceHome extends StatefulWidget {
  const SurveillanceHome({super.key});

  @override
  State<SurveillanceHome> createState() => _SurveillanceHomeState();
}

class _SurveillanceHomeState extends State<SurveillanceHome> {
  int _selectedTab = 0;

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final destinations = SurveillanceNavBar.destinations;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _selectedTab,
                onDestinationSelected: (index) =>
                    setState(() => _selectedTab = index),
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 20),
                  child: CircleAvatar(child: Icon(Icons.shield_outlined)),
                ),
                destinations: destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                    )
                    .toList(),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  SurveillanceOverviewPage(
                    onMessage: _message,
                    onViewFullMap: () => setState(() => _selectedTab = 1),
                  ),
                  SurveillanceMapPage(onMessage: _message),
                  SurveillanceAlertsPage(onMessage: _message),
                  SurveillanceProfilePage(onMessage: _message),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : SurveillanceNavBar(
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
            ),
    );
  }
}

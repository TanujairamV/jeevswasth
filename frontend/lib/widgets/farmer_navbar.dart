import 'package:flutter/material.dart';

class FarmerNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const FarmerNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Hub',
    ),
    NavigationDestination(
      icon: Icon(Icons.pets_outlined),
      selectedIcon: Icon(Icons.pets),
      label: 'Animals',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: 'Surveys',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_active_outlined),
      selectedIcon: Icon(Icons.notifications_active),
      label: 'Alerts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final navigationTheme = Theme.of(context).navigationBarTheme;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: navigationTheme.backgroundColor ?? colors.surface,
      indicatorColor:
          navigationTheme.indicatorColor ?? colors.secondaryContainer,
      elevation: navigationTheme.elevation ?? 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: destinations,
    );
  }
}
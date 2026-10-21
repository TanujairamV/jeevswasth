import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/livestock_survey_repository.dart';
import 'livestock_survey_page.dart';
import 'models/livestock_survey.dart';

class _LocationProblem implements Exception {
  const _LocationProblem(this.message);

  final String message;
}

class FieldWorkerHome extends StatefulWidget {
  const FieldWorkerHome({super.key});

  @override
  State<FieldWorkerHome> createState() => _FieldWorkerHomeState();
}

class _FieldWorkerHomeState extends State<FieldWorkerHome> {
  int selectedIndex = 1;
  Position? _position;
  String? _address;
  DateTime? _locationTimestamp;
  String _gpsStatus = 'Checking GPS…';
  bool _isRefreshingLocation = false;
  final _surveyRepository = LivestockSurveyRepository();
  List<LivestockSurvey> _surveys = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _refreshLocation();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    final surveys = await _surveyRepository.getAll();
    if (mounted) setState(() => _surveys = surveys);
  }

  Future<void> _openSurvey() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LivestockSurveyPage()),
    );
    if (saved == true) _loadSurveys();
  }

  Future<void> _loadSavedLocation() async {
    final preferences = await SharedPreferences.getInstance();
    final latitude = preferences.getDouble('field_worker_latitude');
    final longitude = preferences.getDouble('field_worker_longitude');
    if (!mounted || latitude == null || longitude == null) return;

    setState(() {
      _position = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          preferences.getInt('field_worker_location_timestamp') ?? 0,
        ),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        floor: null,
        isMocked: false,
      );
      _address = preferences.getString('field_worker_address');
      final timestamp = preferences.getInt('field_worker_location_timestamp');
      _locationTimestamp = timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
    });
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshingLocation) return;
    setState(() {
      _isRefreshingLocation = true;
      _gpsStatus = 'Locating…';
    });

    try {
      await _requestLocationPermission();
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationProblem('GPS is disabled on this device.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = [
            place.name,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        }
      } catch (_) {
        // Coordinates remain useful when the geocoder is offline/unavailable.
      }
      address ??= _coordinatesFor(position);

      final timestamp = DateTime.now();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble('field_worker_latitude', position.latitude);
      await preferences.setDouble('field_worker_longitude', position.longitude);
      await preferences.setString('field_worker_address', address);
      await preferences.setInt(
        'field_worker_location_timestamp',
        timestamp.millisecondsSinceEpoch,
      );

      if (!mounted) return;
      setState(() {
        _position = position;
        _address = address;
        _locationTimestamp = timestamp;
        _gpsStatus = 'GPS Active';
      });
    } on _LocationProblem catch (problem) {
      if (!mounted) return;
      setState(() => _gpsStatus = problem.message);
      showMessage(problem.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _gpsStatus = 'Unable to read GPS right now.');
      showMessage('Could not refresh location. Last saved location is shown.');
    } finally {
      if (mounted) setState(() => _isRefreshingLocation = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const _LocationProblem('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const _LocationProblem(
        'Location permission is blocked. Enable it in Settings.',
      );
    }
  }

  String _coordinatesFor(Position position) =>
      '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

  String _locationLabel() {
    if (_address != null && _address!.isNotEmpty) return _address!;
    if (_position != null) return _coordinatesFor(_position!);
    return 'Location unavailable';
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: [
            const Center(child: Text('Hub')),
            _dashboard(context),
            _surveysView(context),
            const Center(child: Text('Alerts')),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
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
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _dashboard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.health_and_safety,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JEEVSWASTH',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Livestock Registry',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => showMessage('No new notifications.'),
              icon: const Icon(Icons.notifications_none),
            ),
            InkWell(
              onTap: _refreshLocation,
              borderRadius: BorderRadius.circular(24),
              child: Tooltip(
                message: 'Open profile and check GPS permission',
                child: CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  child: Icon(Icons.person, color: colors.onSecondaryContainer),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '● MOBILE UNIT #3 • KARNAL',
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    'Suresh Verma',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('Today, 14 Nov 2024', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  avatar: _isRefreshingLocation
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _gpsStatus == 'GPS Active'
                              ? Icons.gps_fixed
                              : Icons.gps_off,
                          size: 16,
                        ),
                  label: Text(_gpsStatus),
                  backgroundColor: colors.secondaryContainer,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        _locationLabel(),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh location',
                      onPressed: _isRefreshingLocation
                          ? null
                          : _refreshLocation,
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ),
                if (_locationTimestamp != null)
                  Text(
                    'Updated ${_formatTime(_locationTimestamp!)}',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  child: Icon(Icons.sync, color: colors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode Ready',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '4 reports stored securely',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => showMessage('Reports synced.'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Sync Now'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Card(
          color: colors.primary,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY FIELD QUOTA',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.75),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '5 of 8 Farms Visited',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 routine visits & 1 outbreak verification left',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _quota(
                        context,
                        Icons.science_outlined,
                        '3 Samples',
                        'Cold chain safe',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quota(
                        context,
                        Icons.sell_outlined,
                        '12 Ear Tags',
                        'Registered',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'QUICK FIELD ACTION',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text('Tap to launch form', style: theme.textTheme.bodySmall),
          ],
        ),

        const SizedBox(height: 10),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _action(
              context,
              Icons.assignment_add,
              'Start Survey',
              'Checklist & Triage',
              _openSurvey,
            ),
            _action(
              context,
              Icons.camera_alt_outlined,
              'Photo Lesions',
              'AI Oral / Foot Check',
              () => showMessage('Camera feature coming soon.'),
            ),
            _action(
              context,
              Icons.colorize,
              'Sample Kit',
              'Vial Barcode Scan',
              () => showMessage('Sample kit feature coming soon.'),
            ),
            _action(
              context,
              Icons.qr_code_scanner,
              'Attach Tag',
              'RFID / INAPH ID',
              () => showMessage('Tag scanning coming soon.'),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'SCHEDULED FARM VISITS',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => showMessage('Route map coming soon.'),
              child: const Text('Route Map'),
            ),
          ],
        ),

        _visit(
          context,
          urgent: true,
          title: 'Ramesh Kumar Dairy Farm',
          time: '10:30 AM • Delayed',
          location: 'Bilaspur Village, North Ward • 1.2 km away',
          animal: 'Target: Buffalo #HR-402',
          status: 'Suspected FMD',
          description:
              'Inspect hyper-salivation and vesicular mouth lesions. '
              'Collect viral swab and chilled blood serum.',
          onPressed: () => showMessage('Inspection started.'),
        ),

        const SizedBox(height: 12),

        _visit(
          context,
          urgent: false,
          title: 'Anita Devi Smallholding',
          time: '01:00 PM • Scheduled',
          location: 'Kunjpura Hamlet • 4.8 km away',
          animal: '3 Indigenous Cows',
          status: 'Routine',
          description: 'Brucellosis sero-monitoring and ear tags.',
          onPressed: () => showMessage('Routine visit opened.'),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline, color: colors.primary),
            title: const Text(
              'Vikas Milk Producers',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Done & synced • 8 buffaloes checked, all healthy',
            ),
            trailing: IconButton(
              onPressed: () => showMessage('Dossier coming soon.'),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          color: colors.secondaryContainer,
          child: const ListTile(
            leading: Icon(Icons.health_and_safety_outlined),
            title: Text(
              'Biosecurity Protocol Reminder',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Use boot-dip disinfectant before entering the farm shed.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _surveysView(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => _loadSurveys(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: Text('Saved surveys', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
            FilledButton.icon(onPressed: _openSurvey, icon: const Icon(Icons.add), label: const Text('New')),
          ]),
          const SizedBox(height: 8),
          Text('Surveys remain available offline until they are synced.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (_surveys.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.assignment_outlined, size: 48, color: colors.primary), const SizedBox(height: 12), const Text('No saved surveys yet'), const SizedBox(height: 12), OutlinedButton(onPressed: _openSurvey, child: const Text('Start first survey'))])))
          else
            ..._surveys.map((survey) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: colors.primaryContainer, child: Icon(Icons.pets, color: colors.onPrimaryContainer)),
                    title: Text('${survey.species} • ${survey.animalCount} animals', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${survey.farmerName} • ${survey.village}\n${survey.createdAt.toLocal()}'),
                    isThreeLine: true,
                    trailing: Chip(avatar: Icon(survey.syncStatus == SurveySyncStatus.synced ? Icons.cloud_done : Icons.cloud_off, size: 16), label: Text(survey.syncStatus == SurveySyncStatus.synced ? 'Synced' : 'Pending')),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _quota(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primary,
                    child: Icon(icon, color: colors.onPrimary),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: colors.onSurfaceVariant),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: themeTextSmall(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? themeTextSmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;

  Widget _visit(
    BuildContext context, {
    required bool urgent,
    required String title,
    required String time,
    required String location,
    required String animal,
    required String status,
    required String description,
    required VoidCallback onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;
    final accent = urgent ? colors.error : colors.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          avatar: Icon(
                            urgent
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(
                            urgent
                                ? 'URGENT OUTBREAK ALERT'
                                : 'ROUTINE SURVEILLANCE',
                          ),
                        ),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: urgent
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 $location',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animal,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(status),
                            backgroundColor: urgent
                                ? colors.errorContainer
                                : colors.secondaryContainer,
                          ),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onPressed,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        label: Text(urgent ? 'Start Inspection' : 'Open Visit'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showMessage('Directions coming soon.'),
                        icon: const Icon(Icons.navigation_outlined),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        label: const Text('Directions'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

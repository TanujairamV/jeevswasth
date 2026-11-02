import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'surveillance_location_service.dart';

class SurveillanceRiskMap extends StatefulWidget {
  const SurveillanceRiskMap({super.key, this.height = 240, this.onMessage});

  final double height;
  final ValueChanged<String>? onMessage;

  @override
  State<SurveillanceRiskMap> createState() => _SurveillanceRiskMapState();
}

class _SurveillanceRiskMapState extends State<SurveillanceRiskMap> {
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _initialPosition = CameraPosition(target: LatLng(29.6857, 76.9905), zoom: 9.5);

  final _locationService = SurveillanceLocationService();
  MapLibreMapController? _controller;
  List<SurveillanceLocationCluster> _clusters = const [];
  String? _error;
  bool _loading = true;
  bool _usingDemoData = false;
  bool _styleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clusters = await _locationService.fetchClusters(since: DateTime.now().subtract(const Duration(days: 14)));
      if (!mounted) return;
      final hasLiveClusters = clusters.isNotEmpty;
      setState(() {
        _clusters = hasLiveClusters ? clusters : _demoClusters;
        _loading = false;
        _usingDemoData = !hasLiveClusters;
      });
      if (_styleLoaded) await _addMarkers();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _clusters = _demoClusters;
        _loading = false;
        _error = null;
        _usingDemoData = true;
      });
      if (_styleLoaded) await _addMarkers();
    }
  }

  Future<void> _addMarkers() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearCircles();
    for (final cluster in _clusters) {
      await controller.addCircle(
        CircleOptions(
          geometry: LatLng(cluster.position.latitude, cluster.position.longitude),
          circleColor: _markerColor(cluster.riskLevel),
          circleRadius: switch (cluster.riskLevel?.toLowerCase()) {
            'high' || 'critical' => 11,
            'elevated' || 'medium' => 9,
            _ => 7,
          },
          circleOpacity: .9,
          circleBlur: 0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
          circleStrokeOpacity: 1,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            MapLibreMap(
              styleString: _styleUrl,
              initialCameraPosition: _initialPosition,
              annotationOrder: const [AnnotationType.circle],
              compassEnabled: false,
              myLocationEnabled: false,
              rotateGesturesEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
              },
              onStyleLoadedCallback: () {
                _styleLoaded = true;
                _addMarkers();
              },
              onMapClick: (_, point) {
                final nearest = _nearestCluster(point);
                if (nearest != null) widget.onMessage?.call(_summary(nearest));
              },
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: Align(
                alignment: Alignment.topLeft,
                child: Card(
                  margin: EdgeInsets.zero,
                  color: _usingDemoData ? colors.tertiaryContainer : colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      _usingDemoData ? 'Demonstration data · connect API for live reports' : 'Live aggregated report data',
                      style: TextStyle(
                        color: _usingDemoData ? colors.onTertiaryContainer : colors.onPrimaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(child: _legend(colors)),
                  IconButton.filledTonal(
                    tooltip: 'Recenter map',
                    onPressed: () => _controller?.animateCamera(CameraUpdate.newCameraPosition(_initialPosition)),
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Positioned.fill(
                child: ColoredBox(
                  color: colors.surface.withValues(alpha: .9),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.location_off_outlined),
                        const SizedBox(height: 8),
                        const Text('Location data is unavailable.'),
                        const SizedBox(height: 4),
                        Text('Connect the surveillance report feed to load real markers.', textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                        TextButton(onPressed: _loadClusters, child: const Text('Retry')),
                      ]),
                    ),
                  ),
                ),
              ),
            if (!_loading && _error == null && _clusters.isEmpty)
              Positioned.fill(
                child: IgnorePointer(child: Center(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('No report clusters with valid coordinates'))))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(ColorScheme colors) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Wrap(
            spacing: 8,
            children: [
              _dot(colors.primary, 'Normal'),
              _dot(colors.tertiary, 'Elevated'),
              _dot(colors.error, 'High risk'),
            ],
          ),
        ),
      );

  Widget _dot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 8, color: color), const SizedBox(width: 3), Text(label, style: const TextStyle(fontSize: 10))]);

  String _markerColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'high':
      case 'critical':
        return '#BA1A1A';
      case 'elevated':
      case 'medium':
        return '#E65100';
      default:
        return '#2E7D32';
    }
  }

  SurveillanceLocationCluster? _nearestCluster(LatLng point) {
    if (_clusters.isEmpty) return null;
    return _clusters.reduce(
      (a, b) => _distanceToCluster(point, a) < _distanceToCluster(point, b) ? a : b,
    );
  }

  double _distanceToCluster(LatLng point, SurveillanceLocationCluster cluster) =>
      (point.latitude - cluster.position.latitude).abs() +
      (point.longitude - cluster.position.longitude).abs();

  String _summary(SurveillanceLocationCluster cluster) => '${cluster.clusterId}: ${cluster.reportCount} reports, ${cluster.affectedAnimals} animals. ${cluster.riskLevel == null ? 'Risk level not supplied by API.' : 'Risk: ${_riskLabel(cluster.riskLevel)}.'}';

  String _riskLabel(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'high':
      case 'critical':
        return 'High risk';
      case 'elevated':
      case 'medium':
        return 'Elevated';
      case 'normal':
      case 'low':
        return 'Normal';
      default:
        return 'Unclassified';
    }
  }

  static final List<SurveillanceLocationCluster> _demoClusters = [
    SurveillanceLocationCluster(
      clusterId: 'demo_bilaspur',
      position: const geo.LatLng(29.6857, 76.9905),
      reportCount: 8,
      affectedAnimals: 14,
      species: const ['cattle'],
      firstReportTimestamp: DateTime(2026, 10, 23, 9),
      lastReportTimestamp: DateTime(2026, 10, 24, 8),
      minimumReports: 5,
      riskLevel: 'high',
    ),
    SurveillanceLocationCluster(
      clusterId: 'demo_indri',
      position: const geo.LatLng(29.8795, 77.0598),
      reportCount: 6,
      affectedAnimals: 9,
      species: const ['cattle', 'buffalo'],
      firstReportTimestamp: DateTime(2026, 10, 22, 12),
      lastReportTimestamp: DateTime(2026, 10, 24, 7),
      minimumReports: 5,
      riskLevel: 'elevated',
    ),
    SurveillanceLocationCluster(
      clusterId: 'demo_assandh',
      position: const geo.LatLng(29.5224, 76.6033),
      reportCount: 5,
      affectedAnimals: 7,
      species: const ['goat'],
      firstReportTimestamp: DateTime(2026, 10, 23, 15),
      lastReportTimestamp: DateTime(2026, 10, 24, 6),
      minimumReports: 5,
      riskLevel: 'elevated',
    ),
    SurveillanceLocationCluster(
      clusterId: 'demo_gharaunda',
      position: const geo.LatLng(29.5361, 76.9714),
      reportCount: 5,
      affectedAnimals: 5,
      species: const ['goat', 'cattle'],
      firstReportTimestamp: DateTime(2026, 10, 23, 8),
      lastReportTimestamp: DateTime(2026, 10, 24, 5),
      minimumReports: 5,
      riskLevel: 'normal',
    ),
  ];
}

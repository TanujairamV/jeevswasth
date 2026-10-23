import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'data/livestock_survey_repository.dart';
import 'data/reports_api_client.dart';
import 'models/livestock_survey.dart';
import 'widgets/survey_field.dart';

enum _SubmissionState { idle, saving, submitting, submitted, failed }

class LivestockSurveyPage extends StatefulWidget {
  const LivestockSurveyPage({super.key});
  @override
  State<LivestockSurveyPage> createState() => _LivestockSurveyPageState();
}

class _LivestockSurveyPageState extends State<LivestockSurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _farmer = TextEditingController();
  final _phone = TextEditingController();
  final _village = TextEditingController();
  final _count = TextEditingController();
  final _notes = TextEditingController();
  final _repository = LivestockSurveyRepository();
  final _apiClient = ReportsApiClient();
  String _species = 'Cattle';
  final _symptoms = <String>{};
  final _signs = <String>{};
  Position? _position;
  _SubmissionState _submissionState = _SubmissionState.idle;
  LivestockSurvey? _draftSurvey;
  String? _reportId;
  String? _submissionError;

  static const _symptomOptions = ['Fever', 'Loss of appetite', 'Cough', 'Diarrhea', 'Lameness'];
  static const _signOptions = ['Nasal discharge', 'Oral lesions', 'Swelling', 'Dehydration', 'Abnormal breathing'];

  @override
  void dispose() {
    for (final controller in [_farmer, _phone, _village, _count, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _captureLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('Location permission is required.');
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Enable GPS to capture coordinates.');
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _position = position);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _save() async {
    if (_submissionState == _SubmissionState.saving || _submissionState == _SubmissionState.submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_symptoms.isEmpty && _signs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one symptom or clinical sign.')));
      return;
    }
    setState(() => _submissionState = _SubmissionState.saving);
    final survey = _draftSurvey ?? LivestockSurvey(
      id: DateTime.now().microsecondsSinceEpoch.toString(), species: _species,
      animalCount: int.parse(_count.text), farmerName: _farmer.text.trim(), farmerPhone: _phone.text.trim(),
      village: _village.text.trim(), location: _position == null ? null : SurveyLocation(latitude: _position!.latitude, longitude: _position!.longitude),
      symptoms: _symptoms.toList(), clinicalSigns: _signs.toList(), notes: _notes.text.trim(), createdAt: DateTime.now(), syncStatus: SurveySyncStatus.pending,
    );
    _draftSurvey = survey;
    await _repository.save(survey);
    if (!mounted) return;
    setState(() => _submissionState = _SubmissionState.submitting);
    try {
      final reportId = await _apiClient.submit(survey);
      await _repository.save(survey.copyWith(syncStatus: SurveySyncStatus.synced));
      if (!mounted) return;
      setState(() {
        _reportId = reportId;
        _submissionState = _SubmissionState.submitted;
        _submissionError = null;
      });
    } catch (error) {
      await _repository.save(survey.copyWith(syncStatus: SurveySyncStatus.failed));
      if (!mounted) return;
      setState(() {
        _submissionState = _SubmissionState.failed;
        _submissionError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _chips(String title, List<String> options, Set<String> selected) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, children: options.map((item) => FilterChip(label: Text(item), selected: selected.contains(item), onSelected: (value) => setState(() => value ? selected.add(item) : selected.remove(item)))).toList()),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Livestock health survey')),
        body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<String>(initialValue: _species, decoration: const InputDecoration(labelText: 'Animal species', border: OutlineInputBorder()), items: ['Cattle', 'Buffalo', 'Goat', 'Sheep', 'Poultry', 'Pig'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _species = value!)),
          const SizedBox(height: 12),
          SurveyField(controller: _count, label: 'Animal count', keyboardType: TextInputType.number), const SizedBox(height: 12),
          SurveyField(controller: _farmer, label: 'Farmer name'), const SizedBox(height: 12),
          SurveyField(controller: _phone, label: 'Farmer phone', keyboardType: TextInputType.phone), const SizedBox(height: 12),
          SurveyField(controller: _village, label: 'Village / location'), const SizedBox(height: 18),
          _chips('Symptoms', _symptomOptions, _symptoms), const SizedBox(height: 18),
          _chips('Clinical signs', _signOptions, _signs), const SizedBox(height: 12),
          SurveyField(controller: _notes, label: 'Notes', maxLines: 4), const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _captureLocation, icon: const Icon(Icons.gps_fixed), label: Text(_position == null ? 'Capture GPS coordinates' : '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}')),
          const SizedBox(height: 8), Text('Timestamp: ${MaterialLocalizations.of(context).formatFullDate(DateTime.now())}', style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 20),
          if (_submissionState == _SubmissionState.submitted)
            Card(child: ListTile(leading: const Icon(Icons.cloud_done), title: const Text('Submitted'), subtitle: Text('Report ID: $_reportId'))),
          if (_submissionState == _SubmissionState.failed)
            Card(child: ListTile(leading: const Icon(Icons.cloud_off), title: const Text('Submission Failed'), subtitle: Text(_submissionError ?? 'The survey remains saved locally.'), trailing: TextButton(onPressed: _save, child: const Text('Retry')))),
          FilledButton.icon(onPressed: _submissionState == _SubmissionState.saving || _submissionState == _SubmissionState.submitting ? null : _save, icon: const Icon(Icons.save), label: Text(_submissionState == _SubmissionState.saving ? 'Saving…' : _submissionState == _SubmissionState.submitting ? 'Submitting…' : _submissionState == _SubmissionState.submitted ? 'Submitted' : 'Save and submit')),
        ])),
      );
}

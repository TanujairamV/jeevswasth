import 'package:flutter/material.dart';
import 'data/reports_api_client.dart';

class ReportsHistoryPage extends StatefulWidget {
  const ReportsHistoryPage({super.key});
  @override
  State<ReportsHistoryPage> createState() => _ReportsHistoryPageState();
}

class _ReportsHistoryPageState extends State<ReportsHistoryPage> {
  final _client = ReportsApiClient();
  late Future<List<ApiReport>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = _client.mine();
  }

  void _retry() => setState(() => _reports = _client.mine());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My reports')),
        body: FutureBuilder<List<ApiReport>>(
          future: _reports,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Message(icon: Icons.cloud_off, text: snapshot.error.toString(), action: _retry);
            }
            final reports = snapshot.data ?? const <ApiReport>[];
            if (reports.isEmpty) return const _Message(icon: Icons.assignment_outlined, text: 'No submitted reports yet.');
            return RefreshIndicator(
              onRefresh: () async => _retry(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final report = reports[index];
                  final survey = report.survey;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text('${survey.species} · ${survey.animalCount} animals'),
                      subtitle: Text('${survey.village}\n${MaterialLocalizations.of(context).formatMediumDate(survey.createdAt.toLocal())} · ${report.reportId}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center), if (action != null) ...[const SizedBox(height: 16), FilledButton(onPressed: action, child: const Text('Retry'))]])));
}

import 'package:shared_preferences/shared_preferences.dart';
import '../models/livestock_survey.dart';

class LivestockSurveyRepository {
  static const _storageKey = 'farmer_livestock_health_reports';
  // Keep the legacy key as a one-way migration fallback so reports saved by
  // earlier builds remain available after reporting moved to the Farmer role.
  static const _legacyStorageKey = 'field_worker_livestock_surveys';

  Future<List<LivestockSurvey>> getAll() async {
    final preferences = await SharedPreferences.getInstance();
    final surveys = List<LivestockSurvey>.from(
      decodeSurveys(
        preferences.getString(_storageKey) ??
            preferences.getString(_legacyStorageKey),
      ),
    );
    surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return surveys;
  }

  Future<void> save(LivestockSurvey survey) async {
    final surveys = await getAll();
    surveys.removeWhere((item) => item.id == survey.id);
    surveys.insert(0, survey);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, encodeSurveys(surveys));
  }
}

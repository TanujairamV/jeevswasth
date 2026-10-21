import 'package:shared_preferences/shared_preferences.dart';
import '../models/livestock_survey.dart';

class LivestockSurveyRepository {
  static const _storageKey = 'field_worker_livestock_surveys';

  Future<List<LivestockSurvey>> getAll() async {
    final preferences = await SharedPreferences.getInstance();
    final surveys = List<LivestockSurvey>.from(
      decodeSurveys(preferences.getString(_storageKey)),
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

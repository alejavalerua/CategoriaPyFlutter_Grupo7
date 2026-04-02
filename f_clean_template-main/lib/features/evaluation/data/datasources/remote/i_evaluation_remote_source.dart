abstract class IEvaluationRemoteSource {
  Future<void> createActivity(String categoryId, String name, String description, DateTime startDate, DateTime endDate, bool visibility);
  Future<List<dynamic>> getActivitiesByCategory(String categoryId);
} 
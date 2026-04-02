import 'package:peer_sync/features/evaluation/domain/models/activity.dart';

import '../../domain/repositories/i_evaluation_repository.dart';
import '../datasources/remote/i_evaluation_remote_source.dart';

class EvaluationRepositoryImpl implements IEvaluationRepository {
  final IEvaluationRemoteSource _remoteSource;

  // Inyectamos el Data Source
  EvaluationRepositoryImpl(this._remoteSource);

  @override
  Future<void> createActivity({
    required String categoryId,
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required bool visibility,
  }) async {
    // Llamamos al método que se conecta a la API de ROBLE
    await _remoteSource.createActivity(
      categoryId,
      name,
      description,
      startDate,
      endDate,
      visibility,
    );
  }
  
  @override
  Future<List<Activity>> getActivitiesByCategory(String categoryId) async {
    final rawData = await _remoteSource.getActivitiesByCategory(categoryId);
    
    // Mapeamos la lista de JSONs a una lista de objetos Activity puros
    return rawData.map((json) {
      return Activity(
        id: json['_id'].toString(),
        categoryId: json['category_id'].toString(),
        name: json['name'].toString(),
        description: json['description']?.toString(),
        // Parseamos el string ISO-8601 a DateTime y lo pasamos a la hora local del celular
        startDate: DateTime.parse(json['start_date'].toString()).toLocal(),
        endDate: DateTime.parse(json['end_date'].toString()).toLocal(),
        // Si visibility viene nulo, asumimos que es falso
        visibility: json['visibility'] ?? false, 
      );
    }).toList();
  }
  
}
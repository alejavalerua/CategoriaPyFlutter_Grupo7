import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/repositories/i_evaluation_repository.dart';
import '../../domain/models/peer.dart';
import '../../domain/models/criteria.dart';
import '../../../auth/ui/viewmodels/auth_controller.dart';

class EvaluationFormController extends GetxController {
  final IEvaluationRepository repository;
  final AuthController authController = Get.find();

  final isLoading = false.obs;
  final isSubmitting = false.obs;

  final peers = <Peer>[].obs;
  final criteriaList = <Criteria>[].obs;

  // Mapa para almacenar las notas temporales que el usuario le da a cada compañero
  // Formato: { "email_del_compañero": { "Puntualidad": 4.5, "Actitud": 5.0 } }
  final pendingEvaluations = <String, Map<String, double>>{}.obs;
  final completedEvaluations = <String, Map<String, double>>{}.obs;

  final myAverageResults = <String, double>{}.obs;

  EvaluationFormController(this.repository);

  // Saber quién soy yo
  String get myEmail => authController.user?.email ?? '';

  Future<void> loadFormData(String activityId, String categoryId) async {
    try {
      isLoading.value = true;

      final results = await Future.wait<dynamic>([
        repository.getPeers(categoryId, myEmail),
        repository.getCriteria(activityId),
        repository.getMyEvaluations(activityId, myEmail), 
        repository.getMyAverageResults(activityId, myEmail),
      ]);

      peers.assignAll(results[0] as List<Peer>);
      criteriaList.assignAll(results[1] as List<Criteria>);
      completedEvaluations.value = results[2] as Map<String, Map<String, double>>;

      myAverageResults.value = results[3] as Map<String, double>;
    } catch (e) {
      _showError('No se pudieron cargar los datos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Se llama cada vez que el slider de EditablePeerEvaluationCard cambia
  void updateScoreForPeer(String peerEmail, Map<String, double?> newScores) {
    if (!pendingEvaluations.containsKey(peerEmail)) {
      pendingEvaluations[peerEmail] = {};
    }

    newScores.forEach((key, value) {
      if (value != null) {
        // Mapeamos las llaves del widget de tu compañera a nombres legibles
        String criteriaName = '';
        if (key == 'puntualidad') criteriaName = 'Puntualidad';
        if (key == 'contribucion') criteriaName = 'Contribución';
        if (key == 'compromiso') criteriaName = 'Compromiso';
        if (key == 'actitud') criteriaName = 'Actitud';

        if (criteriaName.isNotEmpty) {
          pendingEvaluations[peerEmail]![criteriaName] = value;
        }
      }
    });
  }

  // Enviar la evaluación de un compañero específico a ROBLE
  Future<void> submitEvaluationForPeer(
    String activityId,
    String categoryId,
    String evaluatedEmail,
  ) async {
    final scoresToSubmit = pendingEvaluations[evaluatedEmail];

    if (scoresToSubmit == null || scoresToSubmit.length < 4) {
      _showError('Por favor, califica todos los criterios antes de guardar.');
      return;
    }

    try {
      isSubmitting.value = true;

      // Transformamos los nombres legibles a los ID reales de la tabla Criteria (Ignorando tildes y mayúsculas)
      Map<String, double> dbScores = {};

      scoresToSubmit.forEach((uiName, score) {
        // Normalizamos los textos (minúsculas y sin tildes) para evitar errores tipográficos de BD
        final normalizedUiName = uiName.toLowerCase().replaceAll('ó', 'o');

        final matchedCriteria = criteriaList.firstWhereOrNull((c) {
          final normalizedDbName = c.name.toLowerCase().replaceAll('ó', 'o');
          return normalizedDbName == normalizedUiName;
        });

        if (matchedCriteria != null) {
          dbScores[matchedCriteria.id] = score;
        } else {
          print(
            "🔴 ALERTA: No se encontró el criterio '$uiName' en la base de datos.",
          );
        }
      });

      // SEGURO DE VIDA: Si no se logró hacer match con la base de datos, abortamos.
      if (dbScores.isEmpty) {
        _showError(
          'Error interno: Los criterios de la app no coinciden con los de la Base de Datos.',
        );
        return;
      }

      await repository.submitEvaluation(
        activityId,
        categoryId,
        myEmail,
        evaluatedEmail,
        "",
        dbScores,
      );

      _showSuccess('Evaluación guardada exitosamente.');
      pendingEvaluations.remove(evaluatedEmail);

      // Recargamos el historial para que la UI se actualice y bloquee la tarjeta
      final updatedEvaluations = await (repository as dynamic).getMyEvaluations(
        activityId,
        myEmail,
      );
      completedEvaluations.value = updatedEvaluations;
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  // Helpers para mostrar mensajes nativos con ScaffoldMessenger
  void _showError(String message) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showSuccess(String message) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
}

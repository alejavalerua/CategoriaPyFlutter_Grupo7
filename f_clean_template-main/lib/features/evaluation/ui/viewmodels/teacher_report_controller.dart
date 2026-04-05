import 'package:get/get.dart';
import '../../domain/repositories/i_evaluation_repository.dart';
import '../../domain/models/activity_report.dart';

class TeacherReportController extends GetxController {
  final IEvaluationRepository repository;

  final isLoading = false.obs;
  final groupReports = <GroupReport>[].obs;

  TeacherReportController(this.repository);

  Future<void> loadReport(String activityId, String categoryId) async {
    try {
      isLoading.value = true;
      final result = await repository.getActivityReport(activityId, categoryId);
      groupReports.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el reporte: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
import 'dart:convert'; // Para utf8.decode
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:peer_sync/core/themes/app_theme.dart';
import 'package:peer_sync/core/widgets/category_card.dart';
import 'package:peer_sync/core/widgets/create_category_modal.dart';
// Asegúrate de importar tu controlador de grupos
import 'package:peer_sync/features/groups/ui/viewmodels/groups_controller.dart'; 

class CourseDetailPage extends StatelessWidget {
  // ¡NUEVO! Agregamos courseId para pasárselo a ROBLE
  final String courseId; 
  final String courseTitle;
  final List<Map<String, dynamic>> categories;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.categories,
  });

  void openCreateCategoryModal(BuildContext context) {
    // Obtenemos el controlador de grupos
    final groupsController = Get.find<GroupsController>();

    // Usamos Get.dialog en lugar del showDialog nativo
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          // ¡QUITAMOS EL OBX AQUÍ! Ya no es necesario.
          child: CreateGroupCategoryModal(
            onCancel: () {
              // Sigue funcionando perfecto porque lee el valor al momento de hacer clic
              if (!groupsController.isLoading.value) {
                Get.back(); // Navegación GetX
              }
            },
            onCreate: () {
              print("Categoría manual creada");
              Get.back();
            },
            onCsvSelected: (file) async {
              if (file != null && file.bytes != null) {
                // 1. Decodificamos el archivo a Texto
                final csvString = utf8.decode(file.bytes!);
                
                // 2. Cerramos el modal
                Get.back(); 
                print("Archivo CSV seleccionado, procesando... $csvString , courseId: $courseId");
                // 3. Mandamos el texto a ROBLE
                await groupsController.importCsvData(courseId, csvString);
              } else {
                Get.snackbar('Error', 'No se pudo leer el archivo seleccionado', backgroundColor: Colors.redAccent, colorText: Colors.white);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el controlador para mostrar un loader general si está subiendo el CSV
    final groupsController = Get.find<GroupsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      floatingActionButton: Obx(() => groupsController.isLoading.value 
        ? const CircularProgressIndicator() // Si está cargando, mostramos un círculo
        : FloatingActionButton(
            onPressed: () {
              openCreateCategoryModal(context);
            },
            backgroundColor: AppTheme.secondaryColor,
            child: const Icon(Icons.add),
          )
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        title: Text(
          courseTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: Text(
              "Categorias de Grupos",
              style: AppTheme.bodyM.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor300,
              ),
            ),
          ),

          const SizedBox(height: 20),

          ...categories.map((item) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ProjectCategoryCard(
                    title: item["title"],
                    subtitle: item["subtitle"],
                    leadingIcon: item["icon"],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
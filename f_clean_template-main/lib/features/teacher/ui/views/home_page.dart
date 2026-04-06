import 'package:flutter/material.dart';
import 'package:peer_sync/core/utils/loading_overlay.dart';
import 'dart:convert';
import 'package:peer_sync/core/widgets/navbar.dart';
import 'package:peer_sync/core/themes/app_theme.dart';
import 'package:peer_sync/core/widgets/create_course_modal.dart';
import 'package:peer_sync/features/groups/ui/viewmodels/groups_controller.dart';
import 'teacher_home_page.dart';
import 'teacher_courses_page.dart';
import 'teacher_profile_page.dart';
import 'package:get/get.dart';
import 'package:peer_sync/features/course/ui/viewmodels/course_controller.dart';

class HomePageTe extends StatefulWidget {
  const HomePageTe({super.key});

  @override
  State<HomePageTe> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageTe> {
  int currentIndex = 1;

  final List<Widget> pages = const [
    TeacherCoursesPage(),
    TeacherHomePage(),
    TeacherProfilePage(),
    
  ];

  void openCreateCourseModal() {
    final TextEditingController nameController = TextEditingController();
    dynamic selectedCsvFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CreateCourseModal(
              nameController: nameController,
              onCancel: () {
                Navigator.pop(context);
              },
              onCreate: () async {
                final coursecontroller = Get.find<CourseController>();
                final groupsController = Get.find<GroupsController>();

                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("El nombre del curso es obligatorio"),
                    ),
                  );
                  return;
                }
                LoadingOverlay.show("Configurando curso y procesando estudiantes...");

                try {
                  // 2. Crear el curso
                  final newCourseId = await coursecontroller.createCourse(name);

                  // 3. Si se creó bien, procedemos con el CSV
                  if (newCourseId != null) {
                    if (selectedCsvFile != null && selectedCsvFile!.bytes != null) {
                      final csvString = utf8.decode(selectedCsvFile!.bytes!);
                      await groupsController.importCsvData(newCourseId, csvString);
                    }

                    // 4. Todo terminó. Cerramos la pantalla de carga (el círculo giratorio)
                    LoadingOverlay.hide(); 
                    
                    // 5. Cerramos el modal original donde se puso el nombre del curso
                    Navigator.pop(context); 
                  } else {
                    // Si falló la creación del curso, cerramos el círculo de carga 
                    // pero dejamos el modal abierto por si el profe quiere corregir el nombre
                    LoadingOverlay.hide();
                  }
                } catch (e) {
                  // Si algo estalla, nos aseguramos de cerrar el círculo de carga
                  LoadingOverlay.hide();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Ocurrió un error inesperado: $e"), backgroundColor: Colors.red),
                  );
                }
              },
              onCsvSelected: (file) {
                selectedCsvFile = file;
                print("CSV seleccionado: ${file?.name}");
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              onPressed: openCreateCourseModal,
              backgroundColor: AppTheme.secondaryColor,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}

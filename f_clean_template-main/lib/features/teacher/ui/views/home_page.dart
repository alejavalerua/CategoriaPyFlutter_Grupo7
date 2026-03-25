import 'package:flutter/material.dart';
import 'package:peer_sync/core/widgets/navbar.dart';
import 'package:peer_sync/core/themes/app_theme.dart';
import 'package:peer_sync/core/widgets/create_course_modal.dart';
import 'teacher_home_page.dart';
import 'teacher_courses_page.dart';
import 'teacher_profile_page.dart';

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
              onCreate: () {
                print("Nombre del curso: ${nameController.text}");
                Navigator.pop(context);
              },
              onCsvSelected: (file) {
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

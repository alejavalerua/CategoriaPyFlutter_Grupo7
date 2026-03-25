import 'package:flutter/material.dart';
import 'package:peer_sync/core/themes/app_theme.dart';
import 'package:peer_sync/core/widgets/course_card.dart';
import 'teacher_category_page.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  void openNotifications() {
    print("Abrir notificaciones");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 40, left: 25, right: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        "Cursos",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      size: 28,
                      color: Color(0xFF110E47),
                    ),
                    onPressed: openNotifications,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 CARD DE CURSO
            Column(
              children: [
                CourseCard(
                  title: "Programación Móvil",
                  progressText: "3 de 5 actividades",
                  progress: 0.6,
                  leadingIcon: Icons.phone_android,
                  projects: const [
                    CourseProjectItem(
                      title: "Proyecto CPU",
                      subtitle: "Entrega en 2 días",
                    ),
                    CourseProjectItem(
                      title: "Proyecto CPU 2",
                      subtitle: "En progreso",
                    ),
                    CourseProjectItem(
                      title: "Proyecto CPU 3",
                      subtitle: "Pendiente",
                    ),
                  ],
                  
                  onTap: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailPage(
                          courseTitle: "Programación Móvil",
                          categories: [
                            {
                              "title": "Proyecto CPU",
                              "subtitle": "3 integrantes • 0/3 done",
                              "icon": Icons.download,
                            },
                            {
                              "title": "Proyecto CPU 2",
                              "subtitle": "3 integrantes • 0/3 done",
                              "icon": Icons.download,
                            },
                            {
                              "title": "Proyecto CPU 3",
                              "subtitle": "3 integrantes • 0/3 done",
                              "icon": Icons.download,
                            },
                            {
                              "title": "Proyecto CPU 4",
                              "subtitle": "3 integrantes • 0/3 done",
                              "icon": Icons.download,
                            },
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

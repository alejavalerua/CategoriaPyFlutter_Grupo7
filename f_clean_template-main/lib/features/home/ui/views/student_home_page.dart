import 'package:flutter/material.dart';
import 'package:peer_sync/core/widgets/graph.dart';
import 'package:peer_sync/core/widgets/curses_home.dart';
import 'package:peer_sync/core/widgets/activities_home.dart';
import 'package:peer_sync/core/themes/app_theme.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  void openNotifications() {
    print("Abrir notificaciones");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Home",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text(
                      "Contenido Reciente",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondaryColor,
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

            const SizedBox(height: 20),

            EvaluationCard(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cursos Agregados",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAF95DE),
                  ),
                ),

                Text(
                  "View All",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBF94FF),
                  ),
                ),
              ],
            ),

            CoursesSection(),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Actividades Agregadas",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAF95DE),
                  ),
                ),

                Text(
                  "View All",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBF94FF),
                  ),
                ),
              ],
            ),

            ActivitiesSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:peer_sync/core/themes/app_theme.dart';
import 'package:peer_sync/core/widgets/navbar.dart';
import 'package:peer_sync/features/category/ui/bindings/category_binding.dart';
import 'package:peer_sync/features/category/ui/viewmodels/category_controller.dart';
import 'package:peer_sync/features/course/ui/bindings/course_binding.dart';
import 'package:peer_sync/features/course/ui/viewmodels/course_controller.dart';
import 'package:peer_sync/features/evaluation/ui/views/student_evaluation_page.dart';
import 'package:peer_sync/features/student/ui/views/student_courses_page.dart';
import 'package:peer_sync/features/student/ui/views/student_home_page.dart';
import 'package:peer_sync/features/student/ui/views/student_profile_page.dart';
import '../viewmodels/evaluation_controller.dart';

class StudentActivitiesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const StudentActivitiesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<StudentActivitiesPage> createState() => _StudentActivitiesPageState();
}

class _StudentActivitiesPageState extends State<StudentActivitiesPage> {
  final EvaluationController controller = Get.find<EvaluationController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadActivities(widget.categoryId);
    });
  }

  void _ensureStudentCourseDependencies() {
    if (!Get.isRegistered<dynamic>(tag: 'student_courses_binding_marker')) {
      CourseBinding().dependencies();
      CategoryBinding().dependencies();
      Get.put<Object>(Object(), tag: 'student_courses_binding_marker');
    } else {
      if (!Get.isRegistered<CourseController>()) {
        CourseBinding().dependencies();
      }
      if (!Get.isRegistered<CategoryController>()) {
        CategoryBinding().dependencies();
      }
    }
  }

  void _handleNavTap(int index) {
    _ensureStudentCourseDependencies();

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const _StudentCoursesShell()),
        (route) => false,
      );
      return;
    }

    if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const _StudentHomeShell()),
        (route) => false,
      );
      return;
    }

    if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const _StudentProfileShell()),
        (route) => false,
      );
      return;
    }
  }

  int _activityPriority(dynamic activity) {
    final now = DateTime.now();
    final isExpired = now.isAfter(activity.endDate);
    final isPending = now.isBefore(activity.startDate);
    final isActive = !isExpired && !isPending;

    if (isActive) return 0;
    if (isPending) return 1;
    return 2;
  }

  List<dynamic> _sortedActivities(List<dynamic> activities) {
    final sorted = [...activities];

    sorted.sort((a, b) {
      final priorityA = _activityPriority(a);
      final priorityB = _activityPriority(b);

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // Activas: la que vence más temprano primero
      if (priorityA == 0) {
        return a.endDate.compareTo(b.endDate);
      }

      // Próximamente: la que empieza más pronto primero
      if (priorityA == 1) {
        return a.startDate.compareTo(b.startDate);
      }

      // Vencidas: la más recientemente vencida primero
      return b.endDate.compareTo(a.endDate);
    });

    return sorted;
  }

  ({String label, String detail}) _buildStatusParts({
    required bool isExpired,
    required bool isPending,
    required String dayStr,
    required String endMonth,
    required String endTimeStr,
    required String startDay,
    required String startMonth,
    required String startTimeStr,
  }) {
    if (isExpired) {
      return (
        label: 'Vencida',
        detail: '• Cierre: $dayStr $endMonth $endTimeStr',
      );
    }

    if (isPending) {
      return (
        label: 'Próximamente',
        detail: '• Abre: $startDay $startMonth $startTimeStr',
      );
    }

    return (
      label: 'Pendiente',
      detail: '• Cierre: $dayStr $endMonth $endTimeStr',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        title: Text(
          'Actividades: ${widget.categoryName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingActivities.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activities.isEmpty) {
          return const Center(child: Text('No hay actividades disponibles.'));
        }

        final sortedActivities = _sortedActivities(controller.activities);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedActivities.length,
          itemBuilder: (context, index) {
            final activity = sortedActivities[index];
            final now = DateTime.now();

            final isExpired = now.isAfter(activity.endDate);
            final isPending = now.isBefore(activity.startDate);
            final isActive = !isExpired && !isPending;

            const monthNames = [
              'ENE',
              'FEB',
              'MAR',
              'ABR',
              'MAY',
              'JUN',
              'JUL',
              'AGO',
              'SEP',
              'OCT',
              'NOV',
              'DIC',
            ];

            final monthStr = monthNames[activity.endDate.month - 1];
            final dayStr = activity.endDate.day.toString();

            final endMonth = monthNames[activity.endDate.month - 1];
            final endHour = activity.endDate.hour > 12
                ? activity.endDate.hour - 12
                : (activity.endDate.hour == 0 ? 12 : activity.endDate.hour);
            final endAmPm = activity.endDate.hour >= 12 ? 'PM' : 'AM';
            final endMinute = activity.endDate.minute.toString().padLeft(
              2,
              '0',
            );
            final endTimeStr = "$endHour:$endMinute $endAmPm";

            final startMonth = monthNames[activity.startDate.month - 1];
            final startDay = activity.startDate.day.toString();
            final startHour = activity.startDate.hour > 12
                ? activity.startDate.hour - 12
                : (activity.startDate.hour == 0 ? 12 : activity.startDate.hour);
            final startAmPm = activity.startDate.hour >= 12 ? 'PM' : 'AM';
            final startMinute = activity.startDate.minute.toString().padLeft(
              2,
              '0',
            );
            final startTimeStr = "$startHour:$startMinute $startAmPm";

            final statusParts = _buildStatusParts(
              isExpired: isExpired,
              isPending: isPending,
              dayStr: dayStr,
              endMonth: endMonth,
              endTimeStr: endTimeStr,
              startDay: startDay,
              startMonth: startMonth,
              startTimeStr: startTimeStr,
            );

            final dateBgColor = isExpired
                ? Colors.grey[200]!
                : const Color(0xFFE5DBF5);
            final dateTextColor = isExpired
                ? Colors.grey[600]!
                : const Color(0xFF8761BE);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ActivityStatusCard(
                title: activity.name,
                month: monthStr,
                day: dayStr,
                statusTag: statusParts.label,
                statusDetail: statusParts.detail,
                dateBgColor: dateBgColor,
                dateTextColor: dateTextColor,
                onTap: () {
                  if (isActive || isExpired) {
                    Get.to(
                      () => StudentEvaluationPage(
                        activityId: activity.id,
                        activityName: activity.name,
                        categoryId: widget.categoryId,
                        isExpired: isExpired,
                      ),
                    );
                  } else {
                    Get.snackbar(
                      'Paciencia',
                      'Esta actividad aún no comienza.',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
            );
          },
        );
      }),
      bottomNavigationBar: NavBar(currentIndex: 0, onTap: _handleNavTap),
    );
  }
}

class _ActivityStatusCard extends StatelessWidget {
  final String title;
  final String month;
  final String day;
  final String statusTag;
  final String statusDetail;
  final Color dateBgColor;
  final Color dateTextColor;
  final VoidCallback onTap;

  const _ActivityStatusCard({
    required this.title,
    required this.month,
    required this.day,
    required this.statusTag,
    required this.statusDetail,
    required this.dateBgColor,
    required this.dateTextColor,
    required this.onTap,
  });

  ({Color background, Color text, Color border}) _tagColors(String value) {
    final normalized = value.toLowerCase().trim();

    if (normalized.contains('pendiente')) {
      return (
        background: const Color(0xFFF3EDFF),
        text: const Color(0xFF7F56D9),
        border: const Color(0xFFE4D7FF),
      );
    }

    if (normalized.contains('próximamente') ||
        normalized.contains('proximamente')) {
      return (
        background: const Color(0xFFEAF2FF),
        text: const Color(0xFF3B82F6),
        border: const Color(0xFFD7E5FF),
      );
    }

    if (normalized.contains('vencida')) {
      return (
        background: const Color(0xFFF3F4F6),
        text: const Color(0xFF6B7280),
        border: const Color(0xFFE5E7EB),
      );
    }

    return (
      background: const Color(0xFFF3F4F6),
      text: const Color(0xFF667085),
      border: const Color(0xFFE5E7EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagStyle = _tagColors(statusTag);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: dateBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      month,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: dateTextColor,
                      ),
                    ),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: dateTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyL.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagStyle.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: tagStyle.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusTag,
                            style: AppTheme.bodyS.copyWith(
                              color: tagStyle.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              height: 1,
                            ),
                          ),
                        ),
                        Text(
                          statusDetail,
                          style: AppTheme.bodyS.copyWith(
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCoursesShell extends StatelessWidget {
  const _StudentCoursesShell();

  void _ensureBindings() {
    if (!Get.isRegistered<dynamic>(tag: 'student_courses_binding_marker')) {
      CourseBinding().dependencies();
      CategoryBinding().dependencies();
      Get.put<Object>(Object(), tag: 'student_courses_binding_marker');
    } else {
      if (!Get.isRegistered<CourseController>()) {
        CourseBinding().dependencies();
      }
      if (!Get.isRegistered<CategoryController>()) {
        CategoryBinding().dependencies();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureBindings();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const StudentCoursesPage(),
      bottomNavigationBar: NavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const _StudentHomeShell()),
              (route) => false,
            );
          }
          if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const _StudentProfileShell()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

class _StudentHomeShell extends StatelessWidget {
  const _StudentHomeShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const StudentHomePage(),
      bottomNavigationBar: NavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const _StudentCoursesShell()),
              (route) => false,
            );
          }
          if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const _StudentProfileShell()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

class _StudentProfileShell extends StatelessWidget {
  const _StudentProfileShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const StudentProfilePage(),
      bottomNavigationBar: NavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const _StudentCoursesShell()),
              (route) => false,
            );
          }
          if (index == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const _StudentHomeShell()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

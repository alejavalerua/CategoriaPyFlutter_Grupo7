import 'package:flutter/material.dart';
import 'package:peer_sync/core/themes/app_theme.dart';

class SettingsCardItem {
  final String title;
  final VoidCallback? onTap;

  const SettingsCardItem({required this.title, this.onTap});
}

class SettingsCard extends StatelessWidget {
  final List<SettingsCardItem> items;
  final double width;

  const SettingsCard({
    super.key,
    this.width = 330,
    this.items = const [
      SettingsCardItem(title: 'Notificaciones'),
      SettingsCardItem(title: 'Privacidad y seguridad'),
      SettingsCardItem(title: 'Cerrar sesión'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsRow(title: item.title, onTap: item.onTap),
              if (index != items.length - 1) const _SettingsDivider(),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SettingsRow({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyM.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.grayColor100, width: 1),
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
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB));
  }
}

import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  // 1. Definimos las variables que el widget necesita recibir
  final String title;
  final String month;
  final String day;
  final String statusText;
  final Color dateBgColor;
  final Color dateTextColor;
  final VoidCallback onTap;

  const ActivityCard({
    Key? key,
    required this.title,
    required this.month,
    required this.day,
    required this.statusText,
    required this.dateBgColor,
    required this.dateTextColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. Envolvemos su contenedor original en un GestureDetector para el tap
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Quitamos el width fijo (width: 327) para que se adapte al ancho de la pantalla
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            /// FECHA (Diseño original de tu compañera, pero con variables)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: dateBgColor, // Color dinámico
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    month, // Mes dinámico
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: dateTextColor, // Color dinámico
                    ),
                  ),
                  Text(
                    day, // Día dinámico
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: dateTextColor, // Color dinámico
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            /// TEXTO (Diseño original de tu compañera)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, // Título dinámico
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText, // Estado dinámico
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),

            /// BOTON (Diseño original)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
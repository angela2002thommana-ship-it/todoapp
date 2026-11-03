
import 'package:flutter/material.dart';


InputDecoration inputDecoration(
  String text,
  IconData icon,
) {
  return InputDecoration(
    labelText: text,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.82),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

Widget sectionTitle(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 236, 233, 243),
        ),
      ),
    ),
  );
}

Widget optionCard(
  String text,
  IconData icon,
  bool selected,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      decoration: BoxDecoration(
        color: selected
            ? const Color.fromARGB(255, 240, 237, 241).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? const Color.fromARGB(255, 242, 238, 243)
              : Colors.white.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,size: 20,
            color: selected
                ? const Color.fromARGB(255, 87, 30, 241)
                : const Color.fromARGB(255, 65, 115, 223),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: const TextStyle(fontSize: 20,
                  color: Color.fromARGB(255, 56, 104, 236),fontWeight:FontWeight(2)),
                ),
              ),
            ),
          
        ],
      ),
    ),
  );
}

Widget infoCard(
  String title,
  String value,
) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.65),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color.fromARGB(255, 27, 1, 100),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF3B3355),
          ),
        ),
      ],
    ),
  );
}

Widget statCard(
  String title,
  String value,
  IconData icon, {
  Color backgroundColor = const Color.fromARGB(117, 255, 255, 255),
  Color textColor = const Color(0xFF3B3355),
  Color iconColor = const Color.fromARGB(255, 58, 127, 216),
}) {
  final cardColor = backgroundColor == const Color.fromARGB(71, 255, 255, 255)
      ? const Color.fromARGB(3, 255, 255, 255).withValues(alpha: 0.78)
      : backgroundColor.withValues(alpha: 0.88);

  return Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color.fromARGB(97, 255, 255, 255).withValues(alpha: 0.65),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Icon(
                icon,
                size: 27,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget tag(
  String text,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

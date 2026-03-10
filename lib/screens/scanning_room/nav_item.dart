import 'package:flutter/material.dart';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';


class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const NavItem(
      {super.key, required this.icon,
        required this.label,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? kCyan : Colors.white24, size: 24),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: selected ? kCyan : Colors.white24,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal)),
      ]),
    );
  }
}
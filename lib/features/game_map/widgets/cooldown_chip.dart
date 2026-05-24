import 'package:flutter/material.dart';

class CooldownChip extends StatelessWidget {
  const CooldownChip({
    required this.label,
    required this.seconds,
    super.key,
  });

  final String label;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        seconds > 0 ? '$label ${seconds}s' : label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

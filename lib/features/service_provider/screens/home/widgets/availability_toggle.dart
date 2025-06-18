import 'package:flutter/material.dart';

class AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onToggle;

  const AvailabilityToggle({
    Key? key,
    required this.isAvailable,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAvailable
            ? (Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF1E3A38)
                : Color(0xFFE6F7F5))
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isAvailable ? Color(0xFF2A9D8F) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                isAvailable
                    ? 'You are available for work'
                    : 'You are unavailable',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isAvailable
                      ? Color(0xFF2A9D8F)
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700],
                ),
              ),
            ],
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) => onToggle(),
            activeColor: Color(0xFF2A9D8F),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  final Function(String) onCategoryTap;

  const CategoriesSection({
    Key? key,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryItem(
                icon: Icons.bolt,
                label: 'Electrical',
                color: Colors.blue,
                onTap: () => onCategoryTap('Electrical'),
              ),
              CategoryItem(
                icon: Icons.plumbing,
                label: 'Plumbing',
                color: Colors.green,
                onTap: () => onCategoryTap('Plumbing'),
              ),
              CategoryItem(
                icon: Icons.cleaning_services,
                label: 'Cleaning',
                color: Colors.purple,
                onTap: () => onCategoryTap('Cleaning'),
              ),
              CategoryItem(
                icon: Icons.format_paint,
                label: 'Painting',
                color: Colors.orange,
                onTap: () => onCategoryTap('Painting'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryItem(
                icon: Icons.handyman,
                label: 'Carpentry',
                color: Colors.brown,
                onTap: () => onCategoryTap('Carpentry'),
              ),
              CategoryItem(
                icon: Icons.grass,
                label: 'Gardening',
                color: Colors.lightGreen,
                onTap: () => onCategoryTap('Gardening'),
              ),
              CategoryItem(
                icon: Icons.local_shipping,
                label: 'Moving',
                color: Colors.deepOrange,
                onTap: () => onCategoryTap('Moving'),
              ),
              CategoryItem(
                icon: Icons.build,
                label: 'Appliance\nRepair',
                color: Colors.red,
                onTap: () => onCategoryTap('Appliance Repair'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryItem(
                icon: Icons.computer,
                label: 'Computer\nRepair',
                color: Colors.cyan,
                onTap: () => onCategoryTap('Computer Repair'),
              ),
              CategoryItem(
                icon: Icons.more_horiz,
                label: 'Other',
                color: Colors.grey,
                onTap: () => onCategoryTap('Other'),
              ),
              Container(width: 60),
              Container(width: 60),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const CategoryItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

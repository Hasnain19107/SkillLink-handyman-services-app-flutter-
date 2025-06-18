import 'package:flutter/material.dart';

import '../../../widgets/home/top_rated.dart';

// Add this import assuming TopRated widget exists in this file

class TopRatedSection extends StatelessWidget {
  final GlobalKey topRatedKey;

  const TopRatedSection({
    Key? key,
    required this.topRatedKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Rated',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        TopRatedProviders(key: topRatedKey),
      ],
    );
  }
}

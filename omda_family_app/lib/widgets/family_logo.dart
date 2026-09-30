import 'package:flutter/material.dart';

import 'omda_photo.dart';

class FamilyLogo extends StatelessWidget {
  const FamilyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const OmdaPhoto(size: 130, showBadge: true),
        const SizedBox(height: 16),
        Text('عائلة العمدة',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('أفراحنا ومناسباتنا في مكان واحد', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

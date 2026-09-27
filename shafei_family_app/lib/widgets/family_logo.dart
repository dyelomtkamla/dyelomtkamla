import 'package:flutter/material.dart';

class FamilyLogo extends StatelessWidget {
  const FamilyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.diversity_3, size: 52, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text('عائلة الشافعي',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('أفراحنا ومناسباتنا في مكان واحد', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

Widget pair(
  BuildContext context,
  String label,
  String value, {
  bool ellipsis = false,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        child: Text(
          value,
          overflow: ellipsis ? TextOverflow.ellipsis : null,
        ),
      ),
    ],
  ),
);

class ProxmoxSectionHeader extends StatelessWidget {
  const ProxmoxSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 11.5,
      letterSpacing: 11.5 * 0.16,
      color: context.brass.smallCaps,
    ),
  );
}

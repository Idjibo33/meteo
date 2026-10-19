import 'package:flutter/material.dart';

class MaxWidthContainer extends StatelessWidget {
  static const double defaultMaxWidth = 480;

  final double maxWidth;
  final Widget child;

  const MaxWidthContainer({
    super.key,
    this.maxWidth = defaultMaxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth;
        return Center(
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

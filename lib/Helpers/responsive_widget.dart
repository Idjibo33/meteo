import 'package:flutter/material.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget child;
  const ResponsiveWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FractionallySizedBox(
            widthFactor: constraints.maxWidth < 500 ? 1.0 : 0.5,
            child: child,
          ),
        );
      },
    );
  }
}

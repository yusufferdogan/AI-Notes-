import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
          padding: const EdgeInsets.only(left: 30.0, right: 15.0, bottom: 30),
          child: child),
    );
  }
}

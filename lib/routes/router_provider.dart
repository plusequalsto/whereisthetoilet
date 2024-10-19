import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class RouterProvider extends StatelessWidget {
  final Widget child;
  final FluroRouter router;

  const RouterProvider({
    Key? key,
    required this.child,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

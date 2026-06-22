import 'package:flutter/material.dart';

class Responsive {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 800;
}

import 'package:flutter/material.dart';
import 'submissionsscreen.dart';

class AdminSubmissionsScreen extends StatelessWidget {
  const AdminSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubmissionsScreen(isAdmin: true);
  }
}

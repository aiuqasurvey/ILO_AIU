import 'package:flutter/material.dart';

import 'splash_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'professor_survey_screen.dart';
import 'professor_home_page.dart';
import 'admin_screen.dart';
import 'submissionsscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intended Learning Outcomes AIU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color.fromARGB(255, 189, 212, 245),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      initialRoute: "/splash",
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/survey':
            final args = settings.arguments;
            if (args == null) {
              throw Exception('يجب تمرير البيانات إلى /survey');
            }

            int professorId;
            Map<String, dynamic>? submissionData;

            if (args is int) {
              professorId = args;
            } else if (args is Map<String, dynamic>) {
              professorId = args['professorId'] as int;
              submissionData = args['submissionData'] as Map<String, dynamic>?;
            } else {
              throw Exception('البيانات المرسلة إلى /survey غير صالحة');
            }

            return MaterialPageRoute(
              builder: (_) => ProfessorSurveyScreen(
                professorId: professorId,
                submissionData: submissionData,
              ),
            );

          case '/professorHome':
            final professorId = settings.arguments as int?;
            if (professorId == null) {
              throw Exception('يجب تمرير professorId إلى /professorHome');
            }
            return MaterialPageRoute(
              builder: (_) => ProfessorHomePage(professorId: professorId),
            );

          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminScreen());

          case '/submissions':
            final isAdmin = settings.arguments as bool? ?? false;
            return MaterialPageRoute(
              builder: (_) => SubmissionsScreen(isAdmin: isAdmin),
            );

          default:
            return null;
        }
      },
    );
  }
}

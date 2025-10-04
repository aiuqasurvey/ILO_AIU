import 'package:flutter/material.dart';
import 'api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _professorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

 Future<void> _signup() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  try {
    final api = ApiService();
    final result = await api.signup(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      professorName: _professorController.text.trim(),
      email: _emailController.text.trim(),
    );

    // 🔹 Debug check to ensure role and userId
    debugPrint('New user created: userId=${result['userId']}, role=professor');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء الحساب بنجاح!')),
    );

    Navigator.pushReplacementNamed(context, "/professorHome", arguments: result['userId']);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('فشل إنشاء الحساب: $e')),
    );
  } finally {
    setState(() => _loading = false);
  }
}


  @override
  void dispose() {
    _usernameController.dispose();
    _professorController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'اسم المستخدم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _professorController,
                    decoration: const InputDecoration(labelText: 'اسم الأستاذ'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'اسم الأستاذ مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'البريد الإلكتروني مطلوب';
                      final emailRegex = RegExp(r'^[^@]+@aiu\.edu\.sy$');
                      if (!emailRegex.hasMatch(v)) {
                        return 'البريد يجب أن ينتهي بـ @aiu.edu.sy (استخدم بريد الجامعة)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'كلمة المرور مطلوبة' : null,
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('إنشاء حساب'),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, "/login"),
                    child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _tracks = [];

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  Future<void> _reloadData() async {
    setState(() => _loading = true);
    try {
      _users = await _api.getUsers();
      _faculties = await _api.getFaculties();
      if (_faculties.isNotEmpty) {
        _tracks = await _api.getTracks(_faculties.first['id'].toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل تحميل البيانات: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- إضافة بروفيسور ----------------
  Future<void> _showAddProfessorDialog() async {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isAdmin = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("إضافة بروفيسور"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: "اسم المستخدم")),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "كلمة المرور"), obscureText: true),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم البروفيسور")),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "البريد الإلكتروني")),
              Row(
                children: [
                  const Text("أدمن؟"),
                  StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return Checkbox(
                        value: isAdmin,
                        onChanged: (v) => setStateDialog(() => isAdmin = v ?? false),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (usernameCtrl.text.isEmpty ||
                  passwordCtrl.text.isEmpty ||
                  nameCtrl.text.isEmpty ||
                  emailCtrl.text.isEmpty) return;

              await _api.signup(
                username: usernameCtrl.text,
                password: passwordCtrl.text,
                professorName: nameCtrl.text,
                email: emailCtrl.text,
              );

              Navigator.pop(context);
              await _reloadData();
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  // ---------------- إضافة منهاج ----------------
  Future<void> _showAddCurriculumDialog() async {
    int? selectedTrack;
    String? selectedPeriod;
    final currEnCtrl = TextEditingController();
    final currArCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final totalHoursCtrl = TextEditingController();
    final lectureHoursCtrl = TextEditingController();
    final labHoursCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("إضافة منهاج"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedTrack,
                  decoration: const InputDecoration(labelText: "التخصص"),
                  items: _tracks.map((t) => DropdownMenuItem<int>(
                        value: t['id'],
                        child: Text(t['name']),
                      )).toList(),
                  onChanged: (val) => setStateDialog(() => selectedTrack = val),
                ),
                TextField(controller: currEnCtrl, decoration: const InputDecoration(labelText: "اسم المنهاج (EN)")),
                TextField(controller: currArCtrl, decoration: const InputDecoration(labelText: "اسم المنهاج (AR)")),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "رمز المنهاج")),
                TextField(controller: totalHoursCtrl, decoration: const InputDecoration(labelText: "الساعات الكلية")),
                TextField(controller: lectureHoursCtrl, decoration: const InputDecoration(labelText: "ساعات المحاضرات النظري")),
                TextField(controller: labHoursCtrl, decoration: const InputDecoration(labelText: "ساعات المحاضرات العملي")),
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(labelText: "الفصل الدراسي"),
                  items: ['سنوي', 'فصلي']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedPeriod = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                if (selectedTrack == null ||
                    currEnCtrl.text.isEmpty ||
                    currArCtrl.text.isEmpty ||
                    codeCtrl.text.isEmpty ||
                    totalHoursCtrl.text.isEmpty ||
                    lectureHoursCtrl.text.isEmpty ||
                    labHoursCtrl.text.isEmpty ||
                    selectedPeriod == null) return;

                await _api.addCurriculum(
                  trackId: selectedTrack!,
                  name: currArCtrl.text,
                  curriculumCode: codeCtrl.text,
                  currPeriod: selectedPeriod!,
                  totalHours: int.tryParse(totalHoursCtrl.text) ?? 0,
                  lectureHours: int.tryParse(lectureHoursCtrl.text) ?? 0,
                  labHours: int.tryParse(labHoursCtrl.text) ?? 0,
                  prerequisites: null,
                );

                Navigator.pop(context);
                await _reloadData();
              },
              child: const Text("إضافة"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAdmin(int userId, bool makeAdmin) async {
    await _api.setUserAdmin(userId, makeAdmin);
    await _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("لوحة الأدمن")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(onPressed: _showAddProfessorDialog, child: const Text("إضافة بروفيسور")),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _showAddCurriculumDialog, child: const Text("إضافة منهاج")),
            const SizedBox(height: 16),
            const Text("المستخدمون", style: TextStyle(fontWeight: FontWeight.bold)),
            ..._users.map((u) => ListTile(
                  title: Text(u['name']),
                  subtitle: Text(u['email']),
                  trailing: Switch(
                    value: u['is_admin'] == true,
                    onChanged: (val) => _toggleAdmin(u['id'], val),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

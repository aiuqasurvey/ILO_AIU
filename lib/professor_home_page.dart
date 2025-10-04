import 'package:flutter/material.dart';
import 'api_service.dart';
import 'professor_submissions_screen.dart';
import 'professor_survey_screen.dart';
import 'export_csv.dart';
import 'export_docx.dart';

class ProfessorHomePage extends StatefulWidget {
  final int professorId;

  const ProfessorHomePage({
    super.key,
    required this.professorId,
  });

  @override
  State<ProfessorHomePage> createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  final ApiService _apiService = ApiService();
  bool _loadingCsv = false;
  bool _loadingDocx = false;
  List<Map<String, dynamic>> _submissions = [];

  Future<void> _loadSubmissions() async {
    try {
      final submissions = await _apiService.getSubmissions();
      _submissions = submissions
          .where((s) => s['user_id'] == widget.professorId)
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل التقديمات: $e')),
      );
    }
  }

  Future<void> _downloadCsv() async {
    setState(() => _loadingCsv = true);
    await _loadSubmissions();
    if (_submissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تقديمات للتصدير')),
      );
      setState(() => _loadingCsv = false);
      return;
    }
    await exportToCSV(_submissions, locale: "ar");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تصدير ملف CSV بنجاح')),
    );
    setState(() => _loadingCsv = false);
  }

  Future<void> _downloadAllDocx() async {
    setState(() => _loadingDocx = true);
    await _loadSubmissions();
    if (_submissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تقديمات للتصدير')),
      );
      setState(() => _loadingDocx = false);
      return;
    }
    for (final submission in _submissions) {
      await exportToDOCX(submission, locale: "ar");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تصدير جميع ملفات DOCX بنجاح')),
    );
    setState(() => _loadingDocx = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // 👈 Arabic RTL
      child: Scaffold(
        appBar: AppBar(
          title: const Text("الصفحة الرئيسية للمدرس"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text("تقديماتي"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfessorSubmissionsScreen(
                        userId: widget.professorId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("إضافة توصيف مقرر جديد"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfessorSurveyScreen(
                        professorId: widget.professorId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: _loadingCsv
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download),
                label: const Text("تحميل جميع الملفات بصيغة CSV"),
                onPressed: _loadingCsv ? null : _downloadCsv,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: _loadingDocx
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: const Text("تحميل جميع الملفات بصيغة DOCX"),
                onPressed: _loadingDocx ? null : _downloadAllDocx,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

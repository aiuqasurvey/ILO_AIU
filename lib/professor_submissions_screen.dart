import 'package:flutter/material.dart';
import 'api_service.dart';
import 'export_docx.dart';
import 'professor_survey_screen.dart';

class ProfessorSubmissionsScreen extends StatefulWidget {
  final int userId;

  const ProfessorSubmissionsScreen({super.key, required this.userId});

  @override
  State<ProfessorSubmissionsScreen> createState() => _ProfessorSubmissionsScreenState();
}

class _ProfessorSubmissionsScreenState extends State<ProfessorSubmissionsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;
  bool _downloadingAll = false;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _loading = true);
    try {
      final submissions = await _apiService.getSubmissions(professorId: widget.userId);
      setState(() => _submissions = submissions);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الإرسالات: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteSubmission(int submissionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا الإرسال؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteSubmission(submissionId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الإرسال')),
        );
        _loadSubmissions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الإرسال: $e')),
        );
      }
    }
  }

  void _editSubmission(Map<String, dynamic> submission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessorSurveyScreen(
          professorId: widget.userId,
          submissionData: submission,
        ),
      ),
    ).then((_) => _loadSubmissions());
  }

  Future<void> _downloadAllDOCX() async {
    if (_submissions.isEmpty) return;
    setState(() => _downloadingAll = true);
    for (final sub in _submissions) {
      await exportToDOCX(sub, locale: "ar");
    }
    setState(() => _downloadingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تصدير جميع الإرسالات كملف DOCX بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("كل الإرسالات"), centerTitle: true),
        body: Column(
          children: [
            if (_submissions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: _downloadingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.file_download),
                  label: Text(_downloadingAll ? 'جاري التنزيل...' : 'تنزيل كل الإرسالات DOCX'),
                  onPressed: _downloadingAll ? null : _downloadAllDOCX,
                ),
              ),
            Expanded(
              child: _submissions.isEmpty
                  ? const Center(child: Text("لا توجد إرسالات"))
                  : RefreshIndicator(
                      onRefresh: _loadSubmissions,
                      child: ListView.builder(
                        itemCount: _submissions.length,
                        itemBuilder: (context, index) {
                          final submission = _submissions[index];
                          final curriculum = submission['curriculum'] ?? {};

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${submission['professor']} - ${submission['year']} - المستوى ${submission['level']}",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text("المقرر: ${curriculum['name'] ?? 'غير معروف'} (${curriculum['code'] ?? ''})"),
                                        Text("الكلية: ${curriculum['faculty'] ?? ''}"),
                                        Text("المحور: ${curriculum['track'] ?? ''}"),
                                        Text("مدة المقرر: ${curriculum['period'] ?? ''}"),
                                        Text(
                                            "الساعات: الكلية ${curriculum['total_hours'] ?? 0}, النظرية ${curriculum['lecture_hours'] ?? 0}, العملية ${curriculum['lab_hours'] ?? 0}"),
                                        Text("المتطلبات السابقة: ${curriculum['prerequisites'] ?? 'لا يوجد'}"),
                                        const SizedBox(height: 6),
                                        Text("المخرجات التعليمية:", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (submission['outcomes'] != null)
                                          ...submission['outcomes'].map<Widget>((o) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Text(
                                                    "- ${o['bloom_level'] ?? ''} | ${o['verb'] ?? ''} | ${o['object'] ?? ''} | ${o['qualifier'] ?? ''}"),
                                              )),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'تعديل',
                                        onPressed: () => _editSubmission(submission),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'حذف',
                                        onPressed: () => _deleteSubmission(submission['id']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        tooltip: "تصدير DOCX",
                                        onPressed: () async {
                                          await exportToDOCX(submission, locale: "ar");
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("تم تصدير الملف DOCX")),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

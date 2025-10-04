import 'package:flutter/material.dart';
import 'api_service.dart';
import 'export_csv.dart';
import 'export_docx.dart';

class SubmissionsScreen extends StatefulWidget {
  final bool isAdmin;
  final String? professorEmail; 

  const SubmissionsScreen({super.key, this.isAdmin = false, this.professorEmail});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _loading = true);
    try {
      final submissions = await _apiService.getSubmissions();

      if (!widget.isAdmin && widget.professorEmail != null) {
        _submissions = submissions
            .where((s) => s['professor_email'] == widget.professorEmail)
            .toList();
      } else {
        _submissions = submissions;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الإرسالات: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isAr = langCode == 'ar';

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isAdmin ? "كل الإرسالات" : "إرسالاتي"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (!widget.isAdmin && _submissions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text("تصدير كـ CSV"),
                  onPressed: () async {
                    await exportToCSV(_submissions, locale: langCode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم التصدير إلى CSV")),
                    );
                  },
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
                          final professor = submission['professor'] ?? "غير معروف";
                          final year = submission['year'] ?? '';
                          final integerLevel = submission['level']?.toString() ?? '';

                          final curriculum = submission['curriculum'] ?? {};
                          final currEn = curriculum['curr_en'] ?? '';
                          final currAr = curriculum['curr_ar'] ?? '';
                          final code = curriculum['curriculum_code'] ?? '';
                          final period = curriculum['curr_period'] ?? '';
                          final totalHours = curriculum['total_hours']?.toString() ?? '0';
                          final lectureHours = curriculum['lecture_hours']?.toString() ?? '0';
                          final labHours = curriculum['lab_hours']?.toString() ?? '0';
                          final prereq = curriculum['prerequisites'] ?? '';

                          final bloomLevels = (submission['bloom_levels'] as List<dynamic>? ?? [])
                              .map((e) => e.toString())
                              .join(', ');

                          final outcomes = (submission['outcomes'] as List<dynamic>? ?? [])
                              .map((e) =>
                                  "بلوم: ${e['bloom_level']}, المستوى: ${e['level']}, الفعل: ${e['verb_id']}, الهدف: ${e['object']} (${e['qualifier'] ?? ''})")
                              .join('\n');

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              title: Text(
                                "$professor - $year - المستوى $integerLevel",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "المنهاج:\n"
                                "- EN: $currEn\n"
                                "- AR: $currAr\n"
                                "- الكود: $code\n"
                                "- الفصل: $period\n"
                                "- الساعات الكلية: $totalHours\n"
                                "- ساعات المحاضرات: $lectureHours\n"
                                "- ساعات العملي: $labHours\n"
                                "- المتطلبات السابقة: $prereq\n\n"
                                "مستويات بلوم: $bloomLevels\n"
                                "المخرجات:\n$outcomes",
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.download),
                                tooltip: "تصدير DOCX",
                                onPressed: () async {
                                  await exportToDOCX(submission, locale: langCode);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم التصدير إلى DOCX")),
                                  );
                                },
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

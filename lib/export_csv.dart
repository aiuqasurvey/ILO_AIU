import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:path_provider/path_provider.dart';

Future<Directory?> _getDownloadsDirectory() async {
  if (kIsWeb) return null;
  if (Platform.isAndroid || Platform.isIOS) {
    return Directory('/storage/emulated/0/Download');
  }
  return await getApplicationDocumentsDirectory();
}

Future<void> exportToCSV(List<Map<String, dynamic>> submissions, {String locale = 'en'}) async {
  if (submissions.isEmpty) return;

  final headersMap = {
    'en': [
      'Professor',
      'Faculty',
      'Department',
      'Curriculum',
      'Curriculum Code',
      'Period',
      'Prerequisites',
      'Total Hours',
      'Lecture Hours',
      'Lab Hours',
      'Year',
      'Integer Level',
      'Bloom Levels',
      'Action Verbs',
      'Objects',
      'Qualifiers'
    ],
    'ar': [
      'الأستاذ',
      'الكلية',
      'القسم',
      'المقرر',
      'رمز المقرر',
      'مدة المقرر',
      'المتطلبات السابقة',
      'إجمالي الساعات',
      'ساعات المحاضرة',
      'ساعات المختبر',
      'السنة الدراسية',
      'المستوى العددي',
      'المستويات',
      'الأفعال',
      'الغرض',
      'المؤهلات'
    ],
  };

  final headers = headersMap[locale] ?? headersMap['en']!;

  final rows = submissions.map((s) {
    final curriculum = s['curriculum'] ?? {};
    final bloomLevels = (s['bloom_levels'] as List?)?.join(', ') ?? '';
    final integerLevel = s['level']?.toString() ?? '';

    final verbs = <String>[];
    final objects = <String>[];
    final qualifiers = <String>[];

    if (s['outcomes'] != null && s['outcomes'] is List<Map<String, dynamic>>) {
      for (var outcome in s['outcomes']) {
        verbs.add(outcome['verb_id']?.toString() ?? '');
        objects.add(outcome['object'] ?? '');
        qualifiers.add(outcome['qualifier'] ?? '');
      }
    }

    return [
      s['professor'] ?? '',
      s['faculty'] ?? '',
      s['department'] ?? '',
      locale == 'ar' ? (curriculum['curr_ar'] ?? '') : (curriculum['curr_en'] ?? ''),
      curriculum['curriculum_code'] ?? '',
      curriculum['curr_period'] ?? '',
      curriculum['prerequisites'] ?? '',
      curriculum['total_hours']?.toString() ?? '',
      curriculum['lecture_hours']?.toString() ?? '',
      curriculum['lab_hours']?.toString() ?? '',
      s['year'] ?? '',
      integerLevel,
      bloomLevels,
      verbs.join('; '),
      objects.join('; '),
      qualifiers.join('; ')
    ];
  }).toList();

  final csvData = [headers, ...rows];
  final csv = const ListToCsvConverter().convert(csvData);

  if (kIsWeb) {
    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'submissions.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
    return;
  }

  final dir = await _getDownloadsDirectory();
  if (dir == null) return;

  final file = File('${dir.path}/submissions.csv');
  await file.writeAsString(csv);

  print('CSV saved to ${file.path}');
}

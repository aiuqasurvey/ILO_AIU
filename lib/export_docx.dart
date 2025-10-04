import 'dart:io';
import 'package:flutter/services.dart';
import 'package:docx_template_fork/docx_template_fork.dart';
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

Future<void> exportToDOCX(Map<String, dynamic> submission, {String locale = 'en'}) async {
  final ByteData data = await rootBundle.load('assets/template.docx');
  final DocxTemplate docx = await DocxTemplate.fromBytes(data.buffer.asUint8List());

  final curriculum = submission['curriculum'] ?? {};
  final bloomLevels = (submission['bloom_levels'] as List?)?.join(', ') ?? '';
  final level = submission['level']?.toString() ?? '';

  // Prepare outcomes list for the {{#outcomes}} section
  final outcomes = submission['outcomes'] is List
      ? List<Map<String, dynamic>>.from(submission['outcomes'])
      : <Map<String, dynamic>>[];

  final outcomesContent = outcomes
      .map((o) => Content()
        ..add(TextContent('bloom_level', o['bloom_level'] ?? ''))
        ..add(TextContent('level', o['level']?.toString() ?? level))
        ..add(TextContent('verb', o['verb_id']?.toString() ?? ''))
        ..add(TextContent('object', o['object'] ?? ''))
        ..add(TextContent('qualifier', o['qualifier'] ?? '')))
      .toList();

  // Fill placeholders in DOCX template
  final content = Content()
    ..add(TextContent('curriculum', locale == 'ar' ? curriculum['curr_ar'] ?? '' : curriculum['curr_en'] ?? ''))
    ..add(TextContent('faculty', submission['faculty'] ?? ''))
    ..add(TextContent('department', submission['department'] ?? ''))
    ..add(TextContent('professor', submission['professor'] ?? ''))
    ..add(TextContent('year', submission['year'] ?? ''))
    ..add(TextContent('level', level))
    ..add(TextContent('bloom_levels', bloomLevels))
    ..add(TextContent('code', curriculum['curriculum_code'] ?? ''))
    ..add(TextContent('period', curriculum['curr_period'] ?? ''))
    ..add(TextContent('prerequisite', curriculum['prerequisites'] ?? ''))
    ..add(TextContent('total_h', curriculum['total_hours']?.toString() ?? ''))
    ..add(TextContent('lecture_h', curriculum['lecture_hours']?.toString() ?? ''))
    ..add(TextContent('lab_h', curriculum['lab_hours']?.toString() ?? ''))
    ..add(ListContent('outcomes', outcomesContent));

  final List<int>? generated = await docx.generate(content);

  if (generated == null) {
    print('DOCX generation failed');
    return;
  }

  final filename = '${submission['professor']?.toString().replaceAll(' ', '_') ?? 'submission'}.docx';

  if (kIsWeb) {
    final blob = html.Blob([Uint8List.fromList(generated)],
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    return;
  }

  final dir = await _getDownloadsDirectory();
  if (dir == null) return;

  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(generated);
  print('DOCX saved to ${file.path}');
}

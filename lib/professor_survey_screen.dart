import 'package:flutter/material.dart';
import 'api_service.dart';
import 'widget/verb_selector.dart';
import 'professor_submissions_screen.dart';

class ProfessorSurveyScreen extends StatefulWidget {
  final int professorId;
  final Map<String, dynamic>? submissionData;

  const ProfessorSurveyScreen({
    super.key,
    required this.professorId,
    this.submissionData,
  });

  @override
  State<ProfessorSurveyScreen> createState() => _ProfessorSurveyScreenState();
}

class _ProfessorSurveyScreenState extends State<ProfessorSurveyScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;

  List<Map<String, dynamic>> _curriculums = [];
  final List<String> _years = [
    '2025-2026',
    '2026-2027',
    '2027-2028',
    '2028-2029',
    '2029-2030'
  ];
  List<Map<String, dynamic>> _bloomLevels = [];
  final Map<int, List<Map<String, dynamic>>> _verbsCache = {}; // verbs cached per bloom level

  String? _selectedCurriculumId;
  String? _selectedYear;
  int? _selectedLevel;

  final List<String> _selectedBloomLevelIds = [];
  final Map<String, Map<int, Map<String, dynamic>>> _verbsPerBloomLevel = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (var bloomVerbs in _verbsPerBloomLevel.values) {
      for (var controllers in bloomVerbs.values) {
        controllers['object']?.dispose();
        controllers['qualifier']?.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final curriculums = await _api.getCurriculumsForProfessor(widget.professorId);
      final bloomLevels = await _api.getBloomLevels();

      setState(() {
        _curriculums = curriculums;
        _bloomLevels = bloomLevels;
      });

      // Prefill if editing
      if (widget.submissionData != null) {
        final sub = widget.submissionData!;
        _selectedCurriculumId = (sub['curriculum_id'] ?? sub['curriculum']?['curriculum_id'])?.toString();
        _selectedYear = sub['year'];
        _selectedLevel = sub['level'];

        for (var outcome in sub['outcomes'] ?? []) {
          final bloomId = outcome['bloom_level_id']?.toString();
          if (bloomId == null) continue;

          if (!_selectedBloomLevelIds.contains(bloomId)) {
            _selectedBloomLevelIds.add(bloomId);

            final idInt = int.parse(bloomId);
            final verbs = _verbsCache[idInt] ?? await _api.getVerbsForBloomLevel(idInt);
            _verbsCache[idInt] = verbs;

            _verbsPerBloomLevel[bloomId] = {};
          }

          final verbKey = DateTime.now().millisecondsSinceEpoch;
          _verbsPerBloomLevel[bloomId]![verbKey] = {
            'verb_id': outcome['verb_id'],
            'object': TextEditingController(text: outcome['object'] ?? ''),
            'qualifier': TextEditingController(text: outcome['qualifier'] ?? ''),
          };
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل تحميل البيانات: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addBloomLevel(String bloomId) async {
    if (_selectedBloomLevelIds.contains(bloomId)) return;

    final idInt = int.parse(bloomId);
    final verbs = _verbsCache[idInt] ?? await _api.getVerbsForBloomLevel(idInt);
    _verbsCache[idInt] = verbs;

    setState(() {
      _selectedBloomLevelIds.add(bloomId);
      _verbsPerBloomLevel[bloomId] = {};
    });
  }

  void _removeBloomLevel(String bloomId) {
    _verbsPerBloomLevel[bloomId]?.forEach((_, controllers) {
      controllers['object']?.dispose();
      controllers['qualifier']?.dispose();
    });
    setState(() {
      _verbsPerBloomLevel.remove(bloomId);
      _selectedBloomLevelIds.remove(bloomId);
    });
  }

  List<Map<String, dynamic>> _availableVerbs(String bloomId) {
    final idInt = int.tryParse(bloomId);
    if (idInt == null) return [];
    return _verbsCache[idInt] ?? [];
  }

  void _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى استكمال جميع الحقول')),
      );
      return;
    }

    final outcomes = <Map<String, dynamic>>[];
    _verbsPerBloomLevel.forEach((bloomId, verbsMap) {
      verbsMap.forEach((_, controllers) {
        if (controllers['verb_id'] == null) return;
        outcomes.add({
          'bloom_level_id': int.parse(bloomId),
          'verb_id': controllers['verb_id'],
          'object': controllers['object']?.text ?? '',
          'qualifier': controllers['qualifier']?.text ?? '',
        });
      });
    });

    if (outcomes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أفعال قبل الإرسال')),
      );
      return;
    }

    try {
      if (widget.submissionData != null) {
        final submissionId = widget.submissionData!['id'] as int;
        await _api.updateILO(submissionId, {
          'professor_id': widget.professorId,
          'curriculum_id': int.parse(_selectedCurriculumId!),
          'year': _selectedYear,
          'level': _selectedLevel,
          'outcomes': outcomes,
        });
      } else {
        await _api.submitILO({
          'professor_id': widget.professorId,
          'curriculum_id': int.parse(_selectedCurriculumId!),
          'year': _selectedYear,
          'level': _selectedLevel,
          'outcomes': outcomes,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الإرسال بنجاح!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessorSubmissionsScreen(userId: widget.professorId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الإرسال: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.submissionData != null ? 'تعديل التوصيف' : 'إضافة توصيف جديد'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Curriculum
                  DropdownButtonFormField<String>(
                    value: _selectedCurriculumId,
                    decoration: const InputDecoration(labelText: 'الخطة الدراسية'),
                    items: _curriculums
                        .map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['name'].toString()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCurriculumId = val),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 8),

                  // Year
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(labelText: 'السنة الدراسية'),
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (v) => setState(() => _selectedYear = v),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 8),

                  // Level
                  DropdownButtonFormField<int>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(labelText: 'المستوى (1-10)'),
                    items: List.generate(10, (i) => i + 1)
                        .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLevel = v),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  // Add Bloom Level
                  DropdownButtonFormField<String>(
                    value: null,
                    hint: const Text("اختر مستوى Bloom"),
                    items: _bloomLevels
                        .map((level) => DropdownMenuItem(
                              value: level['bloom_level_id'].toString(),
                              child: Text(level['name']),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) await _addBloomLevel(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selected Bloom Levels and verbs
                  ..._selectedBloomLevelIds.map((bloomId) {
                    final bloomName = _bloomLevels.firstWhere(
                      (b) => b['bloom_level_id'].toString() == bloomId,
                      orElse: () => {'name': 'غير معروف'},
                    )['name'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(bloomName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeBloomLevel(bloomId),
                                ),
                              ],
                            ),
                            VerbSelector(
                              levelName: bloomName,
                              availableVerbs: _availableVerbs(bloomId),
                              selectedVerbs: _verbsPerBloomLevel[bloomId]!,
                              onUpdate: () => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: Text(widget.submissionData != null ? 'تحديث' : 'إرسال'),
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

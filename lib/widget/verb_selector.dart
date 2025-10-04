import 'package:flutter/material.dart';

class VerbSelector extends StatefulWidget {
  final String levelName; // Bloom Level name
  final List<Map<String, dynamic>> availableVerbs; // verbs for this bloom level
  final Map<int, Map<String, dynamic>> selectedVerbs; // key -> {verb_id, object, qualifier}
  final VoidCallback onUpdate;

  const VerbSelector({
    super.key,
    required this.levelName,
    required this.availableVerbs,
    required this.selectedVerbs,
    required this.onUpdate,
  });

  @override
  State<VerbSelector> createState() => _VerbSelectorState();
}

class _VerbSelectorState extends State<VerbSelector> {
  int? _chosenVerbId;

  void _addVerb(int verbId) {
    final key = DateTime.now().millisecondsSinceEpoch;
    widget.selectedVerbs[key] = {
      'verb_id': verbId,
      'object': TextEditingController(),
      'qualifier': TextEditingController(),
    };
    widget.onUpdate();
  }

  void _removeVerb(int key) {
    widget.selectedVerbs[key]?['object']?.dispose();
    widget.selectedVerbs[key]?['qualifier']?.dispose();
    widget.selectedVerbs.remove(key);
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.availableVerbs.isNotEmpty)
          DropdownButtonFormField<int>(
            value: _chosenVerbId,
            hint: const Text("اختر الفعل"),
            isExpanded: true,
            items: widget.availableVerbs.map((v) {
              final verbName = v['name']?.toString() ?? 'غير معروف';
              final verbId = v['verb_id'];
              if (verbId == null) return null;
              return DropdownMenuItem<int>(
                value: verbId as int,
                child: Text(verbName),
              );
            }).whereType<DropdownMenuItem<int>>().toList(),
            onChanged: (val) {
              if (val != null) {
                _addVerb(val);
                setState(() => _chosenVerbId = null);
              }
            },
          ),
        const SizedBox(height: 8),
        ...widget.selectedVerbs.entries.map((entry) {
          final key = entry.key;
          final controllers = entry.value;

          final verbObj = widget.availableVerbs.firstWhere(
            (v) => v['verb_id'] == controllers['verb_id'],
            orElse: () => {'name': 'غير معروف'},
          );
          final verbName = verbObj['name']?.toString() ?? 'غير معروف';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(verbName)),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: controllers['object'],
                      decoration: const InputDecoration(labelText: "الموضوع"),
                      validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: controllers['qualifier'],
                      decoration: const InputDecoration(labelText: "المحدد"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVerb(key),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/hifz_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';

class HifzRevisionScreen extends StatefulWidget {
  const HifzRevisionScreen({super.key});
  @override
  State<HifzRevisionScreen> createState() => _HifzRevisionScreenState();
}

class _HifzRevisionScreenState extends State<HifzRevisionScreen> {
  List<Map<String, dynamic>>? _due;
  Map<int, String> _surahNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final due = await HifzService.getPortionsDueForRevision();
    final surahs = await QuranRepository.load();
    if (!mounted) return;
    setState(() {
      _due = due;
      _surahNames = {for (final s in surahs) s.number: s.name};
      _loading = false;
    });
  }

  Future<void> _markRevised(String id) async {
    await HifzService.markPortionRevised(id);
    await _load();
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? '\\u0645\\u0631\\u0627\\u062c\\u0639\\u0629 \\u0627\\u0644\\u062d\\u0641\\u0638' : 'Hifz Revision'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_due == null || _due!.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isAr
                          ? '\\u0644\\u0627 \\u062a\\u0648\\u062c\\u062f \\u0645\\u0642\\u0627\\u0637\\u0639 \\u0645\\u062d\\u0641\\u0648\\u0638\\u0629 \\u062a\\u062d\\u062a\\u0627\\u062c \\u0645\\u0631\\u0627\\u062c\\u0639\\u0629 \\u062d\\u0627\\u0644\\u064a\\u064b\\u0627. \\u0623\\u0643\\u0645\\u0644 \\u062e\\u0637\\u0629 \\u062d\\u0641\\u0638 \\u064a\\u0648\\u0645\\u064a\\u0629 \\u0644\\u062a\\u0638\\u0647\\u0631 \\u0647\\u0646\\u0627 \\u0644\\u0627\\u062d\\u0642\\u064b\\u0627 \\u0644\\u0644\\u0645\\u0631\\u0627\\u062c\\u0639\\u0629.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _due!.length,
                    itemBuilder: (context, index) {
                      final p = _due![index];
                      final surahName = _surahNames[p['surah']] ?? '${p['surah']}';
                      return Card(
                        child: ListTile(
                          title: Text(surahName, textDirection: TextDirection.rtl),
                          subtitle: Text('${p['start']} - ${p['end']}'),
                          trailing: FilledButton(
                            onPressed: () => _markRevised(p['id'] as String),
                            child: Text(isAr ? '\\u062a\\u0645\\u062a \\u0627\\u0644\\u0645\\u0631\\u0627\\u062c\\u0639\\u0629' : 'Revised'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/hifz_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';

String _ht(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

enum HifzVisibility { visible, blurred, hidden }

/// Memorization practice mode: pick a surah, then hide/blur its verses one
/// at a time (or all at once) to test recall. Also supports an optional
/// daily memorization plan (surah + ayah range + a target repeat count
/// per ayah) with day-streak tracking, persisted via [HifzService] --
/// unlike the visibility-cycling state (still intentionally ephemeral,
/// resets when leaving the screen), the plan/reps/streak survive
/// across app restarts since a "daily" plan is meaningless otherwise.
class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key});
  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> {
  List<SurahModel>? _allSurahs;
  SurahModel? _selectedSurah;
  HifzVisibility _globalMode = HifzVisibility.visible;
  final Map<int, HifzVisibility> _perAyahOverride = {};

  HifzPlan? _plan;
  int _streak = 0;
  final Map<int, int> _repsCache = {};

  @override
  void initState() {
    super.initState();
    QuranRepository.load().then((s) {
      if (mounted) setState(() => _allSurahs = s);
    });
    _loadPlanAndStreak();
  }

  Future<void> _loadPlanAndStreak() async {
    final plan = await HifzService.getPlan();
    final streak = await HifzService.getStreak();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _streak = streak;
    });
  }

  Future<void> _loadRepsForSurah(SurahModel surah) async {
    final plan = _plan;
    if (plan == null || plan.surahNumber != surah.number) return;
    final entries = <int, int>{};
    for (var a = plan.startAyah; a <= plan.endAyah; a++) {
      entries[a] = await HifzService.getTodayReps(surah.number, a);
    }
    if (!mounted) return;
    setState(() => _repsCache.addAll(entries));
  }

  Future<void> _incrementRep(int ayahNumber) async {
    final plan = _plan;
    if (plan == null) return;
    final updated = await HifzService.incrementReps(plan.surahNumber, ayahNumber, plan.targetReps);
    final wasStreak = _streak;
    final newStreak = await HifzService.checkAndUpdateStreakIfPlanCompleted();
    if (newStreak != wasStreak) {
      await HifzService.markPortionMemorized(plan.surahNumber, plan.startAyah, plan.endAyah);
    }
    if (!mounted) return;
    setState(() {
      _repsCache[ayahNumber] = updated;
      _streak = newStreak;
    });
  }

  HifzVisibility _modeFor(int ayahNumber) => _perAyahOverride[ayahNumber] ?? _globalMode;

  void _cycleAyah(int ayahNumber) {
    setState(() {
      final current = _modeFor(ayahNumber);
      _perAyahOverride[ayahNumber] = switch (current) {
        HifzVisibility.visible => HifzVisibility.blurred,
        HifzVisibility.blurred => HifzVisibility.hidden,
        HifzVisibility.hidden => HifzVisibility.visible,
      };
    });
  }

  Future<void> _openPlanEditor() async {
    final surahs = _allSurahs;
    if (surahs == null) return;
    final result = await showDialog<HifzPlan>(
      context: context,
      builder: (context) => _PlanEditorDialog(surahs: surahs, initial: _plan),
    );
    if (result != null) {
      await HifzService.setPlan(result);
      _repsCache.clear();
      await _loadPlanAndStreak();
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah = _selectedSurah;
    return Scaffold(
      appBar: AppBar(
        title: Text(surah == null ? _ht(context, '\u0648\u0636\u0639 \u0627\u0644\u062d\u0641\u0638', 'Hifz Mode') : surah.name),
        centerTitle: true,
        leading: surah != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() {
                _selectedSurah = null;
                _perAyahOverride.clear();
              }))
            : null,
        actions: surah == null
            ? null
            : [
                PopupMenuButton<HifzVisibility>(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: _ht(context, '\u0648\u0636\u0639 \u0627\u0644\u0625\u062e\u0641\u0627\u0621', 'Hide mode'),
                  onSelected: (mode) => setState(() {
                    _globalMode = mode;
                    _perAyahOverride.clear();
                  }),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: HifzVisibility.visible, child: Text(_ht(context, '\u0645\u0631\u0626\u064a', 'Visible'))),
                    PopupMenuItem(value: HifzVisibility.blurred, child: Text(_ht(context, '\u0645\u0636\u0628\u0651\u0628', 'Blurred'))),
                    PopupMenuItem(value: HifzVisibility.hidden, child: Text(_ht(context, '\u0645\u062e\u0641\u064a', 'Hidden'))),
                  ],
                ),
              ],
      ),
      body: surah == null ? _buildSurahList() : _buildAyahList(surah),
    );
  }

  SurahModel? _findSurah(int number) {
    final surahs = _allSurahs;
    if (surahs == null) return null;
    for (final s in surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  Widget _buildDailyPlanCard() {
    final plan = _plan;
    final surahs = _allSurahs;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryEmerald, AppColors.goldAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            _streak > 0
                ? _ht(context, '\u0633\u0644\u0633\u0644\u0629 $_streak \u064a\u0648\u0645', 'Streak: $_streak days')
                : _ht(context, '\u0627\u0628\u062f\u0623 \u0633\u0644\u0633\u0644\u062a\u0643 \u0627\u0644\u064a\u0648\u0645', 'Start your streak today'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton(
            onPressed: surahs == null ? null : _openPlanEditor,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(_ht(context, plan == null ? '\u062a\u062d\u062f\u064a\u062f \u062e\u0637\u0629' : '\u062a\u0639\u062f\u064a\u0644', plan == null ? 'Set plan' : 'Edit')),
          ),
        ]),
        if (plan != null) ...[
          const SizedBox(height: 6),
          Builder(builder: (context) {
            final s = _findSurah(plan.surahNumber);
            final label = s == null
                ? '\u0633\u0648\u0631\u0629 ${plan.surahNumber}'
                : '${s.name} (${plan.startAyah}-${plan.endAyah})';
            return Text(
              '$label \u2022 ${_ht(context, '\u0627\u0644\u0647\u062f\u0641', 'target')}: ${plan.targetReps}\u00d7',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildSurahList() {
    final surahs = _allSurahs;
    if (surahs == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      children: [
        _buildDailyPlanCard(),
        ...surahs.map((s) => ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
                child: Text('${s.number}', style: TextStyle(color: AppColors.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              title: Text(s.name, textDirection: TextDirection.rtl),
              subtitle: Text('${s.ayahs.length} ${_ht(context, '\u0622\u064a\u0629', 'verses')}', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              onTap: () {
                setState(() => _selectedSurah = s);
                _repsCache.clear();
                _loadRepsForSurah(s);
              },
            )),
      ],
    );
  }

  Widget _buildAyahList(SurahModel surah) {
    final plan = _plan;
    final planActiveHere = plan != null && plan.surahNumber == surah.number;
    return Column(children: [
      Container(
        width: double.infinity,
        color: AppColors.primaryEmerald.withValues(alpha: 0.06),
        padding: const EdgeInsets.all(10),
        child: Text(
          _ht(context, '\u0627\u0636\u063a\u0637 \u0639\u0644\u0649 \u0623\u064a \u0622\u064a\u0629 \u0644\u062a\u063a\u064a\u064a\u0631 \u0648\u0636\u0639\u0647\u0627 (\u0645\u0631\u0626\u064a \u2190 \u0645\u0636\u0628\u0651\u0628 \u2190 \u0645\u062e\u0641\u064a)',
              'Tap any verse to cycle its state (visible \u2192 blurred \u2192 hidden)'),
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          textAlign: TextAlign.center,
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surah.ayahs.length,
          itemBuilder: (context, index) {
            final ayah = surah.ayahs[index];
            final mode = _modeFor(ayah.number);
            final showReps = planActiveHere && ayah.number >= plan.startAyah && ayah.number <= plan.endAyah;
            final reps = _repsCache[ayah.number] ?? 0;
            return GestureDetector(
              onTap: () => _cycleAyah(ayah.number),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (mode == HifzVisibility.hidden)
                    Center(
                      child: Icon(Icons.remove_red_eye_outlined, color: Colors.grey.shade400),
                    )
                  else if (mode == HifzVisibility.blurred)
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Text(
                        ayah.text,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.9),
                      ),
                    )
                  else
                    Text(
                      ayah.text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.9),
                    ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('\u0622\u064a\u0629 ${ayah.number}', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    if (showReps) ...[
                      const Spacer(),
                      Text('$reps/${plan.targetReps}', style: TextStyle(fontSize: 11, color: reps >= plan.targetReps ? AppColors.primaryEmerald : AppColors.mutedText, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: reps >= plan.targetReps ? null : () => _incrementRep(ayah.number),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            reps >= plan.targetReps ? Icons.check_circle : Icons.add_circle_outline,
                            size: 18,
                            color: reps >= plan.targetReps ? AppColors.primaryEmerald : AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _PlanEditorDialog extends StatefulWidget {
  final List<SurahModel> surahs;
  final HifzPlan? initial;
  const _PlanEditorDialog({required this.surahs, required this.initial});

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  late SurahModel _surah;
  late int _startAyah;
  late int _endAyah;
  late int _targetReps;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    SurahModel initialSurah = widget.surahs.first;
    for (final s in widget.surahs) {
      if (s.number == initial?.surahNumber) {
        initialSurah = s;
        break;
      }
    }
    _surah = initialSurah;
    _startAyah = initial?.startAyah ?? 1;
    _endAyah = initial?.endAyah ?? (_surah.ayahs.isNotEmpty ? _surah.ayahs.first.number : 1);
    _targetReps = initial?.targetReps ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    final maxAyah = _surah.ayahs.isEmpty ? 1 : _surah.ayahs.last.number;
    return AlertDialog(
      title: Text(_ht(context, '\u062e\u0637\u0629 \u0627\u0644\u062d\u0641\u0638 \u0627\u0644\u064a\u0648\u0645\u064a\u0629', 'Daily Hifz Plan')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<SurahModel>(
            initialValue: _surah,
            isExpanded: true,
            items: widget.surahs
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name, textDirection: TextDirection.rtl)))
                .toList(),
            onChanged: (s) {
              if (s == null) return;
              setState(() {
                _surah = s;
                _startAyah = 1;
                _endAyah = s.ayahs.isNotEmpty ? s.ayahs.first.number : 1;
              });
            },
            decoration: InputDecoration(labelText: _ht(context, '\u0627\u0644\u0633\u0648\u0631\u0629', 'Surah')),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('start_${_surah.number}'),
                initialValue: '$_startAyah',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _ht(context, '\u0645\u0646 \u0622\u064a\u0629', 'From ayah')),
                onChanged: (v) => _startAyah = int.tryParse(v)?.clamp(1, maxAyah) ?? _startAyah,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: ValueKey('end_${_surah.number}'),
                initialValue: '$_endAyah',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _ht(context, '\u0625\u0644\u0649 \u0622\u064a\u0629', 'To ayah')),
                onChanged: (v) => _endAyah = int.tryParse(v)?.clamp(1, maxAyah) ?? _endAyah,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '$_targetReps',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: _ht(context, '\u0639\u062f\u062f \u0645\u0631\u0627\u062a \u0627\u0644\u062a\u0643\u0631\u0627\u0631 \u0644\u0643\u0644 \u0622\u064a\u0629', 'Repeats per ayah')),
            onChanged: (v) => _targetReps = int.tryParse(v)?.clamp(1, 50) ?? _targetReps,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_ht(context, '\u0625\u0644\u063a\u0627\u0621', 'Cancel'))),
        FilledButton(
          onPressed: () {
            final start = _startAyah <= _endAyah ? _startAyah : _endAyah;
            final end = _startAyah <= _endAyah ? _endAyah : _startAyah;
            Navigator.pop(
              context,
              HifzPlan(surahNumber: _surah.number, startAyah: start, endAyah: end, targetReps: _targetReps),
            );
          },
          child: Text(_ht(context, '\u062d\u0641\u0638', 'Save')),
        ),
      ],
    );
  }
}

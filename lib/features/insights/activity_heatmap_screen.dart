import 'package:flutter/material.dart';

import '../../core/models/progress_models.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';

class ActivityHeatmapScreen extends StatefulWidget {
  const ActivityHeatmapScreen({super.key});
  @override
  State<ActivityHeatmapScreen> createState() => _ActivityHeatmapScreenState();
}

class _ActivityHeatmapScreenState extends State<ActivityHeatmapScreen> {
  List<DailyActivitySummary> _days = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = <DailyActivitySummary>[];
    for (var w = 4; w >= 0; w--) {
      final week = await UserProgressService.weekSummary(weeksAgo: w);
      all.addAll(week);
    }
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final filtered = all.where((d) => !d.date.isAfter(todayOnly)).toList();
    if (!mounted) return;
    setState(() {
      _days = filtered;
      _loading = false;
    });
  }

  double _score(DailyActivitySummary d) {
    if (!d.hasAnyActivity) return 0.0;
    final quran = (d.wirdPages / 5).clamp(0.0, 1.0);
    final azkar = (d.azkarCompleted / 20).clamp(0.0, 1.0);
    final tasbeeh = (d.tasbeehTotal / 100).clamp(0.0, 1.0);
    final prayer = (d.prayersDone / 5).clamp(0.0, 1.0);
    final avg = (quran + azkar + tasbeeh + prayer) / 4;
    return avg.clamp(0.15, 1.0);
  }

  Color _colorFor(double score) {
    if (score == 0) return AppColors.mutedText.withValues(alpha: 0.08);
    return AppColors.primaryEmerald.withValues(alpha: 0.2 + (score * 0.8));
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'خريطة النشاط' : 'Activity Heatmap'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isAr ? 'آخر 5 أسابيع' : 'Last 5 weeks',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in _days)
                        Tooltip(
                          message: '${d.date.year}-${d.date.month}-${d.date.day}',
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _colorFor(_score(d)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

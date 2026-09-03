import 'package:flutter/material.dart';
import '../../core/services/sadaqah_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

class SadaqahScreen extends StatefulWidget {
  const SadaqahScreen({super.key});
  @override
  State<SadaqahScreen> createState() => _SadaqahScreenState();
}

class _SadaqahScreenState extends State<SadaqahScreen> {
  List<SadaqahEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final entries = await SadaqahService.getAllEntries();
    if (!mounted) return;
    setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _addEntry() async {
    final result = await showDialog<SadaqahEntry>(context: context, builder: (context) => const _AddSadaqahDialog());
    if (result != null) { await SadaqahService.addEntry(result); _load(); }
  }

  Future<void> _delete(String id) async { await SadaqahService.deleteEntry(id); _load(); }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final total = SadaqahService.totalAmount(_entries);
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? '\u0645\u062a\u062a\u0628\u0651\u0639 \u0627\u0644\u0635\u062f\u0642\u0629' : 'Sadaqah Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              final current = appSettings.dailyReminder('sadaqah');
              await appSettings.setDailyReminder('sadaqah', current.copyWith(enabled: !current.enabled));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(current.enabled ? '\u062a\u0630\u0643\u064a\u0631 \u0627\u0644\u0635\u062f\u0642\u0629 \u0645\u0639\u0637\u0651\u0644' : '\u062a\u0630\u0643\u064a\u0631 \u0627\u0644\u0635\u062f\u0642\u0629 \u0645\u0641\u0639\u0651\u0644')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addEntry, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryEmerald, AppColors.goldAccent]), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text(isAr ? '\u0625\u062c\u0645\u0627\u0644\u064a \u0627\u0644\u0635\u062f\u0642\u0627\u062a \u0627\u0644\u0645\u0633\u062c\u0644\u0629' : 'Total recorded charity', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(total.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(isAr ? '${_entries.length} \u0639\u0645\u0644\u064a\u0629' : '${_entries.length} entries', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              Expanded(
                child: _entries.isEmpty
                    ? Center(child: Text(isAr ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0645\u0644\u064a\u0627\u062a \u0628\u0639\u062f. \u0627\u0636\u063a\u0637 + \u0644\u0625\u0636\u0627\u0641\u0629 \u0623\u0648\u0644 \u0635\u062f\u0642\u0629' : 'No entries yet. Tap + to add your first', style: const TextStyle(color: AppColors.mutedText)))
                    : ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final e = _entries[index];
                          return Dismissible(
                            key: ValueKey(e.id), direction: DismissDirection.endToStart, onDismissed: (_) => _delete(e.id),
                            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.volunteer_activism)),
                              title: Text(e.type),
                              subtitle: e.note.isEmpty ? null : Text(e.note),
                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(e.amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}

class _AddSadaqahDialog extends StatefulWidget {
  const _AddSadaqahDialog();
  @override
  State<_AddSadaqahDialog> createState() => _AddSadaqahDialogState();
}

class _AddSadaqahDialogState extends State<_AddSadaqahDialog> {
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() { _typeController.dispose(); _amountController.dispose(); _noteController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(isAr ? '\u0625\u0636\u0627\u0641\u0629 \u0635\u062f\u0642\u0629' : 'Add Sadaqah'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _typeController, decoration: InputDecoration(labelText: isAr ? '\u0627\u0644\u0646\u0648\u0639 (\u0645\u062b\u0627\u0644: \u0637\u0639\u0627\u0645\u060c \u0645\u0627\u0644)' : 'Type (e.g. food, money)')),
          const SizedBox(height: 12),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isAr ? '\u0627\u0644\u0642\u064a\u0645\u0629' : 'Amount')),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: InputDecoration(labelText: isAr ? '\u0645\u0644\u0627\u062d\u0638\u0629 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)' : 'Note (optional)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? '\u0625\u0644\u063a\u0627\u0621' : 'Cancel')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            final type = _typeController.text.trim().isEmpty ? (isAr ? '\u0635\u062f\u0642\u0629' : 'Charity') : _typeController.text.trim();
            Navigator.pop(context, SadaqahEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), type: type, amount: amount, date: DateTime.now(), note: _noteController.text.trim()));
          },
          child: Text(isAr ? '\u062d\u0641\u0638' : 'Save'),
        ),
      ],
    );
  }
}

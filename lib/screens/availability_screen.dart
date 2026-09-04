import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() =>
    _AvailabilityScreenState();
}

class _AvailabilityScreenState
    extends State<AvailabilityScreen> {
  final List<String> _dates = [];
  final _dateCtrl = TextEditingController();

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final cast = provider.castMembers;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: '回答フォーム'),
            Tab(text: '一覧表'),
          ]),
          Expanded(
            child: TabBarView(children: [
              _FormView(
                cast: cast,
                dates: _dates,
                provider: provider,
                onAddDate: (d) => setState(() => _dates.add(d)),
                onRemoveDate: (d) =>
                  setState(() => _dates.remove(d)),
                dateCtrl: _dateCtrl,
              ),
              _MatrixView(
                cast: cast,
                dates: _dates,
                provider: provider,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  final List<CastMember> cast;
  final List<String> dates;
  final ProjectProvider provider;
  final ValueChanged<String> onAddDate;
  final ValueChanged<String> onRemoveDate;
  final TextEditingController dateCtrl;

  const _FormView({
    required this.cast,
    required this.dates,
    required this.provider,
    required this.onAddDate,
    required this.onRemoveDate,
    required this.dateCtrl,
  });

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  CastMember? _selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: cs.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.dateCtrl,
                  decoration: const InputDecoration(
                    labelText: '日付を追加',
                    hintText: '例：9/15',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final d = widget.dateCtrl.text.trim();
                  if (d.isEmpty) return;
                  if (!widget.dates.contains(d)) {
                    widget.onAddDate(d);
                  }
                  widget.dateCtrl.clear();
                },
                child: const Text('追加'),
              ),
            ],
          ),
        ),
        if (widget.dates.isNotEmpty)
          Container(
            height: 44,
            color: cs.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
              children: widget.dates.map((d) =>
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(d,
                      style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => widget.onRemoveDate(d),
                  ),
                )).toList(),
            ),
          ),
        if (widget.cast.isEmpty)
          const Expanded(
            child: Center(
              child: Text('先に出演者を登録してください',
                style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 56,
                  color: cs.surface,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                    children: widget.cast.map((c) {
                      final isSelected = _selected?.id == c.id;
                      return GestureDetector(
                        onTap: () =>
                          setState(() => _selected = c),
                        child: AnimatedContainer(
                          duration:
                            const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? glightGreen : Colors.transparent,
                            borderRadius:
                              BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? glightGreen
                                  : Colors.grey.shade700),
                          ),
                          child: Text(c.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: _selected == null
                      ? const Center(
                          child: Text('上から名前を選んでください',
                            style: TextStyle(color: Colors.grey)))
                      : widget.dates.isEmpty
                          ? const Center(
                              child: Text('日付を追加してください',
                                style: TextStyle(
                                  color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: widget.dates.length,
                              itemBuilder: (_, i) {
                                final date = widget.dates[i];
                                final val = _selected!
                                  .availability[date] ?? '';
                                return _AvailRow(
                                  date: date,
                                  value: val,
                                  onChanged: (v) async {
                                    await widget.provider
                                      .updateAvailability(
                                        _selected!.id, date, v);
                                    setState(() {
                                      _selected = widget.provider
                                        .castMembers
                                        .firstWhere((c) =>
                                          c.id == _selected!.id);
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AvailRow extends StatelessWidget {
  final String date;
  final String value;
  final ValueChanged<String> onChanged;

  const _AvailRow({
    required this.date,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(date,
              style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            _AvailBtn(label: '○', color: Colors.green,
              selected: value == '○',
              onTap: () => onChanged('○')),
            const SizedBox(width: 8),
            _AvailBtn(label: '△', color: Colors.orange,
              selected: value == '△',
              onTap: () => onChanged('△')),
            const SizedBox(width: 8),
            _AvailBtn(label: '×', color: Colors.red,
              selected: value == '×',
              onTap: () => onChanged('×')),
          ],
        ),
      ),
    );
  }
}

class _AvailBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AvailBtn({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade700,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: selected ? color : Colors.grey.shade600,
            )),
        ),
      ),
    );
  }
}

class _MatrixView extends StatelessWidget {
  final List<CastMember> cast;
  final List<String> dates;
  final ProjectProvider provider;

  const _MatrixView({
    required this.cast,
    required this.dates,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (cast.isEmpty || dates.isEmpty) {
      return Center(
        child: Text(
          cast.isEmpty
              ? '出演者を登録してください'
              : '日付を追加してください',
          style: const TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(cs.surface),
          border: TableBorder.all(
            color: cs.outline, width: 1,
            borderRadius: BorderRadius.circular(8)),
          columns: [
            const DataColumn(
              label: Text('演者',
                style: TextStyle(fontWeight: FontWeight.w700))),
            ...dates.map((d) => DataColumn(
              label: Text(d,
                style: const TextStyle(
                  fontWeight: FontWeight.w700)))),
          ],
          rows: [
            ...cast.map((c) => DataRow(
              cells: [
                DataCell(Text(c.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600))),
                ...dates.map((d) {
                  final v = c.availability[d] ?? '';
                  return DataCell(Center(
                    child: Text(v,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: v == '○' ? Colors.green
                            : v == '△' ? Colors.orange
                            : v == '×' ? Colors.red
                            : Colors.grey,
                      )),
                  ));
                }),
              ],
            )),
            DataRow(
              color: WidgetStateProperty.all(
                glightGreen.withOpacity(0.08)),
              cells: [
                const DataCell(Text('全員○の日',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: glightGreen))),
                ...dates.map((d) {
                  final allOk = cast.isNotEmpty &&
                      cast.every(
                        (c) => c.availability[d] == '○');
                  return DataCell(Center(
                    child: allOk
                        ? const Icon(Icons.check_circle,
                            color: glightGreen, size: 20)
                        : const SizedBox.shrink(),
                  ));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'reminder_notifications.dart';
import 'state.dart';

const _pageSurface = Color(0xFF151C25);
const _pageRaised = Color(0xFF222D39);
const _pageAccent = Color(0xFF5E91FF);
const _pageMuted = Color(0xFFA5B0BE);
const _pageBorder = Color(0xFF2C3847);

Future<void> showVehicleForm(
  BuildContext context, {
  Map<String, dynamic>? vehicle,
}) async {
  if (vehicle == null && !context.read<AppState>().canAddVehicle) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your garage is limited to 3 vehicles')),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _VehicleDialog(vehicle: vehicle),
  );
}

Future<void> showActivityForm(BuildContext context, String type) async {
  final state = context.read<AppState>();
  if (type == 'reminder') {
    final result = await showDialog<_ReminderResult>(
      context: context,
      builder: (_) => const _ReminderDialog(),
    );
    if (result == null || !context.mounted) return;
    await state.addReminder(
      title: result.title,
      reminderType: result.type,
      dueDate: result.date,
      notes: result.notes,
    );
    await ReminderNotifications.scheduleAll(state.reminders);
    return;
  }

  final result = await showDialog<_ActivityResult>(
    context: context,
    builder: (_) => _ActivityDialog(type: type),
  );
  if (result == null || !context.mounted) return;
  await state.addActivity(
    type: type,
    title: result.title,
    date: result.date,
    cost: result.cost,
    category: result.category,
    odometer: result.odometer,
    quantity: result.quantity,
    serviceCenter: result.serviceCenter,
    details: result.details,
  );
}

class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state.timelineRecords.where((record) {
      return _filter == 'all' || record['type'] == _filter;
    }).toList();
    final vehicles = {
      for (final vehicle in state.vehicles) vehicle['id']: vehicle,
    };

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      itemCount: records.isEmpty ? 5 : records.length + 4,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _PageHeading(
            title: 'Activity timeline',
            eyebrow: 'EVERY VEHICLE',
          );
        }
        if (index == 1) return const SizedBox(height: 16);
        if (index == 2) {
          return Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                value: 'all',
                selected: _filter,
                onSelected: _setFilter,
              ),
              _FilterChip(
                label: 'Fuel',
                value: 'fuel',
                selected: _filter,
                onSelected: _setFilter,
              ),
              _FilterChip(
                label: 'Service',
                value: 'service',
                selected: _filter,
                onSelected: _setFilter,
              ),
              _FilterChip(
                label: 'Expenses',
                value: 'expense',
                selected: _filter,
                onSelected: _setFilter,
              ),
              _FilterChip(
                label: 'Documents',
                value: 'document',
                selected: _filter,
                onSelected: _setFilter,
              ),
              _FilterChip(
                label: 'Reminders',
                value: 'reminder',
                selected: _filter,
                onSelected: _setFilter,
              ),
            ],
          );
        }
        if (index == 3) return const SizedBox(height: 18);
        if (records.isEmpty) {
          return const _EmptyFeature(
            icon: Icons.timeline_rounded,
            title: 'Your timeline starts here',
            message:
                'Fuel fills, services, expenses, documents and reminders will appear in date order.',
          );
        }
        final record = records[index - 4];
        final vehicle = vehicles[record['vehicle_id']];
        final name = vehicle?['nickname'] as String? ?? 'Vehicle';
        return _TimelineEntry(
          record: record,
          vehicleName: name,
          onDelete: () =>
              context.read<AppState>().deleteRecord(record['id'] as int),
        );
      },
    );
  }

  void _setFilter(String value) => setState(() => _filter = value);
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fuelRecords =
        state.maintenanceRecords
            .where(
              (record) =>
                  record['type'] == 'fuel' && record['odometer'] != null,
            )
            .toList()
          ..sort(
            (a, b) => (a['odometer'] as num).compareTo(b['odometer'] as num),
          );
    final efficiency = <FlSpot>[];
    for (var index = 1; index < fuelRecords.length; index++) {
      final previous = fuelRecords[index - 1];
      final current = fuelRecords[index];
      final distance =
          (current['odometer'] as num) - (previous['odometer'] as num);
      final quantity = (current['quantity'] as num?)?.toDouble() ?? 0;
      if (distance > 0 && quantity > 0) {
        efficiency.add(FlSpot((index - 1).toDouble(), distance / quantity));
      }
    }
    final services =
        state.maintenanceRecords
            .where(
              (record) =>
                  record['type'] == 'service' && record['odometer'] != null,
            )
            .toList()
          ..sort(
            (a, b) => (a['odometer'] as num).compareTo(b['odometer'] as num),
          );
    final serviceCycles = <FlSpot>[];
    for (var index = 1; index < services.length; index++) {
      final previous = (services[index - 1]['odometer'] as num).toDouble();
      final current = (services[index]['odometer'] as num).toDouble();
      if (current > previous) {
        serviceCycles.add(FlSpot((index - 1).toDouble(), current - previous));
      }
    }
    final spend = _monthlyTotals(state.timelineRecords);
    final total = state.timelineRecords.fold<double>(
      0,
      (sum, record) => sum + ((record['cost'] as num?)?.toDouble() ?? 0),
    );
    final vehicle = state.vehicles.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['id'] == state.currentVehicleId,
      orElse: () => null,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        const _PageHeading(title: 'Your numbers', eyebrow: 'GARAGE ANALYTICS'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricBlock(
                label: 'TOTAL COST',
                value: _money(total),
                tint: _pageAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricBlock(
                label: 'VEHICLES',
                value: '${state.vehicles.length}',
                tint: const Color(0xFFFFC66D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricBlock(
                label: 'CURRENT ODO',
                value: '${_number(state.currentMileage)} km',
                tint: const Color(0xFF43D6B5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ChartPanel(
          title: 'Fuel efficiency',
          subtitle: vehicle?['nickname'] as String? ?? 'Selected vehicle',
          trailing: 'KM / L',
          child: efficiency.length < 2
              ? const _ChartEmpty(
                  message:
                      'Add at least three fuel fills with odometer readings to see a trend.',
                )
              : SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: efficiency,
                          isCurved: true,
                          color: _pageAccent,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            color: _pageAccent.withValues(alpha: 0.12),
                            show: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        _ChartPanel(
          title: 'Maintenance cycles',
          subtitle: 'Distance between service visits',
          trailing: 'KM',
          child: serviceCycles.isEmpty
              ? const _ChartEmpty(
                  message:
                      'Log at least two service visits with odometer readings to compare maintenance intervals.',
                )
              : SizedBox(
                  height: 170,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: serviceCycles,
                          isCurved: false,
                          color: const Color(0xFF43D6B5),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        _ChartPanel(
          title: 'Monthly spending',
          subtitle: 'All vehicles · last 6 months',
          trailing: _money(total),
          child: SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY:
                    spend
                        .map((item) => item.$2)
                        .fold<double>(1, (a, b) => a > b ? a : b) *
                    1.2,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= spend.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            spend[index].$1,
                            style: const TextStyle(
                              color: _pageMuted,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < spend.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: spend[index].$2,
                          width: 16,
                          color: const Color(0xFFFFC66D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Spending by type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._categoryTotals(state.timelineRecords).entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: _pageMuted),
                  ),
                ),
                Text(
                  _money(entry.value),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DocumentVaultTab extends StatelessWidget {
  const DocumentVaultTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      itemCount: state.documents.isEmpty ? 3 : state.documents.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              const Expanded(
                child: _PageHeading(
                  title: 'Document vault',
                  eyebrow: 'STORED ON THIS DEVICE',
                ),
              ),
              IconButton.filled(
                tooltip: 'Add document',
                onPressed: () => _importDocument(context),
                icon: const Icon(Icons.upload_file_rounded),
              ),
            ],
          );
        }
        if (index == 1) return const SizedBox(height: 18);
        if (state.documents.isEmpty) {
          return const _EmptyFeature(
            icon: Icons.folder_open_rounded,
            title: 'No paperwork yet',
            message:
                'Keep registration, insurance, PUC, warranty and service bills together offline.',
          );
        }
        return _DocumentTile(document: state.documents[index - 2]);
      },
    );
  }

  Future<void> _importDocument(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    if (state.currentVehicleId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add or select a vehicle first')),
      );
      return;
    }

    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Choose a vehicle document',
        type: FileType.any,
      );
      if (picked == null || !context.mounted) return;
      const maximumDocumentSize = 20 * 1024 * 1024;
      final knownSize = await picked.length();
      if (knownSize != null && knownSize > maximumDocumentSize) {
        throw const FormatException('Choose a document smaller than 20 MB.');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in picked.readAsByteStream()) {
        if (builder.length + chunk.length > maximumDocumentSize) {
          throw const FormatException('Choose a document smaller than 20 MB.');
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) {
        throw const FormatException(
          'The selected file is empty or unreadable.',
        );
      }
      if (!context.mounted) return;

      final result = await showDialog<_DocumentResult>(
        context: context,
        builder: (_) => _DocumentDialog(fileName: picked.name),
      );
      if (result == null || !context.mounted) return;
      final extension = picked.extension?.toLowerCase();
      final mimeType = switch (extension) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'heic' => 'image/heic',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };
      await state.addDocument(
        title: result.title,
        documentType: result.type,
        fileName: picked.name,
        mimeType: mimeType,
        data: bytes,
        expiresOn: result.expiresOn,
      );
      await ReminderNotifications.scheduleAll(state.reminders);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Document saved offline')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add document: $error')),
      );
    }
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final Map<String, dynamic> document;

  @override
  Widget build(BuildContext context) {
    final dataSize = (document['data_size'] as num?)?.toInt() ?? 0;
    final expiry = document['expires_on'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: _pageSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pageBorder),
      ),
      child: ListTile(
        leading: Icon(
          document['mime_type'] == 'application/pdf'
              ? Icons.picture_as_pdf_rounded
              : Icons.image_outlined,
          color: const Color(0xFF5E91FF),
        ),
        title: Text(
          document['title'] as String? ?? 'Vehicle document',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${document['document_type']} · ${_fileSize(dataSize)}${expiry == null ? '' : ' · Expires ${_displayDate(expiry)}'}',
          maxLines: 2,
          style: const TextStyle(color: _pageMuted, fontSize: 11),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Document actions',
          onSelected: (action) async {
            try {
              if (action == 'export') {
                final bytes = await context.read<AppState>().readDocumentData(
                  document['id'] as int,
                );
                if (!context.mounted) return;
                await FilePicker.saveFile(
                  fileName: document['file_name'] as String,
                  bytes: bytes,
                  mimeType:
                      document['mime_type'] as String? ??
                      'application/octet-stream',
                );
              } else {
                await context.read<AppState>().deleteDocument(
                  document['id'] as int,
                );
              }
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Document action failed: $error')),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'export', child: Text('Export a copy')),
            PopupMenuItem(value: 'delete', child: Text('Delete document')),
          ],
        ),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _pageSurface,
            title: Text(document['title'] as String? ?? 'Vehicle document'),
            content: Text(
              '${document['file_name']}\n${_fileSize(dataSize)} stored offline',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleDialog extends StatefulWidget {
  const _VehicleDialog({this.vehicle});

  final Map<String, dynamic>? vehicle;

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _registration = TextEditingController();
  final _odometer = TextEditingController(text: '0');
  String _fuel = 'Petrol';
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle == null) return;
    _nickname.text = vehicle['nickname'] as String? ?? '';
    _make.text = vehicle['make'] as String? ?? '';
    _model.text = vehicle['model'] as String? ?? '';
    _year.text = '${vehicle['year'] ?? ''}';
    _registration.text = vehicle['registration'] as String? ?? '';
    _odometer.text = '${vehicle['odometer'] ?? 0}';
    _fuel = vehicle['fuel_type'] as String? ?? _fuel;
    _photo = vehicle['photo'] as Uint8List?;
  }

  @override
  void dispose() {
    _nickname.dispose();
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _registration.dispose();
    _odometer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _pageSurface,
      title: Text(widget.vehicle == null ? 'Add vehicle' : 'Edit vehicle'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _choosePhoto,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 86,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _pageRaised,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _photo == null
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: _pageAccent,
                              ),
                              SizedBox(width: 9),
                              Text('Add a vehicle photo'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(_photo!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _textField(_nickname, 'Nickname', required: true),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _textField(_make, 'Make', required: true)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _textField(_model, 'Model', required: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _year,
                        'Year',
                        numeric: true,
                        minimum: 1900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _textField(
                        _odometer,
                        'Odometer (km)',
                        numeric: true,
                        minimum: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _fuel,
                  decoration: const InputDecoration(labelText: 'Fuel type'),
                  items: const ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _fuel = value ?? _fuel),
                ),
                const SizedBox(height: 10),
                _textField(_registration, 'Registration number'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.vehicle == null ? 'Add vehicle' : 'Save changes'),
        ),
      ],
    );
  }

  Future<void> _choosePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (mounted) setState(() => _photo = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final vehicle = widget.vehicle;
    if (vehicle == null) {
      await state.addVehicle(
        nickname: _nickname.text.trim(),
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text) ?? DateTime.now().year,
        fuelType: _fuel,
        registration: _registration.text.trim(),
        odometer: int.tryParse(_odometer.text) ?? 0,
        photo: _photo,
      );
    } else {
      await state.updateVehicle(
        id: vehicle['id'] as int,
        nickname: _nickname.text.trim(),
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text) ?? DateTime.now().year,
        fuelType: _fuel,
        registration: _registration.text.trim(),
        odometer: int.tryParse(_odometer.text) ?? 0,
        photo: _photo,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _ActivityDialog extends StatefulWidget {
  const _ActivityDialog({required this.type});

  final String type;

  @override
  State<_ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<_ActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _cost = TextEditingController();
  final _odometer = TextEditingController();
  final _quantity = TextEditingController();
  final _center = TextEditingController();
  final _details = TextEditingController();
  DateTime _date = DateTime.now();
  late String _category;

  String get _heading => switch (widget.type) {
    'fuel' => 'Log fuel fill',
    'service' => 'Log service visit',
    _ => 'Add expense',
  };

  @override
  void initState() {
    super.initState();
    _category = widget.type == 'fuel'
        ? 'Fuel'
        : widget.type == 'service'
        ? 'Maintenance'
        : 'Repairs';
  }

  @override
  void dispose() {
    _title.dispose();
    _cost.dispose();
    _odometer.dispose();
    _quantity.dispose();
    _center.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFuel = widget.type == 'fuel';
    final isService = widget.type == 'service';
    return AlertDialog(
      backgroundColor: _pageSurface,
      title: Text(_heading),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(
                  _title,
                  isFuel
                      ? 'Fuel station'
                      : isService
                      ? 'Service or repair'
                      : 'Expense description',
                  required: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _cost,
                        'Total cost',
                        numeric: true,
                        prefix: '₹ ',
                        required: !isService,
                        minimum: 0,
                      ),
                    ),
                    if (isFuel) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _textField(
                          _quantity,
                          'Litres',
                          numeric: true,
                          required: true,
                          minimum: 0.001,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _textField(
                  _odometer,
                  isFuel || isService ? 'Odometer (km)' : 'Odometer (optional)',
                  numeric: true,
                  required: isFuel || isService,
                  minimum: 0,
                ),
                if (isService) ...[
                  const SizedBox(height: 10),
                  _textField(_center, 'Service center'),
                ],
                if (!isFuel) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Spending category',
                    ),
                    items:
                        const [
                              'Maintenance',
                              'Repairs',
                              'Insurance',
                              'Registration',
                              'Other',
                            ]
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                  ),
                ],
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today_rounded,
                    color: _pageAccent,
                  ),
                  title: const Text(
                    'Activity date',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    _displayDate(_date.toIso8601String()),
                    style: const TextStyle(color: _pageMuted, fontSize: 12),
                  ),
                  onTap: _chooseDate,
                ),
                _textField(_details, 'Notes (optional)', maxLines: 2),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save entry')),
      ],
    );
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final date = DateTime(
      _date.year,
      _date.month,
      _date.day,
      now.hour,
      now.minute,
    ).toIso8601String();
    Navigator.pop(
      context,
      _ActivityResult(
        title: _title.text.trim(),
        date: date,
        cost: double.tryParse(_cost.text) ?? 0,
        category: widget.type == 'fuel' ? 'Fuel' : _category,
        odometer: int.tryParse(_odometer.text),
        quantity: double.tryParse(_quantity.text),
        serviceCenter: _center.text.trim(),
        details: _details.text.trim(),
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog();

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'Insurance';
  DateTime _date = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _pageSurface,
    title: const Text('Set a reminder'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Reminder name',
            hintText: 'Insurance renewal',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Reminder type'),
          items: const ['Insurance', 'PUC', 'Service', 'Registration', 'Other']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.notifications_active_outlined,
            color: _pageAccent,
          ),
          title: const Text('Due date'),
          subtitle: Text(
            _displayDate(_date.toIso8601String()),
            style: const TextStyle(color: _pageMuted),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (date != null) setState(() => _date = date);
          },
        ),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isEmpty) return;
          final date =
              '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
          Navigator.pop(
            context,
            _ReminderResult(
              _title.text.trim(),
              _type,
              date,
              _notes.text.trim(),
            ),
          );
        },
        child: const Text('Set reminder'),
      ),
    ],
  );
}

class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog({required this.fileName});

  final String fileName;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  late final _title = TextEditingController(
    text: widget.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
  );
  String _type = 'Insurance';
  DateTime? _expiry;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _pageSurface,
    title: const Text('Save document'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Document name'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Document type'),
          items:
              const [
                    'Registration Certificate',
                    'Insurance',
                    'PUC',
                    'Warranty',
                    'Service bill',
                    'Other',
                  ]
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_outlined, color: _pageAccent),
          title: Text(
            _expiry == null
                ? 'Add expiry date'
                : 'Expires ${_displayDate(_expiry!.toIso8601String())}',
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (date != null) setState(() => _expiry = date);
          },
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isEmpty) return;
          final expiry = _expiry == null
              ? null
              : '${_expiry!.year.toString().padLeft(4, '0')}-${_expiry!.month.toString().padLeft(2, '0')}-${_expiry!.day.toString().padLeft(2, '0')}';
          Navigator.pop(
            context,
            _DocumentResult(_title.text.trim(), _type, expiry),
          );
        },
        child: const Text('Save offline'),
      ),
    ],
  );
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.record,
    required this.vehicleName,
    required this.onDelete,
  });

  final Map<String, dynamic> record;
  final String vehicleName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = record['type'] as String? ?? 'service';
    final color = _typeColor(type);
    final odometer = (record['odometer'] as num?)?.toInt();
    final quantity = (record['quantity'] as num?)?.toDouble();
    final cost = (record['cost'] as num?)?.toDouble() ?? 0;
    final title = record['title'] as String? ?? 'Vehicle activity';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('timeline-${record['id']}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7468),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pageSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _pageBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(type), color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (cost > 0)
                          Text(
                            _money(cost),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$vehicleName · ${_displayDate(record['date'] as String? ?? '')}',
                      style: const TextStyle(color: _pageMuted, fontSize: 11),
                    ),
                    if (type == 'fuel' && quantity != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          '${quantity.toStringAsFixed(1)} L${odometer == null ? '' : ' · ${_number(odometer)} km'}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (type == 'service' && odometer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          '${_number(odometer)} km${record['service_center'] == null || (record['service_center'] as String).isEmpty ? '' : ' · ${record['service_center']}'}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (odometer != null &&
                        odometer > 0 &&
                        odometer % 10000 == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: _MilestoneBadge(
                          value: '${_number(odometer)} km milestone',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.eyebrow});

  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: _pageAccent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected == value,
    onSelected: (_) => onSelected(value),
    selectedColor: _pageAccent.withValues(alpha: 0.18),
    labelStyle: TextStyle(
      color: selected == value ? _pageAccent : _pageMuted,
      fontSize: 12,
    ),
    side: BorderSide(
      color: selected == value
          ? _pageAccent.withValues(alpha: 0.5)
          : _pageBorder,
    ),
    backgroundColor: _pageSurface,
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
  );
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _pageSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _pageBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _pageMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: tint,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
    decoration: BoxDecoration(
      color: _pageSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _pageBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _pageMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                color: _pageAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 140,
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _pageMuted, fontSize: 12),
      ),
    ),
  );
}

class _EmptyFeature extends StatelessWidget {
  const _EmptyFeature({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _pageSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _pageBorder),
    ),
    child: Column(
      children: [
        Icon(icon, size: 28, color: _pageMuted),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _pageMuted, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}

class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC66D).withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      value,
      style: const TextStyle(
        color: Color(0xFFFFC66D),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Widget _textField(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool numeric = false,
  String? prefix,
  int maxLines = 1,
  num? minimum,
}) => TextFormField(
  controller: controller,
  maxLines: maxLines,
  keyboardType: numeric
      ? const TextInputType.numberWithOptions(decimal: true)
      : TextInputType.text,
  decoration: InputDecoration(labelText: label, prefixText: prefix),
  validator: (value) {
    if (required && (value == null || value.trim().isEmpty)) return 'Required';
    if (numeric && value != null && value.trim().isNotEmpty) {
      final number = num.tryParse(value.trim());
      if (number == null) return 'Enter a number';
      if (minimum != null && number < minimum) {
        return minimum > 0
            ? 'Enter a value above zero'
            : 'Enter a non-negative value';
      }
    }
    return null;
  },
);

List<(String, double)> _monthlyTotals(List<Map<String, dynamic>> records) {
  final now = DateTime.now();
  final months = List.generate(
    6,
    (index) => DateTime(now.year, now.month - 5 + index),
  );
  return months.map((month) {
    final total = records.fold<double>(0, (sum, record) {
      final date = DateTime.tryParse(record['date'] as String? ?? '');
      if (date?.year != month.year || date?.month != month.month) return sum;
      return sum + ((record['cost'] as num?)?.toDouble() ?? 0);
    });
    return (_monthNames[month.month - 1], total);
  }).toList();
}

Map<String, double> _categoryTotals(List<Map<String, dynamic>> records) {
  final totals = <String, double>{};
  for (final record in records) {
    final cost = (record['cost'] as num?)?.toDouble() ?? 0;
    if (cost <= 0) continue;
    final category = record['category'] as String? ?? 'Other';
    totals[category] = (totals[category] ?? 0) + cost;
  }
  return Map.fromEntries(
    totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

Color _typeColor(String type) => switch (type) {
  'fuel' => const Color(0xFF43D6B5),
  'service' => const Color(0xFFFFC66D),
  'expense' => const Color(0xFFFF7468),
  'document' => const Color(0xFF5E91FF),
  'reminder' => const Color(0xFFE88BB2),
  _ => _pageMuted,
};

IconData _typeIcon(String type) => switch (type) {
  'fuel' => Icons.local_gas_station_rounded,
  'service' => Icons.build_circle_outlined,
  'expense' => Icons.receipt_long_rounded,
  'document' => Icons.description_outlined,
  'reminder' => Icons.notifications_active_outlined,
  _ => Icons.directions_car_filled_rounded,
};

String _money(num value) {
  final digits = value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '₹$digits';
}

String _number(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

String _displayDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final formatted = '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  if (!value.contains('T')) return formatted;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$formatted · $hour:$minute';
}

String _fileSize(int bytes) => bytes < 1024
    ? '$bytes B'
    : bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(0)} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _ActivityResult {
  const _ActivityResult({
    required this.title,
    required this.date,
    required this.cost,
    required this.category,
    this.odometer,
    this.quantity,
    this.serviceCenter,
    this.details,
  });
  final String title;
  final String date;
  final double cost;
  final String category;
  final int? odometer;
  final double? quantity;
  final String? serviceCenter;
  final String? details;
}

class _ReminderResult {
  const _ReminderResult(this.title, this.type, this.date, this.notes);
  final String title;
  final String type;
  final String date;
  final String notes;
}

class _DocumentResult {
  const _DocumentResult(this.title, this.type, this.expiresOn);
  final String title;
  final String type;
  final String? expiresOn;
}

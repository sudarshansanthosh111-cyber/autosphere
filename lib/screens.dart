import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'feature_screens.dart';
import 'reminder_notifications.dart';
import 'state.dart';

const _background = Color(0xFF0D1117);
const _surface = Color(0xFF151C25);
const _surfaceRaised = Color(0xFF222D39);
const _accent = Color(0xFF5E91FF);
const _muted = Color(0xFFA5B0BE);
const _border = Color(0xFF2C3847);
const _amber = Color(0xFFFFC66D);
const _coral = Color(0xFFFF7468);

Future<void> _editServiceInterval(
  BuildContext context, {
  required int vehicleId,
  required int currentInterval,
}) async {
  final state = context.read<AppState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ServiceIntervalDialog(
      state: state,
      vehicleId: vehicleId,
      currentInterval: currentInterval,
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Service interval updated')));
  }
}

class _ServiceIntervalDialog extends StatefulWidget {
  const _ServiceIntervalDialog({
    required this.state,
    required this.vehicleId,
    required this.currentInterval,
  });

  final AppState state;
  final int vehicleId;
  final int currentInterval;

  @override
  State<_ServiceIntervalDialog> createState() => _ServiceIntervalDialogState();
}

class _ServiceIntervalDialogState extends State<_ServiceIntervalDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentInterval}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      title: const Text('Service interval'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Distance between services',
          suffixText: 'km',
          hintText: 'e.g. 5,000',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final interval = int.tryParse(_controller.text.trim());
    if (interval == null || interval <= 0) {
      setState(() => _errorText = 'Enter a number greater than 0');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.state.setServiceInterval(
        vehicleId: widget.vehicleId,
        interval: interval,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText = 'Could not save service interval: $error';
          _isSaving = false;
        });
      }
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: state.isLoading || _selectedTab > 1
          ? null
          : FloatingActionButton.extended(
              onPressed: _selectedTab == 0
                  ? () => _showAddRecordDialog(context)
                  : () => _showActivityPicker(context),
              backgroundColor: _accent,
              foregroundColor: _background,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _selectedTab == 0 ? 'Add record' : 'Add activity',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                reverseDuration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (_selectedTab) {
                  0 => CustomScrollView(
                    key: const ValueKey('garage-page'),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _Header(
                              isSyncing: state.isSyncing,
                              onSync: () =>
                                  context.read<AppState>().syncWithCloud(),
                              onAddVehicle: state.canAddVehicle
                                  ? () => showVehicleForm(context)
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.98,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: _VehicleCard(
                                key: ValueKey(state.currentVehicleId),
                                vehicle: _selectedVehicle(state),
                                mileage: state.currentMileage,
                                serviceInterval: state.currentServiceInterval,
                                lastServiceMileage: state.lastServiceMileage,
                                onSetServiceInterval:
                                    state.currentVehicleId == null
                                    ? null
                                    : () => _editServiceInterval(
                                        context,
                                        vehicleId: state.currentVehicleId!,
                                        currentInterval:
                                            state.currentServiceInterval,
                                      ),
                                onEdit: () => state.vehicles.isEmpty
                                    ? showVehicleForm(context)
                                    : showVehicleForm(
                                        context,
                                        vehicle: _selectedVehicle(state),
                                      ),
                              ),
                            ),
                            if (state.vehicles.length > 1) ...[
                              const SizedBox(height: 12),
                              _VehicleSelector(
                                vehicles: state.vehicles,
                                selectedId: state.currentVehicleId,
                                onSelected: (id) =>
                                    context.read<AppState>().selectVehicle(id),
                                onEdit: (vehicle) =>
                                    showVehicleForm(context, vehicle: vehicle),
                                onDelete: (id) =>
                                    _confirmDeleteVehicle(context, id),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _QuickActions(
                              onFuel: () => showActivityForm(context, 'fuel'),
                              onService: () =>
                                  showActivityForm(context, 'service'),
                              onExpense: () =>
                                  showActivityForm(context, 'expense'),
                              onReminder: () =>
                                  showActivityForm(context, 'reminder'),
                            ),
                            const SizedBox(height: 24),
                            _SectionHeading(
                              title: 'Your garage',
                              trailing:
                                  '${state.maintenanceRecords.length} records',
                            ),
                            const SizedBox(height: 12),
                            _QuickStats(records: state.maintenanceRecords),
                            const SizedBox(height: 24),
                            _SectionHeading(
                              title: 'Renewals & service',
                              trailing: '${state.reminders.length} reminders',
                            ),
                            const SizedBox(height: 10),
                            _ReminderPanel(
                              reminders: state.reminders,
                              vehicles: state.vehicles,
                              onAdd: () =>
                                  showActivityForm(context, 'reminder'),
                            ),
                            const SizedBox(height: 28),
                            _SectionHeading(
                              title: 'Service forecast',
                              trailing: state.isSyncing
                                  ? 'Updating'
                                  : 'Vehicle estimate',
                            ),
                            const SizedBox(height: 12),
                            _InsightCard(
                              prediction: state.prediction,
                              syncMessage: state.cloudSyncMessage,
                              isSyncing: state.isSyncing,
                              onSync: () =>
                                  context.read<AppState>().syncWithCloud(),
                            ),
                            const SizedBox(height: 28),
                            _SectionHeading(
                              title: 'Maintenance spend',
                              trailing: _formatCurrency(
                                _totalSpend(state.maintenanceRecords),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ExpenseCard(records: state.maintenanceRecords),
                            const SizedBox(height: 28),
                            _SectionHeading(
                              title: 'Recent activity',
                              trailing:
                                  '${state.maintenanceRecords.length} entries',
                            ),
                            const SizedBox(height: 12),
                            if (state.maintenanceRecords.isEmpty)
                              const _EmptyRecords()
                            else
                              ...state.maintenanceRecords
                                  .take(10)
                                  .map(
                                    (record) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _MaintenanceTile(
                                        record: record,
                                        onDismissed: () => context
                                            .read<AppState>()
                                            .deleteRecord(record['id'] as int),
                                      ),
                                    ),
                                  ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  1 => const TimelineTab(),
                  2 => const AnalyticsTab(),
                  _ => const DocumentVaultTab(),
                },
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        backgroundColor: _surface,
        indicatorColor: _accent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.garage_outlined),
            selectedIcon: Icon(Icons.garage_rounded),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_rounded),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Documents',
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRecordDialog(BuildContext context) async {
    final record = await showDialog<_MaintenanceFormResult>(
      context: context,
      builder: (context) => const _AddMaintenanceDialog(),
    );
    if (record == null || !context.mounted) return;

    await context.read<AppState>().addRecord(
      title: record.title,
      date: record.date,
      cost: record.cost,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Maintenance record added')));
  }

  Future<void> _showActivityPicker(BuildContext context) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActivityChoice(
              icon: Icons.local_gas_station_rounded,
              label: 'Fuel fill',
              value: 'fuel',
            ),
            _ActivityChoice(
              icon: Icons.build_circle_outlined,
              label: 'Service visit',
              value: 'service',
            ),
            _ActivityChoice(
              icon: Icons.receipt_long_rounded,
              label: 'Expense',
              value: 'expense',
            ),
            _ActivityChoice(
              icon: Icons.notifications_active_outlined,
              label: 'Reminder',
              value: 'reminder',
            ),
          ],
        ),
      ),
    );
    if (type != null && context.mounted) await showActivityForm(context, type);
  }

  Future<void> _confirmDeleteVehicle(BuildContext context, int id) async {
    final state = context.read<AppState>();
    if (state.vehicles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep at least one vehicle in your garage'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Remove vehicle?'),
        content: const Text(
          'Its activity, documents and reminders will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      for (final reminder in state.reminders.where(
        (item) => item['vehicle_id'] == id,
      )) {
        await ReminderNotifications.cancel(reminder['id'] as int);
      }
      await state.deleteVehicle(id);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSyncing,
    required this.onSync,
    required this.onAddVehicle,
  });

  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback? onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: const Icon(
            Icons.directions_car_filled_outlined,
            color: _accent,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AutoSphere',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your garage',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: onAddVehicle == null ? 'Maximum 3 vehicles' : 'Add vehicle',
          onPressed: onAddVehicle,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            foregroundColor: _accent,
            fixedSize: const Size(46, 46),
          ),
          icon: const Icon(Icons.add_road_rounded),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Sync with cloud',
          onPressed: isSyncing ? null : onSync,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            foregroundColor: _accent,
            fixedSize: const Size(46, 46),
          ),
          icon: isSyncing
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.sync_rounded),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    super.key,
    required this.vehicle,
    required this.mileage,
    required this.serviceInterval,
    required this.lastServiceMileage,
    required this.onSetServiceInterval,
    required this.onEdit,
  });

  final Map<String, dynamic>? vehicle;
  final int mileage;
  final int serviceInterval;
  final int? lastServiceMileage;
  final VoidCallback? onSetServiceInterval;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final interval = serviceInterval > 0
        ? serviceInterval
        : AppState.defaultServiceInterval;
    final serviceBaseline = lastServiceMileage ?? mileage - mileage % interval;
    final distanceSinceService = mileage >= serviceBaseline
        ? mileage - serviceBaseline
        : 0;
    final distanceIntoInterval = distanceSinceService % interval;
    final progress = distanceIntoInterval / interval;
    final remaining = interval - distanceIntoInterval;
    final nextServiceMileage = mileage + remaining;
    final make = vehicle?['make'] as String? ?? 'Add your first vehicle';
    final model = vehicle?['model'] as String? ?? '';
    final year = vehicle?['year'] as int?;
    final nickname = vehicle?['nickname'] as String?;
    final photo = vehicle?['photo'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _accent.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(12),
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
                      (nickname?.isNotEmpty == true
                              ? nickname!
                              : 'YOUR VEHICLE')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      model.isEmpty ? make : '$make $model',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${year ?? ''}  ·  ${vehicle?['fuel_type'] ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFFE0E8FB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (photo is Uint8List)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    photo,
                    width: 76,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              IconButton(
                tooltip: 'Edit vehicle',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: Color(0xFFE0E8FB),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.speed_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                _formatNumber(mileage),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'KM',
                  style: TextStyle(
                    color: Color(0xFFE0E8FB),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_formatNumber(remaining)} km to service',
                style: const TextStyle(
                  color: Color(0xFFE0E8FB),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Every ${_formatNumber(interval)} km',
                style: const TextStyle(
                  color: Color(0xFFE0E8FB),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Next at ${_formatNumber(nextServiceMileage)} km',
                style: TextStyle(
                  color: Color(0xFFE0E8FB),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSetServiceInterval,
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Set service interval'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic>? _selectedVehicle(AppState state) {
  for (final vehicle in state.vehicles) {
    if (vehicle['id'] == state.currentVehicleId) return vehicle;
  }
  if (state.vehicles.isNotEmpty) return state.vehicles.first;
  return {
    'nickname': 'Hycross',
    'make': 'Toyota',
    'model': 'Innova Hycross',
    'year': 2025,
    'fuel_type': 'Hybrid',
    'registration': 'Last service',
  };
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.selectedId,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> vehicles;
  final int? selectedId;
  final ValueChanged<int> onSelected;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: vehicles.length,
      separatorBuilder: (_, _) => const SizedBox(width: 9),
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final selected = vehicle['id'] == selectedId;
        final photo = vehicle['photo'];
        return InkWell(
          onTap: () => onSelected(vehicle['id'] as int),
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: 174,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF24375E) : _surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? _accent.withValues(alpha: 0.6) : _border,
              ),
            ),
            child: Row(
              children: [
                if (photo is Uint8List)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      photo,
                      width: 40,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(
                    Icons.directions_car_filled_rounded,
                    color: _accent,
                    size: 27,
                  ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['nickname'] as String? ?? 'Vehicle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle['make']} ${vehicle['model']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Vehicle actions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onSelected: (action) => action == 'edit'
                      ? onEdit(vehicle)
                      : onDelete(vehicle['id'] as int),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit vehicle')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove vehicle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onFuel,
    required this.onService,
    required this.onExpense,
    required this.onReminder,
  });

  final VoidCallback onFuel;
  final VoidCallback onService;
  final VoidCallback onExpense;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _QuickAction(
        icon: Icons.local_gas_station_rounded,
        label: 'Fuel',
        onPressed: onFuel,
      ),
      _QuickAction(
        icon: Icons.build_circle_outlined,
        label: 'Service',
        onPressed: onService,
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Expense',
        onPressed: onExpense,
      ),
      _QuickAction(
        icon: Icons.notifications_active_outlined,
        label: 'Reminder',
        onPressed: onReminder,
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        IconButton.filledTonal(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          style: IconButton.styleFrom(
            backgroundColor: _surfaceRaised,
            foregroundColor: _accent,
            fixedSize: const Size(46, 46),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ActivityChoice extends StatelessWidget {
  const _ActivityChoice({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: _accent),
    title: Text(label),
    onTap: () => Navigator.pop(context, value),
  );
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final spend = _totalSpend(records);
    final serviceCount = records.where((record) {
      final title = (record['title'] as String? ?? '').toLowerCase();
      return title.contains('service') || title.contains('maintenance');
    }).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'TOTAL SPEND',
            value: _formatCurrency(spend),
            tint: _accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.build_circle_outlined,
            label: 'SERVICES',
            value: '$serviceCount',
            tint: _amber,
          ),
        ),
      ],
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  const _ReminderPanel({
    required this.reminders,
    required this.vehicles,
    required this.onAdd,
  });

  final List<Map<String, dynamic>> reminders;
  final List<Map<String, dynamic>> vehicles;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'No due dates saved',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add reminder'),
            ),
          ],
        ),
      );
    }

    final vehicleNames = {
      for (final vehicle in vehicles) vehicle['id']: vehicle['nickname'],
    };
    final visible = reminders.take(3);
    return Column(
      children: visible.map((reminder) {
        final dueDate = DateTime.tryParse(
          reminder['due_date'] as String? ?? '',
        );
        final days = dueDate == null
            ? null
            : DateTime(
                dueDate.year,
                dueDate.month,
                dueDate.day,
              ).difference(DateTime.now()).inDays;
        final subtitle = days == null
            ? (reminder['due_date'] as String? ?? '')
            : days < 0
            ? 'Overdue · ${vehicleNames[reminder['vehicle_id']] ?? 'Vehicle'}'
            : days == 0
            ? 'Due today · ${vehicleNames[reminder['vehicle_id']] ?? 'Vehicle'}'
            : 'In $days days · ${vehicleNames[reminder['vehicle_id']] ?? 'Vehicle'}';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: _amber,
              size: 20,
            ),
            title: Text(
              reminder['title'] as String? ?? 'Vehicle reminder',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
            trailing: IconButton(
              tooltip: 'Delete reminder',
              onPressed: () async {
                final id = reminder['id'] as int;
                final state = context.read<AppState>();
                await ReminderNotifications.cancel(id);
                await state.deleteReminder(id);
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              color: _muted,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 16),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.prediction,
    required this.syncMessage,
    required this.isSyncing,
    required this.onSync,
  });

  final Map<String, dynamic>? prediction;
  final String? syncMessage;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final serviceType = prediction?['service_type']?.toString();
    final message = prediction?['message']?.toString();
    final predictedDate = prediction?['predicted_date']?.toString();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: _accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceType?.isNotEmpty == true
                      ? serviceType!
                      : 'Maintenance estimate',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    message?.isNotEmpty == true
                        ? message!
                        : syncMessage ??
                              'Sync service records to estimate your next visit.',
                    if (predictedDate != null && predictedDate.isNotEmpty)
                      'Predicted date: $predictedDate',
                  ].join('\n'),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                if (prediction == null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: isSyncing ? null : onSync,
                    style: TextButton.styleFrom(
                      foregroundColor: _accent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.cloud_sync_rounded, size: 16),
                    label: Text(
                      isSyncing
                          ? 'Syncing service records…'
                          : 'Sync service history',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final buckets = _monthlySpend(records);
    final maxSpend = buckets.fold<double>(
      0,
      (maximum, bucket) => bucket.amount > maximum ? bucket.amount : maximum,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Your maintenance costs, month by month.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${records.length} entries',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((bucket) {
                final fraction = maxSpend == 0 ? 0.0 : bucket.amount / maxSpend;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (bucket.amount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatCurrency(bucket.amount),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: bucket.amount == 0
                                  ? 0.025
                                  : (0.12 + fraction * 0.88),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bucket.amount == 0
                                      ? _surfaceRaised
                                      : _accent.withValues(
                                          alpha: 0.45 + fraction * 0.55,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          bucket.label,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceTile extends StatelessWidget {
  const _MaintenanceTile({required this.record, required this.onDismissed});

  final Map<String, dynamic> record;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final title = record['title'] as String? ?? 'Maintenance record';
    final date = record['date'] as String? ?? '';
    final cost = (record['cost'] as num?)?.toDouble() ?? 0;

    return Dismissible(
      key: ValueKey(record['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _coral,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _surfaceRaised,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.build_rounded, color: _accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cost == 0 ? '—' : _formatCurrency(cost),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: _muted, size: 27),
          SizedBox(height: 9),
          Text(
            'No service records yet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Add your first record to start tracking your car.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _MonthlySpend {
  const _MonthlySpend(this.label, this.amount);

  final String label;
  final double amount;
}

List<_MonthlySpend> _monthlySpend(List<Map<String, dynamic>> records) {
  final now = DateTime.now();
  final months = List.generate(
    6,
    (index) => DateTime(now.year, now.month - 5 + index),
  );
  final amounts = <String, double>{
    for (final month in months) '${month.year}-${month.month}': 0,
  };

  for (final record in records) {
    final date = DateTime.tryParse(record['date'] as String? ?? '');
    if (date == null) continue;
    final key = '${date.year}-${date.month}';
    if (!amounts.containsKey(key)) continue;
    amounts[key] = amounts[key]! + ((record['cost'] as num?)?.toDouble() ?? 0);
  }

  const monthNames = [
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
  return months
      .map(
        (month) => _MonthlySpend(
          monthNames[month.month - 1],
          amounts['${month.year}-${month.month}'] ?? 0,
        ),
      )
      .toList();
}

double _totalSpend(List<Map<String, dynamic>> records) => records.fold<double>(
  0,
  (total, record) => total + ((record['cost'] as num?)?.toDouble() ?? 0),
);

String _formatCurrency(num value) {
  final rounded = value.round();
  final digits = rounded.toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '₹$grouped';
}

String _formatNumber(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

String _formatDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  const monthNames = [
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
  return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

class _MaintenanceFormResult {
  const _MaintenanceFormResult({
    required this.title,
    required this.date,
    required this.cost,
  });

  final String title;
  final String date;
  final double cost;
}

class _AddMaintenanceDialog extends StatefulWidget {
  const _AddMaintenanceDialog();

  @override
  State<_AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<_AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      title: const Text('Add maintenance record'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Service or repair',
                hintText: 'e.g. Periodic service',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cost',
                prefixText: '₹ ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final cost = double.tryParse(value.trim());
                if (cost == null || !cost.isFinite || cost < 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded, color: _accent),
              title: const Text('Service date', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                _formatDate(_date.toIso8601String()),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              onTap: _chooseDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _background,
          ),
          child: const Text('Save record'),
        ),
      ],
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final cost = double.tryParse(_costController.text.trim()) ?? 0;
    final date =
        '${_date.year.toString().padLeft(4, '0')}-'
        '${_date.month.toString().padLeft(2, '0')}-'
        '${_date.day.toString().padLeft(2, '0')}';
    Navigator.pop(
      context,
      _MaintenanceFormResult(
        title: _titleController.text.trim(),
        date: date,
        cost: cost,
      ),
    );
  }
}

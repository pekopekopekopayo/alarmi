import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class ScheduleScreen extends StatefulWidget {
  final DateTime selectedDate;

  const ScheduleScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Schedule> _schedules = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay? _selectedTime;
  late SharedPreferences _prefs;
  bool _isLoading = true;
  ScheduleStatus? _statusFilter;

  Color getStatusColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.waiting:
        return Colors.grey[100]!;
      case ScheduleStatus.inProgress:
        return Colors.blue[100]!;
      case ScheduleStatus.completed:
        return Colors.green[100]!;
    }
  }

  Icon getStatusIcon(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.waiting:
        return const Icon(Icons.schedule, color: Colors.grey);
      case ScheduleStatus.inProgress:
        return const Icon(Icons.play_circle, color: Colors.blue);
      case ScheduleStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }

  String getStatusText(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.waiting:
        return '대기';
      case ScheduleStatus.inProgress:
        return '진행중';
      case ScheduleStatus.completed:
        return '완료';
    }
  }

  List<Schedule> get filteredSchedules {
    if (_statusFilter == null) return _schedules;
    return _schedules.where((s) => s.status == _statusFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodTextStyle: const TextStyle(fontSize: 12),
              hourMinuteTextStyle: const TextStyle(fontSize: 48),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _loadSchedules() async {
    _prefs = await SharedPreferences.getInstance();
    final schedulesJson = _prefs.getString('schedules') ?? '[]';
    final List<dynamic> decodedList = json.decode(schedulesJson);

    setState(() {
      _schedules = decodedList
          .map((item) => Schedule.fromJson(item))
          .where((schedule) =>
              schedule.date.year == widget.selectedDate.year &&
              schedule.date.month == widget.selectedDate.month &&
              schedule.date.day == widget.selectedDate.day)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _saveSchedules() async {
    final schedulesJson = _prefs.getString('schedules') ?? '[]';
    final List<dynamic> allSchedules = json.decode(schedulesJson);

    final otherDates = allSchedules
        .map((item) => Schedule.fromJson(item))
        .where((schedule) =>
            schedule.date.year != widget.selectedDate.year ||
            schedule.date.month != widget.selectedDate.month ||
            schedule.date.day != widget.selectedDate.day)
        .toList();

    final allSchedulesList = [...otherDates, ..._schedules];

    await _prefs.setString(
      'schedules',
      json.encode(allSchedulesList.map((s) => s.toJson()).toList()),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedTime = null;
  }

  void _addSchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${DateFormat('yyyy년 M월 d일', 'ko_KR').format(widget.selectedDate)} 스케줄 추가',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '설명',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      await _selectTime(context);
                      setModalState(() {});
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '시간',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.access_time,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _formatTimeOfDay(_selectedTime)
                            : '시간을 선택하세요',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedTime == null || _titleController.text.isEmpty
                        ? null
                        : () async {
                            setState(() {
                              _schedules.add(
                                Schedule(
                                  id: DateTime.now().toString(),
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  date: widget.selectedDate,
                                  time: _formatTimeOfDay(_selectedTime),
                                ),
                              );
                            });
                            await _saveSchedules();
                            _resetForm();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: const Text('추가'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final schedules = filteredSchedules;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('yyyy년 M월 d일', 'ko_KR').format(widget.selectedDate),
        ),
        actions: [
          PopupMenuButton<ScheduleStatus?>(
            icon: const Icon(Icons.filter_list),
            initialValue: _statusFilter,
            onSelected: (status) {
              setState(() {
                _statusFilter = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('전체'),
              ),
              ...ScheduleStatus.values.map((status) => PopupMenuItem(
                value: status,
                child: Text(getStatusText(status)),
              )),
            ],
          ),
        ],
      ),
      body: schedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '스케줄이 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addSchedule,
                    child: const Text('스케줄 추가'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: schedules.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return Dismissible(
                  key: Key(schedule.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    setState(() {
                      _schedules.removeWhere((s) => s.id == schedule.id);
                    });
                    await _saveSchedules();
                  },
                  child: Card(
                    color: getStatusColor(schedule.status),
                    child: ListTile(
                      leading: getStatusIcon(schedule.status),
                      title: Text(schedule.title),
                      subtitle: Text(schedule.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            schedule.time,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<ScheduleStatus>(
                            initialValue: schedule.status,
                            onSelected: (ScheduleStatus status) async {
                              setState(() {
                                _schedules[_schedules.indexWhere((s) => s.id == schedule.id)] =
                                    schedule.copyWith(status: status);
                              });
                              await _saveSchedules();
                            },
                            itemBuilder: (BuildContext context) =>
                                ScheduleStatus.values.map((status) => PopupMenuItem<ScheduleStatus>(
                                  value: status,
                                  child: Row(
                                    children: [
                                      getStatusIcon(status),
                                      const SizedBox(width: 8),
                                      Text(getStatusText(status)),
                                    ],
                                  ),
                                )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSchedule,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

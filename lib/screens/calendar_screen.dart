import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'schedule_screen.dart';
import '../models/schedule.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late PageController _pageController;
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  final int _initialPage = 1000;
  Map<String, List<Schedule>> _schedules = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _pageController = PageController(initialPage: _initialPage);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getString('schedules') ?? '[]';
    final List<dynamic> decodedList = json.decode(schedulesJson);

    final Map<String, List<Schedule>> scheduleMap = {};
    for (var item in decodedList) {
      final schedule = Schedule.fromJson(item);
      final dateKey = DateFormat('yyyy-MM-dd').format(schedule.date);
      if (!scheduleMap.containsKey(dateKey)) {
        scheduleMap[dateKey] = [];
      }
      scheduleMap[dateKey]!.add(schedule);
    }

    if (mounted) {
      setState(() {
        _schedules = scheduleMap;
        _isLoading = false;
      });
    }
  }

  List<Schedule> _getSchedulesForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _schedules[dateKey] ?? [];
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final firstWeekDay = firstDayOfMonth.weekday;
    final daysBeforeMonth = firstWeekDay == 7 ? 0 : 7 - (7 - firstWeekDay);
    final firstToDisplay = firstDayOfMonth.subtract(Duration(days: daysBeforeMonth));

    final lastWeekDay = lastDayOfMonth.weekday;
    final daysAfterMonth = lastWeekDay == 7 ? 6 : 6 - lastWeekDay;
    final lastToDisplay = lastDayOfMonth.add(Duration(days: daysAfterMonth));

    final days = <DateTime>[];
    var currentDay = firstToDisplay;

    while (!currentDay.isAfter(lastToDisplay)) {
      days.add(currentDay);
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return days;
  }

  DateTime _getMonthFromIndex(int index) {
    final difference = index - _initialPage;
    final month = DateTime(
      _selectedDate.year,
      _selectedDate.month + difference,
    );
    return DateTime(month.year, month.month);
  }

  void _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
    });

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleScreen(selectedDate: date),
      ),
    );

    if (result == true && mounted) {
      await _loadSchedules();
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Color _getScheduleColor(List<Schedule> schedules) {
    if (schedules.isEmpty) return Colors.transparent;

    bool hasWaiting = schedules.any((s) => s.status == ScheduleStatus.waiting);
    bool hasInProgress = schedules.any((s) => s.status == ScheduleStatus.inProgress);
    bool hasCompleted = schedules.any((s) => s.status == ScheduleStatus.completed);

    if (hasWaiting) {
      return Colors.grey.withOpacity(0.5); // 대기 상태가 하나라도 있으면 회색
    } else if (hasInProgress) {
      return Colors.blue.withOpacity(0.5); // 진행중이 있으면 파란색
    } else if (hasCompleted) {
      return Colors.green.withOpacity(0.5); // 완료만 있으면 초록색
    }

    return Colors.transparent;
  }

  Widget _buildDayCell(DateTime date, DateTime month) {
    final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isCurrentMonth = date.month == month.month;
    final isSunday = date.weekday == 7;
    final isSaturday = date.weekday == 6;

    final schedules = _getSchedulesForDate(date);
    final hasSchedules = schedules.isNotEmpty;
    final scheduleColor = _getScheduleColor(schedules);

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isToday
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : scheduleColor,
          borderRadius: BorderRadius.circular(16),
          border: isToday && !isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : hasSchedules && !isSelected
                  ? Border.all(
                      color: scheduleColor.withOpacity(1),
                      width: 2,
                    )
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : !isCurrentMonth
                        ? Colors.grey.withOpacity(0.5)
                        : isSunday
                            ? Colors.red
                            : isSaturday
                                ? Colors.blue
                                : isToday
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                fontSize: 24,
                fontWeight: isToday || isSelected ? FontWeight.bold : null,
              ),
            ),
            if (hasSchedules && !isSelected) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheduleColor.withOpacity(1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (schedules.length > 1) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheduleColor.withOpacity(1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (hasSchedules) ...[
              const SizedBox(height: 6),
              Text(
                schedules.map((s) => s.time).join(', '),
                style: TextStyle(
                  color: isSelected ? Colors.white : scheduleColor.withOpacity(1),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['일', '월', '화', '수', '목', '금', '토']
            .map((day) => SizedBox(
                  width: 52,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: {
                        '일': Colors.red,
                        '토': Colors.blue,
                      }[day] ?? Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ))
            .toList(),
      ),
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

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('종료'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            DateFormat('yyyy년 M월', 'ko_KR').format(_currentMonth),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 32,
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              iconSize: 32,
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildWeekdayHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentMonth = _getMonthFromIndex(index);
                      });
                    },
                    itemBuilder: (context, index) {
                      final month = _getMonthFromIndex(index);
                      final days = _getDaysInMonth(month);
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) => _buildDayCell(days[index], month),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

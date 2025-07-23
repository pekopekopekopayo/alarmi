import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'schedule_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _pageController = PageController(initialPage: _initialPage);
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

    // 스케줄 화면에서 돌아왔을 때 상태 갱신
    if (result == true && mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Widget _buildDayCell(DateTime date, DateTime month) {
    final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isCurrentMonth = date.month == month.month;
    final isSunday = date.weekday == 7;
    final isSaturday = date.weekday == 6;

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isToday
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: Theme.of(context).primaryColor)
              : null,
        ),
        child: Center(
          child: Text(
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
              fontSize: 16,
              fontWeight: isToday || isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['일', '월', '화', '수', '목', '금', '토']
            .map((day) => SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: {
                        '일': Colors.red,
                        '토': Colors.blue,
                      }[day] ?? Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 앱 종료 확인 다이얼로그
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemCount: days.length,
                      itemBuilder: (context, index) => _buildDayCell(days[index], month),
                    );
                  },
                ),
              ),
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

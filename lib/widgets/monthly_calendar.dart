import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/schedule_screen.dart';

class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({super.key});

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
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
    // 해당 월의 첫 날
    final firstDayOfMonth = DateTime(month.year, month.month, 1);

    // 해당 월의 마지막 날
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // 첫 주의 시작일 (이전 달의 날짜들)
    final firstWeekDay = firstDayOfMonth.weekday;
    final daysBeforeMonth = firstWeekDay == 7 ? 0 : 7 - (7 - firstWeekDay);
    final firstToDisplay = firstDayOfMonth.subtract(Duration(days: daysBeforeMonth));

    // 마지막 주의 마지막일 (다음 달의 날짜들)
    final lastWeekDay = lastDayOfMonth.weekday;
    final daysAfterMonth = lastWeekDay == 7 ? 6 : 6 - lastWeekDay;
    final lastToDisplay = lastDayOfMonth.add(Duration(days: daysAfterMonth));

    final days = <DateTime>[];
    var currentDay = firstToDisplay;

    // 첫 날부터 마지막 날까지 모든 날짜를 추가
    while (!currentDay.isAfter(lastToDisplay)) {
      days.add(currentDay);
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return days;
  }

  DateTime _getMonthFromIndex(int index) {
    final difference = index - _initialPage;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month + difference,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              Text(
                DateFormat('yyyy년 M월', 'ko_KR').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        ),
        Row(
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
        const SizedBox(height: 8),
        SizedBox(
          height: 320,
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
                  childAspectRatio: 1,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(_selectedDate);
                  final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final isCurrentMonth = date.month == month.month;
                  final isSunday = date.weekday == 7;
                  final isSaturday = date.weekday == 6;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleScreen(
                            selectedDate: date,
                          ),
                        ),
                      );
                    },
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
                            fontWeight:
                                isToday || isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

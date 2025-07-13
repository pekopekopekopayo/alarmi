import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/schedule_screen.dart';

class WeeklyCalendar extends StatefulWidget {
  const WeeklyCalendar({super.key});

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  late PageController _pageController;
  late DateTime _selectedDate;
  late List<DateTime> _currentWeek;
  final int _initialPage = 1000;
  late String _currentMonthYear;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _pageController = PageController(initialPage: _initialPage);
    _currentWeek = _getWeekDays(_selectedDate);
    _currentMonthYear = _getMonthYearText(_currentWeek);
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  List<DateTime> _getWeekFromIndex(int index) {
    final difference = index - _initialPage;
    final DateTime startDate = DateTime.now().add(Duration(days: difference * 7));
    return _getWeekDays(startDate);
  }

  String _getMonthYearText(List<DateTime> week) {
    // 각 월의 출현 횟수를 계산
    Map<int, int> monthCount = {};
    for (var date in week) {
      monthCount[date.month] = (monthCount[date.month] ?? 0) + 1;
    }

    // 가장 많이 등장한 월을 찾음
    int mostFrequentMonth = week[0].month;
    int maxCount = monthCount[mostFrequentMonth] ?? 0;

    monthCount.forEach((month, count) {
      if (count > maxCount) {
        mostFrequentMonth = month;
        maxCount = count;
      }
    });

    // 해당 월이 속한 년도 찾기
    DateTime representativeDate = week.firstWhere((date) => date.month == mostFrequentMonth);
    return '${DateFormat('yyyy년 M월', 'ko_KR').format(representativeDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _currentMonthYear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentWeek = _getWeekFromIndex(index);
                _selectedDate = _currentWeek[_selectedDate.weekday - 1];
                _currentMonthYear = _getMonthYearText(_currentWeek);
              });
            },
            itemBuilder: (context, index) {
              final weekDays = _getWeekFromIndex(index);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weekDays.map((date) {
                  bool isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(_selectedDate);
                  bool isToday = DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
                  bool isCurrentMonth = date.month == weekDays[weekDays.length ~/ 2].month;

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
                      width: 45,
                      decoration: BoxDecoration(
                        color: isSelected
                          ? Theme.of(context).primaryColor
                          : isToday
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                          ? Border.all(color: Theme.of(context).primaryColor)
                          : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('E', 'ko_KR').format(date),
                            style: TextStyle(
                              color: isSelected
                                ? Colors.white
                                : !isCurrentMonth
                                  ? Colors.grey.withOpacity(0.5)
                                  : isToday
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected
                                ? Colors.white
                                : !isCurrentMonth
                                  ? Colors.grey.withOpacity(0.5)
                                  : isToday
                                    ? Theme.of(context).primaryColor
                                    : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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

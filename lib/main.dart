import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weekly Schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WeeklyScheduleScreen(),
    );
  }
}

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final PageController _pageController = PageController();
  late DateTime _selectedDate;
  late List<List<DateTime>> _weeks;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weeks = _generateWeeks();
  }

  List<List<DateTime>> _generateWeeks() {
    final List<List<DateTime>> weeks = [];
    final now = DateTime.now();

    // 현재 주를 포함하여 전후 10주씩 생성
    for (int i = -10; i <= 10; i++) {
      final week = <DateTime>[];
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: 7 * i));

      for (int j = 0; j < 7; j++) {
        week.add(firstDayOfWeek.add(Duration(days: j)));
      }
      weeks.add(week);
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주간 스케줄'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _weeks.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedDate = _weeks[index][0];
                });
              },
              itemBuilder: (context, index) {
                return WeekView(dates: _weeks[index], selectedDate: _selectedDate);
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '선택된 날짜: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekView extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;

  const WeekView({
    super.key,
    required this.dates,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dates.map((date) {
        final isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E', 'ko_KR').format(date),
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

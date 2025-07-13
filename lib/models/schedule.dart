enum ScheduleStatus {
  waiting,    // 대기
  inProgress, // 진행중
  completed   // 완료
}

class Schedule {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final ScheduleStatus status;

  Schedule({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.status = ScheduleStatus.waiting,
  });

  Schedule copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    ScheduleStatus? status,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'status': status.toString(),
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      status: ScheduleStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ScheduleStatus.waiting,
      ),
    );
  }
}

class Quarter {
  String id;
  String name = "";
  DateTime firstDayOfClasses = DateTime.now();
  DateTime lastDayOfClasses = DateTime.now();
  List<DateTime> weeks = [];

  Quarter({required this.id}) {
    name = getName(id);
  }

  getName(String id) {
    switch (id[3]) {
      case "1":
        return "Winter ${id.substring(0, 3)}";
      case "2":
        return "Spring ${id.substring(0, 3)}";
      case "3":
        return "Summer ${id.substring(0, 3)}";
      case "4":
        return "Fall ${id.substring(0, 3)}";
      default:
        return "Unknown";
    }
  }

  getWeek(DateTime date) {
    int week = -1;
    for (int i = 0; i < weeks.length; i++) {
      if (date.isAfter(weeks[i]) && date.isBefore(weeks[i + 1])) {
        week = i;
        break;
      }
    }
    return week;
  }

  @override
  String toString() {
    return name;
  }
}
class Quarter {
  String id = "";
  String name = "";
  DateTime firstDayOfClasses = DateTime.now();
  DateTime lastDayOfClasses = DateTime.now();
  DateTime firstDayOfFinals = DateTime.now();
  DateTime lastDayOfFinals = DateTime.now();
  List<DateTime> weeks = [];

  Quarter({required this.id}) {
    name = getName(id);
  }

  Quarter.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    name = json["name"] ?? "";
    firstDayOfClasses = DateTime.tryParse(json["firstDayOfClasses"]) ?? DateTime.now();
    lastDayOfClasses = DateTime.tryParse(json["lastDayOfClasses"]) ?? DateTime.now();
    firstDayOfFinals = DateTime.tryParse(json["firstDayOfFinals"]) ?? DateTime.now();
    lastDayOfFinals = DateTime.tryParse(json["lastDayOfFinals"]) ?? DateTime.now();
    if (json["weeks"] != null) {
      for (int i = 0; i < json["weeks"].length; i++) {
        weeks.add(DateTime.parse(json["weeks"][i]));
      }
    }
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

  // Helper function to return the week of the quarter given a date
  // Returns -1 if the date is not in the quarter and 11 if it is in finals week
  int getWeek(DateTime date) {
    int week = -1;
    if (date.isAfter(lastDayOfFinals)) {
      week = -1;
    }
    else if (date.isAfter(firstDayOfFinals)) {
      week = 11;
    }
    else {
      for (int i = 0; i < weeks.length; i++) {
        if (date.isAfter(weeks[i])) {
          week = i;
        }
      }
    }
    return week;
  }

  @override
  String toString() {
    return name;
  }
}
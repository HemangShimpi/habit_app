import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Habit {
  int? id;
  String title;

  Habit({this.id, required this.title});

  factory Habit.fromMap(Map<String, dynamic> json) =>
      Habit(id: json["id"], title: json["title"]);

  Map<String, dynamic> toMap() {
    return {"id": id, "title": title};
  }
}

class HabitStatus {
  int? id;
  int habitId;
  String date;
  int isCompleted;
  int streak;

  HabitStatus({
    this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    required this.streak,
  });

  factory HabitStatus.fromMap(Map<String, dynamic> json) => HabitStatus(
    id: json["id"],
    habitId: json["habitId"],
    date: json["date"],
    isCompleted: json["isCompleted"],
    streak: json["streak"],
  );

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "habitId": habitId,
      "date": date,
      "isCompleted": isCompleted,
      "streak": streak,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "habits.db");
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        streak INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits(id)
      )
    ''');
  }


  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert("habits", habit.toMap());
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    var res = await db.query("habits");
    List<Habit> list =
    res.isNotEmpty ? res.map((c) => Habit.fromMap(c)).toList() : [];
    return list;
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      "habits",
      habit.toMap(),
      where: "id = ?",
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete("habits", where: "id = ?", whereArgs: [id]);
  }



  Future<HabitStatus?> getHabitStatus(int habitId, String date) async {
    final db = await database;
    var res = await db.query(
      "habit_status",
      where: "habitId = ? AND date = ?",
      whereArgs: [habitId, date],
    );
    if (res.isNotEmpty) {
      return HabitStatus.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertHabitStatus(HabitStatus status) async {
    final db = await database;
    return await db.insert("habit_status", status.toMap());
  }

  Future<int> updateHabitStatus(HabitStatus status) async {
    final db = await database;
    return await db.update(
      "habit_status",
      status.toMap(),
      where: "id = ?",
      whereArgs: [status.id],
    );
  }

  Future<void> toggleHabitStatus(
      int habitId,
      String date,
      bool isCompleted,
      ) async {
    HabitStatus? status = await getHabitStatus(habitId, date);
    if (isCompleted) {
      DateTime currentDate = DateTime.parse(date);
      DateTime previousDate = currentDate.subtract(Duration(days: 1));
      String previousDateStr =
      previousDate.toIso8601String().split('T')[0]; // "yyyy-MM-dd"
      HabitStatus? previousStatus = await getHabitStatus(
        habitId,
        previousDateStr,
      );
      int streak =
      (previousStatus != null && previousStatus.isCompleted == 1)
          ? previousStatus.streak + 1
          : 1;
      if (status != null) {
        status.isCompleted = 1;
        status.streak = streak;
        await updateHabitStatus(status);
      } else {
        HabitStatus newStatus = HabitStatus(
          habitId: habitId,
          date: date,
          isCompleted: 1,
          streak: streak,
        );
        await insertHabitStatus(newStatus);
      }
    } else {
      if (status != null) {
        status.isCompleted = 0;
        status.streak = 0;
        await updateHabitStatus(status);
      } else {
        HabitStatus newStatus = HabitStatus(
          habitId: habitId,
          date: date,
          isCompleted: 0,
          streak: 0,
        );
        await insertHabitStatus(newStatus);
      }
    }
  }

  Future<List<HabitStatus>> getHabitStatusesForDate(String date) async {
    final db = await database;
    var res = await db.query(
      "habit_status",
      where: "date = ?",
      whereArgs: [date],
    );
    List<HabitStatus> list =
    res.isNotEmpty ? res.map((c) => HabitStatus.fromMap(c)).toList() : [];
    return list;
  }

  Future<int> updateHabitStreak(int habitId, String date, int newStreak) async {
    final db = await database;

    HabitStatus? existingStatus = await getHabitStatus(habitId, date);
    if (existingStatus != null) {
      existingStatus.streak = newStreak;
      return await updateHabitStatus(existingStatus);
    } else {
      HabitStatus newStatus = HabitStatus(
        habitId: habitId,
        date: date,
        isCompleted:
        0,
        streak: newStreak,
      );
      return await insertHabitStatus(newStatus);
    }
  }

  Future<int> deleteHabitStatus(int id) async {
    final db = await database;
    return await db.delete("habit_status", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteAllHabitStatuses() async {
    final db = await database;
    await db.delete("habit_status");
  }

  Future<void> deleteAllHabits() async {
    final db = await database;
    await db.delete("habits");
  }
}
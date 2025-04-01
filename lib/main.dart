import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> habits = ['Drink Water', 'Exercise', 'Read Book'];
  DateTime selectedDate = DateTime.now();

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _addHabit() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Habit"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Habit title"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  habits.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text("Habit Tracker for $formattedDate"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (_, index) {
          return ListTile(
            title: Text(habits[index]),
            leading: Checkbox(
              value: false,
              onChanged: (value) {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:path/path.dart' hide context;
import 'package:sqflite/sqflite.dart';

class Student {
  final int? id;
  final String name;
  final String regNo;
  final String department;

  Student({
    this.id,
    required this.name,
    required this.regNo,
    required this.department,
  });

  Map<String, dynamic> toMap() =>
      {'name': name, 'regNo': regNo, 'department': department};

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as int,
        name: m['name'] as String,
        regNo: m['regNo'] as String,
        department: m['department'] as String,
      );
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'students.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE students('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, '
            'regNo TEXT NOT NULL, '
            'department TEXT NOT NULL)');
      },
    );
  }

  // CREATE
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return db.insert('students', s.toMap());
  }

  // READ
  Future<List<Student>> getStudents() async {
    final db = await database;
    final rows = await db.query('students', orderBy: 'id DESC');
    return rows.map(Student.fromMap).toList();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Records',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _deptController = TextEditingController();
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final data = await DatabaseHelper.instance.getStudents();
    setState(() => _students = data);
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    await DatabaseHelper.instance.insertStudent(Student(
      name: _nameController.text.trim(),
      regNo: _regController.text.trim(),
      department: _deptController.text.trim(),
    ));
    _nameController.clear();
    _regController.clear();
    _deptController.clear();
    await _loadStudents();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Student saved')));
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Records (SQLite)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Student Name', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regController,
                  decoration: const InputDecoration(
                      labelText: 'Register Number',
                      border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deptController,
                  decoration: const InputDecoration(
                      labelText: 'Department', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveStudent,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Student'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Stored Students (${_students.length})',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ..._students.map((s) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(s.name[0].toUpperCase())),
                  title: Text(s.name),
                  subtitle: Text('${s.regNo}  |  ${s.department}'),
                ),
              )),
        ],
      ),
    );
  }
}

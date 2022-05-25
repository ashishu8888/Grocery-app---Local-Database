import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _selectedID;
  final txt = TextEditingController();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(controller: txt),
        ),
        body: Center(
          child: FutureBuilder<List<Grocery>>(
              future: DatabaseHelper.instance.getGroceries(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Grocery>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Text('Loading...'),
                  );
                }
                return ListView(
                  children: snapshot.data!.map((grocery) {
                    return Center(
                      child: ListTile(
                        title: Text(grocery.name!),
                        onLongPress: () {
                          setState(() {
                            DatabaseHelper.instance.remove(grocery.id!);
                          });
                        },
                        onTap: () {
                          setState(() {
                            txt.text = grocery.name!;
                            _selectedID = grocery.id!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              }),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () async {
              _selectedID != null
                  ? await DatabaseHelper.instance.update(
                      Grocery(id: _selectedID, name: txt.text),
                    )
                  : await DatabaseHelper.instance.add(Grocery(name: txt.text));

              setState(() {
                txt.clear();
              });
            },
            child: Icon(Icons.save)),
      ),
    );
  }
}

class Grocery {
  int? id;
  String? name;

  Grocery({this.id, this.name});

  factory Grocery.fromMap(Map<String, dynamic> json) {
    return Grocery(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'Grocery.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
        ''' CREATE TABLE groceries(id INTEGER PRIMARY KEY,name TEXT)''');
  }

  Future<List<Grocery>> getGroceries() async {
    Database db = await instance.database;

    var groceries = await db.query('groceries', orderBy: 'name');

    List<Grocery> groceryList = groceries.isNotEmpty
        ? groceries.map((c) => Grocery.fromMap(c)).toList()
        : [];
    return groceryList;
  }

  Future<int> add(Grocery grocery) async {
    Database db = await instance.database;
    return await db.insert('groceries', grocery.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;

    return await db.delete('groceries', where: 'id =?', whereArgs: [id]);
  }

  Future<int> update(Grocery grocery) async {
    Database db = await instance.database;
    return await db.update('groceries', grocery.toMap(),
        where: 'id = ?', whereArgs: [grocery.id]);
  }
}

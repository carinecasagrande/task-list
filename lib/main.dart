import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  Color colorDelete = const Color.fromRGBO(188, 65, 43, 1);
  Color colorAccent = const Color.fromRGBO(5, 168, 170, 1);
  Color colorSecondary = const Color.fromRGBO(186, 186, 186, 1);

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedIndex;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  void _addToDo() {
    String text = _toDoController.text;
    if (text.trim() != '') {
      setState(() {
        Map<String, dynamic> newToDo = {};
        newToDo["title"] = _toDoController.text;
        newToDo["ok"] = false;
        _toDoController.text = '';
        _toDoList.add(newToDo);
        _saveData();
      });
    } else {
      const snack1 = SnackBar(
        content: Text('Nenhuma tarefa informada!'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snack1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Lista de Tarefas'),
            backgroundColor: colorAccent,
          ),
          body: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(17, 1, 17, 1),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: colorAccent)),
                    )),
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: ElevatedButton(
                        onPressed: _addToDo,
                        child: const Icon(Icons.add),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(colorAccent),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _toDoController.text = '';
                      },
                      child: const Icon(Icons.close),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(colorSecondary),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                  child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem),
              ))
            ],
          )),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error,
            color: Colors.white,
          ),
          backgroundColor: colorAccent,
        ),
        onChanged: (checked) {
          setState(() {
            _toDoList[index]['ok'] = checked;
            _saveData();
          });
        },
        activeColor: colorAccent,
        checkColor: Colors.white,
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: const Text('Tarefa removida!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedIndex, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 2),
          );

          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
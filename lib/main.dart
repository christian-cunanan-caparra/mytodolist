
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';

import 'notes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('taskBox'); // Consistent box name
  await Hive.openBox('notesBox'); // For notes
  runApp(const CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> todolist = [];
  final TextEditingController _addTask = TextEditingController();
  final TextEditingController _editTask = TextEditingController();
  final box = Hive.box('taskBox'); // Consistent box name
  List<int> selectedIndices = [];
  String _searchQuery = '';
  bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    final data = box.get('todo', defaultValue: []); // Consistent key name

    todolist = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .map((task) {
      task.putIfAbsent('date', () => DateTime.now().toIso8601String());
      return task;
    })
        .toList()
        .reversed
        .toList();

    setState(() => _isLoading = false);
  }

  void _saveTask(String taskText) {
    final task = {
      "task": taskText,
      "status": false,
      "date": DateTime.now().toIso8601String(),
    };

    setState(() {
      todolist.insert(0, task);
      _saveToDatabase();
    });
  }

  void _saveToDatabase() {
    box.put('todo', List<Map<String, dynamic>>.from(todolist.reversed));
  }



  Widget _buildTaskItem(Map<String, dynamic> task, int index) {
    final isSelected = selectedIndices.contains(index);
    final status = task['status'] ? 'Completed' : 'Pending';
    final statusColor = task['status']
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemOrange;

    return GestureDetector(
      onTap: () {
        if (selectedIndices.isNotEmpty) {
          setState(() {
            if (isSelected) {
              selectedIndices.remove(index);
            } else {
              selectedIndices.add(index);
            }
          });
        } else {
          // Only allow editing if the task is not completed
          if (todolist[index]['status'] == false) {
            _showEditDialog(index, task['task']);
          } else {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Editing Not Allowed'),
                content: const Text('This task is already marked as completed.'),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }

        }
      },

      onLongPress: () {
        setState(() {
          if (isSelected) {
            selectedIndices.remove(index);
          } else {
            selectedIndices.add(index);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: CupertinoColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedIndices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.inactiveGray,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['task'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task['status']
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['note'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.black,
                      ),
                    ),

                  ],
                ),
              ),
              if (selectedIndices.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),


    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((task) {
          final index = todolist.indexOf(task);
          return _buildTaskItem(task, index);
        }).toList(),
      ],
    );
  }

  void _showEditDialog(int index, String currentText) {
    _editTask.text = currentText;
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _editTask,
                placeholder: 'Task name',
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Cancel'),
              onPressed: () {
                _editTask.clear();
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('Update'),
              onPressed: () {
                if (_editTask.text.trim().isNotEmpty) {
                  final updatedTask = {
                    ...todolist[index],
                    "task": _editTask.text.trim(),
                    "date": DateTime.now().toIso8601String(),
                  };

                  setState(() {
                    todolist.removeAt(index);
                    todolist.insert(0, updatedTask); // Put updated pending at top
                    _saveToDatabase();
                  });
                }
                _editTask.clear();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Selected'),
          content: Text('Remove ${selectedIndices.length} item(s)?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  selectedIndices.sort((a, b) => b.compareTo(a));
                  for (var index in selectedIndices) {
                    todolist.removeAt(index);
                  }
                  selectedIndices.clear();
                  _saveToDatabase();
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _markSelectedAsCompleted() {
    final alreadyCompleted = selectedIndices.every((index) => todolist[index]['status'] == true);

    if (alreadyCompleted) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Tasks already completed'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Mark as Completed'),
          content: Text('Mark ${selectedIndices.length} item(s) as completed?'),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              onPressed: () {
                setState(() {
                  for (var index in selectedIndices) {
                    todolist[index]['status'] = true;
                    todolist[index]['date'] = DateTime.now().toIso8601String();
                  }
                  selectedIndices.clear();
                  _saveToDatabase();
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  List<Map<String, dynamic>> _getPendingTasks() {
    return todolist.where((task) =>
    task['status'] == false &&
        task['task'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
  }

  List<Map<String, dynamic>> _getCompletedTasks() {
    return todolist.where((task) =>
    task['status'] == true &&
        task['task'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
  }


  @override
  Widget build(BuildContext context) {
    final notCompleted = _getPendingTasks();
    final completed = _getCompletedTasks();

    return CupertinoPageScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            selectedIndices.isEmpty
                                ? Row(
                              children: [
                                const Text(
                                  'Todo List',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => NotesPage(),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    CupertinoIcons.line_horizontal_3,
                                    size: 26,
                                    color: CupertinoColors.systemYellow,
                                  ),
                                ),
                              ],
                            )
                                : Text(
                              '${selectedIndices.length} Selected',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            selectedIndices.isNotEmpty
                                ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: CupertinoColors.systemBlue),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedIndices.clear();
                                });
                              },
                            )
                                : CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.info_circle,
                                size: 23,
                                color: CupertinoColors.systemYellow,
                              ),
                              onPressed: () {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('Team Members'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        SizedBox(height: 10),
                                        Text('Caparra, Christian'),
                                        Text('De Ramos, Michael'),
                                        Text('Galang, Jhuniel'),
                                        Text('Guevarra, John Lloyd'),
                                        Text('Miranda, Samuel'),
                                      ],
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: const Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CupertinoSearchTextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          onSubmitted: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: todolist.isEmpty
                            ? const Center(child: Text("No tasks yet!"))
                            : Column(
                          children: [
                            _buildSection('Not Completed', notCompleted),
                            if (completed.isNotEmpty)
                              _buildSection('Completed', completed),
                          ],
                        ),
                      ),
                      if (selectedIndices.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: CupertinoColors.systemGroupedBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              CupertinoButton(
                                onPressed: _markSelectedAsCompleted,
                                child: const Text(
                                  'Mark as Completed',
                                  style: TextStyle(
                                    color: CupertinoColors.systemYellow,
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _showDeleteConfirmation,
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: CupertinoColors.systemYellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: CupertinoColors.systemGroupedBackground,
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${todolist.isNotEmpty ? todolist.length : 0} tasks',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(
                                  CupertinoIcons.square_pencil,
                                  color: CupertinoColors.systemYellow,
                                  size: 28,
                                ),
                                onPressed: () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) {
                                      return CupertinoAlertDialog(
                                        title: const Text('Add Task'),
                                        content: Column(
                                          children: [
                                            const SizedBox(height: 12),
                                            CupertinoTextField(
                                              controller: _addTask,
                                              placeholder: 'Task name',
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            child: const Text('Cancel'),
                                            onPressed: () {
                                              _addTask.clear();
                                              Navigator.pop(context);
                                            },
                                          ),
                                          CupertinoDialogAction(
                                            child: const Text('Save'),
                                            onPressed: () {
                                              if (_addTask.text.trim().isNotEmpty) {
                                                _saveTask(_addTask.text.trim());
                                              }
                                              _addTask.clear();
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}


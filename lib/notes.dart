import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('notesBox');
  runApp(const CupertinoApp(
    home: NotesPage(),
  ));
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _searchQuery = '';
  late Box notesBox;

  @override
  void initState() {
    super.initState();
    notesBox = Hive.box('notesBox');
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final weekAgo = DateTime(now.year, now.month, now.day - 7);
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) return 'Today';
    if (noteDate == yesterday) return 'Yesterday';
    if (noteDate.isAfter(weekAgo)) return 'Previous 7 Days';
    if (noteDate.isAfter(monthAgo)) return 'Previous 30 Days';
    return 'Older';
  }

  Map<String, List<Map<String, dynamic>>> _groupNotes(List<Map<String, dynamic>> notes) {
    notes.sort((a, b) {
      final dateA = DateTime.parse(a['date'] ?? '1970-01-01');
      final dateB = DateTime.parse(b['date'] ?? '1970-01-01');
      return dateB.compareTo(dateA);
    });

    final groups = <String, List<Map<String, dynamic>>>{};

    for (final note in notes) {
      final date = DateTime.parse(note['date'] ?? DateTime.now().toString());
      final group = _getDateGroup(date);

      if (!groups.containsKey(group)) {
        groups[group] = [];
      }
      groups[group]!.add(note);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notesList = notesBox.keys.map((key) {
      final note = notesBox.get(key);
      return {
        'key': key,
        'title': note['title'],
        'content': note['content'],
        'date': note['date'],
      };
    }).toList();

    final filteredNotes = notesList.where((note) {
      final title = note['title']?.toString().toLowerCase() ?? '';
      final content = note['content']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase()) ||
          content.contains(_searchQuery.toLowerCase());
    }).toList();

    final groupedNotes = _groupNotes(filteredNotes);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: CupertinoColors.black,
                    ),
                  ),
                  CupertinoButton(
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
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(
                child: Text(
                  'No notes yet!',
                  style: TextStyle(color: CupertinoColors.black),
                ),
              )
                  : ListView.builder(
                itemCount: groupedNotes.length,
                itemBuilder: (context, index) {
                  final groupKey = groupedNotes.keys.elementAt(index);
                  final groupNotes = groupedNotes[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8),
                        child: Text(
                          groupKey,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                      ...groupNotes.map((note) {
                        final date = DateTime.parse(
                            note['date'] ?? DateTime.now().toString());
                        final formattedDate =
                        DateFormat('MMMM d y h:mm a').format(date);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final updatedNote = await Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => NoteEditor(
                                    initialTitle:
                                    note['title']?.toString() ?? '',
                                    initialContent:
                                    note['content']?.toString() ?? '',
                                  ),
                                ),
                              );

                              if (updatedNote != null &&
                                  updatedNote['title'] != null) {
                                await notesBox.put(
                                  note['key'],
                                  {
                                    'title': updatedNote['title'],
                                    'content': updatedNote['content'],
                                    'date': DateTime.now().toString(),
                                  },
                                );
                                setState(() {});
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGroupedBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note['title']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note['content']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.systemGrey2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: CupertinoColors.systemGroupedBackground,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '${notesBox.length} notes',
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
                    onPressed: () async {
                      final newNote = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const NoteEditor(
                            initialTitle: '',
                            initialContent: '',
                          ),
                        ),
                      );

                      if (newNote != null && newNote['title'] != null) {
                        await notesBox.add({
                          'title': newNote['title'],
                          'content': newNote['content'],
                          'date': DateTime.now().toString(),
                        });
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteEditor extends StatefulWidget {
  final String initialTitle;
  final String initialContent;

  const NoteEditor({
    super.key,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text(
          'Edit Note',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text(
            'Save',
            style: TextStyle(
              color: CupertinoColors.black,
            ),
          ),
          onPressed: () {
            if (titleController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'title': titleController.text,
                'content': contentController.text,
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoTextField(
                  controller: titleController,
                  placeholder: 'Title',
                  placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    color: CupertinoColors.black,
                  ),
                  decoration: null,
                ),
                const SizedBox(height: 11),
                CupertinoTextField(
                  controller: contentController,
                  placeholder: 'Note something down',
                  placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: CupertinoColors.black,
                  ),
                  decoration: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
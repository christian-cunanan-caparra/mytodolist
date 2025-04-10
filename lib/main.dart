import 'dart:async';

import 'package:bsitdolist/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notesBox');
  await Hive.openBox('trashBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('securityBox');
  runApp(const MyApp());
}

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  late Box securityBox;
  bool _isFirstTime = true;
  bool _isPasswordCorrect = true;

  @override
  void initState() {
    super.initState();
    securityBox = Hive.box('securityBox');
    _isFirstTime = securityBox.get('password', defaultValue: null) == null;
  }

  void _checkPassword() {
    final storedPassword = securityBox.get('password');
    if (_isFirstTime || _passwordController.text == storedPassword) {
      if (_isFirstTime) {
        securityBox.put('password', _passwordController.text);
      }
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => widget.child),
      );
    } else {
      setState(() {
        _isPasswordCorrect = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('iNotes Security'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.lock_fill,
                size: 60,
                color: CupertinoColors.systemOrange,
              ),
              const SizedBox(height: 30),
              Text(
                _isFirstTime ? 'Set a password' : 'Enter your password',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (!_isPasswordCorrect)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Incorrect password',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.systemOrange,
                  onPressed: _checkPassword,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                      if (_isFirstTime) // Show only if it's the first time
                        const Text(
                          'Set Password',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Box settingsBox;
  bool isDarkMode = false;
  late Box securityBox;
  bool isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadSecuritySettings();
  }

  Future<void> _loadTheme() async {
    settingsBox = await Hive.openBox('settingsBox');
    setState(() {
      isDarkMode = settingsBox.get('darkMode', defaultValue: false);
    });
    settingsBox.listenable().addListener(_updateTheme);
  }

  Future<void> _loadSecuritySettings() async {
    securityBox = await Hive.openBox('securityBox');
    setState(() {
      isLockEnabled = securityBox.get('isLockEnabled', defaultValue: false);
    });
  }

  void _updateTheme() {
    setState(() {
      isDarkMode = settingsBox.get('darkMode', defaultValue: false);
    });
  }

  @override
  void dispose() {
    settingsBox.listenable().removeListener(_updateTheme);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'iNote',
      theme: CupertinoThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.systemOrange,
      ),
      home: isLockEnabled
          ? const LockScreen(child: NotesPage())
          : const NotesPage(),
    );
  }
}



class _SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _SwipeActionButton({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: CupertinoColors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _searchQuery = '';
  late Box notesBox;
  final Set<dynamic> _selectedNotes = {};
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    notesBox = Hive.box('notesBox');
    // Add listener for real-time updates
    notesBox.listenable().addListener(_onBoxChanged);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    notesBox.listenable().removeListener(_onBoxChanged);
    super.dispose();
  }

  void _onBoxChanged() {
    // This will trigger a rebuild when the box changes
    if (mounted) {
      setState(() {});
    }
  }

  bool _areSelectedNotesPinned() {
    for (var key in _selectedNotes) {
      final note = notesBox.get(key);
      if (note['isPinned'] != true) {
        return false;
      }
    }
    return _selectedNotes.isNotEmpty;
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
    final pinnedNotes = notes.where((note) => note['isPinned'] == true).toList();
    final unpinnedNotes = notes.where((note) => note['isPinned'] != true).toList();

    unpinnedNotes.sort((a, b) {
      final dateA = DateTime.parse(a['date'] ?? '1970-01-01');
      final dateB = DateTime.parse(b['date'] ?? '1970-01-01');
      return dateB.compareTo(dateA);
    });

    final groups = <String, List<Map<String, dynamic>>>{};

    if (pinnedNotes.isNotEmpty) {
      groups['Pinned'] = pinnedNotes;
    }

    for (final note in unpinnedNotes) {
      final date = DateTime.parse(note['date'] ?? DateTime.now().toString());
      final group = _getDateGroup(date);

      if (!groups.containsKey(group)) {
        groups[group] = [];
      }
      groups[group]!.add(note);
    }

    return groups;
  }

  String _getPlainTextPreview(String? content) {
    if (content == null) return '';

    return content
        .replaceAll('[style bold="true"]', '')
        .replaceAll('[style italic="true"]', '')
        .replaceAll('[style underline="true"]', '')
        .replaceAll('[style strikethrough="true"]', '')
        .replaceAll('[/style]', '');
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedNotes.clear();
      }
    });
  }

  void _toggleNoteSelection(dynamic noteKey) {
    setState(() {
      if (_selectedNotes.contains(noteKey)) {
        _selectedNotes.remove(noteKey);
        if (_selectedNotes.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedNotes.add(noteKey);
        if (!_isSelecting) {
          _isSelecting = true;
        }
      }
    });
  }

  Future<void> _togglePinnedStatus() async {
    for (var key in _selectedNotes) {
      final note = notesBox.get(key);
      await notesBox.put(key, {
        ...note,
        'isPinned': !(note['isPinned'] ?? false),
      });
    }
    setState(() {
      _selectedNotes.clear();
      _isSelecting = false;
    });
  }

  Future<void> _deleteSelectedNotes() async {
    final trashBox = Hive.box('trashBox');

    // Move notes to trash with deletion date
    for (var key in _selectedNotes) {
      final note = notesBox.get(key);
      await trashBox.put(key, {
        ...note,
        'dateDeleted': DateTime.now().toString(),
      });
    }

    // Delete from main notes
    await notesBox.deleteAll(_selectedNotes);

    setState(() {
      _selectedNotes.clear();
      _isSelecting = false;
    });
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
        'isBold': note['isBold'] ?? false,
        'isItalic': note['isItalic'] ?? false,
        'isUnderline': note['isUnderline'] ?? false,
        'isStrikethrough': note['isStrikethrough'] ?? false,
        'textAlignment': note['textAlignment'] ?? 'left',
        'fontSize': note['fontSize'] ?? 16.0,
        'isPinned': note['isPinned'] ?? false,
      };
    }).toList();

    final filteredNotes = notesList.where((note) {
      final title = note['title']?.toString().toLowerCase() ?? '';
      final content = _getPlainTextPreview(note['content']?.toString()).toLowerCase();

      return title.contains(_searchQuery.toLowerCase()) ||
          content.contains(_searchQuery.toLowerCase());
    }).toList();

    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoColors.darkBackgroundGray
        : CupertinoColors.white;
    final textColor = isDarkMode
        ? CupertinoColors.white
        : CupertinoColors.black;
    final secondaryTextColor = isDarkMode
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;
    final groupedNotes = _groupNotes(filteredNotes);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            if (_isSelecting)
              Container(
                padding: const EdgeInsets.all(16),
                color: CupertinoTheme.of(context).barBackgroundColor,
                child: Row(
                  children: [
                    Text(
                      '${_selectedNotes.length} Selected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,

                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _toggleSelectionMode,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'iNotes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 33,
                        color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: CupertinoColors.systemOrange, width: 2),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.more_horiz,
                          color: CupertinoColors.systemOrange,
                          size: 10,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                    )

                  ],
                ),
              ),
            const SizedBox(height: 12),
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
                  ? Center(
                child: Text(
                  'No notes yet!',
                  style: TextStyle(color: textColor),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Row(
                          children: [
                            if (groupKey == 'Pinned')
                              const Icon(
                                CupertinoIcons.pin_fill,
                                size: 16,
                                color: CupertinoColors.systemOrange, // Keep orange icon
                              ),
                            if (groupKey == 'Pinned') const SizedBox(width: 6),
                            Text(
                              groupKey,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: groupKey == 'Pinned'
                                    ? CupertinoColors.systemOrange // Keep orange text
                                    : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...groupNotes.map((note) {
                        final date = DateTime.parse(
                            note['date'] ?? DateTime.now().toString());
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final noteDate =
                        DateTime(date.year, date.month, date.day);

                        final formattedTime = noteDate == today
                            ? DateFormat('h:mm a').format(date)
                            : DateFormat('M/d/yy').format(date);

                        return Dismissible(
                          key: Key(note['key'].toString()),
                          direction: DismissDirection.endToStart, // Only allow right-to-left swipe
                          confirmDismiss: (direction) async {
                            // Delete action confirmation
                            final shouldDelete = await showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Delete Note'),
                                content: const Text(
                                    'Are you sure you want to delete this note?'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text('Delete'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            );
                            return shouldDelete;
                          },
                          onDismissed: (direction) async {
                            final trashBox = Hive.box('trashBox');
                            final noteKey = note['key'];
                            final currentNote = notesBox.get(noteKey);
                            await trashBox.put(noteKey, {
                              ...currentNote,
                              'dateDeleted': DateTime.now().toString(),
                            });
                            await notesBox.delete(noteKey);
                          },
                          background: Container(), // Empty background for left swipe
                          secondaryBackground: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                const Spacer(),
                                _SwipeActionButton(
                                  icon: CupertinoIcons.delete,
                                  color: CupertinoColors.destructiveRed,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                            child: GestureDetector(
                              onLongPress: () {
                                _toggleSelectionMode();
                                _toggleNoteSelection(note['key']);
                              },
                              onTap: () {
                                if (_isSelecting) {
                                  _toggleNoteSelection(note['key']);
                                } else {
                                  _openNoteEditor(context, note);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedNotes.contains(note['key'])
                                      ? CupertinoColors.systemOrange.withOpacity(0.2)
                                      : backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? CupertinoColors.systemGrey.withOpacity(0.3)
                                          : CupertinoColors.systemGrey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  // Remove this entire border condition
                                  // border: groupKey == 'Pinned'
                                  //     ? Border.all(
                                  //         color: isDarkMode
                                  //             ? CupertinoColors.systemOrange
                                  //             : CupertinoColors.systemOrange.withOpacity(0.3),
                                  //         width: 1.5,
                                  //       )
                                  //     : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (note['isPinned'] && !_isSelecting)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            right: 12, top: 6),
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemOrange,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.pin_fill,
                                            size: 20,
                                            color: CupertinoColors.white,
                                          ),
                                        ),
                                      ),
                                    if (_isSelecting)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 12),
                                        child: Icon(
                                          _selectedNotes.contains(note['key'])
                                              ? CupertinoIcons
                                              .checkmark_circle_fill
                                              : CupertinoIcons.circle,
                                          color: _selectedNotes
                                              .contains(note['key'])
                                              ? CupertinoColors.systemOrange
                                              : CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                      Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  note['title']?.toString() ?? 'No title',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formattedTime,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getPlainTextPreview(note['content'].toString()),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: secondaryTextColor,
                                            ),
                                          ),


                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.folder,
                                                size: 15,
                                                color: CupertinoColors.systemGrey,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Notes',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: CupertinoColors
                                                      .systemGrey2,
                                                ),
                                              ),
                                            ],
                                          )

                                          ],
                                          ),
                                         ),
                                        ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDarkMode
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.systemGroupedBackground,
              child: Row(
                children: [
                  if (!_isSelecting) ...[
                    Expanded(
                      child: Center(
                        child: Text(
                          '${notesBox.length} notes',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.square_pencil,
                        color: CupertinoColors.systemOrange,
                        size: 28,
                      ),
                      onPressed: () async {
                        final newNote = await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const NoteEditor(
                              initialTitle: '',
                              initialContent: '',
                              initialIsBold: false,
                              initialIsItalic: false,
                              initialIsUnderline: false,
                              initialIsStrikethrough: false,
                              initialTextAlignment: 'left',
                              initialFontSize: 16.0,
                            ),
                          ),
                        );

                        if (newNote != null && newNote['title'] != null) {
                          await notesBox.add({
                            'title': newNote['title'],
                            'content': newNote['content'],
                            'date': DateTime.now().toString(),
                            'isBold': newNote['isBold'],
                            'isItalic': newNote['isItalic'],
                            'isUnderline': newNote['isUnderline'],
                            'isStrikethrough': newNote['isStrikethrough'],
                            'textAlignment': newNote['textAlignment'],
                            'fontSize': newNote['fontSize'],
                          });
                        }
                      },
                    ),
                  ] else if (_selectedNotes.isNotEmpty) ...[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _togglePinnedStatus,
                                child: Icon(
                                  _areSelectedNotesPinned()
                                      ? CupertinoIcons.pin_slash
                                      : CupertinoIcons.pin,
                                  color: CupertinoColors.systemOrange,
                                  size: 28,
                                ),
                              ),
                              Text(
                                _areSelectedNotesPinned() ? 'Unpin' : 'Pin',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final shouldDelete = await showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Delete Notes'),
                                      content: Text(
                                        'Are you sure you want to delete ${_selectedNotes.length} note${_selectedNotes.length > 1 ? 's' : ''}?',
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('Cancel'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: const Text('Delete'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true) {
                                    await _deleteSelectedNotes();
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoColors.destructiveRed,
                                  size: 28,
                                ),
                              ),
                              const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNoteEditor(BuildContext context, Map<String, dynamic> note) async {
    final updatedNote = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NoteEditor(
          initialTitle: note['title']?.toString() ?? '',
          initialContent: note['content']?.toString() ?? '',
          initialIsBold: note['isBold'] ?? false,
          initialIsItalic: note['isItalic'] ?? false,
          initialIsUnderline: note['isUnderline'] ?? false,
          initialIsStrikethrough: note['isStrikethrough'] ?? false,
          initialTextAlignment: note['textAlignment'] ?? 'left',
          initialFontSize: note['fontSize'] ?? 16.0,
        ),
      ),
    );

    if (updatedNote != null && updatedNote['title'] != null) {
      await notesBox.put(
        note['key'],
        {
          'title': updatedNote['title'],
          'content': updatedNote['content'],
          'date': DateTime.now().toString(),
          'isBold': updatedNote['isBold'],
          'isItalic': updatedNote['isItalic'],
          'isUnderline': updatedNote['isUnderline'],
          'isStrikethrough': updatedNote['isStrikethrough'],
          'textAlignment': updatedNote['textAlignment'],
          'fontSize': updatedNote['fontSize'],
          'isPinned': note['isPinned'] ?? false,
        },
      );
    }
  }
}

class NoteEditor extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final bool initialIsBold;
  final bool initialIsItalic;
  final bool initialIsUnderline;
  final bool initialIsStrikethrough;
  final String initialTextAlignment;
  final double initialFontSize;

  const NoteEditor({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.initialIsBold,
    required this.initialIsItalic,
    required this.initialIsUnderline,
    required this.initialIsStrikethrough,
    required this.initialTextAlignment,
    required this.initialFontSize,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;
  bool isFormattingToolbarVisible = false;
  bool isFontSizePickerVisible = false;
  bool isAlignmentPickerVisible = false;

  // Formatting states
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  bool isStrikethrough = false;
  String textAlignment = 'left';
  double fontSize = 16.0;

  // Availableas font sizes
  final List<double> fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 64.0];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    contentController = TextEditingController(text: widget.initialContent);
    isBold = widget.initialIsBold;
    isItalic = widget.initialIsItalic;
    isUnderline = widget.initialIsUnderline;
    isStrikethrough = widget.initialIsStrikethrough;
    textAlignment = widget.initialTextAlignment;
    fontSize = widget.initialFontSize;
  }


  @override
  void dispose() {
    _saveNote(); // Save when disposing (when navigating back)
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (titleController.text.trim().isNotEmpty) {
      Navigator.pop(context, {
        'title': titleController.text,
        'content': contentController.text,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'isStrikethrough': isStrikethrough,
        'textAlignment': textAlignment,
        'fontSize': fontSize,
        'isPinned': false,
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _toggleFormatting(String format) {
    setState(() {
      switch (format) {
        case 'bold':
          isBold = !isBold;
          break;
        case 'italic':
          isItalic = !isItalic;
          break;
        case 'underline':
          isUnderline = !isUnderline;
          break;
        case 'strikethrough':
          isStrikethrough = !isStrikethrough;
          break;
      }
    });

    final selection = contentController.selection;
    if (selection.start == selection.end) {
      return;
    }

    final text = contentController.text;
    final selectedText = text.substring(selection.start, selection.end);

    final updatedText = text.replaceRange(
      selection.start,
      selection.end,
      _applyInlineFormatting(selectedText),
    );

    contentController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: selection.start),
    );
  }

  String _applyInlineFormatting(String text) {
    String formattedText = text;
    if (isBold) {
      formattedText = '[style bold="true"]$formattedText[/style]';
    }
    if (isItalic) {
      formattedText = '[style italic="true"]$formattedText[/style]';
    }
    if (isUnderline) {
      formattedText = '[style underline="true"]$formattedText[/style]';
    }
    if (isStrikethrough) {
      formattedText = '[style strikethrough="true"]$formattedText[/style]';
    }
    return formattedText;
  }

  void _applyAlignment(String alignment) {
    setState(() {
      textAlignment = alignment;
      isAlignmentPickerVisible = false;
    });
  }

  void _applyFontSize(double size) {
    setState(() {
      fontSize = size;
      isFontSizePickerVisible = false;
    });
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        isUnderline ? TextDecoration.underline : TextDecoration.none,
        isStrikethrough ? TextDecoration.lineThrough : TextDecoration.none,
      ]),
    );
  }

  TextAlign _getTextAlign() {
    switch (textAlignment) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Transform.translate(
          offset: Offset(-8, 0), // Move 8 pixels to the left
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveNote,
                child: Icon(
                  CupertinoIcons.back,
                  color: CupertinoColors.systemOrange,
                  size: 30,
                ),
              ),
              Text(
                'iNotes',
                style: TextStyle(
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
        ),
      ),




      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoTextField(
                          controller: titleController,
                          placeholder: 'Title',
                          placeholderStyle: TextStyle(
                            color: CupertinoTheme.of(context).textTheme.textStyle.color?.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            color: CupertinoTheme.of(context).textTheme.textStyle.color,
                          ),
                          decoration: null,
                        ),
                        const SizedBox(height: 11),
                        CupertinoTextField(
                          controller: contentController,
                          placeholder: 'Note something down',
                          placeholderStyle: TextStyle(
                            color: CupertinoTheme.of(context).textTheme.textStyle.color?.withOpacity(0.5),
                          ),
                          maxLines: null,
                          textAlign: _getTextAlign(),
                          textAlignVertical: TextAlignVertical.top,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          style: _getTextStyle().copyWith(
                            color: CupertinoTheme.of(context).textTheme.textStyle.color,
                          ),
                          decoration: null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Format Button
            if (!isFormattingToolbarVisible && !isFontSizePickerVisible && !isAlignmentPickerVisible)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).barBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey4,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            Icons.format_bold,
                            color: CupertinoColors.systemOrange,
                            size: 24,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            isFormattingToolbarVisible = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Full Formatting Toolbar (positioned at the bottom)
            if (isFormattingToolbarVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).barBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? CupertinoColors.black
                            : CupertinoColors.systemGrey,
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Format',
                              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 28,
                            onPressed: () {
                              setState(() {
                                isFormattingToolbarVisible = false;
                              });
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.clear,
                                size: 18,
                                color: CupertinoTheme.of(context).textTheme.textStyle.color,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      // Format Buttons - Wrap in SingleChildScrollView for horizontal scrolling on small devices
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Bold
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: isBold ? CupertinoColors.systemOrange : CupertinoColors.systemGrey5,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                child: Icon(
                                  CupertinoIcons.bold,
                                  color: isBold ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _toggleFormatting('bold'),
                              ),
                            ),

                            const SizedBox(width: 2),

                            // Italic
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: isItalic ? CupertinoColors.systemOrange : CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.zero,
                                child: Icon(
                                  CupertinoIcons.italic,
                                  color: isItalic ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _toggleFormatting('italic'),
                              ),
                            ),
                            const SizedBox(width: 2),

                            // Underline
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: isUnderline ? CupertinoColors.systemOrange : CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.zero,
                                child: Icon(
                                  CupertinoIcons.underline,
                                  color: isUnderline ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _toggleFormatting('underline'),
                              ),
                            ),
                            const SizedBox(width: 2),

                            // Strikethrough
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: isStrikethrough ? CupertinoColors.systemOrange : CupertinoColors.systemGrey5,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                child: Icon(
                                  Icons.strikethrough_s,
                                  color: isStrikethrough ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _toggleFormatting('strikethrough'),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Font Size
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(8),
                                child: Icon(
                                  Icons.text_fields,
                                  color: CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isFormattingToolbarVisible = false;
                                    isFontSizePickerVisible = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Alignment Buttons - Also wrapped in SingleChildScrollView
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Left Align
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.18,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: textAlignment == 'left'
                                    ? CupertinoColors.systemOrange
                                    : CupertinoColors.systemGrey5,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                child: Icon(
                                  Icons.format_align_left,
                                  color: textAlignment == 'left' ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _applyAlignment('left'),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Center Align
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.18,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: textAlignment == 'center'
                                    ? CupertinoColors.systemOrange
                                    : CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.zero,
                                child: Icon(
                                  Icons.format_align_center,
                                  color: textAlignment == 'center' ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _applyAlignment('center'),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Right Align
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.18,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: textAlignment == 'right'
                                    ? CupertinoColors.systemOrange
                                    : CupertinoColors.systemGrey5,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                child: Icon(
                                  Icons.format_align_right,
                                  color: textAlignment == 'right' ? CupertinoColors.white : CupertinoColors.black,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () => _applyAlignment('right'),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Justify
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.18,

                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Font Size Picker
            if (isFontSizePickerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey4,
                      ),
                    ),
                    color: CupertinoTheme.of(context).barBackgroundColor,
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: fontSizes.map((size) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: size == fontSize
                                    ? CupertinoColors.systemBlue
                                    : isDarkMode
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey4,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                size.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: size == fontSize
                                      ? CupertinoColors.systemBlue
                                      : CupertinoTheme.of(context).textTheme.textStyle.color,
                                ),
                              ),
                            ),
                          ),
                          onPressed: () {
                            _applyFontSize(size);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
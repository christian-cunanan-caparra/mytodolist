import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    // Sort notes by: pinned status first (newest pinned on top), then by date
    notes.sort((a, b) {
      final aPinned = a['isPinned'] ?? false;
      final bPinned = b['isPinned'] ?? false;

      // If both are pinned or both are not pinned, sort by date
      if (aPinned == bPinned) {
        final dateA = DateTime.parse(a['date'] ?? '1970-01-01');
        final dateB = DateTime.parse(b['date'] ?? '1970-01-01');
        return dateB.compareTo(dateA); // Newest first
      }
      // If one is pinned, it comes first
      return bPinned ? 1 : -1;
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

  String _getPlainTextPreview(String? content) {
    if (content == null) return '';


    return content
        .replaceAll('[style bold="true"]', '')
        .replaceAll('[style italic="true"]', '')
        .replaceAll('[style underline="true"]', '')
        .replaceAll('[style strikethrough="true"]', '')
        .replaceAll('[/style]', '');
  }


  void _showNoteOptions(BuildContext context, Map<String, dynamic> note) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [


                _buildOptionButton(
                  icon: note['isPinned'] ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                  label: note['isPinned'] ? 'Unpin' : 'Pin',
                  onTap: () async {
                    Navigator.pop(context);
                    await notesBox.put(
                      note['key'],
                      {
                        ...notesBox.get(note['key']),
                        'isPinned': !(note['isPinned'] ?? false),
                      },
                    );
                    setState(() {});
                  },
                  color: CupertinoColors.activeBlue,
                ),
                _buildOptionButton(
                  icon: CupertinoIcons.delete,
                  label: 'Delete',
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, note);
                  },
                  color: CupertinoColors.destructiveRed,
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }



  void _confirmDelete(BuildContext context, Map<String, dynamic> note) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Delete Note?"),
        content: Text("Are you sure you want to delete this note? This action cannot be undone."),
        actions: [
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text("Delete"),
            onPressed: () async {
              Navigator.pop(context);
              await notesBox.delete(note['key']);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }




  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = CupertinoColors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
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
                  final date = DateTime.parse(note['date'] ?? DateTime.now().toString());
                  final formattedTime = DateFormat('h:mm a').format(date);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                    child: GestureDetector(
                      onLongPress: () => _showNoteOptions(context, note),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
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
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (note['isPinned'])
                                  Container(
                                    width: 24,

                                    alignment: Alignment.centerLeft,
                                    child: const Icon(
                                      CupertinoIcons.pin_fill,

                                      size: 30,
                                      color: CupertinoColors.systemOrange,
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                note['title']?.toString() ?? 'No title',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: CupertinoColors.black,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              formattedTime,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: CupertinoColors.systemGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getPlainTextPreview(note['content'].toString()),

                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Notes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors.systemGrey2,
                                            fontStyle: FontStyle.italic,
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

  // Available font sizes
  final List<double> fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0];

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
    titleController.dispose();
    contentController.dispose();
    super.dispose();
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

  void _toggleBulletList() {
    final controller = contentController;
    final selection = controller.selection;
    final text = controller.text;


    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final lineEnd = text.indexOf('\n', selection.start);
    final currentLine = lineEnd == -1
        ? text.substring(lineStart)
        : text.substring(lineStart, lineEnd);

    if (currentLine.startsWith('• ')) {

      final newText = text.replaceRange(lineStart, lineStart + 2, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 2),
      );
    } else {

      final newText = text.replaceRange(lineStart, lineStart, '• ');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + 2),
      );
    }
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.systemYellow,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text(
          'iNote',
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
              color: CupertinoColors.systemYellow,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
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
          },
        ),
      ),
      child: SafeArea(
        child: Column(
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
                      placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      style: TextStyle(
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
                      textAlign: _getTextAlign(),
                      textAlignVertical: TextAlignVertical.top,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      style: _getTextStyle(),
                      decoration: null,
                    ),
                  ],
                ),
              ),
            ),
            // Main Toolbar
            if (!isFormattingToolbarVisible &&
                !isFontSizePickerVisible &&
                !isAlignmentPickerVisible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CupertinoColors.systemGrey4)),
                  color: CupertinoColors.white,
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.textformat, color: CupertinoColors.black),
                      onPressed: () {
                        setState(() {
                          isFormattingToolbarVisible = true;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.list_bullet, color: CupertinoColors.black),
                      onPressed: _toggleBulletList,
                    ),
                    const Spacer(),
                  ],
                ),
              ),

            if (isFormattingToolbarVisible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CupertinoColors.systemGrey4)),
                  color: CupertinoColors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Bold
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.bold,
                              color: isBold ? CupertinoColors.systemBlue : CupertinoColors.black),
                          onPressed: () => _toggleFormatting('bold'),
                        ),
                        // Italic
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.italic,
                              color: isItalic ? CupertinoColors.systemBlue : CupertinoColors.black),
                          onPressed: () => _toggleFormatting('italic'),
                        ),
                        // Underline
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.underline,
                              color: isUnderline ? CupertinoColors.systemBlue : CupertinoColors.black),
                          onPressed: () => _toggleFormatting('underline'),
                        ),
                        // Strikethrough
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(Icons.strikethrough_s,
                              color: isStrikethrough ? CupertinoColors.systemBlue : CupertinoColors.black),
                          onPressed: () => _toggleFormatting('strikethrough'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Font Size
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(Icons.text_fields, color: CupertinoColors.black),
                          onPressed: () {
                            setState(() {
                              isFormattingToolbarVisible = false;
                              isFontSizePickerVisible = true;
                            });
                          },
                        ),
                        // Text Alignment
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(Icons.format_align_left, color: CupertinoColors.black),
                          onPressed: () {
                            setState(() {
                              isFormattingToolbarVisible = false;
                              isAlignmentPickerVisible = true;
                            });
                          },
                        ),
                        // Close
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.clear, color: CupertinoColors.black),
                          onPressed: () {
                            setState(() {
                              isFormattingToolbarVisible = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            // Font Size Picker
            if (isFontSizePickerVisible)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CupertinoColors.systemGrey4)),
                  color: CupertinoColors.white,
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
                                    : CupertinoColors.black,
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
            // Alignment Picker
            if (isAlignmentPickerVisible)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CupertinoColors.systemGrey4)),
                  color: CupertinoColors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(Icons.format_align_left,
                          color: 'left' == textAlignment
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.black),
                      onPressed: () => _applyAlignment('left'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(Icons.format_align_center,
                          color: 'center' == textAlignment
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.black),
                      onPressed: () => _applyAlignment('center'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(Icons.format_align_right,
                          color: 'right' == textAlignment
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.black),
                      onPressed: () => _applyAlignment('right'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(Icons.format_align_justify,
                          color: 'justify' == textAlignment
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.black),
                      onPressed: () => _applyAlignment('justify'),
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
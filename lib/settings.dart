import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box trashBox;

  @override
  void initState() {
    super.initState();
    trashBox = Hive.box('trashBox');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: trashBox.listenable(),
          builder: (context, Box box, _) {
            final deletedNotes = box.keys.map((key) {
              final note = box.get(key);
              // Only include notes that still exist in trash
              return note != null
                  ? {
                'key': key,
                'title': note['title'],
                'content': note['content'],
                'dateDeleted': note['dateDeleted'],
              }
                  : null;
            }).where((note) => note != null).toList();

            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                CupertinoListSection.insetGrouped(
                  children: [
                    CupertinoListTile(
                      title: const Text('Appearance'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {
                        // Navigate to appearance settings
                      },
                    ),
                    CupertinoListTile(
                      title: const Text('Backup & Sync'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {
                        // Navigate to backup settings
                      },
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Recently Deleted',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                if (deletedNotes.isEmpty)
                  CupertinoListSection.insetGrouped(
                    children: const [
                      CupertinoListTile(
                        title: Text('No recently deleted notes'),
                      ),
                    ],
                  )
                else
                  CupertinoListSection.insetGrouped(
                    children: deletedNotes.map((note) {
                      final dateDeleted = DateTime.parse(note!['dateDeleted']);
                      final formattedDate = DateFormat('MMM d, y - h:mm a').format(dateDeleted);

                      return CupertinoListTile(
                        title: Text(note['title'] ?? 'Untitled Note'),
                        subtitle: Text('Deleted $formattedDate'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.arrow_2_circlepath,
                                color: CupertinoColors.systemOrange,
                              ),
                              onPressed: () async {
                                // Restore the note
                                final notesBox = Hive.box('notesBox');
                                await notesBox.put(note['key'], {
                                  'title': note['title'],
                                  'content': note['content'],
                                  'date': DateTime.now().toString(),
                                  'isPinned': false,
                                });
                                await box.delete(note['key']);
                              },
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.destructiveRed,
                              ),
                              onPressed: () async {
                                final shouldDelete = await showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('Permanently Delete'),
                                    content: const Text(
                                        'Are you sure you want to permanently delete this note?'),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('Cancel'),
                                        onPressed: () => Navigator.pop(context, false),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: const Text('Delete'),
                                        onPressed: () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  await box.delete(note['key']);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                if (deletedNotes.isNotEmpty)
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: const Text(
                          'Empty Trash',
                          style: TextStyle(color: CupertinoColors.destructiveRed),
                        ),
                        onTap: () async {
                          final shouldEmpty = await showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Empty Trash'),
                              content: const Text(
                                  'Are you sure you want to permanently delete all notes in the trash?'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Empty Trash'),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (shouldEmpty == true) {
                            await box.clear();
                          }
                        },
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'AppearancePage.dart';
import 'main.dart';

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
    final brightness = CupertinoTheme.brightnessOf(context);
    final textColor = brightness == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Transform.translate(
          offset: Offset(-8, 0), // Move 8 pixels to the left
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.pop(context); // This goes back to the previous page
                },
                child: Icon(
                  CupertinoIcons.back,
                  color: CupertinoColors.systemOrange,
                  size: 30,
                ),
              ),
              Text(
                'Settings',
                style: TextStyle(
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
        ),
      ),

      child: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: trashBox.listenable(),
          builder: (context, Box box, _) {
            final deletedNotes = box.keys.map((key) {
              final note = box.get(key);
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
                  dividerMargin: 0,
                  children: [
                    CupertinoListTile.notched(
                      leading: Icon(CupertinoIcons.moon_fill, color: CupertinoColors.systemGrey),
                      title: const Text('Appearance'),
                      subtitle: const Text('Light or Dark mode preferences'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const AppearancePage(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile.notched(
                      leading: Icon(CupertinoIcons.info, color: CupertinoColors.systemGrey),
                      title: const Text('About'),
                      subtitle: const Text('Meet the developers behind this app'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {
                        final developers = [
                          'Caparra, Christian',
                          'De Ramos, Michael',
                          'Galang, Jhuniel',
                          'Guevarra, John Lloyd',
                          'Miranda, Samuel',
                        ]..sort();

                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            title: Text(
                              'Developers',
                              style: TextStyle(color: textColor),
                            ),
                            message: Text(
                              'The team behind this app',
                              style: TextStyle(color: textColor),
                            ),
                            actions: developers.map((dev) =>
                                CupertinoActionSheetAction(
                                  onPressed: () {},
                                  child: Text(
                                    dev,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                            ).toList(),
                            cancelButton: CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ),
                        );
                      },
                    ),


                    // Add this to your SettingsPage build method, inside the first CupertinoListSection
                    CupertinoListTile.notched(
                      leading: Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey),
                      title: const Text('Security'),
                      subtitle: const Text('Password protection'),
                      trailing: CupertinoSwitch(
                        value: Hive.box('securityBox').get('isLockEnabled', defaultValue: false),
                        onChanged: (value) async {
                          final securityBox = Hive.box('securityBox');
                          await securityBox.put('isLockEnabled', value);
                          if (value && securityBox.get('password') == null) {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => LockScreen(child: const NotesPage()),
                              ),
                            );
                          }
                          setState(() {});
                        },
                      ),
                    ),


                    CupertinoListTile.notched(
                      leading: Icon(CupertinoIcons.lock_rotation_open, color: CupertinoColors.systemGrey),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your security password'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {
                        final securityBox = Hive.box('securityBox');
                        if (securityBox.get('isLockEnabled', defaultValue: false)) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => LockScreen(
                                child: Builder(
                                  builder: (context) {
                                    return CupertinoPageScaffold(
                                      navigationBar: const CupertinoNavigationBar(
                                        middle: Text('Change Password'),
                                      ),
                                      child: _ChangePasswordScreen(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        } else {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Password Protection Disabled'),
                              content: const Text(
                                  'Please enable password protection first to change your password.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
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
                    dividerMargin: 0,
                    children: const [
                      CupertinoListTile.notched(
                        title: Text('No recently deleted notes'),
                      ),
                    ],
                  )
                else
                  CupertinoListSection.insetGrouped(
                    dividerMargin: 0,
                    children: deletedNotes.map((note) {
                      final dateDeleted = DateTime.parse(note!['dateDeleted']);
                      final formattedDate = DateFormat('MMM d, y - h:mm a').format(dateDeleted);

                      return CupertinoListTile.notched(
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
                    dividerMargin: 0,
                    children: [
                      CupertinoListTile.notched(
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


class _ChangePasswordScreen extends StatefulWidget {
  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordCorrect = true;
  bool _doPasswordsMatch = true;

  void _changePassword() {
    final securityBox = Hive.box('securityBox');
    final storedPassword = securityBox.get('password');

    setState(() {
      _isCurrentPasswordCorrect = _currentPasswordController.text == storedPassword;
      _doPasswordsMatch = _newPasswordController.text == _confirmPasswordController.text;
    });

    if (_isCurrentPasswordCorrect && _doPasswordsMatch) {
      securityBox.put('password', _newPasswordController.text);
      Navigator.pop(context);
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Password Changed'),
          content: const Text('Your password has been updated successfully.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CupertinoTextField(
              controller: _currentPasswordController,
              placeholder: 'Current Password',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (!_isCurrentPasswordCorrect)
              const Padding(
                padding: EdgeInsets.only(top: 5, bottom: 10),
                child: Text(
                  'Incorrect current password',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: _newPasswordController,
              placeholder: 'New Password',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: _confirmPasswordController,
              placeholder: 'Confirm New Password',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (!_doPasswordsMatch)
              const Padding(
                padding: EdgeInsets.only(top: 5, bottom: 10),
                child: Text(
                  'Passwords do not match',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.systemOrange,
                onPressed: _changePassword,
                child: const Text(
                  'Change Password',
                  style: TextStyle(color: CupertinoColors.white), // Ensure text color is visible
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
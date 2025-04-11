import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  late Box settingsBox;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    isDarkMode = settingsBox.get('darkMode', defaultValue: false);
  }

  void toggleDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
      settingsBox.put('darkMode', value);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                'Appearance',
                style: TextStyle(
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Text('Dark Mode'),
                  trailing: CupertinoSwitch(
                    value: isDarkMode,
                    onChanged: toggleDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
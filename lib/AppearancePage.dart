import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Appearance'),
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
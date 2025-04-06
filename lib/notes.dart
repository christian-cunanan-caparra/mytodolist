import 'package:flutter/cupertino.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _searchQuery = '';
  List<Map<String, dynamic>> notesList = [];

  @override
  Widget build(BuildContext context) {
    final filteredNotes = notesList.where((note) {
      final title = note['title']?.toLowerCase() ?? '';
      return title.contains(_searchQuery);
    }).toList();

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
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.info_circle,
                      size: 23,
                      color: CupertinoColors.systemBlue,
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
              ),
            ),
            const SizedBox(height: 12),


            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(child: Text('No notes yet!'))
                  : ListView.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGroupedBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),


            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: CupertinoColors.systemGroupedBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.square_pencil,
                      color: CupertinoColors.systemYellow,
                      size: 28,
                    ),
                    onPressed: () {
                      // Add note dialog logic here
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

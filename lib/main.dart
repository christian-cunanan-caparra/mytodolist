import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async{
  await Hive.initFlutter();
  var box = await Hive.openBox('database');

  runApp(CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<dynamic> todolist = [];
  TextEditingController _addTask = TextEditingController();
  var box = Hive.box('database');
  @override
  void initState() {
    try{
      todolist = box.get('todo');
      print(todolist);
    }catch (e){
      todolist = [];
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Task', style: TextStyle(color: CupertinoColors.systemYellow),),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
          Row(
            children: [
              Text('ToDo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 30),),
            ],
          ),

                  Expanded(child: ListView.builder(
                      itemCount: todolist.length,
                      itemBuilder: (context, int index){
                        final item = todolist;
                        return GestureDetector(
                          onLongPress: (){
                            showCupertinoDialog(context: context, builder: (context){
                              return CupertinoAlertDialog(
                                title: Text('Delete'),
                                content: Text('Remove ${item[index]['task']} ?'),
                                actions: [
                                  CupertinoButton(child: Text('Yes', style: TextStyle(color: CupertinoColors.destructiveRed),), onPressed: (){
                                    setState(() {
                                      item.removeAt(index);
                                      box.put('todo', item);
                                    });
                                    Navigator.pop(context);
                                  }),
                                  CupertinoButton(child: Text('No'), onPressed: (){
                                    Navigator.pop(context);
                                  }),
                                ],
                              );
                            });
                          },
                          onTap: (){
                            setState(() {
                              item[index]['status'] = !item[index]['status'];
                              box.put('todo', item);
                            });
                          },
                          child: Container(
                            child: CupertinoListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item[index]['task'], style: TextStyle(decoration: item[index]['status']? TextDecoration.lineThrough : null),),
                                    Icon(CupertinoIcons.circle_fill, size: 15, color: item[index]['status']? CupertinoColors.systemGreen : CupertinoColors.destructiveRed,)
                                  ],
                                ),
                              subtitle: Divider(color: CupertinoColors.systemFill.withOpacity(0.5),),

                            ),
                          ),
                        );
                  })),

                  Container(
                    color: CupertinoColors.systemFill.withOpacity(0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('              '),
                        Text('${box.get('todo').length} ToDo'),
                       CupertinoButton(child: Icon(CupertinoIcons.square_pencil, color: CupertinoColors.systemYellow,), onPressed: (){

                         showCupertinoDialog(context: context, builder: (context){
                           return CupertinoAlertDialog(title: Text('Add Task'),
                           content: CupertinoTextField(
                             placeholder: 'Add To-Do',
                             controller: _addTask,
                           ),
                             actions: [
                               CupertinoButton(child: Text('Close', style: TextStyle(color: CupertinoColors.destructiveRed),), onPressed: (){
                                 _addTask.text = "";
                                 Navigator.pop(context);
                               }),
                               CupertinoButton(child: Text('Save'), onPressed: (){
                                 setState(() {
                                   todolist.add({
                                     "task" : _addTask.text,
                                     "status" : false
                                   });

                                   box.put('todo', todolist);
                                 });

                                 _addTask.text = "";
                                 Navigator.pop(context);
                               }),
                             ],
                           );
                         });

                       })
                      ],
                    ),
                  )
                ],
              ),
        ));
  }
}
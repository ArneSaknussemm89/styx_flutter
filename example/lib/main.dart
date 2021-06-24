import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styx/styx.dart';
import 'package:styx_flutter/styx_flutter.dart';

class TodoComponent extends Component {
  TodoComponent({String title = '', bool completed = false}) {
    this.title(title);
    this.completed(completed);
  }

  final title = ''.obs;
  final completed = false.obs;

  void complete() {
    completed.toggle();
  }
}

final system = EntitySystem();

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: EntityProvider(
        system: system,
        child: TodoListingPage(),
      ),
    );
  }
}

class TodoListingPage extends StatelessWidget {
  TodoListingPage({Key? key}) : super(key: key);

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: context.watchFilteredEntities(
                matcher: EntityMatcher(all: Set.of([TodoComponent])),
                builder: (context, matcher, todos) {
                  if (todos.isEmpty)
                    return Center(
                      child: Text('No Todos!'),
                    );
                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return todos[index].styx((data) {
                        return Dismissible(
                          key: ValueKey(data),
                          confirmDismiss: (direction) async {
                            if (data.get<TodoComponent>().completed()) {
                              data.destroy();
                              return true;
                            }
                            return false;
                          },
                          child: CheckboxListTile(
                            title: Text(
                              data.get<TodoComponent>().title(),
                              style: Theme.of(context).textTheme.headline5,
                            ),
                            value: data.get<TodoComponent>().completed(),
                            onChanged: (checked) => data.get<TodoComponent>().completed.value = checked!,
                          ),
                        );
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 80,
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  hintText: 'Create new todo...',
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          system.create()..set(TodoComponent(title: controller.text));
          controller.clear();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

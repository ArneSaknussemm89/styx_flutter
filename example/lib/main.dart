import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:styx/styx.dart';
import 'package:styx_flutter/styx_flutter.dart';

class TodoComponent extends Component {
  TodoComponent({String title = '', bool completed = false}) {
    this.title(title);
    this.completed(completed);
  }

  final title = ''.bs;
  final completed = false.bs;
  final editing = false.bs;

  @override
  void onRemoved() {
    title.close();
    completed.close();
    editing.close();
  }

  void complete() {
    completed(!completed());
  }

  void edit() {
    editing(!editing());
  }
}

class TodoViewModel extends Equatable {
  TodoViewModel({required this.title, required this.completed});

  final String title;
  final bool completed;

  @override
  List<Object> get props => [title, completed];

  Map<String, dynamic> toJson() => {
        'title': title,
        'completed': completed,
      };
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
                      final todo = todos[index];

                      return Dismissible(
                        key: ValueKey(todo.guid),
                        confirmDismiss: (direction) async {
                          if (todo.get<TodoComponent>().completed()) {
                            todo.destroy();
                            return true;
                          }
                          return false;
                        },
                        child: EntityBuilder<TodoViewModel>(
                          key: ValueKey(todo.guid),
                          streams: [
                            todo.get<TodoComponent>().title,
                            todo.get<TodoComponent>().completed,
                          ],
                          merge: (title, completed) => TodoViewModel(
                            title: title,
                            completed: completed,
                          ),
                          builder: (context, snapshot) {
                            return snapshot.when(
                              data: (model) => CheckboxListTile(
                                value: model.completed,
                                title: Text(model.title),
                                onChanged: (checked) => todo.get<TodoComponent>().completed(checked),
                              ),
                              error: (error, trace) => CheckboxListTile(
                                value: false,
                                title: Text(
                                  error
                                      .toString()
                                      .substring(0, error.toString().length > 144 ? 144 : error.toString().length),
                                ),
                                onChanged: (checked) {},
                              ),
                              loading: () => CircularProgressIndicator.adaptive(),
                            );
                          },
                        ),
                      );
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:styx/styx.dart';

import 'extensions.dart';

// Typedefs for the builders and a filter function.
typedef EntityWatcherFilterBuilder = Widget Function(BuildContext, EntityMatcher, List<Entity>);
typedef EntityWatcherBuilder = Widget Function(BuildContext, List<Entity>);
typedef EntityWatcherFilter = List<Entity> Function(BuildContext, List<Entity>);

typedef EntityDataBuilder<T> = Widget Function(T data);
typedef EntityErrorBuilder = Widget Function(Object? error, StackTrace? stackTrace);
typedef EntityEmptyBuilder = Widget Function();

/// An inherited widget that can provide entities to a section of the Widget tree.
///
/// Example:
///
/// class App extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: EntityProvider(
///           system: system,
///           child: EntityListWidget(),
///         ),
///       );
///     );
///   }
/// }
///
/// class EntityListWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final entities = EntityProvider.of(context).system.entities;
///     return Column(
///       children: [
///         ...entities.map((entity) {
///           return Text('Entity');
///         }),
///       ],
///     );
///   }
/// }
///
/// This is typically used in conjunction with EntityWatcher or context.watchFilteredEntities
/// to have a widget that rebuilds anytime the EntityProvider's entity list updates.
///
class EntityProvider<T extends EntitySystem> extends InheritedWidget {
  const EntityProvider({Key? key, required Widget child, required this.system}) : super(key: key, child: child);

  final T system;

  static EntityProvider of<T extends EntitySystem>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<EntityProvider<T>>();
    assert(provider != null, 'Unable to find EntityProvider in this build context');
    return provider!;
  }

  static BehaviorSubject<List<Entity>> entities<T extends EntitySystem>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<EntityProvider<T>>();
    assert(provider != null, 'Unable to find EntityProvider in this build context');
    return provider!.system.entities;
  }

  @override
  bool updateShouldNotify(covariant EntityProvider oldWidget) {
    return oldWidget.system != system;
  }
}

extension EntityProviderWatcher on BuildContext {
  Widget watchFilteredEntities<T extends EntitySystem>({
    required EntityMatcher matcher,
    required EntityWatcherFilterBuilder builder,
  }) =>
      EntityWatcher<T>(matcher: matcher, builder: builder);

  Widget watchEntities<T extends EntitySystem>({
    required EntityWatcherBuilder builder,
    required EntityErrorBuilder error,
    required EntityEmptyBuilder loading,
  }) {
    return entities<T>().styx(
      data: (data) => builder(this, data),
      error: error,
      loading: loading,
    );
  }
}

/// A component that expect an EntitySystem type and will do a lookup in the current widget tree for
/// that EntityProvider and watch those entities.
///
/// A provided matcher filters the entities passed to the builder.
class EntityWatcher<T extends EntitySystem> extends StatefulWidget {
  const EntityWatcher({
    Key? key,
    required this.matcher,
    required this.builder,
    this.filter,
  }) : super(key: key);

  final EntityMatcher matcher;
  final EntityWatcherFilterBuilder builder;
  final EntityWatcherFilter? filter;

  @override
  _EntityWatcherState<T> createState() => _EntityWatcherState();
}

class _EntityWatcherState<T extends EntitySystem> extends State<EntityWatcher> {
  late StreamSubscription _listWatcher;

  /// Map of tracked entities guid => entity.
  Map<String, Entity> _entities = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Set watcher if null.
    _listWatcher = context.entities<T>().listen(refreshList);
  }

  @override
  void dispose() {
    _listWatcher.cancel();
    _entities.clear();
    super.dispose();
  }

  /// This is where we set up all the workers for watching changes to entities in the provided system.
  ///
  /// Every time the watched list of entities changes (entities are added or removed) we add a watcher for that
  /// entity so if any entity changes we rebuild this widget. Then when this widget builds, it filters the entities
  /// according to the matcher and then provides that list to the builder.
  ///
  /// So the builder will be called anytime entities are removed/added to the watched EntityProvider OR if any Entity
  /// in that provider actually changes it's components.
  ///
  /// Changing component values will *not* cause this to rebuild unless using the .update() method on the Rx<Entity>
  ///
  ///
  void refreshList(List<Entity> value) {
    _entities = Map.fromIterable(value, key: (entity) => entity.guid);

    // Call for rebuild.
    setState(() {});
  }

  /// Currently when this widget builds we filter the watched entities that match the provided matcher and then
  /// we pass those to the builder.
  @override
  Widget build(BuildContext context) {
    final entities = _entities.values
        .where(
          (element) => widget.matcher.matches(element),
        )
        .toList(growable: false);
    return widget.builder(context, widget.matcher, entities);
  }
}

// A builder where you can pass multiple streams and then a provided merge function
// will merge the data together into T and then that data is passed to the stream builder.
class EntityBuilder<T> extends StatefulWidget {
  const EntityBuilder({
    Key? key,
    this.streams = const [],
    required this.merge,
    required this.builder,
  }) : assert(streams.length > 1), super(key: key);

  final List<ValueStream> streams;
  final Function merge;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<EntityBuilder<T>> createState() => _EntityBuilderState<T>();
}

class _EntityBuilderState<T> extends State<EntityBuilder<T>> {
  // @TODO: Ability to handle "selects" and only rebuild when selected data changes.
  T? _selected;
  T? _initial;
  late Stream<T> _stream;

  @override
  void initState() {
    super.initState();
    // decide which combiner we need.
    switch (widget.streams.length) {
      case 2:
        _stream = Rx.combineLatest2(
          widget.streams[0],
          widget.streams[1],
          (a, b) => widget.merge.call(a, b),
        );
        _initial = widget.merge.call(
          widget.streams[0].value,
          widget.streams[1].value,
        );
        break;
      case 3:
        _stream = Rx.combineLatest3(
          widget.streams[0],
          widget.streams[1],
          widget.streams[2],
          (a, b, c) => widget.merge.call(a, b, c),
        );
        _initial = widget.merge.call(
          widget.streams[0].value,
          widget.streams[1].value,
          widget.streams[2].value,
        );
        break;
      case 4:
        _stream = Rx.combineLatest4(
          widget.streams[0],
          widget.streams[1],
          widget.streams[2],
          widget.streams[3],
          (a, b, c, d) => widget.merge.call(a, b, c, d),
        );
        _initial = widget.merge.call(
          widget.streams[0].value,
          widget.streams[1].value,
          widget.streams[2].value,
          widget.streams[3].value,
        );
        break;
      case 5:
        _stream = Rx.combineLatest5(
          widget.streams[0],
          widget.streams[1],
          widget.streams[2],
          widget.streams[3],
          widget.streams[4],
          (a, b, c, d, e) => widget.merge.call(a, b, c, d, e),
        );
        _initial = widget.merge.call(
          widget.streams[0].value,
          widget.streams[1].value,
          widget.streams[2].value,
          widget.streams[3].value,
          widget.streams[4].value,
        );
        break;
      default:
        _stream = Rx.combineLatest(widget.streams, (list) => widget.merge.call(list));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(builder: widget.builder, stream: _stream, initialData: _initial);
  }
}

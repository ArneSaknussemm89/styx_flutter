import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styx/styx.dart';

import 'extensions.dart';

// Typedefs for the builders and a filter function.
typedef EntityWatcherFilterBuilder = Widget Function(BuildContext, EntityMatcher, List<Rx<Entity>>);
typedef EntityWatcherBuilder = Widget Function(BuildContext, List<Rx<Entity>>);
typedef EntityWatcherFilter = RxList<Rx<Entity>> Function(BuildContext, List<Rx<Entity>>);

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

  static RxList<Rx<Entity>> entities<T extends EntitySystem>(BuildContext context) {
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

  Widget watchEntities<T extends EntitySystem>({required EntityWatcherBuilder builder}) {
    final watchedEntities = entities<T>();
    return Obx(() {
      return builder(this, watchedEntities);
    });
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
  Worker? _listWatcher;

  /// Map of entity guid => worker
  Map<String, Worker> _itemWatchers = {};

  /// Map of tracked entities guid => entity.
  Map<String, Rx<Entity>> _entities = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Set the entities.
    final ents = context.entities<T>();
    ents.forEach((entity) {
      _entities[entity().guid] = entity;
      _itemWatchers[entity().guid] = ever(entity, rebuild);
    });

    /// Set watcher if null.
    _listWatcher = ever(ents, (List<Rx<Entity>> list) {
      refreshList(list);
    });
  }

  @override
  void dispose() {
    _listWatcher?.dispose();
    _entities.clear();
    clearWatchers();
    super.dispose();
  }

  void clearWatchers() {
    _itemWatchers.forEach((key, value) => value.dispose());
    _itemWatchers.clear();
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
  void refreshList(List<Rx<Entity>> newEntities) {
    newEntities.forEach((entity) {
      if (_entities[entity().guid] == null) {
        // Add the entity to the list and set up the listener.
        _entities[entity().guid] = entity;
        _itemWatchers[entity().guid] = ever<Entity>(entity, rebuild);
      }
    });

    // Now we get our current keys, and the keys from the updated list.
    final currentKeys = Set.from(_entities.keys);
    final newKeys = newEntities.map((e) => e().guid).toSet();

    // This should gives us keys that were in current that are NOT in the new set. These items are no longer
    // in the provided system, so we remove it from our list and dispose the watcher.
    final unusedKeys = currentKeys.difference(newKeys);
    if (unusedKeys.isNotEmpty) {
      unusedKeys.forEach((guid) {
        // Remove entity and dispose watcher.
        _entities.remove(guid);

        // Dispose watcher and remove
        _itemWatchers[guid]?.dispose();
        _itemWatchers.remove(guid);
      });
    }

    // Call for rebuild.
    setState(() {});
  }

  // If any tracked entity changes, rebuild.
  void rebuild(Entity entity) {
    setState(() {});
  }

  /// Currently when this widget builds we filter the watched entities that match the provided matcher and then
  /// we pass those to the builder.
  @override
  Widget build(BuildContext context) {
    final entities = _entities.values.where((element) => widget.matcher.matches(element)).toList(growable: false);
    return widget.builder(context, widget.matcher, entities);
  }
}

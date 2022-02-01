import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:styx/styx.dart';

import 'widgets.dart';

extension EntityProviderExt on BuildContext {
  EntityProvider entityProvider<T extends EntitySystem>() {
    final p = dependOnInheritedWidgetOfExactType<EntityProvider<T>>();
    assert(p != null, 'EntityProvider not found in this build context.');
    return p!;
  }

  BehaviorSubject<List<Entity>> entities<T extends EntitySystem>() {
    final p = dependOnInheritedWidgetOfExactType<EntityProvider<T>>();
    assert(p != null, 'EntityProvider not found in this build context.');
    return p!.system.entities;
  }
}

extension StyxWatcherOnBehaviorSubject<T> on BehaviorSubject<T> {
  Widget styx({
    required EntityDataBuilder<T> data,
    required EntityErrorBuilder error,
    required EntityEmptyBuilder loading,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        return snapshot.when(
          data: data,
          error: error,
          loading: loading,
        );
      },
    );
  }

  Widget styxData(EntityDataBuilder<T> data) {
    return StreamBuilder<T>(
      builder: (context, snapshot) {
        return snapshot.when(
          data: data,
          error: (error, stackTrace) => const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
        );
      },
      stream: stream,
    );
  }
}

extension StyxWatcherOnPublishSubject<T> on PublishSubject<T> {
  Widget styx({
    required EntityDataBuilder<T> data,
    required EntityErrorBuilder error,
    required EntityEmptyBuilder loading,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        return snapshot.when(
          data: data,
          error: error,
          loading: loading,
        );
      },
    );
  }

  Widget styxData(EntityDataBuilder<T> data) {
    return StreamBuilder<T>(
      builder: (context, snapshot) {
        return snapshot.when(
          data: data,
          error: (error, stackTrace) => const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
        );
      },
      stream: stream,
    );
  }
}

extension StyxWatcherOnReplaySubject<T> on ReplaySubject<T> {
  Widget styx({
    required EntityDataBuilder<T> data,
    required EntityErrorBuilder error,
    required EntityEmptyBuilder loading,
  }) {
    return StreamBuilder<T>(
      builder: (context, snapshot) {
        return snapshot.when(
          data: data,
          error: error,
          loading: loading,
        );
      },
      stream: stream,
    );
  }

  Widget styxData(EntityDataBuilder<T> data) {
    return StreamBuilder<T>(
      builder: (context, snapshot) {
        return snapshot.when(
          data: data,
          error: (error, stackTrace) => const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
        );
      },
      stream: stream,
    );
  }
}

extension AsyncSnapshotWhen<T> on AsyncSnapshot<T> {
  /// Performs an action based on the state of the [AsyncSnapshot].
  ///
  /// All cases are required, which allows returning a non-nullable value.
  Widget when({
    required EntityDataBuilder<T> data,
    required EntityErrorBuilder error,
    required EntityEmptyBuilder loading,
  }) {
    switch (this.connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
        return loading();
      case ConnectionState.active:
      case ConnectionState.done:
        if (hasError) return error(this.error, stackTrace);
        return data(this.data!);
    }
  }
}

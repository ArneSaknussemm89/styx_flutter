import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styx/styx.dart';

import 'widgets.dart';

extension EntityProviderExt on BuildContext {
  EntityProvider entityProvider<T extends EntitySystem>() {
    final p = dependOnInheritedWidgetOfExactType<EntityProvider<T>>();
    assert(p != null, 'EntityProvider not found in this build context.');
    return p!;
  }

  RxList<Rx<Entity>> entities<T extends EntitySystem>() {
    final p = dependOnInheritedWidgetOfExactType<EntityProvider<T>>();
    assert(p != null, 'EntityProvider not found in this build context.');
    return p!.system.entities;
  }
}

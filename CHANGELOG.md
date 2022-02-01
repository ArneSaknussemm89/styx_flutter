## [2.0.0] - 31/01/2022

**BREAKING CHANGES**
- Removed dependency on `get` and moved to `rxdart`.
- EntityWatcher now returns `List<Entity>` instead of `List<Rx<Entity>>`.
- `BuildContext`'s `watchedFilteredEntities` and `watchEntities` methods now return `List<Entity>` instead of `List<Rx<Entity>>`.

- Added a new widget `EntityBuilder` that allows you to merge `ValueStreams` into a single value and then rebuilds when those streams emit new values.
- Added new extension `when` on `AsyncSnapshot` that simplifies building a widget based on the state of an `AsyncSnapshot`.
- Added new extension `styx` on `Subject`s that simplifies building a widget based on values emitted by a `Subject`.
- Added new extensions `.ps` and `.bs` and `.rs` on built-in simple types and then on generics that can easily turn a value into a `Subject`.

## [1.3.1] - 24/06/2021

Fixed:
- An issue with too many workers being created and not being cleared from the Watcher.

## [1.3.0] - 23/06/2021

Initial release! Adds Flutter specific Widgets to use with Styx to inject entities into your widget
tree. See example for more info.

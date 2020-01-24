<h1>Pawns</h1>

In the context of XCOM 2, *Pawns* are the Unreal-3D representation of units and weapons.
These Pawns define the 3D meshes and materials, their attachments, animations, and state.

A pawn always has an *archetype* that is usually specified in the template. When a unit or weapon
is spawned, a clone of the archetype is created and placed in the 3D world. This leaves mods that want to
make modifications with two options:

* **Modify the archetype:** The archetype can be dynamically loaded (`RequestGameArchetype`/`DynamicLoadObject`) by mods for modification.
This can, especially with many mods, take a fair while as some mods would have to load every archetype they want to modify.
It also interacts badly with the garbage collector, as unused archetypes will be removed from memory and have their
changes reverted.
Additionally, these changes are static; all future instances will be affected the same and different instances cannot receive individual changes.

* **Modify the instance:** The mod finds a way to modify the instance that was just created as a clone. This allows mods to change
things that are considered properties of the archetype on a per-instance basis. However, it is difficult to reliably receive a
notification when an archetype is cloned and a new instance is created. The Highlander can help with this by triggering events
and calling DLC hooks whenever mods may need to change instance properties.

This page contains a list of features that can help with pawn modification on a per-instance basis.


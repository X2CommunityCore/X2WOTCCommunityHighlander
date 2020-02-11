<h1>Events</h1>

Many of the Highlander's features utilize *Event Hooks*. Mods can subscribe to
any event by name, and then

* Read some of the data passed with the event
* Perform actions in response to the event
* Send data back to the sender of the event

Especially the last option is something many Highlander hooks expect mods to do.

This is done with the [`XComLWTuple`](misc/XComLWTuple.md) class. It can contain arbitrary
tagged data, can be read and written to by mods. Consider it a polymorphic tuple that is
compatible with any event trigger/listener signature.

The following is a list of all pages tagged "Events" due to their relevance to or
use of the event system.


<h1>X2DownloadableContentInfo Hooks</h1>

Many of the Highlander's features utilize function calls to the subclasses of
X2DownloadableContentInfo that all mods require. These are known colloquially
as DlcInfo hooks, and are commonly used as an alternative when an event will
not work for a given feature.

Mods can define a function of the same name with the same arguments in their
X2DownloadableContentInfo file, and then perform any custom handling.

Unlike events, these DlcInfo hooks are not limited to two arguments. However,
they are much slower than events are, so events should generally be used.


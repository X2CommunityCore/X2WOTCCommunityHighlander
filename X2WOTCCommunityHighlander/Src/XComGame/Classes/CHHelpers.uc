class CHHelpers extends Object config(Game);

var config int SPAWN_EXTRA_TILE; // Issue #18 - Add extra ini config
var config int MAX_TACTICAL_AUTOSAVES; // Issue #53 - make configurable, only use if over 0

// Start Issue #41 
// allow chosen to ragdoll, and to collide via config.
// will have performance impacts as the physics will not turn off.
var config bool ENABLE_CHOSEN_RAGDOLL;
var config bool ENABLE_RAGDOLL_COLLISION;
// End Issue #41


//start issue #82
//have game choose from an array of names in config when initing custom factions
//this is so mods can expand that when custom chosen start being added
var config array<name> FACTIONS_AT_START;
//End issue #82
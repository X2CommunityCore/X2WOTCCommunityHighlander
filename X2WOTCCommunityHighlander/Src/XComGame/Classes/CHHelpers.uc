class CHHelpers extends Object config(Game);

var config int SPAWN_EXTRA_TILE; // Issue #18 - Add extra ini config

// Start Issue #41 
// allow chosen to ragdoll, and to collide via config.
// will have performance impacts as the physics will not turn off.
var config bool ENABLE_CHOSEN_RAGDOLL;
var config bool ENABLE_RAGDOLL_COLLISION;
// End Issue #41

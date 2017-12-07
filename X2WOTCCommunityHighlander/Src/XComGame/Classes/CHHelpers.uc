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
//allow factions to be filtered at game start so we don't have broken base game factions
var config array<name> EXCLUDED_FACTIONS;
//end issue #82

//start issue #85
//variable for controlling whether the game is allowed to track whether a unit has ever gotten a trait before
//this is kept disabled for balance reasons
var config bool CHECK_CURED_TRAITS;
//end issue #85

// Start Issue #80
// List of classes to exclude from rolling awc abilities
// These classes have bAllowAWCAbilities set to true just to participate in the ComInt / AP system
var config array<name> ClassesExcludedFromAWCRoll;
// End Issue #80

// Start Issue #240
// PI Added: Configure auto remove equipment. These have two different senses to ensure that all false values
// maintains baseline behavior.
var config bool NoStripWoundedInventory;	// If true, suppress the normal behavior of stripping utility items from wounded soldiers.
var config bool NoStripOnTraining;			// If true, suppress the normal behavior of stripping items when a soldier is put
											// in a training slot. Note that this is not referenced in this class but is 
											// added here for consistency and back-compatibility to keep related flags together.
var config bool AutoStripWoundedAllItems;	// If true, also strip other equipment slots on wounded soldiers.
// End Issue #240

/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup for each mod
 **/
class X2WOTCCH_DialogCallbackData extends UICallbackData dependson (X2WOTCCH_ModDependencies);

var ModDependency DependencyData;
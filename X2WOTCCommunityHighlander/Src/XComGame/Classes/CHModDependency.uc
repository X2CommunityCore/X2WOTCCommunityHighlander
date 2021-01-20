class CHModDependency extends Object perobjectconfig Config(Game);

var config array<string> IncompatibleMods;
var config array<string> IgnoreIncompatibleMods;
var config array<string> RequiredMods;
var config array<string> IgnoreRequiredMods;
var config string DisplayName;

final function bool IsInteresting()
{
	return IncompatibleMods.Length > 0 || RequiredMods.Length > 0
		|| IgnoreIncompatibleMods.Length > 0 || IgnoreRequiredMods.Length > 0
		|| DisplayName != "";
}
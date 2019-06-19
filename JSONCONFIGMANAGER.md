## JsonConfig Manager
The JsonConfig Manager introduces a new method of defining config values as json string.

```
[Mod.MyModConfigManager]
+ConfigProperties = {"BAR":{"Value":"Foo"}}
```
these config values can be accessed like `class'MyModConfigManager'.static.GetConfigStringValue("BAR")`

The advantage over regular config properties is that they can be accessed by string identifiers which makes automatic localization tag generation and mapping in the MCMBuilder possible.

### Tag generation

There are a whole bunch of meta attributes you can use for localization tag generation. Here are some example:

```
+ConfigProperties = {"ACTIVIST_DETECTION_MOD":{"Value":"-5", "TagFunction":"TagValueMetersToTiles"}}
+ConfigProperties = {"ACTIVIST_DETECTION_MOD_CIVS":{"Value":"0.5", "TagFunction":"TagValueToPercent", "TagSuffix": "%"}}
+ConfigProperties = {"AGRESSION_CRIT_CHANCE":{"Value":"5", "TagPrefix":"+"}}
+ConfigProperties = {"AGRESSION_SCALE_MAX":{"Value":"6", "TagPrefix":"+", "TagFunction":"TagValueParamMultiplication", "TagParam":"AGRESSION_CRIT_CHANCE"}}
+ConfigProperties = {"AIRSTRIKECHARGES":{"Value":"1"}};
+ConfigProperties = {"AIRSTRIKEDAMAGE":{"DamageValue":{"Damage": 10, "Spread": 2, "Shred": 3, "DamageType":"Explosion"}}}
+ConfigProperties = {"ANARCHIST_CHARGES":{"Value":"1"}}
+ConfigProperties = {"ANARCHIST_CRIT":{"Value":"2", "TagPrefix":"+", "TagSuffix":"%"}}
+ConfigProperties = {"ANARCHIST_CRIT_MAX":{"Value":"50", "TagSuffix":"%"}}
+ConfigProperties = {"ARCTHROWER_ABILITIES":{"ArrayValue":"ArcThrowerStun, EMPulser, ChainLightning"}}
```

The mapping code in client mods DLCInfo class just looks like thus:

```
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local string PossibleValue;

	PossibleValue = class'TestModUserSettingsConfigManager'.static.GetConfigTagValue(InString);
	if (PossibleValue != "")
	{
		OutString = PossibleValue;
		return true;
	}

	return false;
}
```

#### Complete Example:

Config:
```
+ConfigProperties = {"MILITIA_AIM":{"Value":"3", "TagPrefix":"+"}}
+ConfigProperties = {"MILITIA_RANGE_MULTIPLIER":{"Value":"0.5", "TagPrefix": "-" , "TagFunction":"TagValueToPercent"}}
+ConfigProperties = {"MILITIA_SIGHT_RADIUS":{"Value":"3", "TagPrefix":"+", "TagSuffix":" tiles", "TagFunction":"TagValueMetersToTiles"}}}
```

Usage:
```
static function X2AbilityTemplate Militia()
{
	local X2AbilityTemplate				Template;
	local X2Effect_RangeMultiplier			RangeEffect;
	local X2Effect_PersistentStatChange		Effect;

	RangeEffect = new class'X2Effect_RangeMultiplier';
	RangeEffect.RangeMultiplier=class'RPGOAbilityConfigManager'.static.GetConfigFloatValue("MILITIA_RANGE_MULTIPLIER");
	RangeEffect.BuildPersistentEffect(1, true, false, false);

	Template = Passive('APT_Militia', "img:///UILibrary_PerkIcons.UIPerk_Urban_Aim", true, RangeEffect);

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.AddPersistentStatChange(eStat_Offense, class'RPGOAbilityConfigManager'.static.GetConfigIntValue("MILITIA_AIM"));
	Effect.AddPersistentStatChange(eStat_SightRadius, class'RPGOAbilityConfigManager'.static.GetConfigIntValue("MILITIA_SIGHT_RADIUS"));

	AddSecondaryEffect(Template, Effect);

	return Template;
}
```

Localization:
`LocLongDescription="A militia marksman from one of the Resistance camps we saved. Has <Ability:MILITIA_AIM/> aim and <Ability:MILITIA_SIGHT_RADIUS/> sight radius, and <Ability:MILITIA_RANGE_MULTIPLIER/> weapon range penalties."`

Expanded String:
`A militia marksman from one of the Resistance camps we saved. Has +1 aim and +2 tiles sight radius, and -50% weapon range penalties.`

#### TagFunctions:
There are some predefined functions you can use in tag generation and to convert values on the fly:

- TagValueToPercent
- TagValueToPercentMinusHundred
- TagValueMetersToTiles
- TagValueTilesToMeters
- TagValueTilesToUnits
- TagValueParamAddition
- TagValueParamMultiplication
- TagArrayValue

usage for tag generation:
`+ConfigProperties = {"MILITIA_RANGE_MULTIPLIER":{"Value":"0.5", "TagFunction":"TagValueToPercent"}}`

usage for converting values in code:
`ConeMultiTarget.ConeEndDiameter = class'RPGOAbilityConfigManager'.static.GetConfigIntValue("SPRAY_TILE_WIDTH", "TagValueTilesToUnits");`

In your derived config manager you can even add your own custom TagFunctions:

```
class RPGOAbilityConfigManager extends JsonConfig_Manager config (RPGO_SoldierSkills);

function bool OnTagFunction(name TagFunctionName, JsonConfig_TaggedConfigProperty ConfigProperty, out string TagValue)
{
	switch (TagFunctionName)
	{
		case 'TagValueLockDown':
			 TagValue = string(Round(float(ConfigProperty.GetValue()) * (1 - class'X2AbilityToHitCalc_StandardAim'.default.REACTION_FINALMOD)));
			 return true;
			 break;
		default:
			break;
	}

	return false;
}
```

### Clientside Usage
So how do you use this awesomeness in your mod?
You need to compile you mod agains the Highlander.
Then simply add two files:

1. A mod manager derived from `JsonConfig_Manager`
```
class MyModSettingsConfigManager extends JsonConfig_Manager config(MyModSettings);
```

2. A config file with a valid json config
```
[Mod.MyModConfigManager]
+ConfigProperties = {"BAR":{"Value":"Foo"}}
```

For the tag generation add the AbilityTagExpandHandler code snippet above to you DLCInfo file.

Thats all!

you can start using your config values like 
```
// in unreal code
class'MyModSettingsConfigManager'.static.GetConfigStringValue("BAR");

// in localization files
LocLongDescription="Hello World <Ability:BAR/>=Bar"
```
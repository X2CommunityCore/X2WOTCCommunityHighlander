## MCM Builder

MCM Builder provides a new way of creating MCM Pages.
Instead of writing the mcm code the pages are completely generated from a json config.
Lets get right down to it and have a look at this example config:

```
[MCMBuilderClientTestMod.TestMod_MCM_Builder]
+MCMPages = { \\
	"TESTMOD_SETTINGS_PAGE":{ \\
		"SaveConfigManager": "TestModUserSettingsConfigManager",\\
		"EnableResetButton": "true", \\
		"TESTMOD_SETTINGS_GROUP_1":{ \\
			"A_BOOL_PROPERTY":  { "Type": "Checkbox" }, \\
			"A_FLOAT_PROPERTY": { "Type": "Slider", "SliderMin": "0.0", "SliderMax": "1.0", "SliderStep":"0.1" }, \\
			"A_INT_PROPERTY":   { "Type": "Spinner", "Options": "1, 2, 3, 4, 5, 6, 7, 8, 9, 10" }, \\
			"A_STRING_PROPERTY":{ "Type": "Dropdown", "Options": "Bar, Foo, Test" }, \\
		}, \\
		"TESTMOD_SETTINGS_GROUP_2":{ \\
			"A_LABEL":          { "Type": "Label" }, \\
		}, \\
	}, \\
}
```

This small config is enough to generate a complete MCM page.
Lets have a look at the elements in detail.

### Pages and Groups

```
TESTMOD_SETTINGS_PAGE
TESTMOD_SETTINGS_GROUP_1
TESTMOD_SETTINGS_GROUP_2
```
are mcm page or group identifiers that are used to for localization mapping:
`MCMBuilderClientTestMod.int`
```
[TestMod_MCM_Builder]

TESTMOD_SETTINGS_PAGE_TITLE="Test Mod"
TESTMOD_SETTINGS_PAGE_LABEL="MCMBuilder Test Mod"

TESTMOD_SETTINGS_GROUP_1_LABEL="First settings group"
TESTMOD_SETTINGS_GROUP_2_LABEL="Second setting group"
```

There are two special config properties:

`"SaveConfigManager": "TestModUserSettingsConfigManager"`

This references the config manager you want to use to get default config properties and thats responsible to save your properties to the user config directory.

`"EnableResetButton": "true"`

this just tells the builder if you want to display a reset button on your page.

### Elements
```
"A_BOOL_PROPERTY":  { "Type": "Checkbox" }, \\
"A_FLOAT_PROPERTY": { "Type": "Slider", "SliderMin": "0.0", "SliderMax": "1.0", "SliderStep":"0.1" }, \\
"A_INT_PROPERTY":   { "Type": "Spinner", "Options": "1, 2, 3, 4, 5, 6, 7, 8, 9, 10" }, \\
"A_STRING_PROPERTY":{ "Type": "Dropdown", "Options": "Bar, Foo, Test" }, \\
"A_LABEL":          { "Type": "Label" }, \\
```

These are the actual mcm elements that are displayed.
The identifiers (like "A_BOOL_PROPERTY") are actual referencing config properties from the JsonConfigManager System.

localization works the same as with pages and groups:
Just define localization properties following the convention:
```
<PROPERTY_NAME>_LABEL
<PROPERTY_NAME>_TOOLTIP
```
e.g.
```
A_BOOL_PROPERTY_LABEL="Checkbox"
A_BOOL_PROPERTY_TOOLTIP="A bool property checkbox"

A_INT_PROPERTY_LABEL="Spinner"
A_INT_PROPERTY_TOOLTIP="A int property spinner"

A_FLOAT_PROPERTY_LABEL="Slider"
A_FLOAT_PROPERTY_TOOLTIP="A float property slider"

A_STRING_PROPERTY_LABEL="Dropdown"
A_STRING_PROPERTY_TOOLTIP="A string property dropdown"

A_LABEL_LABEL="Label"
A_LABEL_TOOLTIP="Just a tooltip"
```

## Client Side Integration
You need to compile your mod against the Highlander.
Minimum you need these files:

- `XComUI.ini`
- `XComYourModMCMBuilder.ini`
- `XComYourModDefaultSettings.ini`
- `YourModDefaultSettingsConfigManager.uc`
- `YourModUserSettingsConfigManager.uc`
- `YourModMCM_Builder.uc`

Lets see there contents in detail:

##### `XComUI.ini`
```
[X2WOTCCommunityHighlander.X2WOTCCommunityHighlander_MCMScreen]
+MCMBuilderClasses="YourModMCM_Builder"
```
##### `XComYourModMCMBuilder.ini`
```
[YourMod.YourModMCM_Builder]
+MCMPages = { \\
	"TESTMOD_SETTINGS_PAGE":{ \\
		"SaveConfigManager": "YourModUserSettingsConfigManager",\\
		"EnableResetButton": "true", \\
		"TESTMOD_SETTINGS_GROUP_1":{ \\
			"A_BOOL_PROPERTY":					{ "Type": "Checkbox" }, \\
			"A_FLOAT_PROPERTY":					{ "Type": "Slider", "SliderMin": "0.0", "SliderMax": "1.0", "SliderStep":"0.1" }, \\
			"A_INT_PROPERTY":					{ "Type": "Spinner", "Options": "1, 2, 3, 4, 5, 6, 7, 8, 9, 10" }, \\
			"A_STRING_PROPERTY":				{ "Type": "Dropdown", "Options": "Bar, Foo, Test" }, \\
		}, \\
		"TESTMOD_SETTINGS_GROUP_2":{ \\
			"A_LABEL":							{ "Type": "Label" }, \\
		}, \\
	}, \\
}
```
##### `XComYourModDefaultSettings.ini`
```
[YourMod.YourModDefaultSettingsConfigManager]
+ConfigProperties = {"A_BOOL_PROPERTY":{"Value":"true"}}
+ConfigProperties = {"A_INT_PROPERTY":{"Value":"1"}}
+ConfigProperties = {"A_FLOAT_PROPERTY":{"Value":"0.1"}}
+ConfigProperties = {"A_STRING_PROPERTY":{"Value":"Foo"}}
```
##### `YourModDefaultSettingsConfigManager.uc`
```
class YourModDefaultSettingsConfigManager extends JsonConfig_Manager config(YourModDefaultSettings);
```

##### `YourModUserSettingsConfigManager.uc`
```
class YourModUserSettingsConfigManager extends JsonConfig_Manager config(YourModUserSettings_NullConfig);

defaultproperties
{
	Begin Object Class=TestModDefaultSettingsConfigManager Name=DefaultConfigManager0
	End Object
	DefaultConfigManager = DefaultConfigManager0;
}
```

#### `YourModMCM_Builder.uc`
```
class YourModMCM_Builder extends JsonConfig_MCM_Builder config(YourModMCMBuilder);
```

### Thats all!
The MCMBuilder in the Highlander will take care of the rest.

See the full example project here: https://github.com/Musashi1584/MCMBuilderClientTestMod
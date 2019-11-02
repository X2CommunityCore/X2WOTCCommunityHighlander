class X2DataSet extends Object 
	native(Core) 
	dependson(X2GameRuleset, XComGameStateVisualizationMgr);

// Issue #413 - unprotected the field
var bool bShouldCreateDifficultyVariants;

/// <summary>
/// Native accessor for CreateTemplates. Used by the engine object and template manager
/// to automatically pick up new templates.
/// </summary>
static event array<X2DataTemplate> CreateTemplatesEvent()
{
	local array<X2DataTemplate> BaseTemplates, NewTemplates;
	local X2DataTemplate CurrentBaseTemplate;
	local int Index;

	BaseTemplates = CreateTemplates();

	for( Index = 0; Index < BaseTemplates.Length; ++Index )
	{
		CurrentBaseTemplate = BaseTemplates[Index];
		CurrentBaseTemplate.ClassThatCreatedUs = default.Class;

		if( default.bShouldCreateDifficultyVariants )
		{
			CurrentBaseTemplate.bShouldCreateDifficultyVariants = true;
		}

		if( CurrentBaseTemplate.bShouldCreateDifficultyVariants )
		{
			CurrentBaseTemplate.CreateDifficultyVariants(NewTemplates);
		}
		else
		{
			NewTemplates.AddItem(CurrentBaseTemplate);
		}
	}

	return NewTemplates;
}

/// <summary>
/// Override this method in sub classes to create new templates by creating new X2<Type>Template
/// objects and filling them out.
/// </summary>
static function array<X2DataTemplate> CreateTemplates();

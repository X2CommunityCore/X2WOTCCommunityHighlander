//---------------------------------------------------------------------------------------
//  FILE:    X2EventListenerTemplateManager.uc
//  AUTHOR:  David Burchanowsk
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2EventListenerTemplateManager extends X2DataTemplateManager
	native(Core);

static function native X2EventListenerTemplateManager GetEventListenerTemplateManager();

event X2EventListenerTemplate FindEventListenerTemplate(name TemplateName)
{
	local X2EventListenerTemplate Template;

	Template = X2EventListenerTemplate(FindDataTemplate(TemplateName));
	if(Template == none)
	{
		`Redscreen("Could not find X2EventListenerTemplate " $ TemplateName);
	}

	return Template;
}

static function RegisterTacticalListeners()
{
	local X2EventListenerTemplate ListenerTemplate;
	local X2DataTemplate Template;

	// unregister any previously registered templates
	UnRegisterAllListeners();

	foreach GetEventListenerTemplateManager().IterateTemplates(Template)
	{
		ListenerTemplate = X2EventListenerTemplate(Template);
		if(ListenerTemplate.RegisterInTactical)
		{
			ListenerTemplate.RegisterForEvents();
		}
	}
}

static function RegisterStrategyListeners()
{
	local X2EventListenerTemplate ListenerTemplate;
	local X2DataTemplate Template;

	// unregister any previously registered templates
	UnRegisterAllListeners();

	foreach GetEventListenerTemplateManager().IterateTemplates(Template)
	{
		ListenerTemplate = X2EventListenerTemplate(Template);
		if(ListenerTemplate.RegisterInStrategy)
		{
			ListenerTemplate.RegisterForEvents();
		}
	}
}

// Start Issue #869
//
// Registers CHL event listeners that are configured to listen for
// events during a new campaign start.
static function RegisterCampaignStartListeners()
{
	local CHEventListenerTemplate ListenerTemplate;
	local X2DataTemplate Template;

	UnRegisterAllListeners();

	foreach GetEventListenerTemplateManager().IterateTemplates(Template)
	{
		ListenerTemplate = CHEventListenerTemplate(Template);
		if (ListenerTemplate != none && ListenerTemplate.RegisterInCampaignStart)
		{
			ListenerTemplate.RegisterForEvents();
		}
	}
}
// End Issue #869

static function UnRegisterAllListeners()
{
	local X2EventListenerTemplate ListenerTemplate;
	local X2DataTemplate Template;

	foreach GetEventListenerTemplateManager().IterateTemplates(Template)
	{
		ListenerTemplate = X2EventListenerTemplate(Template);
		ListenerTemplate.UnRegisterFromEvents();
	}
}

defaultproperties
{
	TemplateDefinitionClass=class'X2EventListener'
}

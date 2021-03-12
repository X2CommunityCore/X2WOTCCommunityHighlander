//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD.uc
//  AUTHORS: Brit Steiner, Katie Hirsch, Tronster
//
//  PURPOSE: Container for specific abilities menu representations.
//           Actually this is more of a container than having anything to do with the
//           original radial menu.  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD extends UIScreen dependson(X2GameRuleset);

enum eUI_ReticleMode
{
	eUIReticle_NONE,
	eUIReticle_Overshoulder,
	eUIReticle_Offensive,
	eUIReticle_Defensive,
	eUIReticle_Sword,
	eUIReticle_Advent,
	eUIReticle_Alien,
	eUIReticle_Vektor
};

enum eUI_ConcealmentMode
{
	eUIConcealment_None,
	eUIConcealment_Individual,
	eUIConcealment_Squad,
	eUIConcealment_Super,
};

//----------------------------------------------------------------------------
// MEMBERS
//
struct HUDVisibilityFlags
{
	var bool bInventory;
	//	var bool bShotHUD;
	//	var bool bAbilityHUD;
	var bool bStatsContainer;
	var bool bPerks;
	var bool bObjectives;
	var bool bMouseControls;
	var bool bEnemyTargets;
	var bool bEnemyPreview;
	var bool bCountdown;
	var bool bTooltips;
	var bool bTutorialHelp;
	var bool bCommanderHUD;
	var bool bShotInfoWings;
	var bool bTargetReticle;
	var bool bChallengeCountdown;
	var bool bChosenHUD;
	var bool bSitRep;
	var bool bMessageBanner;
};

var bool bVisibilityInfoCached;
var HUDVisibilityFlags CachedVisibility;

var eUI_ConcealmentMode                 ConcealmentMode;
var eUI_ReticleMode                     m_eReticleMode;
var UITacticalHUD_Inventory                     m_kInventory;
var UITacticalHUD_ShotHUD                       m_kShotHUD;
var UITacticalHUD_AbilityContainer              m_kAbilityHUD;
var UITacticalHUD_SoldierInfo                   m_kStatsContainer;
var UITacticalHUD_PerkContainer                 m_kPerks;
var UIObjectiveList						        m_kObjectivesControl;
var UITacticalHUD_MouseControls                 m_kMouseControls;
var UITacticalHUD_Enemies					    m_kEnemyTargets;
var UITacticalHUD_Enemies					    m_kEnemyPreview;
var UITacticalHUD_Countdown						m_kCountdown;
var UITacticalHUD_Tooltips						m_kTooltips;
var UIStrategyTutorialBox                       m_kTutorialHelpBox;
var UITacticalHUD_CommanderHUD					m_kCommanderHUD;
var UITacticalHUD_ShotWings						m_kShotInfoWings;
var UITargetingReticle							m_kTargetReticle;
var UITacticalHUD_ChallengeCountdown            m_kChallengeCountdown; // DEPRECATED bsteiner 3/24/2016
var UIPanel										m_kChosenHUD;
var UIPanel										m_kSitRep; 
var UITacticalHUDMessageBanner					m_kMessageBanner;

var UIEventNoticesTactical						m_kEventNotices;

var int CachedChosenActivationPreviewLevel;
var int CachedChosenActivationLevel;
var int	 CurrentTargetID;
var bool m_isMenuRaised;
var bool m_bForceOverheadView;
var bool m_bChosenHUDActive;
var bool m_bRevealedChosenHUD; // Keep track of the first time we reveal the Chosen UI.
var bool m_bShowingReaperHUD;
var name m_currentScopeOn;
var name m_currentScopeOff;
var string SitRepText; //Cache the text

var bool m_bIgnoreShowUntilInternalUpdate;		//The Show function will immediately return until Show is called from InternalUpdate.
var bool m_bIsHidingShotHUDForSecondaryMovement;

var UIButton CharInfoButton;
var UIButton EndTurnButton; //bsg-hlee (05.11.17): Adding in button to be nav help for end turn functionality.
var UIButton SkyrangerButton;
var localized string m_strEvac;
//</workshop>
var bool m_bEnemyInfoVisible;
var localized string m_strNavHelpCharShow;
var localized string m_strNavHelpEnemyShow;
var localized string m_strNavHelpEnemyHide;
var localized string m_strNavHelpEndTurn; //bsg-hlee (05.11.17): String for end turn nav help.

var localized string m_strConcealed;
var localized string m_strReaperConcealed;
var localized string m_strSquadConcealed;
var localized string m_strRevealed;
var localized string m_strChosenHUD;
var localized string m_strChosenWarning;
var localized string m_strHitChance;
var localized string m_strConvVektor;
var localized string m_strMagVektor;
var localized string m_strBeamVektor;
var localized string m_strSitRepPanelHeader; 
var localized string m_strReaperRevealChance;

//----------------------------------------------------------------------------
// METHODS
//

simulated function X2TargetingMethod GetTargetingMethod()
{
	return m_kAbilityHUD.GetTargetingMethod();
}
simulated function HideInputButtonRelatedHUDElements(bool bHide)
{
	if(bHide)
	{
		if (SkyrangerButton != none)
			SkyrangerButton.Hide();

		m_kAbilityHUD.Hide();
		m_kEnemyTargets.Hide();
		if( CharInfoButton != none ) CharInfoButton.Hide();

		if(EndTurnButton != none) EndTurnButton.Hide(); //bsg-hlee (05.11.17): Adding end turn nav help.
	}
	else
	{
		UpdateSkyrangerButton();
		m_kAbilityHUD.Show();
		if (m_kEnemyTargets.GetEnemyCount() > 0)
		{
			m_kEnemyTargets.Show();
		}

		if( CharInfoButton != none && CanCharInfoShow()) CharInfoButton.Show();

		if(EndTurnButton != none) EndTurnButton.Show(); //bsg-hlee (05.11.17): Adding end turn nav help.

		Show();
	}
}

simulated function OnToggleHUDElements(SeqAct_ToggleHUDElements Action)
{
	local int i;

	if (Action.InputLinks[0].bHasImpulse)
	{
		for (i = 0; i < Action.HudElements.Length; ++i)
		{
			switch(Action.HudElements[i])
			{
				case eHUDElement_InfoBox:
					m_kShotHUD.Hide();
					break;
				case eHUDElement_Abilities:
					m_kAbilityHUD.Hide();
					break;
				case eHUDElement_WeaponContainer:
					m_kInventory.Hide();
					break;
				case eHUDElement_StatsContainer:
					m_kStatsContainer.Hide();
					break;
				case eHUDElement_Perks:
					m_kPerks.Hide();
					break;
				case eHUDElement_MouseControls:
					if( m_kMouseControls != none )
						m_kMouseControls.Hide();
					if (SkyrangerButton != none)
					{
						SkyrangerButton.Hide();
					}
					if( CharInfoButton != none ) CharInfoButton.Hide();
					if(EndTurnButton != none) EndTurnButton.Hide(); //bsg-hlee (05.11.17): Adding end turn nav help.
					break;
				case eHUDElement_Countdown:
					m_kCountdown.Hide(); 
					break;
			}
		}
	}
	else if (Action.InputLinks[1].bHasImpulse)
	{
		for (i = 0; i < Action.HudElements.Length; ++i)
		{
			switch(Action.HudElements[i])
			{
				case eHUDElement_InfoBox:
					m_kShotHUD.Show();
					break;
				case eHUDElement_Abilities:
					m_kAbilityHUD.Show();
					break;
				case eHUDElement_WeaponContainer:
					m_kInventory.Show();
					break;
				case eHUDElement_StatsContainer:
					m_kStatsContainer.Show();
					break;
				case eHUDElement_Perks:
					m_kPerks.Show();
					break;
				case eHUDElement_MouseControls:
					if( m_kMouseControls != none )
						m_kMouseControls.Show();
					if (SkyrangerButton != none)
					{
						SkyrangerButton.Show();
					}
					if( CharInfoButton != none && CanCharInfoShow()) CharInfoButton.Show();
					if(EndTurnButton != none) EndTurnButton.Show(); //bsg-hlee (05.11.17): Adding end turn nav help.
					break;
				case eHUDElement_Countdown:
					m_kCountdown.Show(); 
					break;
			}
		}
	}
}

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);	

	// Shot information panel
	m_kShotHUD = Spawn(class'UITacticalHUD_ShotHUD', self).InitShotHUD();

	// Ability Container
	m_kAbilityHUD = Spawn(class'UITacticalHUD_AbilityContainer', self).InitAbilityContainer();

	// Perk Container
	m_kPerks = Spawn(class'UITacticalHUD_PerkContainer', self).InitPerkContainer();

	// Weapon Rack
	m_kInventory = Spawn(class'UITacticalHUD_Inventory', self).InitInventory();
	
	// Soldier stats
	m_kStatsContainer = Spawn(class'UITacticalHUD_SoldierInfo', self).InitStatsContainer();

	// Objectives List
	m_kObjectivesControl = Spawn(class'UIObjectiveList', self).InitObjectiveList(); 
	
	//Alien heads
	m_kEnemyTargets	= Spawn(class'UITacticalHUD_Enemies', self).InitEnemyTargets();

	//Preview alien heads
	m_kEnemyPreview = Spawn(class'UITacticalHUD_EnemyPreview', self).InitEnemyTargets();
	
	//Reinforcements counter
	m_kCountdown = Spawn(class'UITacticalHUD_Countdown', self).InitCountdown();

	//Tooltip Movie
	m_kTooltips = Spawn(class'UITacticalHUD_Tooltips', self).InitTooltips();

	// Commander HUD buttons 
	m_kCommanderHUD = Spawn(class'UITacticalHUD_CommanderHUD', Screen).InitCommanderHUD();

	// Shot Stats wings
	m_kShotInfoWings = Spawn(class'UITacticalHUD_ShotWings', Screen).InitShotWings();

	// Target Reticle
	m_kTargetReticle = Spawn(class'UITargetingReticle', Screen).InitTargetingReticle();

	//Event notice watcher. 
	m_kEventNotices = new(self) class'UIEventNoticesTactical';
	m_kEventNotices.Init();

	// Set up the ChosenHUD click
	m_kChosenHUD = Spawn(class'UIPanel', self).InitPanel('chosenHUD');
	//m_kChosenHUD.ProcessMouseEvents(OnChosenHUDEvent);

	m_kSitRep = Spawn(class'UIPanel', self);
	m_kSitRep.bAnimateOnInit = false; 
	m_kSitRep.InitPanel('SitRepInfoPanel');
	m_kSitRep.ProcessMouseEvents();
	RefreshSitRep();	

	// Set Chosen HUD as revealed if it was already in the engaged state upon load.
	m_bRevealedChosenHUD = class'XComGameState_Unit'.static.GetEngagedChosen() != None;

	m_kMessageBanner = Spawn(class'UITacticalHUDMessageBanner', self);
	m_kMessageBanner.InitScreen(PC, Movie);
	Movie.LoadScreen(m_kMessageBanner);

}

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();
	
	if( Movie.IsMouseActive() )
	{
		m_kMouseControls = Spawn(class'UITacticalHUD_MouseControls', self).InitMouseControls();
	}
	else
	{
		if (!`XENGINE.IsMultiplayerGame())
		{
			SkyrangerButton = Spawn(class'UIButton', self);
			SkyrangerButton.InitButton('SkyrangerButton', m_strEvac,, eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
			SkyrangerButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSCLICK_R3);
			SkyrangerButton.SetFontSize(26);
			SkyrangerButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
			SkyrangerButton.SetPosition(-195, 15);
			SkyrangerButton.OnSizeRealized = OnSkyrangerButtonSizeRealized;
			SkyrangerButton.Hide();
			UpdateSkyrangerButton();
		}

		CharInfoButton = Spawn(class'UIButton', self);
		CharInfoButton.InitButton('CharInfo', class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(m_strNavHelpCharShow),,eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		CharInfoButton.SetTextShadow(true);
		CharInfoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
		CharInfoButton.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT); //bsg-hlee (05.17.17): Anchor the button to the bottom left.
		CharInfoButton.SetPosition(CharInfoButton.X + 20, CharInfoButton.Y - 30); //bsg-hlee (05.17.17): Reposition so it does not clip the edges of screen.

		//bsg-hlee (05.11.17): Adding nav help for the end turn button.
		EndTurnButton = Spawn(class'UIButton', self);
		EndTurnButton.InitButton('EndTurn', m_strNavHelpEndTurn,,eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		EndTurnButton.SetTextShadow(true);
		EndTurnButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_BACK_SELECT);
		EndTurnButton.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT); //bsg-hlee (05.17.17): Anchor the button to the bottom left.
		EndTurnButton.SetPosition(EndTurnButton.X + 20, EndTurnButton.Y - 55); //bsg-hlee (05.17.17): Reposition so it does not clip the edges of screen.
		//bsg-hlee (05.11.17): End

		//NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
		//NavHelp.SetY(NavHelp.Y - 65); //NavHelp's default location overlaps with the static character info, so we're offsetting it here
	}

	LowerTargetSystem(true);

	// multiplayer specific watches -tsmith 
	if(WorldInfo.NetMode != NM_Standalone)
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalGRI(WorldInfo.GRI).m_kBattle, 'm_iPlayerTurn', m_kInventory, m_kInventory.ForceUpdate);
	
	// Force initial update.
	// Currently game core is raising update after building abilities but it's
	// happening before this screen is spawned.
	Update();

	Movie.UpdateHighestDepthScreens();
}
simulated function OnSkyrangerButtonSizeRealized()
{
	SkyrangerButton.SetPosition(-45 - SkyrangerButton.Width, 15);
}

// Delays call to OnInit until this function returns true
simulated function bool CheckDependencies()
{
	return XComTacticalGRI(WorldInfo.GRI) != none && XComTacticalGRI(WorldInfo.GRI).m_kBattle != none;
}

simulated function bool SelectTargetByHotKey(int ActionMask, int KeyCode)
{
	local int EnemyIndex;

	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return false;

	EnemyIndex = KeyCode - class'UIUtilities_Input'.const.FXS_KEY_F1;

	if (EnemyIndex >= m_kEnemyTargets.GetEnemyCount())
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
		return false;
	}

	m_kEnemyTargets.SelectEnemyByIndex(EnemyIndex);
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{	
	local bool bHandled;    // Has input been 'consumed'?

	//set the current selection in the AbilityContainer
	if ( ( arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 && m_kAbilityHUD != none)
		m_kAbilityHUD.SetSelectionOnInputPress(cmd);

	if( m_kEnemyPreview != none )
	{
		bHandled = m_kEnemyPreview.OnUnrealCommand(cmd, arg);
	}

	// Only allow releases through past this point.
	if ( ( arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0 )
		return false;

	if( m_kAbilityHUD != none )
	{
		bHandled = m_kAbilityHUD.OnUnrealCommand(cmd, arg); 
	}


	// Rest of the system ignores input if not in a shot menu mode.
	// Need to return bHandled to prevent double weapon switching. -TMH
 	if ( !m_isMenuRaised )		
		return bHandled;

	if ( !bHandled )
		bHandled = m_kShotHUD.OnUnrealCommand(cmd, arg);

	if ( !bHandled )
	{
		if (cmd >= class'UIUtilities_Input'.const.FXS_KEY_F1 && cmd <= class'UIUtilities_Input'.const.FXS_KEY_F8)
		{
			bHandled = SelectTargetByHotKey(arg, cmd);
		}
		else
		{
			switch(cmd)
			{
				case (class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER):	
				case (class'UIUtilities_Input'.const.FXS_MOUSE_4):	
					GetTargetingMethod().PrevTarget();
					bHandled=true;
					break;

				case (class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT):
					if(IsActionPathingWithTarget())
					{
						bHandled = false;
					}
					else
					{
						GetTargetingMethod().PrevTarget();
						bHandled = true;
					}
					break;

				case (class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER):
				case (class'UIUtilities_Input'.const.FXS_KEY_TAB):
				case (class'UIUtilities_Input'.const.FXS_MOUSE_5):	
					GetTargetingMethod().NextTarget();
					bHandled=true;
					break;

				case (class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER): // if the press the button to raise the menu again, close it.
				case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
					bHandled = CancelTargetingAction();
					break; 

				case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
					if (!IsActionPathingWithTarget())
					{
						bHandled = CancelTargetingAction();
					}
					else
					{
						bHandled = false;
					}
					break;

				case (class'UIUtilities_Input'.const.FXS_BUTTON_START):

					CancelTargetingAction();
					Movie.Pres.UIPauseMenu( );
					bHandled = true;
					break;
			
				default: 				
					bHandled = false;
					break;
			}
		}
	}

	if ( !bHandled )
		bHandled = super.OnUnrealCommand(cmd, arg);

	return bHandled;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
//	local string callbackTarget;

	if(cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		return;

//	callbackTarget = args[args.Length - 1];
}

simulated function UpdateSkyrangerButton()
{
	local int i;
	local AvailableAction AvailableActionInfo;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local bool bButtonVisible;

	for (i = 0; i < m_kAbilityHUD.m_arrAbilities.Length; i++)
	{
		AvailableActionInfo = m_kAbilityHUD.m_arrAbilities[i];
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_kAbilityHUD.m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if (AbilityTemplate.DataName == class'CHHelpers'.static.GetPlaceEvacZoneAbilityName())  // Issue #855
		{
			bButtonVisible = AvailableActionInfo.AvailableCode == 'AA_Success' &&
				(!`REPLAY.bInTutorial || `TUTORIAL.IsNextAbility(AbilityTemplate.DataName));
			break;
		}
	}

	if (SkyrangerButton != none)
	{
		if (bButtonVisible)
		{
			SkyrangerButton.Show();
		}
		else
		{
			SkyrangerButton.Hide();
		}
	}
}
simulated function TargetHighestHitChanceEnemy()
{
	local AvailableAction AvailableActionInfo;
	local int HighestHitChanceIndex;
	local float HighestHitChance;
	local array<Availabletarget> Targets;	
	local float HitChance;
	local int i;
	
	AvailableActionInfo = m_kAbilityHUD.GetSelectedAction();
	
	if( `ISCONTROLLERACTIVE == false )
		AvailableActionInfo.AvailableTargets = m_kAbilityHUD.SortTargets(AvailableActionInfo.AvailableTargets);

	Targets = AvailableActionInfo.AvailableTargets;
	for (i = 0; i < Targets.Length; i++)
	{
		HitChance = m_kEnemyTargets.GetHitChanceForObjectRef(Targets[i].PrimaryTarget);
		if (HitChance > HighestHitChance)
		{
			HighestHitChance = HitChance;
			HighestHitChanceIndex = i;
		}
	}

	m_kAbilityHUD.GetTargetingMethod().DirectSetTarget(HighestHitChanceIndex);
	
	// Issue #295 - Make sure there's at least one member in the Targets array before accessing it.
	if (Targets.Length > 0)
	{
		TargetEnemy(Targets[HighestHitChanceIndex].PrimaryTarget.ObjectID);
	}
	else
	{
		TargetEnemy();
	}
}

simulated function OnChosenHUDEvent(UIPanel ChildControl, int cmd)
{
	//TODO @bsteiner update this interaction check 
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		`PRES.UIChosenRevealScreen();
	}
}

simulated function RaiseTargetSystem()
{
	local XGUnit kUnit;

	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;

	m_kAbilityHUD.m_iPreviousIndexForSecondaryMovement = -1;
	m_bIsHidingShotHUDForSecondaryMovement = false;
	Ruleset = `XCOMGAME.GameRuleset;	
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	kUnit = XComTacticalController(PC).GetActiveUnit();
	if (kUnit == none )
	{
		`warn("Unable to raise tactical UI targeting system due to GetActiveUnit() being none.");
		return;
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect); //bsg-crobinson (5.10.17): Add sound effect to menu raise

	m_kShotHUD.AnimateShotIn();
	m_kAbilityHUD.SetAlpha(1.0);
	m_bForceOverheadView = false;
	m_isMenuRaised = true;
	XComTacticalController(PC).m_bInputInShotHUD = true;

	if( `ISCONTROLLERACTIVE )
		TargetHighestHitChanceEnemy();
	else
		TargetEnemy(CurrentTargetID);

	if( m_kMouseControls != none )
		m_kMouseControls.UpdateControls();

	UpdateSkyrangerButton();
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit(  m_kEnemyTargets.GetSelectedEnemyStateObjectRef() );

	m_kObjectivesControl.Hide();
	m_kShotInfoWings.Show();
	

	if (m_kEnemyTargets.GetEnemyCount() > 0)
	{
		m_kEnemyTargets.Show();
		if( CharInfoButton != none ) CharInfoButton.Show();
	}
	else
	{
		CharInfoButton.Hide();
	}
	m_kEnemyPreview.Hide();
	`PRES.m_kWorldMessageManager.NotifyShotHudRaised();

	// This is for making it so the targeting unit can still animate when off screen enabling the unit 
	// to keep facing the cursor position.  See function definition for more info.  mdomowicz 2015_09_03
	GetTargetingMethod().EnableShooterSkelUpdatesWhenNotRendered(true);
	if(m_bEnemyInfoVisible)
	{
		if (GetTargetingMethod() != none)
		{
			SimulateEnemyMouseOver(true);
		}
	}
}

simulated function bool CanCharInfoShow()
{
	if (m_isMenuRaised)
		return m_kEnemyTargets.GetEnemyCount() > 0 && (ShotBreakdownIsAvailable() || TargetEnemyHasEffectsToDisplay());

	return true;
}

simulated function UpdateCharacterInfoButton()
{
	if (CanCharInfoShow())
	{
		if (CharInfoButton != none) CharInfoButton.Show();
	}
	else
	{
		if (CharInfoButton != none) CharInfoButton.Hide();
	}
}

simulated function HideAwayTargetSystemCosmetic()
{
	local XGUnit kUnit;

	kUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if (kUnit != none)
		kUnit.RemoveRangesOnSquad(kUnit.GetSquad());

	Invoke("ShowNonShotMode");
	m_kShotHUD.AnimateShotOut();
	m_kAbilityHUD.m_iPreviousIndexForSecondaryMovement = m_kAbilityHUD.m_iCurrentIndex;
	m_kAbilityHUD.NotifyCanceled();

	//<workshop> SCI 2016/1/11
	//INS:
	if (`XPROFILESETTINGS.Data.m_bAbilityGrid)
	{
		m_kAbilityHUD.SetAlpha(0.36);
	}
	else
	{
		m_kAbilityHUD.SetAlpha(0.58);
	}
	//</workshop>

	XComPresentationLayer(Owner).m_kUnitFlagManager.ClearAbilityDamagePreview();

	m_isMenuRaised = false;
	XComTacticalController(PC).m_bInputInShotHUD = false;

	XComPresentationLayer(Owner).m_kUnitFlagManager.RealizeTargetedStates();

	if( m_kMouseControls != none )
		m_kMouseControls.UpdateControls();

	//<workshop> SCI 2016/5/17
	//INS:
	UpdateSkyrangerButton();
	//</workshop>

	m_kShotHUD.ResetDamageBreakdown(true);
	m_kEnemyTargets.RealizeTargets(-1);
	m_kEnemyPreview.RealizeTargets(-1);
	m_kShotInfoWings.Hide();

	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.DeactivateExtensionForTargetedUnit();
	GetTargetingMethod().EnableShooterSkelUpdatesWhenNotRendered(false);

	//<workshop> ENEMY_INFO_HANDLING - JTA 2016/1/6
	//INS:
	SimulateEnemyMouseOver(false);
	//</workshop>
}

simulated function LowerTargetSystem(optional bool bIsCancelling = false)
{	
	local XGUnit kUnit;
	local X2TargetingMethod TargetingMethod;

	kUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if (kUnit != none)
		kUnit.RemoveRangesOnSquad(kUnit.GetSquad());

	Invoke("ShowNonShotMode");
	m_kAbilityHUD.NotifyCanceled();
	m_kAbilityHUD.m_iPreviousIndexForSecondaryMovement = -1;
	m_kTargetReticle.SetTarget();

	// Hide Reaper Targeting HUD
	`Pres.EnablePostProcessEffect(m_currentScopeOff, true, true);
	`Pres.EnablePostProcessEffect(m_currentScopeOn, false);
	if (ConcealmentMode == eUIConcealment_Super)
	{
		`Pres.EnablePostProcessEffect('ShadowModeOn', true, true);
	}

	UpdateReaperHUD();
	UpdateChosenHUDPreview();

	XComPresentationLayer(Owner).m_kUnitFlagManager.ClearAbilityDamagePreview();

	m_isMenuRaised = false;
	XComTacticalController(PC).m_bInputInShotHUD = false;

	XComPresentationLayer(Owner).m_kUnitFlagManager.RealizeTargetedStates();

	if( m_kMouseControls != none )
		m_kMouseControls.UpdateControls();
	UpdateSkyrangerButton();
	
	m_kShotHUD.ResetDamageBreakdown(true);
	m_kShotHUD.LowerShotHUD();
	m_kEnemyTargets.RealizeTargets(-1, !bIsCancelling);
	m_kEnemyPreview.RealizeTargets(-1, !bIsCancelling);
	m_kEnemyPreview.Show();
	m_kShotInfoWings.Hide();
	m_kObjectivesControl.Show();
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.DeactivateExtensionForTargetedUnit();
	TargetingMethod = GetTargetingMethod();
	if (TargetingMethod != none)
		TargetingMethod.EnableShooterSkelUpdatesWhenNotRendered(false);
	if( `ISCONTROLLERACTIVE )
		SimulateEnemyMouseOver(false);
}

simulated function UpdateNavHelp()
{
	local PlayerInput InputController; //used to detect the state
	local String LabelForInfoHelp; //pulls up info about the character/enemy
	
	if(!`ISCONTROLLERACTIVE)
		return;	

	//determine what type of info is displayed, if any
	InputController = `LEVEL.GetALocalPlayerController().PlayerInput; //using Input class because that is where the handling is located for the character info
	if(InputController != None && InputController.IsInState('ActiveUnit_Moving'))
	{
		LabelForInfoHelp = m_strNavHelpCharShow;
	}
	else if(m_isMenuRaised && m_bEnemyInfoVisible)
	{
		LabelForInfoHelp = m_strNavHelpEnemyHide;
	}
	//checks to see if there is an active enemy
	else if(m_isMenuRaised && !m_bEnemyInfoVisible && m_kEnemyTargets != none)
	{
		//checks to see if the target-able enemy has any info to show
		if(m_kEnemyTargets.TargetEnemyHasEffectsToDisplay() || ShotBreakdownIsAvailable())
		{
			LabelForInfoHelp = m_strNavHelpEnemyShow;
		}
	}
			
	//Sometimes the player can focus on 'enemies' that have extra info (explosive canisters)
	if(m_isMenuRaised && !(ShotBreakdownIsAvailable() || TargetEnemyHasEffectsToDisplay()))
	{
		LabelForInfoHelp = "";
	}

	//If the label was set, show the help icon
	if(LabelForInfoHelp != "")
	{
		if( CharInfoButton != none ) CharInfoButton.SetText(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(LabelForInfoHelp));
	}	
}


//Simulates the mouse event that occurs when a player hovers their mouse over the enemy targets
//Purpose is to manually show the tooltips that are triggered via button press when a mouse isn't available
//bIsHovering - simulate a MOUSE_IN command if 'true'
//returns 'true' if it attempts to simulate a mouse hover (can abort the process if there are no enemy targets to simulate)
simulated function bool SimulateEnemyMouseOver(bool bIsHovering)
{
	local UITooltipMgr Mgr;
	local String ActiveEnemyPath;
	local int MouseCommand;

	if(bIsHovering)
	{		
		//checks to see if current enemy has any information to display
		if(m_kEnemyTargets != None && m_kEnemyTargets.TargetEnemyHasEffectsToDisplay())
		{
			MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_IN;
			m_bEnemyInfoVisible = true;
		}
		else //if enemy does not have any effects to display, do not simulate a mouse-hover
		{
			//This used to simply "return false;", leaving the tooltip in its current state.
			//We need to handle the case where the user switches directly between enemies with LB/RB, though.
			//They may toggle away from an enemy that had buffs, and land on an enemy with no buffs.
			//Hide the tooltip in this case. -BET 2016-05-31
			MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;
		}
	}		
	else
	{
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;
		m_bEnemyInfoVisible = false;
	}		

	//UITacticalHUD_BuffsTooltip uses the path to determine the enemy type, pulling directly from the 6th parsed section, after "icon" (this happens in 'RefreshData')
	//It will look something like this: "_level0.theInterfaceMgr.UITacticalHUD_0.theTacticalHUD.enemyTargets.Icon0"
	ActiveEnemyPath = string(m_kEnemyTargets.MCPath) $ ".icon" $ m_kEnemyTargets.GetCurrentTargetIndex();

	Mgr = Movie.Pres.m_kTooltipMgr;
	Mgr.OnMouse("", MouseCommand, ActiveEnemyPath); //The Tooltip Manager uses the 'arg' parameter to set the path instead of the 'path' parameter
	
	UpdateNavHelp();

	return true;
}
//Sets a "show details" boolean that will persist when switching view modes, switching targets, etc
simulated function ToggleEnemyInfo()
{
	local bool bShotBreakdownAvailable;

	bShotBreakdownAvailable = ShotBreakdownIsAvailable();

	if (!m_isMenuRaised || (bShotBreakdownAvailable || TargetEnemyHasEffectsToDisplay()))
	{
		m_bEnemyInfoVisible = !m_bEnemyInfoVisible;

		if (bShotBreakdownAvailable)
		{
			ShowShotWings(m_bEnemyInfoVisible);
		}

		SimulateEnemyMouseOver(m_bEnemyInfoVisible);
	}
}

//Grabs the 'shot breakdown' and returns true if there is added info available in the shot wings (UITacticalHUD_ShotWings)
simulated function bool ShotBreakdownIsAvailable()
{
	local ShotBreakdown Breakdown;
	local XComGameState_Ability AbilityState;

	AbilityState = m_kAbilityHUD.GetCurrentSelectedAbility();
	if(AbilityState != None)
	{
		AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, m_kEnemyTargets.GetSelectedEnemyStateObjectRef(), AbilityState.GetReference(), Breakdown);
		return !Breakdown.HideShotBreakdown;
	}

	return false;
}

simulated function bool TargetEnemyHasEffectsToDisplay()
{
	if (m_kEnemyTargets != none)
	{
		return m_kEnemyTargets.TargetEnemyHasEffectsToDisplay();
	}

	return false;
}

//Handles visibility for UITacticalHUD_ShotWings.uc (simulates player pressing the show/hide buttons available on PC)
simulated function ShowShotWings(bool bShow)
{
	if(m_kShotInfoWings != None)
	{
		//function called is a blind toggle, so this checks to make sure the desired effect is going to happen
		if(	(bShow && !m_kShotInfoWings.bLeftWingOpen && !m_kShotInfoWings.bRightWingOpen) ||
			(!bShow && m_kShotInfoWings.bLeftWingOpen && m_kShotInfoWings.bRightWingOpen))
		{
			m_kShotInfoWings.LeftWingMouseEvent(None, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
			m_kShotInfoWings.RightWingMouseEvent(None, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
		}
	}
}

simulated function bool IsActionPathingWithTarget()
{
	//TODO:TARGETING
	/*
	local XGAction_Targeting kTargetingAction;

	kTargetingAction = XGAction_Targeting( XComTacticalController(PC).GetActiveUnit().GetAction() );
	if( kTargetingAction != none && kTargetingAction.GetPathAction() != none)
	{
		return true;
	}
	*/
	return false;
}

simulated function bool IsHidingForSecondaryMovement()
{
	return m_bIsHidingShotHUDForSecondaryMovement;
}

simulated function bool HideAwayTargetAction()
{
	HideAwayTargetSystemCosmetic();
	m_bIsHidingShotHUDForSecondaryMovement = true;
	return false;
}
simulated function bool CancelTargetingAction()
{
	LowerTargetSystem(true);
	//XComPresentationLayer(Movie.Pres).m_kSightlineHUD.ClearSelectedEnemy();
	PC.SetInputState('ActiveUnit_Moving');
	return true; // controller: return false ? bsteiner 
}

simulated function int GetTargetIndexForID(int TargetID)
{
	local AvailableAction CurrentAction;
	local int ActionIndex;

	CurrentAction = m_kAbilityHUD.GetSelectedAction();

	for( ActionIndex = 0; ActionIndex < CurrentAction.AvailableTargets.Length; ++ActionIndex )
	{
		if( CurrentAction.AvailableTargets[ActionIndex].PrimaryTarget.ObjectID == TargetID )
		{
			return ActionIndex;
		}
	}

	return 0;
}

simulated function TargetEnemy( int TargetID = -1 )
{
	local int TargetIndex;

	m_kAbilityHUD.UpdateAbilitiesArray();

	CurrentTargetID = TargetID;
	TargetIndex = GetTargetIndexForID(TargetID);
	RealizeTargetingReticules(TargetIndex);
	m_kEnemyTargets.RefreshSelectedEnemy(true, true);
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit(  m_kEnemyTargets.GetSelectedEnemyStateObjectRef() );
	m_kShotHUD.Update();

	RealizeTargetingReticules(TargetIndex);
	if (!IsHidingForSecondaryMovement())
		RealizeTargetingReticules(TargetIndex);

	UpdateReaperHUD();

	if( `ISCONTROLLERACTIVE )
		SimulateEnemyMouseOver(m_bEnemyInfoVisible && ShotBreakdownIsAvailable());
}

simulated function RealizeTargetingReticules( optional int TargetIndex = 0 )
{
	local bool isDefensiveMode;

	//@TODO - jbouscher - add a field to AvailableAction, or provide a mechanism in the ability template that can tell if this is an offensive or defensive ability
	isDefensiveMode = false;

	if ( isDefensiveMode )
	{
		Invoke("ShowDefenseReticule");
	}
	else
	{
		//@TODO - jbouscher - the ability should be able to specify an overhead / overshoulder interface
		if ( !m_bForceOverheadView )
		{
			Invoke("ShowOffenseReticule");
		}
		else
		{
			Invoke("ShowOvershoulderReticule");
		}
	}

	//-----------------------------------------

	//Use the actual selected ability for reticle update, so that it uses the correct target. 
	UpdateReticle( m_kAbilityHUD.GetSelectedAction(), TargetIndex );
	
	//-----------------------------------------
	XComPresentationLayer(Owner).m_kUnitFlagManager.RealizeTargetedStates();
}


simulated function Update()
{
	InternalUpdate(false, -1);
}

simulated function ForceUpdate(int HistoryIndex)
{
	InternalUpdate(true, HistoryIndex);
}

simulated function InternalUpdate(bool bForceUpdate, int HistoryIndex)
{
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;
	local StateObjectReference ActiveUnitRef;

	if ( !bIsInited )
	{
		`warn("Attempt to ResetActionHUD before it was initialized.");
		return;
	}

	Ruleset = `XCOMGAME.GameRuleset;	

	ActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();
	if( ActiveUnitRef.ObjectID > 0 )
	{
		Ruleset.GetGameRulesCache_Unit(ActiveUnitRef, UnitInfoCache);
	
		//TODO: change over to a watch variable. -bsteiner 
		// TODO: may need to force the update on clients when we get replicated data. -tsmith 
		m_kInventory.Update( True );
		m_kStatsContainer.UpdateStats();

		// Re-raise target system if an abilities update was requested.
		if ( m_isMenuRaised )
			TargetEnemy( 0 );
		
		if( m_isMenuRaised )
		{
			if( `ISCONTROLLERACTIVE )
				TargetHighestHitChanceEnemy();
			else
				TargetEnemy( 0 );
		}
				
		if ( m_isMenuRaised )
			TargetEnemy(CurrentTargetID);
		
		m_kAbilityHUD.UpdateAbilitiesArray();
		m_kEnemyTargets.RefreshTargetHoverData();
		m_kEnemyTargets.RefreshAllTargetsBuffs();
		//TEMP: 
		UpdateEnemyPreview(true);

		// force visualizer sync
		RealizeConcealmentStatus(ActiveUnitRef.ObjectID, bForceUpdate, HistoryIndex);
	}

	m_bIgnoreShowUntilInternalUpdate = false;
	Show();
}

simulated function UpdateEnemyPreview(bool bShow)
{
	if( bShow )
	{
		m_kEnemyPreview.RefreshTargetHoverData();
		m_kEnemyPreview.RefreshAllTargetsBuffs();
		m_kEnemyPreview.Show();
	}
	else
	{
		m_kEnemyPreview.RealizeTargets(-1);
		m_kEnemyPreview.Hide();
	}
}

function ReplayToggleReaperHUD(bool bShow)
{
	if (bShow)
	{
		MC.FunctionVoid("ShowReaperHUD");
	}
	else
	{
		MC.FunctionVoid("HideReaperHUD");
	}
}

simulated function RealizeConcealmentStatus(int SelectedUnitID, bool bForceUpdate, int HistoryIndex)
{
	local eUI_ConcealmentMode DesiredConcealmentMode;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local float currentConcealLoss, modifiedLoss;
	local int SuperConcealedModifier;
	// Variables for Issue #6
	local XComLWTuple Tuple;
	local bool bShowReaperUI;
	local float CurrentConcealLossCH, ModifiedLossCH;

	SuperConcealedModifier = 0;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(SelectedUnitID, , HistoryIndex));

	// Start Issue #6
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'TacticalHUDReaperUI';
	Tuple.Data.Add(3);
	
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false;

	Tuple.Data[1].kind = XComLWTVFloat;
	Tuple.Data[1].f = 0.0f;

	Tuple.Data[2].kind = XComLWTVFloat;
	Tuple.Data[2].f = 0.0f;

	`XEVENTMGR.TriggerEvent('TacticalHUD_RealizeConcealmentStatus', Tuple, UnitState, none);
	bShowReaperUI = Tuple.Data[0].b;
	CurrentConcealLossCH = Tuple.Data[1].f;
	ModifiedLossCH = Tuple.Data[2].f;
	// End Issue #6

	if( !UnitState.IsConcealed() )
	{
		DesiredConcealmentMode = eUIConcealment_None;
	}
	else if (UnitState.IsSuperConcealed() || bShowReaperUI)
	{
		DesiredConcealmentMode = eUIConcealment_Super;
	}
	else if( UnitState.IsSquadConcealed() )
	{
		DesiredConcealmentMode = eUIConcealment_Squad;
	}
	else
	{
		DesiredConcealmentMode = eUIConcealment_Individual;
	}

	if( bForceUpdate )
	{
		UpdateChosenHUDActivation();
	}

	if( DesiredConcealmentMode != ConcealmentMode || ConcealmentMode == eUIConcealment_Super)
	{
		if (DesiredConcealmentMode != eUIConcealment_Super)
		{
			m_bShowingReaperHUD = false;
			UpdateChosenHUD_Internal(false);
			MC.FunctionVoid("HideReaperHUD");
		}
		ConcealmentMode = DesiredConcealmentMode;

		if( ConcealmentMode == eUIConcealment_None )
		{
			if( !bForceUpdate )
			{
				// when changing the selected unit ID, the transition should be instant
				MC.FunctionVoid("HideConcealmentHUD");
			}
			else
			{
				// when not changing the selected unit ID, the transition should display the concealment broken animation
				MC.FunctionString("ShowRevealedHUD", m_strRevealed);
			}
		}
		else
		{
			if (DesiredConcealmentMode == eUIConcealment_Super)
			{
				SelectedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(GetSelectedAction().AbilityObjectRef.ObjectID));
				if (SelectedAbilityState != none)
				{
					SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();

					SuperConcealedModifier = SelectedAbilityTemplate.SuperConcealmentLoss;

					if (SuperConcealedModifier == -1)
						SuperConcealedModifier = class'X2AbilityTemplateManager'.default.SuperConcealmentNormalLoss;
				}

				SuperConcealedModifier += UnitState.SuperConcealmentLoss;

				if (SuperConcealedModifier > 100)
					SuperConcealedModifier = 100;
				if (SuperConcealedModifier < 0)
					SuperConcealedModifier = 0;

				currentConcealLoss = UnitState.SuperConcealmentLoss / 100.0f;
				modifiedLoss = SuperConcealedModifier / 100.0f;
				MC.FunctionVoid("HideConcealmentHUD");

				m_bShowingReaperHUD = true;
				UpdateChosenHUD_Internal(false);
				//soldier is reaper concealed so hard hide the reveal HUD so it does not overlap the reaper HUD
				MC.FunctionVoid("HardHideRevealedHUD");
				MC.BeginFunctionOp("ShowReaperHUD");
				MC.QueueBoolean(true);
				MC.QueueString(m_strReaperConcealed);

				// Start Issue #6
				if (bShowReaperUI)
				{
					MC.QueueNumber(CurrentConcealLossCH);
					MC.QueueNumber(ModifiedLossCH);
				}
				else
				{
					MC.QueueNumber(currentConcealLoss);
					MC.QueueNumber(modifiedLoss);
				}
				// End Issue #6

				MC.EndOp();

				MC.FunctionVoid("SetReaperHUDTactical");
			}
			else
			{
				MC.BeginFunctionOp("ShowConcealmentHUD");
				MC.QueueBoolean(ConcealmentMode == eUIConcealment_Squad);
				MC.QueueString(ConcealmentMode == eUIConcealment_Squad ? m_strSquadConcealed : m_strConcealed);
				MC.EndOp();
			}
		}
	}
}

function int GetCurrentChosenActivationModifier()
{
	local int ChosenActivationModifier;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;

	SelectedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(GetSelectedAction().AbilityObjectRef.ObjectID));
	ChosenActivationModifier = 0;
	if( SelectedAbilityState != none )
	{
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();

		ChosenActivationModifier = SelectedAbilityTemplate.ChosenActivationIncreasePerUse;

		if( ChosenActivationModifier == -1 )
		{
			ChosenActivationModifier = class'X2AbilityTemplateManager'.default.NormalChosenActivationIncreasePerUse;
		}
	}

	return ChosenActivationModifier;
}

function UpdateChosenHUDPreview()
{
	UpdateChosenHUD_Internal(true);
}

function UpdateChosenHUDActivation()
{
	UpdateChosenHUD_Internal(false);
}

private function UpdateChosenHUD_Internal(bool bUseCachedActivationValue)
{
	local int ChosenActivationModifier, PreviewLevel;
	local XComGameState_Unit ChosenState, UnengagedChosen;
	local bool bUpdateChosenHUDRequired;
	local float MeterFill, PreviewFill;

	if( `SecondWaveEnabled('ChosenActivationSystemEnabled') )
	{
		ChosenState = class'XComGameState_Unit'.static.GetEngagedChosen(UnengagedChosen);
		if( ChosenState != none && !m_bShowingReaperHUD ) // we have an active & engaged chosen on the battlefield
		{
			bUpdateChosenHUDRequired = false;

			ChosenActivationModifier = GetCurrentChosenActivationModifier();

			PreviewLevel = Clamp(ChosenActivationModifier + ChosenState.ActivationLevel, 0, ChosenState.ActivationThreshold);

			if( PreviewLevel != CachedChosenActivationPreviewLevel )
			{
				CachedChosenActivationPreviewLevel = PreviewLevel;

				bUpdateChosenHUDRequired = true;
			}

			if( (!bUseCachedActivationValue || CachedChosenActivationLevel == -1) && ChosenState.ActivationLevel != CachedChosenActivationLevel )
			{
				if( CachedChosenActivationLevel < ChosenState.ActivationLevel )
					`SOUNDMGR.PlaySoundEvent("UI_Warning_Red"); //TEMP until audio gets a new noise

				CachedChosenActivationLevel = ChosenState.ActivationLevel;

				bUpdateChosenHUDRequired = true;
			}

			// if the chosen UI is not visible, it needs to be marked visible
			if( !m_bChosenHUDActive )
			{
				m_bChosenHUDActive = true;

				// first time shown -> play the big reveal animation
				if( !m_bRevealedChosenHUD )
				{
					// Add Chosen Fanfare audio here.
					PlayFanfareAudioForChosen(ChosenState);

					// Chosen UI is normally hidden during the AI turn.  Force the UI visible here
					super.Show(); // to show the fancy Reveal Chosen UI during the AI turn.
					MC.FunctionVoid("RevealChosenHUD");
					m_bRevealedChosenHUD = true;
				}

				// any time shown -> call Show
				MC.BeginFunctionOp("ShowChosenHUD");
				MC.QueueBoolean(true);
				MC.QueueString(m_strChosenHUD);
				MC.QueueNumber(float(CachedChosenActivationLevel) / ChosenState.ActivationThreshold); // Current pips
				MC.QueueNumber(float(CachedChosenActivationPreviewLevel) / ChosenState.ActivationThreshold); // Preview
				MC.QueueNumber(ChosenState.ActivationThreshold); // Total Num Pips
				MC.QueueString(m_strChosenWarning);
				MC.EndOp();
			}
			else if( bUpdateChosenHUDRequired )
			{
				MeterFill = float(CachedChosenActivationLevel) / ChosenState.ActivationThreshold;
				PreviewFill = float(CachedChosenActivationPreviewLevel) / ChosenState.ActivationThreshold;

				if( MeterFill == PreviewFill ) //No preview visible when they are equal
					`SOUNDMGR.PlaySoundEvent("UI_Warning_Red"); //TEMP until audio gets a new noise

				MC.BeginFunctionOp("UpdateChosenHUD");
				MC.QueueNumber(MeterFill);
				MC.QueueNumber(PreviewFill);
				MC.EndOp();
			}
		}
		else
		{
			// no engaged chosen on the battlefield; hide the UI
			if( m_bChosenHUDActive )
			{
				MC.FunctionVoid("HideChosenHUD");
				if( UnengagedChosen != None )
				{
					if( UnengagedChosen.IsDead() || UnengagedChosen.bRemovedFromPlay ) // Chosen unit left the map.
					{
						// Add Chosen Fanfare audio here.
						PlayFanfareAudioForChosen(UnengagedChosen);
					}
				}
				m_bChosenHUDActive = false;
			}
		}
	}
}

function SetFocusLevel(XComGameState_Effect_TemplarFocus FocusState, XComGameState_Unit UnitState)
{
	local XGUnit Unit;

	Unit = XGUnit(`XCOMHISTORY.GetVisualizer(UnitState.ObjectID));
	m_kStatsContainer.SetFocusLevel(Unit, FocusState.FocusLevel, FocusState.GetMaxFocus(UnitState));
}

private function PlayFanfareAudioForChosen(XComGameState_Unit ChosenUnitState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local String FanfareSoundString;

	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	if( AlienHQ.GetChosenOfTemplate(ChosenUnitState.GetMyTemplateGroupName()).GetFanfareSound(FanfareSoundString) )
	{
		`XTACTICALSOUNDMGR.PlayPersistentSoundEvent(FanfareSoundString);
	}
}

simulated function UpdateReaperHUD()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_Ability SelectedAbilityState;
	local float modifiedLoss, currentConcealment;
	local int SuperConcealedModifier;
	local StateObjectReference ActiveUnitRef;
	local XComGameState_Item WeaponState;
	// Variables for Issue #6
	local XComLWTuple Tuple;
	local bool bShowReaperUI, bShowReaperShotHUD;
	local float CurrentConcealLossCH, ModifiedLossCH;
	
	ActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();
	SuperConcealedModifier = 0;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActiveUnitRef.ObjectID, , -1));

	// Start Issue #6
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'TacticalHUDReaperUI';
	Tuple.Data.Add(4);
	
	// Use Reaper HUD override
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false;

	// Current Loss override
	Tuple.Data[1].kind = XComLWTVFloat;
	Tuple.Data[1].f = 0.0f;

	// Modified Loss override
	Tuple.Data[2].kind = XComLWTVFloat;
	Tuple.Data[2].f = 0.0f;

	// Show Reaper Shot HUD override
	Tuple.Data[3].kind = XComLWTVBool;
	Tuple.Data[3].b = true;

	`XEVENTMGR.TriggerEvent('TacticalHUD_UpdateReaperHUD', Tuple, UnitState, none);
	bShowReaperUI = Tuple.Data[0].b;
	CurrentConcealLossCH = Tuple.Data[1].f;
	ModifiedLossCH = Tuple.Data[2].f;
	bShowReaperShotHUD = Tuple.Data[3].b;
	// End Issue #6

	if (ConcealmentMode == eUIConcealment_Super || bShowReaperUI)
	{
		SelectedAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(GetSelectedAction().AbilityObjectRef.ObjectID));

		if (SelectedAbilityState.MayBreakConcealmentOnActivation(CurrentTargetID))
		{
			// Issue #6 Reaper Shot HUD override
			if (bShowReaperShotHUD && SelectedAbilityState != none && 'AA_Success' == SelectedAbilityState.CanActivateAbility(UnitState))
			{
				SuperConcealedModifier = UnitState.GetSuperConcealedModifier(SelectedAbilityState, , CurrentTargetID);
				MC.FunctionVoid("SetReaperHUDShotHUD");
			}
			else
			{
				MC.FunctionVoid("SetReaperHUDTactical");
			}

			SuperConcealedModifier += UnitState.SuperConcealmentLoss;

			if (SuperConcealedModifier > 100)
				SuperConcealedModifier = 100;
			if (SuperConcealedModifier < 0)
				SuperConcealedModifier = 0;

			//	taking a shot with the vektor rifle has a specific cap to loss chance - except against objective targets
			if (!class'Helpers'.static.IsObjectiveTarget(CurrentTargetID))
			{
				WeaponState = SelectedAbilityState.GetSourceWeapon();
				if (WeaponState != none && WeaponState.InventorySlot == eInvSlot_PrimaryWeapon)
				{
					if (SuperConcealedModifier > class'X2AbilityTemplateManager'.default.SuperConcealShotMax)
						SuperConcealedModifier = class'X2AbilityTemplateManager'.default.SuperConcealShotMax;

					MC.FunctionVoid("HideReaperTech");
				}
				else
				{
					MC.FunctionVoid("ShowReaperTech");
				}
			}

			currentConcealment = UnitState.SuperConcealmentLoss / 100.0f;
			modifiedLoss = SuperConcealedModifier / 100.0f;

			MC.BeginFunctionOp("UpdateReaperHUD");

			// Start Issue #6
			if (bShowReaperUI)
			{
				MC.QueueNumber(CurrentConcealLossCH);
				MC.QueueNumber(ModifiedLossCH);
			}
			else
			{
				MC.QueueNumber(currentConcealment);
				MC.QueueNumber(modifiedLoss);
			}
			// End Issue #6

			MC.QueueString(m_strReaperRevealChance);
			MC.EndOp();
		}
		else
		{
			MC.FunctionVoid("SetReaperHUDTactical");
			MC.FunctionVoid("ShowReaperTech");
		}
	}
	else
	{
		MC.FunctionVoid("HideReaperTech");
	}
}

simulated function UpdateReaperHUDPreview(float Roll, float CurrentValue, string BannerText)
{
	if (Roll > CurrentValue)
	{
		`XTACTICALSOUNDMGR.PlayPersistentSoundEvent("Reaper_ShotHUD_NotRevealed");
	}
	else
	{
		`XTACTICALSOUNDMGR.PlayPersistentSoundEvent("Reaper_ShotHUD_Revealed");
	}

	MC.FunctionVoid("SetReaperHUDShotHUD");

	MC.BeginFunctionOp("UpdateReaperHUDPreview");
	MC.QueueNumber(Roll);
	MC.QueueNumber(CurrentValue);
	MC.QueueString(BannerText);
	MC.QueueNumber(class'X2Ability_ReaperAbilitySet'.default.ShadowRollBlipDuration);
	MC.EndOp();
}

// Should only be raised when switching abilities AFTER the initial raise.
simulated function OnAbilityChanged()
{
	local AvailableAction AvailableActionInfo;

	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;

	Ruleset = `XCOMGAME.GameRuleset;	
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	AvailableActionInfo = GetSelectedAction();
	if (AvailableActionInfo.AbilityObjectRef.ObjectID > 0)
	{
		return;
	}
	else 
	{
		RealizeTargetingReticules();
	}

	//XComPresentationLayer(Movie.Pres).m_kSightlineHUD.RefreshSelectedEnemy();
	
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit( m_kEnemyTargets.GetSelectedEnemyStateObjectRef() );
}

//Triggered in the ability container. 
simulated function OnFreeAimChange()
{
	//Update the reticles 
	UpdateReticle( m_kAbilityHUD.GetSelectedAction(), 0 );
	//Refresh the list of visible enemies (i.e. get rid of targeting icons for free-aiming abilities like grenades)
	m_kEnemyTargets.UpdateVisibleEnemies(-1);
}

function UpdateReticle( AvailableAction kAbility, int TargetIndex )
{	
	local XComGameState_BaseObject  TargetState;
	local XComGameState_Ability AbilityState;
	local int reticuleIndex;
	local string strLabel;
	local name WeaponTech;

	if( !kAbility.bFreeAim && TargetIndex < kAbility.AvailableTargets.Length )
	{
		TargetState = `XCOMHISTORY.GetGameStateForObjectID( kAbility.AvailableTargets[TargetIndex].PrimaryTarget.ObjectID );			
	}
	
	m_kTargetReticle.SetTarget(TargetState != None ? TargetState.GetVisualizer() : None);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID( kAbility.AbilityObjectRef.ObjectID ));
	if (AbilityState != none)
	{
		reticuleIndex = AbilityState.GetUIReticleIndex();
		m_kTargetReticle.SetMode(reticuleIndex);


		if (reticuleIndex == eUIReticle_Vektor)
		{
			WeaponTech = AbilityState.GetWeaponTech();
			if (AbilityState.GetMyTemplate().AbilityTargetStyle.IsA('X2AbilityTarget_Single') && kAbility.AvailableTargets.Length > 0)
			{
				if (ConcealmentMode == eUIConcealment_Super)
				{
					m_currentScopeOn = class'X2SoldierClass_DefaultChampionClasses'.default.ShadowScopePostProcessOn;
					m_currentScopeOff = class'X2SoldierClass_DefaultChampionClasses'.default.ShadowScopePostProcessOff;
					`Pres.EnablePostProcessEffect('ShadowModeOn', false);
				}
				else
				{
					m_currentScopeOn = class'X2SoldierClass_DefaultChampionClasses'.default.ScopePostProcessOn;
					m_currentScopeOff = class'X2SoldierClass_DefaultChampionClasses'.default.ScopePostProcessOff;
				}

				
				`Pres.EnablePostProcessEffect(m_currentScopeOff, false);
				`Pres.EnablePostProcessEffect(m_currentScopeOn, true, true);
			}
			if (WeaponTech == 'magnetic')
				strLabel = m_strMagVektor;
			else if(WeaponTech == 'beam')
				strLabel = m_strBeamVektor;
			else
				strLabel = m_strConvVektor;

			m_kTargetReticle.SetReaperLabels(m_strHitChance, strLabel);
		}
		else
		{
			`Pres.EnablePostProcessEffect(m_currentScopeOff, true, true);
			`Pres.EnablePostProcessEffect(m_currentScopeOn, false);
			if (ConcealmentMode == eUIConcealment_Super)
			{
				`Pres.EnablePostProcessEffect('ShadowModeOn', true, true);
			}
		}
	}
}

simulated function SetReticleMessages( string msg )
{
	m_kTargetReticle.SetCursorMessage( msg );
}

simulated function LockTheReticles( bool bLock )
{
	m_kTargetReticle.LockTheCursor( bLock );
}

simulated function SetReticleAimPercentages( float fPercent, float fCritical )
{
	m_kTargetReticle.SetAimPercentages( fPercent, fCritical );
}

simulated function AvailableAction GetSelectedAction()
{
	return m_kAbilityHUD.GetSelectedAction();
}

simulated function eUI_ReticleMode GetReticleMode() 
{ 
	return m_eReticleMode; 
}
simulated function SetReticleMode( eUI_ReticleMode eMode ) 
{
	m_eReticleMode = eMode; 
}

simulated function Show()
{
	local XComPresentationLayer Pres;

	if (m_bIgnoreShowUntilInternalUpdate)
	{
		return;
	}

	if(`TACTICALRULES.HasTacticalGameEnded())
	{
		// the match has ended, no need for this UI now as we are simply visualizing the rest of the match
		// from here on out
		Hide();
		return;
	}

	m_kAbilityHUD.PopulateFlash();

	Pres = XComPresentationLayer(Movie.Pres);

	if( CharInfoButton != none && !Movie.Pres.ScreenStack.IsInStack(class'UIChallengeModeScoringDialog') && CanCharInfoShow())CharInfoButton.Show();

	if( !Pres.m_kTurnOverlay.IsShowingAlienTurn() 
	   && !Pres.m_kTurnOverlay.IsShowingOtherTurn()
	   && !Pres.m_kTurnOverlay.IsShowingTheLostTurn()
	   && !Pres.m_kTurnOverlay.IsShowingChosenTurn()
	   && !Pres.m_kTurnOverlay.IsShowingReflexAction()
	   && !Pres.m_kTurnOverlay.IsShowingSpecialTurn() 
		&& !Pres.ScreenStack.HasInstanceOf(class'UIChosenReveal')
	   && (!Pres.ScreenStack.HasInstanceOf(class'UIReplay') || `REPLAY.bInTutorial)) //And don't show if the turn overlay is still active. -bsteiner 5/11/2015
		super.Show();
}

simulated function VisualizerForceShow()
{
	super.Show();
}

simulated function Hide()
{
	m_kAbilityHUD.NotifyCanceled();
	super.Hide();
}

simulated function InitializeMouseControls()
{
	Invoke("InitializeMouseControls");
}

simulated function bool IsMenuRaised() 
{ 
	if(WorldInfo.NetMode != NM_Client)
	{
		return m_isMenuRaised; 
	}
	else
	{
		return m_isMenuRaised || XComTacticalController(PC).m_bInputInShotHUD;
	}
}

simulated function RefreshSitRep()
{
	local XComGameState_BattleData BattleDataObject;
	local XComGameState_MissionSite MissionState;
	local X2SitRepTemplateManager SitRepManager;
	local X2SitRepTemplate SitRepTemplate;
	local string SitRepInfo, SitRepTooltip;
	local name SitRepName;
	local EUIState eState;
	local int idx;
	local array<string> SitRepLines, SitRepTooltipLines;

	BattleDataObject = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if( BattleDataObject == none )
	{
		UpdateSitRep("", "");
	}

	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(BattleDataObject.m_iMissionID));
	if( BattleDataObject.ActiveSitReps.Length > 0 && !MissionState.GetMissionSource().bBlockSitrepDisplay)
	{
		SitRepManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();
		foreach BattleDataObject.ActiveSitReps(SitRepName)
		{
			SitRepTemplate = SitRepManager.FindSitRepTemplate(SitRepName);

			if( SitRepTemplate != none )
			{
				if( SitRepTemplate.bExcludeFromStrategy )
					continue; 

				if( SitRepTemplate.bNegativeEffect )
				{
					eState = eUIState_Bad;
				}
				else
				{
					eState = eUIState_Normal;
				}

				SitRepLines.AddItem( class'UIUtilities_Text'.static.GetColoredText(SitRepTemplate.GetFriendlyName(), eState));
				SitRepTooltipLines.AddItem(SitRepTemplate.GetDescriptionExpanded()); // Issue #566
			}
		}
	}

	for( idx = 0; idx < SitRepLines.Length; idx++ )
	{
		SitRepInfo $= SitRepLines[idx];
		if( idx < SitRepLines.length - 1 )
			SitRepInfo $= "\n";

		SitRepTooltip $= SitRepLines[idx] $ ":" @ SitRepTooltipLines[idx];
		if (idx < SitRepLines.length - 1)
			SitRepTooltip $= "\n";
	}

	UpdateSitRep(SitRepInfo, SitRepTooltip);
}
simulated function UpdateSitRep(string NewText, string TooltipText)
{
	if( SitRepText != NewText )
	{
		SitRepText = NewText;
		
		m_kSitRep.MC.BeginFunctionOp("UpdateDisplay");
		m_kSitRep.MC.QueueString(m_strSitRepPanelHeader);
		m_kSitRep.MC.QueueString(SitRepText);
		m_kSitRep.MC.EndOp();

		m_kSitRep.SetTooltipText(TooltipText);
	}
	if( SitRepText == "" )
	{
		m_kSitRep.Hide();
	}
}

//==============================================================================
//		TUTORIAL / SET-UP PHASE:
//==============================================================================

simulated function ShowTutorialHelp(string strHelpText, float DisplayTime)
{
	ClearTimer('HideTutorialHelp');

	if (DisplayTime > 0)
	{
		SetTimer(DisplayTime, false, 'HideTutorialHelp');
	}

	if (m_kTutorialHelpBox == none)
	{
		m_kTutorialHelpBox = Spawn(class'UIStrategyTutorialBox', self);
		m_kTutorialHelpBox.m_strHelpText = strHelpText; 
		m_kTutorialHelpBox.InitScreen(PC, Movie);
		`PRES.ScreenStack.Push( m_kTutorialHelpBox );
	}
	else
	{
		m_kTutorialHelpBox.SetNewHelpText(strHelpText);
		m_kTutorialHelpBox.Show();
	}
}

simulated function HideTutorialHelp()
{
	ClearTimer('HideTutorialHelp');

	if (m_kTutorialHelpBox != none)
	{
		m_kTutorialHelpBox.Hide();
	}
}

simulated function UpdateButtonHelp()
{
}

simulated function OnRemoved()
{
	XComPresentationLayer(Movie.Pres).DeactivateAbilityHUD();

	if (m_kEventNotices != none)
		m_kEventNotices.Uninit();
}

function SetHUDVisibility(HUDVisibilityFlags NewVisibilityFlags)
{
	if (!bVisibilityInfoCached)
	{
		CachedVisibility.bInventory = m_kInventory.bIsVisible;
		//		CachedVisibility.bShotHUD = m_kShotHUD.bIsVisible;
		//		CachedVisibility.bAbilityHUD = m_kAbilityHUD.bIsVisible;
		CachedVisibility.bStatsContainer = m_kStatsContainer.bIsVisible;
		CachedVisibility.bPerks = m_kPerks.bIsVisible;
		CachedVisibility.bObjectives = m_kObjectivesControl.bIsVisible;
		CachedVisibility.bMouseControls = m_kMouseControls.bIsVisible;
		CachedVisibility.bEnemyTargets = m_kEnemyTargets.bIsVisible;
		CachedVisibility.bEnemyPreview = m_kEnemyPreview.bIsVisible;
		CachedVisibility.bCountdown = m_kCountdown.bIsVisible;
		CachedVisibility.bTooltips = m_kTooltips.bIsVisible;
		CachedVisibility.bTutorialHelp = m_kTutorialHelpBox.bIsVisible;
		CachedVisibility.bCommanderHUD = m_kCommanderHUD.bIsVisible;
		CachedVisibility.bShotInfoWings = m_kShotInfoWings.bIsVisible;
		CachedVisibility.bTargetReticle = m_kTargetReticle.bIsVisible;
		CachedVisibility.bChallengeCountdown = m_kChallengeCountdown.bIsVisible;
		CachedVisibility.bChosenHUD = m_kChosenHUD.bIsVisible;
		CachedVisibility.bSitRep = m_kSitRep.bIsVisible;
		CachedVisibility.bMessageBanner = m_kMessageBanner.bIsVisible;

		bVisibilityInfoCached = true;
	}

	m_kInventory.SetVisible(NewVisibilityFlags.bInventory);
	//m_kShotHUD.SetVisible(NewVisibilityFlags.bShotHUD);
	//m_kAbilityHUD.SetVisible(NewVisibilityFlags.bAbilityHUD);
	m_kStatsContainer.SetVisible(NewVisibilityFlags.bStatsContainer);
	m_kPerks.SetVisible(NewVisibilityFlags.bPerks);
	m_kObjectivesControl.SetVisible(NewVisibilityFlags.bObjectives);
	m_kMouseControls.SetVisible(NewVisibilityFlags.bMouseControls);
	m_kEnemyTargets.SetVisible(NewVisibilityFlags.bEnemyTargets);
	m_kEnemyPreview.SetVisible(NewVisibilityFlags.bEnemyPreview);
	m_kCountdown.SetVisible(NewVisibilityFlags.bCountdown);
	m_kTooltips.SetVisible(NewVisibilityFlags.bTooltips);
	m_kTutorialHelpBox.SetVisible(NewVisibilityFlags.bTutorialHelp);
	m_kCommanderHUD.SetVisible(NewVisibilityFlags.bCommanderHUD);
	m_kShotInfoWings.SetVisible(NewVisibilityFlags.bShotInfoWings);
	m_kTargetReticle.SetVisible(NewVisibilityFlags.bTargetReticle);
	m_kChallengeCountdown.SetVisible(NewVisibilityFlags.bChallengeCountdown);
	m_kChosenHUD.SetVisible(NewVisibilityFlags.bChosenHUD);
	m_kSitRep.SetVisible(NewVisibilityFlags.bSitRep);
	m_kMessageBanner.SetVisible(NewVisibilityFlags.bMessageBanner);
}

function RestoreHUDVisibility()
{
	if (bVisibilityInfoCached)
	{
		bVisibilityInfoCached = false;

		m_kInventory.SetVisible(CachedVisibility.bInventory);
		//m_kShotHUD.SetVisible(CachedVisibility.bShotHUD);
		//m_kAbilityHUD.SetVisible(CachedVisibility.bAbilityHUD);
		m_kStatsContainer.SetVisible(CachedVisibility.bStatsContainer);
		m_kPerks.SetVisible(CachedVisibility.bPerks);
		m_kObjectivesControl.SetVisible(CachedVisibility.bObjectives);
		m_kMouseControls.SetVisible(CachedVisibility.bMouseControls);
		m_kEnemyTargets.SetVisible(CachedVisibility.bEnemyTargets);
		m_kEnemyPreview.SetVisible(CachedVisibility.bEnemyPreview);
		m_kCountdown.SetVisible(CachedVisibility.bCountdown);
		m_kTooltips.SetVisible(CachedVisibility.bTooltips);
		m_kTutorialHelpBox.SetVisible(CachedVisibility.bTutorialHelp);
		m_kCommanderHUD.SetVisible(CachedVisibility.bCommanderHUD);
		m_kShotInfoWings.SetVisible(CachedVisibility.bShotInfoWings);
		m_kTargetReticle.SetVisible(CachedVisibility.bTargetReticle);
		m_kChallengeCountdown.SetVisible(CachedVisibility.bChallengeCountdown);
		m_kChosenHUD.SetVisible(CachedVisibility.bChosenHUD);
		m_kSitRep.SetVisible(CachedVisibility.bSitRep);
		m_kMessageBanner.SetVisible(CachedVisibility.bMessageBanner);
	}
}


// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "theTacticalHUD";
	Package = "/ package/gfxTacticalHUD/TacticalHUD";

	m_isMenuRaised = false;
	bHideOnLoseFocus = false;
	bAnimateOnInit = false;
	m_bChosenHUDActive = false;
	m_bShowingReaperHUD = false;

	m_bIsHidingShotHUDForSecondaryMovement = false;
	bProcessMouseEventsIfNotFocused = true;
	CachedChosenActivationLevel = -1
	SitRepText = "DEFAULT";
}

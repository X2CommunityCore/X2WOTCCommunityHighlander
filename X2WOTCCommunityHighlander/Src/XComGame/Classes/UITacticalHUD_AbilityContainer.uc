//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_AbilityContainer.uc
//  AUTHOR:  Brit Steiner, Tronster
//  PURPOSE: Containers holding current soldiers ability icons.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_AbilityContainer extends UIPanel
	dependson( X2GameRuleset )
	dependson( UITacticalHUD )
	dependson( UIAnchoredMessageMgr);

// These values must be mirrored in the AbilityContainer actionscript file.
const MAX_NUM_ABILITIES = 30;
const MAX_NUM_ABILITIES_PER_ROW = 15;
const MAX_NUM_ABILITIES_PER_ROW_BAR = 15;

var bool bShownAbilityError;

var int                      m_iCurrentIndex;    // Index of selected item.
var int						 m_iPreviousIndexForSecondaryMovement;


var bool LastSelectionPermitsImmediateSelect;
var Actor LastTargetActor;
var int ActiveAbilities;
var int TargetIndex;
var int ForceSelectNextTargetID;
var array<AvailableAction> m_arrAbilities;
var array<UITacticalHUD_Ability> m_arrUIAbilities;

var int              m_iMouseTargetedAbilityIndex;  //Captures the targeted ability clicked by the mouse 
var int                      m_kWatchVar_Enemy;             // Watching which enemy is targeted 
var int                      m_iUseOnlyAbility;             // Don't allow the user to use any ability except the designated ability. -dwuenschell

var int                      m_iSelectionOnButtonDown;      // The current index when an input is pressed

var X2TargetingMethod TargetingMethod;
var X2TargetingMethod PrevTargetingMethodUsedForSecondaryTargetingMethodSwap;
var StateObjectReference LastActiveUnitRef;

var Vector SortReferencePoint;
var Vector SortOriginPoint;
var bool bAbilitiesInited;
//</workshop>

var bool bTutorialMgrInvalidSubmission;

//----------------------------------------------------------------------------
// LOCALIZATION
//
var localized string m_sNoTargetsHelp;
var localized string m_sNoAmmoHelp;
var localized string m_sNoMedikitTargetsHelp;
var localized string m_sNoMedikitChargesHelp;
var localized string m_sNewDefensiveLabel;
var localized string m_sNewOffensiveLabel;
var localized string m_sCanFreeAimHelp;
var localized string m_sHowToFreeAimHelp;
var localized string m_sNoTarget;
var localized string m_strAbilityHoverConfirm;

var localized string m_strHitFriendliesTitle;
var localized string m_strHitFriendliesBody;
var localized string m_strHitFriendliesAccept;
var localized string m_strHitFriendliesCancel;

var localized string m_strHitFriendlyObjectTitle;
var localized string m_strHitFriendlyObjectBody;
var localized string m_strHitFriendlyObjectAccept;
var localized string m_strHitFriendlyObjectCancel;

var localized string m_strAscensionPlatformTitle;
var localized string m_strAscensionPlatformBody;
var localized string m_strAscensionPlatformAccept;
var localized string m_strAscensionPlatformCancel;

var localized string m_strMeleeAttackName;

//----------------------------------------------------------------------------
// METHODS
//

simulated function UITacticalHUD_AbilityContainer InitAbilityContainer()
{
	local int i;
	local UITacticalHUD_Ability kItem;

	InitPanel();

	// Pre-cache UI data array
	for(i = 0; i < MAX_NUM_ABILITIES; ++i)
	{	
		kItem = Spawn(class'UITacticalHUD_Ability', self);
		kItem.InitAbilityItem(name("AbilityItem_" $ i));
		m_arrUIAbilities.AddItem(kItem);
	}
	
	return self;
}

simulated function OnInit()
{
	super.OnInit();

	PopulateFlash();
	SetTimer(0.18, false, 'PopulateFlash');
	SetTimer(0.8, false, 'PopulateFlash');
}

simulated function X2TargetingMethod GetTargetingMethod()
{
	return TargetingMethod;
}

simulated function NotifyCanceled()
{
	ResetMouse(); 
	UpdateHelpMessage(""); //Clears out any message when canceling the mode. 
	Invoke("Deactivate");  //Animate back to top corner. Handle this here instead of in "clear", so that we prevent unwanted animations when staying in show mode. 

	if(TargetingMethod != none)
	{
		TargetingMethod.Canceled();
		TargetingMethod = none;
	}

	if(m_iCurrentIndex != -1)
		m_arrUIAbilities[m_iCurrentIndex].OnLoseFocus();
	
	RefreshTutorialShine(true); //Force a show refresh, since the menu is canceling out.
	
	m_iCurrentIndex = -1;
}

simulated function RefreshTutorialShine(optional bool bIgnoreMenuStatus = false)
{	
	local int i;
	
	if( !`REPLAY.bInTutorial ) return; 

	for( i = 0; i < MAX_NUM_ABILITIES; ++i )
	{
		m_arrUIAbilities[i].RefreshShine(bIgnoreMenuStatus);
	}
}

//bsg-mfawcett(10.03.16): helper to determine if this ability uses grenade targeting
simulated function bool AbilityRequiresTargetingActivation(int Index)
{
	local XComGameState_Ability AbilityState;

	if (!`ISCONTROLLERACTIVE)
	{
		return false;
	}

	if (Index < 0 || Index >= m_arrAbilities.Length)
	{
		return false;
	}

	AbilityState = XComGameState_Ability(
		`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[Index].AbilityObjectRef.ObjectID));

	if (AbilityState != none)
	{
		// Start Issue #476
		/// HL-Docs: feature:RequiresTargetingActivation; issue:476; tags:tactical
		/// When playing with a controller (gamepad), some abilities allow the player
		/// to press (A) again to aim the ability, which allows them to rotate the camera 
		/// with the buttons that would normally cycle the ability selection.
		///
		/// In base game this behaviour was hardcoded to work only for a few specific Targeting Methods.
		/// Highlander replaces the original implementation with a the `RequiresTargetingActivation` 
		/// config array that takes values from `XComGame.ini` config file.
		/// This potentailly allows mods to use this behavior for custom Targeting Methods
		/// that do not extend any of the Targeting Methods that are already configured to use this behavior.
		///    
		///```ini
		/// [XComGame.CHHelpers]
		/// +RequiresTargetingActivation=X2TargetingMethod_Grenade
		/// +RequiresTargetingActivation=X2TargetingMethod_Cone
		///```
		return class'CHHelpers'.static.TargetingClassRequiresActivation(X2TargetingMethod(class'XComEngine'.static.GetClassDefaultObject(AbilityState.GetMyTemplate().TargetingMethod)));
		// End Issue #476
	}

	return false;
}

simulated function bool IsTargetingMethodActivated()
{
	// Start Issue #476
	if (TargetingMethod != none)
	{
		return class'CHHelpers'.static.TargetingClassRequiresActivation(TargetingMethod);
		// End Issue #476
	}


	return false;
}

simulated function SetSelectionOnInputPress(int ucmd)
{

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):  
		case (class'UIUtilities_Input'.const.FXS_L_MOUSE_UP):  
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):  
			m_iSelectionOnButtonDown = m_iCurrentIndex;
		break;
	}

	if (IsCommmanderAbility(m_iCurrentIndex))
	{
		return;
	}

	//bsg-mfawcett(10.03.16): if this is a grenade ability and we are already targeting, dont let user cycle abilities with dpad (rotate camera instead)
	if (AbilityRequiresTargetingActivation(m_iCurrentIndex) && IsTargetingMethodActivated())
	{
		return;
	}


	switch (ucmd)
	{
	case (class'UIUtilities_Input'.const.FXS_DPAD_UP):
	case (class'UIUtilities_Input'.const.FXS_ARROW_UP):
		if (UITacticalHUD(Owner).IsMenuRaised())
		{
			CycleAbilitySelectionRow(-1);
		}
		break;

	case (class'UIUtilities_Input'.const.FXS_DPAD_DOWN):
	case (class'UIUtilities_Input'.const.FXS_ARROW_DOWN):
		if (UITacticalHUD(Owner).IsMenuRaised())
		{
			CycleAbilitySelectionRow(1);
		}
		break;

	case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
	case (class'UIUtilities_Input'.const.FXS_ARROW_LEFT):
		if (UITacticalHUD(Owner).IsMenuRaised())
			CycleAbilitySelection(-1);
		break;

	case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):
	case (class'UIUtilities_Input'.const.FXS_ARROW_RIGHT):
		if (UITacticalHUD(Owner).IsMenuRaised())
			CycleAbilitySelection(1);
		break;
	}

}

simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	local bool bHandled;
	local XComGameState_Ability AbilityState;

	bHandled = true;

	// Only allow releases through.
	if ( ( arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0 )
		return false;

	if( !CanAcceptAbilityInput() )
	{
		return false;
	}

	//bsg-mfawcett(10.03.16): support for rotating camera while aiming grenades
	if (AbilityRequiresTargetingActivation(m_iCurrentIndex))
	{
		if (IsTargetingMethodActivated())
		{
			bHandled = false;
			switch (ucmd)
			{
			case (class'UIUtilities_Input'.static.GetBackButtonInputCode()):
				TargetingMethod.Canceled();
				TargetingMethod = none;
				// reset the camera (based on the cursor) on the active unit
				`Cursor.MoveToUnit(XComTacticalController(PC).GetActiveUnitPawn());
				`Cursor.m_bCustomAllowCursorMovement = false;
				`Cursor.m_bAllowCursorAscensionAndDescension = false;
				bHandled = true;
				break;
			case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
			case (class'UIUtilities_Input'.const.FXS_ARROW_LEFT):
				XComTacticalController(PC).YawCamera(class'XComTacticalInput'.static.GetCameraRotationAngle(arg));  // Issue #854
				bHandled = true;
				break;
			case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):
			case (class'UIUtilities_Input'.const.FXS_ARROW_RIGHT):
				XComTacticalController(PC).YawCamera(-1 * class'XComTacticalInput'.static.GetCameraRotationAngle(arg));  // Issue #854
				bHandled = true;
				break;
			case (class'UIUtilities_Input'.const.FXS_DPAD_UP):
			case (class'UIUtilities_Input'.const.FXS_ARROW_UP):
				// if we are using the ability grid, allow the cursor to go up/down
				// if we are not using the ability grid this is handled in XComTacticalInput
				if (`XPROFILESETTINGS.Data.m_bAbilityGrid)
				{
					`Cursor.AscendFloor();
				}
				break;
			case (class'UIUtilities_Input'.const.FXS_DPAD_DOWN):
			case (class'UIUtilities_Input'.const.FXS_ARROW_DOWN):
				if (`XPROFILESETTINGS.Data.m_bAbilityGrid)
				{
					`Cursor.DescendFloor();
				}
				break;
			}
			if (bHandled)
			{
				// all done, we dont want any more handling of this input
				return true;
			}
			else
			{
				// restore value of bHandled so that rest of function behaves properly
				bHandled = true;
			}
		}
		else
		{
			if (ucmd == class'UIUtilities_Input'.static.GetAdvanceButtonInputCode())
			{
				// cancel the current (top down) targeting method
				if (TargetingMethod != none)
				{
					TargetingMethod.Canceled();
				}

				// create the actual grenade targeting method
				AbilityState = XComGameState_Ability(
					`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[m_iCurrentIndex].AbilityObjectRef.ObjectID));
				TargetingMethod = new AbilityState.GetMyTemplate().TargetingMethod;

//shipping
				// 0 here may be wrong...
				TargetingMethod.Init(m_arrAbilities[m_iCurrentIndex], 0);
				return true;
			}
			// anything else fall through
		}
	}
	//bsg-mfawcett(10.03.16): end

	// ignore the virtual dpad inputs on PC, we want to pass them along to the camera for rotation
	// since PC has the extra buttons to dedicate to ability selection
	// VALVE disabled for Steam controller, this didn't appear to work in the
	// first place and dpad didn't do anything in shot HUD?
	/*if ( `BATTLE != none && `BATTLE.ProfileSettingsActivateMouse() )
	{
	switch(ucmd)
	{
	case (class'UIUtilities_Input'.const.FXS_DPAD_UP):
	case (class'UIUtilities_Input'.const.FXS_DPAD_DOWN):
	case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
	case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):
	return false;
	default:
	}
	}*/
	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):  
		case (class'UIUtilities_Input'.const.FXS_L_MOUSE_UP):  
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			if (UITacticalHUD(Owner).IsMenuRaised() || UITacticalHUD(Owner).IsHidingForSecondaryMovement())
				OnAccept();
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER):
			if( UITacticalHUD(Owner).IsMenuRaised() )
				UITacticalHUD(Owner).CancelTargetingAction();
			else
			{
				if (UITacticalHUD(Owner).IsHidingForSecondaryMovement())
				{
					m_iCurrentIndex = m_iPreviousIndexForSecondaryMovement;
					UITacticalHUD(Owner).RaiseTargetSystem();
					TargetingMethod.Canceled();
					TargetingMethod = None;
					SetAbilityByIndex(m_iCurrentIndex);
				}
				else
					bHandled = false;
			}
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_TAB):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER):
			if( TargetingMethod != none )
				TargetingMethod.NextTarget();
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER):
			if( TargetingMethod != none )
				TargetingMethod.PrevTarget();
			else
				bHandled = false;
			break;
		//bsg-nlong (1.5.17): Commenting these out as it was causing the controller to skip over every other ability
		//case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
		//case (class'UIUtilities_Input'.const.FXS_ARROW_LEFT):
		//	if( UITacticalHUD(Owner).IsMenuRaised() )
		//		CycleAbilitySelection(-1);
		//	else
		//		bHandled = false;
		//	break;

		//case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):	
		//case (class'UIUtilities_Input'.const.FXS_ARROW_RIGHT):
		//	if( UITacticalHUD(Owner).IsMenuRaised() )
		//		CycleAbilitySelection(1);	
		//	else
		//		bHandled = false;
		//	break;
		//bsg-nlong (1.5.17): end

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
		case (class'UIUtilities_Input'.const.FXS_KEY_X):

			// Don't allow user to swap weapons in the tutorial if we're not supposed to.
			if( `BATTLE.m_kDesc.m_bIsTutorial && `TACTICALGRI != none && `TACTICALGRI.DirectedExperience != none && !`TACTICALGRI.DirectedExperience.AllowSwapWeapons() )
			{
				bHandled = false;
				break;
			}
			//Joe Cortese: cycleing weapons isn't a thing in xcom2
			/*if( UITacticalHUD(Owner).IsMenuRaised() )
				OnCycleWeapons();
			else*/
			bHandled = false;
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_L3 :
			if (UITacticalHUD(ParentPanel) != None)
			{
				//toggles a boolean that will display more relevant enemy info (Shot wings + enemy buffs/debuff tooltips) - JTA 2016/4/25
				UITacticalHUD(ParentPanel).ToggleEnemyInfo();
				bHandled = true;
			}
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_1):	DirectConfirmAbility( 0 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_2):	DirectConfirmAbility( 1 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_3):	DirectConfirmAbility( 2 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_4):	DirectConfirmAbility( 3 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_5):	DirectConfirmAbility( 4 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_6):	DirectConfirmAbility( 5 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_7):	DirectConfirmAbility( 6 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_8):	DirectConfirmAbility( 7 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_9):	DirectConfirmAbility( 8 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_0):	DirectConfirmAbility( 9 ); break;

		default: 
			bHandled = false;
			break;
	}

	return bHandled;
}

simulated function bool AbilityClicked(int index)
{
	if( !XComTacticalInput(XComTacticalController(PC).PlayerInput).PreProcessCheckGameLogic( class'UIUtilities_Input'.const.FXS_BUTTON_Y, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) )
		return false;

	// For the tutorial, don't allow the user to bring up the HUD by clicking on it if the right trigger is disabled.
	if( `BATTLE.m_kDesc.m_bIsTutorial )
	{
		if( XComTacticalInput(XComTacticalController(PC).PlayerInput).ButtonIsDisabled( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) )
		{
			PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			return false;
		}
	}

	//Update the selection based on what the mouse clicked
	m_iMouseTargetedAbilityIndex = index;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	//If the HUD is closed, then trigger it to open
	return SelectAbility( m_iMouseTargetedAbilityIndex );
}

// Reset any mouse-specific data.
// Expected use: keyboard or controller nav. 
function ResetMouse()
{
	m_iMouseTargetedAbilityIndex = -1;
}

function DirectSelectAbility( int index )
{
	// For the tutorial, don't allow the user to bring up the HUD by clicking on it if the right trigger is disabled.
	if( `BATTLE.m_kDesc.m_bIsTutorial )
	{
		if( XComTacticalInput(XComTacticalController(PC).PlayerInput).ButtonIsDisabled( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) )
		{
			PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			return;
		}
	}

	//Check if it's in range, and bail if out of range 
	if( index >= m_arrAbilities.Length )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose); 
		return; 
	}

	if( m_iMouseTargetedAbilityIndex != index )
	{
		//Update the selection 
		m_iMouseTargetedAbilityIndex = index;
		SelectAbility( m_iMouseTargetedAbilityIndex );
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
}

function DirectConfirmAbility(int index, optional bool ActivateViaHotKey)
{
	// For the tutorial, don't allow the user to bring up the HUD by clicking on it if the right trigger is disabled.
	if( `BATTLE.m_kDesc.m_bIsTutorial )
	{
		if( XComTacticalInput(XComTacticalController(PC).PlayerInput).ButtonIsDisabled( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) )
		{
			PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			return;
		}
	}

	//Check if it's in range, and bail if out of range 
	if( index >= m_arrAbilities.Length - UITacticalHUD(screen).m_kMouseControls.CommandAbilities.Length)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose); 
		return; 
	}

	if (m_iMouseTargetedAbilityIndex != index)
	{
		if (ActivateViaHotKey)
		{
			m_arrUIAbilities[m_iCurrentIndex].OnLoseFocus();
		}
		//Update the selection 
		m_iMouseTargetedAbilityIndex = index;
		if (ActivateViaHotKey)
		{
			if (!SelectAbility(m_iMouseTargetedAbilityIndex, ActivateViaHotKey))
			{
				UITacticalHUD(Owner).CancelTargetingAction();
				return;
			}
		}
		else
		{
			SelectAbility(m_iMouseTargetedAbilityIndex, ActivateViaHotKey);
		}
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		if (ActivateViaHotKey)
		{
			Invoke("Deactivate");
			PopulateFlash();
		}
	}
	else
	{
		m_iSelectionOnButtonDown = index;
		OnAccept();
	}
}

simulated public function bool OnAccept( optional string strOption = "" )
{
	m_arrUIAbilities[m_iCurrentIndex].OnLoseFocus();
	return ConfirmAbility();
}

simulated public function bool ConfirmAbility( optional AvailableAction AvailableActionInfo )
{
	local XComGameStateHistory          History;
	local array<vector>                 TargetLocations;
	local AvailableTarget               AdditionalTarget;
	local XComGameStateContext          AbilityContext;
	local XComGameState_Ability         AbilityState;
	local array<TTile>                  PathTiles;
	local string                        ConfirmSound;

	ResetMouse();

	//return if the current selection on release does not match the same option that was selected on press
	if( m_iCurrentIndex != m_iSelectionOnButtonDown && !Movie.IsMouseActive() )
		return false;	
	
	if( AvailableActionInfo.AbilityObjectRef.ObjectID <= 0 ) // See if one was sent in as a param
		AvailableActionInfo = GetSelectedAction();

	if(AvailableActionInfo.AbilityObjectRef.ObjectID <= 0)
		return false;

	if( TargetingMethod != none ) 
		TargetIndex = TargetingMethod.GetTargetIndex();

	//overwrite Targeting Method which does not exist for cases such as opening of doors
	if(AvailableActionInfo.AvailableTargetCurrIndex > 0)
	{
		TargetIndex = AvailableActionInfo.AvailableTargetCurrIndex;
	}
	if( TargetingMethod != none )
	{
		TargetingMethod.GetTargetLocations(TargetLocations);
		AdditionalTarget = AvailableActionInfo.AvailableTargets[TargetIndex];
		if( TargetingMethod.GetAdditionalTargets(AdditionalTarget) )
		{
			//	overwrite target to include data from GetAdditionalTargets
			AvailableActionInfo.AvailableTargets[TargetIndex] = AdditionalTarget;
		}

		if (AvailableActionInfo.AvailableCode == 'AA_Success')
		{
			AvailableActionInfo.AvailableCode = TargetingMethod.ValidateTargetLocations(TargetLocations);
		}
	}
	
	// Cann't activate the ability, so bail out
	if(AvailableActionInfo.AvailableCode != 'AA_Success')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		//m_iCurrentIndex = -1;
		return false;
	}

	// before activation of a new ability, mark any existing visualization for quick-completion
	`XCOMVISUALIZATIONMGR.HandleNewUnitSelection();

	if (TargetingMethod != none)
	{
		if(!TargetingMethod.VerifyTargetableFromIndividualMethod(ConfirmAbility))
		{
			return true;
		}

		TargetingMethod.GetPreAbilityPath(PathTiles);

		if( QuickTargetSelectEnabled() )
		{
			ForceSelectNextTargetID = SelectNextImmediateSelectTargetID();
			LastTargetActor = TargetingMethod.GetTargetedActor();
		}
	}

	// add a UI visualization guard
	LastActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();

	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	AbilityContext = AbilityState.GetParentGameState().GetContext();

	AbilityContext.SetSendGameState(true);

	// submit the context latently
	if(class'XComGameStateContext_Ability'.static.ActivateAbility(AvailableActionInfo, TargetIndex, TargetLocations, TargetingMethod, PathTiles,,,LatentSubmitGameStateContextCallback))
	{
		if (bTutorialMgrInvalidSubmission) //Set by XComTutorialMgr HandleSubmittedGameStateContext
		{
			bTutorialMgrInvalidSubmission = false; //reset this flag, it served its purpose
		}
		else
		{
			ConfirmSound = AbilityState.GetMyTemplate().AbilityConfirmSound;
			if (ConfirmSound != "")
				`SOUNDMGR.PlaySoundEvent(ConfirmSound);

			if (TargetingMethod != none)
			{
				TargetingMethod.Committed();
				TargetingMethod = none;
			}

			XComPresentationLayer(Owner.Owner).PopTargetingStates();
			PC.SetInputState('ActiveUnit_Moving');
			`Pres.m_kUIMouseCursor.HideMouseCursor();

			AbilityContext.SetSendGameState(false);
		}

		return true;
	}

	return false;
}

function protected LatentSubmitGameStateContextCallback(XComGameState GameState)
{
	local XComGameStateContext_Ability AbilityContext;
	local name PreviousAbilityName;
	local int PreviousAbilityNewIndex;

	if (GameState != none)
		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if( AbilityContext != none && ForceSelectNextTargetID > 0 && AbilityContext.ShouldImmediateSelectNextTarget() )
	{
		LastSelectionPermitsImmediateSelect = true;
		m_iCurrentIndex = -1;

		PreviousAbilityName = AbilityContext.InputContext.AbilityTemplateName;
		PreviousAbilityNewIndex = GetAbilityIndexByName(PreviousAbilityName);

		if( PreviousAbilityNewIndex != INDEX_NONE )
		{
			// refresh the list of abilities/targets
			UpdateAbilitiesArray();

			DirectSelectAbility(PreviousAbilityNewIndex);
		}

		LastTargetActor = None;
		ForceSelectNextTargetID = -1;
	}
	else
	{
		LastSelectionPermitsImmediateSelect = false;
		m_iCurrentIndex = -1;
		LastTargetActor = None;
		ForceSelectNextTargetID = -1;
	}
}

function bool QuickTargetSelectEnabled()
{
	local XComTacticalCheatManager CheatMgr;

	CheatMgr = `CHEATMGR;
	if( CheatMgr != none && CheatMgr.bQuickTargetSelectEnabled )
	{
		return true;
	}

	return false;
}

/*

AbilityTemplate = AbilityState.GetMyTemplate();
if(AbilityTemplate.SecondaryTargetingMethod != none)
{
if( UITacticalHUD(Owner).IsMenuRaised() && !UITacticalHUD(Owner).IsHidingForSecondaryMovement())
{
UITacticalHUD(Owner).HideAwayTargetAction();
XComTacticalInput(PC.PlayerInput).GotoState('UsingSecondaryTargetingMethod');
//we need to store the targeting method.

PrevTargetingMethodUsedForSecondaryTargetingMethodSwap = TargetingMethod;
TargetingMethod = new AbilityState.GetMyTemplate().SecondaryTargetingMethod;
TargetingMethod.Init(AvailableActionInfo);
TargetingMethod.DirectSetTarget(TargetIndex);
}
else if( UITacticalHUD(Owner).IsHidingForSecondaryMovement() && AbilityState.CustomCanActivateFlag )
bSubmitSuccess = class'XComGameStateContext_Ability'.static.ActivateAbility(AvailableActionInfo, TargetIndex, TargetLocations, TargetingMethod, PathTiles);
}
else
{
if( AbilityState.CustomCanActivateFlag )
bSubmitSuccess = class'XComGameStateContext_Ability'.static.ActivateAbility(AvailableActionInfo, TargetIndex, TargetLocations, TargetingMethod, PathTiles);
}
AbilityContext.SetSendGameState(false);


if (bSubmitSuccess && AbilityState.CustomCanActivateFlag)
{
ConfirmSound = AbilityState.GetMyTemplate().AbilityConfirmSound;
if (ConfirmSound != "")
`SOUNDMGR.PlaySoundEvent(ConfirmSound);

TargetingMethod.Committed();
TargetingMethod = none;
PrevTargetingMethodUsedForSecondaryTargetingMethodSwap = none;
UITacticalHUD(Owner).m_bIsHidingShotHUDForSecondaryMovement = false;

XComPresentationLayer(Owner.Owner).PopTargetingStates();

PC.SetInputState('ActiveUnit_Moving');

`Pres.m_kUIMouseCursor.HideMouseCursor();
}
//we're not going to reset this value if this flag is false, it means our
//current ability should still be selected, but it couldn't activate for some gameplay reason.
if( AbilityState.CustomCanActivateFlag && bSubmitSuccess)
m_iCurrentIndex = -1;
else
Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);

return bSubmitSuccess;
}

*/

function int SelectNextImmediateSelectTargetID()
{
	local int IndexOffset;
	local int TestTargetIndex;
	local int TestTargetID;
	local int CurrentTargetIndex;
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit;

	CurrentTargetIndex = TargetingMethod.GetTargetIndex();

	if( CurrentTargetIndex >= 0 )
	{
		History = `XCOMHISTORY;

		for( IndexOffset = 0; IndexOffset < TargetingMethod.Action.AvailableTargets.Length - 1; ++IndexOffset )
		{
			TestTargetIndex = (CurrentTargetIndex + IndexOffset + 1) % TargetingMethod.Action.AvailableTargets.Length;

			TestTargetID = TargetingMethod.Action.AvailableTargets[TestTargetIndex].PrimaryTarget.ObjectID;

			if( TestTargetID > 0 )
			{
				TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TestTargetID));

				if( TargetUnit != None && TargetUnit.IsAnImmediateSelectTarget() )
				{
					return TestTargetID;
				}
			}
		}
	}

	return -1;
}

function HitFriendliesDialogue() 
{
	local TDialogueBoxData kDialogData; 
	
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strHitFriendliesTitle;
	kDialogData.strText = m_strHitFriendliesBody;
	kDialogData.strAccept = m_strHitFriendliesAccept;
	kDialogData.strCancel = m_strHitFriendliesCancel;
	kDialogData.fnCallback = HitFriendliesDialogueCallback;

	XComPresentationLayer(Movie.Pres).UIRaiseDialog( kDialogData );
	XComPresentationLayer(Movie.Pres).SetHackUIBusy(true);
	XComPresentationLayer(Movie.Pres).UIFriendlyFirePopup();
}

function HitFriendlyObjectDialogue()
{
	local TDialogueBoxData kDialogData; 
	
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strHitFriendlyObjectTitle;
	kDialogData.strText = m_strHitFriendlyObjectBody;
	kDialogData.strAccept = m_strHitFriendlyObjectAccept;
	kDialogData.strCancel = m_strHitFriendlyObjectCancel;
	kDialogData.fnCallback = HitFriendliesDialogueCallback;

	XComPresentationLayer(Movie.Pres).UIRaiseDialog( kDialogData );
	XComPresentationLayer(Movie.Pres).SetHackUIBusy(true);
	XComPresentationLayer(Movie.Pres).UIFriendlyFirePopup();
}

simulated public function HitFriendliesDialogueCallback(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		HitFriendliesAccepted();
		XComPresentationLayer(Movie.Pres).SetHackUIBusy(false);
	}
	else if( eAction == 'eUIAction_Cancel' )
	{
		HitFriendliesDeclined();
		XComPresentationLayer(Movie.Pres).SetHackUIBusy(false);
	}

	if( XComPresentationLayer(Movie.Pres).IsInState( 'State_FriendlyFirePopup' ) )
		XComPresentationLayer(Movie.Pres).PopState();
}
public function HitFriendliesAccepted()
{
	// TODO:TARGETING
	//if (kTargetingAction != none)
	//{
	//	kTargetingAction.m_bPleaseHitFriendlies = true;

		// HAX: OnAccept does some state manipulation which requires the state stack to be purged of the popup dialog state.
		//      This should not cause a problem since the function above (which calls us) does a state check before poping the dialog state.
		//      We need to perform the same call in both functions since cancelling or accepting needs to remove the state - sbatista 6/18/12
		if( XComPresentationLayer(Movie.Pres).IsInState( 'State_FriendlyFirePopup' ) )
			XComPresentationLayer(Movie.Pres).PopState();

	//	OnAccept();
	//	kTargetingAction.m_bPleaseHitFriendlies = false;
	//}
}

public function HitFriendliesDeclined()
{
	//Do nothing. 
}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if(TargetingMethod != none)
	{
		TargetingMethod.Update(DeltaTime);
	}
}

simulated function bool CanAcceptAbilityInput()
{
	if( LastSelectionPermitsImmediateSelect )
	{
		return true;
	}

	if(`XCOMGAME.GameRuleset.BuildingLatentGameState)
	{
		return false;
	}

	// when switching units, don't tneed to wait on visualization
	if( LastActiveUnitRef.ObjectID != XComTacticalController(PC).GetActiveUnitStateRef().ObjectID )
	{
		return true;
	}

	if( class'XComGameStateVisualizationMgr'.static.VisualizerBusy() )
	{
		return false;
	}

	return true;
}

simulated static function bool ShouldShowAbilityIcon(out AvailableAction AbilityAvailableInfo, optional out int ShowOnCommanderHUD)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;

	if( AbilityAvailableInfo.AbilityObjectRef.ObjectID < 1 ||
		AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_NeverShow || 
		(AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_ShowIfAvailable && AbilityAvailableInfo.AvailableCode != 'AA_Success'))
	{
			return false;
	}

	if (AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_ShowIfAvailableOrNoTargets)
	{
		if (AbilityAvailableInfo.AvailableCode != 'AA_Success' && AbilityAvailableInfo.AvailableCode != 'AA_NoTargets')
			return false;
	}

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityAvailableInfo.AbilityObjectRef.ObjectID));
	if(AbilityState == none)
	{
		return false;
	}

	AbilityTemplate = AbilityState.GetMyTemplate();

	if (AbilityTemplate == none)
	{
		return false;
	}

	if (AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_HideSpecificErrors)
	{
		if (AbilityTemplate.HideErrors.Find(AbilityAvailableInfo.AvailableCode) != INDEX_NONE)
			return false;
	}

	if (`REPLAY.bInTutorial && !`TUTORIAL.IsNextAbility(AbilityTemplate.DataName) && AbilityState.GetMyTemplateName() == 'ThrowGrenade')
	{
		return false;
	}

	ShowOnCommanderHUD = AbilityTemplate.bCommanderAbility ? 1 : 0;

	return true;
}

simulated function UpdateAbilitiesArray() 
{
	local int i;
	local int len;
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;
	local array<AvailableAction> arrCommandAbilities;
	local int bCommanderAbility;

	local AvailableAction AbilityAvailableInfo; //Represents an action that a unit can perform. Usually tied to an ability.
	

	//Hide any AOE indicators from old abilities
	for (i = 0; i < m_arrAbilities.Length; i++)
	{
		HideAOE(i);
	}

	//Clear out the array 
	m_arrAbilities.Length = 0;

	// Loop through all abilities.
	Ruleset = `XCOMGAME.GameRuleset;
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	len = UnitInfoCache.AvailableActions.Length;
	for(i = 0; i < len; i++)
	{	
		// Obtain unit's ability.
		AbilityAvailableInfo = UnitInfoCache.AvailableActions[i];

		if(ShouldShowAbilityIcon(AbilityAvailableInfo, bCommanderAbility))
		{
			//Separate out the command abilities to send to the CommandHUD, and do not want to show them in the regular list. 
			// Commented out in case we bring CommanderHUD back.
			if( bCommanderAbility == 1 )
			{
				arrCommandAbilities.AddItem(AbilityAvailableInfo);
			}

			//Add to our list of abilities 
			m_arrAbilities.AddItem(AbilityAvailableInfo);
		}
	}

	arrCommandAbilities.Sort(SortAbilities);
	m_arrAbilities.Sort(SortAbilities);
	PopulateFlash();

	if (m_iCurrentIndex < 0)
	{
		mc.FunctionNum("animateIn", m_arrAbilities.Length - arrCommandAbilities.Length);
	}
	UITacticalHUD(screen).m_kShotInfoWings.Show();
	
	if (`ISCONTROLLERACTIVE)
	{
		UITacticalHUD(screen).UpdateSkyrangerButton();
	}
	else
	{
		UITacticalHUD(screen).m_kMouseControls.SetCommandAbilities(arrCommandAbilities);
		UITacticalHUD(screen).m_kMouseControls.UpdateControls();
	}

	//  jbouscher: I am 99% certain this call is entirely redundant, so commenting it out
	//kUnit.UpdateUnitBuffs();

	// If we're in shot mode, then set the current ability index based on what (if anything) was populated.
	if( UITacticalHUD(screen).IsMenuRaised() && m_arrAbilities.Length > 0 )
	{
		if( m_iMouseTargetedAbilityIndex == -1 )
		{
			// MHU - We reset the ability selection if it's not initialized.
			//       We also define the initial shot determined in XGAction_Fire.
			//       Otherwise, retain the last selection.
			if (m_iCurrentIndex < 0)
				SetAbilityByIndex( 0 );
			else
				SetAbilityByIndex( m_iCurrentIndex );
		}
	}

	// Do this after assigning the CurrentIndex
	UpdateWatchVariables();
	CheckForHelpMessages();
	DoTutorialChecks();

	if (`ISCONTROLLERACTIVE)
	{
		//INS:
		if (m_iCurrentIndex >= 0 && m_arrAbilities[m_iCurrentIndex].AvailableTargets.Length > 1)
			m_arrAbilities[m_iCurrentIndex].AvailableTargets = SortTargets(m_arrAbilities[m_iCurrentIndex].AvailableTargets);
		else if (m_iPreviousIndexForSecondaryMovement >= 0 && m_arrAbilities[m_iPreviousIndexForSecondaryMovement].AvailableTargets.Length > 1)
			m_arrAbilities[m_iPreviousIndexForSecondaryMovement].AvailableTargets = SortTargets(m_arrAbilities[m_iPreviousIndexForSecondaryMovement].AvailableTargets);
	}

}

simulated function DoTutorialChecks()
{
	local XComGameStateHistory History;
	local int Index;
	local Name AbilityName;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit ActiveUnit;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(XComTacticalController(PC).GetActiveUnitStateRef().ObjectID));

	if (XComHQ != None && !XComHQ.bHasPlayedMeleeTutorial && !ActiveUnit.IsConcealed())
	{
		for (Index = 0; Index < m_arrAbilities.Length; Index++)
		{
			if (m_arrAbilities[Index].AvailableCode == 'AA_Success' && m_arrAbilities[Index].AvailableTargets.Length > 0)
			{
				AbilityName = XComGameState_Ability(History.GetGameStateForObjectID((m_arrAbilities[Index].AbilityObjectRef.ObjectID))).GetMyTemplateName();

				if (AbilityName == 'SwordSlice')
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Melee Tutorial");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForMeleeTutorial;

					// Update the HQ state to record that we saw this enemy type
					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));
					XComHQ.bHasPlayedMeleeTutorial = true;

					`TACTICALRULES.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(class'XLocalizedData'.default.MeleeTutorialTitle,
																										class'XLocalizedData'.default.MeleeTutorialText,
																										class'UIUtilities_Image'.static.GetTutorialImage_Melee());
				}
			}
		}
	}
}

static function BuildVisualizationForMeleeTutorial(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayNarrative NarrativeAction;

	NarrativeAction = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	NarrativeAction.Moment = XComNarrativeMoment'X2NarrativeMoments.CENTRAL_Tactical_Tutorial_Misison_Two_Melee';
	NarrativeAction.WaitForCompletion = false;

	foreach VisualizeGameState.IterateByClassType( class'XComGameState_BaseObject', ActionMetadata.StateObject_OldState )
	{
		break;
	}

	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
}

simulated function int SortAbilities(AvailableAction A, AvailableAction B)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AA, BB;
	local bool bACommander, bBCommander;

	History = `XCOMHISTORY;

	AA = XComGameState_Ability(History.GetGameStateForObjectID(A.AbilityObjectRef.ObjectID));
	BB = XComGameState_Ability(History.GetGameStateForObjectID(B.AbilityObjectRef.ObjectID));

	bACommander = AA.GetMyTemplate().bCommanderAbility;
	bBCommander = BB.GetMyTemplate().bCommanderAbility;

	if(bACommander && !bBCommander) return -1;
	else if(!bACommander && bBCommander) return 1;

	if(A.ShotHUDPriority < B.ShotHUDPriority) return 1;
	else if(A.ShotHUDPriority > B.ShotHUDPriority) return -1;
	else return 0;
}

simulated function XComGameState_Ability GetAbilityStateByHotKey(int KeyCode)
{
	local int i;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	for (i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if (AbilityTemplate.DefaultKeyBinding == KeyCode && m_arrAbilities[i].AvailableCode == 'AA_Success')
		{
			return AbilityState;
		}
	}

	return none;
}

simulated function int GetAbilityIndexByHotKey(int KeyCode)
{
	local int i;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	for (i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if (AbilityTemplate.DefaultKeyBinding == KeyCode && m_arrAbilities[i].AvailableCode == 'AA_Success')
		{
			return i;
		}
	}

	return INDEX_NONE;
}


simulated function int GetAbilityIndex(AvailableAction A)
{
	local int i;

	for(i = 0; i < m_arrAbilities.Length; i++)
	{
		if(m_arrAbilities[i] == A)
			return i;
	}

	return INDEX_NONE;
}

simulated function int GetAbilityIndexByName(name A)
{
	local int i;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	for(i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if(AbilityTemplate.DataName == A)
			return i;
	}

	return INDEX_NONE;
}

// Build Flash pieces based on abilities loaded.
// Assumes the containing screen has made the appropriate invoke/timeline calls.
simulated function PopulateFlash()
{
	local int i, len;
	local AvailableAction AvailableActionInfo; //Represents an action that a unit can perform. Usually tied to an ability.
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local UITacticalHUD_AbilityTooltip TooltipAbility;

	if (!bAbilitiesInited)
	{
		bAbilitiesInited = true;
		for (i = 0; i < MAX_NUM_ABILITIES; i++)
		{
			if (!m_arrUIAbilities[i].bIsInited)
			{
				bAbilitiesInited = false;
				return;
			}
		}
	}

	if (!bIsInited)
	{
		return;
	}

	if (m_arrAbilities.Length < 0)
	{
		return;
	}

	//Process the number of abilities, verify that it does not violate UI assumptions
	len = m_arrAbilities.Length;

	ActiveAbilities = 0;
	for( i = 0; i < len; i++ )
	{
		if (i >= m_arrAbilities.Length)
		{
			m_arrUIAbilities[i].ClearData();
			continue;
		}

		AvailableActionInfo = m_arrAbilities[i];

		AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if (AbilityTemplate.bCommanderAbility)
		{
			m_arrUIAbilities[i].ClearData();

			continue;
		}

		if(!AbilityTemplate.bCommanderAbility)
		{
			m_arrUIAbilities[ActiveAbilities].UpdateData(ActiveAbilities, AvailableActionInfo);
			ActiveAbilities++;
		}
	}
	
	mc.FunctionNum("SetNumActiveAbilities", ActiveAbilities);
	
	if (ActiveAbilities > MAX_NUM_ABILITIES && !bShownAbilityError)
	{
		bShownAbilityError = true;
		Movie.Pres.PopupDebugDialog("UI ERROR", "More abilities are being updated than UI supports( " $ len $"). Please report this to UI team and provide a save.");
	}

	if (ActiveAbilities > MAX_NUM_ABILITIES_PER_ROW)
	{
		UITacticalHUD(Owner).m_kShotHUD.MC.FunctionVoid("AbilityOverrideAnimateIn");
		UITacticalHUD(Owner).m_kEnemyTargets.MC.FunctionBool("SetMultirowAbilities", true);
		UITacticalHUD(Owner).m_kEnemyPreview.MC.FunctionBool("SetMultirowAbilities", true);
	}
	else
	{
		UITacticalHUD(Owner).m_kShotHUD.MC.FunctionVoid("AbilityOverrideAnimateOut");
		UITacticalHUD(Owner).m_kEnemyTargets.MC.FunctionBool("SetMultirowAbilities", false);
		UITacticalHUD(Owner).m_kEnemyPreview.MC.FunctionBool("SetMultirowAbilities", false);
	}

	//bsg-jneal (3.2.17): set the gamepadIcon where we populate flash
	if(`ISCONTROLLERACTIVE)
	{
		mc.FunctionString("SetHelp", class'UIUtilities_Input'.const.ICON_RT_R2);
	}
	//bsg-jneal (3.2.17): end

	Show();

	// Refresh the ability tooltip if it's open
	TooltipAbility = UITacticalHUD_AbilityTooltip(Movie.Pres.m_kTooltipMgr.GetChildByName('TooltipAbility'));
	if(TooltipAbility != none && TooltipAbility.bIsVisible)
		TooltipAbility.RefreshData();
}

// Eac hotkey 
simulated function bool IsCommmanderAbility(int Index)
{
	local XComGameState_Ability AbilityState;

	if (Index < 0 || Index >= m_arrAbilities.Length)
	{
		return false;
	}

	AbilityState = XComGameState_Ability(
		`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[Index].AbilityObjectRef.ObjectID));
	return AbilityState != none ? AbilityState.GetMyTemplate().bCommanderAbility : false;
}

simulated function CycleAbilitySelection(int step)
{
	local int index;
	local int totalStep;

	// Ignore if index was never set (e.g. nothing was populated.)
	if (m_iCurrentIndex == -1)
		return;

	totalStep = step;
	do
	{
		index = m_iCurrentIndex;
		index = ((index / MAX_NUM_ABILITIES_PER_ROW_BAR) * MAX_NUM_ABILITIES_PER_ROW_BAR) +
			((index + totalStep) % MAX_NUM_ABILITIES_PER_ROW_BAR);
		if (index < 0)
		{
			index += MAX_NUM_ABILITIES_PER_ROW_BAR;
		}

		totalStep += step;
	}
	until(index >= 0 && index < m_arrAbilities.Length && !IsCommmanderAbility(index));

	ResetMouse();
	SelectAbility( index );
}
simulated function CycleAbilitySelectionRow(int step)
{
	local int index;
	local int totalStep;

	// Ignore if index was never set (e.g. nothing was populated.)
	if (m_iCurrentIndex == -1)
		return;

	totalStep = step;
	do
	{
		index = m_iCurrentIndex;
		index = (MAX_NUM_ABILITIES + (index + (totalStep * MAX_NUM_ABILITIES_PER_ROW_BAR))) % MAX_NUM_ABILITIES;
		
		if (index >= m_arrAbilities.Length)
		{
			index = m_arrAbilities.Length - 1;
			
		}

		while (IsCommmanderAbility(index) && index >= 0)
		{
			index--;
		}

		totalStep += step;
	}
	until(index >= 0 && index < m_arrAbilities.Length);

	if(index != m_iCurrentIndex && index >= 0 && index < m_arrAbilities.Length )
	{
		ResetMouse();
		SelectAbility( index );
	}
}

simulated function bool GetDefaultTargetingAbility(int TargetObjectID, out AvailableAction DefaultAction, optional bool SelectReloadLast = false)
{
	local int i, j;
	local name AbilityName;
	local AvailableAction AbilityAction;
	local AvailableAction ReloadAction;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityCost AbilityCost;

	for(i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityAction = m_arrAbilities[i];
		AbilityName = name(class'XGAIBehavior'.static.GetAbilityName(AbilityAction));

		// We'll want to default to the reload action if the user doesn't have enough ammo for the default ability
		if(AbilityName == 'Reload' && AbilityAction.ShotHUDPriority == class'UIUtilities_Tactical'.const.MUST_RELOAD_PRIORITY)
		{
			ReloadAction = AbilityAction;
			DefaultAction = AbilityAction;
		}

		// Find the first available ability that includes the enemy as a target
		if(AbilityAction.AvailableCode == 'AA_Success')
		{
			for(j = 0; j < AbilityAction.AvailableTargets.Length; ++j)
			{
				if(AbilityAction.AvailableTargets[j].PrimaryTarget.ObjectID == TargetObjectID)
				{
					// if this action requires ammo, and we need to reload, select the reload action instead
					if(!SelectReloadLast && ReloadAction.AbilityObjectRef.ObjectID > 0)
					{
						AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
						`assert(AbilityTemplate != none);

						foreach AbilityTemplate.AbilityCosts(AbilityCost)
						{
							if(X2AbilityCost_Ammo(AbilityCost) != none)
							{
								DefaultAction = ReloadAction;
								return true;
							}
						}
					}
				
					// don't need to reload, so use this ability
					DefaultAction = AbilityAction;
					return true;
				}
			}
		}
	}

	return DefaultAction.AbilityObjectRef.ObjectID > 0;
}

simulated function bool DirectTargetObjectWithDefaultTargetingAbility(int TargetObjectID, optional bool AutoConfirmIfFreeCost = false)
{
	local XComGameStateHistory History;
	local AvailableAction DefaultAction;
	local X2AbilityTemplate Template;
	local XComGameState_Ability Ability;
	local int Index;

	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
	{
		return false;
	}

	// find the default ability for targeting this target
	if(GetDefaultTargetingAbility(TargetObjectID, DefaultAction))
	{
		for(Index = 0; Index < DefaultAction.AvailableTargets.Length; Index++)
		{
			if(DefaultAction.AvailableTargets[Index].PrimaryTarget.ObjectID == TargetObjectID)
			{
				DefaultAction.AvailableTargetCurrIndex = Index;
			}
		}

		// first check if we can autoconfirm it (direct activation without bringing up the hud)
		if(AutoConfirmIfFreeCost)
		{
			History = `XCOMHISTORY;
			Ability = XComGameState_Ability(History.GetGameStateForObjectID(DefaultAction.AbilityObjectRef.ObjectID));
			Template = Ability.GetMyTemplate();
			if(Template.CanAfford(Ability) == 'AA_Success' 
				&& Template.IsFreeCost(Ability)
				&& ConfirmAbility(DefaultAction))
			{
				return true;
			}
		}
		
		// set the ability
		SelectAbilityByAbilityObject(DefaultAction);

		// find the target's index in the target array
		for(Index = 0; Index < DefaultAction.AvailableTargets.Length; Index++)
		{
			if(DefaultAction.AvailableTargets[Index].PrimaryTarget.ObjectID == TargetObjectID)
			{
				// target the enemy unit
				TargetingMethod.DirectSetTarget(Index);
				return true;
			}
		}
	}

	return false;
}

simulated function bool DirectTargetObject(int TargetObjectID, optional bool AutoConfirmIfFreeCost = false)
{
	local XComGameStateHistory History;
	local AvailableAction DefaultAction;
	local X2AbilityTemplate Template;
	local XComGameState_Ability Ability;
	local int Index;

	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
	{
		return false;
	}

	if(m_iCurrentIndex < 0 || m_iCurrentIndex > m_arrAbilities.Length)
	{
		return DirectTargetObjectWithDefaultTargetingAbility(TargetObjectID, AutoConfirmIfFreeCost);
	}

	DefaultAction = m_arrAbilities[m_iCurrentIndex];
	
	// first check if we can autoconfirm it (direct activation without bringing up the hud)
	if(AutoConfirmIfFreeCost)
	{
		History = `XCOMHISTORY;
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(DefaultAction.AbilityObjectRef.ObjectID));
		Template = Ability.GetMyTemplate();
		if(Template.CanAfford(Ability) == 'AA_Success' 
			&& Template.IsFreeCost(Ability)
			&& ConfirmAbility(DefaultAction))
		{
			return true;
		}
	}
		
	// set the ability
	SelectAbilityByAbilityObject(DefaultAction);

	// find the target's index in the target array
	for(Index = 0; Index < DefaultAction.AvailableTargets.Length; Index++)
	{
		if(DefaultAction.AvailableTargets[Index].PrimaryTarget.ObjectID == TargetObjectID)
		{
			// target the enemy unit
			TargetingMethod.DirectSetTarget(Index);
			return true;
		}
	}

	// we were unable to set the target with the current ability, lets try the default ability
	return DirectTargetObjectWithDefaultTargetingAbility(TargetObjectID, AutoConfirmIfFreeCost);
}


// Select ability at index, and then update all associated visuals. 
simulated function bool SelectAbility( int index, optional bool ActivateViaHotKey )
{
	if (m_iCurrentIndex < 0)
	{
		mc.FunctionNum("animateIn", MAX_NUM_ABILITIES);
	}

	if(!SetAbilityByIndex( index, ActivateViaHotKey ))
	{
		return false;
	}

	if (`ISCONTROLLERACTIVE)
	{
		Invoke("Activate");
	}
	
	PopulateFlash();
	UpdateWatchVariables();
	CheckForHelpMessages();

	UITacticalHUD(Owner).UpdateCharacterInfoButton();
	UITacticalHUD(Owner).UpdateReaperHUD();
	UITacticalHUD(Owner).UpdateChosenHUDPreview();

	// Update targetting reticules
	if(UITacticalHUD(Owner).GetReticleMode() != eUIReticle_NONE && GetTargetingMethod() != none)
		UITacticalHUD(Owner).TargetEnemy(GetTargetingMethod().GetTargetedObjectID());

	//Update sightline HUD (targeting head icons) 
	//XComPresentationLayer(Movie.Pres).m_kSightlineHUD.RefreshSelectedEnemy();

	return true;
}

simulated function int GetFirstUsableAbilityIdx()
{
	local int actionCount;
	local int result;
	local int i;

	result = -1;
	actionCount = m_arrAbilities.Length;
	for(i = 0; i < actionCount && result < 0; i++)
	{	
		if( m_arrAbilities[i].AvailableCode == 'AA_Success' )
		{
			result = i;
		}
	}

	return (result < 0) ? 0 : result;
}

simulated function ShowAOE(int Index)
{
	local AvailableAction       AvailableActionInfo;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit UnitState;
	local XGUnit UnitVisualizer;

	AvailableActionInfo = m_arrAbilities[Index];
	if( AvailableActionInfo.AbilityObjectRef.ObjectID == 0 )
	{
		return;
	}
		
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);

	if( AbilityState.GetMyTemplate().AbilityPassiveAOEStyle != none )
	{
		AbilityState.GetMyTemplate().AbilityPassiveAOEStyle.SetupAOEActor(AbilityState);
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
		if( UnitState.m_bSubsystem )
			UnitVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitState.OwningObjectId));
		else
			UnitVisualizer = XGUnit(UnitState.GetVisualizer());
		AbilityState.GetMyTemplate().AbilityPassiveAOEStyle.DrawAOETiles(AbilityState, UnitVisualizer.Location);
	}

		
}

simulated function HideAOE(int Index)
{
	local AvailableAction AvailableActionInfo;
	local XComGameState_Ability AbilityState;

	AvailableActionInfo = m_arrAbilities[Index];
	if( AvailableActionInfo.AbilityObjectRef.ObjectID == 0 )
	{
		return;
	}

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);

	if( AbilityState.GetMyTemplate().AbilityPassiveAOEStyle != none )
	{
		AbilityState.GetMyTemplate().AbilityPassiveAOEStyle.DestroyAOEActor();
	}
}

simulated function SelectAbilityByAbilityObject( AvailableAction Ability )
{
	local int AbilityIndex;

	for(AbilityIndex = 0; AbilityIndex < m_arrAbilities.Length; AbilityIndex++)
	{
		if(m_arrAbilities[AbilityIndex].AbilityObjectRef == Ability.AbilityObjectRef)
		{
			DirectSelectAbility(AbilityIndex);
			return;
		}
	}
}

public function OnCycleWeapons()
{
	local XGUnit                kUnit;
	kUnit = XComTacticalController(PC).GetActiveUnit();
	// MP: we don't allow certain UI interactions such as switching weapons while in the shot hud.
	// we cant just check UITacticalHUD::IsMenuRaised() because that gets called from the
	// XGAction_Fire Execute state and there is a slight delay between the input and when
	// that actually happens that would allow other UI interactions to take place and could hang the game. -tsmith 
	if (kUnit != none && 
		(WorldInfo.NetMode == NM_Standalone || (!XComTacticalController(PC).m_bInputInShotHUD && !XComTacticalController(PC).m_bInputSwitchingWeapons)) &&
		kUnit.CycleWeapons())
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		XComTacticalController(PC).m_bInputSwitchingWeapons = true;
	}
}

simulated function int SortTargetsByLocation(AvailableTarget TargetA, AvailableTarget TargetB)
{
	local Actor ActorA, ActorB;
	local XComGameStateHistory History;
	local Vector ActorALocation, ActorBLocation;
	local Vector ReferenceDirection;
	local float DeterminantA, DeterminantB;
	local Vector DirectionA, DirectionB;

	History = `XCOMHISTORY;

		ActorA = History.GetVisualizer(TargetA.PrimaryTarget.ObjectID);
	ActorB = History.GetVisualizer(TargetB.PrimaryTarget.ObjectID);

	ActorALocation = ActorA.Location;
	ActorALocation.Z = 0.0;
	ActorBLocation = ActorB.Location;
	ActorBLocation.Z = 0.0;

	DirectionA = ActorALocation - SortOriginPoint;
	DirectionB = ActorBLocation - SortOriginPoint;

	ReferenceDirection = SortReferencePoint - SortOriginPoint;

	DirectionA = Normal(DirectionA);
	DirectionB = Normal(DirectionB);

	ReferenceDirection = Normal(ReferenceDirection);

	DeterminantA = ReferenceDirection.X * DirectionA.Y - ReferenceDirection.Y * DirectionA.X;
	DeterminantB = ReferenceDirection.X * DirectionB.Y - ReferenceDirection.Y * DirectionB.X;

	if (DeterminantA < DeterminantB)
	{
		return 1;
	}

	if (DeterminantA > DeterminantB)
	{
		return -1;
	}

	return 0;
}

simulated function array<AvailableTarget> SortTargets(array<AvailableTarget> AvailableTargets)
{
	local int i;

	SortReferencePoint.X = 0.0;
	SortReferencePoint.Y = 0.0;
	for (i = 0; i < AvailableTargets.Length; ++i)
	{
		SortReferencePoint += `XCOMHISTORY.GetVisualizer(AvailableTargets[i].PrimaryTarget.ObjectID).Location;
	}

	SortReferencePoint.X /= AvailableTargets.Length;
	SortReferencePoint.Y /= AvailableTargets.Length;
	SortReferencePoint.Z = 0.0;

	SortOriginPoint = `XCOMHISTORY.GetVisualizer(XComTacticalController(PC).GetActiveUnit().ObjectID).Location;
	SortOriginPoint.Z = 0.0;

	AvailableTargets.Sort(SortTargetsByLocation);

	return AvailableTargets;
}

// Setup an ability. Eventually this should be the ONLY way to select an ability. Everything must route through it.
simulated function bool SetAbilityByIndex( int AbilityIndex, optional bool ActivatedViaHotKey  )
{	
	local UITacticalHUD         TacticalHUD;
	local AvailableAction       AvailableActionInfo;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit    UnitState;
	local XGUnit                UnitVisualizer;
	local GameRulesCache_Unit	UnitInfoCache;
	local int                   PreviousIndex;
	local int                   DefaultTargetIndex;
	local name					PreviousInputState;
	local int					TestTargetIndex;

	local XComWorldData			WorldData;
	local XComLevelVolume		LevelVolume;
	local XCom3DCursor			Cursor;


	if (AbilityIndex == m_iCurrentIndex && TargetingMethod != None)
		return false; // we are already using this ability

	//See if anything is happening in general that should block ability activation
	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
		return false;

	//Don't activate any abilities if the HUD is not visible.
	if (!Screen.bIsVisible)
		return false;

	//Don't activate any abilities if the active unit has none. (TTP #21216)
	`XCOMGAME.GameRuleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);
	if (UnitInfoCache.AvailableActions.Length == 0)
		return false;

	AvailableActionInfo = m_arrAbilities[AbilityIndex];
	if(AvailableActionInfo.AbilityObjectRef.ObjectID == 0)
		return false;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (UnitState.m_bSubsystem)
		UnitVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitState.OwningObjectId));
	else
		UnitVisualizer = XGUnit(UnitState.GetVisualizer());

	if(UnitVisualizer != XComTacticalController(PC).GetActiveUnit())
		return false;

	//No ability activation while we are moving. Maybe we can add an exception for moving twice in a row ... but double move can
	//do the same
	if (UnitVisualizer.m_bIsMoving)
	{
		return false;
	}

	if( AbilityIndex < 0 || AbilityIndex >= m_arrAbilities.Length )
	{
		`warn("Attempt to set ability to focus with illegal index: '" $ AbilityIndex $ "', numAbilities: '" $ m_arrAbilities.Length $ "'.");
		return false;
	}

	PreviousIndex = m_iCurrentIndex;
	m_iMouseTargetedAbilityIndex = AbilityIndex; // make sure this gets updated
	m_iCurrentIndex = AbilityIndex;

	if (`ISCONTROLLERACTIVE)
	{
		if (AvailableActionInfo.AvailableTargets.Length > 1)
			AvailableActionInfo.AvailableTargets = SortTargets(AvailableActionInfo.AvailableTargets);
	}

	if(TargetingMethod != none)
	{
		// if switching abilities, the previous targeting method will still be active. Cancel it.
		TargetingMethod.Canceled();
	}

	// Immediately trigger the ability if it bypasses confirmation
	if(AbilityState.GetMyTemplate().bBypassAbilityConfirm)
	{
		OnAccept();
		return true;
	}

	// make sure our input is in the right mode
//shipping
	Cursor = `CURSOR;
	Cursor.m_bCustomAllowCursorMovement = false;
	Cursor.m_bAllowCursorAscensionAndDescension = false;
	Cursor.SetForceHidden(true);
	WorldData = `XWORLD;
	LevelVolume = WorldData.Volume;
	LevelVolume.BorderComponent.SetUIHidden(true);
//shipping

	PreviousInputState = XComTacticalInput(PC.PlayerInput).GetStateName();
	XComTacticalInput(PC.PlayerInput).GotoState('UsingTargetingMethod');

	if(AvailableActionInfo.AvailableTargets.Length > 0 || AvailableActionInfo.bFreeAim)
	{
		// bsg-nlong (1.5.17): Reintroducing this shipping code and adding a controller check
		// so that abilities that have manual targeting have to be manually activated with a controller

		//bsg-mfawcett(10.03.16): if this is a grenade, delay creating the targeting method so we can support rotating camera while aiming grenades
		if (!AbilityRequiresTargetingActivation(m_iCurrentIndex) || !`ISCONTROLLERACTIVE)
		{
			TargetingMethod = new AbilityState.GetMyTemplate().TargetingMethod;

			TargetIndex = 0;

			if( ForceSelectNextTargetID > 0 )
			{
				for( TestTargetIndex = 0; TestTargetIndex < AvailableActionInfo.AvailableTargets.Length; ++TestTargetIndex )
				{
					if( AvailableActionInfo.AvailableTargets[TestTargetIndex].PrimaryTarget.ObjectID == ForceSelectNextTargetID )
					{
						TargetIndex = TestTargetIndex;
					}
				}
			}

			TargetingMethod.Init(AvailableActionInfo, TargetIndex);
		}
		else
		{
			// reset the camera (based on the cursor) on the active unit as it might be currently on another unit from a previous ability (eg. melee)
			Cursor.MoveToUnit(XComTacticalController(PC).GetActiveUnitPawn());
		}
		// bsg-nlong (1.5.17): end

		DefaultTargetIndex = Max(TargetingMethod.GetTargetIndex(), 0);
	}

	if (AbilityState.GetMyTemplate().bNoConfirmationWithHotKey && ActivatedViaHotKey)
	{
		m_iSelectionOnButtonDown = m_iCurrentIndex;
		// if the OnAccept fails, because unavailable or other similar reasons, we need to put the input state back. 
		if( !OnAccept() )
			XComTacticalInput(PC.PlayerInput).GotoState(PreviousInputState);
		return true;
	}

	if(PreviousIndex != -1)
		m_arrUIAbilities[PreviousIndex].OnLoseFocus();
	if(m_iCurrentIndex != -1)
		m_arrUIAbilities[m_iCurrentIndex].OnReceiveFocus();

	TacticalHUD = UITacticalHUD(Screen);

	if( !TacticalHUD.IsMenuRaised() )
		TacticalHUD.RaiseTargetSystem();

	if(AvailableActionInfo.bFreeAim)
		TacticalHUD.OnFreeAimChange();

	if (`ISCONTROLLERACTIVE == false)
		TacticalHUD.RealizeTargetingReticules(DefaultTargetIndex);
	else
		TacticalHUD.TargetHighestHitChanceEnemy();
	TacticalHUD.m_kShotHUD.Update();

	TacticalHUD.m_kStatsContainer.PreviewFocusLevel(UnitState, AbilityState.GetFocusCost(UnitState));

	return true;
}

//Used by the mouse hover tooltip to figure out which ability to get info from 
simulated function XComGameState_Ability GetAbilityAtIndex( int AbilityIndex )
{
	local AvailableAction       AvailableActionInfo;
	local XComGameState_Ability AbilityState;

	if( AbilityIndex < 0 || AbilityIndex >= m_arrAbilities.Length )
	{
		`warn("Attempt to get ability with illegal index: '" $ AbilityIndex $ "', numAbilities: '" $ m_arrAbilities.Length $ "'.");
		return none;
	}

	AvailableActionInfo = m_arrAbilities[AbilityIndex];
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);
	return AbilityState; 
}

simulated function XComGameState_Ability GetCurrentSelectedAbility()
{ 
	if( m_iCurrentIndex == -1 )
		return none;
	else
		return GetAbilityAtIndex(m_iCurrentIndex);
}

function XGUnit GetMouseTargetedUnit()
{
	local XComTacticalHUD HUD; 
	local IMouseInteractionInterface LastInterface; 
	local XComUnitPawnNativeBase kPawn; 
	local XGUnit kTargetedUnit;

	HUD = XComTacticalHUD(PC.myHUD);
	if( HUD == none ) return none; 

	LastInterface = HUD.CachedMouseInteractionInterface; 
	if( LastInterface == none ) return none; 
	
	kPawn = XComUnitPawnNativeBase(LastInterface);	
	if( kPawn == none ) return none; 

	//This is the next unit we want to set as active 
	kTargetedUnit = XGUnit(kPawn.GetGameUnit());
	if( kTargetedUnit == none ) return none; 

	return kTargetedUnit;

}

simulated function AvailableAction GetSelectedAction()
{
	local AvailableAction NoAction;
	if( m_iCurrentIndex >= 0 && m_iCurrentIndex < m_arrAbilities.Length )
	{	
		return m_arrAbilities[m_iCurrentIndex];
	}
	else if (m_iPreviousIndexForSecondaryMovement >= 0 && m_iPreviousIndexForSecondaryMovement < m_arrAbilities.Length)
	{
		return m_arrAbilities[m_iPreviousIndexForSecondaryMovement];
	}
	else
	{
		`log("Ability out of bounds. Current: '" $ string(m_iCurrentIndex) $ "' Length: '" $ string( m_arrAbilities.Length) $ "'",,'XCom_GameStates');
	}
	return NoAction;
}

simulated function AvailableAction GetShotActionForTooltip()
{
	local AvailableAction NoAction;
	local XComGameState_Ability AvailableAbility;
	local int i;

	if( m_iCurrentIndex >= 0 && m_iCurrentIndex < m_arrAbilities.Length )
	{	
		return m_arrAbilities[m_iCurrentIndex];
	}
	else if( m_arrAbilities.Length > 0 )
	{
		for( i = 0; i < m_arrAbilities.Length; i++ )
		{
			AvailableAbility = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
			if(AvailableAbility.GetMyTemplate().DisplayTargetHitChance)
				return m_arrAbilities[i];
		}
	}
	return NoAction;
}

simulated function bool IsSelectedValue( int i )
{
	return (m_iCurrentIndex == i);
}

simulated function int GetSelectedIndex()
{
	return m_iCurrentIndex;
}

simulated function bool CheckForNotifier( XGUnit kUnit )
{
	local XGWeapon      kActiveWeapon;
	local XGInventory   kInventory;

	kInventory = kUnit.GetInventory();
	kActiveWeapon = kInventory.GetActiveWeapon();
	
	if (kActiveWeapon != none)
	{
		if ( true )
		{
			if (! ( kActiveWeapon.GetRemainingAmmo() > 0 || 
					(kInventory.GetNumClips( kActiveWeapon.GameplayType() ) > 0)) )
			{
				return true;
			}
		}
	}

	return false;
}


simulated function CheckForHelpMessages()
{
	UITacticalHUD(Owner).LockTheReticles(false);

	//@TODO - rmcfall - figure out how to handle help messages later
	//for(i = 0; i < kUnit.GetNumAbilities(); i++)
	//{	
	//	kAbility = GetSelectedAbility();
	//	if( kAbility != none &&
	//		IsAbilityValidWithoutTarget(kAbility) )
	//	{
	//		kTargetedAbility = XGAbility_Targeted(kAbility);

	//		if (kTargetedAbility == none ||             // If the ability is not targeted
	//			kTargetedAbility.GetPrimaryTarget() == none)     // or if the targeted ability has no target 
	//		{
	//			if (kTargetedAbility.HasProperty( eProp_TraceWorld ))
	//			{

	//				// MHU - HelpMessage is continuously updated depending on what the unit is currently
	//				//       aiming at. At this point, there's no information available.
	//				UpdateHelpMessage( m_sNoTarget );
	//				UITacticalHUD(Owner).SetReticleAimPercentages( -1, -1 );
	//				return;
	//			}
	//			else if (!kTargetedAbility.HasProperty( eProp_FreeAim )) // free aim has no target implications
	//			{
	//				// check for no ammo
	//				if(kTargetedAbility.m_kWeapon != none
	//					&& kTargetedAbility.m_kWeapon.GetRemainingAmmo() <= 0
	//					&& kTargetedAbility.HasProperty( eProp_FireWeapon ))
	//				{
	//					UpdateHelpMessage(m_sNoAmmoHelp);
	//				}
	//				else
	//				{
	//					switch (kTargetedAbility.GetType())
	//					{
	//					case eAbility_MedikitHeal:
	//						if (kUnit.GetMediKitCharges() <= 0)
	//							UpdateHelpMessage(m_sNoMedikitChargesHelp);
	//						else
	//						{
	//							kUnit.GetNumPotentialMedikitTargets(iTargets);
	//							if (iTargets > 0)
	//								UpdateHelpMessage(m_sNoMedikitTargetsHelp);
	//						}
	//						break;
	//					case eAbility_Revive:							
	//					case eAbility_Stabilize:
	//						if (kUnit.GetMediKitCharges() <= 0)
	//							UpdateHelpMessage(m_sNoMedikitChargesHelp);
	//						else
	//						{
	//							kUnit.GetNumPotentialStabilizeTargets(iTargets);
	//							if (iTargets > 0)
	//								UpdateHelpMessage(m_sNoMedikitTargetsHelp);
	//						}
	//						break;
	//					default:
	//						UpdateHelpMessage( m_sNoTargetsHelp);
	//						break;
	//					}
	//				}

	//				UITacticalHUD(Owner).SetReticleAimPercentages( -1, -1 );
	//				//UITacticalHUD(Owner).LockTheReticles(false);
	//				return;
	//			}

	//		}
	//	}
	//}

	//If no message was found, clear any message that may  be displayed currently.
	UpdateHelpMessage("");
}

simulated function UpdateHelpMessage( string strMsg )
{
	UITacticalHUD(Owner).SetReticleMessages(strMsg);
}

simulated function UpdateWatchVariables()
{
	//@TODO - rmcfall - support m_bFreeAiming changes
}

simulated function OnFreeAimChange()
{
	UITacticalHUD(Owner).OnFreeAimChange(); 
	CheckForHelpMessages();
}
simulated function bool IsEmpty()
{
	return( m_arrAbilities.Length == 0 ) ;
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	LibID = "AbilityContainer";
	MCName = "AbilityContainerMC";
		
	m_iCurrentIndex = -1;
	
	m_iUseOnlyAbility = -1;  // Only used in ShootAtLocation Kismet Action.  -DMW
	
	m_iMouseTargetedAbilityIndex = -1;

	bAnimateOnInit = false;
}

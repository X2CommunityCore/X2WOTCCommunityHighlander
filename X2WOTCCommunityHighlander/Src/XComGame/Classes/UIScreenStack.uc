//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIScreen.uc
//  AUTHOR:  Samuel Batista, Brit Steiner
//  PURPOSE: Base class for managing a SWF/GFx file that is loaded into the game.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIScreenStack extends Object;

var bool IsInputBlocked; // Block UI system from handling input.
var XComPresentationLayerBase Pres;

var bool ScreensVisible; // Cache Movie-level visibility.
var bool DebugHardHide;  // Debug: Hide UI despite other show/hide commands;
var bool bCinematicMode; 
var bool bPauseMenuInput; //Named to the pause menu as this is not for general use

var array<UIScreen> Screens;
var array<UIScreen> ScreensHiddenForCinematic;
var array< delegate<CHOnInputDelegate> > OnInputSubscribers;		// issue #198

delegate bool CHOnInputDelegate(int iInput, int ActionMask);		// issue #198

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
// CONSTRUCTOR
//

simulated event Destroyed()
{
	`log("UIScreenStack.Destroyed(), self:" $ String(self),,'uicore');
}

// Movie handles Screen input directly, because screens from different Movies are interleaved in this giant stack. 
simulated function bool OnInput( int iInput,  optional int ActionMask = class'UIUtilities_Input'.const.FXS_ACTION_PRESS )
{
	local UIScreen Screen;
	local UIAvengerHUD AvengerHUD;
//	local XComHQPresentationLayer HQPres;

	// Ignore input if system is gated.
	if ( IsInputBlocked )
		return false;

	/*
	// Block all Avenger input if non-interactive events (e.g. camera transition, fullscreen video) are occurring, 
	// unless the pause menu is up.  This prevents a plethora of bugs from occurring!
	HQPres = XCOmHQPresentationLayer( XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres );
	if (HQPres != None && HQPres.NonInterruptiveEventsOccurring() && !IsInStack(class'UIPauseMenu') && !IsInStack(class'UIEndGameStats') )
	{
		// Because the new strategy camera code is suspected of a bug, this will help diagnose, in that case, why X
		// buttons are being blocked, if indeed this system is the one blocking them.
		if (iInput == class'UIUtilities_Input'.const.FXS_BUTTON_A && 
			(ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			HQPres.DiagnoseWhyNonInterruptiveEventsAreOccurring();
		}

		// Return false to block the input.
		return false;
	}*/
	
	// Process screens to handle Avenger Y button shortcut.
	AvengerHUD = UIAvengerHUD( GetFirstInstanceOf(class'UIAvengerHUD') );
	if (AvengerHUD != none && AvengerHUD.bIsInited)
	{
		if( iInput == class'UIUtilities_Input'.const.FXS_BUTTON_Y)
		{
			if (AvengerHUD.OnUnrealCommand(iInput, ActionMask))
			{
				return true;
			}
		}
	}

	// start issue #198
	if (ModOnInput(iInput, ActionMask))
    {
        return true;
    }
	// end issue #198

	// Not using foreach to enforce calling via stack order: LIFO
	foreach Screens(Screen)
	{
		// jboswell: it is possible for Screen to be none when the Movie/pres layer has been
		// allowed to live into a transitional level
		if ( Screen == none )
			continue;

		if ( !Screen.AcceptsInput() )       // Ignore screens not set for input.
			continue;

		// If this Screen is not yet initialized, or is marked for removal stop the input chain right here - sbatista
		if( !Screen.bIsInited )
			return true;

		// Stop if a screen has handled the input or consumes it regardless.
		if( (Screen.EvaluatesInput() && Screen.OnUnrealCommand( iInput, ActionMask )) || Screen.ConsumesInput() )
		{
			// Uncomment to track down input consumption issues - THIS SEEMS TO CAUSE A CRASH AFTER A TACTICAL MISSION ENDS - sbatista
			/*
			if(!Screen.IsFinished())
				`log("Input consumed \""$Screen.MCPath$"\"",,'uixcom');
			*/
			return true;
		}
	}

	return false;
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

// Turn on entire User Interface
simulated function Show()
{
	local UIScreen Screen;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if ( DebugHardHide || ScreensVisible )
		return;

	ScreensVisible = true; 

	foreach Screens(Screen)
	{
		Screen.Show();
	}
}

// Turn off entire User Interface
simulated function Hide()
{
	local UIScreen Screen;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if ( DebugHardHide || !ScreensVisible)
		return;
	
	ScreensVisible = false; 

	foreach Screens(Screen)
	{
		if(!Screen.IsA('UIDebugMenu'))
		{
			Screen.Hide();
		}
	}
}

simulated function HideUIForCinematics()
{
	local UIScreen Screen;

	if( bCinematicMode ) return;

	bCinematicMode = true;

	foreach Screens(Screen)
	{
		Screen.HideForCinematics();
	}
}

simulated function ShowUIForCinematics()
{
	local UIScreen Screen;

	if( !bCinematicMode ) return;

	bCinematicMode = false;

	foreach Screens(Screen)
	{
		Screen.ShowForCinematics();
	}
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

simulated function PrintScreenStack()
{
`if (`notdefined(FINAL_RELEASE))
	local int i;
	local UIScreen Screen;
	local string inputType;
	local string prefix;

	`log("============================================================", , 'uicore');
	`log("---- BEGIN UIScreenStack.PrintScreenStack() -------------", , 'uicore');

	`log("", , 'uicore');
	
	`log("---- Stack: General Information ----------------", , 'uicore');
	`log("Stack.GetCurrentScreen() = " $GetCurrentScreen(), , 'uicore');
	`log("Stack.IsInputBlocked = " $IsInputBlocked, , 'uicore');

	`log("", , 'uicore');
	`log("---- Screens[]:  Classes and Instance Names ---", , 'uicore');
	for( i = 0; i < Screens.Length; i++)
	{
		Screen = Screens[i];
		if ( Screen == none )
		{
			`log(i $": NONE ", , 'uicore');
			continue;
		}
		`log(i $": " $Screen.Class $", " $ Screen, , 'uicore');
	}	
	if( Screens.Length == 0)
		`log("Nothing to show because Screens.Length = 0,", , 'uicore');
	`log("", , 'uicore');

	`log("---- Screen.MCPath ----------------------------", , 'uicore');
	for( i = 0; i < Screens.Length; i++)
	{
		Screen = Screens[i];
		if ( Screen == none )
		{
			`log(i $": NONE ", , 'uicore');
			continue;
		}
		`log(i $": " $Screen.MCPath, , 'uicore');
	}	
	if( Screens.Length == 0)
		`log("Nothing to show because Screens.Length = 0,", , 'uicore');
	`log("", , 'uicore');
	
	`log("---- Unreal Visibility -----------------------", , 'uicore');
	for( i = 0; i < Screens.Length; i++)
	{
		Screen = Screens[i];
		if ( Screen == none )
		{
			`log(i $": NONE ", , 'uicore');
			continue;
		}
		`log(i $": " $"bIsVisible = " $Screen.bIsVisible @ Screen, , 'uicore');
	}	
	if( Screens.Length == 0)
		`log("Nothing to show because Screens.Length = 0,", , 'uicore');
	`log("", , 'uicore');

	`log("---- Owned by 2D vs. 3D movies --------------", , 'uicore');
	for( i = 0; i < Screens.Length; i++)
	{
		Screen = Screens[i];
		if ( Screen == none )
		{
			`log(i $": NONE ", , 'uicore');
			continue;
		}
		if( Screen.bIsIn3D )
			`log(i $": 3D " $ Screen, , 'uicore');
		else
			`log(i $": 2D " $ Screen, , 'uicore');
	}	
	if( Screens.Length == 0)
		`log("Nothing to show because Screens.Length = 0,", , 'uicore');
	`log("", , 'uicore');
	
	`log("---- ScreensHiddenForCinematic[] -------------", , 'uicore');
	for( i = 0; i < ScreensHiddenForCinematic.Length; i++)
	{
		Screen = ScreensHiddenForCinematic[i];
		if ( Screen == none )
		{
			`log(i $": NONE ", , 'uicore');
			continue;
		}
		`log(i $": " $Screen, , 'uicore');
	}	
	if( ScreensHiddenForCinematic.Length == 0)
		`log("Nothing to show because ScreensHiddenForCinematic.Length = 0,", , 'uicore');
	`log("", , 'uicore');

	`log("---- UI Input information --------------------", , 'uicore');
	
	prefix = IsInputBlocked ? "INPUT GATED " : "      ";
	for( i = 0; i < Screens.Length; i++)
	{
		Screen = Screens[i];
		if ( Screen == none )
		{
			`log("      " $ "        " $ " " $ i $ ": ?none?", , 'uicore');
			continue;
		}

		if( Screen.ConsumesInput() )
		{
			inputType = "CONSUME ";
			prefix = "XXX   ";
		}
		else if( Screen.EvaluatesInput() )
			inputType = "eval    ";
		else
			inputType = "-       ";

		`log(prefix $ inputType $ " " $ i $ ": '" @ Screen.class $ "'", , 'uicore');
	}
	if( Screens.Length == 0)
		`log("Nothing to show because Screens.Length = 0,", , 'uicore');
	`log("", , 'uicore');

	`log("*** Movie.Screens are what the movie has loaded: **", , 'uicore');	
	Pres.Get2DMovie().PrintCurrentScreens();
	`log("****************************************************", , 'uicore');	
	`log("", , 'uicore');

	`log("---- END PrintScreenStack --------------------", , 'uicore');

	`log("========================================================", , 'uicore');
`endif
}

//----------------------------------------------------------------------------

/*  
 * Push a new Screen on top of the stack. 
 * Default Movie is 2D HUD, but may be overwritten to be in another Movie. 
 */
simulated function UIScreen Push( UIScreen Screen, optional UIMovie Movie = none )
{
	//local UIScreen ReconnectControllerScreen;
	local XComHQPresentationLayer HQPres;
	
	`log("UIScreenStack::Push "$Screen @ Movie,,'DebugHQCamera');
	
	if( Screens.Length > 0 )
	{
		Screens[0].OnLoseFocus();
		Screens[0].SignalOnLoseFocus();

		// If we have a mouse guard underneath the current screen, hide it as well.
		if(Screens.Length > 1 && UIMouseGuard(Screens[1]) != none)
		{
			Screens[1].OnLoseFocus();
			Screens[1].SignalOnLoseFocus();
		}
	}

	if( Screen.bConsumeMouseEvents )
	{
		Screen.MouseGuardInst = Pres.Spawn(Screen.MouseGuardClass, Pres);
		Push(Screen.MouseGuardInst, Movie);
	}

	Screens.InsertItem( 0, Screen );

	if( Movie == none ) Movie = Pres.Get2DMovie();

	// Mouse guards are only ever added as a recursive call (buddy screen!) when bConsumeMouseEvents is
	// set on a screen. As such, they are paired to their buddy screen and should not be moved around
	if(UIMouseGuard(Screen) == none)
	{
		// Must do before initing a screen, because initing a screen could manipulate the state stack
		ForceStackOrder( Movie );
	}

`if(`notdefined(FINAL_RELEASE))
	`log("UIScreenStack::PushPanel '" $ Screen $ "'.",,'uicore');
	//ScriptTrace();
	PrintScreenStack();
`endif

	//We want to load/init automatically if we can
	if( Screen != none ) 
	{	
		if( Movie.HasScreen( Screen ) )
		{
			`log("The Movie already has a copy of this Screen '" $ Screen.MCName $ "'.",,'uicore');
		}
		else
		{
			//if(!Screen.bIsInited)
			//	Screen.InitScreen( XComPlayerController(Pres.Owner), Movie );
			//
			//Movie.LoadScreen( Screen );			
			HQPres = XCOmHQPresentationLayer( XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres );

			if (HQPres != None)
			{
				HQPres.LoadUIScreen(Screen, Movie);
			}
			else
			{
				LoadUIScreen(Screen, Movie);
			}
		}

		// Clean reference used to store spawned screens (which is passed via 'Screen' argument).
		Pres.TempScreen = none;
	}
	
	//For added safety, hide any tooltip that is up right now. 
	if (Pres.m_kTooltipMgr != None)
		Pres.m_kTooltipMgr.HideAllTooltips();

	return Screen;
}
simulated function LoadUIScreen(UIScreen Screen, UIMovie Movie)
{
	if(!Screen.bIsInited)
		Screen.InitScreen( XComPlayerController(Pres.Owner), Movie );

	Movie.LoadScreen(Screen);
}

//----------------------------------------------------------------------------
// Certain Screen types need be on the top of the stack
simulated function ForceStackOrder(UIMovie Movie)
{
	MoveToTopOfStack(class'UIMultiplayerDisconnectPopup');
	MoveToTopOfStack(class'UITooltipMgr');
	MoveToTopOfStack(class'UIDialogueBox');
	MoveToTopOfStack(class'UIRedScreen');
	MoveToTopOfStack(class'UIProgressDialogue');
}

// This function updates the stack by moving the Screen up but without triggering focus changes
simulated function MoveToTopOfStack(class<UIScreen> ScreenClass)
{
	local int Index;
	local UIScreen Screen, UIGuardScreen;

	Screen = GetScreen(ScreenClass);
	Index = Screens.Find(Screen);

	// If Index == -1, then this Screen isn't found, so do nothing.
	// If Index == 0, then this Screen is currently at the front, so do nothing. 
	if( Index > 0 ) // Panel is found, but isn't at front, so we need to do this udpate. 
	{
		// if the next screen after the one we want to move is a UI Guard, also move the guard with it
		UIGuardScreen = UIMouseGuard(Screens[Index+1]);

		Screens.RemoveItem(Screen);

		if( Screens.Length > 0 )
			Screens[0].OnLoseFocus();

		Screens.InsertItem(0, Screen);
		Screens[0].OnReceiveFocus();

		// move the guard just below the top of the stack
		if( UIGuardScreen != None )
		{
			Screens.RemoveItem(UIGuardScreen);
			Screens.InsertItem(1, UIGuardScreen);
		}
	}
}

/*
 * Removes a single Screen from the top of the state stack. 
 * This is the most common way to request Screen removal.
 * Assumes that the requested Screen is the top-most Screen in the stack, and shows an error if not. 
 * 
 * WARNING:
 * If the Screen is not at the top of the stack, an error will be displayed.
 */
simulated function UIScreen Pop(UIScreen Screen, optional bool MustExist = true)
{
	local int Index;

	`log("UIScreenStack::Pop "$Screen,,'DebugHQCamera');
	Index = Screens.Find(Screen);

`if( `notdefined(FINAL_RELEASE) )
	if( Screen == none && MustExist ) 
	{
		`RedScreen( "UI NAVIGATION ERROR", "UIScreenStack::Pop attempted to pop a null Screen. This is bad mojo." $
					"\nPlease inform the UI team and provide a log with 'uixcom' and 'uicore' unsuppressed." );
	}

	if( Index != INDEX_NONE )
	{
		`log("UIScreenStack::Pop '" $ Screen $ "' - found at Index "$Index$".",,'uicore');
		if(Index != 0 && !Screen.IsA('UIRedScreen') && !GetCurrentScreen().IsA('UIRedScreen'))
		{
			//Disabling until UI can investigate
			//`RedScreen("UI ERROR in UIScreenStack::Pop\n\n'"$ Screen $"' is not at the top of the stack right now. This is a critical error, panels must always be removed from top to bottom.");
		}	
	}
	else if( MustExist )
		`RedScreen("UI ERROR in UIScreenStack::Pop\n\nAttempted to remove Screen '"$ Screen $ "' from state stack, but it was not present in the array. This might indicate an issue, pass false to 'MustExist' if this is intended behavior.");
`endif

	if( Screen != none )
	{
		// We must remove the screen the array before triggering its OnRemove call, because OnRemove could manipulate the state stack.
		Screens.RemoveItem(Screen);

		if( !Screen.bIsPermanent )
			Screen.Movie.RemoveScreen(Screen);
	}

	if( Index == 0 && Screens.Length > 0 )
	{
		GetCurrentScreen().OnReceiveFocus();
		GetCurrentScreen().SignalOnReceiveFocus();

		if(GetCurrentScreen().bConsumeMouseEvents)
		{
			GetFirstInstanceOf(GetCurrentScreen().MouseGuardClass).OnReceiveFocus();
			GetFirstInstanceOf(GetCurrentScreen().MouseGuardClass).SignalOnReceiveFocus();
		}
	}

	if( Screen != none && Screen.bConsumeMouseEvents && Screen.MouseGuardInst != none)
	{
		Pop(Screen.MouseGuardInst, MustExist);
	}

	return Screen;
}

/*
 * Removes the first instance of a Screen that is, or inherits the ScreenClass.
 */
simulated function PopFirstInstanceOfClass( class<UIScreen> ScreenClass, optional bool MustExist = true )
{
	Pop(GetFirstInstanceOf(ScreenClass), MustExist); 
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/* 
 * This will preserve the target Screen, and pop all screens above it.
 * 
 * USE THIS ONLY WHEN YOU WANT TO NUKE ADDITIONAL LAYERS
 */
simulated function PopUntil( UIScreen Screen, optional bool MustExist = true )
{
	local int Index;
	Index = Screens.Find( Screen );
	if(Index != INDEX_NONE)
	{
		while( Screens[0] != Screen ) 
		{
			Pop(Screens[0]);
		}
	}
	else if( MustExist )
	{
		`log( "UIScreenStack::PopUntilScreenClass: '" $ Screen $"': failed to find any Screen of this type in the current Screen stack.",,'uicore');
	}
}

/* 
 * This will preserve the Screen of the ScreenClass, and pop all screens above it.
 * 
 * USE THIS ONLY WHEN YOU WANT TO NUKE ADDITIONAL LAYERS
 */
simulated function PopUntilClass( class<UIScreen> ClassToKeep, optional bool MustExist = true )
{
	`log("PopUntilClass",,'DebugHQCamera');
	PopUntil( GetScreen( ClassToKeep ), MustExist );
}

/*
* This will preserve the Screen of the ScreenClass type (or derived from the target class type), and pop all screens above it.
*
* USE THIS ONLY WHEN YOU WANT TO NUKE ADDITIONAL LAYERS
*/
simulated function PopUntilFirstInstanceOfClass(class<UIScreen> ClassToKeep, optional bool MustExist = true)
{
	PopUntil(GetFirstInstanceOf(ClassToKeep), MustExist);
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/* 
 * Pop all screens above, as well as the target Screen.
 * 
 * USE THIS ONLY WHEN YOU WANT TO NUKE ADDITIONAL LAYERS PLUS THE PANEL
 */
simulated function PopIncluding( UIScreen Screen, optional bool MustExist = true )
{
	local int Index;
	Index = Screens.Find( Screen );
	if(Index != INDEX_NONE)
	{
		while( Screens.Find( Screen ) != INDEX_NONE)
		{
			if( Screens[0].IsA( 'UIRedScreen' ) )
				Pop(Screens[1]);
			else
				Pop(Screens[0]);
		}
	}
	else if( MustExist && Screen != none )
	{
		`log( "UIScreenStack::PopIncludingScreenClass: '" $ Screen.Name $"': failed to find any Screen of this type in the current Screen stack.",,'uicore');
	}
}

/* 
 * Pop all screens above, as well as the Screen of the ScreenClass.
 * 
 * USE THIS ONLY WHEN YOU WANT TO NUKE ADDITIONAL LAYERS PLUS THE PANEL
 */
simulated function PopIncludingClass( class<UIScreen> ClassToRemove, optional bool MustExist = true)
{
	PopIncluding( GetScreen( ClassToRemove ), MustExist );
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

// Returns the first instance of a Screen of the target class type.
simulated function UIScreen GetScreen( class<UIScreen> ScreenClass )
{
	local int Index;
	for( Index = 0; Index < Screens.Length;  ++Index)
	{
		if( ScreenClass ==  Screens[Index].Class )
			return Screens[Index];
	}
	return none; 
}

// Returns the first instance of a Screen of the target class type (or derived from the target class type).
simulated function UIScreen GetFirstInstanceOf( class<UIScreen> ScreenClass )
{
	local int Index;
	for( Index = 0; Index < Screens.Length;  ++Index)
	{
		if( Screens[Index].IsA(ScreenClass.Name) )
			return Screens[Index];
	}
	return none; 
}

// Returns the last (bottom) instance of a Screen of the target class type (or derived from the target class type).
simulated function UIScreen GetLastInstanceOf( class<UIScreen> ScreenClass )
{
	local int Index;
	for( Index = Screens.Length - 1; Index >= 0;  --Index)
	{
		if( Screens[Index].IsA(ScreenClass.Name) )
			return Screens[Index];
	}
	return none; 
}

// Returns the class of the Screen that is at the top of the stack.
simulated function class<UIScreen> GetCurrentClass()
{
	if(Screens.Length > 0)
		return Screens[0].Class;
	return none; 
}

// Returns the first Screen in the stack.
simulated function UIScreen GetCurrentScreen()
{
	local int Index;
	for( Index = 0; Index < Screens.Length;  ++Index)
	{
		if( Screens[Index] != none)
			return Screens[Index];
	}
	return none; 
}

simulated function bool HasInstanceOf( class<UIScreen> ScreenClass )
{
	return GetFirstInstanceOf(ScreenClass) != none;
}

simulated function bool IsCurrentClass( class<UIScreen> ScreenClass )
{
	return GetCurrentClass() == ScreenClass;
}

simulated function bool IsCurrentScreen( name ScreenClass )
{
	return GetCurrentScreen().IsA(ScreenClass);
}

simulated function bool IsTopScreen( UIScreen Screen )
{
	return GetCurrentScreen() == Screen;
}

// Returns whether a Screen of the specified type is in the stack.
simulated function bool IsInStack( class<UIScreen> ScreenClass )
{
	return GetScreen(ScreenClass) != none;
}

simulated function bool IsNotInStack( class<UIScreen> ScreenClass, optional bool ErrorIfInStack = true )
{
	local bool inStack;

	inStack = IsInStack(ScreenClass);

`if(`notdefined(FINAL_RELEASE))	
	if( inStack && ErrorIfInStack )
	{
		ScriptTrace();
		PrintScreenStack();
		`RedScreen( "UI WARNING: UIScreenStack::IsInStack - found existing instance of '" $ ScreenClass.Name $ "'." $
					"\n\nCall stack and other useful debug info was dumped to the log." );
	}
`endif
	return !inStack;
}

// start issue #198
function SubscribeToOnInput(delegate<CHOnInputDelegate> callback)
{
	// add the delegate to the array of subscribers, if it doesn't exist
    if (OnInputSubscribers.Find(callback) == INDEX_NONE)
    {
        OnInputSubscribers.AddItem(callback);
    }
}
 
function UnsubscribeFromOnInput(delegate<CHOnInputDelegate> callback)
{
	// remove the delegate from the array, if it exists
    if (OnInputSubscribers.Find(callback) != INDEX_NONE)
    {
        OnInputSubscribers.RemoveItem(callback);
    }
}

/* helper function to OnInput() that returns true if any mods are subscribing to the key that was pressed
	Parameters:
		iInput is the int of the most recent input event. See UIUtilities_Input class for values
		ActionMask is the action bitmask associated with the input event. Search for 'Actions - bitmasks' 
			in UIUtilities_Input class, to see possible values
*/
simulated function bool ModOnInput(int iInput, int ActionMask)
{
    local int i;
    local delegate<CHOnInputDelegate> callback;
    for (i = OnInputSubscribers.Length - 1; i >= 0; i--)
    {
        callback = OnInputSubscribers[i];
        if (callback(iInput, ActionMask))
        {
            return true;
        }
    }
}
// end issue #198

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

defaultproperties
{
	ScreensVisible = true
	IsInputBlocked = false
	bCinematicMode = false;
}

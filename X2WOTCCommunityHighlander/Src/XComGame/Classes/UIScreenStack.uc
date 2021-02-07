//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIScreen.uc
//  AUTHOR:  Samuel Batista, Brit Steiner
//  PURPOSE: Base class for managing a SWF/GFx file that is loaded into the game.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIScreenStack extends Object;

// Start issue #501
struct InputDelegateForScreen
{
	var UIScreen Screen;
	var delegate<CHOnInputDelegateImproved> Callback;
};
// End issue #501

var bool IsInputBlocked; // Block UI system from handling input.
var XComPresentationLayerBase Pres;

var bool ScreensVisible; // Cache Movie-level visibility.
var bool DebugHardHide;  // Debug: Hide UI despite other show/hide commands;
var bool bCinematicMode; 
var bool bPauseMenuInput; //Named to the pause menu as this is not for general use

var array<UIScreen> Screens;
var array<UIScreen> ScreensHiddenForCinematic;
var array< delegate<CHOnInputDelegate> > OnInputSubscribers;		// issue #198
var protected array<InputDelegateForScreen> OnInputForScreenSubscribers; // Issue #501

delegate bool CHOnInputDelegate(int iInput, int ActionMask);		// issue #198
delegate bool CHOnInputDelegateImproved(UIScreen Screen, int iInput, int ActionMask); // Issue #501

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

		// Start issue #501
		if (ModOnInputForScreen(Screen, iInput, ActionMask))
		{
			return true;
		}
		// End issue #501

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
		RemoveOnInputSubscribersForScreen(Screen); // Issue #501

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

// Start Issue #290
//
// Lots of code in the base game and mods seems to use `GetScreen()` when
// it should be using `GetFirstInstanceOf()`.

/// HL-Docs: feature:ScreenStackSubClasses; issue:290; tags:compatibility
/// A number of functions in `UIScreenStack` operate on classes, but fail
/// to consider subclasses. This causes subtle bugs in base game and mod
/// code that fails to consider the possibility that a given class can
/// be subclassed/overridden. For example, `UIArmory` does something like this:
///
/// ```unrealscript
/// // Don't allow jumping to the geoscape from the armory when coming from squad select
/// if (!`ScreenStack.IsInStack(class'UISquadSelect'))
/// {
/// 	NavHelp.AddGeoscapeButton();
/// }
/// ```
///
/// However, if `UISquadSelect` is being overridden or replaced, *this can cause the
/// campaign to permanently deadlock* because `UIArmory` fails to find the changed
/// squad select screen. The proper fix would be using `HasInstanceOf`, but this error
/// is extremely common in base game and mod code. As a result, it was decided that
/// the best fix is to change all functions in `UIScreenStack` to always consider
/// subclasses. A full list of affected functions:
///
/// * `GetScreen`
/// * `IsCurrentClass`
/// * `IsInStack`
/// * `IsNotInStack`
///
/// ## Compatibility
///
/// If you legitimately want to *not* consider subclasses, you can use the functions
///
/// ``` unrealscript
/// function UIScreen GetScreen_CH(class<UIScreen> ScreenClass, bool IncludeSubTypes);
/// function bool IsCurrentClass_CH(class<UIScreen> ScreenClass, bool IncludeSubTypes);
/// ```
///
/// and rewrite `IsInStack`/`IsNotInStack` in terms of `GetScreen_CH(...) !=/== none`.

// Returns the first instance of a Screen of the target class type (or a subclass).
simulated function UIScreen GetScreen( class<UIScreen> ScreenClass )
{
	return GetScreen_CH(ScreenClass, true);
}

simulated function UIScreen GetScreen_CH( class<UIScreen> ScreenClass, bool IncludeSubTypes )
{
	local int Index;
	for( Index = 0; Index < Screens.Length;  ++Index)
	{
		if( IncludeSubTypes )
		{
			if (ClassIsChildOf(Screens[Index].Class, ScreenClass))
			{
				return Screens[Index];
			}
		}
		else if( ScreenClass ==  Screens[Index].Class )
		{
			return Screens[Index];
		}
	}
	return none; 
}
// End Issue #290

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

// Start Issue #290
//
// A lot of code seems to assume that certain screen classes will never have
// subclasses, which is rubbish in the context of mods.
simulated function bool IsCurrentClass( class<UIScreen> ScreenClass )
{
	return IsCurrentClass_CH(ScreenClass, true);
}

simulated function bool IsCurrentClass_CH( class<UIScreen> ScreenClass, bool IncludeSubTypes )
{
	if( IncludeSubTypes )
	{
		return ClassIsChildOf(GetCurrentClass(), ScreenClass);
	}
	else
	{
		return GetCurrentClass() == ScreenClass;
	}
}
// End Issue #290

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
/// HL-Docs: feature:SubscribeToOnInput; issue:198; tags:ui
/// Mods may want to intercept mouse/keyboard/controller input and instead run their own code.
/// For most purposes, this feature should be considered superseded by [`SubscribeToOnInputForScreen`](./SubscribeToOnInputForScreen.md),
/// which is more ergonomic to use and harder to misuse. Read that documentation page for a general overview.
///
/// This feature does not allow receiving the notification only for a specific screen, which is usually what
/// you want. Additionally, it is *required* to manually unsubscribe at some point, lest you
/// invoke the wrath of the garbage collector and crash everyone's games.
///
/// ```unrealscript
/// delegate bool CHOnInputDelegate(int iInput, int ActionMask);
/// function SubscribeToOnInput(delegate<CHOnInputDelegate> callback);
/// function UnsubscribeFromOnInput(delegate<CHOnInputDelegate> callback);
/// ```
///
/// Again, it is recommended to instead use [`SubscribeToOnInputForScreen`](./SubscribeToOnInputForScreen.md).
/// The documentation for that feature has examples.
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

/* helper function to OnInput() that returns true if any mods handled this input event
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
	return false;
}
// end issue #198

// Start issue #501
/// HL-Docs: feature:SubscribeToOnInputForScreen; issue:501; tags:ui
/// Mods may want to intercept mouse/keyboard/controller input on certain screens and instead run their own code.
/// For example, the Highlander adds a text to the main menu that has small pop-up accessible
/// by pressing the right controller stick.
///
/// The API consists of a delegate definition and two functions:
///
/// ```unrealscript
/// delegate bool CHOnInputDelegateImproved(UIScreen Screen, int iInput, int ActionMask);
/// function SubscribeToOnInputForScreen(UIScreen Screen, delegate<CHOnInputDelegateImproved> Callback);
/// function UnsubscribeFromOnInputForScreen(UIScreen Screen, delegate<CHOnInputDelegateImproved> Callback);
/// ```
///
/// In a nutshell, with `SubscribeToOnInputForScreen` you ask the UIScreenStack
/// "when screen `Screen` would receive input, ask me first".
/// The `CHOnInputDelegateImproved` delegate defines the signature of the callback function
/// called when the targeted screen would receive input.
///
/// Your function will be called with three arguments: The screen that would have received the input (`Screen`),
/// the button that was pressed (`iInput`), and the action that occured (`ActionMask`, button press/release).
/// The button and action are numeric values that correspond to constants in `UIUtilities_Input.uc`. 
/// If your function returns true, the ScreenStack will consider the input handled and immediately
/// stop processing the input event. If your function returns false, the ScreenStack will continue
/// calling other subscribers and, if unhandled, will finally notify the screen itself.
///
/// You can manually unsubscribe from receiving input, but this is generally not necessary
/// as your callback will only be called when the screen would have received input and
/// will automatically be unsubscribed upon removal of the targeted screen.
///
/// The following simplified example is taken from [Covert Infiltration](https://github.com/WOTCStrategyOverhaul/CovertInfiltration):
///
/// ```unrealscript
/// class UIListener_Mission extends UIScreenListener;
///
/// event OnInit (UIScreen Screen)
/// {
/// 	local UIMission MissionScreen;
///
/// 	MissionScreen = UIMission(Screen);
/// 	if (MissionScreen == none) return;
///
/// 	// This is a UIMission screen, register
/// 	MissionScreen.Movie.Stack.SubscribeToOnInputForScreen(MissionScreen, OnMissionScreenInput);
/// }
///
/// simulated protected function bool OnMissionScreenInput (UIScreen Screen, int iInput, int ActionMask)
/// {
/// 	if (!Screen.CheckInputIsReleaseOrDirectionRepeat(iInput, ActionMask))
/// 	{
/// 		return false;
/// 	}
/// 
/// 	switch (iInput)
/// 	{
/// 	case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
/// 		// The right controller trigger was just released, show custom screen
/// 		// ...
/// 		// Tell the ScreenStack that this input was handled
/// 		return true;
/// 		break;
/// 	}
/// 
/// 	return false;
/// }
/// ```
///
/// `CheckInputIsReleaseOrDirectionRepeat` ensures that the button was just released (or, if directional button,
/// held for a long time), making input behavior more consistent with base game screens.
///
/// Although all mouse events can be inspected, Flash usually provides its own handlers that run even if
/// the callback indicates to the ScreenStack that the input was handled. As a result, the only mouse event
/// that can reliably be stopped with `SubscribeToOnInputForScreen` is the already navigation-relevant
/// right click.
///
/// This feature is a more convenient version of [`SubscribeToOnInput`](./SubscribeToOnInput), which receives
/// events for any screen and has to be manually unsubscribed. `SubscribeToOnInput` offers lower-level
/// interaction with the input system at the cost of ergonomics.
function SubscribeToOnInputForScreen (UIScreen Screen, delegate<CHOnInputDelegateImproved> Callback)
{
	local InputDelegateForScreen CallbackScreenPair;

	// Do not allow duplicate entries
	foreach OnInputForScreenSubscribers(CallbackScreenPair)
	{
		if (CallbackScreenPair.Screen == Screen && CallbackScreenPair.Callback == Callback)
		{
			return;
		}
	}

	CallbackScreenPair.Screen = Screen;
	CallbackScreenPair.Callback = Callback;

	OnInputForScreenSubscribers.AddItem(CallbackScreenPair);
}

function UnsubscribeFromOnInputForScreen (UIScreen Screen, delegate<CHOnInputDelegateImproved> Callback)
{
	local InputDelegateForScreen CallbackScreenPair;
	local int i;

	foreach OnInputForScreenSubscribers(CallbackScreenPair, i)
	{
		if (CallbackScreenPair.Screen == Screen && CallbackScreenPair.Callback == Callback)
		{
			OnInputForScreenSubscribers.Remove(i, 1);
			return; // Since duplicates aren't allowed, we are done
		}
	}
}

// The next 2 functions were intended to be private, but by accident were released into a stable version as public.
// As such, they are technically covered by the BC policy.
// HOWEVER, MODS ARE STRONGLY DISCOURAGED FROM USING THEM.
// Please open a github issue first if you have a use case for calling either (or both) directly.

/*private*/ function RemoveOnInputSubscribersForScreen (UIScreen Screen)
{
	local int i;

	for (i = 0; i < OnInputForScreenSubscribers.Length; i++)
	{
		if (OnInputForScreenSubscribers[i].Screen == Screen)
		{
			OnInputForScreenSubscribers.Remove(i, 1);
			i--;
		}
	}
}

simulated /*private*/ function bool ModOnInputForScreen (UIScreen Screen, int iInput, int ActionMask)
{
	local delegate<CHOnInputDelegateImproved> Callback;
	local InputDelegateForScreen CallbackScreenPair;

	foreach OnInputForScreenSubscribers(CallbackScreenPair)
	{
		if (CallbackScreenPair.Screen == Screen)
		{
			Callback = CallbackScreenPair.Callback;
			
			if (Callback(Screen, iInput, ActionMask))
			{
				return true;
			}
		}
	}

	return false;
}
// End issue #501

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

defaultproperties
{
	ScreensVisible = true
	IsInputBlocked = false
	bCinematicMode = false;
}

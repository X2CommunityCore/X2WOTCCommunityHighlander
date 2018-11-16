//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPanel.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Base class of the UI control system (dynamic panels)
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIPanel extends Actor native(UI);

// Library identifier necessary to dynamically initialize control, look at UIUtilities_Controls for valid IDs
var name LibID;

// Instance name, leave empty to auto generate, or specify manually to link up with an existing MovieClip
var name MCName;

// Plays an animation (fade in by default) when control is initialized, true by default
var bool bAnimateOnInit;

// Cascade OnRecieveFocus to ALL child panels (on by default)
var bool bCascadeFocus;

// Cascade navigation current selected child when receiving focus and navigable (on by default)
var bool bCascadeSelection; 

// If true, this UI element should play generic audio events on mouseover & click
var bool bShouldPlayGenericUIAudioEvents;

// Watch handle on display size changes, to automatically re-Anchor UIControls when resolution changes 
var int AnchorWatch;

// Basic data shared by all panels
var float X;
var float Y;
var float Width;
var float Height;
var float Alpha;
var float RotationDegrees;
var int Anchor;
var int Origin;

var bool bIsInited;
var bool bIsVisible;
var bool bIsFocused;
var bool bIsRemoved;
var bool bHasTooltip;

var int CachedTooltipId;
// Whether this control should be added to its parent's navigator or not
var bool bIsNavigable;

// Call EnableMouseHit or DisableMouseHit to enable or disable mouse functionality for this control
var bool bHitTestDisabled;
  
// UIPanels don't receive mouse events by default
// Set this variable to true in the default properties or call ProcessMouseEvents() to receive mouse events 
// NOTE: Does not work if bHitTestDisabled is set to true
var bool bProcessesMouseEvents;

// Full path that corresponds to the movie clip path in Flash, used to process OnInit, OnMouseEvent, and OnCommand
// NOTE: private on purpose, use MCPath to access this value
var name MCPath;

// External references
var UIMovie Movie;
var UIScreen Screen;
var XComPlayerController PC;

// Flash batching controller
var UIMCController MC;

// Navigation helper for keyboard / gamepad input
var UINavigator Navigator;

// Child / ParentPanel Controls
var UIPanel ParentPanel;
var array<UIPanel> ChildPanels;
var public delegate<OnChildChanged> OnChildAdded;
var public delegate<OnChildChanged> OnChildRemoved;

// List of delegates that will be triggered when this control is initialized
var array<delegate<OnPanelInited> > OnInitDelegates;

// List of delegates that will be triggered when this control is removed
var array<delegate<OnPanelRemoved> > OnRemovedDelegates;

// Delegate definitions
delegate OnPanelInited(UIPanel Panel);
delegate OnPanelRemoved(UIPanel Panel);
delegate OnChildChanged(UIPanel Child);
delegate OnMouseEventDelegate(UIPanel Panel, int Cmd);

// Initializes a UIPanel
// NOTE: This should be called before any other operation takes place on a UIPanel object
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	// Process optional parameters
	if( InitName != '' ) MCName = InitName;
	if( InitLibID != '' ) LibID = InitLibID;

	// If MCName is not specified, use Unreal's auto generated name since it's guaranteed to be unique
	if( MCName == '' ) MCName = self.Name;

	// Create navigator (used in List and gamepad / arrow key navigation)
	Navigator = new(self) class'UINavigator';
	Navigator.InitNavigator(self);

	// UIScreen handles setting external members in InitScreen()
	if( self.IsA('UIScreen') )
	{
		// Screens are contained within a container in the Movie (Self.Name)
		MCPath = name(Movie.MCPath $ "." $ Self.Name $ "." $ MCName);

		// Spawn the controller on UIScreens as well, assuming Movie is already assigned
		MC = new(self) class'UIMCController';
		MC.InitController(self);
	}
	else
	{
		// Panels must always be owned by a parent panel
		ParentPanel = UIPanel(Owner);

		PC = ParentPanel.PC;
		Movie = ParentPanel.Movie;
		Screen = ParentPanel.Screen;
		MCPath = name(ParentPanel.MCPath $ "." $ MCName);

		// NOTE: MC must be initialized after Movie is assigned, and before AddChild occurs
		MC = new(self) class'UIMCController';
		MC.InitController(self);

		ParentPanel.AddChild(self);
		ParentPanel.LoadChild(self);

		if( bIsNavigable )
			EnableNavigation();
	}

	// Every panel is a child of screen (including screens themselves)
	// This allows OnInit, OnMouseEvent, and OnCommand events to find us
	// NOTE: If Screen is the same as ParentPanel, we're already in Screen's ChildPanels
	if(Screen != none && Screen != ParentPanel)
		Screen.AddChild(self);

	// Enable mouse handling if bProcessesMouseEvents is set to true
	if( bProcessesMouseEvents )
		MC.FunctionVoid("processMouseEvents");

	return self;
}

// Add a delegate that will get called when this panel is initialized
simulated function AddOnInitDelegate(delegate<OnPanelInited> Callback)
{
	if(bIsInited)
	{
		`warn("Adding OnInit delegate to an already initialized Panel: '" $ MCName $ "'!");
		return;
	}
	if(onInitDelegates.Find(Callback) == INDEX_NONE)
		onInitDelegates.AddItem(Callback);
}

// Remove a delegate that would get called when this panel is initialized
simulated function ClearOnInitDelegate(delegate<OnPanelInited> Callback)
{
	local int Index;
	Index = OnInitDelegates.Find(Callback);
	if (Index != INDEX_NONE)
		OnInitDelegates.Remove(Index, 1);
}

simulated function OnInit()
{
	local int i;
	local delegate<OnPanelInited> OnInitDelegate;

	bIsInited = true;

	// Panels start hidden in flash, show them once their commands are initially processed (unless explicitly hidden)
	if( bIsVisible )
	{
		MC.SetBool("_visible", true);

		if( bAnimateOnInit )
			AnimateIn();
	}

	// Process any commands that might have been queued up before this panel was initialized
	// The order of operations is important here, we must process queued commands before loading any pending children
	MC.ProcessCommands(true);

	// Trigger OnInitDelegates
	for(i = 0; i < OnInitDelegates.Length; ++i)
	{
		OnInitDelegate = OnInitDelegates[i];
		if( OnInitDelegate != none )
			OnInitDelegate( self );
	}
}

simulated function UIPanel ProcessMouseEvents(optional delegate<OnMouseEventDelegate> MouseEventDelegate)
{
	OnMouseEventDelegate = MouseEventDelegate;
	if( !bProcessesMouseEvents )
	{
		bProcessesMouseEvents = true;
		MC.FunctionVoid("processMouseEvents");
	}
	return self;
}

simulated function UIPanel IgnoreMouseEvents()
{
	OnMouseEventDelegate = none;
	if( bProcessesMouseEvents )
	{
		bProcessesMouseEvents = false;
		MC.FunctionVoid("ignoreMouseEvents");
	}
	return self;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local UIList ContainerList;

	if( bShouldPlayGenericUIAudioEvents )
	{
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
			break;
		}
	}

	// HAX: Lists must handle all child mouse events
	ContainerList = UIList(GetParent(class'UIList'));
	if( ContainerList != none )
	{
		ContainerList.OnChildMouseEvent(self, cmd);
	}
	else
	{
		switch(cmd)
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			OnReceiveFocus();
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			OnLoseFocus();
			break;
		}
	}

	if( OnMouseEventDelegate != none )
		OnMouseEventDelegate(self, cmd);
}

simulated function bool HasHitTestDisabled()
{
	if(bHitTestDisabled)
		return true;
	else if(ParentPanel != none)
		return ParentPanel.HasHitTestDisabled();
	else
		return false;
}

simulated function UIPanel SetHitTestDisabled(bool DisableHitTest)
{
	if( bHitTestDisabled != DisableHitTest )
	{
		bHitTestDisabled = DisableHitTest;
		MC.SetBool("hitTestDisable", bHitTestDisabled);
	}
	return self;
}

simulated function UIPanel EnableMouseHit() { return SetHitTestDisabled(false); }
simulated function UIPanel DisableMouseHit() { return SetHitTestDisabled(true); }

simulated function SetTooltip(UITooltip Tooltip)
{
	Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(Tooltip);
	bHasTooltip = true;
}

// Tooltip code is kinda nasty - TODO @sbatista - cleanup unused params before ship
simulated function SetTooltipText(string Text, 
								  optional string Title,
								  optional float OffsetX,
								  optional float OffsetY, 
								  optional bool bRelativeLocation   = class'UITextTooltip'.default.bRelativeLocation,
								  optional int TooltipAnchor        = class'UITextTooltip'.default.Anchor, 
								  optional bool bFollowMouse        = class'UITextTooltip'.default.bFollowMouse,
								  optional float Delay              = class'UITextTooltip'.default.tDelay)
{

	if( bHasTooltip )
	{
		RemoveTooltip();
	}
	
	if( Text != "" ) 
	{
		CachedTooltipId = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(Text,
													  OffsetX,
													  OffsetY,
													  string(MCPath),
													  Title,
													  bRelativeLocation,
													  TooltipAnchor,
													  bFollowMouse,
		class'UITextTooltip'.default.maxW,
		class'UITextTooltip'.default.maxH,
		class'UITextTooltip'.default.eTTBehavior,
		class'UITextTooltip'.default.eTTColor,
		class'UITextTooltip'.default.tDisplayTime,
			Delay);
		bHasTooltip = true;
	}
}

simulated function RemoveTooltip()
{
	Movie.Pres.m_kTooltipMgr.RemoveTooltips(self);
	bHasTooltip = false;
}

simulated function UIPanel SetPosition(float NewX, float NewY)
{
	if( X != NewX || Y != NewY )
	{
		X = NewX;
		Y = NewY;
		RealizeLocation();
	}
	return self;
}

// Sets the position of this UIPanel based on a 0-1 range, where if NormalizedPos.X=1 then X=1920 and NormalizedPos.Y=1 then Y=1080
simulated function UIPanel SetNormalizedPosition(Vector2D NormalizedPos)
{
	NormalizedPos = Movie.ConvertNormalizedScreenVectorToUICoords(NormalizedPos);
	return SetPosition(NormalizedPos.X, NormalizedPos.Y);
}

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	if( Width != NewWidth || Height != NewHeight )
	{
		Width = NewWidth;
		Height = NewHeight;

		// example of calling an actionscript function with multiple parameters:

		MC.BeginFunctionOp("setSize");							// begin function call
		MC.QueueNumber(Width);									// add param
		MC.QueueNumber(Height);									// add param (...)
		MC.EndOp();												// end function call (queue it for processing)
	}
	return self;
}

//accepts a 0-1 scale pct (can exceed 1), though actionscript2 uses a 0-100 scale pct
simulated function UIPanel SetPanelScale(float NewScale)
{
	MC.SetNum("_xscale", NewScale * 100);
	MC.SetNum("_yscale", NewScale * 100);

	return Self;
}

// Expects the const Anchor values from UIUtilities. 
simulated function UIPanel SetAnchor(int NewAnchor)
{
	if( Anchor != NewAnchor )
	{
		// Turn off notification if we no longer care about anchoring 
		if( NewAnchor == class'UIUtilities'.const.ANCHOR_NONE && AnchorWatch != class'UIPanel'.default.AnchorWatch )
		{
			WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(AnchorWatch, false);
		}

		Anchor = NewAnchor;
		MC.FunctionNum("setAnchor", float(Anchor));
		RealizeLocation();

		// Turn on notification if we care about anchoring 
		if( Anchor != class'UIUtilities'.const.ANCHOR_NONE )
		{
			// Watch for resolution changes for automatic re-positioning
			if( AnchorWatch == class'UIPanel'.default.AnchorWatch )
				AnchorWatch = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(Movie, 'm_v2ScaledDimension', self, RealizeLocation);
			else
				WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(AnchorWatch, true);
		}
	}
	return self;
}

// Expects the const Anchor values from UIUtilities. 
simulated function UIPanel SetOrigin(int NewOrigin)
{
	if( Origin != NewOrigin )
	{
		Origin = NewOrigin;
		MC.FunctionNum("setOrigin", float(Origin));
		RealizeLocation();
	}
	return self;
}

simulated function UIPanel AnchorCenter() { return SetAnchor(class'UIUtilities'.const.ANCHOR_MIDDLE_CENTER); }
simulated function UIPanel AnchorTopCenter() { return SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_CENTER); }
simulated function UIPanel AnchorBottomCenter() { return SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER); }
simulated function UIPanel AnchorTopLeft() { return SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT); }
simulated function UIPanel AnchorBottomLeft() { return SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT); }
simulated function UIPanel AnchorTopRight() { return SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT); }
simulated function UIPanel AnchorBottomRight() { return SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT); }

simulated function UIPanel OriginCenter() { return SetOrigin(class'UIUtilities'.const.ANCHOR_MIDDLE_CENTER); }
simulated function UIPanel OriginTopCenter() { return SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_CENTER); }
simulated function UIPanel OriginBottomCenter() { return SetOrigin(class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER); }
simulated function UIPanel OriginTopLeft() { return SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_LEFT); }
simulated function UIPanel OriginBottomLeft() { return SetOrigin(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT); }
simulated function UIPanel OriginTopRight() { return SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT); }
simulated function UIPanel OriginBottomRight() { return SetOrigin(class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT); }

// Extra helper functions to position UIPanel elements
simulated function UIPanel CenterOnScreen() 
{
	AnchorCenter();
	return CenterWithin(self);
}
simulated function UIPanel CenterWithin(UIPanel Panel)
{
	AnchorCenter();
	SetPosition( -0.5 * Panel.Width, -0.5 * Panel.Height );
	return self; 
}

// Overrides the color of this panel, expects a hex string, ex: 0xFFFFFF
// Look at UIUtilities_Colors to get preset hex colors.
simulated function UIPanel SetColor(string HexColor)
{
	MC.FunctionString("setColor", HexColor);
	Alpha = 100;
	return self;
}

// Start Issue #258
// PI Mods: Allow changing of colors of arbitrary MCs within a panel. Pass the full path to the MC
// as the first argument as string, and the hex color as the 2nd argument as SetColor above.
simulated function AS_SetMCColor(string ClipPath, string HexColor)
{
	Movie.ActionScriptVoid("Colors.setColor");
}
// End Issue #258

/*** IMPORTANT NOTICE ****
 *  
 * The following cannot return self because we wish them to be manipulated by Scrollbar.
 * Because of that, these function signatures must match delegate OnCalculatedValueChangeCallback.
 * 
 */
simulated function SetAlpha(float NewAlpha)
{
	//Auto convert to Flash values, because we end up creating bugs on ourselves if we don't. 
	if( NewAlpha > 0 && NewAlpha <= 1.0 ) 
		NewAlpha *= 100; // 0 - 100

	if( Alpha != NewAlpha )
	{
		Alpha = NewAlpha;
		MC.FunctionNum("setAlpha", Alpha);
	}
}

simulated function SetRotationDegrees(float NewRotation)
{
	if( RotationDegrees != NewRotation )
	{
		RotationDegrees = NewRotation;
		MC.FunctionNum("setRotation", RotationDegrees);
	}
}

simulated function SetX(float NewX)
{
	if( X != NewX )
	{
		X = NewX;
		RealizeLocation();
	}
}

simulated function SetY(float NewY)
{
	if( Y != NewY )
	{
		Y = NewY;
		RealizeLocation();
	}
}

simulated function SetWidth(float NewWidth)
{
	if( Width != NewWidth )
	{
		Width = NewWidth;
		MC.FunctionNum("setWidth", Width);
	}
}

simulated function SetHeight(float NewHeight)
{
	if( Height != NewHeight )
	{
		Height = NewHeight;
		MC.FunctionNum("setHeight", Height);
	}
}

simulated function RealizeLocation()
{
	RealizeLocationNative();
}

native function RealizeLocationNative();

simulated function Show()
{
	if( !bIsVisible )
	{
		bIsVisible = true;
		if (MC != none)
			MC.FunctionVoid("Show");
	}
}

simulated function Hide()
{
	if( bIsVisible )
	{
		bIsVisible = false;
		if (MC != none)
			MC.FunctionVoid("Hide");
	}
}

simulated function SetVisible(bool bVisible)
{
	if( bVisible ) 
		Show();
	else
		Hide();
}

simulated function ToggleVisible()
{
	if( bIsVisible ) 
		Hide();
	else
		Show();
}

//Request this panel move itself up to the highest available depth in it's parent context. 
simulated function MoveToHighestDepth()
{
	MC.FunctionVoid("MoveToHighestDepth");
}

// This is overwritten in child classes that care about focus functionality
simulated function OnReceiveFocus()
{
	local UIPanel Child;

	if(!bIsFocused) 
	{
		bIsFocused = true;
		MC.FunctionVoid("onReceiveFocus");
	}

	if(bCascadeSelection)
	{
		Child = Navigator.GetSelected();
		if( Child == none )
		{
			if( Navigator.SelectFirstAvailableIfNoCurrentSelection() )
			{
				Child = Navigator.GetSelected();
			}
		}

		if( Child != none && Child != self )
			Child.OnReceiveFocus();
	}

	if(bCascadeFocus)
	{
		foreach ChildPanels(Child)
		{
			if(Child != self)
				Child.OnReceiveFocus();
		}
	}
}

simulated function OnLoseFocus()
{
	local UIPanel Child;

	if(bIsFocused) 
	{
		bIsFocused = false;
		MC.FunctionVoid("onLoseFocus");
	}

	if( bCascadeSelection )
	{
		Child = Navigator.GetSelected();

		if( Child != none && Child != self )
			Child.OnLoseFocus();
	}

	if(bCascadeFocus)
	{
		foreach ChildPanels(Child)
		{
			if(Child != self)
				Child.OnLoseFocus();
		}
	}
}

simulated function OnCommand(string cmd, string arg)
{
	`log("Unhandled command '" $ cmd $ "," $ arg $ "' sent to '" $ MCPath $ "'.",,'uicore' );
}

simulated function EnableNavigation()
{
	bIsNavigable = true;
	if( ParentPanel != none && ParentPanel.Navigator.GetIndexOf(self) == -1 )
		ParentPanel.Navigator.AddControl(Self);
}

simulated function DisableNavigation()
{
	bIsNavigable = false;
	if (ParentPanel != none)
		ParentPanel.Navigator.RemoveControl(Self);
}

simulated function SetSelectedNavigation()
{
	if( bIsNavigable && ParentPanel != none )
		ParentPanel.Navigator.SetSelected(self);
}

simulated function bool IsSelectedNavigation()
{	
	if( bIsNavigable )
	{ 
		if( ParentPanel == none )
			return true;
		else
			return ParentPanel.Navigator.GetSelected() == self;
	}

	return false; 
}

// ------------------------------------------
// CONTROLLER / KEYBOARD INPUT
// ------------------------------------------

simulated native function bool OnUnrealCommand(int cmd, int arg);
simulated native function bool CheckInputIsReleaseOrDirectionRepeat(int cmd, int arg);

// ------------------------------------------
// ANIMATION 
// ------------------------------------------

//Override the panel versions, to batch these. 
simulated function AnimateScroll(float ObjectHeight, float MaskHeight)
{
	//Check sizes to see if we need to scroll at all. This check also happens flash-side, but let's save the call across the wire if we can. 
	if( ObjectHeight > MaskHeight )
	{
		MC.BeginFunctionOp("animateScroll");
		MC.QueueNumber(ObjectHeight);  
		MC.QueueNumber(MaskHeight);  
		MC.EndOp();
	}
}

simulated function ClearScroll()
{
	MC.FunctionVoid("clearScroll");
}

// Access the FxsTween system. 
// Ease is converted to the easing function name. 
simulated function AddTween( String Prop, float Value, float Time, optional float Delay = 0.0, optional String Ease = "linear" )
{
	MC.BeginFunctionOp("addTween"); 

	MC.QueueString(Prop);   
	MC.QueueNumber(Value);  
	
	MC.QueueString("time");  
	MC.QueueNumber(Time);  

	if( Delay != 0.0 )
	{
		MC.QueueString("delay");  
		MC.QueueNumber(Delay);
	}

	if( Ease != "linear" )
	{
		MC.QueueString("ease");  
		MC.QueueString(Ease); 
	}

	MC.EndOp();
}

simulated function AddTweenBetween( String Prop, float StartValue, float EndValue, float Time, optional float Delay = 0.0, optional String Ease = "linear" )
{
	MC.BeginFunctionOp("addTweenBetween");

	MC.QueueString(Prop);
	MC.QueueNumber(StartValue);
	MC.QueueNumber(EndValue);

	MC.QueueString("time");
	MC.QueueNumber(Time);

	if( Delay != 0.0 )
	{
		MC.QueueString("delay");
		MC.QueueNumber(Delay);
	}

	if( Ease != "linear" )
	{
		MC.QueueString("ease");
		MC.QueueString(Ease);
	}

	MC.EndOp();
}

// Removes all tweens (including delayed tweens).
simulated function RemoveTweens()
{
	MC.FunctionVoid("removeTweens");
}

simulated function AnimateIn(optional float Delay = -1.0)
{
	if( Delay == -1.0 && ParentPanel != none)
		Delay = ParentPanel.GetDirectChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; // Issue #341

	AddTweenBetween("_alpha", 0, Alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
}

simulated function AnimateOut(optional float Delay = -1.0)
{
	if( Delay == -1.0 && ParentPanel != none )
		Delay = ParentPanel.GetDirectChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; // Issue #341

	AddTweenBetween("_alpha", Alpha, 0, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
}

simulated function AnimateY(float NewY, optional float Time = class'UIUtilities'.const.INTRO_ANIMATION_TIME, optional float Delay = 0.0)
{
	if( Y != NewY )
	{
		Y = NewY;
		AddTween("_y", Y, Time, Delay, "easeoutquad");
	}
}

simulated function AnimateX(float NewX, optional float Time = class'UIUtilities'.const.INTRO_ANIMATION_TIME, optional float Delay = 0.0)
{
	if( X != NewX )
	{
		X = NewX;
		AddTween("_x", X, Time, Delay, "easeoutquad");
	}
}

simulated function AnimatePosition(float NewX, float NewY, optional float Time = class'UIUtilities'.const.INTRO_ANIMATION_TIME, optional float Delay = 0.0)
{
	AnimateX(NewX, Time, Delay);
	AnimateY(NewY, Time, Delay);
}

simulated function AnimateWidth( float NewWidth, optional float Time = class'UIUtilities'.const.INTRO_ANIMATION_TIME, optional float Delay = 0.0)
{
	if( Width != NewWidth )
	{
		Width = NewWidth; 
		AddTween("_width", Width, Time, Delay, "easeoutquad");
	}
}

simulated function AnimateHeight(float NewHeight, optional float Time = class'UIUtilities'.const.INTRO_ANIMATION_TIME, optional float Delay = 0.0)
{
	if( Height != NewHeight )
	{
		Height = NewHeight;
		AddTween("_height", Height, Time, Delay, "easeoutquad");
	}
}

simulated function AnimateSize(float NewWidth, float NewHeight, optional float Time = class'UIUtilities'.const.INTRO_ANIMATION_TIME, optional float Delay = 0.0)
{
	AnimateWidth(NewWidth, Time, Delay);
	AnimateHeight(NewHeight, Time, Delay);
}

//==============================================================================
// 		PARENTING (TODO: NATIVIZE ALL FUNCTIONS BELLOW)
//==============================================================================

simulated function LoadChild(UIPanel Child)
{
	MC.BeginFunctionOp("spawnChildPanel");
	MC.QueueString(string(Child.MCName));
	MC.QueueString(string(Child.LibID));
	MC.QueueNumber(float(Child.MC.CacheIndex));
	MC.EndOp();
}

simulated native function AddChild(UIPanel Child);
simulated native function RemoveChild(UIPanel Child);
simulated native function RemoveChildren();

// TODO: Nativize
simulated function UIPanel GetChild(name ChildName, optional bool ErrorIfNotFound = true) 
{
	return GetChildByName( ChildName, ErrorIfNotFound );
}

// TODO: Nativize
simulated function UIPanel GetChildByName(Name ChildName, optional bool ErrorIfNotFound = true)
{
	local UIPanel ChildControl, RecursiveControl; 

	foreach ChildPanels(ChildControl)
	{
		if( ChildControl.MCName == ChildName )
		{
			return ChildControl; 
		}
		else if( ChildControl != self ) // Screens insert themselves into their ChildPanels array
		{
			RecursiveControl = ChildControl.GetChildByName(ChildName, false);
			if( RecursiveControl != none )
				return RecursiveControl;
		}
	}

	// Don't print errors when recursing through children.
	if( ErrorIfNotFound )
	{
		ScriptTrace();
		`warn("UI ERROR: could not find child panel '" $ ChildName $ "' in '" $ self.MCName $ "'.");
	}
	return none;
}

// TODO: Nativize
simulated function UIPanel GetChildAt( int Index, optional bool ErrorIfNotFound = true ) 
{
	if( Index < 0 || Index >= ChildPanels.Length && ErrorIfNotFound )
	{
		ScriptTrace();
		`warn("UI ERROR: could not find child control at Index '" $ Index $ "' in '" $ self.MCName $ "'.");
		return none;
	}
	return ChildPanels[Index];
}

// TODO: Nativize
//Does not search recursively, because we only want the local Index on this flat level 
simulated function int GetChildIndex(UIPanel Child, optional bool ErrorIfNotFound = true)
{
	local int i; 

	for(i = 0; i < ChildPanels.Length; ++i)
	{
		if( ChildPanels[i] == Child )
			return i; 
	}

	// Don't print errors when recursing through children.
	if( ErrorIfNotFound )
	{
		ScriptTrace();
		`warn("UI ERROR: could not find Index of the child control '" $ Child.MCName $ "' in '" $ self.MCName $ "'.");
	}
	return -1;
}

// Start Issue #341: Function to be used when actually getting the "direct" child index.
// UIScreens get all their recursive child panels added, so GetChildIndex is unusable for AnimateIn
simulated function int GetDirectChildIndex(UIPanel Child, optional bool ErrorIfNotFound = true)
{
	local int i, index;

	for(i = 0; i < ChildPanels.Length; ++i)
	{
		if( ChildPanels[i] == Child )
			return index; 

		if (ChildPanels[i].ParentPanel == self)
			index++;
	}

	// Don't print errors when recursing through children.
	if( ErrorIfNotFound )
	{
		ScriptTrace();
		`warn("UI ERROR: could not find Index of the child control '" $ Child.MCName $ "' in '" $ self.MCName $ "'.");
	}
	return -1;
}
// End Issue #341

// TODO: Nativize
simulated function GetChildrenOfType(class ClassType, out array<UIPanel> ChildrenOfType)
{
	local int i;
	for(i = 0; i < ChildPanels.Length; ++i)
	{
		// screens contain themselves in their ChildPanels array
		if(ChildPanels[i] != self)
		{
			if(ChildPanels[i].IsA(ClassType.Name))
				ChildrenOfType.AddItem(ChildPanels[i]);
			ChildPanels[i].GetChildrenOfType(ClassType, ChildrenOfType);
		}
	}
}

simulated function SwapChildren(int ChildIndexA, int ChildIndexB)
{
	local UIPanel Panel;

	Panel = ChildPanels[ChildIndexA];
	ChildPanels[ChildIndexA] = ChildPanels[ChildIndexB];
	ChildPanels[ChildIndexB] = Panel;

	// Start Issue #47
	// Tell the navigator to swap its controls too
	// or keyboard nav will be out of sync.
	// Note the swap of B and A, we already changed them in the array above
	Navigator.SwapControls(ChildPanels[ChildIndexB], ChildPanels[ChildIndexA]);
	// End Issue #47
}

simulated function int NumChildren()
{
	return ChildPanels.Length;
}

simulated function UIPanel GetParent(class ClassType, optional bool bInheritsClass)
{
	if( ParentPanel != none )
	{
		if( (bInheritsClass && ParentPanel.IsA(ClassType.Name)) || ParentPanel.Class == ClassType )
			return ParentPanel;
		else
			return ParentPanel.GetParent(ClassType, bInheritsClass);
	}
	return none;
}

//==============================================================================
// 		DEPRECATED FLASH INTERFACE
//==============================================================================

// Calls a function on an existing MC in Flash (must be triggered after OnInit call)
simulated native function Invoke(string FunctionToCall, optional Array<ASValue> Parameters);
simulated native function SetVariable(string FieldToSet, optional ASValue Value);

//==============================================================================
// 		REMOVAL + DEBUG 
//==============================================================================

simulated native function Remove();

// Add a delegate that will get called when this panel is initialized
simulated function AddOnRemovedDelegate(delegate<OnPanelRemoved> Callback)
{
	if( OnRemovedDelegates.Find(Callback) == INDEX_NONE )
		OnRemovedDelegates.AddItem(Callback);
}

// Remove a delegate that would get called when this panel is initialized
simulated function ClearOnRemovedDelegate(delegate<OnPanelRemoved> Callback)
{
	local int Index;
	Index = OnRemovedDelegates.Find(Callback);
	if( Index != INDEX_NONE )
	{
		OnRemovedDelegates.Remove(Index, 1);
	}
}

// Called during Remove
simulated event Removed()
{
	local int i;
	local delegate<OnPanelRemoved> OnRemovedDelegate;

	MC.Remove();

	Navigator.Clear();
	DisableNavigation();

	if(bHasTooltip)
		RemoveTooltip();

	if( AnchorWatch != class'UIPanel'.default.AnchorWatch )
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(AnchorWatch);

	// Trigger OnRemovedDelegates
	for( i = 0; i < OnRemovedDelegates.Length; ++i )
	{
		OnRemovedDelegate = OnRemovedDelegates[i];
		if( OnRemovedDelegate != None )
		{
			OnRemovedDelegate(self);
		}
	}
	OnRemovedDelegates.Length = 0;

	bIsRemoved = true;
}

// Override this function to show useful debugging information.
// Called from XComCheatManager.UIDebugControls
simulated function DebugControl();

simulated function PrintNavigator(optional string Indentation = "")
{
	//`log("+" @ Name @ "PrintDebugNavigator +++++++++++++++++++++++++", , 'uixcom' );

	Navigator.PrintDebug(true, Indentation);
}

simulated function PrintPanelNavigationInfo(optional bool bCascade = false, optional bool bShowNavigatorInfo = false, optional string Indentation = "")
{
	local int i;
	local UIPanel SelectedControl, Control; 
	local string DisplayBuffer; 

	if( ChildPanels.Length == 0 )
	{
		return;
	}
	else if( Indentation == "" )
	{
		`log(" ", , 'uixcom' );
		`log(Indentation $"+" @ MCName @ Name @ "Panel.PrintDebugNavigationInfo +++++++++++++++++++++++++", , 'uixcom' );
		//`log(Indentation $"-- ChildPanels --", , 'uixcom' );
	}

	SelectedControl = Navigator.GetSelected();
	for( i = 0; i < ChildPanels.length; i++ )
	{
		Control = ChildPanels[i];
		DisplayBuffer = Control.bIsNavigable ? " " : "";

		if( SelectedControl == Control )
			`log(Indentation $">>>>>"@ Control.bIsNavigable @ DisplayBuffer$" | " @ Control.MCName @ Control.Name, , 'uixcom' );
		else
			`log(Indentation $"|||||"@ Control.bIsNavigable @ DisplayBuffer$" | " @ Control.MCName @ Control.Name, , 'uixcom' );
	}

	if( bShowNavigatorInfo )
	{
		Navigator.PrintDebug(false, Indentation);
	}
	if( bCascade )
	{
		for( i = 0; i < ChildPanels.length; i++ )
		{
			if( ChildPanels[i].bIsNavigable && ChildPanels[i] != self )
				ChildPanels[i].PrintPanelNavigationInfo(bCascade, bShowNavigatorInfo, (Indentation $"   "));
		}
	}
}

defaultproperties
{
	LibID = "EmptyControl";

	bIsVisible = true;
	bIsFocused = false;
	bIsNavigable = true;

	bCascadeFocus = true;
	bCascadeSelection = false;
	bAnimateOnInit = true;
	bProcessesMouseEvents = false;
	bShouldPlayGenericUIAudioEvents = true;

	Anchor = 0;
	Origin = 0; 

	Alpha = 100; // 0 - 100
	RotationDegrees = 0; // 0 - 360
	
	AnchorWatch = -1;
}

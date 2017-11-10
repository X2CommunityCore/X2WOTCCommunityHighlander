//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UINavigator.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Automatic navigation control for navigable UI elements. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UINavigator extends Object;

struct UINavTarget
{
	var UIPanel Control; 
	var int Cmd; 
	var int Arg; 
};

var UIPanel OwnerControl;

var int Size;
var public int SelectedIndex;

var public bool LoopSelection;
var public bool LoopOnReceiveFocus;
var public bool HorizontalNavigation;
// If this is set to true we're going to avoid going through prev and next functions, because those are 2 different systems of navigation.
var public bool OnlyUsesNavTargets;

var array<UIPanel> NavigableControls;
var array<UINavTarget> NavigationTargets;

var public delegate<OnNavigablesChanged> OnAdded;
var public delegate<OnNavigablesChanged> OnRemoved;
var public delegate<OnCheckForOwnerHandling> CheckForOwnerHandling;

delegate OnNavigablesChanged(UIPanel Control);
delegate OnSelectedIndexChanged(int NewIndex);
delegate bool OnCheckForOwnerHandling(bool bIsNext); // true for next, false for prev 

public function UINavigator InitNavigator(UIPanel InitPanel)
{
	OwnerControl = InitPanel;
	return self;
}

public function AddControl(UIPanel Control)
{
	if(NavigableControls.Find(Control) == INDEX_NONE)
	{
		Size++;

		NavigableControls.AddItem(Control);

		if(OnAdded != none)
			OnAdded(Control);

		if(OnNavigablesChanged != none)
			OnNavigablesChanged(Control);
	}
}

public function RemoveControl(UIPanel Control)
{
	local int RegularIndex, TargetIndex; 
	
	RegularIndex = NavigableControls.Find(Control);
	if(RegularIndex > INDEX_NONE)
	{
		NavigableControls.RemoveItem(Control);
		Size--;

		// Keep the selection in range, and will also take care of setting to -1 if no navigables remain. 
		if( Size > 0 )
		{
			//We don't need to update selection if the current selection is less than the removed item 
			if( SelectedIndex >= RegularIndex )
			{
				if( IsValid(SelectedIndex) )
				{
					if( SelectedIndex == RegularIndex )
					{
						// If we removed the item that was currently selected, then refresh selection on the next item in the array, 
						// which has now moved "forward" in the array because of the deletion. 
						SelectedIndex--;
						Next();
					}
					else
					{
						// Else the selection was after the deletion, keep the visual selection stable by adjusting the selected index. 
						SetSelected(NavigableControls[SelectedIndex - 1]);
					}
				}
				else
				{
					//If we don't have a valid selection, then try go find something to select. 
					SelectFirstAvailableIfNoCurrentSelection();
				}
			}
		}
	}

	//Check the manual nav targets for the control. 
	TargetIndex = NavigationTargets.Find('Control', Control);
	if( TargetIndex > Index_NONE )
		NavigationTargets.RemoveItem(NavigationTargets[TargetIndex]);
	
	//Only trigger callbacks if a change was made 
	if( RegularIndex != -1 || TargetIndex != -1 )
	{
		if( OnRemoved != none )
			OnRemoved(Control);

		if( OnNavigablesChanged != none )
			OnNavigablesChanged(Control);
	}
}

simulated function bool OnUnrealCommand( int Cmd, int Arg )
{
	local bool bHandled;
	local UIPanel Selected;

	bHandled = SendToNavigationTargets( Cmd, Arg ); 
	if( bHandled ) return true; 

	if( !OnlyUsesNavTargets )
	{
		switch( Cmd )
		{
			case class'UIUtilities_Input'.const.FXS_ARROW_UP:
			case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
				if( !HorizontalNavigation )
					bHandled = Prev(,, Arg == class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
				break;
			case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
			case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
				if( !HorizontalNavigation )
					bHandled = Next(,, Arg == class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
				break;
			case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
				if( HorizontalNavigation )
					bHandled = Prev(,, Arg == class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
				break;
			case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
			case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
				if( HorizontalNavigation )
					bHandled = Next(,, Arg == class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
				break;
		}

	}
	if (!bHandled)
	{
		Selected = GetSelected();
		if (Selected != none)
		{
			bHandled = Selected.OnUnrealCommand(cmd, arg);
			if (!bHandled)
			{
				bHandled = Selected.Navigator.OnUnrealCommand(cmd, arg);
			}
		}
	}
	else
	{
		`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
	}

	return bHandled;
}

simulated function bool SendToNavigationTargets( int Cmd, int Arg )
{
	local bool bHandled; 
	local UINavTarget Target; 
	local UIPanel Selected;

	bHandled = false; 
	Selected = GetSelected();	

	if (Selected != None && Selected.Navigator != none && Selected.Navigator.SendToNavigationTargets( Cmd, Arg ) )
	{
		return true; 
	}
	else
	{
		foreach NavigationTargets(Target)
		{
			if( Target.Cmd == Cmd && Target.Arg == Arg )
			{
				bHandled = true; 
				if( Target.Control != None )
				{
					OnLoseFocus();
					Target.Control.SetSelectedNavigation();
					if (Target.Control.Navigator.GetSelected() == None)
					{
						OnLoseFocus();
						Target.Control.ParentPanel.Navigator.SetSelected(Target.Control);
						if(Target.Control.ParentPanel.Navigator.OnSelectedIndexChanged != none)
							Target.Control.ParentPanel.Navigator.OnSelectedIndexChanged(Target.Control.ParentPanel.Navigator.SelectedIndex);
					}
				}
			}
		}
	}
	return bHandled; 
}
simulated function ClearAllNavigationTargets()
{
	NavigationTargets.Length = 0;
}

// Multiple panels may request the same command call; this will clear all for the specified cmd. 
simulated function RemoveNavTargetByCmd(int Cmd)
{
	local int i;
	local UINavTarget Target;

	for( i = NavigationTargets.length - 1; i > -1; i-- )
	{
		Target = NavigationTargets[i];
		if( Target.Cmd == Cmd )
			NavigationTargets.Remove(i, 1);
	}
}
simulated function RemoveNavTargetByControl(UIPanel Control)
{
	local int i;
	local UINavTarget Target;

	for( i = NavigationTargets.length - 1; i > -1; i-- )
	{
		Target = NavigationTargets[i];
		if( Target.Control == Control)
			NavigationTargets.Remove(i, 1);
	}
}

// Multiple panels may request the same command call; an invalic Control is also legit for consuming that command. 
simulated function AddNavTarget( UIPanel Control, int Cmd, int Arg )
{
	local UINavTarget Target;

	Target.Control = Control;
	Target.Cmd = Cmd; 
	Target.Arg = Arg; 

	if( Target.Control != None && !Target.Control.bIsNavigable )
		`RedScreen("Potential UI navigation error! Adding '" $Control.MCName $"' as a nav Target, but this Control is not marked bIsNavigable. Navigation to this Control will fail.",,'uixcom'); 

	NavigationTargets.AddItem(Target); 
}
simulated function AddNavTargetRight( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);

	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
}
simulated function AddNavTargetLeft( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);

	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
}
simulated function AddNavTargetUp( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_UP, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_UP, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);

	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_UP, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_UP, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
}
simulated function AddNavTargetDown( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);

	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_ARROW_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_DPAD_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT);
}

simulated function AddNavTargetDiagUpRight( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_UP_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
}
simulated function AddNavTargetDiagDownRight( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_DOWN_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
}
simulated function AddNavTargetDiagDownLeft( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_DOWN_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
}
simulated function AddNavTargetDiagUpLeft( UIPanel Control )
{
	AddNavTarget(Control, class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_UP_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
}
simulated function RemoveNavTargetRight()
{
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_ARROW_RIGHT);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_DPAD_RIGHT);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT);
}

simulated function RemoveNavTargetLeft()
{
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_ARROW_LEFT);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_DPAD_LEFT);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT);
}

simulated function RemoveNavTargetUp()
{
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_ARROW_UP);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_DPAD_UP);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP);
}

simulated function RemoveNavTargetDown()
{
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_ARROW_DOWN);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_DPAD_DOWN);
	RemoveNavTargetByCmd(class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN);
}
public function string PrintTabs(int NumTabs)
{
	local string Tabs;
	local int i;
	for (i = 0; i < NumTabs; i++)
		Tabs = Tabs$"  ";
	return Tabs;
}

public function PrintTree(optional int NumTabs=0, optional bool IsSelectedIndex=false)
{
	local int i;
	local string descriptor;
	local string joinedItems;
	local UIButton button;
	local UIDropdown dropdown;

	if (NumTabs == 0)
		`log("");

	button = UIButton(self.OwnerControl);
	dropdown = UIDropdown(self.OwnerControl);
	if (button != none)
	{
		descriptor = button.Text;
	}
	else if (dropdown != none)
	{
		JoinArray(dropdown.Items, joinedItems, ", ");
		descriptor = dropdown.Label$":" @ joinedItems;
	}

	`log(PrintTabs(NumTabs)$self.OwnerControl @ self.OwnerControl.MCName @ "("$descriptor$")"@ (IsSelectedIndex ? "<<< SELECTED" : "") @ (self.OwnerControl.bIsFocused ? "<<< FOCUSED" : ""));
	for (i = 0; i < NavigableControls.length; i++)
		NavigableControls[i].Navigator.PrintTree(NumTabs+1, i == SelectedIndex);
}
// This assumes the calling control is the left target, and constructs mutual nav to the target control 
simulated function AddHorizontalNavTarget(UIPanel TargetControl)
{
	AddNavTargetRight(TargetControl);
	TargetControl.Navigator.AddNavTargetLeft(OwnerControl);
}

// This assumes the calling control is the top target, and constructs mutual nav to the target control 
simulated function AddVerticalNavTarget(UIPanel TargetControl)
{
	AddNavTargetDown(TargetControl);
	TargetControl.Navigator.AddNavTargetUp(OwnerControl);
}

// FALSE means we've lost focus.
// TRUE means we've handled this internally.

public function bool Next(optional bool ReturningFromChild = false, optional bool bNewFocus = false, optional bool IsRepeat = false)
{
	local bool HandledByChild; 
	local bool HandledByOwner;
	local int PrevSelectedIndex;
	local UIPanel NavigableControl;
	local UIPanel SelectedControl;
	local int ChildIndex;

	//Allow for the  owner to interrupt
	if( CheckForOwnerHandling != None )
	{
		if( CheckForOwnerHandling(true) ) return true;
	}

	if(Size == 0)
		return false;
	ChildIndex = -1;

	// If our Control was unfocused, then we need to force the direction that we are entering from,
	// because we're in Next() so we know what the selection will need to be. 
	if( !OwnerControl.IsSelectedNavigation() )
		SelectedIndex = -1;

	// See if children of our NavigableControls want to control handle this command,
	// but only if this request hasn't come cascading upwards from a child already. 
	if(!ReturningFromChild)
	{
		SelectedControl = GetSelected();

		if(SelectedControl != none)
		{
			HandledByChild = SelectedControl.Navigator.Next(,, IsRepeat);
		}
		else
		{
			foreach NavigableControls(NavigableControl)
			{
				if(NavigableControl.Navigator.Next(,, IsRepeat))
				{
					HandledByChild = true;
					break;
				}
			}
		}
	}

	if(HandledByChild)
	{
		if(SelectedIndex < 0)
		{
			SelectedIndex = ChildIndex;
			SelectedControl = GetSelected();
			if(SelectedControl != none)
				SelectedControl.OnReceiveFocus();
		}
		return true;
	}
	else
	{
		ChildIndex = -1;
		//Do we need to LoopSelection? 
		PrevSelectedIndex = SelectedIndex++;
		if(SelectedIndex >= Size)
		{
			if(LoopSelection || (LoopOnReceiveFocus && bNewFocus))
			{
				//no loop when holding down
				if (IsRepeat && !bNewFocus) //Added !bNewFocus condition - BET 2016-04-14
				{
					SelectedIndex--;
					return true;
				}
				SelectedIndex = 0;
			}
			else
			{
				// We've hit an end cap of our local Control's items, so we need to report upwards to go to the next item if possible. 
				if( OwnerControl.ParentPanel != none && OwnerControl.Navigator.Size >= 1 && !bNewFocus)

					HandledByOwner = OwnerControl.ParentPanel.Navigator.Next(true,, IsRepeat);


				// Set to out of range endcap values, so we can see which way we left this object for debugging purposes. 
				if( HandledByOwner )
					SelectedIndex = Size;
				else
					SelectedIndex--;
			}
		}
		if(ReturningFromChild && size == 1 && OwnerControl.ParentPanel.Navigator.Size == 1)
		{
			return true;
		}

		// Always lose focus on the previously selected element, in case the Control UIPanel is losing focus 
		if( IsValid(PrevSelectedIndex) && SelectedIndex != PrevSelectedIndex && NavigableControls[PrevSelectedIndex].bIsFocused)
			NavigableControls[PrevSelectedIndex].OnLoseFocus();

		if(SelectedIndex != PrevSelectedIndex)
		{
			// Pass down recursively to any children for notification
			// ORDER MATTERS: must call Next() before OnReceiveFocus() to successfully see which way we are entering 
			// a previously unfocused object and set the correct SelectedIndex accordingly. 
			SelectedControl = GetSelected();
			if(SelectedControl != none  && OwnerControl.Navigator.Size > 1 )
			{
				SelectedControl.Navigator.Next(ReturningFromChild, true, IsRepeat);
				SelectedControl.OnReceiveFocus();
			}

			if(OnSelectedIndexChanged != none)
				OnSelectedIndexChanged(SelectedIndex);
			return true;
		}
	}

	// If we went in to an area where the Control handled our upward-cascade request, then report successful handling internally. 
	return HandledByOwner;
}

// FALSE means we've lost focus.
// TRUE means we've handled this internally.
public function bool Prev( optional bool ReturningFromChild = false, optional bool bNewFocus = false, optional bool IsRepeat = false)
{
	local bool HandledByChild; 
	local bool HandledByOwner;
	local int PrevSelectedIndex;
	local UIPanel NavigableControl;
	local UIPanel SelectedControl;
	local int ChildIndex;

	//Allow for the  owner to interrupt
	if( CheckForOwnerHandling != None )
	{
		if( CheckForOwnerHandling(false) ) return true;
	}

	if(Size == 0)
		return false;
	ChildIndex = -1;

	// If our Control was unfocused, then we need to force the direction that we are entering from, 
	// because we're in Prev() so we know what the selection will need to be. 
	if( !OwnerControl.IsSelectedNavigation() )
		SelectedIndex = Size;

	// See if children of our NavigableControls want to control handle this command,
	// but only if this request hasn't come cascading upwards from a child already. 
	if(!ReturningFromChild)
	{
		SelectedControl = GetSelected();
		if(SelectedControl != none)
		{

			HandledByChild = SelectedControl.Navigator.Prev(,, IsRepeat);
		}
		else
		{
			foreach NavigableControls(NavigableControl)
			{
				ChildIndex++;
				if(NavigableControl.Navigator.Prev(,, IsRepeat))
				{
					HandledByChild = true;
					break;
				}
			}
		}
	}

	if(HandledByChild)
	{
		if(SelectedIndex < 0)
		{
			SelectedIndex = ChildIndex;
			SelectedControl = GetSelected();
			if(SelectedControl != none)
				SelectedControl.OnReceiveFocus();
		}
		return true;
	}
	else
	{
		ChildIndex = -1;
		//Do we need to LoopSelection? 
		PrevSelectedIndex = SelectedIndex--;
		if(SelectedIndex < 0)
		{
			if(LoopSelection || (LoopOnReceiveFocus && bNewFocus))
			{
				//no loop when holding down
				if (IsRepeat && !bNewFocus) //Added !bNewFocus condition - BET 2016-04-14
				{
					SelectedIndex++;
					return true;
				}
				SelectedIndex = Size - 1;
			}
			else
			{
				// We've hit an end cap of our local Control's items, so we need to report upwards to go to the next item if possible. 
				if( OwnerControl.ParentPanel != none && OwnerControl.Navigator.Size >= 1 && !bNewFocus)
					HandledByOwner = OwnerControl.ParentPanel.Navigator.Prev(true,, IsRepeat);

				// Set to out of range endcap values, so we can see which way we left this object for debugging purposes. 
				if( HandledByOwner )
					SelectedIndex = -1; 
				else
					SelectedIndex++;
			}
		}
		if(ReturningFromChild && size == 1 && OwnerControl.ParentPanel.Navigator.Size == 1)
		{
			return true;
		}

		// Always lose focus on the previously selected element, in case the Control UIPanel is losing focus 
		if( IsValid(PrevSelectedIndex) && SelectedIndex != PrevSelectedIndex && NavigableControls[PrevSelectedIndex].bIsFocused )
			GetControl(PrevSelectedIndex).OnLoseFocus();

		if(SelectedIndex != PrevSelectedIndex)
		{
			// Pass down recursively to any children for notification
			// ORDER MATTERS: must call Prev() before OnReceiveFocus() to successfully see which way we are entering 
			// a previously unfocused object and set the correct SelectedIndex accordingly. 
			SelectedControl = GetSelected();
			if(SelectedControl != none)
			{
				SelectedControl.Navigator.Prev(ReturningFromChild, true, IsRepeat);
				SelectedControl.OnReceiveFocus();
			}

			if(OnSelectedIndexChanged != none)
				OnSelectedIndexChanged(SelectedIndex);

			return true;
		}
	}

	// If we went in to an area where the Control handled our upward-cascade request, then report successful handling internally.
	return HandledByOwner;
}

public function UIPanel GetControl(int Index)
{
	if( IsValid(Index) )
		return NavigableControls[Index];
	return none;
}

public function UIPanel GetSelected()
{
	if( IsValid(SelectedIndex) )
		return NavigableControls[SelectedIndex];
	//<workshop> SAFEGUARD_TO_PREVENT_FOCUS_LOSS - JTA 2016/2/22  /  WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
	//INS:
	//Triggers if a UIList has a valid SelectedIndex, but its Navigator has an invalid (and different) SelectedIndex
	//***This is a workaround for focus issues that manifested after the Feb2016 integration***
	if( UIList(OwnerControl) != None && UIList(OwnerControl).SelectedIndex >= 0 && IsValid(UIList(OwnerControl).SelectedIndex) )
	{
		if(!UIList(OwnerControl).bPermitNavigatorToDefocus) //Compound hack, explicitly call out places where this was correct behavior -bet
		{
			SelectedIndex = UIList(OwnerControl).SelectedIndex;
			return NavigableControls[SelectedIndex];
		}
	}
	return none;
}

simulated function bool IsValid(int Index)
{
	return( Index < NavigableControls.length && Index > -1 ); 
}

public function int GetIndexOf(UIPanel Control)
{
	return NavigableControls.Find(Control);
}

public function SetSelected( optional UIPanel SelectedControl = none )
{ 
	local int Index; 

	SelectedIndex = -1;
	if( SelectedControl != none )
	{
		Index = GetIndexOf(SelectedControl);
		if( IsValid(Index) )
		{
			SelectedIndex = Index;
			NavigableControls[Index].OnReceiveFocus();
		}
	}
}

public function ClearSelectionHierarchy()
{
	local int i;

	SelectedIndex = -1;
	OnLoseFocus();
	for( i = 0; i < NavigableControls.length; i++ )
	{
		NavigableControls[i].Navigator.ClearSelectionHierarchy();
	}
}

public function bool SelectFirstAvailableIfNoCurrentSelection()
{
	local bool bHandledByChild;

	if( !IsValid(SelectedIndex) && NavigableControls.length > 0 )
	{
		//Walk down the chain to the bottom, trigger selection, then SetSelected will bubble back up.
		bHandledByChild = NavigableControls[0].Navigator.SelectFirstAvailableIfNoCurrentSelection();

		if( !bHandledByChild )
		{
			SetSelected(NavigableControls[0]);

			if( OnSelectedIndexChanged != none )
				OnSelectedIndexChanged(SelectedIndex);
		}
		else
		{
			//the appropriate item has been handled by a child, let's 
			//just ensure that the parent has the child selected as well.
			if(SelectedIndex < 0)
				SelectedIndex = 0;
		}
		return true; 
	}
	else
	{
		//Nothing available to select, so return false. 
		return false;
	}
}

public function bool SelectFirstAvailable()
{
	local bool bHandledByChild; 

	if( NavigableControls.length > 0 )
	{
		//Walk down the chain to the bottom, trigger selection, then SetSelected will bubble back up.
		bHandledByChild = NavigableControls[0].Navigator.SelectFirstAvailable();

		if( !bHandledByChild )
		{
			SetSelected(NavigableControls[0]);

			if( OnSelectedIndexChanged != none )
				OnSelectedIndexChanged(SelectedIndex);
		}
		else
		{
			SelectedIndex = 0;
		}
		return true; 
	}
	else
	{
		//Nothing available to select, so return false. 
		return false;
	}
}

simulated function OnLoseFocus()
{
	local UIPanel SelectedControl; 

	// Note that this walks from self on up the chain. 
	SelectedControl = GetSelected();
	if( SelectedControl != none ) 
		SelectedControl.OnLoseFocus();

	if( OwnerControl.ParentPanel != none )
		OwnerControl.ParentPanel.Navigator.OnLoseFocus();
}
simulated function OnReceiveFocus()
{
	local UIPanel SelectedControl; 

	// Note that this walks from self on up the chain. 
	SelectedControl = GetSelected();

	if( OwnerControl.ParentPanel != none )
		OwnerControl.ParentPanel.Navigator.OnReceiveFocus();

	if( SelectedControl != none ) 
		SelectedControl.OnReceiveFocus();
}

simulated function Clear()
{
	local UIPanel Selected;

	if(Size > 0)
	{
		Selected = GetSelected();
		if (Selected != none)
			Selected.OnLoseFocus();
		Size = 0;
		NavigableControls.Length = 0;
	}
}
simulated function PrintDebug(optional bool bCascade = false, optional string Indentation = "")
{
	local int i;
	local UIPanel SelectedControl, Target; 

	if( Indentation == "" )
	{
		`log(Indentation$"-------------" @OwnerControl.MCName @ "{"$ OwnerControl.Name $"}" @ " Navigator.PrintDebug ---------------*", , 'uixcom' );
	}

	if( NavigationTargets.Length == 0 && NavigableControls.length == 0 )
	{
		if( !OwnerControl.IsSelectedNavigation() )
		{
			`log(Indentation $"||"@ OwnerControl.MCName @ "{"$ OwnerControl.Name $"}", , 'uixcom' );
		}
		return;
	}

	SelectedControl = GetSelected(); 

	//Nav Targets
	if( NavigationTargets.Length > 0 )
		`log(Indentation$"-- NavigationTargets -------------", , 'uixcom' );

	for( i = 0; i < NavigationTargets.length; i++ )
	{
		if( NavigationTargets[i].Control == none )
			`log(Indentation$"|| NONE {none}" @ NavigationTargets[i].Cmd, , 'uixcom' );
		else if( NavigationTargets[i].Control == SelectedControl )
			`log(Indentation$">>" @ NavigationTargets[i].Control.MCName@ "{"$ NavigationTargets[i].Control.Name $"}" @ NavigationTargets[i].Cmd, , 'uixcom' );
		else
			`log(Indentation$"||" @ NavigationTargets[i].Control.MCName @ "{"$ NavigationTargets[i].Control.Name $"}" @ NavigationTargets[i].Cmd, , 'uixcom' );

		// Can't cascade NavTargets: you end up with an infinite loop if you have items that link to each other. 
	}

	//NavigableControls, only a header if we need to differentiate from targets. 
	if( NavigationTargets.Length > 0 && NavigableControls.Length > 0 && NavigableControls.Length > 0 )
		`log(Indentation$"== NavigableControls ==============", , 'uixcom' );

	for( i = 0; i < NavigableControls.length; i++ )
	{
		Target = NavigableControls[i];
		if( Target == SelectedControl )
		{
			`log(Indentation$">>" @ Target.MCName @ "{"$ Target.Name $"}", , 'uixcom' );
		}
		else
		{
			`log(Indentation$"||" @ Target.MCName @ "{"$ Target.Name $"}", , 'uixcom' );
		}

		if( bCascade )
		{
			if( Target.Navigator.NavigationTargets.Length == 0 && Target.Navigator.NavigableControls.length == 0 )
			{
				// Do nothing 
			}
			else
			{
				Target.PrintNavigator((Indentation$"|| "));
			}
		}
	}
}


DefaultProperties
{
	SelectedIndex = -1;
	LoopSelection = false;
	LoopOnReceiveFocus = false;
	HorizontalNavigation = false;
}
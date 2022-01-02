//---------------------------------------------------------------------------------------
//  FILE:    UICharacterPool_ListPools.uc
//  AUTHOR:  Brit Steiner --  9/4/2014
//  PURPOSE: ListPools menu in the character pool system. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICharacterPool_ListPools extends UIScreen
	dependson(CharacterPoolManager);

//----------------------------------------------------------------------------
// MEMBERS

// UI
var UIPanel	Container;
var UIBGBox    BG;
var UIList		List;
var UIButton	AcceptButton;
var UIX2PanelHeader TitleHeader;
var UINavigationHelp NavHelp;

//Default (active) pool
var CharacterPoolManager CharacterPoolMgr;

//Passed in by UICharacterPool if we're exporting
var public array<XComGameState_Unit> UnitsToExport;

var array<string> Data; 
var bool bIsExporting;
var bool bHasSelectedImportLocation;

var localized public string m_strTitle;
var localized public string m_strTitleImportPoolLocation;
var localized public string m_strExportSubtitle;
var localized public string m_strImportSubtitle;
var localized public string m_strCreateNewPool;
var localized public string m_strTitleImportPoolCharacter;
var localized public string m_strImportAll;

var localized string m_strExportSuccessDialogueTitle;
var localized string m_strExportSuccessDialogueBody;

var localized string m_strExportConfirmDialogueTitle;
var localized string m_strExportConfirmDialogueBody;
var localized string m_strExportConfirmDialogueMultipleUnits;

var localized string m_strExportManySuccessDialogueTitle;
var localized string m_strExportManySuccessDialogueBody;

var localized string m_strDeletePoolDialogueTitle;
var localized string m_strDeletePoolDialogueBody;

var localized string m_strNewPoolFailedExtantTitle;
var localized string m_strNewPoolFailedExtantBody;
var localized string m_strNewPoolFailedBadFilenameTitle;
var localized string m_strNewPoolFailedBadFilenameBody;

var localized string m_strNewPoolSuccessTitle;
var localized string m_strNewPoolSuccessBody;

var array<string> EnumeratedFilenames; //Filenames found which contain importable character pools
var string SelectedFilename; //Filename selected by the user for import, if any
var string SelectedFriendlyName;

var int PoolToBeDeleted;

var array<CharacterPoolManager> ImportablePoolsLoaded; //Memory-resident pools that the user has browsed

delegate OnItemSelectedCallback(UIList _list, int itemIndex);

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	// ---------------------------------------------------------

	// Create Container
	Container = Spawn(class'UIPanel', self).InitPanel('').SetPosition(30, 110).SetSize(600, 800);

	// Create BG
	BG = Spawn(class'UIBGBox', Container).InitBG('', 0, 0, Container.width, Container.height);
	BG.SetAlpha(80);

	// Create Title text
	TitleHeader = Spawn(class'UIX2PanelHeader', Container);
	TitleHeader.InitPanelHeader('', m_strTitleImportPoolLocation, m_strImportSubtitle);
	TitleHeader.SetHeaderWidth(Container.width - 20);
	TitleHeader.SetPosition(10, 10);

	List = Spawn(class'UIList', Container);
	List.bAnimateOnInit = false;
	List.InitList('', 10, TitleHeader.height, TitleHeader.headerWidth - 20, Container.height - TitleHeader.height - 10);
	List.Navigator.LoopSelection = true;
	List.OnSelectionChanged = ItemChanged;
	
	BG.ProcessMouseEvents(List.OnChildMouseEvent);

	// ---------------------------------------------------------

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddBackButton(OnCancel);
		
	// ---------------------------------------------------------

	CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
}
simulated function OnInit()
{	
	super.OnInit();

	UpdateGamepadFocus();
}

simulated function UpdateGamepadFocus()
{
	if( `ISCONTROLLERACTIVE == false ) return;

	if(List.ItemCount > 0)
	{
		List.SetSelectedIndex(0);
		Navigator.SetSelected(List);
	}

	UpdateNavHelp();
}

simulated function ItemChanged(UIList ContainerList, int ItemIndex)
{
	UpdateNavHelp();
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();

	NavHelp.AddBackButton(OnCancel);

	//Toggle selection is constant
	if(List.ItemCount > 0)
		NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericSelect, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());

	if (`ISCONTROLLERACTIVE)
	{
		if(!bHasSelectedImportLocation || List.SelectedIndex > 0)
			NavHelp.AddLeftHelp(class'UISaveLoadGameListItem'.default.m_sDeleteLabel, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateGamepadFocus();
}


simulated function UpdateData( bool _bIsExporting )
{
	bIsExporting = _bIsExporting; 

	if( bIsExporting )
	{
		TitleHeader.SetText(m_strTitle, m_strExportSubtitle);
		Data = GetExportList(); 
	}
	else
	{
		if( bHasSelectedImportLocation )
		{
			TitleHeader.SetText(m_strTitleImportPoolCharacter, SelectedFriendlyName);
			Data = GetImportList();
		}
		else
		{
			TitleHeader.SetText(m_strTitleImportPoolLocation, m_strImportSubtitle);
			Data = GetImportLocationList();
		}
	}

	List.OnItemClicked = OnClickLocal;
	
	UpdateDisplay();
}

simulated function UpdateDisplay()
{
	local UIMechaListItem SpawnedItem;
	local int i;

	if(List.itemCount > Data.length)
		List.ClearItems();

	while (List.itemCount < Data.length)
	{
		SpawnedItem = Spawn(class'UIMechaListItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
	}
	
	for( i = 0; i < Data.Length; i++ )
	{
		if(bHasSelectedImportLocation || (bIsExporting && i == 0) || `ISCONTROLLERACTIVE)
			UIMechaListItem(List.GetItem(i)).UpdateDataValue(Data[i], "");
		else
			UIMechaListItem(List.GetItem(i)).UpdateDataButton(Data[i], class'UISaveLoadGameListItem'.default.m_sDeleteLabel, OnDeletePool);
	}
}

simulated function DeleteCurrentlySelectedPool()
{
	PoolToBeDeleted = List.SelectedIndex;
	
	if (bHasSelectedImportLocation)
	{
		if (PoolToBeDeleted > 0)
		{
			OnConfirmDeleteCharacter();
		}
	}
	else
	{
		if (PoolToBeDeleted != INDEX_NONE)
			OnConfirmDeletePool();
	}
}

simulated function OnDeletePool(UIButton Button)
{
	local int Index;

	Index = List.GetItemIndex(Button);
	PoolToBeDeleted = Index;

	if(Index != INDEX_NONE)
		OnConfirmDeletePool();
}

simulated function OnConfirmDeleteCharacter()
{
	local XGParamTag        kTag;
	local TDialogueBoxData  DialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = Data[PoolToBeDeleted];
	
	DialogData.strTitle	   = class'UICharacterPool'.default.m_strDeleteCharacterDialogueTitle;
	DialogData.strText     = `XEXPAND.ExpandString(m_strDeletePoolDialogueBody); 
	DialogData.fnCallback  = OnConfirmDeletePoolCallback;

	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function OnConfirmDeletePool()
{
	local XGParamTag        kTag;
	local TDialogueBoxData  DialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = Data[PoolToBeDeleted];

	DialogData.strTitle = m_strDeletePoolDialogueTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strDeletePoolDialogueBody);
	DialogData.fnCallback = OnConfirmDeletePoolCallback;

	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated public function OnConfirmDeletePoolCallback(Name eAction)
{
	local CharacterPoolManager PoolToDelete;

	if( eAction == 'eUIAction_Accept' )
	{
		PoolToDelete = new class'CharacterPoolManager';
		PoolToDelete.PoolFileName = EnumeratedFilenames[PoolToBeDeleted - (bIsExporting ? 1 : 0)]; // -1 to account for new pool button
		PoolToDelete.DeleteCharacterPool();
		UpdateData(bIsExporting);
	}
}

//------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
			if(!bHasSelectedImportLocation || List.SelectedIndex > 0)
				DeleteCurrentlySelectedPool();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//------------------------------------------------------

simulated function OnAccept()
{

	if( `ISCONTROLLERACTIVE )
		OnClickLocal(List, List.SelectedIndex);
	//OnButtonCallback(AcceptButton);

	UpdateNavHelp();
}

simulated function OnCancel()
{
	if( !bIsExporting && bHasSelectedImportLocation )
	{
		//Return back to select location
		bHasSelectedImportLocation = false; 
		// Then, refresh this screen:
		UpdateData( false );
		if( `ISCONTROLLERACTIVE )
			UpdateGamepadFocus();
	}
	else
	{
		ImportablePoolsLoaded.Length = 0; //Dump any characters not in the main pool by now
		Movie.Stack.Pop(self);
	}
}

simulated function OnClickLocal(UIList _list, int iItemIndex)
{
	if( bIsExporting )
	{
		if( iItemIndex == 0) //Request to create a new pool 
		{
			// We want a new pool
			OpenNewExportPoolInputBox();
		}
		else
		{
			//TODO @nway: notify the game of the export pool: iItemIndex-1 
			SelectedFilename = EnumeratedFilenames[iItemIndex-1];
			SelectedFriendlyName = Data[iItemIndex];
			// TODO: Confirm export
			`log("EXPORT location selected: " $string(iItemIndex-1) $ ":" $ SelectedFilename);
			OnExportCharacters();
		}
	}
	else
	{
		if( !bHasSelectedImportLocation )
		{
			// We just picked the import location
			bHasSelectedImportLocation = true; 
			SelectedFilename = EnumeratedFilenames[iItemIndex];
			SelectedFriendlyName = Data[iItemIndex];
			`log("IMPORT location selected: " $string(iItemIndex) $ ":" $ SelectedFilename);
			// Then, refresh this screen:
			UpdateData( false );
		}
		else
		{
			`log("IMPORT character selected: " $string(iItemIndex));

			if (iItemIndex == 0) //"all" case
				DoImportAllCharacters(SelectedFilename);
			else
				DoImportCharacter(SelectedFilename, iItemIndex-1);

			bHasSelectedImportLocation = false;  // This will allow us to exit the screen 
			OnCancel();
		}
	}
}

simulated function OnExportCharacters()
{
	local XGParamTag        kTag;
	local TDialogueBoxData  DialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	if(UnitsToExport.Length == 1)
	{
		kTag.StrValue0 = UnitsToExport[0].GetName(eNameType_Full);
	}
	else
	{
		kTag.IntValue0 = UnitsToExport.Length;
		kTag.StrValue0 = `XEXPAND.ExpandString(m_strExportConfirmDialogueMultipleUnits);
	}
	
	DialogData.strTitle	   = m_strExportConfirmDialogueTitle;
	DialogData.strText     = `XEXPAND.ExpandString(m_strExportConfirmDialogueBody); 
	DialogData.fnCallback  = OnExportCharactersCallback;

	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated public function OnExportCharactersCallback(Name eAction)
{
	if( eAction == 'eUIAction_Accept' )
	{
		DoExportCharacters(SelectedFilename);
		OnCancel();
	}
}

simulated function array<string> GetExportList()
{
	local array<string> FriendlyNames;

	//The first item should be "create new pool", followed by all existing pools
	FriendlyNames.Length = 0;
	FriendlyNames.AddItem(m_strCreateNewPool);

	//Re-enumerate pool files
	EnumeratedFilenames.Length = 0;
	class'CharacterPoolManager'.static.EnumerateImportablePools(FriendlyNames, EnumeratedFilenames);

	return FriendlyNames;
}

simulated function array<string> GetImportLocationList()
{
	local array<string> FriendlyNames; 

	//Re-enumerate pool files
	FriendlyNames.Length = 0;
	EnumeratedFilenames.Length = 0;
	class'CharacterPoolManager'.static.EnumerateImportablePools(FriendlyNames, EnumeratedFilenames);

	return FriendlyNames;
}

simulated function array<string> GetImportList()
{
	local array<string> Items; 
	local CharacterPoolManager SelectedPool;
	local bool PoolAlreadyLoaded;
	local XComGameState_Unit PoolUnit;

	//Top item should let user grab all characters from the pool
	Items.AddItem(m_strImportAll);

	//Check if we've already deserialized the desired pool
	PoolAlreadyLoaded = false;
	foreach ImportablePoolsLoaded(SelectedPool)
	{
		if (SelectedPool.PoolFileName == SelectedFilename)
		{
			PoolAlreadyLoaded = true;
			break;
		}
	}

	//Instantiate a new pool with data from the file, if we haven't already
	if (!PoolAlreadyLoaded)
	{
		SelectedPool = new class'CharacterPoolManager';
		SelectedPool.PoolFileName = SelectedFilename;
		SelectedPool.LoadCharacterPool();
		ImportablePoolsLoaded.AddItem(SelectedPool);
	}

	foreach SelectedPool.CharacterPool(PoolUnit)
	{
		if (PoolUnit.GetNickName() != "")
			Items.AddItem(PoolUnit.GetFirstName() @ PoolUnit.GetNickName() @ PoolUnit.GetLastName());
		else
			Items.AddItem(PoolUnit.GetFirstName() @ PoolUnit.GetLastName());		
	}

	//If we didn't actually have valid characters to import, don't even show the "all" option
	if (Items.Length == 1)
		Items.Length = 0;

	return Items; 
}


simulated function OpenNewExportPoolInputBox()
{
	local TInputDialogData kData;

//	if( !`GAMECORE.WorldInfo.IsConsoleBuild() || `ISCONTROLLERACTIVE )
//	{
		kData.strTitle = m_strCreateNewPool $":";
		kData.iMaxChars = 32; //TODO: @nway: what is the actual max on these names? 
		kData.strInputBoxText = "";
		kData.fnCallback = OnNewExportPoolInputBoxClosed;

		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		XComPresentationLayerBase(Outer).UIKeyboard(m_strCreateNewPool $":",
													"",
													VirtualKeyboard_OnNewExportPoolInputBoxAccepted,
													VirtualKeyboard_OnNewExportPoolInputBoxCancelled,
													false,
													32
		);
	}*/
}

// TEXT INPUT BOX (PC)
function OnNewExportPoolInputBoxClosed(string text)
{
	local TDialogueBoxData kDialogData;
	if (text != "")
	{
		`log("Player wants a new pool named '" $text $"'.");

		//Sanitize the filename that the user entered
		text = class'UIUtilities'.static.SanitizeFilenameFromUserInput(text);

		//The filename might have been totally sanitized away
		if (text == "")
		{
			kDialogData.eType = eDialog_Normal;
			kDialogData.strTitle = m_strNewPoolFailedBadFilenameTitle;
			kDialogData.strText = m_strNewPoolFailedBadFilenameBody;
			kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;
			Movie.Pres.UIRaiseDialog(kDialogData);
			return;
		}

		//The pool might already exist
		if (!DoMakeEmptyPool(text))
		{
			kDialogData.eType = eDialog_Normal;
			kDialogData.strTitle = m_strNewPoolFailedExtantTitle;
			kDialogData.strText = m_strNewPoolFailedExtantBody;
			kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;
			Movie.Pres.UIRaiseDialog(kDialogData);
			return;
		}

		//Show a success dialog, letting them know that they still need to export their character to the new, empty pool
		kDialogData.eType = eDialog_Normal;
		kDialogData.strTitle = m_strNewPoolSuccessTitle;
		kDialogData.strText = m_strNewPoolSuccessBody;
		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;
		Movie.Pres.UIRaiseDialog(kDialogData);

		//Now that import pool list should be updated, we can call refresh to grab that new lit and repopulate the list.
		UpdateData(true);
	}
}

function VirtualKeyboard_OnNewExportPoolInputBoxAccepted(string text, bool bWasSuccessful)
{
	OnNewExportPoolInputBoxClosed(bWasSuccessful ? text : "");
}

function VirtualKeyboard_OnNewExportPoolInputBoxCancelled()
{
	OnNewExportPoolInputBoxClosed("");
}


simulated function DoImportCharacter(string FilenameForImport, int IndexOfCharacter)
{
	local CharacterPoolManager ImportPool;
	local XComGameState_Unit ImportUnit;

	//Find the character pool we want to import from
	foreach ImportablePoolsLoaded(ImportPool)
	{
		if (ImportPool.PoolFileName == FilenameForImport)
			break;
	}
	`assert(ImportPool.PoolFileName == FilenameForImport);

	//Grab the unit (we already know the index)
	ImportUnit = ImportPool.CharacterPool[IndexOfCharacter];

	//Put the unit in the default character pool
	if (ImportUnit != None)
		CharacterPoolMgr.CharacterPool.AddItem(ImportUnit);

	//Save the default character pool
	CharacterPoolMgr.SaveCharacterPool();

	`log("Imported character" @ FilenameForImport @ IndexOfCharacter @ ":" @ ImportUnit.GetFullName());
}

simulated function DoImportAllCharacters(string FilenameForImport)
{
	local CharacterPoolManager ImportPool;
	local XComGameState_Unit ImportUnit;

	if(ImportablePoolsLoaded.Length > 0)
	{
		//Find the character pool we want to import from
		foreach ImportablePoolsLoaded(ImportPool)
		{
			if(ImportPool.PoolFileName == FilenameForImport)
				break;
		}

		if(ImportPool == none)
		{
			ImportPool = ImportablePoolsLoaded[0];
		}
		`assert(ImportPool.PoolFileName == FilenameForImport);

		//Grab each unit and put it in the default pool
		foreach ImportPool.CharacterPool(ImportUnit)
		{
			if(ImportUnit != None)
				CharacterPoolMgr.CharacterPool.AddItem(ImportUnit);
		}

		//Save the default character pool
		CharacterPoolMgr.SaveCharacterPool();

		`log("Imported characters" @ FilenameForImport);
	}
}

simulated function DoExportCharacters(string FilenameForExport)
{
	local int i;
	local XComGameState_Unit ExportUnit;
	local CharacterPoolManager ExportPool;

	//Just to be sure we don't have stale data, kill all cached pools and re-open the one we want
	ImportablePoolsLoaded.Length = 0;
	ExportPool = new class'CharacterPoolManager';
	ExportPool.PoolFileName = FilenameForExport;
	ExportPool.LoadCharacterPool();

	//Copy out each character
	for (i = 0; i < UnitsToExport.Length; i++)
	{
		ExportUnit = UnitsToExport[i];

		if (ExportUnit != None)
			ExportPool.CharacterPool.AddItem(ExportUnit);

		`log("Exported character" @ ExportUnit.GetFullName() @ "to pool" @ FilenameForExport);
	}

	//Save it
	ExportPool.SaveCharacterPool();

	ExportSuccessDialogue();
}

simulated function ExportSuccessDialogue()
{
	local XGParamTag LocTag;
	local int i;
	local TDialogueBoxData kDialogData;

	if (UnitsToExport.Length <= 0)
		return;

	kDialogData.eType = eDialog_Normal;

	if( UnitsToExport.Length > 25 )
	{
		LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		LocTag.IntValue0 = UnitsToExport.Length; 

		kDialogData.strTitle = m_strExportManySuccessDialogueTitle;
		kDialogData.strText = `XEXPAND.ExpandString(m_strExportManySuccessDialogueBody);
	}
	else
	{
		kDialogData.strTitle = m_strExportSuccessDialogueTitle;
		kDialogData.strText = m_strExportSuccessDialogueBody;

		for (i = 0; i < UnitsToExport.Length; i++)
		{
			kDialogData.strText = kDialogData.strText $ "\n" $ UnitsToExport[i].GetFullName();
		}
	}

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

//Returns false if pool already exists
simulated function bool DoMakeEmptyPool(string NewFriendlyName)
{
	local CharacterPoolManager ExportPool;
	local string FullFileName;
	FullFileName = CharacterPoolMgr.ImportDirectoryName $ "\\" $ NewFriendlyName $ ".bin";

	if(EnumeratedFilenames.Find(FullFileName) != INDEX_NONE)
		return false;

	ExportPool = new class'CharacterPoolManager';
	ExportPool.PoolFileName = FullFileName;
	ExportPool.SaveCharacterPool();
	return true;
}

//==============================================================================

defaultproperties
{
	InputState      = eInputState_Evaluate;
	PoolToBeDeleted = INDEX_NONE;
	bIsNavigable	= true;
	bIsExporting	= false;
	bHasSelectedImportLocation = false; 
}

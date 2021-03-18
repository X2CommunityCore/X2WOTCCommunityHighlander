//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyPolicy.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Strategy card policy screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyPolicy extends UIScreen
	dependson(UIDialogueBox, UIStrategyPolicy_Card);

/// HL-Docs: feature:UIStrategyPolicy_MiscEvents; issue:986; tags:strategy,ui
/// `UIStrategyPolicy` is the screen that allows players to allocate
/// resistance orders at end of "month". The Community Highlander adds
/// the following events to that screen so mods have more options for
/// modifying it without overriding it entirely.
///
/// See the tracking issue for background on why these events were
/// added, and hence a potential use for them.
///
/// **Note** You'll need to look at the code for `UIStrategyPolicy` in
/// order to understand when these events are fired, and hence which
/// ones you'll need for your own customisations.
///
/// ```event
/// EventID: UIStrategyPolicy_PreRefreshAllDecks,
/// EventData: none,
/// EventSource: UIStrategyPolicy (StrategyPolicy),
/// NewGameState: none
/// ```
///
/// ```event
/// EventID: UIStrategyPolicy_PostRealizeColumn,
/// EventData: UIList (Column),
/// EventSource: UIStrategyPolicy (StrategyPolicy),
/// NewGameState: none
/// ```
///
/// ```event
/// EventID: UIStrategyPolicy_PreSelect,
/// EventData: UIStrategyPolicy_Card (TargetCard),
/// EventSource: UIStrategyPolicy (StrategyPolicy),
/// NewGameState: none
/// ```
///
/// ```event
/// EventID: UIStrategyPolicy_PreClearSelection,
/// EventData: none,
/// EventSource: UIStrategyPolicy (StrategyPolicy),
/// NewGameState: none
/// ```
///
/// ```event
/// EventID: UIStrategyPolicy_DraggingStarted,
/// EventData: none,
/// EventSource: UIStrategyPolicy (StrategyPolicy),
/// NewGameState: none
/// ```
///
/// ```event
/// EventID: UIStrategyPolicy_DraggingEnded,
/// EventData: none,
/// EventSource: UIStrategyPolicy (StrategyPolicy),
/// NewGameState: none
/// ```

var localized string DeckTitle;
var localized string WildCardColumnLabel;
var localized string UnknownFactionColumnLabel;
var localized string InfluenceLabel;
var localized string LockedSlotLabel;
var localized string WildCardSlotLabel;
var localized string m_strLeaveWithoutPlayingCardTitle;
var localized string m_strLeaveWithoutPlayingCardBody;
var localized string m_strLeaveWithoutPlayingCardStay;
var localized string m_strLeaveWithoutPlayingCardLeave;
var localized string m_strRemoveCard;
var localized string m_strChangeFilter; //bsg-jneal (5.31.17): support for changing filter tabs

var array<UIList> Columns;
var UIStrategyPolicy_DeckList Hand;
var UIPanel CardCatcher;
var UIPanel DeckCatcher;
var bool bDragging;
var bool bHighlightDeckRow;
var name FilterFaction;
var array<name> TabFactionNames;
var array<UIPanel> TabButtons;
var bool bEnableDragging;

var UIPanel DeckPageArrowNext;
var UIPanel DeckPageArrowPrev;

var int m_iCurrentFactionTab; //bsg-jneal (5.31.17): support for changing filter tabs

var bool bInstantInterp;
var bool bResistanceReport;
var UIStrategyPolicy_Card InspectingCard;
var UINavigationHelp NavHelp;

var array<name> ColumnNames;
var string CameraTag;

// bsg-nlong (2.6.17): indexes for tracking navigation and flags for looping navigation or not
var int m_iColumnIndex;
var int m_iSlotIndex;
var int m_iHandIndex;
var bool m_bSelectingHand;
var bool m_bLoopColumnSelection;
var bool m_bLoopSlotSelection;
var bool m_bLoopHandSelection;
// bsg-nlong (2.6.17): end

//==============================================================================
//==============================================================================

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local float InterpTime;

	InterpTime = `HQINTERPTIME;

	if (bInstantInterp)
	{
		InterpTime = 0.0;
	}

	super.InitScreen(InitController, InitMovie, InitName);
	`HQPRES.CAMLookAtNamedLocation(CameraTag, InterpTime);
	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();
	`HQPRES.StrategyMap2D.ClearDarkEvents();

	Navigator.HorizontalNavigation = true;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp; //bsg-jneal (5.31.17): use existing navhelp instead of spawning a new one

	UpdateNavHelp(); //bsg-crobinson (5.12.17): Update navhelp when screen is inited

	// Issue #440
	/// HL-Docs: feature:UIStrategyPolicy_ScreenInit; issue:440; tags:strategy,ui
	/// Triggers the event `UIStrategyPolicy_ScreenInit` immediately after opening the
	/// `UIStrategyPolicy` screen, before it has fully initialized. Can be used to make
	/// modifications to camera transition behavior that would be too late in a ScreenListener.
	///
	/// ```unrealscript
	/// ID: UIStrategyPolicy_ScreenInit,
	/// Source: UIStrategyPolicy
	/// ```
	`XEVENTMGR.TriggerEvent('UIStrategyPolicy_ScreenInit', , self);
}

simulated function OnInit()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;

	super.OnInit();

	InitializeDecks();
	InitializeStrategyData();
	RefreshAllDecks();

	MC.FunctionBool("SetResistanceReportMode", bResistanceReport);

	CardCatcher = Spawn(class'UIPanel', self);
	CardCatcher.InitPanel('CardCatcherBGMC');
	CardCatcher.ProcessMouseEvents(OnMouseEventCardCatcher);
	CardCatcher.bShouldPlayGenericUIAudioEvents = false;

	DeckCatcher = Spawn(class'UIPanel', self);
	DeckCatcher.InitPanel('DeckCatcherBGMC');
	DeckCatcher.ProcessMouseEvents(OnMouseEventDeckCatcher);
	DeckCatcher.bShouldPlayGenericUIAudioEvents = false;

	DeckPageArrowNext = Spawn(class'UIPanel', self);
	DeckPageArrowNext.InitPanel('DeckPageArrowNext');
	DeckPageArrowNext.Hide();

	DeckPageArrowPrev= Spawn(class'UIPanel', self);
	DeckPageArrowPrev.InitPanel('DeckPageArrowPrev');
	DeckPageArrowPrev.Hide();

	RefreshPageArrows();

	History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
	{
		// Display any new cards that have been received by meeting Factions
		// (Cards gained form increasing influencing should be displayed with that popup post-Covert Action)
		if( FactionState.bSeenFactionHQReveal )
		{
			FactionState.DisplayNewStrategyCardPopups();
		}
	}

	if( !class'UIUtilities_Strategy'.static.GetXComHQ().bHasSeenResistanceOrdersIntroPopup )
	{
		`HQPRES.UIResistanceOrdersIntro();
	}
	else
	{
		if( bIsFocused )
			UpdateNavHelp();
	}

	if( !bResistanceReport )
	{
		bEnableDragging = false;
		MC.FunctionVoid("DisableDragging");
	}

	// bsg-nlong (2.6.17): If using a controller we are going to manually handle navigation in this screen
	// Controller flow starts with the hand (if it has at least one card), player selects a card and then a slot to put it in
	// if the hand is initially empty, then we will start selecting the cards in factions
	if( `ISCONTROLLERACTIVE )
	{
		DisableNavigation();

		//bsg-jneal (5.31.17): default selection to the columns if no extra cards in hand
		if( Hand.GetItemCount() <= 0 )
		{
			m_bSelectingHand = false;
			HighlightDeckRow(false);
			SelectColumn(0); //bsg-nlong (2.6.17): Column 0, Card 0 is always selectable
		}
		//bsg-jneal (5.31.17): end
	}
	// bsg-nlong (2.6.17): end
}

//bsg-jneal (5.31.17): refresh card selection after new cards are initialized
function OnFirstHandItemInit(UIPanel Panel)
{
	SelectCardInDeck(m_iHandIndex);
}
//bsg-jneal (5.31.17): end

function InitializeDecks()
{
	local int idx;
	local UIList List;
	local array<name> FactionNames;
	local UIPanel Tab;

	ColumnNames.Length = 0;
	ColumnNames.AddItem('');

	FactionNames.AddItem('Faction_Reapers');
	FactionNames.AddItem('Faction_Skirmishers');
	FactionNames.AddItem('Faction_Templars');

	FactionNames.Sort(SortFactionNames);

	ColumnNames.AddItem(FactionNames[0]);
	ColumnNames.AddItem(FactionNames[1]);
	ColumnNames.AddItem(FactionNames[2]);

	Hand = spawn(class'UIStrategyPolicy_DeckList', self);
	Hand.InitList('DeckListMC');
	Hand.Navigator.HorizontalNavigation = true;
	Hand.LeftMaskOffset = -25;
	Hand.ItemWidthBuffer = 100;

	if( `ISCONTROLLERACTIVE )
	{
		Hand.DisableNavigation(); // bsg-nlong (2.6.17): Manually handling Navigation
	}

	for( idx = 0; idx < 4; idx++ )
	{
		List = spawn(class'UIList', self);
		List.InitList(Name("ActiveColumnList" $ idx));
		Columns.AddItem(List);
	}

	FilterFaction = '';
	m_iCurrentFactionTab = 0; //bsg-jneal (5.31.17): support for changing filter tabs
	MC.FunctionNum("HighlightPolicyTab", m_iCurrentFactionTab);

	Tab = Spawn(class'UIPanel', self);
	Tab.InitPanel('CardTab0');
	Tab.ProcessMouseEvents(ClickTab);
	TabButtons.AddItem(Tab);

	Tab = Spawn(class'UIPanel', self);
	Tab.InitPanel('CardTab1');
	Tab.ProcessMouseEvents(ClickTab);
	TabButtons.AddItem(Tab);

	Tab = Spawn(class'UIPanel', self);
	Tab.InitPanel('CardTab2');
	Tab.ProcessMouseEvents(ClickTab);
	TabButtons.AddItem(Tab);

	Tab = Spawn(class'UIPanel', self);
	Tab.InitPanel('CardTab3');
	Tab.ProcessMouseEvents(ClickTab);
	TabButtons.AddItem(Tab);
}

private function int SortFactionNames(name FactionNameA, name FactionNameB)
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState, FactionStateA, FactionStateB;
	local bool bFactionAMetFirst;

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
	{
		if( FactionState.GetMyTemplateName() == FactionNameA )
		{
			FactionStateA = FactionState;
		}
		else if( FactionState.GetMyTemplateName() == FactionNameB )
		{
			FactionStateB = FactionState;
		}
	}

	if( FactionStateA == none || FactionStateB == none )
	{
		return 0;
	}

	if( !FactionStateA.bSeenFactionHQReveal && !FactionStateB.bSeenFactionHQReveal )
	{
		return 0;
	}
	else if( FactionStateA.bSeenFactionHQReveal && !FactionStateB.bSeenFactionHQReveal )
	{
		return 1;
	}
	else if( !FactionStateA.bSeenFactionHQReveal && FactionStateB.bSeenFactionHQReveal )
	{
		return -1;
	}

	bFactionAMetFirst = class'X2StrategyGameRulesetDataStructures'.static.LessThan(FactionStateA.MetXComDate, FactionStateB.MetXComDate);

	if( bFactionAMetFirst )
	{
		return 1;
	}

	return -1;
}

function InitializeStrategyData()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResHQ;

	ResHQ = GetResistanceHQ();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Policy Screen Init");
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
	ResHQ.StoreOldCards(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function TriggerNarrativeEvents()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;

	History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Events: Faction Resistance Orders");

	foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
	{
		if( FactionState.GetInfluence() == eFactionInfluence_Respected )
		{
			// First slot is unlocked at respected (medium) influence
			`XEVENTMGR.TriggerEvent(FactionState.GetFirstOrderSlotEvent(), , , NewGameState);
		}
		else if( FactionState.GetInfluence() == eFactionInfluence_Influential )
		{
			// Second slot is unlocked at influential (high) influence
			`XEVENTMGR.TriggerEvent(FactionState.GetSecondOrderSlotEvent(), , , NewGameState);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function XComGameState_ResistanceFaction GetColumnFaction(int ColumnIndex)
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;

	if( ColumnIndex < 0 || ColumnIndex >= ColumnNames.Length || ColumnNames[ColumnIndex] == '' )
	{
		return none;
	}

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
	{
		if( FactionState.GetMyTemplateName() == ColumnNames[ColumnIndex] )
		{
			return FactionState;
		}
	}

	return none;
}

function XComGameState_HeadquartersResistance GetResistanceHQ()
{
	return XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
}

function RefreshAllDecks()
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;
	local array<StateObjectReference> HandCards, ListCards;
	local int idx;

	/// HL-Docs: ref:UIStrategyPolicy_MiscEvents
	`XEVENTMGR.TriggerEvent('UIStrategyPolicy_PreRefreshAllDecks',, self);

	ResHQ = GetResistanceHQ();
	HandCards = ResHQ.GetHandCards();

	Hand.ClearItems();
	Hand.ClearPagination();
	RealizeHand(HandCards);

	for( idx = 0; idx < 4; idx++ )
	{
		FactionState = GetColumnFaction(idx);
		Columns[idx].ClearItems();

		if( FactionState == none )
		{
			ListCards = ResHQ.GetWildCardSlots();
		}
		else
		{
			ActivatePolicyColumn(idx, FactionState.GetLeaderImage());
			ListCards = FactionState.GetCardSlots();
		}

		RealizeColumn(Columns[idx], ListCards, idx);
	}

	RealizePolicyLabels();
	RealizePolicyTabs(HandCards);
	MC.BeginFunctionOp("LayoutPolicyTabs");
	MC.EndOp();
}

function DEBUG_FillDecks()
{
	local array<StateObjectReference> Cards;
	local StateObjectReference EmptyRef;

	Cards.AddItem(EmptyRef);

	RealizeHand(Cards);

	RealizeColumn(Columns[0], Cards, 0);
	RealizeColumn(Columns[1], Cards, 1);
	RealizeColumn(Columns[2], Cards, 2);
	RealizeColumn(Columns[3], Cards, 3);
}

//==============================================================================
//==============================================================================

function RealizePolicyLabels()
{
	MC.BeginFunctionOp("UpdatePolicyLabels");
	MC.QueueString(DeckTitle);

	MC.QueueString(WildCardColumnLabel);
	MC.QueueString(KnowsFaction(ColumnNames[1]) ? Caps(GetColumnFaction(1).GetFactionTitle()) : UnknownFactionColumnLabel);
	MC.QueueString(KnowsFaction(ColumnNames[2]) ? Caps(GetColumnFaction(2).GetFactionTitle()) : UnknownFactionColumnLabel);
	MC.QueueString(KnowsFaction(ColumnNames[3]) ? Caps(GetColumnFaction(3).GetFactionTitle()) : UnknownFactionColumnLabel);

	MC.EndOp();

	SetColumnFaction(0);
	SetColumnFaction(1, GetColumnFaction(1).FactionIconData);
	SetColumnFaction(2, GetColumnFaction(2).FactionIconData);
	SetColumnFaction(3, GetColumnFaction(3).FactionIconData);

	if( !KnowsFaction(ColumnNames[1]) )	 DeactivatePolicyColumn(1);
	if( !KnowsFaction(ColumnNames[2]) )	 DeactivatePolicyColumn(2);
	if( !KnowsFaction(ColumnNames[3]) )	 DeactivatePolicyColumn(3);

	UpdateFactionInfluence(1);
	UpdateFactionInfluence(2);
	UpdateFactionInfluence(3);

	UpdateColumnHints();
}

function string GetInfluenceString(int ColumnIndex)
{
	local string DisplayString;
	local XComGameState_ResistanceFaction Faction;
	local EUIState ColorState;

	Faction = GetColumnFaction(ColumnIndex);
	DisplayString = Caps(Faction.GetInfluenceString());

	switch( Faction.Influence )
	{
	case 2:		ColorState = eUIState_Good;		break;
	case 1:		ColorState = eUIState_Normal;	break;
	case 0:		ColorState = eUIState_Warning;	break;
	default:	ColorState = eUIState_Bad;		break;
	}

	DisplayString = class'UIUtilities_Text'.static.GetColoredText(DisplayString, ColorState);

	return DisplayString;
}

function UpdateFactionInfluence(int Index)
{
	MC.BeginFunctionOp("UpdateFactionInfluence");
	MC.QueueNumber(Index);

	if( KnowsFaction(ColumnNames[Index]) )
	{
		MC.QueueString(InfluenceLabel);
		MC.QueueString(GetInfluenceString(Index));
		MC.QueueBoolean(ShouldSwapInfluenceLabel());
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueBoolean(false);

	}
	MC.EndOp();
}

function bool ShouldSwapInfluenceLabel()
{
	local string Language;
	Language = GetLanguage();
	switch( Language )
	{
	case "FRA": //swap vertical placement for French, TTP 8747
	case "DEU": //swap vertical placement for German, TTP 10104
	case "ESN": //swap vertical placement for Spanish, TTP 10104
		return true;
	default:
		return false;
	}
}

function RealizePolicyTabs(array<StateObjectReference> HandCards)
{
	local XComGameState_ResistanceFaction FactionState;
	local name FactionName;
	local int idx;

	TabFactionNames.length = 0;

	UpdatePolicyTab(0);
	TabFactionNames.AddItem('');

	for( idx = 1; idx < 4; idx++ )
	{
		FactionState = GetColumnFaction(idx);
		FactionName = FactionState.GetMyTemplateName();

		if( HasCardsOfType(FactionName, HandCards) )
		{
			UpdatePolicyTab(idx, FactionState.FactionIconData);
			TabFactionNames.AddItem(FactionState.GetMyTemplateName());
		}
		else
		{
			UpdatePolicyTab(idx);
			TabFactionNames.AddItem('');
		}
	}

	CheckScrollBar();
}

function CheckScrollBar()
{
	local bool ScrollBarActive;

	if( Hand.Scrollbar == none )
	{
		ScrollBarActive = false;
	}
	else
	{
		ScrollBarActive = true;
	}

	MC.BeginFunctionOp("UpdatePolicyTabY");
	MC.QueueBoolean(ScrollBarActive);
	MC.EndOp();
}

function UpdatePolicyTab(int Index, optional StackedUIIconData factionIcon)
{
	local int i;
	local StackedUIIconData EmptyIcon;


	if( Index == 0 )
	{
		MC.BeginFunctionOp("UpdatePolicyTab");
		MC.QueueNumber(Index);
		MC.QueueBoolean(false);
		MC.QueueString("img:///" $ class'UIUtilities_Image'.const.FactionIcon_XCOM $ "_sm");
		MC.EndOp();
	}
	else if( factionIcon == EmptyIcon )
	{
		MC.BeginFunctionOp("HidePolicyTab");
		MC.QueueNumber(Index);
		MC.EndOp();
	}
	else
	{
		MC.BeginFunctionOp("UpdatePolicyTab");

		MC.QueueNumber(Index);
		MC.QueueBoolean(factionIcon.bInvert);
		for( i = 0; i < factionIcon.Images.Length; i++ )
		{
			MC.QueueString("img:///" $ factionIcon.Images[i] $ "_sm");
		}
		MC.EndOp();
	}
}


function ClickTab(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP :
		if( !bDragging )
			SelectTab(int(Repl(string(Panel.MCName), "CardTab", "")));
		break;
	}
}

function SelectTab(int iTargetTab)
{
	m_iCurrentFactionTab = iTargetTab; 
	FilterFaction = TabFactionNames[iTargetTab];
	if( `ISCONTROLLERACTIVE)
	{
		SelectCardInDeck(0);
	}
	Hand.ClearPagination();
	RealizeHand(GetResistanceHQ().GetHandCards());
	CheckScrollBar();

	//bsg-jneal (5.31.17): support for changing filter tabs
	if( `ISCONTROLLERACTIVE)
	{
		ClearInspector();
	}
	//bsg-jneal (5.31.17): end

	MC.FunctionNum("HighlightPolicyTab", m_iCurrentFactionTab);
}

function SetColumnFaction(int Index, optional StackedUIIconData factionIcon)
{
	local int i;
	local StackedUIIconData EmptyIcon;

	MC.BeginFunctionOp("SetColumnFaction");

	MC.QueueNumber(Index);
	if( Index == 0 )
	{
		MC.QueueBoolean(false);
		MC.QueueString("img:///" $ class'UIUtilities_Image'.const.FactionIcon_XCOM);
	}
	else if( factionIcon == EmptyIcon )
	{
		MC.QueueBoolean(false);
		MC.QueueString("");
	}
	else
	{
		MC.QueueBoolean(factionIcon.bInvert);
		for( i = 0; i < factionIcon.Images.Length; i++ )
		{
			MC.QueueString("img:///" $ factionIcon.Images[i]);
		}
	}
	MC.EndOp();
}

function UpdateColumnHints()
{
	if( ColumnNames.length == 0 ) return;

	MC.BeginFunctionOp("UpdatePolicyHints");
	MC.QueueString(GetColumnFaction(0).GetColumnHint());
	MC.QueueString(GetColumnFaction(1).GetColumnHint());
	MC.QueueString(GetColumnFaction(2).GetColumnHint());
	MC.QueueString(GetColumnFaction(3).GetColumnHint());
	MC.EndOp();
}

function bool KnowsFaction(Name FactionName)
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
	{
		if( FactionState.GetMyTemplateName() == FactionName && FactionState.bSeenFactionHQReveal )
		{
			return true;
		}
	}

	return false;
}

function bool HasCardsOfType(name FactionName, array<StateObjectReference> HandCards)
{
	local int idx;
	local XComGameState_StrategyCard CardState;
	local bool hasCard;

	hasCard = false;

	for( idx = 0; idx < HandCards.Length; idx++ )
	{
		CardState = GetCardState(HandCards[idx]);

		if( CardState != none )
		{
			if( FactionName == CardState.GetAssociatedFactionName() )
			{
				hasCard = true;
				break;
			}
		}
	}

	return hasCard;
}

function ActivatePolicyColumn(int ColumnNumber, string ImageString)
{
	MC.BeginFunctionOp("ActivatePolicyColumn");
	MC.QueueNumber(ColumnNumber);
	MC.QueueString(ImageString);
	MC.EndOp();
}
function DeactivatePolicyColumn(int ColumnNumber)
{
	MC.FunctionNum("DeactivatePolicyColumn", ColumnNumber);
}

function DisablePolicyColumn(int iColumn, bool bActiveInColumn)
{
	if( bActiveInColumn )
	{
		MC.FunctionNum("EnablePolicyColumn", iColumn);
		Columns[iColumn].SetAlpha(100);
	}
	else
	{
		MC.FunctionNum("DisablePolicyColumn", iColumn);
		Columns[iColumn].SetAlpha(50);
	}
}

function Inspect(UIPanel Card)
{
	InspectingCard = UIStrategyPolicy_Card(Card);
	if( InspectingCard == none || !InspectingCard.CanInspectCard() )
		ClearInspector();
	else
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ResistanceOrders_CardMouseover");

		MC.FunctionString("Inspect", string(Card.MCPath));
	}
}
function ClearInspector(optional bool bAnimate = true)
{
	InspectingCard = none;
	MC.FunctionBool("ClearInspector", bAnimate);
}

//==============================================================================
//==============================================================================

function RealizeHand(array<StateObjectReference> HandCards)
{
	local int idx;
	local UIStrategyPolicy_Card Card;
	local XComGameState_StrategyCard CardState;

	Hand.ClearItems();
	HandCards = ApplyFilters(HandCards);
	HandCards = Hand.FilterCardsToDisplay(HandCards); 

	for( idx = 0; idx < HandCards.Length; idx++ )
	{
		Card = CreateCard(Hand, HandCards[idx]);

		//bsg-jneal (5.31.17): if there are cards in hand, start initial selection there
		if( `ISCONTROLLERACTIVE && idx == m_iHandIndex )
		{
			m_bSelectingHand = true;
			HighlightDeckRow(true);
			Card.AddOnInitDelegate(OnFirstHandItemInit);
		}
		//bsg-jneal (5.31.17): end

		CardState = GetCardState(HandCards[idx]);

		if( CardState != none )
		{
			Card.AssociatedFactionName = CardState.GetAssociatedFactionName();
		}

		Card.SetCardState(eUIStrategyPolicyCardState_Hand);
	}

	// Due to the cards animating on, sometimes the mask won't get turned off even if we don't need it
	if( Hand.Scrollbar == none )
	{
		if( Hand.Mask != none )
		{
			Hand.Mask.Remove();
			Hand.Mask = none;
		}
	}
	if( `ISCONTROLLERACTIVE )
	{
		RefreshPageArrows();
	}
}

function array<StateObjectReference> ApplyFilters(array<StateObjectReference> Cards)
{
	local int idx;
	local XComGameState_StrategyCard CardState;
	local array<StateObjectReference> FilteredCards;

	for( idx = 0; idx < Cards.Length; idx++ )
	{
		CardState = GetCardState(Cards[idx]);
		if( (CardState.GetAssociatedFactionName() == FilterFaction)
		   || (FilterFaction == '') )
		{
			FilteredCards.AddItem(Cards[idx]);
		}
	}

	// If we don't have any filtered cards, just display all cards rather than an empty deck
	if( FilteredCards.Length == 0 )
	{
		FilteredCards = Cards;
	}

	return FilteredCards;
}


function RealizeColumn(UIList Column, array<StateObjectReference> ColumnSlots, int ColumnIndex)
{
	local int idx;
	local UIStrategyPolicy_Card Card;
	local XComGameState_ResistanceFaction FactionState;

	Column.ClearItems();
	FactionState = GetColumnFaction(ColumnIndex);

	for( idx = 0; idx < ColumnSlots.Length; idx++ )
	{
		Card = CreateCard(Column, ColumnSlots[idx]);
		Card.AssociatedFactionName = GetCardState(ColumnSlots[idx]).GetAssociatedFactionName();

		if( FactionState == none )
		{
			Card.SetCardSlotHint(WildCardSlotLabel);
		}

		Card.ColumnIndex = ColumnIndex;
		Card.ColumnSlot = idx;

		Card.SetCardState(eUIStrategyPolicyCardState_Slot);
	}

	if( FactionState != none && FactionState.bSeenFactionHQReveal && FactionState.GetInfluence() < eFactionInfluence_Influential )
	{
		CreateLockedCard(Column, LockedSlotLabel);
	}

	/// HL-Docs: ref:UIStrategyPolicy_MiscEvents
	`XEVENTMGR.TriggerEvent('UIStrategyPolicy_PostRealizeColumn', Column, self);
}

function XComGameState_StrategyCard GetCardState(StateObjectReference CardRef)
{
	return XComGameState_StrategyCard(`XCOMHISTORY.GetGameStateForObjectID(CardRef.ObjectID));
}

private function UIStrategyPolicy_Card CreateCard(UIList TargetList, StateObjectReference CardRef)
{
	local XComGameState_StrategyCard CardState;
	local UIStrategyPolicy_Card Card;

	CardState = GetCardState(CardRef);
	Card = UIStrategyPolicy_Card(TargetList.CreateItem(class'UIStrategyPolicy_Card'));
	Card.InitPanel();
	Card.CardRef = CardRef;

	if( CardState != none )
	{
		Card.SetCardData(CardState.GetDisplayName(),
						 CardState.GetSummaryText(),
						 CardState.GetQuote(),
						 CardState.GetImagePath(),
						 CardState.GetNeedsAttention());

		Card.SetCardFaction(CardState.GetAssociatedFactionName());
		Card.SetCardFactionIcon(CardState.GetFactionIcon());
		Card.SetCardSlotHint(CardState.GetSlotHint());

		if( !IsInHand(Card) && !CardState.CanBeRemoved() )
		{
			Card.MarkCardAsSpecial(true);
		}
		else
		{
			Card.MarkCardAsSpecial(false);
		}
	}
	else
	{
		// Blank Slot
		Card.SetCardData("", "", "", "", false);
		Card.SetCardFaction('');
		Card.SetCardSlotHint("");
	}

	return Card;
}

private function UIStrategyPolicy_Card CreateLockedCard(UIList TargetList, string DisplayHint)
{
	local UIStrategyPolicy_Card Card;

	Card = UIStrategyPolicy_Card(TargetList.CreateItem(class'UIStrategyPolicy_Card'));
	Card.InitPanel();
	Card.SetCardLocked();
	Card.SetCardData("", "", "", "", false);
	Card.SetCardSlotHint(DisplayHint);
	Card.SetCardState(eUIStrategyPolicyCardState_Slot);

	return Card;
}

//==============================================================================
//==============================================================================
simulated function OnMouseEventCardCatcher(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
		EndDrag(true);
		HighlightDeckRow(false);
		break;
	}
}
simulated function OnMouseEventDeckCatcher(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
		if( bDragging )
			DropCardBackInToHand(InspectingCard);

		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER :
		if( bDragging )
			HighlightDeckRow(true);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT :
		if( bDragging )
			HighlightDeckRow(false);
		break;
	}

}

function DropCardBackInToHand(UIStrategyPolicy_Card TargetCard)
{
	local XComGameState_StrategyCard CardState;

	CardState = GetCardState(TargetCard.CardRef);

	// Put back in the deck
	if( CardState != none && CardState.CanBeRemoved() )
	{
		RemoveCardFromSlot(TargetCard);
	}

	ClearInspector(false);
	EndDrag(false);
	HighlightDeckRow(false);
	RefreshAllDecks();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int TargetIndex;

	TargetIndex = int(Split(args[5], "tab", true));
	`log("Clicked: " @TargetIndex,, 'uixcom' );

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP :
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
		if( bDragging )
		{
			DropCardBackInToHand(InspectingCard);
		}
		else
		{
			ClearInspector();
			SelectTab(TargetIndex);
		}
													   break;

	}
}

// bsg-nlong (2.6.17): These are the function used to manually navigate the screen
simulated function bool IsColumnSelectable(int columnIndex)
{
	local XComGameState_ResistanceFaction FactionState;

	FactionState = GetColumnFaction(columnIndex);
	return columnIndex == 0 ||
		(
			KnowsFaction(ColumnNames[columnIndex])
			&& FactionState != none
			&& FactionState.Influence > 0
			&& (InspectingCard == none || FactionState.GetMyTemplateName() == InspectingCard.AssociatedFactionName)
			);
}

simulated function SelectNextColumn()
{
	local int idx;
	local bool bInvalidNavigation;

	bInvalidNavigation = false;
	idx = m_iColumnIndex;
	do
	{
		idx = idx + 1;
		if( idx >= Columns.Length )
		{
			if( m_bLoopColumnSelection )
			{
				idx = 0;
			}
			else
			{
				bInvalidNavigation = true;
				break;
			}
		}
	} until(IsColumnSelectable(idx) || idx == m_iColumnIndex);

	if( bInvalidNavigation ) return;

	if( idx != m_iColumnIndex )
	{
		SelectColumn(idx);
	}
}

simulated function SelectPrevColumn()
{
	local int idx;
	local bool bInvalidNavigation;

	bInvalidNavigation = false;
	idx = m_iColumnIndex;
	do
	{
		idx = idx - 1;
		if( idx < 0 )
		{
			if( m_bLoopColumnSelection )
			{
				idx = Columns.Length - 1;
			}
			else
			{
				bInvalidNavigation = true;
				break;
			}
		}
	} until(IsColumnSelectable(idx) || idx == m_iColumnIndex);

	if( bInvalidNavigation ) return;

	if( idx != m_iColumnIndex )
	{
		SelectColumn(idx);
	}
}

simulated function SelectNextSlot()
{
	local int idx;

	idx = m_iSlotIndex + 1;
	if( idx >= Columns[m_iColumnIndex].GetItemCount() )
	{
		if( m_bLoopSlotSelection )
		{
			idx = 0;
		}
		else
		{
			return;
		}
	}

	SelectSlot(idx);
}

simulated function SelectPrevSlot()
{
	local int idx;

	idx = m_iSlotIndex - 1;
	if( idx < 0 )
	{
		if( m_bLoopSlotSelection )
		{
			idx = Columns[m_iColumnIndex].GetItemCount() - 1;
		}
		else
		{
			return;
		}
	}

	SelectSlot(idx);
}

simulated function SelectNextCard()
{
	local int idx;

	idx = m_iHandIndex + 1;
	
	if( Hand.ShouldTriggerPageFlipNext(idx) )
	{
		Hand.NextPage(); //BEFORE realizing the Hand

		if( idx >= class'UIStrategyPolicy_DeckList'.const.CARDS_PER_PAGE )
			idx = 0;

		m_iHandIndex = idx;
		RealizeHand(GetResistanceHQ().GetHandCards());
	}
	else
	{
		if( idx >= Hand.GetMaxCardsOnCurrentPage() )
		{
			if( Hand.CanNavNext() )
				idx = 0;
			else
				idx = m_iHandIndex;
		}
	}

	SelectCardInDeck(idx);
}

simulated function SelectPrevCard()
{
	local int idx;

	idx = m_iHandIndex - 1;

	if( Hand.ShouldTriggerPageFlipPrev(idx) )
	{
		Hand.PrevPage(); //BEFORE realizing the Hand

		if( idx < 0 ) 
			idx += class'UIStrategyPolicy_DeckList'.const.CARDS_PER_PAGE;

		m_iHandIndex = idx;
		RealizeHand(GetResistanceHQ().GetHandCards());
	}
	else
	{
		if( idx < 0 )
		{
			if( Hand.CanNavPrev() )
				idx += class'UIStrategyPolicy_DeckList'.const.CARDS_PER_PAGE;
			else
				idx = m_iHandIndex;
		}
	}

	SelectCardInDeck(idx);
}

function NextPage()
{
	m_iHandIndex = class'UIStrategyPolicy_DeckList'.const.CARDS_PER_PAGE - 1;
	SelectNextCard();
}
function PrevPage()
{
	m_iHandIndex = 0;
	SelectPrevCard();
}
simulated function SelectColumn(int newIndex)
{
	ClearSelection();
	m_iColumnIndex = newIndex;

	//bsg-jneal (5.31.17): maintain slot index for grid navigation
	if( `ISCONTROLLERACTIVE)
	{
		if( m_iSlotIndex >= Columns[m_iColumnIndex].GetItemCount() )
		{
			m_iSlotIndex = Columns[m_iColumnIndex].GetItemCount() - 1;
		}
	}
	else
	{
		m_iSlotIndex = 0;
	}
	//bsg-jneal (5.31.17): end

	Select(UIStrategyPolicy_Card(Columns[m_iColumnIndex].GetItem(m_iSlotIndex)));
}

simulated function SelectSlot(int newIndex)
{
	m_iSlotIndex = newIndex;
	Select(UIStrategyPolicy_Card(Columns[m_iColumnIndex].GetItem(m_iSlotIndex)));
}

simulated function SelectCardInDeck(int newIndex)
{
	//bsg-jneal (5.31.17): add selection brackets for Hand cards
	m_iHandIndex = newIndex;
	//bsg-jneal (5.31.17): end
	Select(UIStrategyPolicy_Card(Hand.GetItem(m_iHandIndex)));
}
// bsg-nlong (2.6.17): end

simulated function Select(UIStrategyPolicy_Card TargetCard)
{
	/// HL-Docs: ref:UIStrategyPolicy_MiscEvents
	`XEVENTMGR.TriggerEvent('UIStrategyPolicy_PreSelect', TargetCard, self);

	`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ResistanceOrders_CardMouseover");
	MC.FunctionString("Select", string(TargetCard.MCPath));
}

simulated function ClearSelection()
{
	/// HL-Docs: ref:UIStrategyPolicy_MiscEvents
	`XEVENTMGR.TriggerEvent('UIStrategyPolicy_PreClearSelection',, self);

	MC.FunctionVoid("ClearSelection");
}

function RefreshPageArrows()
{
	if( DeckPageArrowNext != none )
		DeckPageArrowNext.SetVisible(Hand.CanNavNext());
	if( DeckPageArrowPrev != none )
		DeckPageArrowPrev.SetVisible(Hand.CanNavPrev());
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local XComGameState_StrategyCard CardState;
	local UIStrategyPolicy_Card TargetCard;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	//bsg-jneal (5.31.17): gamepad support revamp for grid navigation and other improvements based on feedback
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B : //bsg-cballinger (2.8.17): Button swapping should only be handled in XComPlayerController, to prevent double-swapping back to original value.
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		// bsg-nlong (2.6.17): If there is a hand back out of the factions and go back to the hand, or back out of the screen
		if( `ISCONTROLLERACTIVE )
		{
			if( InspectingCard != none && bResistanceReport )
			{
				ClearInspector();
				HighlightPotentialDropSpots_Controller(); // bsg-nlong (2.3.17): This will re highlight all slots with a cleared inspector.
				UpdateNavHelp();
			}
			else
			{
				OnClickedContinue();
			}
		}
													   // bsg-nlong (2.6.17): end
		else
		{
			OnClickedContinue();
		}
													   break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_A : //bsg-cballinger (2.8.17): Button swapping should only be handled in XComPlayerController, to prevent double-swapping back to original value.
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		if( bResistanceReport )
		{
		// bsg-nlong (2.6.17): Handling select input for both the hand and factions
		if( `ISCONTROLLERACTIVE )
		{
			if( m_bSelectingHand )
			{
				SelectCard(UIStrategyPolicy_Card(Hand.GetItem(m_iHandIndex)));
			}
			else
			{
				SelectCard(UIStrategyPolicy_Card(Columns[m_iColumnIndex].GetItem(m_iSlotIndex)));
			}
			HighlightPotentialDropSpots_Controller();
			}
														   // bsg-nlong (2.6.17): end
		else
		{
			OnClickedContinue();
			}
		}
		else
		{
			`SOUNDMGR.PlaySoundEvent("Play_MenuClickNegative"); //TODO: @sound : better card sounds! 
		}
													   break;

	 // bsg-nlong (2.6.17): Remove the card if you hit X
	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		if( bResistanceReport && !m_bSelectingHand )
		{
			ClearInspector();

			TargetCard = UIStrategyPolicy_Card(Columns[m_iColumnIndex].GetItem(m_iSlotIndex));
			CardState = GetCardState(TargetCard.CardRef);
			// Put back in the deck
			if( CardState != none && CardState.CanBeRemoved() )
			{
				RemoveCardFromSlot(TargetCard);
			}
			else
			{
				`SOUNDMGR.PlaySoundEvent("Play_MenuClickNegative"); //TODO: @sound : better card sounds! 
			}
			RefreshAllDecks();
		}
													 break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
		// change card filter for hand
		if( TabFactionNames.Length > 0 )
		{
			m_iCurrentFactionTab++;

			if( m_iCurrentFactionTab >= TabFactionNames.Length )
			{
				m_iCurrentFactionTab = 0;
			}
			ClearSelection();
			SelectTab(m_iCurrentFactionTab);
		}
													 break;
													 // bsg-nlong (2.6.17): end

													 // bsg-nlong (2.6.17): Controller navigation
	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP : //bsg-crobinson (5.17.17): Add stick input
		if( bResistanceReport )
		{
			if( m_bSelectingHand )
			{
				ClearSelection();
				m_bSelectingHand = false;
				HighlightDeckRow(false);

				m_iColumnIndex = Hand.GetTargetColumnNav(m_iHandIndex);
				SelectSlot(Columns[m_iColumnIndex].GetItemCount() - 1);

				UpdateNavHelp();
			}
			else
			{
				SelectPrevSlot();
			}
		}
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN : //bsg-crobinson (5.17.17): Add stick input
		if( bResistanceReport )
		{
			if( m_bSelectingHand )
			{
				bHandled = false;
			}
			else
			{
				if( m_iSlotIndex + 1 >= Columns[m_iColumnIndex].GetItemCount() )
				{
					ClearSelection();

					m_bSelectingHand = true;
					HighlightDeckRow(true);
					SelectCardInDeck(Hand.GetTargetHandNav(m_iColumnIndex));

					UpdateNavHelp();
				}
				else
				{
					SelectNextSlot();
				}
			}
		}
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT : //bsg-crobinson (5.17.17): Add stick input
		if( bResistanceReport )
		{
		if( m_bSelectingHand )
		{
			SelectPrevCard();
		}
		else
		{
			SelectPrevColumn();
		}
		}
		else
		{
			PrevPage();
		}
													  break;

	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT : //bsg-crobinson (5.17.17): Add stick input
		if( bResistanceReport )
		{
		if( m_bSelectingHand )
		{
			SelectNextCard();
		}
		else
		{
			SelectNextColumn();
			}
		}
		else
		{
			NextPage();
		}
													   break;
													   // bsg-nlong (2.6.17): end

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnClickedContinue()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResHQ;

	ResHQ = GetResistanceHQ();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Policy Screen Init");
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
	ResHQ.OnCardScreenConfirm(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if( !bResistanceReport || !AreUnusedSlotsAndCardsAvailable() )
	{
		NavHelp.ClearButtonHelp();
		CloseScreen();
	}
	else
	{
		LeaveWithoutPlayingCard();
	}
}

function bool AreUnusedSlotsAndCardsAvailable()
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;
	local array<StateObjectReference> HandCards;
	local int idx;

	ResHQ = GetResistanceHQ();

	for( idx = 0; idx < 4; idx++ )
	{
		FactionState = GetColumnFaction(idx);
		if( FactionState != none )
		{
			HandCards = FactionState.GetHandCards();
			if( HandCards.Length > 0 )
			{
				if( FactionState.HasEmptyCardSlot() || ResHQ.HasEmptyWildCardSlot() )
				{
					return true;
				}
			}
		}
	}

	return false;
}

simulated function LeaveWithoutPlayingCard()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strLeaveWithoutPlayingCardTitle;
	kData.strText = m_strLeaveWithoutPlayingCardBody;
	kData.strAccept = m_strLeaveWithoutPlayingCardStay;
	kData.strCancel = m_strLeaveWithoutPlayingCardLeave;
	kData.eType = eDialog_Warning;
	kData.fnCallback = OnLeaveWithoutPlayingCardCallback;

	Movie.Pres.UIRaiseDialog(kData);
}

simulated function OnLeaveWithoutPlayingCardCallback(Name eAction)
{
	// If Cancel, allow you to leave this screen. 
	if( eAction == 'eUIAction_Cancel' )
	{
		NavHelp.ClearButtonHelp();
		CloseScreen();
	}
}

function BeginDrag()
{
	if( !bDragging && bEnableDragging )
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ResistanceOrders_CardPickup");
		MC.FunctionVoid("BeginDrag");
		bDragging = true;
		HighlightPotentialDropSpots(true);

		/// HL-Docs: ref:UIStrategyPolicy_MiscEvents
		`XEVENTMGR.TriggerEvent('UIStrategyPolicy_DraggingStarted',, self);
	}
}

function EndDrag(bool bAnimate)
{
	if( bDragging )
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ResistanceOrders_CardDrop");
		MC.FunctionBool("EndDrag", bAnimate);
		bDragging = false;
		HighlightPotentialDropSpots(false);

		/// HL-Docs: ref:UIStrategyPolicy_MiscEvents
		`XEVENTMGR.TriggerEvent('UIStrategyPolicy_DraggingEnded',, self);
	}
}

function HighlightDeckRow(bool bHighlight)
{
	if( bHighlight != bHighlightDeckRow )
	{
		bHighlightDeckRow = bHighlight;
		MC.FunctionBool("HighlightDeckRow", bHighlightDeckRow);
	}
}

function HighlightPotentialDropSpots(bool bShouldHighlight)
{
	local int iColumn, iCard;
	local UIStrategyPolicy_Card TargetCard;
	local UIList Column;
	local bool bActiveInColumn;

	for( iColumn = 0; iColumn < Columns.Length; iColumn++ )
	{
		bActiveInColumn = !bShouldHighlight; // will cover default for a column without any cards
		Column = Columns[iColumn];

		for( iCard = 0; iCard < Column.ItemCount; iCard++ )
		{
			TargetCard = UIStrategyPolicy_Card(Column.GetItem(iCard));

			if( bShouldHighlight )
			{
				if( InspectingCard != none && IsAllowedToPlay(InspectingCard, TargetCard) )
				{
					TargetCard.Highlight(true);
					bActiveInColumn = true;
				}
				else
				{
					TargetCard.Highlight(false);
				}
			}
			else
			{
				TargetCard.Highlight(false);
				bActiveInColumn = true;
			}
		}

		DisablePolicyColumn(iColumn, bActiveInColumn);
	}
}

// bsg-nlong (2.6.17): On controller we don't want to highlight each slot, we just want to highlight the available columns
// if we're selecting a card and if there is no active card, we will just reset the column highlights
function HighlightPotentialDropSpots_Controller()
{
	local int idx;

	//No gray out if you're selecting a blank slot. 
	if( InspectingCard != none && InspectingCard.eFaction == eUIStrategyPolicyCardFaction_Blank )
		return; 

	for( idx = 0; idx < Columns.Length; ++idx )
	{
		if( InspectingCard != none )
		{
			DisablePolicyColumn(idx, idx == 0 || ColumnNames[idx] == InspectingCard.AssociatedFactionname);
		}
		else
		{
			DisablePolicyColumn(idx, true);
		}
	}
}
// bsg-nlong (2.6.17): end
//==============================================================================

function SelectCard(UIStrategyPolicy_Card TargetCard)
{
	if( InspectingCard == none )
	{
		Inspect(TargetCard);
		//TODO: @gameplay: player has now activated this card! InspectingCard 
	}
	else // We already have an inspecting card so... 
	{
		if( `ISCONTROLLERACTIVE && InspectingCard == TargetCard )
		{
			ClearInspector(); //clear the card if we select it again
		}
		else if( IsInHand(InspectingCard) && IsInHand(TargetCard) )
		{
			// TODO: @mnauta - improve when you have time
			// For now only allow playing from hand to slot
			ClearInspector();
			Inspect(TargetCard);
		}
		else if( `ISCONTROLLERACTIVE && !bResistanceReport )
		{
			//do nothing if it is not the end of the month
		}
		else if( IsAllowedToPlay(InspectingCard, TargetCard) && IsInHand(InspectingCard) && !IsInHand(TargetCard) )
		{
			`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ResistanceOrders_CardPlace");

			PlayCard(InspectingCard, TargetCard);

			ClearInspector();
			RefreshAllDecks();
		}
		else if( !IsInHand(InspectingCard) && !IsInHand(TargetCard) && (GetColumnFaction(TargetCard.ColumnIndex).GetMyTemplateName() == InspectingCard.AssociatedFactionName || TargetCard.ColumnIndex == 0) )
		{
			if( TargetCard.AssociatedFactionName == InspectingCard.AssociatedFactionName || TargetCard.ColumnIndex == InspectingCard.ColumnIndex )
			{
				`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ResistanceOrders_CardPlace");

				SwapSlotLocations(InspectingCard, TargetCard);
			}
			else
			{
				if( IsAllowedToPlay(InspectingCard, TargetCard) && (TargetCard.CanDragCard() || TargetCard.eFaction == eUIStrategyPolicyCardFaction_Blank) )
				{
					PlayCard(InspectingCard, TargetCard);
					RemoveCardFromSlot(InspectingCard);
				}
			}

			ClearInspector();
			RefreshAllDecks();
		}
		else if( !IsInHand(InspectingCard) && IsInHand(TargetCard) )
		{
			if( `ISCONTROLLERACTIVE )
			{
				if( !IsInHand(InspectingCard) && IsAllowedToPlay(TargetCard, InspectingCard) && TargetCard.CanDragCard() )
				{
					PlayCard(TargetCard, InspectingCard);
					DropCardBackInToHand(TargetCard);
				}
			}
			else
			{
				DropCardBackInToHand(InspectingCard);
			}

			ClearInspector();
			RefreshAllDecks();
		}
		else
		{
			`SOUNDMGR.PlaySoundEvent("Play_MenuClickNegative"); //TODO: @sound : better card sounds! 
		}
	}
}

private function SwapSlotLocations(UIStrategyPolicy_Card CardA, UIStrategyPolicy_Card CardB)
{
	local int OriginalSlotA, OriginalColumnA;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;

	//FIRST, save useful CardA origin data 
	OriginalSlotA = CardA.ColumnSlot;
	OriginalColumnA = CardA.ColumnIndex;

	//SECOND, play CardA over in to B's slot. 
	PlayCard(CardA, CardB);

	//THIRD: Now we put CardB in to A's original location. 
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Place Card in Slot");
	FactionState = GetColumnFaction(OriginalColumnA);

	if( FactionState != none )
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
		FactionState.PlaceCardInSlot(CardB.CardRef, OriginalSlotA);
	}
	else
	{
		ResHQ = GetResistanceHQ();
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		ResHQ.PlaceCardInSlot(CardB.CardRef, OriginalSlotA);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function RemoveCardFromSlot(UIStrategyPolicy_Card SourceCard)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Card from Slot");
	FactionState = GetColumnFaction(SourceCard.ColumnIndex);

	if( FactionState != none )
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
		FactionState.RemoveCardFromSlot(SourceCard.ColumnSlot);
	}
	else
	{
		ResHQ = GetResistanceHQ();
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		ResHQ.RemoveCardFromSlot(SourceCard.ColumnSlot);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function PlayCard(UIStrategyPolicy_Card SourceCard, UIStrategyPolicy_Card TargetCard)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Place Card in Slot");
	FactionState = GetColumnFaction(TargetCard.ColumnIndex);

	if( FactionState != none )
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
		FactionState.PlaceCardInSlot(SourceCard.CardRef, TargetCard.ColumnSlot);
	}
	else
	{
		ResHQ = GetResistanceHQ();
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		ResHQ.PlaceCardInSlot(SourceCard.CardRef, TargetCard.ColumnSlot);
	}


	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function bool IsAllowedToPlay(UIStrategyPolicy_Card SourceCard, UIStrategyPolicy_Card TargetCard)
{
	local XComGameState_StrategyCard SourceCardState, TargetCardState;
	local XComGameState_ResistanceFaction FactionState;

	FactionState = GetColumnFaction(TargetCard.ColumnIndex);

	SourceCardState = GetCardState(SourceCard.CardRef);
	TargetCardState = GetCardState(TargetCard.CardRef);

	if( !TargetCard.bLocked && (FactionState.GetMyTemplateName() == SourceCard.AssociatedFactionName || TargetCard.ColumnIndex == 0) &&
		(TargetCardState == none || (TargetCardState.CanBeRemoved(SourceCardState.GetReference()))) )
	{
		return true;
	}

	return false;
}

function bool IsInHand(UIStrategyPolicy_Card Card)
{
	return (Hand.GetItemIndex(Card) != -1);
}

simulated function OnLoseFocus()
{
	if( !bIsFocused )
		return;
	super.OnLoseFocus();
	NavHelp.ClearButtonHelp(); //bsg-crobinson (5.12.17): Clear navhelp
	Hide();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	Show();
}

simulated function UpdateNavHelp()
{
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.bIsVerticalHelp = false; //bsg-crobinson (5.12.17): Get rid of slight overlap with stacked buttons
	NavHelp.ClearButtonHelp();

	//bsg-jneal (1.25.17): adding controller navigation to resistance orders
	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddBackButton();
		if( bResistanceReport  )
			NavHelp.AddSelectNavHelp(); //bsg-crobinson (5.12.17): Add in a select button

		if( bResistanceReport && !m_bSelectingHand )
		{
			NavHelp.AddLeftHelp(m_strRemoveCard, class'UIUtilities_Input'.const.ICON_X_SQUARE); // bsg-nlong (2.6.17): Add the remove card prompt
		}

		//bsg-jneal (5.31.17): support for changing filter tabs
		if( TabFactionNames.Length > 0 )
		{
			NavHelp.AddLeftHelp(m_strChangeFilter, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		}
		//bsg-jneal (5.31.17): end
	}
	else
		NavHelp.AddContinueButton(OnClickedContinue);
	//bsg-jneal (1.25.17): end
}

simulated function CloseScreen()
{
	local XComGameState_HeadquartersResistance ResHQ;
	// Issue #440
	local XComLWTuple Tuple;

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	super.CloseScreen();

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	// Issue #440 Start

	/// HL-Docs: feature:UIStrategyPolicy_ShowCovertActionsOnClose; issue:365; tags:strategy,ui
	/// Allows overriding whether to show the `UICovertActions` screen after closing
	/// the `UIStrategyPolicy` screen.
	///
	/// Default: Show if `UIStrategyPolicy` was created as part of the end-of-month report
	/// and no covert actions are in progress.
	///
	/// ```event
	/// EventID: UIStrategyPolicy_ShowCovertActionsOnClose,
	/// EventData: [inout bool ShouldShow],
	/// EventSource: UIStrategyPolicy,
	/// NewGameState: none
	/// ```
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'UIStrategyPolicy_ShowCovertActionsOnClose';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = bResistanceReport && !ResHQ.IsCovertActionInProgress();

	`XEVENTMGR.TriggerEvent('UIStrategyPolicy_ShowCovertActionsOnClose', Tuple, self);
	if(Tuple.Data[0].b)
	// Issue #440 End
	{
		`HQPRES.UICovertActions();
	}
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_StrategyPolicy/XPACK_StrategyPolicy";
bAnimateOnInit = true;
bHideOnLoseFocus = true;
CameraTag = "UIDisplayCam_ResistanceScreen_FactionEvents";

bHighlightDeckRow = false;
bEnableDragging = true;
m_iColumnIndex = 0;
m_iSlotIndex = 0;
m_iHandIndex = 0;
m_bSelectingHand = true;
m_bLoopColumnSelection = false;
m_bLoopSlotSelection = false;
m_bLoopHandSelection = false;
}

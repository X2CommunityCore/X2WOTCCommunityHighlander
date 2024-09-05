/**DO NOT USE GotoState() IN THE PRESENTATION LAYERS! 
 * Please use PushState(...) and PopState() instead, which will preserve the state stack, if 
 * you wish to add additional states to a pres layer. 
 * If you use an illicit Goto without preserving the stack, you'll screw up the game state 
 * navigation and UI, and I will have to hunt you down. 
 * -bsteiner 
 */

class XComPresentationLayerBase extends Actor 
	dependson(XComNarrativeMoment)
	config(UI)
	abstract;

enum EKismetUIVis
{
	eKismetUIVis_None,
	eKismetUIVis_Show,
	eKismetUIVis_Hide
};

enum EProgressDialog
{
	eProgressDialog_None,
	eProgressDialog_Opening,
	eProgressDialog_Closing,
	eProgressDialog_Showing,
};

var protectedwrite MaterialInstanceConstant MovieRenderTargetMaterial;
var privatewrite UIScreenStack			ScreenStack;
var privatewrite UIDistortionManager	DistortionManger;

var protected UIMovie_2D            m_2DMovie;
var protected UIPhotoboothMovie     m_PhotoboothMovie;
var TextureRenderTarget2D			m_kUIRenderTexture;
var protected UIMovie_3D		    m_3DMovie; // 3D movie display
var protected UIMovie	            m_ModalMovie;
var           UIRedScreen           m_RedScreen;
var           UIDebugInfo		    m_kDebugInfo;
var protected UIPauseMenu           m_kPauseMenu;
var           UIOptionsPCScreen	    m_kPCOptions;
var protected UICredits             m_kCredits; 
var           UISecondWave          m_kGameToggles;
var protected UIDebugSafearea       m_kUIDebugSafeArea;
var protected UIDebugGrid			m_kDebugGrid; 
var			  UIEventNotices		m_kEventNotices;
//var protected UIDebugSizing		m_kDebugSizing; 
var protected UIControllerMap       m_kControllerMap;
var protected UILoadGame            m_kLoadUI;
var protected UILoadScreenAnimation m_kLoadAnimation;
var protected UISaveGame            m_kSaveUI;
var           UINarrativePopup      m_kNarrativePopup;
var           UINarrativeMgr        m_kNarrativeUIMgr;
var protected UIInputDialogue       m_kInputDialog;
var           UITutorialHelper      m_kTutorialHelper;
var		      UIShell_NavHelpScreen m_kNavHelpScreen;

var UIWorldMessageMgr           m_kWorldMessageManager;

var           TInputDialogData      m_kInputDialogData;

var           UIProgressDialogue    m_kProgressDialog;
var           TProgressDialogData   m_kProgressDialogData;
var           EProgressDialog       m_kProgressDialogStatus;

var protected UIReconnectController m_kControllerUnplugDialog;
var           TProgressDialogData   m_kControllerUnplugDialogData;

var protected UIKeybindingsPCScreen m_kPCKeybindings;
var           XComKeybindingData    m_kKeybindingData;

var XComCharacterCustomization m_kCustomizeManager; 

var UIMouseCursor                   m_kUIMouseCursor;
var UIVirtualKeyboard               m_VirtualKeyboard;

var UIScreen                        TempScreen;
var UITooltipMgr                    m_kTooltipMgr; 
var UIPawnMgr                       m_kPawnMgr;

var protected bool                  m_bIsGameDataReady;
var bool                            m_bInitialized;
var EKismetUIVis                    m_ePendingKismetVisibility; // cached value for Kismet calls to hide UI (before level loads; hence stop the ticking... never to receive a callback!)
var protected bool                  m_bIsIronman;
var protected bool					m_bDisallowSaving;
var protected bool                  m_bIsPlayingGame;
var protected EDifficultyLevel      m_eDiff;
var protected bool                  m_bGameOverTriggered;
var protectedwrite bool             m_bPresLayerReady;

var bool                            m_bBlockSystemMessageDisplay;

var public const EUIMode            m_eUIMode;      // Allow other objects to query which presentation layer they are working with
var           XGNarrative           m_kNarrative;
var protected array<TItemUnlock>    m_arrUnlocks;

var delegate<PostStateChangeCallback>  m_postStateChangeCallback;
var array<delegate<PreClientTravelDelegate> >  m_PreClientTravelDelegates;
var array< delegate<UpdateCallback> > m_arrUIUpdateCallbacks;//Holds subscriber calls to UI elements for update tick 

var UITutorialSaveData TutorialSaveData;

var config float DistortionScale;
var float TimeLeftToDistort; //used to control UI distortion
var bool bForceConcealmentOn;
var int MoviesInited;//we need to wait for both UIMovie_2D to finish initializing before initing the UIScreens
var float LastChosenDirectedAttack;

//=======================================================================================
//X-Com 2
//

//Holds a reference to the X-Com state that the UI builds in order to launch a tactical game
var XComGameState TacticalStartState;

//=======================================================================================

`if(`notdefined(FINAL_RELEASE))
var transient bool m_bSkipAsserts;
`endif

var localized string                m_strSaveWarning;
var localized string                m_strSelectSaveDeviceForLoadPrompt;
var localized string                m_strSelectSaveDeviceForSavePrompt;
var localized string                m_strOK;
var localized string                m_strErrHowToPlayNotAvailable;
var localized string                m_strPleaseReconnectController;
var localized string                m_strPleaseReconnectControllerPS3;
var localized string                m_strPleaseReconnectControllerPC;
var localized string                m_strPlayerEnteredUnfriendlyTitle;
var localized string                m_strPlayerEnteredUnfriendlyText;
var localized string                m_strShutdownOnlineGame;

var localized string ChallengeEventLabels[EChallengeModeEventType.EnumCount]<BoundEnum = EChallengeModeEventType>;
var localized string ChallengeEventDescriptions[EChallengeModeEventType.EnumCount]<BoundEnum = EChallengeModeEventType>;
var localized string ChallengeTurnLabel;

var localized string ChallengeObjectiveDecreaseNotice;
var localized string ChallengeObjectiveDecreaseText;
var localized string ChallengeEnemyDecreaseNotice;
var localized string ChallengeEnemyDecreaseText;
var localized string ChallengeScoringDecreaseNotice;
var localized string ChallengeScoringDecreaseText;

//--------------------------------------------------------------------------------

// Callbacks when the user action is performed
delegate delActionAccept( string userInput, bool bWasSuccessful );
delegate delActionCancel();
delegate delNoParams();
delegate delAfterStorageDeviceCallbackSuccess(); 

delegate UpdateCallback();
delegate bool PostStateChangeCallback();
delegate OnNarrativeCompleteCallback();
delegate PreRemoteEventCallback();

delegate PreClientTravelDelegate( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel );

simulated function UIMovie_2D			Get2DMovie()			{ return m_2DMovie; }
simulated function UIMovie_2D			GetPhotoboothMovie()	{ return m_PhotoboothMovie; }
simulated function UIMovie				GetModalMovie()			{ return m_ModalMovie; }
simulated function UIMessageMgr         GetMessenger()          { return m_2DMovie.MessageMgr; }
simulated function UIAnchoredMessageMgr GetAnchoredMessenger()  { return m_2DMovie.AnchoredMessageMgr; }
simulated function UINarrativeCommLink  GetUIComm()             { return m_2DMovie.CommLink; }
simulated private function XComSoundManager GetSoundMgr()		{ return `SOUNDMGR; }
simulated function UIDebugInfo			GetDebugInfo()			{ return m_kDebugInfo; }
simulated function UIPawnMgr            GetUIPawnMgr()          { return m_kPawnMgr; }

simulated function UIWorldMessageMgr    GetWorldMessenger()		{ return m_kWorldMessageManager; }

simulated function Init()
{
	// We must initialize the ScreenStack before Initing any movies
	ScreenStack = new(self) class'UIScreenStack'; 
	ScreenStack.Pres = self;

	DistortionManger = new(self) class'UIDistortionManager';
	DistortionManger.Pres = self;
	DistortionManger.ScreenStack = ScreenStack;
	
	// Load up Interface Manager
	m_2DMovie = new(self) class'UIMovie_2D';
	m_2DMovie.InitMovie(self);	

	if(`XENGINE.m_kPhotoboothUITexture != none)
	{
		class'TextureRenderTarget2D'.static.Resize(`XENGINE.m_kPhotoboothUITexture, 800, 1200);
	}

	m_PhotoboothMovie = new(self) class'UIPhotoboothMovie';
	m_PhotoboothMovie.RenderTexture = `XENGINE.m_kPhotoboothUITexture;
	m_PhotoboothMovie.InitMovie(self);

	// Create a new manager that stores movies to be shown during loading sequences
	m_ModalMovie = new(self) class'UIMovie_2D';
	m_ModalMovie.InitMovie(self);
	m_ModalMovie.Show(); // modal movie is always visible - sbatista 8/6/13
	
	m_bInitialized = true;
	m_bGameOverTriggered = false;

	// Only needs to be created and initialized, once. 
	// This is used for the Tutorial and the PCKeybindings.
	m_kKeybindingData = new class'XComKeybindingData';
	m_kKeybindingData.InitializeBindableCommandsMap();

	m_kPawnMgr = Spawn( class'UIPawnMgr', Owner );

	// Ensure distortion isn't activated initially
	StopDistort();
}

event Tick(float deltaTime)
{
	if( DistortionManger != none )
	{
		DistortionManger.Update(deltaTime);
	}

	// if( Should Show Popups Now )
	DisplayQueuedDynamicPopups();
}

static function QueueDynamicPopup(const out DynamicPropertySet PopupInfo, optional XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bLocalNewGameState;

	if( PopupInfo.bDisplayImmediate )
	{
		`PRESBASE.DisplayDynamicPopupImmediate(PopupInfo);
		return;
	}

	if( NewGameState == None )
	{
		bLocalNewGameState = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Queued UI Alert" @ PopupInfo.PrimaryRoutingKey @ PopupInfo.SecondaryRoutingKey);
	}
	else
	{
		bLocalNewGameState = false;
	}

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.QueuedDynamicPopups.AddItem(PopupInfo);

	if( bLocalNewGameState )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	if( PopupInfo.bDisplayImmediate )
	{
		`PRESBASE.DisplayQueuedDynamicPopups();
	}
}

simulated function bool DisplayDynamicPopupImmediate(const out DynamicPropertySet PropertySet)
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local bool bMessageHandled;
	local int i;

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);

	if (IsPropertySetApplicableForDisplay(PropertySet))
	{
		bMessageHandled = false;

		if (PropertySet.PrimaryRoutingKey == 'UIAlert')
		{
			CallUIAlert(PropertySet);
			bMessageHandled = true;
		}
		else if (PropertySet.PrimaryRoutingKey == 'UIWorldMessage')
		{
			CallWorldMessage(PropertySet);
			bMessageHandled = true;
		}
		else if (PropertySet.PrimaryRoutingKey == 'UIStandardMessage')
		{
			CallStandardMessage(PropertySet);
			bMessageHandled = true;
		}
		else if (PropertySet.PrimaryRoutingKey == 'UIAnchoredMessage')
		{
			CallAnchoredMessage(PropertySet);
			bMessageHandled = true;
		}
		else if (PropertySet.PrimaryRoutingKey == 'UIScreen')
		{
			CallUIScreen(PropertySet);
			bMessageHandled = true;
		}

		// For each DLC, check to see if it has any additional primary routing keys for messages
		for (i = 0; i < DLCInfos.Length; ++i)
		{
			if (DLCInfos[i].DisplayQueuedDynamicPopup(PropertySet))
			{
				bMessageHandled = true;
				break;
			}
		}
	}

	return bMessageHandled;
}

simulated function DisplayQueuedDynamicPopups()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int idx;
	local XComGameState NewGameState;
	local DynamicPropertySet CurrentPropertySet;
	local array<int> HandledIndicies;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	if (XComHQ != None && XComHQ.QueuedDynamicPopups.Length > 0)
	{
		for (idx = 0; idx < XComHQ.QueuedDynamicPopups.Length; idx++)
		{
			CurrentPropertySet = XComHQ.QueuedDynamicPopups[idx];

			if (DisplayDynamicPopupImmediate(CurrentPropertySet))
			{
				HandledIndicies.AddItem(idx);
			}
		}

		// clear all of the popups that have been handled from the list
		if (HandledIndicies.Length > 0)
		{
			// Flag the research report as having been seen
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Raising Queued UI Alert");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

			for (idx = HandledIndicies.Length - 1; idx >= 0; --idx)
			{
				XComHQ.QueuedDynamicPopups.Remove(HandledIndicies[idx], 1);
			}

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

simulated function bool IsPropertySetApplicableForDisplay(const out DynamicPropertySet PropertySet)
{
	local X2TacticalGameRuleset TacticalRuleset;

	if( PropertySet.bDisplayImmediate )
	{
		return true;
	}

	if( PropertySet.bDisplayOnAvengerSideViewIdle && ScreenStack.IsCurrentClass(class'UIFacilityGrid') )
	{
		return true;
	}

	if( PropertySet.bDisplayOnGeoscapeIdle && ScreenStack.IsCurrentClass(class'UIStrategyMap') )
	{
		return true;
	}

	if( PropertySet.bDisplayInTacticalIdle )
	{
		TacticalRuleset = `TACTICALRULES;
		if( TacticalRuleset != None && !TacticalRuleset.WaitingForVisualizer() )
		{
			return true;
		}
	}

	return false;
}

static function BuildUIAlert(
	out DynamicPropertySet PropertySet, 
	Name AlertName, 
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction, 
	Name EventToTrigger, 
	string SoundToPlay,
	bool bImmediateDisplay = true)
{
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert', AlertName, CallbackFunction, bImmediateDisplay, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', EventToTrigger);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', SoundToPlay);
}

simulated function CallUIAlert(const out DynamicPropertySet PropertySet)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	ScreenStack.Push(Alert);
}

static function BuildUIScreen(
	out DynamicPropertySet PropertySet,
	Name ScreenName,
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction,
	bool bImmediateDisplay = true)
{
	`assert( CallbackFunction != none); // without this what are you doing?
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIScreen', ScreenName, CallbackFunction, bImmediateDisplay, true, true, false);
}

simulated function CallUIScreen(DynamicPropertySet PropertySet)
{
	local int StackSize;
	local delegate<X2StrategyGameRulesetDataStructures.AlertCallback> LocalCallbackFunction;

	StackSize = ScreenStack.Screens.Length;

	LocalCallbackFunction = PropertySet.CallbackFunction;
	LocalCallbackFunction(PropertySet.SecondaryRoutingKey, PropertySet, PropertySet.bDisplayImmediate);

	`assert( ScreenStack.Screens.Length != StackSize ); // why'd you set up a queue entry if you weren't going to add anything?
}

static function QueueWorldMessage(
	string                  _sMsg,
	vector                  _vLocation,
	optional StateObjectReference _TargetObject,
	optional int            _eColor = eColor_Xcom,
	optional int            _eBehavior = 0,
	optional string         _sId = "",
	optional ETeam          _eBroadcastToTeams = eTeam_None,
	optional bool           _bUseScreenLocationParam = false,
	optional Vector2D       _vScreenLocationParam,
	optional float          _displayTime = 5.0,
	optional class<XComUIBroadcastWorldMessage> _cBroadcastMessageClass = none, // this property is completely deprecated
	optional string			_sIcon = class'UIUtilities_Image'.const.UnitStatus_Default,
	optional int			_iDamagePrimary = 0,
	optional int			_iDamageModified = 0,
	optional string			_sCritLabel = "",
	optional EHUDMessageType _eType = eHUDMessage_World,
	optional int 	        _damageType = -1,
	optional delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction,
	optional XComGameState NewGameState,
	optional bool			_displayImmediate)
{
	local DynamicPropertySet PropertySet;

	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIWorldMessage', '', CallbackFunction, _displayImmediate, true, true, true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Message', _sMsg);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicVectorProperty(PropertySet, 'Location', _vLocation);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TargetObjectRef', _TargetObject.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Color', _eColor);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Behavior', _eBehavior);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'MessageID', _sId);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Team', _eBroadcastToTeams);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'UseScreenLocation', _bUseScreenLocationParam);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicVector2DProperty(PropertySet, 'ScreenLocation', _vScreenLocationParam);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicFloatProperty(PropertySet, 'Timeout', _displayTime);
	//class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'MessageClass', (_cBroadcastMessageClass != None) ? _cBroadcastMessageClass.Name : '');
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Icon', _sIcon);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'DamageBase', _iDamagePrimary);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'DamageMod', _iDamageModified);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'CritLabel', _sCritLabel);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MessageType', _eType);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'DamageType', _damageType);

	QueueDynamicPopup(PropertySet, NewGameState);
}

simulated function CallWorldMessage(const out DynamicPropertySet PropertySet)
{
	local StateObjectReference TargetObjectRef;
	//local class<XComUIBroadcastWorldMessage> WorldMessageClass;

	TargetObjectRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'TargetObjectRef');
	//WorldMessageClass = class<XComUIBroadcastWorldMessage>(class'XComEngine'.static.GetClassByName(
	//	class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(PropertySet, 'MessageClass')));
	
	GetWorldMessenger().Message(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'Message'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicVectorProperty(PropertySet, 'Location'),
		TargetObjectRef,
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Color'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Behavior'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'MessageID'),
		ETeam(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Team')),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(PropertySet, 'UseScreenLocation'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicVector2DProperty(PropertySet, 'ScreenLocation'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicFloatProperty(PropertySet, 'Timeout'),
		/*WorldMessageClass*/,
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'Icon'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'DamageBase'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'DamageMod'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'CritLabel'),
		EHUDMessageType(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'MessageType')),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'DamageType')
		);
}

static function QueueStandardMessage(
	string    _sMsg,
	EUIIcon   _iIcon = eIcon_GenericCircle,
	EUIPulse  _iPulse = ePulse_None,
	float     _displayTime = 2.0,
	string    _sId = "",
	optional ETeam     _eBroadcastToTeams = eTeam_None,
	optional delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction,
	optional XComGameState NewGameState)
{
	local DynamicPropertySet PropertySet;

	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIStandardMessage', '', CallbackFunction, false, true, true, true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Message', _sMsg);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Icon', _iIcon);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Pulse', _iPulse);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicFloatProperty(PropertySet, 'Timeout', _displayTime);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'MessageID', _sId);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Team', _eBroadcastToTeams);

	QueueDynamicPopup(PropertySet, NewGameState);
}

simulated function CallStandardMessage(const out DynamicPropertySet PropertySet)
{
	GetMessenger().Message(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'Message'),
		EUIIcon(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Icon')),
		EUIPulse(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Pulse')),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicFloatProperty(PropertySet, 'Timeout'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'MessageID'),
		ETeam(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Team'))
	);
}

static function QueueAnchoredMessage(
	string    _sMsg,
	float    _xLoc,
	float    _yLoc,
	EUIAnchor _anchor,
	float     _displayTime = 5.0f,
	optional string    _sId = "",
	optional EUIIcon   _iIcon = eIcon_None,
	optional ETeam _eBroadcastToTeams = eTeam_None,
	optional delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction,
	optional XComGameState NewGameState)
{
	local DynamicPropertySet PropertySet;

	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAnchoredMessage', '', CallbackFunction, false, true, true, true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Message', _sMsg);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicFloatProperty(PropertySet, 'XLoc', _xLoc);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicFloatProperty(PropertySet, 'YLoc', _yLoc);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Anchor', _anchor);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicFloatProperty(PropertySet, 'Timeout', _displayTime);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'MessageID', _sId);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Icon', _iIcon);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'Team', _eBroadcastToTeams);

	QueueDynamicPopup(PropertySet, NewGameState);
}

simulated function CallAnchoredMessage(const out DynamicPropertySet PropertySet)
{
	GetAnchoredMessenger().Message(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'Message'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicFloatProperty(PropertySet, 'XLoc'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicFloatProperty(PropertySet, 'YLoc'),
		EUIAnchor(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Anchor')),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicFloatProperty(PropertySet, 'Timeout'),
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(PropertySet, 'MessageID'),
		EUIIcon(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Icon')),
		ETeam(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'Team'))
	);
}



event PreBeginPlay()
{
	super.PreBeginPlay();
	SubscribeToOnCleanupWorld();

	`ONLINEEVENTMGR.AddSystemMessageAddedDelegate(OnSystemMessageAdd);
	`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);

	SanitizeSystemMessages();
}

simulated function UINavigationHelp GetNavHelp()
{
	if (m_kNavHelpScreen != none)
		return m_kNavHelpScreen.NavHelp;
	return none;
}

event Destroyed()
{
	super.Destroyed();
	UnsubscribeFromOnCleanupWorld();
	Cleanup();
}

simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	Cleanup();
}

private simulated function Cleanup()
{
	local OnlineSubsystem OnlineSub;
	local OnlinePlayerInterface PlayerInterface;
	if( m_2DMovie != none && m_2DMovie.DialogBox != none )
		m_2DMovie.DialogBox.ClearDialogs();
	`ONLINEEVENTMGR.ClearSystemMessageAddedDelegate(OnSystemMessageAdd);
	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.ClearGameInviteCompleteDelegate(OnGameInviteComplete);
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSub != None )
	{
		PlayerInterface = OnlineSub.PlayerInterface;
		if( PlayerInterface != None )
		{
			PlayerInterface.ClearKeyboardInputDoneDelegate(OnVirtualKeyboardInputComplete);
		}
	}

	if(`XENGINE.m_kPhotoboothUITexture != none)
	{
		class'TextureRenderTarget2D'.static.Resize(`XENGINE.m_kPhotoboothUITexture, 2, 2);
	}
}

simulated function OnGameInviteAccepted(bool bWasSuccessful)
{
	local TProgressDialogData kDialogData;
	`log(`location @ `ShowVar(`ONLINEEVENTMGR.bInShellLoginSequence), true, 'XCom_Online');
	if ( !`ONLINEEVENTMGR.bInShellLoginSequence && bWasSuccessful)
	{
		// TTP#6750, the UI dialogs for the pause menu are accepting input still, need to kill the dialogs so the we dont exit to main menu, quit, etc. -tsmith 7.7.2012
		Get2DMovie().DialogBox.ClearDialogs();
		kDialogData.strTitle = `ONLINEEVENTMGR.m_sAcceptingGameInvitation;
		kDialogData.strDescription = `ONLINEEVENTMGR.m_sAcceptingGameInvitationBody;
		UIProgressDialog(kDialogData);
	}
}

simulated function OnGameInviteComplete(ESystemMessageType MessageType, bool bWasSuccessful)
{
	`log(`location @ `ShowVar(MessageType) @ `ShowVar(bWasSuccessful),,'XCom_Online');

	`log(`location @ "Checking success...",,'XCom_Online');
	if (!bWasSuccessful)
	{
		`log(`location @ "Closing Dialog ...",,'XCom_Online');
		UICloseProgressDialog();
	}
}

// Ugly bit of code so we can trigger messages from occurring when bypassing 'OnSystemMessageAdded' delegates.
simulated function ProcessSystemMessages()
{
	OnSystemMessageAdd("", "");
}
simulated function OnSystemMessageAdd(string sMessage, string sTitle)
{
	if(!m_bBlockSystemMessageDisplay)
	{
		`ONLINEEVENTMGR.ActivateAllSystemMessages();
	}
}

// Certain messages take precedent over others, and in the case of certain error messages, we just want to show the most important one and discard others.
// For example: We don't need to show "Connection to Xbox Live lost" message when you unplug the ethernet cable, we just need to show "Ethernet cable unplugged, multiplayer services disabled".
// This function serves as the entry point for filtering and sorting of error messages before they're displayed - sbatista 7/8/12
function SanitizeSystemMessages()
{
	local TDialogueBoxData kData;
	local XComOnlineEventMgr kOnlineEventMgr;

	// Do not mess with the system message queue if we're currently showing a system message, 
	// since the act of closing a system message dialog triggers a pop to occur and we don't want it to 
	// pop the wrong message - sbatista
	if(m_2DMovie != None && m_2DMovie.DialogBox != None && m_2DMovie.DialogBox.GetTopDialogBoxData(kData))
	{
		if(kData.xUserData.IsA('UICallbackData_SystemMessage'))
			return;
	}

	kOnlineEventMgr = `ONLINEEVENTMGR; // Just so I can has intellisence...

	if( kOnlineEventMgr.IsSystemMessageQueued(SystemMessage_QuitReasonLinkLost) )
	{
		// If we have both an ethernet disconect as well as connection to online service lost,
		// toss away the later one, since it doesn't matter you don't have connection to the internet
		// if you have no network connection - sbatista
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_LostConnection);
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_QuitReasonLostConnection);
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_QuitReasonOpponentDisconnected);
	}
	if( kOnlineEventMgr.IsSystemMessageQueued(SystemMessage_QuitReasonLogout) )
	{
		// If we signed out of an online profile then we will also get a lost connection message.
		// This message should be ignored as it is a side effect of the sign out.
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_LostConnection);
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_QuitReasonLostConnection);
	}
	if( kOnlineEventMgr.IsSystemMessageQueued(SystemMessage_GameFull) )
	{
		// For some reason we get an opponent disconnected message when attempting to join a full server. Nuke it - sbatista
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_QuitReasonOpponentDisconnected);
	}
	if( kOnlineEventMgr.IsSystemMessageQueued(SystemMessage_InviteServerVersionOlder) 
	  || kOnlineEventMgr.IsSystemMessageQueued(SystemMessage_InviteClientVersionOlder))
	{
		// For some reason we get an opponent disconnected message when attempting to join a full server. Nuke it - sbatista
		kOnlineEventMgr.RemoveAllSystemMessagesOfType(SystemMessage_QuitReasonOpponentDisconnected);
	}
}

simulated function HideUIForCinematics()
{
	ScreenStack.HideUIForCinematics();
}

simulated function ShowUIForCinematics()
{	
	ScreenStack.ShowUIForCinematics();
}

function SetNarrativeMgr( XGNarrative kNarrative )
{
	m_kNarrative = kNarrative;

	// Store the currently played narrative moments.  If the user restarts a mission, then this count will be restored.
	m_kNarrative.StoreNarrativeCounters();
}

//Called before rendering - avoids off by 1 errors
simulated function PreRender()
{
	UIUpdate();
}

/**
 * Called when the local player controller's m_eTeam variable has replicated.
 */
simulated function OnLocalPlayerTeamTypeReceived(ETeam eLocalPlayerTeam)
{
	// NOTE: assuming one player controller per game instance. i.e. no splitscreen. so the presentation is the same team as the local player -tsmith 
	SetTeamType(eLocalPlayerTeam);
}

/**
 * Callback setup for any UI screens needing to know about the Client Traveling
 */
function AddPreClientTravelDelegate( delegate<PreClientTravelDelegate> dOnPreClientTravel )
{
	if (m_PreClientTravelDelegates.Find(dOnPreClientTravel) == INDEX_None)
	{
		m_PreClientTravelDelegates[m_PreClientTravelDelegates.Length] = dOnPreClientTravel;
	}
}

function ClearPreClientTravelDelegate(delegate<PreClientTravelDelegate> dOnPreClientTravel)
{
	local int i;

	i = m_PreClientTravelDelegates.Find(dOnPreClientTravel);

	if (i != INDEX_None)
	{
		m_PreClientTravelDelegates.Remove(i, 1);
	}
}

/**
 * Called when the local player is about to travel to a new map or IP address.  Provides subclass with an opportunity
 * to perform cleanup or other tasks prior to the travel.
 */
simulated function PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel ) // Called from PlayerController ...
{
	local OnlineSubsystem OnlineSub;
	local OnlinePlayerInterface PlayerInterface;
	local delegate<PreClientTravelDelegate> dOnPreClientTravel;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(PendingURL) @ `ShowVar(TravelType) @ `ShowVar(bIsSeamlessTravel));

	foreach m_PreClientTravelDelegates(dOnPreClientTravel)
	{
		dOnPreClientTravel(PendingURL, TravelType, bIsSeamlessTravel);
	}

	if (!bIsSeamlessTravel) // Level will be destroyed!
	{
		// Cleanup any subsystem delegate references - or level will crash due to GC
		OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
		if( OnlineSub != None )
		{
			PlayerInterface = OnlineSub.PlayerInterface;
			if( PlayerInterface != None )
			{
				PlayerInterface.ClearKeyboardInputDoneDelegate(OnVirtualKeyboardInputComplete);
			}
		}
	}
}

//-----------------------------------------------------------
// UI Update 

//Called based on UI Update frequency 
simulated function UIUpdate()
{
	local int i;
	local delegate< UpdateCallback > dCallback;

	for( i=0; i<m_arrUIUpdateCallbacks.length; i++ )
	{
		dCallback = m_arrUIUpdateCallbacks[i];
		if (dCallback != none)
			dCallback();
	}
}


simulated function SubscribeToUIUpdate( delegate<UpdateCallback> fCallback )
{
	local int foundIndex; 

	foundIndex = m_arrUIUpdateCallbacks.Find( fCallback );

	if( foundIndex == -1 )
		m_arrUIUpdateCallbacks.AddItem( fCallback );
	else
		`log("Can not SubscribeToUIUpdate callback ("$fCallback$"); already found at m_arrUIUpdateCallbacks["$foundIndex$"].",,'uixcom');
}

simulated function UnsubscribeToUIUpdate( delegate<UpdateCallback> fCallback )
{
	local int foundIndex; 

	foundIndex = m_arrUIUpdateCallbacks.Find( fCallback );

	if( foundIndex == -1 )
		`log("Can not UnsubscribeToUIUpdate callback ("$fCallback$"); not found in m_arrUIUpdateCallbacks",,'uixcom');
	else
		m_arrUIUpdateCallbacks.RemoveItem(fCallback);
}

//-----------------------------------------------------------
simulated state BaseScreenState
{
//----------------------------------------------------
//Initialization
	simulated function InitState()
	{
		`log(GetStateName() @"InitState() call",,'uistate');
	}

//----------------------------------------------------
//Custom activation functions, intended to be overwritten by children
	simulated function Activate()       {};
	simulated function Deactivate()     {};
	simulated function OnReceiveFocus() {};
	simulated function OnLoseFocus()    {};

//----------------------------------------------------
//Stack Events
	simulated event PushedState()
	{
		InitState();
		Activate();
	}
	simulated event ContinuedState()
	{
		OnReceiveFocus();

		// If a state needs to do an operation that will alter the state stack during its deactivation, 
		// it will set this callback so that it can be done once it gets removed from the stack. - sbatista
		if(m_postStateChangeCallback != none)
		{
			m_postStateChangeCallback();
			m_postStateChangeCallback = none;
		}
	}	
	simulated event PausedState()
	{
		OnLoseFocus();
	}
	simulated event PoppedState()
	{
		Deactivate();
	}
	
//----------------------------------------------------
Begin: //DO NOT USE IN CHILD STATES
	//`log("BaseScreen.Begin for" @GetCurrentState(),,'uixcom');

//----------------------------------------------------
End: //DO NOT USE IN CHILD STATES
	//`log("BEWARE:" @ self @"is entering END label of state ("$ GetCurrentState() $").",,'uixcom');

//----------------------------------------------------
/*simulated state ExampleScreenState extends BaseScreenState
{
	simulated function Activate()
	{
		//SPAWN memberScreen HERE
		//Find any relevant game data that needs to go to the init
		//INIT memberScreen HERE w/ relevant game data
	}
	simulated function Deactivate()
	{
		//Any game code that needs to happen on close
		//Should call GetUIMgr().Pop( memberScreen );
	}
	simulated function OnReceiveFocus() 
	{
		//Notify memberScreen of received focus HERE
		//memberScreen.OnReceiveFocus();
	}
	simulated function OnLoseFocus()
	{
		//Notify memberScreen of lost focus HERE
		//memberScreen.OnLoseFocus();
	}
}*/
} //END BaseScreenState 
//----------------------------------------------------

simulated state TentPoleScreenState extends BaseScreenState
{
	simulated function Activate() 
	{
		Get2DMovie().RaiseInputGate();  // non-ui screen system handles input
		`HQGAME.PlayerController.myHUD.bShowHUD = false;
	}

	simulated function Deactivate()	
	{
		`HQGAME.PlayerController.myHUD.bShowHUD = true;
		Get2DMovie().LowerInputGate();
	}
};

//-----------------------------------------------------------
// Called from the Interface Manager after it's done loading.
simulated function InitUIScreens() 
{
	// NO narrative manager in multiplayer games! -tsmith 
	if(WorldInfo.NetMode == NM_Standalone && m_kNarrativeUIMgr == none)
		m_kNarrativeUIMgr = new(self) class'UINarrativeMgr'; 
	
	
	if( m_kTooltipMgr == none )
	{
		m_kTooltipMgr = Spawn(class'UITooltipMgr', self );
		m_kTooltipMgr.InitScreen(XComPlayerController(Owner), Get2DMovie());
		Get2DMovie().LoadScreen(m_kTooltipMgr);
	}
	if( !WorldInfo.IsConsoleBuild() )
	{	
		if( m_kUIMouseCursor == none )
		{
			// Mouse Cursor does not need to be on the Stack
			m_kUIMouseCursor = Spawn(class'UIMouseCursor', self );
			m_kUIMouseCursor.InitScreen(XComPlayerController(Owner), Get2DMovie());
			Get2DMovie().LoadScreen(m_kUIMouseCursor);
		}
	}

	if( m_kEventNotices == none )
	{
		m_kEventNotices = Spawn(class'UIEventNotices', self);
		m_kEventNotices.InitScreen(XComPlayerController(Owner), Get2DMovie());
		Get2DMovie().LoadScreen(m_kEventNotices);
		ScreenStack.Push(m_kEventNotices);
		m_kEventNotices.Hide();
	}

	if( m_kTutorialHelper == none && `TACTICALGRI != none && `REPLAY.bInTutorial )
	{
		m_kTutorialHelper = Spawn(class'UITutorialHelper', self);
		m_kTutorialHelper.InitScreen(XComPlayerController(Owner), Get2DMovie());
		Get2DMovie().LoadScreen(m_kTutorialHelper);
	}

	if( m_kDebugInfo == none )
	{
		m_kDebugInfo = Spawn(class'UIDebugInfo', self);
		m_kDebugInfo.InitScreen(XComPlayerController(Owner), Get2DMovie());
		Get2DMovie().LoadScreen(m_kDebugInfo);
	}
}
simulated function UpdateStrategyMapVisuals()
{
	//local UIStrategyMap StrategyMap;
	
//	StrategyMap = UIStrategyMap(ScreenStack.GetScreen(class'UIStrategyMap'));
	//TODO: bsteiner StrategyMap.UpdateVisuals();
	//todo StrategyMap.ClearUIMapRef(StrategyMap2D);
}

simulated function OnMovieInitialized()
{
	MoviesInited++;
	// Initialize initial user interface screen.
	if(MoviesInited == 3)
		InitUIScreens();
}

simulated function Init3DUIScreens()
{
	//May be overwritten in child classes
}

simulated function Update() {}

simulated function bool GetMouseCoords(out Vector2D vMouseCoords)
{
	if(m_kUIMouseCursor != none && !m_kUIMouseCursor.bIsInDefaultLocation)
	{
		vMouseCoords = m_kUIMouseCursor.m_v2MouseLoc;
		return true;
	}
	return false;
}

reliable client function bool UIPreloadNarrative( XComNarrativeMoment Moment )
{
	local name nmConversation;

	if (Moment == none)
		return false;

	//`log("NARRATIVE::UINarrative: CurrentState="$GetStateName(),,'xcomui');

	if(GetNarrativeConversation( nmConversation, Moment, true ))
	{
		if(WorldInfo.NetMode == NM_Standalone && m_kNarrativeUIMgr == none)
		{
			m_kNarrativeUIMgr = new(self) class'UINarrativeMgr'; 
		}

		if(m_kNarrativeUIMgr != none)
		{
			m_kNarrativeUIMgr.PreloadConversation(nmConversation, Moment);
		}

		return true;
	}

	return false;
}

//-----------------------------------------------------------
// Narrative Popus
reliable client function bool UINarrative( XComNarrativeMoment Moment, optional Actor kFocusActor, optional delegate<OnNarrativeCompleteCallback> InNarrativeCompleteCallback, optional delegate<PreRemoteEventCallback> InPreRemoteEventCallback, optional vector vOffset, optional bool bUISound, optional bool bFirstRunOnly, optional float FadeSpeed=0.5 )
{
	local name nmConversation;

	if (Moment == none)
	{
		`log("UINarrative called with none Moment",,'XComNarrative');
		return false;
	}

	`log("NARRATIVE::UINarrative: CurrentState="$GetStateName(),,'XComNarrative');

	if(WorldInfo.NetMode == NM_Standalone && m_kNarrativeUIMgr == none)
	{
		m_kNarrativeUIMgr = new(self) class'UINarrativeMgr'; 
	}

	if(m_kNarrativeUIMgr != none)
	{
		if( Moment.PlayAllConversationsInOrder )
		{
			foreach Moment.arrConversations(nmConversation)
			{
				// restrict the callbacks to only the final conversation line
				if( nmConversation == Moment.arrConversations[Moment.arrConversations.Length-1] )
				{
					if( !m_kNarrativeUIMgr.AddConversation(nmConversation, InNarrativeCompleteCallback, InPreRemoteEventCallback, Moment, kFocusActor, vOffset, bUISound, FadeSpeed) )
					{
						return true;
					}
				}
				else
				{
					if( !m_kNarrativeUIMgr.AddConversation(nmConversation, None, None, Moment, kFocusActor, vOffset, bUISound, FadeSpeed) )
					{
						return true;
					}
				}
			}
		}
		else if( GetNarrativeConversation(nmConversation, Moment) )
		{
			if( !m_kNarrativeUIMgr.AddConversation(nmConversation, InNarrativeCompleteCallback, InPreRemoteEventCallback, Moment, kFocusActor, vOffset, bUISound, FadeSpeed) )
			{
				// Still return true, even though we didn't successfully find the VO otherwise we may impact gameplay events
				// (ex .Unlocking Hangar after first contact)
				return true;
			}
		}

		Moment.bFirstRunOnly = bFirstRunOnly;

		CheckNarrative();

		return true;
	}

	return false;
}

reliable client function bool CheckNarrative()
{
	//`log("NARRATIVE::CheckNarrative",,'xcomui');
	//PrintScreenStack();

	//if( m_kNarrativeUIMgr.IsDone() && m_arrNarrativeMoments.Length > 0 && 
	//	!IsInState('State_UINarrative') && !IsInState('State_UIItemUnlock'))
	if( //m_arrNarrativeMoments.Length > 0 && 
		!IsInState('State_UINarrative') 
		&& !IsInState('State_UIItemUnlock'))
	{
		//`log("NARRATIVE::CREATE m_kNarrativePopup",,'xcomui');
		m_kNarrativeUIMgr.CheckForNextConversation();
//		m_arrNarrativeMoments.Length = 0;

		return true;
	}
	return false;
}
/*
simulated state State_UINarrative extends BaseScreenState
{
	simulated function Activate()
	{
		m_kNarrativePopup = Spawn( class'UINarrativePopup', self );
		m_kNarrativePopup.Init( XComPlayerController(Owner), Get2DMovie(), m_kNarrativeUIMgr);
	
		Get2DMovie().LoadScreen( m_kNarrativePopup );
	}

	simulated function Deactivate()
	{
		ScreenStack.Pop( m_kNarrativePopup );	
		m_kNarrativePopup = none;
	}

	simulated function OnReceiveFocus() { m_kNarrativePopup.OnReceiveFocus();	}
	simulated function OnLoseFocus()	{ m_kNarrativePopup.OnLoseFocus();	}


}
{
	TempScreen = Spawn( class'UINarrativePopup', self );
	UINarrativePopup(TempScreen).m_kNarrativeMgr = m_kNarrativeUIMgr; 	
	ScreenStack.Push( TempScreen );
}*/



// jboswell: this is here because the load screen only has access to stuff in the XComGame package,
// but the functionality for this method is in XComHQPresentationLayer
//reliable client function bool UINarrative3D(ENarrativeMoment Narrative, optional Actor FocusActor, optional delegate<OnNarrativeCompleteCallback> InNarrativeCompleteCallback);

// This is here because the pause menu for HQ needs to have this function to call the XCOM Database. Ryan Baker
reliable client function UITellMeMore();

simulated function UIInvitationsMenu()
{
	local OnlineSubsystem OnlineSub;
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	OnlineSub.GameInterface.ShowReceivedInviteUI(`ONLINEEVENTMGR.LocalUserIndex);
}

// The base functionality will take the player to the main MP Shell, which will handle the rest of the work from there,
// if already in the MP Shell with a different Presentation Layer, this should then handle opening the correct menus.
simulated function StartMPShellState() 
{
    if( !WorldInfo.Game.IsA('XComMPShell') )
	{
		ConsoleCommand("open XComShell_Multiplayer.umap?Game=XComGame.XComMPShell");
	}
}

//-----------------------------------------------------------
// Unlock Item Popups
reliable client function UIItemUnlock(TItemUnlock kUnlock)
{
	local TDialogueBoxData kData;

	kData.strTitle  = kUnlock.strTitle;
	kData.strText   = kUnlock.strName $ "<br><br>" $ kUnlock.strDescription $ "<br><br>" $ kUnlock.strHelp;
	kData.sndIn     = kUnlock.sndFanfare;

	if( kUnlock.eItemUnlocked != eItem_NONE)
		kData.strImagePath = class'UIUtilities_Image'.static.GetItemImagePath( kUnlock.eItemUnlocked );
	else if ( kUnlock.eUnlockImage != eImage_None)	
	{
		if ( kUnlock.bFoundryProject )
			kData.strImagePath = class'UIUtilities_Image'.static.GetFoundryImagePath( kUnlock.eUnlockImage );
		else
			kData.strImagePath = class'UIUtilities_Image'.static.GetStrategyImagePath( kUnlock.eUnlockImage );
	}

	UIRaiseDialog( kData );
}

//-----------------------------------------------------------
reliable client function bool UIKeyboard( string sTitle, string sDefaultText, delegate<delActionAccept> del_OnAccept, delegate<delActionCancel> del_OnCancel, bool bValidateText, optional int maxCharLimit = 256)
{
	local bool bLaunchSuccess;
	local OnlineSubsystem OnlineSub;
	local OnlinePlayerInterface PlayerInterface;

	bLaunchSuccess = false;
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSub != none && `ISCONTROLLERACTIVE == false )
	{
		PlayerInterface = OnlineSub.PlayerInterface;
		if( PlayerInterface != none )
		{
			delActionAccept = del_OnAccept;
			delActionCancel = del_OnCancel;
			PlayerInterface.AddKeyboardInputDoneDelegate(OnVirtualKeyboardInputComplete);
			`log("++++++++ UIKeyboard: default text: " $sDefaultText);
			bLaunchSuccess = PlayerInterface.ShowKeyboardUI(`ONLINEEVENTMGR.LocalUserIndex, sTitle, sTitle, false, bValidateText, sDefaultText, maxCharLimit);
			
			if( !bLaunchSuccess )
			{
				PlayerInterface.ClearKeyboardInputDoneDelegate(OnVirtualKeyboardInputComplete);
			}
		}
	}

	// For now, fall back to the GFX Virtual Keyboard if the platform one failed.
	if( !bLaunchSuccess && WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		// Don't fall back to the 360 virtual keyboard, as it probably failed for a 
		// reason (i.e. not connected to LIVE) and we need the connection for the 
		// verification process. -ttalley
		return false;
	}
	else if( !bLaunchSuccess )
	{
		m_VirtualKeyboard = Spawn( class'UIVirtualKeyboard', self );
		m_VirtualKeyboard.delActionAccept = del_OnAccept; 	
		m_VirtualKeyboard.delActionCancel = del_OnCancel; 	
		ScreenStack.Push( m_VirtualKeyboard );

		m_VirtualKeyboard.SetTitle( sTitle );
		m_VirtualKeyboard.SetDefaultText( sDefaultText );
	
	}
	return true;
}


//-------------------------------------------------------------------
reliable client function UIDifficulty( bool bInGame = false )
{
	local UIMovie TargetMovie;

	//Turning off 3D shell option for now, as the soldier model covers up the second wave options. 
	TargetMovie = XComShellPresentationLayer(self) == none ? Get2DMovie() : Get3DMovie();
	//TargetMovie = Get2DMovie();

	m_bIsPlayingGame = bInGame;
	if(m_kControllerMap == none)
	{
		TempScreen = Spawn( class'UIShellDifficulty', self  );
		UIShellDifficulty(TempScreen).m_bIsPlayingGame = bInGame; 

		ScreenStack.Push( TempScreen, TargetMovie );
	}
}

//-------------------------------------------------------------------

reliable client function UISecondWave( bool bInGame = false )
{
	TempScreen = Spawn( class'UISecondWave', self );
	UISecondWave(TempScreen).m_bViewOnly = bInGame;
	ScreenStack.Push( TempScreen );
}

reliable client function UITutorialBox(string Title, string Desc, string ImagePath, optional string ButtonHelp = "")
{
	TempScreen = Spawn(class'UITutorialBox', self);
	UITutorialBox(TempScreen).Title = Title;
	UITutorialBox(TempScreen).Desc = Desc;
	UITutorialBox(TempScreen).ImagePath = ImagePath; 
	UITutorialBox(TempScreen).ButtonHelp = ButtonHelp;
	TempScreen.AllowShowDuringCinematic(true);

	ScreenStack.Push(TempScreen);
}

simulated private function OnVirtualKeyboardInputComplete(bool bWasSuccessful)
{
	local string sUserInput;
	local byte bWasCanceled, bContainedUnfriendlyText;
	local OnlineSubsystem OnlineSub;
	local OnlinePlayerInterface PlayerInterface;

	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSub != None )
	{
		PlayerInterface = OnlineSub.PlayerInterface;
		if( PlayerInterface != None )
		{
			// BUG #7300 - Players do not receive an error message after attempting to enter an inappropriate unit name in multiplayer.
			PlayerInterface.ClearKeyboardInputDoneDelegate(OnVirtualKeyboardInputComplete);
			sUserInput = PlayerInterface.GetKeyboardInputResults(bWasCanceled, bContainedUnfriendlyText);
			`log( self $ "::" $ GetFuncName() @ `ShowVar(sUserInput) @ `ShowVar(bWasSuccessful) @ `ShowVar(bWasCanceled));
			if( bWasCanceled != 0 )
			{
				delActionCancel();
			}
			else if( bContainedUnfriendlyText != 0 )
			{
				ShowUnfriendlyTextWarningDialog();
				delActionCancel();
			}
			else
			{
				if ( sUserInput != "" )
				{
					delActionAccept(sUserInput, bWasSuccessful);
				}
				else
				{
					`log("OnVirtualKeyboardInputComplete - TODO: Player attempted to clear information");
					delActionCancel();
				}
			}
		}
	}

	delActionAccept = none;
	delActionCancel = none;
}

simulated function ShowUnfriendlyTextWarningDialog()
{
	local TDialogueBoxData kData;

	kData.eType     = eDialog_Warning;
	kData.strTitle  = m_strPlayerEnteredUnfriendlyTitle;
	kData.strText   = m_strPlayerEnteredUnfriendlyText;
	kData.strAccept = m_strOK;

	UIRaiseDialog( kData );
}

simulated state State_VirtualKeyboard extends BaseScreenState
{
	simulated function Activate()
	{
		Get2DMovie().LoadScreen( m_VirtualKeyboard );
	}
	simulated function Deactivate()
	{
		ScreenStack.Pop(m_VirtualKeyboard);
		m_VirtualKeyboard = none;
	}
	simulated function OnReceiveFocus() 
	{
		//`log( GetStateName() @"ContinuedState event",,'uixcom');
		m_VirtualKeyboard.OnReceiveFocus();
	}
	simulated function OnLoseFocus()
	{
		//`log( GetStateName() @"PausedState event",,'uixcom');
		m_VirtualKeyboard.OnLoseFocus();
	}
}

// Helper dialog box function that can be used to help track down issues.
simulated function PopupDebugDialog(string strTitle, optional string strMessage)
{
`if (`notdefined(FINAL_RELEASE))
	local TDialogueBoxData kData;
	kData.eType     = eDialog_Warning;
	kData.strTitle  = strTitle;
	kData.strText   = strMessage;
	kData.isModal   = true;
	UIRaiseDialog( kData );
`endif
}

`if(`notdefined(FINAL_RELEASE))
simulated function PopupAssertDialog(string strEvalExpression, Name kFunctionName, string strScriptTrace)
{
	local string strTitle;
	local string strPrettyPleaseMessage;
	local string strMessage;

	strTitle = "Assert failed in function: " $ kFunctionName;
	strPrettyPleaseMessage = class'UIUtilities_Input'.static.InsertGamepadIcons("(Please show this to an engineer if possible. A copy-paste friendly version of this assert has been dumped to the log output. %X skips further asserts on this level.)");
	strMessage = "Failed statement: " $ strEvalExpression $ "\n" $ strScriptTrace;

	// always log the assert, even if the user has opted not to see any further assert popups
	`log("=====ASSERT FAILED=====");
	`log(strTitle);
	`log(strMessage);
		
	if(!m_bSkipAsserts)
	{
		// popup a big annoying dialog so people notice an assert tripped and get an engineer
		PopupDebugDialog(strTitle, strPrettyPleaseMessage $ "\n\n" $ Left(strMessage, 600));
	}
}
`endif

simulated function ShowMultiplayerLoadoutWarningDialog( string str )
{
	local TDialogueBoxData kData;

	kData.eType     = eDialog_Warning;
	kData.strText   = str;
	kData.strAccept = m_strOK;

	UIRaiseDialog( kData );
}

simulated function UIRaiseDialog( TDialogueBoxData kData )
{
	m_2DMovie.DialogBox.AddDialog( kData );
}

simulated function UITLEUnitStats(array<XComGameState_Unit> unitArray, int startindex, XComGameState CheckGameState)
{
	local UITLEUnitStats UnitStatsScreen;

	UnitStatsScreen = Spawn(class'UITLEUnitStats', self);
	ScreenStack.Push(UnitStatsScreen, Get2DMovie());

	UnitStatsScreen.m_UnitArray = unitArray;
	UnitStatsScreen.m_CheckGameState = CheckGameState;
	UnitStatsScreen.m_CurrentIndex = startindex;
	UnitStatsScreen.UpdateData(unitArray[startindex], CheckGameState);
}

simulated function UITLELadderMedalProgressScreen()
{
	local UITLELadderMedalProgressScreen LadderMedalProgressScreen;

	LadderMedalProgressScreen = Spawn(class'UITLELadderMedalProgressScreen', self);
	ScreenStack.Push(LadderMedalProgressScreen, Get2DMovie());
}

simulated function UITLE_LadderDifficulty()
{
	local UITLE_LadderDifficulty difficultyScreen;

	difficultyScreen = Spawn(class'UITLE_LadderDifficulty', self);
	ScreenStack.Push(difficultyScreen, Get2DMovie());
}

simulated function bool UIIsShowingDialog()
{
	return m_2DMovie.DialogBox.ShowingDialog();
}

// HAX: This is a safe way for screens that are interested in knowing when the dialog box has finished processing its m_arrData.
// IMPORTANT: DON'T FORGET TO ASSIGN THIS TO 'NONE' WHEN YOUR OBJECT GETS REMOVED!
simulated function UISetDialogBoxClosedDelegate(delegate<delNoParams> del)
{
	m_2DMovie.DialogBox.m_fnClosedCallback = del;
}

simulated function UIProgressDialog(TProgressDialogData kData) 
{
	`log("XComPresentationLayerBase::UIProgressDialog()",,'uixcom');
	//ScriptTrace(); 
	if (m_kProgressDialogStatus == eProgressDialog_None)
	{
		m_kProgressDialogStatus = eProgressDialog_Opening;
		m_kProgressDialogData = kData;

		TempScreen = Spawn( class'UIProgressDialogue', self );
		UIProgressDialogue(TempScreen).m_kData = m_kProgressDialogData; 	
		ScreenStack.Push( TempScreen );

		PushState('State_ProgressDialog');
	}
	else
	{
		`warn(`location @ "Attempting to call UIProgressDialog while the Status is in state: '"$m_kProgressDialogStatus$"'");
	}
}
simulated state State_ProgressDialog extends BaseScreenState
{
	simulated function UIProgressDialog(TProgressDialogData kData)
	{
		Get2DMovie().PrintCurrentScreens();
		`warn(`location @ "Attempting to call UIProgressDialog while the Status is in state: '"$m_kProgressDialogStatus$"'");
	}

	simulated function Activate()
	{
		`log("State_ProgressDialog::Activate()",,'uixcom');
		m_kProgressDialogStatus = eProgressDialog_Showing;	
	}

	simulated function Deactivate()
	{
		`log("State_ProgressDialog::Deactivate()",,'uixcom');
		//ScreenStack.Pop(m_kProgressDialog); 
		m_kProgressDialog = none;
		m_kProgressDialogStatus = eProgressDialog_None;
		`ONLINEEVENTMGR.ActivateAllSystemMessages(); // HACK: Fire off system messages since they may have been closed by this progress dialog. -ttalley
	}

	simulated function OnReceiveFocus() {   m_kProgressDialog.OnReceiveFocus();  }
	simulated function OnLoseFocus()    {   m_kProgressDialog.OnLoseFocus();     }	

	simulated function UICloseProgressDialog()
	{
		//ScriptTrace();
		if (m_kProgressDialogStatus == eProgressDialog_Showing)
		{
			m_kProgressDialogStatus = eProgressDialog_Closing;
			PopState();
			ScreenStack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);
		}
		else
		{
			`warn(`location @ "Attempting to call UICloseProgressDialog while the Status is in state: '"$m_kProgressDialogStatus$"'");
		}
	}
}

simulated function UICloseProgressDialog()
{
	`log(`location @ "Not currently in State_ProgressDialog.");
}

simulated function UIControllerUnplugDialog(int ControllerId, optional bool bInOptionsScreen=false) 
{
	local UIMovie_2d InterfaceMgr;
	local int ControllerNum; // User friendly controller number

	m_kControllerUnplugDialogData.fnCallback = None;

	if( m_kControllerUnplugDialog == none )
	{
		m_kControllerUnplugDialogData.strTitle = ""; 

		ControllerNum = ControllerId + 1;
		if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
			m_kControllerUnplugDialogData.strDescription = Repl(m_strPleaseReconnectControllerPS3, "%CONTROLLER_NUM", ControllerNum);
		else if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
			m_kControllerUnplugDialogData.strDescription = Repl(m_strPleaseReconnectController, "%CONTROLLER_NUM", ControllerNum);
		else
			m_kControllerUnplugDialogData.strDescription = m_strPleaseReconnectControllerPC;

		InterfaceMgr = Get2DMovie();
		InterfaceMgr.PushForceShowUI();
	
		m_kControllerUnplugDialog = Spawn( class'UIReconnectController', self );
		m_kControllerUnplugDialog.m_kData = m_kControllerUnplugDialogData; 	
		m_kControllerUnplugDialog.m_bOnOptionsScreen = bInOptionsScreen; 	
		ScreenStack.Push( m_kControllerUnplugDialog, GetModalMovie());
		
		PushState('State_ProgressDialog');
	}
}

simulated function bool IsShowingReconnectControllerDialog()
{
	return (m_kControllerUnplugDialog != none);
}

simulated function UICloseControllerUnplugDialog()
{
	local UIMovie_2D InterfaceMgr;

	if( m_kControllerUnplugDialog != none )
	{
		InterfaceMgr = Get2DMovie();
		InterfaceMgr.PopForceShowUI();
		ScreenStack.Pop( m_kControllerUnplugDialog );
		m_kControllerUnplugDialog = none;
	}
	if (ScreenStack.IsInStack(class'UIOptionsPCScreen'))
	{
		UIOptionsPCScreen(ScreenStack.GetScreen(class'UIOptionsPCScreen')).RefreshConnectedControllers();
	}
}

simulated function UIInputDialog(TInputDialogData kData) 
{
	TempScreen = Spawn( class'UIInputDialogue', self );
	UIInputDialogue(TempScreen).m_kData = kData;
	ScreenStack.Push( TempScreen, GetModalMovie() );
}

simulated function HandleInvalidStorage(string SelectStoragePrompt, delegate<delAfterStorageDeviceCallbackSuccess> delSuccessCallback)
{
	if( !`ONLINEEVENTMGR.bHasLogin )
	{
		if( WorldInfo.IsConsoleBuild() )
			ShowSaveWarningDialog(class'XComOnlineEventMgr'.default.m_sLoginWarning);
		else
			ShowSaveWarningDialog(class'XComOnlineEventMgr'.default.m_sLoginWarningPC);
	}
	else
	{
		delAfterStorageDeviceCallbackSuccess = delSuccessCallback; 
		ShowStorageDevicePrompt(SelectStoragePrompt);
	}
}

simulated function ShowSaveWarningDialog(string sWarningText)
{
	local TDialogueBoxData kData;

	kData.eType     = eDialog_Warning;
	kData.strTitle  = m_strSaveWarning;
	kData.strText   = sWarningText;
	kData.strAccept = m_strOK;
	kData.fnCallback = WarningAcknowledged; 

	UIRaiseDialog( kData );
}

 simulated function WarningAcknowledged(Name eAction)
{	
	//Need to clear out the save screen underneath else we get stuck in an empty save screen state if the warning took over. 
	if( ScreenStack.IsCurrentScreen('UISaveGame') || ScreenStack.IsCurrentScreen('UILoadGame') )
		ScreenStack.Pop(ScreenStack.GetCurrentScreen()); // HAX: Bad code, don't do this unless you know what you're doing.
}

simulated function ShowStorageDevicePrompt(string sPromptText)
{
	local TDialogueBoxData kData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		// Show the storage device prompt on platforms that support a device selector
		kData.eType     = eDialog_Warning;
		kData.strText   = sPromptText;
		kData.strAccept = m_strOK;
		kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		kData.fnCallback = ShowStorageDevicePromptCallback; 

		UIRaiseDialog( kData );
	}
	else
	{
		// This is all we can do on platforms that don't support a device selector.
		ShowSaveWarningDialog(class'XComOnlineEventMgr'.default.m_sNoStorageDeviceSelectedWarning);
	}
}
simulated private function ShowStorageDevicePromptCallback(Name eAction)
{
	local XComOnlineEventMgr OnlineEventMgr;
	OnlineEventMgr = `ONLINEEVENTMGR;

	if( eAction == 'eUIAction_Accept' )
	{
		OnlineEventMgr.OnlineSub.PlayerInterfaceEx.AddDeviceSelectionDoneDelegate( OnlineEventMgr.LocalUserIndex, OnCloseOSStorageDevicePromptCallback );
		OnlineEventMgr.SelectStorageDevice();
	}
}

function OnCloseOSStorageDevicePromptCallback(bool bWasSuccessful)
{
	local XComOnlineEventMgr OnlineEventMgr;
	OnlineEventMgr = `ONLINEEVENTMGR;

	OnlineEventMgr.OnlineSub.PlayerInterfaceEx.ClearDeviceSelectionDoneDelegate(OnlineEventMgr.LocalUserIndex, OnCloseOSStorageDevicePromptCallback );
	if( bWasSuccessful && `ONLINEEVENTMGR.HasValidLoginAndStorage() && delAfterStorageDeviceCallbackSuccess != none)
	{
		//Now that we've logged in, push us back in to the save game ui to actually make a save
		delAfterStorageDeviceCallbackSuccess();
		delAfterStorageDeviceCallbackSuccess = none; 
	}
}

function bool PlayerCanSave()
{
	return true;
}

simulated function UISaveScreen() 
{
	local UIMovie TargetMovie;

	TargetMovie = XComShellPresentationLayer(self) == none ? Get2DMovie() : Get3DMovie();

	if( `ONLINEEVENTMGR.HasValidLoginAndStorage() )
	{
		ScreenStack.Push(  Spawn( class'UISaveGame', self ), TargetMovie );
	}
	else
	{
		HandleInvalidStorage(m_strSelectSaveDeviceForSavePrompt, UISaveScreen);
		// Failed to enter state
	}
}

simulated function UILoadScreen()
{
	local UIMovie TargetMovie;

	TargetMovie = XComShellPresentationLayer(self) == none ? Get2DMovie() : Get3DMovie();

	if( `ONLINEEVENTMGR.HasValidLoginAndStorage() )
	{
		ScreenStack.Push(  Spawn( class'UILoadGame', self ), TargetMovie );
	}
	else
	{
		HandleInvalidStorage(m_strSelectSaveDeviceForLoadPrompt, UILoadScreen);
		 // Failed to enter state
	}
}

//-------------------------------------------------------------------

simulated function UILoadAnimation(bool bShow)
{
	if( bShow )
	{
		if (m_kLoadAnimation == none )
		{
			// Note this is just an animation, and does not use the screen stack navigation system. 
			m_kLoadAnimation = Spawn( class'UILoadScreenAnimation', self );
			m_kLoadAnimation.InitScreen( XComPlayerController(Owner), GetModalMovie() );
			GetModalMovie().LoadScreen( m_kLoadAnimation );
		}
	}
	else
	{
		if( m_kLoadAnimation != none )
		{
			// Note this is just an animation, and does not use the screen stack navigation system. 
			GetModalMovie().RemoveScreen( m_kLoadAnimation );	
			m_kLoadAnimation = none;
		}
	}
}

// Override in derived classes.
simulated function bool IsBusy()
{
	return false;
}

simulated function UIEndGame();

simulated function UIShutdownOnlineGame()
{
	local TProgressDialogData kData;
	if (! IsInState('State_ProgressDialog') )
	{
		kData.strTitle = m_strShutdownOnlineGame;
		UIProgressDialog(kData);
	}
}

function bool StartNetworkGame(name SessionName, optional string ResolvedURL="");

//TODO: this needs to work in the shell pres layer also. -bsteiner 
simulated function UIControllerMap() 
{
	local UIStrategyMap StrategyMap;
	
	TempScreen = Spawn( class'UIControllerMap', self );
	StrategyMap = UIStrategyMap(ScreenStack.GetScreen(class'UIStrategyMap'));
	if (StrategyMap != none )
	{
		UIControllerMap(TempScreen).layout = eLayout_Geoscape;
	}
	else
	{
		UIControllerMap(TempScreen).layout = (m_eUIMode == eUIMode_Strategy) ? eLayout_MissionControl : eLayout_Battlescape; 
	}

	ScreenStack.Push( TempScreen );
} 

simulated function UIPauseMenu( optional bool bAllowCinematicMode, optional bool bDisallowSaving )
{		
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	// Don't let the pause menu sneak in if the basic UI elements in the pres aren't ready 
	
	// Don't raise the pause menu when the InputGate is raised.  You can't get out of the PauseMenu since no input is allowed.  -dwuenschell
	if( ScreenStack != none && ScreenStack.IsInputBlocked ) return;

	// Let gameplay figure out if it should block.
	if( XComPlayerController(Owner).ShouldBlockPauseMenu() && !bAllowCinematicMode ) return;

	History = `XCOMHISTORY;

	//See if we are in a campaign, and if we are, if ironman is enabled
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
	{
		m_bIsIronman = CampaignSettingsStateObject.bIronmanEnabled;
	}
		
	m_bDisallowSaving = bDisallowSaving;

	TempScreen = Spawn( class'UIPauseMenu', self );
	UIPauseMenu(TempScreen).m_bIsIronman = m_bIsIronman;
	UIPauseMenu(TempScreen).m_bAllowSaving = AllowSaving(); 	
	ScreenStack.Push( TempScreen );
}

simulated function bool IsPauseMenuRaised() { return (ScreenStack.GetScreen(class'UIPauseMenu') != none); }

simulated function bool IsDialogBoxShown()
{
	return( Get2DMovie() != none && Get2DMovie().DialogBox != none && Get2DMovie().DialogBox.ShowingDialog() );
}

simulated function bool IsTutorialBoxShown()
{
	return(ScreenStack != none && ScreenStack.GetScreen(class'UITutorialBox') != none);
}

simulated function OnPauseMenu(bool bOpened);

// This is overridden in Headquarters Pres - Ryan Baker
simulated function bool AllowSaving()
{
	local XComOnlineEventMgr EventMgr;
	local bool IsTutorial;
	local Camera kCamera;
	local bool bFading;
	local X2GameRuleset Ruleset;

	if( m_bDisallowSaving )
	{
		return false;
	}

	Ruleset = `GAMERULES;
	if( !Ruleset.IsSavingAllowed() )
	{
		return false;
	}

	EventMgr = `ONLINEEVENTMGR;
	if( !EventMgr.HasValidLoginAndStorage() ||
		EventMgr.SaveInProgress() ||
		EventMgr.bUpdateSaveListInProgress ||
		EventMgr.bIsChallengeModeGame )
	{
		return false;
	}

	IsTutorial = (`TACTICALGRI != none && `TUTORIAL != none);
	if( IsTutorial )
	{
		return false;
	}

	kCamera = GetALocalPlayerController().PlayerCamera;
	bFading = kCamera.bEnableFading && kCamera.FadeAmount > 0.0;
	if( bFading )
	{
		return false;
	}

	if(IsInState('State_MissionSummary', true))
	{
		return false;
	}

	return true;
}

// This is overridden in Headquarters Pres - Ryan Baker
simulated function bool ISCONTROLLED()
{
	if (`BATTLE != none && `BATTLE.m_kDesc.m_bIsTutorial)
	{
		return true;
	}

	return false;
}

//-------------------------------------------------------------------

simulated function UIKeybindingsPCScreen() 
{
	local UIMovie TargetMovie;
	TargetMovie = XComShellPresentationLayer(self) == none ? Get2DMovie() : Get3DMovie();

	`assert(ScreenStack.GetScreen(class'UIKeybindingsPCScreen') == none);
	
	ScreenStack.Push( Spawn( class'UIKeybindingsPCScreen', self ), TargetMovie );
}

//-------------------------------------------------------------------

// Override this function if UI elements that list key bindinds shortcuts need to be updated.
simulated function UpdateShortcutText()
{
	`log("Keybindings were altered, UpdateShortcutText called",,'uixcom');
}

//-------------------------------------------------------------------

simulated function UIPCOptions( optional bool bIn3D = false ) 
{
	ScreenStack.Push( Spawn( class'UIOptionsPCScreen', self ), Get2DMovie());
}

simulated function bool IsPCOptionsRaised() { return (ScreenStack.GetScreen(class'UIOptionsPCScreen') != none); }

simulated function UIChallengeLeaderboard(optional bool bIn3D = false)
{
	local UIChallengeLeaderboards challengeLeaderboard;
	challengeLeaderboard = Spawn(class'UIChallengeLeaderboards', self);
	//challengeLeaderboard.InitScreen(XComPlayerController(Owner), Get2DMovie());
	challengeLeaderboard.LibID = 'ChallengeLeaderboardScreen';
	ScreenStack.Push(challengeLeaderboard, Get2DMovie());
}
//-------------------------------------------------------------------
reliable client function UICredits( bool isGameOver )
{
	TempScreen = Spawn( class'UICredits', self );
	UICredits(TempScreen).m_bGameOver = isGameOver;
	ScreenStack.Push( TempScreen );
}

//-------------------------------------------------------------------
simulated function XComCharacterCustomization GetCustomizeManager()
{
	return m_kCustomizeManager;
}

simulated function InitializeCustomizeManager(optional XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	local UIArmory TopArmoryScreen;

	if(m_kCustomizeManager == None)
	{
		m_kCustomizeManager = new(self) Unit.GetMyTemplate().CustomizationManagerClass;
	}

	TopArmoryScreen = UIArmory(ScreenStack.GetLastInstanceOf(class'UIArmory'));
	if(TopArmoryScreen != none)
		m_kCustomizeManager.Init(Unit, TopArmoryScreen.ActorPawn, CheckGameState);	
	else
		m_kCustomizeManager.Init(Unit, , CheckGameState);
}

simulated function DeactivateCustomizationManager( bool bAcceptChanges )
{
	if(m_kCustomizeManager != None)
	{
		m_kCustomizeManager.OnDeactivate(bAcceptChanges);
		m_kCustomizeManager = none; 
	}
}

reliable client function XComGameState_Unit GetCustomizationUnit()
{
	return m_kCustomizeManager.Unit;
}

reliable client function StateObjectReference GetCustomizationUnitRef()
{
	return m_kCustomizeManager.UnitRef;
}
//-------------------------------------------------------------------
reliable client function UICharacterPool()
{
	ScreenStack.Push(Spawn(class'UICharacterPool', self));
}

reliable client function UISoundtrackPicker()
{
	ScreenStack.Push(Spawn(class'UIShellSoundtrackPicker', self), Get3DMovie());
}

reliable client function UICustomize_Menu(XComGameState_Unit Unit, Actor ActorPawn, optional XComGameState CheckGameState)
{
	InitializeCustomizeManager(Unit, CheckGameState);
	ScreenStack.Push(Spawn(Unit.GetMyTemplate().UICustomizationMenuClass, self), Get3DMovie());
}

reliable client function UIMPShell_UnitEditor(X2MPShellManager ShellManager, XComGameState loadoutState, XComGameState_Unit Unit)
{
	local UIMPShell_UnitEditor editorScreen;
	InitializeCustomizeManager(Unit);
	editorScreen = UIMPShell_UnitEditor(ScreenStack.Push(Spawn(class'UIMPShell_UnitEditor', self), Get3DMovie()));
	editorScreen.m_kEditSquad = loadoutState; 
	editorScreen.InitUnitEditorScreen(ShellManager, Unit);
}

reliable client function UICustomize_Info(optional XComGameState_Unit Unit)
{
	ScreenStack.Push(Spawn(Unit.GetMyTemplate().UICustomizationInfoClass, self), Get3DMovie());
}
reliable client function UICustomize_Props(optional XComGameState_Unit Unit)
{
	ScreenStack.Push(Spawn(Unit.GetMyTemplate().UICustomizationPropsClass, self), Get3DMovie());
}

reliable client function UICustomize_Head(optional XComGameState_Unit Unit)
{
	ScreenStack.Push(Spawn(Unit.GetMyTemplate().UICustomizationHeadClass, self), Get3DMovie());
}

reliable client function UICustomize_Body(optional XComGameState_Unit Unit)
{
	ScreenStack.Push(Spawn(Unit.GetMyTemplate().UICustomizationBodyClass, self), Get3DMovie());
}

reliable client function UICustomize_Weapon(optional XComGameState_Unit Unit)
{
	ScreenStack.Push(Spawn(Unit.GetMyTemplate().UICustomizationWeaponClass, self), Get3DMovie());
}

reliable client function UICustomize_Trait( string _Title, 
											string _Subtitle, 
											array<string> _Data, 
											delegate<UICustomize_Trait.OnItemSelectedCallback> _onSelectionChanged,
											delegate<UICustomize_Trait.OnItemSelectedCallback> _onItemClicked,
											optional delegate<UICustomize.IsSoldierEligible> _eligibilityCheck,
											optional int startingIndex = -1,
											optional string _ConfirmButtonLabel,
											optional delegate<UICustomize_Trait.OnItemSelectedCallback> _onConfirmButtonClicked )
{
	ScreenStack.Push(Spawn(class'UICustomize_Trait', self), Get3DMovie());
	UICustomize_Trait(ScreenStack.GetCurrentScreen()).UpdateTrait( _Title, _Subtitle, _Data, _onSelectionChanged, _onItemClicked, _eligibilityCheck, startingIndex, _ConfirmButtonLabel, _onConfirmButtonClicked );
}

reliable client function UICharacterPool_ExportPools(array<XComGameState_Unit> UnitsToExport)
{
	local UICharacterPool_ListPools ListPools;

	ListPools = Spawn(class'UICharacterPool_ListPools', self);
	ListPools.UnitsToExport = UnitsToExport;
	ScreenStack.Push(ListPools);
	ListPools.UpdateData( true );
}

reliable client function UICharacterPool_ImportPools()
{
	ScreenStack.Push(Spawn(class'UICharacterPool_ListPools', self));
	UICharacterPool_ListPools(ScreenStack.GetCurrentScreen()).UpdateData( false );
}

//-------------------------------------------------------------------
function UIScreen UIChallengeMode_SquadSelect()
{
	local UIScreen Screen;
	Screen = Spawn( class'UIChallengeMode_SquadSelect', self );
	ScreenStack.Push( Screen );
	return Screen;
}

//-------------------------------------------------------------------
function UIScreen UIDebugChallengeMode()
{
	local UIScreen Screen;
	Screen = Spawn( class'UIDebugChallengeMode', self );
	ScreenStack.Push( Screen );
	return Screen;
}

//-------------------------------------------------------------------
function UIScreen UIFiraxisLiveLogin(optional bool bUpdateState=true)
{
	local UIFiraxisLiveLogin Screen;
	Screen = Spawn( class'UIFiraxisLiveLogin', self );
	Screen.bUpdateState = bUpdateState;
	ScreenStack.Push( Screen );
	return Screen;
}

function UIFiraxisLiveLoginButton(UIButton button)
{
	UIFiraxisLiveLogin();
}

//-------------------------------------------------------------------
function UIIronMan()
{
	local UIMovie TargetMovie;

	TargetMovie = XComShellPresentationLayer(self) == none ? Get2DMovie() : Get3DMovie();
	ScreenStack.Push(Spawn(class'UIChooseIronMan', self), TargetMovie);
}

//-------------------------------------------------------------------
function UIShellNarrativeContent()
{
	local UIMovie TargetMovie;

	TargetMovie = XComShellPresentationLayer(self) == none ? Get2DMovie() : Get3DMovie();
	ScreenStack.Push(Spawn(class'UIShellNarrativeContent', self), TargetMovie);
}

//-------------------------------------------------------------------
function UIScreen LoadGenericScreenFromName(string ScreenClassName)
{
	local class<UIScreen> ScreenClass;
	local UIScreen Screen;
	ScreenClass = class<UIScreen>( DynamicLoadObject( ScreenClassName, class'Class' ) );
	Screen = Spawn( ScreenClass, self );
	ScreenStack.Push( Screen );
	return Screen;
}

//-------------------------------------------------------------------

simulated function UIDrawGridPixel(int horizontalSpacing, int verticalSpacing, optional bool bIn3D = false )
{ 
	if( m_kDebugGrid != none)
		UIClearGrid();

	m_kDebugGrid = Spawn( class'UIDebugGrid', self );

	if( bIn3D )
		m_kDebugGrid.InitScreen( XComPlayerController(Owner), Get3DMovie() );
	else
		m_kDebugGrid.InitScreen( XComPlayerController(Owner), Get2DMovie() );

	m_kDebugGrid.DrawGridPixel( horizontalSpacing, verticalSpacing );

	if( bIn3D )
		Get3DMovie().LoadScreen( m_kDebugGrid );
	else
		Get2DMovie().LoadScreen( m_kDebugGrid );
}

simulated function UIDrawGridPercent(float horizontalSpacing, float verticalSpacing, optional bool bIn3D = false )
{
	if( m_kDebugGrid != none)
		UIClearGrid();

	m_kDebugGrid = Spawn( class'UIDebugGrid', self );
	
	if( bIn3D )	
		m_kDebugGrid.InitScreen( XComPlayerController(Owner), Get3DMovie() );
	else
		m_kDebugGrid.InitScreen( XComPlayerController(Owner), Get2DMovie() );

	m_kDebugGrid.DrawGridPercent( horizontalSpacing, verticalSpacing );

	if( bIn3D )
		Get3DMovie().LoadScreen( m_kDebugGrid );
	else
		Get2DMovie().LoadScreen( m_kDebugGrid );
}

simulated function UIClearGrid()
{
	// Could be in either movie, so ask where we are removing from. 
	if( m_kDebugGrid != none )
	{
		m_kDebugGrid.Movie.RemoveScreen(m_kDebugGrid);
		m_kDebugGrid = none;
	}
}

simulated function UIDebugControlOps()
{
	if(m_2DMovie != none)
		m_2DMovie.AS_ToggleControlOpsDebugging();
	
	if (m_PhotoboothMovie != none)
		m_PhotoboothMovie.AS_ToggleControlOpsDebugging();

	if(m_3DMovie != none)
		m_3DMovie.AS_ToggleControlOpsDebugging();

	if(m_ModalMovie != none)
		m_ModalMovie.AS_ToggleControlOpsDebugging();
}
/*
simulated function UIDebugSizing(optional bool in3D)
{
	if(ScreenStack.IsInStack(class'UIDebugSizing'))
		ScreenStack.PopOfClass(class'UIDebugSizing');
	else
		ScreenStack.Push( Spawn( class'UIDebugSizing', self ), in3D ? Get3DMovie() : Get2DMovie());
}
*/
simulated function UITestScreen() 
{	
	ScreenStack.Push( Spawn( class'UIMultiplayerPostMatchSummary', self ) );
}

// Debug: Show/Hide safe area region
simulated function UIToggleSafearea() 
{
	if( m_kUIDebugSafeArea  == none )
	{
		ScreenStack.Push(  Spawn( class'UIDebugSafearea', self ) );
	}
	else 
	{
		ScreenStack.PopFirstInstanceOfClass( class'UIDebugSafearea' ); 
		m_kUIDebugSafeArea = none;
	}
}

simulated function UIRedScreen()
{
	// Create the screen to be available for data setting. 
	if(m_RedScreen == none)
		m_RedScreen = Spawn(class'UIRedScreen', self);

	//Can't fire up RedScreens before the UI is ready, else they are sucked in to the ether. 
	if( !IsPresentationLayerReady() )
	{
		if( !IsTimerActive('UIRedScreen') )
			SetTimer(0.1, true, 'UIRedScreen');
		return;
	}
	else
		ClearTimer('UIRedScreen');

	//Only push on to stack after we're ready
	ScreenStack.Push(m_RedScreen);
}

simulated function bool RedScreenIsOpen()
{
	return ScreenStack.IsInStack(class'UIRedscreen');
}

simulated function UIReplayScreen(string playerID)
{
	local UIReplay replayScreen;

	replayScreen = Spawn(class'UIReplay', self);
	replayScreen.m_playerString = playerID;

	ScreenStack.Push(replayScreen);
}

simulated function UIItemDebugScreen()
{
	ScreenStack.Push( Spawn( class'UIDebugItems', self ) );
}

simulated function UIHistoryDebugScreen()
{
	ScreenStack.Push( Spawn( class'UIDebugHistory', self ) );
}

simulated function UIAuthorRegionsDebugScreen()
{
	ScreenStack.Push(Spawn(class'UIAuthorRegions', self));
}

simulated function UIVisibilityDebugScreen()
{
	ScreenStack.Push( Spawn( class'UIDebugVisibility', self ) );
}

simulated function UIMultiplayerDebugScreen()
{
	ScreenStack.Push( Spawn( class'UIDebugMultiplayer', self ) );
}

simulated function UIDebugMap()
{
	ScreenStack.Push( Spawn( class'UIDebugMap', self ) );
}

simulated function UIDebugMarketing()
{
	ScreenStack.Push(Spawn(class'UIDebugMarketing', self));
}

simulated function UIDebugBehaviorTree()
{
	ScreenStack.Push( Spawn( class'UIDebugBehaviorTree', self ) );
}

simulated function UITacticalQuickLaunch() 
{
	ScreenStack.Push( Spawn( class'UITacticalQuickLaunch', self ) );
}

simulated function UIDropshipHUD()
{
	ScreenStack.Push(Spawn(class'UIDropshipHUD', self));
}

function UIXComDatabase()
{
	if( ScreenStack.IsNotInStack(class'UIInventory_XComDatabase') )
		ScreenStack.Push(Spawn(class'UIInventory_XComDatabase', self));
}

// Debug: Show status of Firaxis / GFx UI system.
simulated function UIStatus() 
{
	if (Get2DMovie() != none )
	{
		Get2DMovie().PrintCurrentScreens();
	}
	else
	{
		`log("Cannot give UIStatus() due to interface manager being NONE.");
	}
}

simulated function UIChallengeModeEventNotify(optional bool bDataView=false)
{
	local UIChallengeModeEventNotify EventNotifyWindow;
	if (!ScreenStack.IsInStack(class'UIChallengeModeEventNotify'))
	{
		EventNotifyWindow = Spawn( class'UIChallengeModeEventNotify', self );
		EventNotifyWindow.SetDataView(bDataView);
		ScreenStack.Push( EventNotifyWindow );
	}
}

simulated function UIChallengeCompletedBanner(int Turn, int NumPlayersPrior, int NumPlayersTotal)
{
	local string PriorPercentOfPlayersSeeingEvent;
	local string Notice, ImagePath, Subtitle, Value;
	local EUIState TextState;
	local XGParamTag ParamTag;

	PriorPercentOfPlayersSeeingEvent = (NumPlayersTotal > 0) ? string(int((float(NumPlayersPrior) / NumPlayersTotal) * 100.0)) : "0";

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Notice = default.ChallengeEventLabels[ECME_CompletedMission];
	ImagePath = "";
	ParamTag.StrValue0 = string(Turn);
	Value = `XEXPAND.ExpandString(default.ChallengeTurnLabel);

	ParamTag.StrValue0 = PriorPercentOfPlayersSeeingEvent;
	TextState = eUIState_Warning;
	Subtitle = `XEXPAND.ExpandString(default.ChallengeEventDescriptions[ECME_CompletedMission]);

	NotifyBanner(Notice, ImagePath, Subtitle, Value, TextState);
}

simulated function UIChallengeEventBanner()
{
	local X2TacticalChallengeModeManager ChallengeModeManager;
	local PendingEventType PendingEvent;
	local string Notice, ImagePath, Subtitle, Value;
	local EUIState TextState;
	local float TotalPlayersStarted;

	if (!`ONLINEEVENTMGR.bIsLocalChallengeModeGame)
	{
		foreach AllActors(class'X2TacticalChallengeModeManager', ChallengeModeManager)
		{
			break;
		}

		TotalPlayersStarted = ChallengeModeManager.GetTotalPlayersStarted();

		while (ChallengeModeManager.GetCurrentEvent(PendingEvent))
		{
			GenerateChallengeEventStrings(PendingEvent, TotalPlayersStarted, Notice, ImagePath, Subtitle, Value, TextState);
			NotifyBanner(Notice, ImagePath, Subtitle, Value, TextState);
			ChallengeModeManager.NextEvent(true);
		}
	}
}

private function GenerateChallengeEventStrings(PendingEventType PendingEvent, float TotalPlayersStarted, out string Notice, out string ImagePath, out string Subtitle, out string Value, out EUIState TextState)
{
	local XGParamTag ParamTag;
	local float TotalPlayersSeeingEvent, EventComparePlayers;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Notice = default.ChallengeEventLabels[PendingEvent.EventType];
	ImagePath = "";
	ParamTag.StrValue0 = string(PendingEvent.Turn);
	Value = `XEXPAND.ExpandString(default.ChallengeTurnLabel);

	
	TotalPlayersSeeingEvent = PendingEvent.NumPlayersCurrent + PendingEvent.NumPlayersPrior + PendingEvent.NumPlayersSubsequent;
	switch(PendingEvent.EventType)
	{
	case ECME_FirstXComKIA:
	case ECME_FirstSoldierWounded:
	case ECME_LostSectopodGatekeeper:
		EventComparePlayers = PendingEvent.NumPlayersCurrent;
		TextState = eUIState_Bad;
		break;
	case ECME_FirstAlienKill:
	case ECME_MissionObjectiveComplete:
	case ECME_10EnemiesKIA:
	case ECME_5EnemiesKIA:
	case ECME_KilledSectopodGatekeeper:
		EventComparePlayers = PendingEvent.NumPlayersSubsequent;
		TextState = eUIState_Good;
		break;
	case ECME_ConcealmentBroken:
		EventComparePlayers = PendingEvent.NumPlayersSubsequent;
		TextState = eUIState_Warning;
		break;
	case ECME_CompletedMission:
	case ECME_FailedMission:
		EventComparePlayers = PendingEvent.NumPlayersCurrent;
		TextState = eUIState_Warning;
		break;
	default:
		TextState = eUIState_Good;
	}

	ParamTag.StrValue0 = (TotalPlayersSeeingEvent > 0) ? string(int((EventComparePlayers / TotalPlayersSeeingEvent) * 100.0)) : "0";
	Subtitle = `XEXPAND.ExpandString(default.ChallengeEventDescriptions[PendingEvent.EventType]);
}

simulated function ObjectiveScoringDecreaseBanner()
{
	NotifyBanner(ChallengeObjectiveDecreaseNotice, "", ChallengeObjectiveDecreaseText, "", eUIState_Bad);
}

simulated function EnemyScoringDecreaseBanner()
{
	NotifyBanner(ChallengeEnemyDecreaseNotice, "", ChallengeEnemyDecreaseText, "", eUIState_Bad);
}

simulated function ChallengeScoringDecreaseBanner()
{
	NotifyBanner(ChallengeScoringDecreaseNotice, "", ChallengeScoringDecreaseText, "", eUIState_Bad);
}

// ================================================================================================
// ================================================================================================
// ================================================================================================

// Override on child classes to provide this functionality
simulated function ClearUIToHUD(optional bool bInstant = true);

// This will be called in the initialization sequence in each Pres layer, but specifically so 
// that the stack sorting order looks good in each area of the game. 
simulated function UIWorldMessages()
{
	if( m_kWorldMessageManager == None )
	{
		m_kWorldMessageManager = Spawn(class'UIWorldMessageMgr', self);
		m_kWorldMessageManager.InitScreen(XComPlayerController(Owner), Get2DMovie());
		Get2DMovie().LoadScreen(m_kWorldMessageManager);
	}
}

//-----------------------------------------------------------
simulated function bool DoNarrativeByMissonType( int eType, int eShipType, optional Actor kFocusActor)
{
	local bool bValid;

	return false; // Don't do these until we have new ones - Requested by Liam

	if( `BATTLE.m_kDesc.m_bIsTutorial && `BATTLE.m_kDesc.m_iMissionType == eMission_Abduction )
		return false;

	/**/

	switch ( eType )
	{
		case eMission_Abduction:
			//bValid = UINarrative( XComNarrativeMoment'NarrativeMoment.MissionIntro',,,,,, true);
			break;
		case eMission_TerrorSite:
			//bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroTerror', kFocusActor,,,,, true);
			break;

		case eMission_AlienBase:
			//bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroAlienBase', kFocusActor,,,,, true);
			break;

		case eMission_LandedUFO:
			//bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroUFOLanded', kFocusActor,,,,, true);
			break;

		case eMission_Final:
			//bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroTempleShip', kFocusActor,,,,, true);
			break;

		case eMission_Crash:
			// determine the type of ship crash
			//switch (eShipType)
			//{
			//	case eShip_UFOBattle:
			//		bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroBattleshipCrash', kFocusActor,,,,, true);
			//		break;

			//	case eShip_UFOEthereal:
			//		bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroOverseerCrash', kFocusActor,,,,, true);
			//		break;

			//	default:
			//		bValid = UINarrative(XComNarrativeMoment'NarrativeMoment.IntroUFOCrash', kFocusActor,,,,, true);
			//		break;
			//}
			break;

		default:
			bValid = false;
			break;
	}

	return bValid;
}

//-----------------------------------------------------------
simulated function bool DoNarrativeByCharacterTemplate(X2CharacterTemplate CharTemplate, optional Actor kFocusActor)
{
	local bool bValid;
	local int idx;

	bValid = false;

	for(idx = 0; idx < CharTemplate.SightedNarrativeMoments.Length; idx++)
	{
		bValid = UINarrative(CharTemplate.SightedNarrativeMoments[idx], kFocusActor);
	}

	for (idx = 0; idx < CharTemplate.SightedEvents.Length; idx++)
	{
		`XEVENTMGR.TriggerEvent(CharTemplate.SightedEvents[idx]);
	}

	return bValid;
}

//-----------------------------------------------------------
// New way
function int GetNarrativeMomentID(XComNarrativeMoment kNarrativeMoment)
{
	local int NarrativeID;

	NarrativeID = kNarrativeMoment.iID;
	if (NarrativeID < 0)
	{
		NarrativeID = m_kNarrative.m_arrNarrativeMoments.Find(kNarrativeMoment);
		if (NarrativeID == INDEX_NONE)
		{
			//This is a new narrative moment, add it
			m_kNarrative.AddNarrativeMoment(kNarrativeMoment);
			NarrativeID = kNarrativeMoment.iID;
		}
	}

	return NarrativeID;
}

simulated function bool GetNarrativeConversation( out name kConversation, XComNarrativeMoment kNarrativeMoment, optional bool bPreloading=false)
{
	local int iIndex;
	local int iNarrativeMomentCounter;
	local bool bNarr;

	bNarr = (m_kNarrative != none);

	if(bNarr)
	{
		iNarrativeMomentCounter = GetTimesPlayed(kNarrativeMoment);
	}
	else
	{
		iNarrativeMomentCounter = 0;
	}
	

	// Make sure there are conversations
	if (kNarrativeMoment.arrConversations.Length == 0)
	{
		if (kNarrativeMoment.bFirstTimeAtIndexZero && iNarrativeMomentCounter > 0)
			return false;

		// Support narrative moments with an empty conversation array, its probably a matinee with no dialogue.
		kConversation = '';
		
		// If we're preloading this conversation, don't add to the counters because we havn't played it yet
		if (bNarr && !bPreloading)
		{
			m_kNarrative.m_arrNarrativeCounters[kNarrativeMoment.iID] +=1;
		}
		return true;  
	}


	if (kNarrativeMoment.bFirstTimeAtIndexZero)
	{
		// If we only have 1 conversation, and we are told we have a first time conversation, we only every play it once
		if (kNarrativeMoment.arrConversations.Length == 1 && (iNarrativeMomentCounter >= 1 || (bNarr && m_kNarrative.bDisableFirstTimeOnlyNarratives)))
			return false;

		if (iNarrativeMomentCounter == 0)
		{
			iIndex = 0;
		}
		else
		{
			// If we only have 1 conversation, and we are told we have a first time conversation, we only every play it once
			if (kNarrativeMoment.arrConversations.Length == 1)
				return false;

			// Make sure we don't reuse index 0 as that is reserved for first time conversation
			iIndex = iNarrativeMomentCounter % (kNarrativeMoment.arrConversations.Length-1);
			iIndex += 1;
		}

		kConversation = kNarrativeMoment.arrConversations[iIndex];

		// If we're preloading this conversation, don't add to the counters because we havn't played it yet
		if (bNarr && !bPreloading)
		{
			m_kNarrative.m_arrNarrativeCounters[kNarrativeMoment.iID] +=1;
		}
		return true;

	}
	else
	{
		iIndex = iNarrativeMomentCounter % kNarrativeMoment.arrConversations.Length;
		kConversation = kNarrativeMoment.arrConversations[iIndex];
		// If we're preloading this conversation, don't add to the counters because we havn't played it yet
		if (bNarr && !bPreloading)
		{
			m_kNarrative.m_arrNarrativeCounters[kNarrativeMoment.iID] +=1;
		}
		return true;
	}
}

simulated function int GetTimesPlayed(XComNarrativeMoment kNarrativeMoment)
{
	local int NarrativeID;
	
	NarrativeID = GetNarrativeMomentID(kNarrativeMoment);
	if (NarrativeID > -1)
	{
		return m_kNarrative.m_arrNarrativeCounters[kNarrativeMoment.iID];
	}
	
	return 0;
}

//-----------------------------------------------------------
// Play full screen movies. Returns the event ID of the wise event if one is played
simulated function int UIPlayMovie( string strMovieName, optional bool wait = true, optional bool bLoop=false, optional string strWiseEventName)
{
	local int WiseEventID;
	//`log("UIPlayMovie:" @ strMovieName,,'uixcom');

	if( strMovieName == "" )
		return -1;

	ClearInput();

	`XENGINE.StopCurrentMovie();
	WiseEventID = `XENGINE.PlayMovie(bLoop, strMovieName, strWiseEventName);
	if (`XENGINE.IsMoviePlaying(strMovieName) && wait)
	{
		`XENGINE.WaitForMovie();
		`XENGINE.StopCurrentMovie();
	}

	return WiseEventID;
}

simulated function StartFadeToBlack(float speed, UINarrativeMgr Manager)
{
	Manager.DoStartFadeToBlack(speed);
}

//----------------------------------------------------
function Speak( string strText, bool bMaleVoice )
{	
	XComPlayerController(Owner).SpeakTTS( strText, bMaleVoice );
}

simulated function UIStopMovie()
{
	`XENGINE.StopCurrentMovie();
}

simulated function ClearInput()
{
	XComInputBase(XComPlayerController(Owner).PlayerInput).ClearAllRepeatTimers();
}

// DEBUG
simulated function HideLoadingScreen()
{
	`log("########### Finished loading and initializing map",,'uicore');
	if (InStr(class'Engine'.static.GetLastMovieName(), "load", false, true) != INDEX_NONE ||
		InStr(class'Engine'.static.GetLastMovieName(), "1080_PropLoad_001", false, true) != INDEX_NONE)
	{
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog( "Tactical Load Debug: Engine Request Stop Movie" );
		class'Engine'.static.StopMovie(true);				
	}

	class'Helpers'.static.SetGameRenderingEnabled(true, 0);
}

function FirstMissionBinkPlaying()
{
	class'Engine'.static.StopMovie(true);
	class'Helpers'.static.SetGameRenderingEnabled(true, 0);	
}
// -----------------------------------------------------------------------

public function CreateTutorialSave()
{
	if( ScreenStack != none )
	{
		TutorialSaveData = Spawn(class'UITutorialSaveData', self );
	}
	else 
	{
		`warn("Could not find HUD while creating tutorial save. This is bad!");
	}
}

simulated function bool IsGameplayOptionEnabled(int option) 
{
	`assert(false); // must be overriden in base classes
	return false;
}

simulated public function OnTurnTimerExpired();

// Used in UIStrategyTutorialBox.
simulated function bool ShouldAnchorTipsToRight()
{
	return true;
}

function bool OnSystemMessage_AutomatchGameFull();

// Override in child classes
reliable client function CAMLookAtNamedLocation( string strLocation, optional float fInterpTime = 2, optional bool bSkipBaseViewTransition, optional Vector ForceLocation, optional Rotator ForceRotation );

simulated function bool PlayUISound( EUISound eSound )
{
	local XComSoundManager SoundManager; 

	SoundManager = GetSoundMgr();
	if( SoundManager == none ) 
		return false; 

	switch( eSound )
	{
	case eSUISound_MenuOpen:
		SoundManager.PlaySoundEvent("Play_MenuOpen");
		break;
	case eSUISound_MenuClose:
		SoundManager.PlaySoundEvent("Play_MenuClose");
		break;
	case eSUISound_MenuSelect:
		SoundManager.PlaySoundEvent("Play_MenuSelect");
		break;
	case eSUISound_MenuClickNegative:
		SoundManager.PlaySoundEvent("Play_MenuClickNegative");
		break;
	case eSUISound_SoldierPromotion:
		SoundManager.PlaySoundEvent("Play_SoldierPromotion");
		break;

	}
	return true; 
}

function UIMovie_3D Get3DMovie()
{
	if(m_3DMovie == None)
	{
		Init3DDisplay();
	}
	return m_3DMovie;
}

simulated function Init3DDisplay()
{
	local PlayerController PController;
	local XComLocalPlayer LocalPlayer;
	local ScriptSceneView SceneView;
	local Vector2D ScreenSize;
	//Initialize the generic 3D movie that is passed around ont eh curved 3D UI screens. 
	m_3DMovie = new(self) class'UIMovie_3D';

	// grab our sceneview interface
	PController = GetALocalPlayerController();
	LocalPlayer = XComLocalPlayer(PController.Player);
	SceneView = LocalPlayer.SceneView;
	ScreenSize = SceneView.GetSceneResolution();
	`log("State_UI3DMovieMgr: Creating 3D UI RenderTarget: " @ ScreenSize.X @ ScreenSize.Y, , 'uixcom');
	m_3DMovie.RenderTexture = TextureRenderTarget2D'HQ_UI.Textures.UIRenderTarget';
	// class'TextureRenderTarget2D'.static.Create( ScreenSize.X, ScreenSize.Y, PF_A8R8G8B8, MakeLinearColor(1, 1, 0, 1), false, false, false);
	class'TextureRenderTarget2D'.static.Resize(m_3DMovie.RenderTexture, ScreenSize.X, ScreenSize.Y);
	MovieRenderTargetMaterial = MaterialInstanceConstant'HQ_UI.Materials.UIDisplayMaterial_INST';
	MovieRenderTargetMaterial.SetTextureParameterValue('Movie', m_3DMovie.RenderTexture);
	// Find all display movie MICs and set the texture parameter

	m_3DMovie.InitMovie(self);
}

simulated function Change3DDisplay(TextureRenderTarget2D newRenderTexture)
{
	m_3DMovie.RenderTexture = newRenderTexture;
	MovieRenderTargetMaterial.SetTextureParameterValue('Movie', newRenderTexture);
}

// 3D Screen material distortion effect
// expects a float between 0 and 1. 
simulated function SetUIDistortionStrength( float NewStrength )
{
	if (MovieRenderTargetMaterial != none)
	{
		MovieRenderTargetMaterial.SetScalarParameterValue('UIDistortionScale', NewStrength * DistortionScale);
	}
}

// hook to enable/disable full screen PP effects
simulated function EnablePostProcessEffect(name EffectName, bool bEnable, optional bool bResetTimer = false)
{
	local LocalPlayer LP;
	local PostProcessChain PPChain;
	local int ChainIdx;
	local PostProcessEffect Effect;
	local MaterialEffect MatEffect;

	// Restore the state of post processing
	LP = LocalPlayer(GetALocalPlayerController().Player);
	if(LP != none)
	{
		for(ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
		{
			PPChain = LP.PlayerPostProcessChains[ChainIdx];
			Effect = PPChain.FindPostProcessEffect(EffectName);
			if(Effect != none)
			{
				if(!PPChain.HasSavedEffectState())
					PPChain.SaveEffectState();

				if( bResetTimer && Effect.bShowInGame != bEnable )
				{
					if( Effect.IsA('MaterialEffect') )
					{
						MatEffect = MaterialEffect(Effect);
						if( MatEffect.Material.IsA('MaterialInstanceTimeVarying') )
						{
							MaterialInstanceTimeVarying(MatEffect.Material).Restart();
						}
						
					}
				}
				
				Effect.bShowInGame = bEnable;

				// Play any sounds associated with enabling/disabling this effect
				`SOUNDMGR.PlayPostProcessEffectTransitionAkEvents(EffectName, bEnable);
			}
		}
	}
}

simulated function SetPostProcessEffectVectorValue(name EffectName, name scalarParameter, LinearColor value)
{
	local LocalPlayer LP;
	local PostProcessChain PPChain;
	local int ChainIdx;
	local PostProcessEffect Effect;
	local MaterialEffect MatEffect;

	// Restore the state of post processing
	LP = LocalPlayer(GetALocalPlayerController().Player);
	if (LP != none)
	{
		for (ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
		{
			PPChain = LP.PlayerPostProcessChains[ChainIdx];
			Effect = PPChain.FindPostProcessEffect(EffectName);
			if (Effect != none)
			{
				if (!PPChain.HasSavedEffectState())
					PPChain.SaveEffectState();

				if (Effect.IsA('MaterialEffect'))
				{
					MatEffect = MaterialEffect(Effect);
					if (MatEffect.Material.IsA('MaterialInstanceTimeVarying'))
					{
						MaterialInstanceTimeVarying(MatEffect.Material).SetVectorParameterValue(scalarParameter, value);
					}
				}
			}
		}
	}
}

function StartDistortUI(float TimeToDistort)
{
	local LocalPlayer LP;
	local int i, j;
	local PostProcessChain PPChain;
	local XComUIPostProcessEffect DistortEffect;
	
	LP = LocalPlayer(GetALocalPlayerController().Player);
	for(i = 0; i < LP.PlayerPostProcessChains.Length; i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for(j = 0; j < PPChain.Effects.Length; j++)
		{
			DistortEffect = XComUIPostProcessEffect(PPChain.Effects[j]);
			if(DistortEffect != none)
			{
				DistortEffect.bShowInGame = true;
			}
		}
	}

	TimeLeftToDistort = TimeToDistort;
	SetTimer(TimeToDistort, false, nameof(StopDistort));
	SetTimer(0.1f, true, nameof(UpdateDistortUI));
}

function UpdateDistortUI()
{
	local LocalPlayer LP;
	local int i, j;
	local PostProcessChain PPChain;
	local XComUIPostProcessEffect DistortEffect;
	local MaterialInstanceConstant MIC;
	local float FinalDistortionScale;
	
	TimeLeftToDistort -= 0.1f;
	FinalDistortionScale = TimeLeftToDistort * DistortionScale;

	LP = LocalPlayer(GetALocalPlayerController().Player);
	for(i = 0; i < LP.PlayerPostProcessChains.Length; i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for(j = 0; j < PPChain.Effects.Length; j++)
		{
			DistortEffect = XComUIPostProcessEffect(PPChain.Effects[j]);
			if(DistortEffect != none)
			{
				MIC = MaterialInstanceConstant(DistortEffect.Material);
				MIC.SetScalarParameterValue('DistortionScale', FinalDistortionScale);
			}
		}
	}

	if(TimeLeftToDistort < 0.0f)
	{
		ClearTimer(nameof(UpdateDistortUI));
		StopDistort();
	}
}

function StopDistort()
{
	local LocalPlayer LP;
	local int i, j;
	local PostProcessChain PPChain;
	local XComUIPostProcessEffect DistortEffect;
	
	LP = LocalPlayer(GetALocalPlayerController().Player);
	for(i = 0; i < LP.PlayerPostProcessChains.Length; i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for(j = 0; j < PPChain.Effects.Length; j++)
		{
			DistortEffect = XComUIPostProcessEffect(PPChain.Effects[j]);
			if(DistortEffect != none)
			{
				DistortEffect.bShowInGame = false;
			}
		}
	}
}

simulated function Notify(string Notice, optional string ImagePath = "") 
{
	m_kEventNotices.Notify(Notice, ImagePath);
}

simulated function NotifyBanner(string Notice,
	optional string ImagePath = "",
	optional string Subtitle = "",
	optional string Value = "",
	optional EUIState eState = eUIState_Normal,
	optional delegate<UIEventNotices.OnMouseEventDel> OnMouseEvent)
{
	m_kEventNotices.NotifyBanner(Notice, ImagePath, Subtitle, Value, eState, OnMouseEvent);
}

simulated function ClickPathUnderMouse( optional bool bDebugLogs = false )
{
	Get2DMovie().ClickPathUnderMouse(bDebugLogs);
}

simulated function ClickPathUnderMouse3D( optional bool bDebugLogs = false )
{
	Get3DMovie().ClickPathUnderMouse(bDebugLogs);
}

simulated function bool IsPresentationLayerReady()
{
	local X2GameRuleset Ruleset;
	Ruleset = `GAMERULES;

	return m_bPresLayerReady && (Ruleset == none || !Ruleset.bProcessingLoad);
}


simulated function UIChosenRevealScreen()
{
	ScreenStack.Push(Spawn(class'UIChosenReveal', self));
}

simulated function UIChosenInformation()
{
	ScreenStack.Push(Spawn(class'UIChosenInfo', self));
}



DefaultProperties
{
	MoviesInited=0;
	m_bBlockSystemMessageDisplay= false;
	m_bIsGameDataReady          = false;
	m_bGameOverTriggered        = false;
	m_bPresLayerReady           = false;
	m_bIsPlayingGame            = false;
	m_ePendingKismetVisibility  = eKismetUIVis_None;
	m_eUIMode                   = eUIMode_Common;
}

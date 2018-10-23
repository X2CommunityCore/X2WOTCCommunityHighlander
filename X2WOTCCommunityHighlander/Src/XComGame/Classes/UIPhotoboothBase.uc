
class UIPhotoboothBase extends UIScreen
	dependson(X2Photobooth)
	native(UI)
	config(UI);

/******************************************/
//		General UI Variables
/******************************************/
var PhotoboothDefaultSettings DefaultSetupSettings;
var bool m_bResetting;

var UINavigationHelp NavHelp;

var UIX2PanelHeader TitleHeader;

var UIPanel	PosterOutline;
var UIPanel CameraOutline;

var UILargeButton TakePhotoButton;

var UIPanel ListContainer; // contains all controls bellow
var UIPanel	ListBG;
var UIList  List;

var int     m_bOriginalSubListIndex; //bsg-jneal (5.16.17): now changing pose on selection change so need to remember initial pose when cancelling menu
var int     m_iDefaultListIndex; //bsg-jneal (5.23.17): saving default list index for better nav

var int		previousSelectedIndexOnFocusLost;

var int		NumPawnsNeedingUpdateAfterFormationChange;

var bool bDestroyPhotoboothPawnsOnCleanup;

var bool bCameraOutlineInited;
var bool bWaitingOnPhoto;
var bool bUpdateCameraWithFormation;
//bsg-jedwards (3.22.17) : Added loc from the .int file
var localized string m_strContinue;
var localized string m_strTakePhoto;
var localized string m_strZoomIn;
var localized string m_strZoomOut;
var localized string m_strToggleCamera; //bsg-jneal (5.2.17): toggle camera loc text for navhelp
var localized string m_strPanCam;
var localized string m_strRotCam;
//bsg-jedwards (3.22.17) : end

var bool bChallengeMode;
var bool bLadderMode;

var bool bHasTakenPicture; //bgs-hlee (05.15.17): Checks to see if a picture has been taken or not.

enum EUIPropagandaType
{
	eUIPropagandaType_Base,
	eUIPropagandaType_Formation,
	eUIPropagandaType_SoldierData,
	eUIPropagandaType_Soldier,
	eUIPropagandaType_Pose,
	eUIPropagandaType_BackgroundOptions,
	eUIPropagandaType_Background,
	eUIPropagandaType_Graphics,
	eUIPropagandaType_Fonts,
	eUIPropagandaType_TextColor,
	eUIPropagandaType_TextFont,
	eUIPropagandaType_Layout,
	eUIPropagandaType_Filter,
	eUIPropagandaType_Treatment,
	eUIPropagandaType_GradientColor1,
	eUIPropagandaType_GradientColor2,
	eUIPropagandaType_MAX
};

/******************************************/
//		UI Strings
/******************************************/

var localized string m_strInfo;
var localized string m_strCameraTab;
var localized string m_strPosterTab;

var localized string m_strEmptyOption;

/******************************************/
//		Camera UI Variables
/******************************************/
var UIPanel m_CameraPanel;
var UIIcon m_PresetFullBody;
var UIIcon m_PresetHeadshot;
var UIIcon m_PresetHigh;
var UIIcon m_PresetLow;
var UIIcon m_PresetProfile;
var UIIcon m_PresetTight;

/******************************************/
//		Camera Logic Variables
/******************************************/

/* Index representing the last soldier 'touched'. This is the soldier we are currently modifying. */
var int m_iLastTouchedSoldierIndex;
var int m_iLastTouchedTextBox;

var int m_iSoldierListIndex;

var array<int>	  m_PosterIcons;
var int	m_iPreviousColor;
var int m_iTextBoxListIndex;
var int m_iIconListIndex;
var int m_iCurrentModifyingTextBox;
var int m_iIconIndexChoosing;


var UIBGBox  			BG;

var public int					        BGPaddingLeft;
var public int					        BGPaddingRight;       
var public int					        BGPaddingTop;        
var public int					        BGPaddingBottom;
var UIImageSelector m_uiIconSelection;

struct native PosedSoldierData
{
	var StateObjectReference	UnitRef;
	var XComUnitPawn			UnitPawn;
	var name					AnimationName;
	var float					AnimationOffset;
};

/******************************************/
//		Poster UI Variables
/******************************************/

var UIPosterScreen m_backgroundPoster;

var TextureRenderTarget2D m_kUIRenderTexture;
var Texture2D m_kBackgroundTexture;

var MaterialInterface m_kFirstFilterPass;
var MaterialInterface m_kSecondFilterPass;

/******************************************/
//		Game Logic Variables
/******************************************/

var CameraActor m_kCameraActor;

var XComGameState CheckGameState;
var int m_iGameIndex;

var array<StateObjectReference> m_arrSoldiers;

/******************************************/
//		Rendering Variables
/******************************************/

var int m_iOnScreenSizeX;
var int m_iOnScreenSizeY;

var int m_iPosterSizeX;
var int m_iPosterSizeY;

var vector m_vOldCaptureLocation;
var Rotator m_vOldCaptureRotator;
var float m_fCameraFOV;

/******************************************/
//		MISC Data
/******************************************/

var EUIPropagandaType currentState;
var EUIPropagandaType lastState; //bsg-jedwards (5.1.17) : Adding last state check for list refresh
var name DisplayTag;
var string CameraTag;
var bool bUseNavHelp;

var bool m_bNeedsCaptureOutlineReset;

var bool m_bInitialized;
var bool m_bNeedsPopulateData;
var bool m_bRotationEnabled;
var bool m_bMouseIn;
var bool m_bRightMouseIn;
var bool m_bRotatingPawn;

var bool m_bGamepadCameraActive; //bsg-jneal (5.2.17): gamepad camera controls toggle

//bsg-jneal (5.2.17): controller input for camera, right stick for rotation, left for pan
var protected Vector2D StickVectorLeft;
var protected Vector2D StickVectorRight;
//bsg-jneal (5.2.17): end

var config float StickRotationMultiplier;
var config float DragRotationMultiplier;
var config float DragPanMultiplier;
var config float DragPanMultiplierController; //bsg-jneal (5.2.17): pan multiplier too low for controller, needs separate value from mouse
var config float SoldierRotationMultiplier;
var config float WheelRotationMultiplier;
var config array<String> IconChooserIcons;
var config int PhotoCommentChance;

var int ColorSelectorState;
var int ColorSelectorX;
var int ColorSelectorY;
var int ColorSelectorWidth;
var int ColorSelectorHeight;
var UIColorSelector ColorSelector;

var localized string m_cameraControlPan;
var localized string m_cameraControlTilt;
var localized string m_cameraControlZoom;
var localized string m_cameraControlPreset;

var localized string m_CategoryFormations;
var localized string m_CategorySoldiers;
var localized string m_PrefixSoldier;
var localized string m_PrefixPose;
var localized string m_CategoryRotateSoldier;
var localized string m_CategoryBackgroundOptions;
var localized string m_CategoryBackground;
var localized string m_CategoryGraphics;
var localized string m_CategoryRandom;
var localized string m_CategoryCameraPresets; //bsg-jedwards (5.1.17) : New string for the spinner
var localized string m_CategoryReset;
var localized string m_PrefixTextBox;
var localized string m_PrefixTextBoxColor;
var localized string m_PrefixTextBoxFont;
var localized string m_PrefixIcon;
var localized string m_CategoryLayout;
var localized string m_CategoryFilter;
var localized string m_CategoryTreatment;
var localized string m_CategoryHidePoster;
var localized string m_CategoryToggleBackgroundTint;
var localized string m_CategoryBackgroundTint1;
var localized string m_CategoryBackgroundTint2;

//bsg-jedwards (5.1.17) : Added strings for the spinner
var localized string m_strCameraPresetLabel_FullBody;
var localized string m_strCameraPresetLabel_Headshot;
var localized string m_strCameraPresetLabel_High;
var localized string m_strCameraPresetLabel_Low;
var localized string m_strCameraPresetLabel_Profile;
var localized string m_strCameraPresetLabel_Tight;
//bsg-jedwards (5.1.17) : end


var localized string m_ButtonSetSoldier;
var localized string m_ButtonSetPose;
var localized string m_ButtonSetFilter;
var localized string m_ButtonSetFont;
var localized string m_ButtonSetLayout;
var localized string m_ButtonSetFormation;
var localized string m_ButtonSetText;
var localized string m_ButtonSetIcon;
var localized string m_ButtonSetBackground;


var localized string m_DestructiveActionTitle;
var localized string m_DestructiveActionBody;

var localized string m_PendingPhotoTitle;
var localized string m_PendingPhotoBody;

var localized string m_TakePhotoString;
var localized string m_PhotoboothTitle;

var localized string m_TooltipNoSoldier;

//bsg-jedwards (5.1.17) : Added array and index to keep track of array's position
var array<string> m_CameraPresets_Labels;
var transient int ModeSpinnerVal;
var int max_SpinnerVal; //bsg-jedwards (5.4.17) : Turned to value for more general use between Armory and Tactical Photobooth
//bsg-jedwards (5.1.17) : end

var AutoGenCaptureState			m_kGenRandomState;

const VIRTUAL_KEYBOARD_MAX_CHARACTERS = 64; //bsg-jedwards (4.13.17) : Sets the max characters to 64

struct native ClassPoseChance
{
	var Photobooth_AnimationFilterType	AnimType;
	var int								Chance;
};

var config array<ClassPoseChance> m_arrClassPoseChances;

var config int FilterChance;

delegate OnClickedDelegate(UIButton Button);
delegate OnClickDelegate();

cpptext
{
	virtual UBOOL Tick(FLOAT DeltaTime, enum ELevelTick TickType);
}

/******************************************/
//		Initialize Functions
/******************************************/

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	bHasTakenPicture = false; //bgs-hlee (05.15.17): Init to not having taken a picture.

	ListContainer = Spawn(class'UIPanel', self).InitPanel(name("photoboothContainerMC"));

	//bsg-jedwards (5.1.17) : Hiding this button if the controller is active and putting the prompt in the NavHelp
	if(!`ISCONTROLLERACTIVE)
	{
		TakePhotoButton = Spawn(class'UILargeButton', self);
		TakePhotoButton.LibID = 'X2ContinueButton';
		TakePhotoButton.InitLargeButton('TakePhotoMC', m_TakePhotoString, , OnMakePosterSelected, eUILargeButtonStyle_READY);
		TakePhotoButton.SetPosition(1325, 925);
	}
	//bsg-jedwards (5.1.17) : end
	
	ListBG = Spawn(class'UIPanel', ListContainer).InitPanel(name("InventoryListBG"));
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	List = Spawn(class'UIList', ListContainer).InitList(name("photoboothListMC"), , , 515, 633);
	List.bSelectFirstAvailable = true;
	List.bStickyHighlight = true;
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	//bsg-jedwards (5.1.17) : Want to make sure the list container navigator ONLY contains the List
	ListContainer.Navigator.Clear();
	ListContainer.Navigator.AddControl(List);
	//bsg-jedwards (5.1.17) : end

	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	PosterOutline = Spawn(class'UIPanel', self).InitPanel(name("thePoster"));
	PosterOutline.Hide();

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	SetCategory( m_PhotoboothTitle );

	InitGameIndex();

	m_iDefaultListIndex = 0; //bsg-jneal (5.23.17): saving default list index for better nav

	bLadderMode = `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) != none;
}

simulated function OnInit()
{
	super.OnInit();
	
	List.SetSelectedNavigation(); //bsg-jneal (5.23.17): moving navigator selection to prevent double hilighting when returning to default list

	InitCameraControls();
	UpdateNavHelp(); //bsg-jedwards (5.1.17) : Change of Nick's to optimize initialization 
	InitImageSelectorPanel();
	InitTabButtons();

	SetupContent();

	SetupCamera();
	
	InitializeFormation();
	UpdateSoldierData();
	m_kGenRandomState = eAGCS_TickPhase1;

	GenerateDefaultSoldierSetup();

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so that they don't overlap with the soldiers

	NeedsPopulateData();
	OnReset();

	bCameraOutlineInited = false;
}

// This should be overriden in the base class to create the tabs that are desired.
function InitTabButtons() {};

function InitCameraButton()
{
	//TabButtons[eUIPropagandaType_Camera] = CreateTabButton(eUIPropagandaType_Camera, "Camera", CameraTab, false);
}

function InitCameraControls()
{
	CameraOutline = Spawn(class'UIPanel', self).InitPanel(name("cameraFrameMC"));

	m_CameraPanel = Spawn(class'UIPanel', self).InitPanel(name("cameraControlMC"));

	if (!`ISCONTROLLERACTIVE)
	{
		m_PresetFullBody = Spawn(class'UIIcon', m_CameraPanel).InitIcon('Preset0', , true, , , , OnCameraPresetFullBody);
		m_PresetFullBody.EnableMouseAutomaticColorStates(eUIState_Normal);
		m_PresetFullBody.bDisableSelectionBrackets = true;
		m_PresetHeadshot = Spawn(class'UIIcon', m_CameraPanel).InitIcon('Preset1', , true, , , , OnCameraPresetHeadshot);
		m_PresetHeadshot.EnableMouseAutomaticColorStates(eUIState_Normal);
		m_PresetHeadshot.bDisableSelectionBrackets = true;
		m_PresetHigh = Spawn(class'UIIcon', m_CameraPanel).InitIcon('Preset2', , true, , , , OnCameraPresetHigh);
		m_PresetHigh.EnableMouseAutomaticColorStates(eUIState_Normal);
		m_PresetHigh.bDisableSelectionBrackets = true;
		m_PresetLow = Spawn(class'UIIcon', m_CameraPanel).InitIcon('Preset3', , true, , , , OnCameraPresetLow);
		m_PresetLow.EnableMouseAutomaticColorStates(eUIState_Normal);
		m_PresetLow.bDisableSelectionBrackets = true;
		m_PresetProfile = Spawn(class'UIIcon', m_CameraPanel).InitIcon('Preset4', , true, , , , OnCameraPresetProfile);
		m_PresetProfile.EnableMouseAutomaticColorStates(eUIState_Normal);
		m_PresetProfile.bDisableSelectionBrackets = true;
		m_PresetTight = Spawn(class'UIIcon', m_CameraPanel).InitIcon('Preset5', , true, , , , OnCameraPresetTight);
		m_PresetTight.EnableMouseAutomaticColorStates(eUIState_Normal);
		m_PresetTight.bDisableSelectionBrackets = true;
	}

	MC.BeginFunctionOp("setCameraControls");
	MC.QueueString(m_cameraControlPan);//Pan
	MC.QueueString(m_cameraControlTilt);//Tilt
	MC.QueueString(m_cameraControlZoom);//Zoom
	MC.QueueString(m_cameraControlPreset);//Preset
	MC.QueueString("img:///UILibrary_XPACK_Common.Preset_Fullbody");//icon0
	MC.QueueString("img:///UILibrary_XPACK_Common.Preset_Headshot");//icon1
	MC.QueueString("img:///UILibrary_XPACK_Common.Preset_High");//icon2
	MC.QueueString("img:///UILibrary_XPACK_Common.Preset_Low");//icon3
	MC.QueueString("img:///UILibrary_XPACK_Common.Preset_Profile");//icon4
	MC.QueueString("img:///UILibrary_XPACK_Common.Preset_Tight");//icon5
	MC.EndOp();
	

	if (`ISCONTROLLERACTIVE)
	{
		MC.BeginFunctionOp("setConsoleControls");
		MC.QueueString(class'UIUtilities_Input'.const.ICON_LSTICK);//PAN
		MC.QueueString(class'UIUtilities_Input'.const.ICON_RSTICK);//ROTATE
		MC.QueueString(class'UIUtilities_Input'.const.ICON_RT_R2);//ZOOM IN
		MC.QueueString(class'UIUtilities_Input'.const.ICON_LT_L2);//ZOOM OUT
		MC.QueueString("");//PREV
		MC.QueueString("");//NEXT
		MC.EndOp();
	}
	else
	{
		MC.FunctionVoid("setPCControls");
	}
}

function EnableConsoleControls( bool bIsEnabled )
{
	MC.BeginFunctionOp("enableConsoleCameraPanel");
	MC.QueueBoolean(bIsEnabled);
	MC.QueueString(class'UIUtilities_Text'.static.InjectImage(
		class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RB_R1, 40, 26, -10) @ m_strToggleCamera);
	MC.EndOp();
}

function InitPosterButton()
{
	//TabButtons[eUIPropagandaType_Poster] = CreateTabButton(eUIPropagandaType_Poster, "Poster", PosterTab, false);
}

function UIButton CreateTabButton(int Index, string Text, delegate<OnClickedDelegate> ButtonClickedDelegate, bool IsDisabled)
{
	local UIButton TabButton;

	TabButton = Spawn(class'UIButton', self);
	TabButton.ResizeToText = false;
	TabButton.InitButton(Name("inventoryTab" $ Index), "", ButtonClickedDelegate);
	TabButton.SetText(Text);
	TabButton.SetDisabled(IsDisabled);
	TabButton.Show();

	return TabButton;
}

function InitImageSelectorPanel()
{
	// BG must be added before ItemContainer so it draws underneath it
	BG = Spawn(class'UIBGBox', self);
	BG.bAnimateOnInit = bAnimateOnInit;
	BG.bIsNavigable = false;
	BG.InitBG('BGBox', 1500 -(BGPaddingLeft), 340 -(BGPaddingTop), 400 + BGPaddingLeft + BGPaddingRight, 600 + BGPaddingTop + BGPaddingBottom);
	BG.bShouldPlayGenericUIAudioEvents = false;

	m_uiIconSelection = Spawn(class'UIImageSelector', self);
	m_uiIconSelection.InitImageSelector('PhotoboothImageSelector', 1500, 340, 400, 600, IconChooserIcons, PreviewIconSelection, SetIconSelection);
	m_uiIconSelection.Hide();
	BG.Hide();

	ColorSelector = Spawn(class'UIColorSelector', self);
	ColorSelector.InitColorSelector(, ColorSelectorX, ColorSelectorY, ColorSelectorWidth, ColorSelectorHeight,
		`PHOTOBOOTH.m_FontColors, PreviewTextColor, SetTextColor,
		0);

	//ColorSelector.
	ColorSelector.Hide();
}

function PreviewTextColor(int iColorIndex)
{
	if (ColorSelectorState == 0)
		`PHOTOBOOTH.SetTextBoxColor(m_iLastTouchedTextBox, iColorIndex);
	else if (ColorSelectorState == 1)
		`PHOTOBOOTH.SetGradientColorIndex1(iColorIndex);
	else if (ColorSelectorState == 2)
		`PHOTOBOOTH.SetGradientColorIndex2(iColorIndex);
}
function SetTextColor(int iColorIndex)
{
	currentState = eUIPropagandaType_BackgroundOptions;
	if (ColorSelectorState == 0)
	{
		`PHOTOBOOTH.SetTextBoxColor(m_iLastTouchedTextBox, iColorIndex);
		currentState = eUIPropagandaType_Graphics;
	}
	else if(ColorSelectorState == 1)
		`PHOTOBOOTH.SetGradientColorIndex1(iColorIndex);
	else if (ColorSelectorState == 2)
		`PHOTOBOOTH.SetGradientColorIndex2(iColorIndex);

	ColorSelector.Hide();
	NeedsPopulateData();

	//bsg-jedwards (5.1.17) : If using a controller and finished selecting a color, disable the color Navigator and select the List
	if(`ISCONTROLLERACTIVE)
	{
		ColorSelector.DisableNavigation();
		List.SetSelectedNavigation();
	}
	//bsg-jedwards (5.1.17) : end
}

function PreviewIconSelection(int iImageIndex)
{
	m_backgroundPoster.mc.FunctionString("posterSetIcon"$m_iIconIndexChoosing + 1, m_uiIconSelection.ImagePaths[iImageIndex]);
}

function SetIconSelection(int iImageIndex)
{
	`PHOTOBOOTH.SetIcon(m_iIconIndexChoosing, m_uiIconSelection.ImagePaths[iImageIndex]);
	m_uiIconSelection.Hide();
	BG.Hide();
}

function InitGameIndex()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings SettingsState;

	History = `XCOMHISTORY;
	SettingsState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	m_iGameIndex = SettingsState.GameIndex;

	`PHOTOBOOTH.SetGameIndex(m_iGameIndex);
}

// Used to load any necessary content for the photobooth.
function SetupContent();

function GenerateDefaultSoldierSetup()
{
	m_bInitialized = true;

	NeedsPopulateData();
}

function UpdateSoldierData() {}

function CameraActor GetSetupCameraActor()
{
	if (m_kCameraActor == none)
	{
		foreach WorldInfo.AllActors(class'CameraActor', m_kCameraActor)
		{
			if (m_kCameraActor.Tag == DisplayTag)
			{
				break;
			}
		}
	}

	return m_kCameraActor;
}

function TPOV GetCameraPOV();

function MoveCaptureComponent()
{
	local Vector2D TopLeft;
	local Vector2D BottomRight;
	local TPOV cameraPOV;

	cameraPOV = GetCameraPOV();

	`PHOTOBOOTH.SetCameraPOV(cameraPOV, false);

	//if (!bCameraOutlineInited)
	//{
		`PHOTOBOOTH.GetPosterCorners(TopLeft, BottomRight);
		CameraOutline.SetPosition(TopLeft.x * movie.m_v2ScaledDimension.X + movie.m_v2ScaledOrigin.X - 4, TopLeft.y * movie.m_v2ScaledDimension.Y + movie.m_v2ScaledOrigin.Y);
		CameraOutline.SetSize((BottomRight.x - TopLeft.x) * movie.m_v2ScaledDimension.X, (BottomRight.y - TopLeft.y) * movie.m_v2ScaledDimension.Y);

		MC.FunctionVoid("UpdateBackgroundFrame");

		if (TopLeft.x != -1.0 && TopLeft.y != -1.0 && BottomRight.x != -1.0 && BottomRight.y != -1.0)
		{
			bCameraOutlineInited = true;
		}
	//}
}

function MoveFormation()
{
	local PointInSpace PlacementActor;

	PlacementActor = GetFormationPlacementActor();

	if (PlacementActor != none)
	{
		`PHOTOBOOTH.MoveFormation(PlacementActor);
	}
}

function UpdateNavHelp() {}

// override for custom behavior
function OnCancel()
{
	if (bWaitingOnPhoto)
		return;

	switch (currentState)
	{
	case eUIPropagandaType_Base:
		//bsg-hlee (05.12.17): If a picture has not been taken then show the popup.
		if(!bHasTakenPicture)
			DestructiveActionPopup();
		else //Skip the popup and just go to the cleanup and close of the screen.
			OnDestructiveActionPopupExitDialog('eUIAction_Accept');
		//bsg-hlee (05.12.17): End
		break;
	
	case eUIPropagandaType_Soldier:
		m_bRotatingPawn = false;
	case eUIPropagandaType_Pose:
		//bsg-jneal (5.16.17): now changing pose on selection change so need to remember initial pose when cancelling menu
		List.SetSelectedIndex(m_bOriginalSubListIndex);
		List.OnSelectionChanged = none;
		//bsg-jneal (5.16.17): end

		currentState = eUIPropagandaType_SoldierData;
		break;

	//bsg-jedwards (5.1.17) : Hide color selector if backing out
	//case eUIPropagandaType_GradientColor1:
	//case eUIPropagandaType_GradientColor2:
	//	ColorSelector.Hide();
	//	currentState = eUIPropagandaType_Base;
	//	break;
	//bsg-jedwards (5.1.17) : end

	//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	case eUIPropagandaType_Formation:
	case eUIPropagandaType_Layout:
	case eUIPropagandaType_Filter:
	case eUIPropagandaType_Treatment:
		List.SetSelectedIndex(m_bOriginalSubListIndex);
		List.OnSelectionChanged = none;
	case eUIPropagandaType_SoldierData:
	case eUIPropagandaType_BackgroundOptions:
	case eUIPropagandaType_Graphics:
		currentState = eUIPropagandaType_Base;
		break;

	
	case eUIPropagandaType_GradientColor1:
	case eUIPropagandaType_GradientColor2:
		ColorSelector.Hide();
		SetTextColor(m_iPreviousColor);
		currentState = eUIPropagandaType_BackgroundOptions;
		break;

	case eUIPropagandaType_Background:
		List.SetSelectedIndex(m_bOriginalSubListIndex);
		List.OnSelectionChanged = none;
		currentState = eUIPropagandaType_BackgroundOptions;
		break;

	case eUIPropagandaType_TextColor:
		ColorSelector.Hide();
		SetTextColor(m_iPreviousColor);
		currentState = eUIPropagandaType_Graphics;
		break;
	//bsg-jneal (5.23.17): end
	case eUIPropagandaType_TextFont:
	case eUIPropagandaType_Fonts:
		currentState = eUIPropagandaType_Graphics;
		break;
	}
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function SetTabHighlight(int TabIndex)
{
	MC.BeginFunctionOp("setTabHighlight");
	MC.QueueNumber(TabIndex);
	MC.EndOp();
}

function SetCategory(string Category)
{
	MC.BeginFunctionOp("setListTitle");
	MC.QueueString( Category );
	MC.EndOp();
}

function OnFormationLoaded()
{
	local int i;

	if (--NumPawnsNeedingUpdateAfterFormationChange <= 0)
	{
		for (i = 0; i < `PHOTOBOOTH.m_arrUnits.Length; ++i)
		{
			if (`PHOTOBOOTH.m_arrUnits[i].FramesToHide > 0)
			{
				SetTimer(0.001f, false, nameof(OnFormationLoaded));
				return;
			}
		}
		
		if (bUpdateCameraWithFormation)
		{
			OnCameraPreset("Full Frontal");
		}
	}
}

function int SetFormation(int FormationIndex, optional bool bSetCallback = false)
{
	local array<X2PropagandaPhotoTemplate> arrFormations;

	`PHOTOBOOTH.GetFormations(arrFormations);
	`PHOTOBOOTH.ChangeFormation(arrFormations[FormationIndex]);
	if (bSetCallback)
	{
		NumPawnsNeedingUpdateAfterFormationChange = `PHOTOBOOTH.SetPawnCreatedDelegate(OnFormationLoaded);
	}

	return arrFormations[FormationIndex].NumSoldiers;
}

//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
function OnConfirmFormation()
{
	List.OnSelectionChanged = none;
	currentState = eUIPropagandaType_Base;
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function OnSetFormation(UIList ContainerList, int ItemIndex)
{	
	SetFormation(List.SelectedIndex, true);
}
//bsg-jneal (5.23.17): end

function OnClickFormation()
{
	currentState = eUIPropagandaType_Formation;
	NeedsPopulateData();
}

function OnClickBackgroundOptions()
{
	currentState = eUIPropagandaType_BackgroundOptions;
	NeedsPopulateData();
}

function SoldierPawnCreated()
{
	local Photobooth_AutoTextUsage autoText;

	NeedsPopulateData();

	switch (`PHOTOBOOTH.GetTotalActivePawns())
	{
	case 1:
		autoText = ePBAT_SOLO;
		break;
	case 2:
		autoText = ePBAT_DUO;
		break;
	default:
		autoText = ePBAT_SQUAD;
		break;
	}
	if(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress') == none)
		`PHOTOBOOTH.SetAutoTextStrings(autoText, ePBTLS_Auto);
}

function SetSoldier(int LocationIndex, int SoldierIndex)
{
	local array<StateObjectReference> arrSoldiers;
	local StateObjectReference Soldier;

	if (SoldierIndex < 0)
	{
		Soldier.ObjectID = 0;
	}
	else
	{
		`PHOTOBOOTH.GetPossibleSoldiers(LocationIndex, m_arrSoldiers, arrSoldiers);
		Soldier = arrSoldiers[SoldierIndex];
	}	

	`PHOTOBOOTH.SetSoldier(LocationIndex, Soldier, false, SoldierPawnCreated);
}

function OnSetSoldier()
{
	SetSoldier(m_iLastTouchedSoldierIndex, List.SelectedIndex - 1);

	currentState = eUIPropagandaType_SoldierData;
	NeedsPopulateData();
}

function OnClickSoldiers()
{
	currentState = eUIPropagandaType_SoldierData;
	NeedsPopulateData();
}

function SetLastTouchedSoldier(int SoldierIndex)
{
	m_iLastTouchedSoldierIndex = SoldierIndex;
}

function OnChooseSoldier0()
{
	SetLastTouchedSoldier(0);
	currentState = eUIPropagandaType_Soldier;
	NeedsPopulateData();
}
function OnChooseSoldier1()
{
	SetLastTouchedSoldier(1);
	currentState = eUIPropagandaType_Soldier;
	NeedsPopulateData();
}
function OnChooseSoldier2()
{
	SetLastTouchedSoldier(2);
	currentState = eUIPropagandaType_Soldier;
	NeedsPopulateData();
}
function OnChooseSoldier3()
{
	SetLastTouchedSoldier(3);
	currentState = eUIPropagandaType_Soldier;
	NeedsPopulateData();
}
function OnChooseSoldier4()
{
	SetLastTouchedSoldier(4);
	currentState = eUIPropagandaType_Soldier;
	NeedsPopulateData();
}
function OnChooseSoldier5()
{
	SetLastTouchedSoldier(5);
	currentState = eUIPropagandaType_Soldier;
	NeedsPopulateData();
}

function OnChoosePose0()
{
	SetLastTouchedSoldier(0);
	currentState = eUIPropagandaType_Pose;
	NeedsPopulateData();
}
function OnChoosePose1()
{
	SetLastTouchedSoldier(1);
	currentState = eUIPropagandaType_Pose;
	NeedsPopulateData();
}
function OnChoosePose2()
{
	SetLastTouchedSoldier(2);
	currentState = eUIPropagandaType_Pose;
	NeedsPopulateData();
}
function OnChoosePose3()
{
	SetLastTouchedSoldier(3);
	currentState = eUIPropagandaType_Pose;
	NeedsPopulateData();
}
function OnChoosePose4()
{
	SetLastTouchedSoldier(4);
	currentState = eUIPropagandaType_Pose;
	NeedsPopulateData();
}
function OnChoosePose5()
{
	SetLastTouchedSoldier(5);
	currentState = eUIPropagandaType_Pose;
	NeedsPopulateData();
}

function OnRotateSoldier0()
{
	SetLastTouchedSoldier(0);
}
function OnRotateSoldier1()
{
	SetLastTouchedSoldier(1);
}
function OnRotateSoldier2()
{
	SetLastTouchedSoldier(2);
}
function OnRotateSoldier3()
{
	SetLastTouchedSoldier(3);
}
function OnRotateSoldier4()
{
	SetLastTouchedSoldier(4);
}
function OnRotateSoldier5()
{
	SetLastTouchedSoldier(5);
}

function OnChooseTextBoxColor0()
{
	m_iLastTouchedTextBox = 0;
	currentState = eUIPropagandaType_TextColor;
	NeedsPopulateData();
}
function OnChooseTextBoxColor1()
{
	m_iLastTouchedTextBox = 1;
	currentState = eUIPropagandaType_TextColor;
	NeedsPopulateData();
}
function OnChooseTextBoxColor2()
{
	m_iLastTouchedTextBox = 2;
	currentState = eUIPropagandaType_TextColor;
	NeedsPopulateData();
}
function OnChooseTextBoxColor3()
{
	m_iLastTouchedTextBox = 3;
	currentState = eUIPropagandaType_TextColor;
	NeedsPopulateData();
}

function OnChooseTextBoxFont0()
{
	m_iLastTouchedTextBox = 0;
	currentState = eUIPropagandaType_TextFont;
	NeedsPopulateData();
}
function OnChooseTextBoxFont1()
{
	m_iLastTouchedTextBox = 1;
	currentState = eUIPropagandaType_TextFont;
	NeedsPopulateData();
}
function OnChooseTextBoxFont2()
{
	m_iLastTouchedTextBox = 2;
	currentState = eUIPropagandaType_TextFont;
	NeedsPopulateData();
}
function OnChooseTextBoxFont3()
{
	m_iLastTouchedTextBox = 3;
	currentState = eUIPropagandaType_TextFont;
	NeedsPopulateData();
}

function OnChooseBackgroundColor1()
{
	currentState = eUIPropagandaType_GradientColor1;
	NeedsPopulateData();
}
function OnChooseBackgroundColor2()
{
	currentState = eUIPropagandaType_GradientColor2;
	NeedsPopulateData();
}

function OnToggleBackgroundTint(UICheckbox CheckboxControl)
{
	`PHOTOBOOTH.SetBackgroundColorOverride(CheckboxControl.bChecked);
}

function RotateSoldierSlider(UISlider SliderControl)
{
	local int i;
	for (i = 0; i < List.ItemCount; i++)
	{
		if (GetListItem(i).Slider == SliderControl)
		{
			m_iLastTouchedSoldierIndex = i / 4;
		}
	}

	`PHOTOBOOTH.ActorRotation[m_iLastTouchedSoldierIndex] = `PHOTOBOOTH.m_arrUnits[m_iLastTouchedSoldierIndex].ActorPawn.Rotation;
	`PHOTOBOOTH.ActorRotation[m_iLastTouchedSoldierIndex].Yaw = SliderControl.percent * SoldierRotationMultiplier;
}


function OnToggleRotateSoldier(UICheckbox CheckboxControl)
{
	local int i;
	for (i = 0; i < List.ItemCount; i++)
	{
		if(GetListItem(i).Checkbox == CheckboxControl)
		{
			m_iLastTouchedSoldierIndex = (i-1) / 3;
		}
		else if (GetListItem(i).Checkbox != none)
		{
			GetListItem(i).Checkbox.SetChecked(false);
		}
	}
	m_bRotatingPawn = CheckboxControl.bChecked;
	`PHOTOBOOTH.ActorRotation[m_iLastTouchedSoldierIndex] = `PHOTOBOOTH.m_arrUnits[m_iLastTouchedSoldierIndex].ActorPawn.Rotation;
}

function SetAnimationPoseForSoldier(int LocationIndex, int AnimationIndex, optional bool bUseDuoPose = false)
{
	local array<AnimationPoses> arrAnimations;

	`PHOTOBOOTH.GetAnimations(LocationIndex, arrAnimations, , DefaultSetupSettings.TextLayoutState == ePBTLS_DeadSoldier);

	if (bUseDuoPose)
	{
		AnimationIndex = `PHOTOBOOTH.GetDuoAnimIndex(LocationIndex, AnimationIndex, arrAnimations);
	}

	`PHOTOBOOTH.SetSoldierAnim(LocationIndex, arrAnimations[AnimationIndex].AnimationName, arrAnimations[AnimationIndex].AnimationOffset);
}

function int SetRandomAnimationPoseForSoldier(int LocationIndex, optional bool bPreventDuplicates = false, optional out array<AnimationPoses> arrAnimationsAlreadyUsed)
{
	local array<AnimationPoses> arrAnimations, arrOrigAnimations;
	local int AnimationIndex, i, Rolls;
	local XComGameState_Unit Unit;
	local Photobooth_AnimationFilterType ClassFilter;
	local bool bUseClassPose, bPoseNotFound;

	AnimationIndex = 0;
	if (LocationIndex >= 0 && LocationIndex < `PHOTOBOOTH.m_arrUnits.Length && `PHOTOBOOTH.m_arrUnits[locationIndex].UnitRef.ObjectID > 0)
	{
		`PHOTOBOOTH.GetAnimations(LocationIndex, arrOrigAnimations, , DefaultSetupSettings.TextLayoutState == ePBTLS_DeadSoldier, true);

		Rolls = bPreventDuplicates ? 100 : 1;
		while (--Rolls >= 0)
		{
			arrAnimations = arrOrigAnimations;
			ClassFilter = ePAFT_None;

			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`PHOTOBOOTH.m_arrUnits[locationIndex].UnitRef.ObjectID));
			if (Unit != none)
			{
				switch (Unit.GetSoldierClassTemplateName())
				{
				case 'Grenadier':
					ClassFilter = ePAFT_Grenadier;
					break;
				case 'Ranger':
					ClassFilter = ePAFT_Ranger;
					break;
				case 'Sharpshooter':
					ClassFilter = ePAFT_Sharpshooter;
					break;
				case 'PsiOperative':
					ClassFilter = ePAFT_PsiOperative;
					break;
				case 'Specialist':
					ClassFilter = ePAFT_Specialist;
					break;
				case 'Skirmisher':
					ClassFilter = ePAFT_Skirmisher;
					break;
				case 'Templar':
					ClassFilter = ePAFT_Templar;
					break;
				case 'Reaper':
					ClassFilter = ePAFT_Reaper;
					break;
				}
			}

			if (ClassFilter != ePAFT_None && DefaultSetupSettings.TextLayoutState != ePBTLS_DeadSoldier)
			{
				bUseClassPose = false;
				for (i = 0; i < m_arrClassPoseChances.length; ++i)
				{
					if (m_arrClassPoseChances[i].AnimType == ClassFilter)
					{
						bUseClassPose = `SYNC_RAND(100) < m_arrClassPoseChances[i].Chance;
						break;
					}
				}

				if (bUseClassPose)
				{
					for (i = 0; i < arrAnimations.length; ++i)
					{
						if (arrAnimations[i].AnimType != ClassFilter)
						{
							arrAnimations.Remove(i--, 1);
						}
					}
				}
			}

			AnimationIndex = `SYNC_RAND(arrAnimations.length);

			if (bPreventDuplicates)
			{
				bPoseNotFound = true;
				for (i = 0; i < arrAnimationsAlreadyUsed.Length; ++i)
				{
					if (arrAnimationsAlreadyUsed[i].AnimationName == arrAnimations[AnimationIndex].AnimationName &&
						arrAnimationsAlreadyUsed[i].AnimationOffset == arrAnimations[AnimationIndex].AnimationOffset)
					{
						bPoseNotFound = false;
						break;
					}
				}

				if (bPoseNotFound)
				{
					arrAnimationsAlreadyUsed.AddItem(arrAnimations[AnimationIndex]);
					Rolls = 0;
				}
			}
		}

		`PHOTOBOOTH.SetSoldierAnim(LocationIndex, arrAnimations[AnimationIndex].AnimationName, arrAnimations[AnimationIndex].AnimationOffset);
	}

	return AnimationIndex;
}

//bsg-jneal (5.16.17): confirm on pose menu now exits since pose selection was done on list selection changed
function OnConfirmPose()
{
	List.OnSelectionChanged = none;
	currentState = eUIPropagandaType_SoldierData;
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function OnSetPose(UIList ContainerList, int ItemIndex)
{
	local array<AnimationPoses> arrAnimations;
	local int CurrAnimationIndex;

	CurrAnimationIndex = `PHOTOBOOTH.GetAnimations(m_iLastTouchedSoldierIndex, arrAnimations, , DefaultSetupSettings.TextLayoutState == ePBTLS_DeadSoldier);

	if (List.SelectedIndex != CurrAnimationIndex)
	{
		`PHOTOBOOTH.SetSoldierAnim(m_iLastTouchedSoldierIndex, arrAnimations[List.SelectedIndex].AnimationName, arrAnimations[List.SelectedIndex].AnimationOffset);
	}
}
//bsg-jneal (5.16.17): end

function OnMakePosterSelected(UIButton ButtonControl)
{
	local XComGameState NewGameState;
	local array<int> ObjectIDs;
	local EPhotoDataType PhotoType;
	local bool bDeleteAutoGenPhoto;

	if (`PHOTOBOOTH.m_kAutoGenCaptureState != eAGCS_Capturing && !bWaitingOnPhoto)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.Roll(default.PhotoCommentChance))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Photobooth Comment");
			`XEVENTMGR.TriggerEvent('OnPhotoTaken', , , NewGameState);
			`GAMERULES.SubmitGameState(NewGameState);
		}

		PlayAKEvent(AkEvent'XPACK_SoundStrategyUI.PhotoBooth_CameraFlash');
		MC.FunctionVoid("AnimateFlash");
		bWaitingOnPhoto = true;

		bDeleteAutoGenPhoto = false;
		switch (DefaultSetupSettings.TextLayoutState)
		{
		case ePBTLS_DeadSoldier:
			PhotoType = ePDT_Dead;
			bDeleteAutoGenPhoto = true;
			ObjectIDs.AddItem(DefaultSetupSettings.PossibleSoldiers[0].ObjectID);
			break;
		case ePBTLS_PromotedSoldier:
			PhotoType = ePDT_Promoted;
			bDeleteAutoGenPhoto = true;
			ObjectIDs.AddItem(DefaultSetupSettings.PossibleSoldiers[0].ObjectID);
			break;
		case ePBTLS_BondedSoldier:
			PhotoType = ePDT_Bonded;
			bDeleteAutoGenPhoto = true;
			ObjectIDs.AddItem(DefaultSetupSettings.PossibleSoldiers[0].ObjectID);
			ObjectIDs.AddItem(DefaultSetupSettings.PossibleSoldiers[1].ObjectID);
			break;
		}

		if (bDeleteAutoGenPhoto)
		{
			if (DefaultSetupSettings.PossibleSoldiers.Length > 0)
			{
				`HQPRES.GetPhotoboothAutoGen().CancelRequest(DefaultSetupSettings.PossibleSoldiers[0], DefaultSetupSettings.TextLayoutState);
				`XENGINE.m_kPhotoManager.DeleteDuplicatePoster(m_iGameIndex, ObjectIDs, PhotoType);
			}
		}

		`PHOTOBOOTH.CreatePoster(4, CreatePosterCallback);
		`PHOTOBOOTH.m_kAutoGenCaptureState = eAGCS_Capturing;
		bHasTakenPicture = true; //bgs-hlee (05.15.17): Picture taken at this point.
	}
}

function CreatePosterCallback(StateObjectReference UnitRef);

function HideListItems()
{
	local int i;

	if(`ISCONTROLLERACTIVE)
	{
		for (i = 0; i < List.ItemCount; ++i)
		{
			List.GetItem(i).OnLoseFocus();
			UIMechaListItem(List.GetItem(i)).SetDisabled(false);
			List.GetItem(i).Hide();
			List.GetItem(i).RemoveTooltip();

			//bsg-jedwards (5.1.17) : do not disable navigation with controller, could cause issues where navigation would no longer work on reset
			if(!`ISCONTROLLERACTIVE)
			{
				List.GetItem(i).DisableNavigation();
			}
			//bsg-jedwards (5.1.17) : end
		}
	}
	else
	{
		for (i = 0; i < List.ItemCount; ++i)
		{
			List.GetItem(i).Destroy();
		}

		List.ClearItems();
	}
}

function GetFormationData(out array<String> outFormationNames, out int outFormationIndex)
{
	local array<X2PropagandaPhotoTemplate> arrFormations;
	local int i;

	outFormationIndex = `PHOTOBOOTH.GetFormations(arrFormations);
	outFormationNames.Length = 0;

	for (i = 0; i < arrFormations.Length; ++i)
	{
		outFormationNames.AddItem(arrFormations[i].DisplayName);
	}
}

function GetSoldierData(int LocationIndex, out array<String> outSoldierNames, out int outSoldierIndex)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> arrPossibleSoldiers;
	local int i;

	History = `XCOMHISTORY;	
	outSoldierIndex = `PHOTOBOOTH.GetPossibleSoldiers(LocationIndex, m_arrSoldiers, arrPossibleSoldiers);

	outSoldierNames.Length = 0;
	outSoldierNames.AddItem(m_strEmptyOption);
	outSoldierIndex++;

	for (i = 0; i < arrPossibleSoldiers.Length; ++i)
	{		
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(arrPossibleSoldiers[i].ObjectID));
		outSoldierNames.AddItem(Unit.GetName(eNameType_Full));
	}
}

function GetBackgroundData(out array<String> outBackgroundNames, out int outBackgroundIndex, optional Photobooth_TeamUsage TeamUsage = ePBT_ALL)
{
	local array<BackgroundPosterOptions> arrBackgrounds;
	local int i;

	outBackgroundIndex = `PHOTOBOOTH.GetBackgrounds(arrBackgrounds, TeamUsage);
	
	for (i = 0; i < arrBackgrounds.Length; ++i)
	{
		outBackgroundNames.AddItem(arrBackgrounds[i].BackgroundDisplayName);
	}	
}

function GetFirstPassFilterData(out array<String> outFilterNames, out int outFilterIndex)
{
	local array<FilterPosterOptions> arrFilters;
	local int i;

	outFilterIndex = `PHOTOBOOTH.GetFirstPassFilters(arrFilters);

	for (i = 0; i < arrFilters.Length; ++i)
	{
		outFilterNames.AddItem(arrFilters[i].FilterDisplayName);
	}
}

function GetSecondPassFilterData(out array<String> outFilterNames, out int outFilterIndex)
{
	local array<FilterPosterOptions> arrFilters;
	local int i;

	outFilterIndex = `PHOTOBOOTH.GetSecondPassFilters(arrFilters);

	for (i = 0; i < arrFilters.Length; ++i)
	{
		outFilterNames.AddItem(arrFilters[i].FilterDisplayName);
	}
}

function GetCameraPresetNames(out array<String> outFilterNames)
{
	local array<PhotoboothCameraPreset> arrCameraPresets;
	local int i;

	`PHOTOBOOTH.GetCameraPresets(arrCameraPresets);

	for (i = 0; i < arrCameraPresets.Length; ++i)
	{
		outFilterNames.AddItem(arrCameraPresets[i].DisplayName);
	}
}

function GetAnimationData(int LocationIndex, out array<String> outAnimationNames, out int outAnimationIndex)
{
	local array<AnimationPoses> arrAnimations;
	local int i;

	outAnimationIndex = `PHOTOBOOTH.GetAnimations(LocationIndex, arrAnimations, , DefaultSetupSettings.TextLayoutState == ePBTLS_DeadSoldier);

	outAnimationNames.Length = 0;
	for (i = 0; i < arrAnimations.Length; ++i)
	{
		outAnimationNames.AddItem(arrAnimations[i].AnimationDisplayName);
	}
}

function SetBackground(int Selection, optional Photobooth_TeamUsage TeamUsage = ePBT_ALL, optional bool bOverrideAllowTinting = true)
{
	local array<BackgroundPosterOptions> arrBackgrounds;

	`PHOTOBOOTH.GetBackgrounds(arrBackgrounds, TeamUsage);

	if (DefaultSetupSettings.BackgroundDisplayName == m_strEmptyOption)
		DefaultSetupSettings.BackgroundDisplayName = arrBackgrounds[Selection].BackgroundDisplayName;

	`PHOTOBOOTH.SetBackgroundTexture(arrBackgrounds[Selection].BackgroundDisplayName);

	if (!bOverrideAllowTinting)
	{
		`PHOTOBOOTH.SetBackgroundColorOverride(arrBackgrounds[Selection].bAllowTintingOnRandomize);
	}
}

function OnClickBackground()
{
	currentState = eUIPropagandaType_Background;
	NeedsPopulateData();
}

//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
function OnConfirmBackground()
{
	List.OnSelectionChanged = none;
	currentState = eUIPropagandaType_BackgroundOptions;
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function OnSetBackground(UIList ContainerList, int ItemIndex)
{	
	SetBackground(List.SelectedIndex);
}
//bsg-jneal (5.23.17): end

function SetFirstPassFilter(int FilterSelection)
{
	`PHOTOBOOTH.SetFirstPassFilter(FilterSelection);
}

//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
function OnConfirmFirstPassFilter()
{
	List.OnSelectionChanged = none;
	currentState = eUIPropagandaType_Base;
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function OnSetFirstPassFilter(UIList ContainerList, int ItemIndex)
{
	SetFirstPassFilter(List.SelectedIndex );
}
//bsg-jneal (5.23.17): end
function OnSetFont()
{
	local array<FontOptions> arrFontOptions;
	`PHOTOBOOTH.GetFonts(arrFontOptions);
	`PHOTOBOOTH.SetTextBoxFont(m_iLastTouchedTextBox, arrFontOptions[List.SelectedIndex].FontName);
}

function OnClickFirstPassFilter()
{
	currentState = eUIPropagandaType_Filter;
	NeedsPopulateData();
}

function SetSecondPassFilter(int FilterSelection)
{
	`PHOTOBOOTH.SetSecondPassFilter(FilterSelection);
}

//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
function OnConfirmSecondPassFilter()
{
	List.OnSelectionChanged = none;
	currentState = eUIPropagandaType_Base;
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function OnSetSecondPassFilter(UIList ContainerList, int ItemIndex)
{
	SetSecondPassFilter(List.SelectedIndex);
}
//bsg-jneal (5.23.17): end
function OnClickSecondPassFilter()
{
	currentState = eUIPropagandaType_Treatment;
	NeedsPopulateData();
}

function HideEntirePoster(bool bHide)
{
	`PHOTOBOOTH.HideEntirePoster(bHide);
}

function HidePosterElements(bool bHide)
{
	`PHOTOBOOTH.HidePosterElements(bHide);
}

function OnHidePoster(UICheckbox CheckboxControl)
{
	HidePosterElements(CheckboxControl.bChecked);
}

function InitializeFormation();
function RandomSetBackground();
function bool RandomSetCamera();

function OnRandomize()
{
	m_kGenRandomState = eAGCS_TickPhase1;
	
	//bsg-jneal (5.23.17): reset list index to properly reset the highlight
	if(`ISCONTROLLERACTIVE)
	{
		List.OnSelectionChanged = none; // don't let selection changed callback reset away from randomize index, better user experience
		List.SetSelectedIndex(-1);
	}
	//bsg-jneal (5.23.17): end
}

function OnReset()
{
	local int loopIndex;
	local StateObjectReference Soldier;
	Soldier.ObjectID = 0;
	m_bResetting = true;
	m_kGenRandomState = eAGCS_TickPhase1;
	`PHOTOBOOTH.ChangeFormation(DefaultSetupSettings.FormationTemplate);
	HidePosterElements(false); //bsg-hlee (05.12.17): Don't hide the poster on reset.

	//bsg-jedwards (5.1.17) : Resets the index to the beginning when reset
	if(`ISCONTROLLERACTIVE)
	{
		ModeSpinnerVal = 0;

		List.SetSelectedIndex(-1); //bsg-jneal (5.23.17): reset list index to properly reset the highlight
	}
	//bsg-jedwards (5.1.17) : end

	for (loopIndex = 0; loopIndex < 6; loopIndex++)
	{
		if (loopIndex >= DefaultSetupSettings.PossibleSoldiers.length)
		{
			`PHOTOBOOTH.SetSoldier(loopIndex, Soldier);
		}
		else
		{
			`PHOTOBOOTH.SetSoldier(loopIndex, DefaultSetupSettings.PossibleSoldiers[loopIndex]);
		}
	}
}

function UpdateCameraToPOV(PhotoboothCameraSettings CameraSettings, bool SnapToFinal);

function OnCameraPreset(string selection, optional bool bUpdateViewDistance = true)
{
	local array<PhotoboothCameraPreset> arrCameraPresets;
	local PhotoboothCameraSettings CameraSettings;
	local int i;

	`PHOTOBOOTH.GetCameraPresets(arrCameraPresets);

	for (i = 0; i < arrCameraPresets.Length; i++)
	{
		if (arrCameraPresets[i].TemplateName == selection)
			break;
	}

	if (`PHOTOBOOTH.GetCameraPOVForPreset(arrCameraPresets[i], CameraSettings, bUpdateViewDistance))
	{
		UpdateCameraToPOV(CameraSettings, false);
	}
}

function OnCameraPresetFullBody()
{
	OnCameraPreset("Full Frontal");
}
function OnCameraPresetHeadshot()
{
	OnCameraPreset("Headshot");
}
function OnCameraPresetHigh()
{
	OnCameraPreset("High");
}
function OnCameraPresetLow()
{
	OnCameraPreset("Low");
}
function OnCameraPresetProfile()
{
	OnCameraPreset("Side");
}
function OnCameraPresetTight()
{
	OnCameraPreset("Tight");
}

function PopulateDefaultList(out int Index)
{
	local array<string> FilterNames;
	local int FilterIndex;

	GetListItem(Index++).UpdateDataValue(m_CategoryFormations, `PHOTOBOOTH.m_kFormationTemplate.DisplayName, OnClickFormation);

	//GetSoldierData(j, SoldierNames, SoldierIndex);
	GetListItem(Index++).UpdateDataDescription(m_CategorySoldiers, OnClickSoldiers);

	GetListItem(Index++).UpdateDataDescription(m_CategoryBackgroundOptions, OnClickBackgroundOptions);

	//GetLayoutNames(LayoutNames);
	GetListItem(Index++).UpdateDataValue(m_CategoryLayout, `PHOTOBOOTH.m_currentTextLayoutTemplate.DisplayName, OnClickTextLayout);

	GetListItem(Index++).UpdateDataDescription(m_CategoryGraphics, OnClickGraphics);
	if (bChallengeMode)
	{
		GetListItem(Index - 1).SetDisabled(true);
	}
	
	GetFirstPassFilterData(FilterNames, FilterIndex);
	GetListItem(Index++).UpdateDataValue(m_CategoryFilter, FilterNames[FilterIndex], OnClickFirstPassFilter);

	FilterNames.Length = 0;
	GetSecondPassFilterData(FilterNames, FilterIndex);
	GetListItem(Index++).UpdateDataValue(m_CategoryTreatment, FilterNames[FilterIndex], OnClickSecondPassFilter);

	GetListItem(Index++).UpdateDataCheckbox(m_CategoryHidePoster, "", `PHOTOBOOTH.PosterElementsHidden(), OnHidePoster);

	//bsg-jedwards (5.1.17) : Adds Spinner to the options when using a controller
	if(`ISCONTROLLERACTIVE)
	{
		GetListItem(Index++).UpdateDataSpinner(m_CategoryCameraPresets, m_CameraPresets_Labels[ModeSpinnerVal], UpdateMode_OnChanged);
	}
	//bsg-jedwards (5.1.17) : end

	GetListItem(Index++).UpdateDataDescription(m_CategoryRandom, OnRandomize);

	GetListItem(Index++).UpdateDataDescription(m_CategoryReset, OnReset);

	List.OnSelectionChanged = OnDefaultListChange; //bsg-jneal (5.23.17): saving default list index for better nav
}

//bsg-jneal (5.23.17): saving default list index for better nav
function OnDefaultListChange(UIList ContainerList, int ItemIndex)
{
	m_iDefaultListIndex = List.SelectedIndex;
}
//bsg-jneal (5.23.17): end

//bsg-jedwards (5.1.17) : Allows the index to move appropriately when used
public function UpdateMode_OnChanged(UIListItemSpinner SpinnerControl, int Direction)
{
	ModeSpinnerVal += direction;

	//bsg-jedwards (5.4.17) : Use max spinner value instead of harcoded number
	if (ModeSpinnerVal < 0)
		ModeSpinnerVal = max_SpinnerVal;
	else if (ModeSpinnerVal > max_SpinnerVal)
		ModeSpinnerVal = 0;
	//bsg-jedwards (5.4.17) : end

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	ChangeCameraPresetView(ModeSpinnerVal);

	SpinnerControl.SetValue(m_CameraPresets_Labels[ModeSpinnerVal]);
}

//bsg-jedwards (5.4.17) : Created in parent class to be used in Armory and Tactical Photobooth
public function ChangeCameraPresetView(int SpinnerValue)
{
}
//bsg-jedwards (4.7.17) : end
//bsg-jedwards (5.4.17) : end

function PopulateFormationList(out int Index)
{
	local array<string> FormationNames;
	local int FormationIndex;
	local int i;
	GetFormationData(FormationNames, FormationIndex);

	for (i = 0; i < FormationNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(FormationNames[i], OnConfirmFormation); //bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	}

	//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	m_bOriginalSubListIndex = FormationIndex;
	List.OnSelectionChanged = OnSetFormation;
	//bsg-jneal (5.23.17): end
}

function PopulateSoldierList(out int Index)
{
	local array<string> SoldierNames;
	local int SoldierIndex, i;

	GetSoldierData(m_iLastTouchedSoldierIndex, SoldierNames, SoldierIndex);
	for (i = 0; i < SoldierNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(SoldierNames[i], OnSetSoldier);
	}

	List.Scrollbar.SetPercent(0);
}

function PopulatePoseList(out int Index)
{
	local array<string> AnimationNames;
	local int AnimationIndex, i;

	GetAnimationData(m_iLastTouchedSoldierIndex, AnimationNames, AnimationIndex);
	for (i = 0; i < AnimationNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(AnimationNames[i], OnConfirmPose); //bsg-jneal (5.16.17): now changing pose on selection change
	}

	//bsg-jneal (5.16.17): now changing pose on selection change so need to remember initial pose when cancelling menu
	m_bOriginalSubListIndex = AnimationIndex;
	List.OnSelectionChanged = OnSetPose;
	//bsg-jneal (5.16.17): end
}

function PopulateBackgroundOptionsList(out int Index)
{
	local array<string> BackgroundNames;
	local int BackgroundIndex;

	GetBackgroundData(BackgroundNames, BackgroundIndex);
	GetListItem(Index++).UpdateDataValue(m_CategoryBackground, BackgroundNames[BackgroundIndex], OnClickBackground);

	GetListItem(Index++).UpdateDataCheckbox(m_CategoryToggleBackgroundTint, "", `PHOTOBOOTH.m_kPhotoboothEffect.bOverrideBackgroundTextureColor, OnToggleBackgroundTint);

	GetListItem(Index++).UpdateDataColorChip(m_CategoryBackgroundTint1, class'UIUtilities_Colors'.static.LinearColorToFlashHex(`PHOTOBOOTH.m_kPhotoboothEffect.GradientColor1), OnChooseBackgroundColor1);
	GetListItem(Index++).UpdateDataColorChip(m_CategoryBackgroundTint2, class'UIUtilities_Colors'.static.LinearColorToFlashHex(`PHOTOBOOTH.m_kPhotoboothEffect.GradientColor2), OnChooseBackgroundColor2);
}

function PopulateBackgroundList(out int Index)
{
	local array<string> BackgroundNames;
	local int BackgroundIndex, i;

	GetBackgroundData(BackgroundNames, BackgroundIndex);
	for (i = 0; i < BackgroundNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(BackgroundNames[i], OnConfirmBackground); //bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	}

	//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	m_bOriginalSubListIndex = BackgroundIndex;
	List.OnSelectionChanged = OnSetBackground;
	//bsg-jneal (5.23.17): end
}

function PopulateGraphicsList(out int Index)
{
	local array<string> FontNames;
	local int i;
	local delegate<OnClickDelegate> OnChooseTextColorDel, OnChooseTextFontDel;

	GetFontDataSpecific(FontNames, `PHOTOBOOTH.m_PosterFont);
	for (i = 0; i < `PHOTOBOOTH.m_currentTextLayoutTemplate.NumTextBoxes; i++)
	{
		switch (i)
		{
		case 0:
			OnChooseTextColorDel = OnChooseTextBoxColor0;
			OnChooseTextFontDel = OnChooseTextBoxFont0;
			break;
		case 1:
			OnChooseTextColorDel = OnChooseTextBoxColor1;
			OnChooseTextFontDel = OnChooseTextBoxFont1;
			break;
		case 2:
			OnChooseTextColorDel = OnChooseTextBoxColor2;
			OnChooseTextFontDel = OnChooseTextBoxFont2;
			break;
		case 3:
			OnChooseTextColorDel = OnChooseTextBoxColor3;
			OnChooseTextFontDel = OnChooseTextBoxFont3;
			break;
		}
		GetListItem(Index++).UpdateDataDescription(m_PrefixTextBox @ i + 1 @ `PHOTOBOOTH.m_PosterStrings[i], UpdateTextBox);

		if (bLadderMode)
			GetListItem( Index - 1 ).SetDisabled( true );

		GetListItem(Index++).UpdateDataColorChip(m_PrefixTextBoxColor @ i + 1 , `PHOTOBOOTH.m_FontColors[`PHOTOBOOTH.m_PosterStringColors[i]], OnChooseTextColorDel);
		GetListItem(Index++).UpdateDataValue(m_PrefixTextBoxFont @ i + 1, FontNames[i], OnChooseTextFontDel);
		//GetListItem(Index++).UpdateDataSlider(m_PrefixTextBoxFont @ i + 1, m_PrefixTextBoxFont @ i + 1, `PHOTOBOOTH.m_FontSize[i], , UpdateTextSize);
	}
}

function PopulateFontList(out int Index)
{
	local array<string> FontNames;
	local int i;
	GetFontData(FontNames);

	for (i = 0; i < FontNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(FontNames[i], OnSetFont);
	}
}

function PopulateTextColors(out int Index)
{
	ColorSelectorState = 0;
	ColorSelector.Show();
	ColorSelector.InitialSelection = `PHOTOBOOTH.m_PosterStringColors[m_iLastTouchedTextBox];
	ColorSelector.SetInitialSelection();
	m_iPreviousColor = `PHOTOBOOTH.m_PosterStringColors[m_iLastTouchedTextBox];

	//bsg-jedwards (5.1.17) : If we're using a controller, re-enable the Color Selector and make it the selected navigation
	if(`ISCONTROLLERACTIVE)
	{
		ColorSelector.EnableNavigation();
		ColorSelector.SetSelectedNavigation();
	}
	//bsg-jedwards (5.1.17) : end
}

function PopulateBackground1Colors(out int Index)
{
	ColorSelectorState = 1;
	ColorSelector.Show();
	ColorSelector.InitialSelection = `PHOTOBOOTH.m_iGradientColor1Index;
	ColorSelector.SetInitialSelection();
	m_iPreviousColor = `PHOTOBOOTH.m_iGradientColor1Index;
}

function PopulateBackground2Colors(out int Index)
{
	ColorSelectorState = 2;
	ColorSelector.Show();
	ColorSelector.InitialSelection = `PHOTOBOOTH.m_iGradientColor2Index;
	ColorSelector.SetInitialSelection();
	m_iPreviousColor = `PHOTOBOOTH.m_iGradientColor2Index; //bsg-hlee (05.12.17): The prev color here should use the current second color.
}

function PopulateLayoutList(out int Index)
{
	local array<string> LayoutNames;
	local int i;
	GetLayoutNames(LayoutNames);
	for (i = 0; i < LayoutNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(LayoutNames[i], OnConfirmLayout); //bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	}

	//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	m_bOriginalSubListIndex = `PHOTOBOOTH.GetLayoutIndex();
	List.OnSelectionChanged = OnSetLayout;
	//bsg-jneal (5.23.17): end
}

function PopulateFilterList(out int Index)
{
	local array<string> FilterNames;
	local int FilterIndex, i;
	GetFirstPassFilterData(FilterNames, FilterIndex);

	for (i = 0; i < FilterNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(FilterNames[i], OnConfirmFirstPassFilter); //bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	}

	//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	m_bOriginalSubListIndex = FilterIndex;
	List.OnSelectionChanged = OnSetFirstPassFilter;
	//bsg-jneal (5.23.17): end
}

function PopulateTreatmentList(out int Index)
{
	local array<string> FilterNames;
	local int FilterIndex, i;
	GetSecondPassFilterData(FilterNames, FilterIndex);

	for (i = 0; i < FilterNames.Length; i++)
	{
		GetListItem(Index++).UpdateDataDescription(FilterNames[i], OnConfirmSecondPassFilter); //bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	}

	//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
	m_bOriginalSubListIndex = FilterIndex;
	List.OnSelectionChanged = OnSetSecondPassFilter;
	//bsg-jneal (5.23.17): end
}

function PopulateSoldierDataList(out int Index)
{
	local int i, AnimIndex, percent;
	local array<String> AnimNames;
	local delegate<OnClickDelegate> OnChooseSoldierDel, OnChoosePoseDel, OnRotateSoldierDel;

	for (i = 0; i < `PHOTOBOOTH.m_kFormationTemplate.NumSoldiers; i++)
	{
		switch (i)
		{
		case 0:
			OnChoosePoseDel = OnChoosePose0;
			OnChooseSoldierDel = OnChooseSoldier0;
			OnRotateSoldierDel = OnRotateSoldier0;
			break;
		case 1:
			OnChoosePoseDel = OnChoosePose1;
			OnChooseSoldierDel = OnChooseSoldier1;
			OnRotateSoldierDel = OnRotateSoldier1;
			break;
		case 2:
			OnChoosePoseDel = OnChoosePose2;
			OnChooseSoldierDel = OnChooseSoldier2;
			OnRotateSoldierDel = OnRotateSoldier2;
			break;
		case 3:
			OnChoosePoseDel = OnChoosePose3;
			OnChooseSoldierDel = OnChooseSoldier3;
			OnRotateSoldierDel = OnRotateSoldier3;
			break;
		case 4:
			OnChoosePoseDel = OnChoosePose4;
			OnChooseSoldierDel = OnChooseSoldier4;
			OnRotateSoldierDel = OnRotateSoldier4;
			break;
		case 5:
			OnChoosePoseDel = OnChoosePose5;
			OnChooseSoldierDel = OnChooseSoldier5;
			OnRotateSoldierDel = OnRotateSoldier5;
			break;
		}

		GetListItem(Index++).UpdateDataValue(m_PrefixSoldier@i+1, `PHOTOBOOTH.GetSoldierName(i), OnChooseSoldierDel);

		GetAnimationData(i, AnimNames, AnimIndex);

		GetListItem(Index++).UpdateDataValue(m_PrefixPose@i+1, AnimNames[AnimIndex], OnChoosePoseDel);
		
		percent = float(`PHOTOBOOTH.m_arrUnits[i].ActorPawn.Rotation.Yaw) / SoldierRotationMultiplier;
		if (percent < 0)
			percent = 100 + percent;

		GetListItem(Index++).UpdateDataSlider(m_CategoryRotateSoldier, "", percent, OnRotateSoldierDel, RotateSoldierSlider);

		if (`PHOTOBOOTH.m_arrUnits[i].ActorPawn == none)
		{
			GetListItem(Index - 2).SetDisabled(true, m_TooltipNoSoldier);
			GetListItem(Index - 1).SetDisabled(true, m_TooltipNoSoldier);
		}
	
		if(i < `PHOTOBOOTH.m_kFormationTemplate.NumSoldiers - 1)
		{
			GetListItem(Index).DisableNavigation(); //bsg-jneal (5.16.17): don't allow navigation on hidden list items
			GetListItem(Index++).Hide();
		}
	}
}

function NeedsPopulateData()
{
	m_bNeedsPopulateData = true;
}

function PopulateData()
{
	//bsg-jneal (5.16.17): now returning to original menu index when leaving soldier or pose selection
	local int i, previousListIndex;

	previousListIndex = -1;

	//bsg-jedwards (5.1.17) : Check if the state changed so we can clear the list items and remake them as some may have changed drastically
	if(currentState != lastState)
	{
		if(currentState == eUIPropagandaType_SoldierData)
		{
			// only check if we are returning to soldier data list
			if(lastState == eUIPropagandaType_Pose)
			{
				previousListIndex = (m_iLastTouchedSoldierIndex * 4) + 1; //multiply index by number of list items per soldier (3 + 1 blank), also add 1 if returning from pose
			}
			else if(lastState == eUIPropagandaType_Soldier)
			{
				previousListIndex = (m_iLastTouchedSoldierIndex * 4); //multiply index by number of list items per soldier (3 + 1 blank)
			}
		}
		lastState = currentState;
		List.ClearItems();
	}
	else
	{
		HideListItems();
	}
	//bsg-jedwards (5.1.17) : end
	
	i = 0;	

	if (m_bInitialized)
	{
		switch (currentState)
		{
		case eUIPropagandaType_Base:
			PopulateDefaultList(i);
			break;
		case eUIPropagandaType_Formation:
			PopulateFormationList(i);
			break;
		case eUIPropagandaType_SoldierData:
			PopulateSoldierDataList(i);
			break;
		case eUIPropagandaType_Soldier:
			PopulateSoldierList(i);
			break;
		case eUIPropagandaType_Pose:
			PopulatePoseList(i);
			break;
		case eUIPropagandaType_BackgroundOptions:
			PopulateBackgroundOptionsList(i);
			break;
		case eUIPropagandaType_Background:
			PopulateBackgroundList(i);
			break;
		case eUIPropagandaType_Graphics:
			PopulateGraphicsList(i);
			break;
		case eUIPropagandaType_Fonts:
			PopulateFontList(i);
			break;
		case eUIPropagandaType_TextColor:
			PopulateTextColors(i);
			break;
		case eUIPropagandaType_GradientColor1:
			PopulateBackground1Colors(i);
			break;
		case eUIPropagandaType_GradientColor2:
			PopulateBackground2Colors(i);
			break;
		case eUIPropagandaType_TextFont:
			PopulateFontList(i);
			break;
		case eUIPropagandaType_Layout:
			PopulateLayoutList(i);
			break;
		case eUIPropagandaType_Filter:
			PopulateFilterList(i);
			break;
		case eUIPropagandaType_Treatment:
			PopulateTreatmentList(i);
			break;
		};

		//bsg-jedwards (5.1.17) : Repopulate the navigator on the list when the list refreshens
		if(`ISCONTROLLERACTIVE)
		{
			if(previousListIndex != -1)
			{
				List.SetSelectedIndex(previousListIndex);
			}
			else 
			{
				//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed, if entering these menus set the initial pose index so the list does not init on the wrong pose
				if(currentState == eUIPropagandaType_Pose || currentState == eUIPropagandaType_Formation || currentState == eUIPropagandaType_Layout || currentState == eUIPropagandaType_Filter || currentState == eUIPropagandaType_Background || currentState == eUIPropagandaType_Treatment)
				{
					List.NavigatorSelectionChanged(m_bOriginalSubListIndex);
				}
				else if(currentState == eUIPropagandaType_Base)
				{
					List.SetSelectedIndex(m_iDefaultListIndex); //bsg-jneal (5.23.17): saving default list index for better nav
				}
				else
				{
					List.OnSelectionChanged = none; //bsg-jneal (5.23.17): clear selection changed callback for sub lists that do not use it
					List.SetSelectedIndex(List.SelectedIndex);
				}
			}
		}
		//bsg-jedwards (5.1.17) : end
	}
	//bsg-jneal (5.16.17): end
}

function UIMechaListItem GetListItem(int ItemIndex, optional bool bDisableItem, optional string DisabledReason)
{
	local UIMechaListItem CustomizeItem;
	local UIPanel Item;

	if (ItemIndex >= List.ItemContainer.ChildPanels.Length)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', List.itemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem();
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		CustomizeItem = UIMechaListItem(Item);
	}

	return CustomizeItem;
}

simulated function OnLoseFocus()
{
	HideEntirePoster(true);
	super.OnLoseFocus();
	if (List.SelectedIndex != -1)
		previousSelectedIndexOnFocusLost = List.SelectedIndex;
	List.SetSelectedIndex(-1);
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

function PointInSpace GetFormationPlacementActor()
{
	local PointInSpace PlacementActor;

	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if ('BlueprintLocation' == PlacementActor.Tag)
			return PlacementActor;
	}

	return none;
}

function SetupCamera();

simulated function OnReceiveFocus()
{
	HideEntirePoster(false);
	super.OnReceiveFocus();

	if (previousSelectedIndexOnFocusLost >= 0)
	{
		List.SetSelectedIndex(previousSelectedIndexOnFocusLost);
	}
}

simulated function OnRemoved()
{
	local int i;
	for (i = 0; i < `PHOTOBOOTH.m_arrUnits.Length; i++)
	{
		`PHOTOBOOTH.ReleaseSoldierPawnDeferred(`PHOTOBOOTH.m_arrUnits[i]);
	}

	`PHOTOBOOTH.m_arrUnits.Remove(0, `PHOTOBOOTH.m_arrUnits.Length);
	`XENGINE.m_kPhotoManager.FillPropagandaTextureArray(ePWM_Campaign, m_iGameIndex);

	`PHOTOBOOTH.EndPhotobooth(bDestroyPhotoboothPawnsOnCleanup);

	if (`ScreenStack.IsInStack(class'UIArmory_MainMenu'))
	{
		UIArmory(`ScreenStack.GetFirstInstanceOf(class'UIArmory_MainMenu')).CreateSoldierPawn();
	}

	super.OnRemoved();
}

// -----------------------------------------------------------------
// Poster Text/Icon functions
//bsg-jneal (5.23.17): updating certain list indices for poster previews on selection changed
function OnConfirmLayout()
{
	List.OnSelectionChanged = none;
	currentState = eUIPropagandaType_Base;
	List.ItemContainer.RemoveChildren();
	NeedsPopulateData();
}

function OnSetLayout(UIList ContainerList, int ItemIndex)
{
	`PHOTOBOOTH.SetLayoutIndex(List.SelectedIndex);
}
//bsg-jneal (5.23.17): end

function OnClickTextLayout()
{
	currentState = eUIPropagandaType_Layout;
	NeedsPopulateData();
}

function OnClickGraphics()
{
	currentState = eUIPropagandaType_Graphics;
	NeedsPopulateData();
}

function UpdateTextBox()
{
	OpenTextBoxInputInterface(List.SelectedIndex /3);
}

function UpdateTextSize(UISlider changedSlider)
{
	local int i;
	for (i = 0; i < List.ItemCount; i++)
	{
		if (GetListItem(i).Slider == changedSlider)
			break;
	}

	`PHOTOBOOTH.SetFontSize((i / 4) - 1, GetListItem(i).Slider.percent);
}

function OpenTextBoxInputInterface(int stringNum)
{
	local TInputDialogData kData;

	m_iCurrentModifyingTextBox = stringNum;

	if( `ISCONSOLE )
	{
		Movie.Pres.UIKeyboard( "TextBox"@stringNum+1, 
			`PHOTOBOOTH.GetTextBoxString(stringNum), 
			VirtualKeyboard_OnBackgroundInputBoxAccepted, 
			VirtualKeyboard_OnBackgroundInputBoxCancelled,
			false, 
			VIRTUAL_KEYBOARD_MAX_CHARACTERS //bsg-jedwards (4.13.17) : Sets the max characters to 64 instead of the GetMaxStringLength
		);
		return;
	}

	// on PC, we have a real keyboard, so use that instead
	kData.fnCallbackAccepted = PCTextField_OnAccept_TextBox;
	kData.fnCallbackCancelled = PCTextField_OnCancel_TextBox;
	kData.strTitle = m_PrefixTextBox @ stringNum+1;
	kData.iMaxChars = `PHOTOBOOTH.GetMaxStringLength(stringNum);
	kData.strInputBoxText = `PHOTOBOOTH.GetTextBoxString(stringNum);
	Movie.Pres.UIInputDialog(kData);

}

function VirtualKeyboard_OnBackgroundInputBoxAccepted(string text, bool bWasSuccessful)
{
	PCTextField_OnAccept_TextBox(bWasSuccessful ? text : "");
}

function VirtualKeyboard_OnBackgroundInputBoxCancelled()
{
	PCTextField_OnCancel_TextBox("");
}

function PCTextField_OnAccept_TextBox(string userInput)
{
	`PHOTOBOOTH.m_bChangedDefaultPosterStrings[m_iCurrentModifyingTextBox] = true;
	`PHOTOBOOTH.SetTextBoxString(m_iCurrentModifyingTextBox, userInput);
	NeedsPopulateData();
}

function PCTextField_OnCancel_TextBox(string userInput)
{
	//bsg-nlong (1.11.17): Reset the focus on the Navigators
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);
	//bsg-nlong (1.11.17): end
}

function GetLayoutNames(out array<string> FormationNames)
{
	local array<X2PropagandaTextLayoutTemplate> arrLayouts;
	local int i;

	`PHOTOBOOTH.GetLayouts(arrLayouts);

	FormationNames.length = 0;
	for (i = 0; i < arrLayouts.length; ++i)
	{
		FormationNames.AddItem(arrLayouts[i].DisplayName);
	}
}

function GetFontData(out array<string> FontNames)
{
	local array<FontOptions> arrFonts;
	local int i;

	`PHOTOBOOTH.GetFonts(arrFonts);

	FontNames.length = 0;
	for (i = 0; i < arrFonts.length; ++i)
	{
		FontNames.AddItem(arrFonts[i].FontDisplayName);
	}
}

function GetFontDataSpecific(out array<string> FontNames, array<String> FontParameters)
{
	local array<FontOptions> arrFonts;
	local int i, j;

	`PHOTOBOOTH.GetFonts(arrFonts);

	FontNames.length = 0;
	for (j = 0; j < FontParameters.length; j++)
	{
		for (i = 0; i < arrFonts.length; ++i)
		{
			if (arrFonts[i].FontName == FontParameters[j])
			{
				FontNames.AddItem(arrFonts[i].FontDisplayName);
			}
		}
	}
}

function UpdateIcon()
{
	m_iIconIndexChoosing = List.SelectedIndex - (`PHOTOBOOTH.m_currentTextLayoutTemplate.NumTextBoxes*4);
	m_uiIconSelection.Show();
	BG.Show();
}

function bool UpdateRandom()
{
	local int loopIndex;
	local array<FilterPosterOptions> arrFilters;
	local array<AnimationPoses> arrAnimationsAlreadyUsed;

	if (m_kGenRandomState == eAGCS_TickPhase1)
	{
		if (`PHOTOBOOTH.DeferPhase1()) return true;

		DefaultSetupSettings.GeneratedText.Length = 0;
		if (DefaultSetupSettings.TextLayoutState == ePBTLS_PromotedSoldier)
		{	
			`PHOTOBOOTH.SetAutoTextStrings(ePBAT_SOLO, DefaultSetupSettings.TextLayoutState, DefaultSetupSettings, true);
			`PHOTOBOOTH.SetTextLayoutByType(eTLT_Promotion);
		}
		else if (DefaultSetupSettings.TextLayoutState == ePBTLS_DeadSoldier)
		{
			`PHOTOBOOTH.SetAutoTextStrings(ePBAT_SOLO, DefaultSetupSettings.TextLayoutState, DefaultSetupSettings);
		}
		else if(!bChallengeMode && !bLadderMode)
		{
			`PHOTOBOOTH.AutoGenTextLayout();
		}

		if (DefaultSetupSettings.GeneratedText.Length <= 0)
		{
			`PHOTOBOOTH.FillDefaultText(DefaultSetupSettings);
		}

		RandomSetBackground();

		
		if (`SYNC_RAND(100) < FilterChance)
		{
			`PHOTOBOOTH.GetFirstPassFilters(arrFilters);
			`PHOTOBOOTH.SetFirstPassFilter(`SYNC_RAND(arrFilters.Length - 1) + 1);
		}
		else
		{
			`PHOTOBOOTH.SetFirstPassFilter(0);
		}

		`PHOTOBOOTH.SetSecondPassFilter(0);

		m_kGenRandomState = eAGCS_TickPhase2;
	}

	if (m_kGenRandomState == eAGCS_TickPhase2)
	{
		if (`PHOTOBOOTH.DeferPhase2()) return true;

		arrAnimationsAlreadyUsed.Length = 0;

		for (loopIndex = 0; loopIndex < `PHOTOBOOTH.GetNumSoldierSlots(); loopIndex++)
		{
			SetRandomAnimationPoseForSoldier(loopIndex, true, arrAnimationsAlreadyUsed);
		}

		m_kGenRandomState = eAGCS_TickPhase3;
	}

	if(m_kGenRandomState == eAGCS_TickPhase3)
	{
		if (`PHOTOBOOTH.DeferPhase3()) return true;

		if (RandomSetCamera())
		{
			m_kGenRandomState = eAGCS_Idle;
			m_bNeedsPopulateData = true;
		}		
	}

	return m_kGenRandomState != eAGCS_Idle;
}


function bool UpdateReset()
{
	local int loopIndex;
	local array<PhotoboothCameraPreset> arrCameraPresets;
	local PhotoboothCameraSettings CameraSettings;
	local Photobooth_AutoTextUsage autoText;

	`PHOTOBOOTH.GetCameraPresets(arrCameraPresets);
	if (m_kGenRandomState == eAGCS_TickPhase1)
	{
		if (`PHOTOBOOTH.DeferPhase1()) return true;

		if (`ScreenStack.IsInStack(class'UITactical_Photobooth'))
		{
			autoText = ePBAT_SQUAD;
		}
		else
		{
			if (`PHOTOBOOTH.GetNumSoldierSlots() > 1)
			{
				autoText = ePBAT_DUO;
			}
			else
			{
				autoText = ePBAT_SOLO;
			}
		}

		`PHOTOBOOTH.SetAutoTextStrings(autoText, DefaultSetupSettings.TextLayoutState, DefaultSetupSettings, true);

		if (!DefaultSetupSettings.bInitialized)
		{
			DefaultSetupSettings.bInitialized = true;
			RandomSetBackground();
			DefaultSetupSettings.bBackgroundTinting = `PHOTOBOOTH.m_kPhotoboothEffect.bOverrideBackgroundTextureColor;
		}
		else
		{
			`PHOTOBOOTH.SetBackgroundTexture(DefaultSetupSettings.BackgroundDisplayName);
			`PHOTOBOOTH.SetBackgroundColorOverride(DefaultSetupSettings.bBackgroundTinting);
		}

		if (DefaultSetupSettings.BackgroundGradientColor1 <= 0)
		{
			DefaultSetupSettings.BackgroundGradientColor1 = `SYNC_RAND(`PHOTOBOOTH.m_FontColors.length);
		}
		if (DefaultSetupSettings.BackgroundGradientColor2 <= 0)
		{
			DefaultSetupSettings.BackgroundGradientColor2 = `SYNC_RAND(`PHOTOBOOTH.m_FontColors.length);
		}

		`PHOTOBOOTH.SetGradientColorIndex1(DefaultSetupSettings.BackgroundGradientColor1);
		`PHOTOBOOTH.SetGradientColorIndex2(DefaultSetupSettings.BackgroundGradientColor2);
		

		`PHOTOBOOTH.SetFirstPassFilter(0);
		`PHOTOBOOTH.SetSecondPassFilter(0);

		m_kGenRandomState = eAGCS_TickPhase2;
	}

	if (m_kGenRandomState == eAGCS_TickPhase2)
	{
		if (`PHOTOBOOTH.DeferPhase2()) return true;

		for (loopIndex = 0; loopIndex < DefaultSetupSettings.PossibleSoldiers.Length; loopIndex++)
		{
			if (loopIndex >= DefaultSetupSettings.SoldierAnimIndex.Length)
			{
				DefaultSetupSettings.SoldierAnimIndex.AddItem(-1);
			}

			if (DefaultSetupSettings.SoldierAnimIndex[loopIndex] == -1)
			{
				DefaultSetupSettings.SoldierAnimIndex[loopIndex] = SetRandomAnimationPoseForSoldier(loopIndex);
			}
			else
			{
				SetAnimationPoseForSoldier(loopIndex, DefaultSetupSettings.SoldierAnimIndex[loopIndex], DefaultSetupSettings.TextLayoutState == ePBTLS_BondedSoldier);
			}
		}

		m_kGenRandomState = eAGCS_TickPhase3;
	}

	if(m_kGenRandomState == eAGCS_TickPhase3)
	{
		if (`PHOTOBOOTH.DeferPhase3()) return true;

		for (loopIndex = 0; loopIndex < arrCameraPresets.length; loopIndex++)
		{
			if (arrCameraPresets[loopIndex].TemplateName == DefaultSetupSettings.CameraPresetDisplayName)
			{
				if( `PHOTOBOOTH.GetCameraPOVForPreset(arrCameraPresets[loopIndex], CameraSettings) )				
				{
					UpdateCameraToPOV(CameraSettings, true);
					m_bResetting = false;
					m_bNeedsPopulateData = true;
					m_kGenRandomState = eAGCS_Idle;
				}

				break;
			}
		}
	}

	return m_kGenRandomState != eAGCS_Idle;
}

event Tick(float DeltaTime)
{
	local int i;
	super.Tick(DeltaTime);

	if (m_bNeedsPopulateData)
	{
		m_bNeedsPopulateData = false;
		UpdateNavHelp(); // bsg-jneal (4.4.17): force a navhelp update to correctly fix wide icon sizing issues when first entering the photobooth
		PopulateData();

		if(`ISCONTROLLERACTIVE && List.SelectedIndex < 1) //bsg-jedwards (5.1.17) : Stay on current selected index until list change
		{
			Navigator.SelectFirstAvailable(); // bsg-jneal (4.4.17): make sure the navigator selects the first available target when the list is recreated
		}
	}

	if (m_bResetting && UpdateReset()) return;

	if (UpdateRandom()) return;
	
	for (i = 0; i < `PHOTOBOOTH.m_arrUnits.Length; i++)
	{
		if (`PHOTOBOOTH.m_arrUnits[i].ActorPawn != none)
		{
			`PHOTOBOOTH.m_arrUnits[i].ActorPawn.SetRotation(`PHOTOBOOTH.ActorRotation[i]);
		}
	}

	MoveCaptureComponent();
}

simulated function OnCommand(string cmd, string arg)
{
	switch (cmd)
	{
	case "FlashComplete":
		PendingPhotoPopup();
		break;
	}
}

function PendingPhotoPopup()
{
	local TProgressDialogData kConfirmData;

	kConfirmData.strTitle = m_PendingPhotoTitle;
	kConfirmData.strDescription = m_PendingPhotoBody;

	if(bWaitingOnPhoto)
		Movie.Pres.UIProgressDialog(kConfirmData);
}

function DestructiveActionPopup()
{
	local TDialogueBoxData kConfirmData;


	kConfirmData.strTitle = m_DestructiveActionTitle;
	kConfirmData.strText = m_DestructiveActionBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnDestructiveActionPopupExitDialog;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDestructiveActionPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		`PRESBASE.GetPhotoboothMovie().RemoveScreen(`PHOTOBOOTH.m_backgroundPoster);
		Movie.Pres.PlayUISound(eSUISound_MenuClose);

		CloseScreen();
	}
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	//bsg-jneal (5.19.17): do not allow additional input if there is a photo pending
	if(bWaitingOnPhoto)
	{
		return true;
	}
	//bsg-jneal (5.19.17): end

	// bsg-jedwards (5.1.17): If the list item has a dropdown and it's open, pass the input on that that instead
	if( UIMechaListItem(List.Navigator.GetSelected()) != none
		&& UIMechaListItem(List.Navigator.GetSelected()).Dropdown != none 
		&& UIMechaListItem(List.Navigator.GetSelected()).Dropdown.IsOpen )
	{
		return UIMechaListItem(List.Navigator.GetSelected()).Dropdown.OnUnrealCommand(cmd, arg);
	}

	if( ColorSelector.bIsVisible )
	{
		if( ColorSelector.OnUnrealCommand(cmd, arg) )
			return true;
	}
	//bsg-jedwards (5.1.17): end

	switch (cmd)
	{
		//catch the cycle unit keys dont allow them to fall through to armory
	case class'UIUtilities_Input'.const.FXS_MOUSE_5 :
	case class'UIUtilities_Input'.const.FXS_KEY_TAB :
	case class'UIUtilities_Input'.const.FXS_MOUSE_4 :
	case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT :
		return true;

	//bsg-jneal (5.30.17): when manipulating the camera do not allow LSTICK, DPAD, or A button to move or select menu options
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		if(m_bGamepadCameraActive)
		{
			return true;
		}
		break;
	//bsg-jneal (5.30.17): end
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
		if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
			return false;
		
		OnCancel();
		return true;
		break;

	//bsg-jedwards (5.1.17) : Diasbles use of the Y button in the photobooth
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
		return true;
		break;
	//bsg-jedwards (5.1.17) : end

	//bsg-jedwards (5.1.17) : Allows the make poster using X Button
	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
			return false;
		OnMakePosterSelected(None);
		return true;
		break;
	//bsg-jedwards (5.1.17) : end

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN :
		
		if (IsMouseInPoster() && ((arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) > 0 || (arg & class'UIUtilities_Input'.const.FXS_ACTION_HOLD) > 0))
		{
			m_bMouseIn = true;
		}
		else if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) > 0)
		{
			m_bMouseIn = false;
		}

		Movie.Pres.m_kUIMouseCursor.UpdateMouseLocation();
		break;
	
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
				
		if (IsMouseInPoster() && ((arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) > 0 || (arg & class'UIUtilities_Input'.const.FXS_ACTION_HOLD) > 0))
		{
				m_bRightMouseIn = true;
				Movie.Pres.m_kUIMouseCursor.UpdateMouseLocation();
		}
		else if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) > 0)
		{
			if(!m_bRightMouseIn)
			{
				OnCancel();
			}

			m_bRightMouseIn = false;
		}
		return true;
		break;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN :
		if (IsMouseInPoster())
		{
			ZoomOut();
		}
		return true;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP :
		if (IsMouseInPoster())
		{
			ZoomIn();
		}
		return true;

		//bsg-jneal (5.2.17): missing Zoom on triggers
	case (class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER):
		if (m_bGamepadCameraActive)
		{
			ZoomIn();
		}
		return true;
	case (class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER):
		if (m_bGamepadCameraActive)
		{
			ZoomOut();
		}
		return true;
		//bsg-jneal (5.2.17): end

	// bsg-nlong (1.24.17): Using the bumbers to cycle functionality to the Right Stick. Whether disable, pan, or rotate.
	case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
		if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
			return false;

		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
		if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
			return false;

		//bsg-jneal (5.2.17): moved gamepad camera control toggle to R1
		if( !m_bGamepadCameraActive )
		{
			m_bGamepadCameraActive = true;
			m_bRightMouseIn = true;
			m_bMouseIn = true;
		}
		else
		{
			m_bGamepadCameraActive = false;
			m_bRightMouseIn = false;
			m_bMouseIn = false;
		}

		UpdateNavHelp();
		//bsg-jneal (5.2.17): end
		return true;
	// bsg-nlong (1.24.17): end
	}

	return super.OnUnrealCommand(cmd, arg);
}

function bool IsMouseInPoster()
{
	local Vector2D TopLeft;
	local Vector2D BottomRight;

	`PHOTOBOOTH.GetPosterCorners(TopLeft, BottomRight);

	if (Movie.Pres.m_kUIMouseCursor.m_v2MouseLoc.X > TopLeft.X * movie.m_v2ScaledDimension.X + movie.m_v2ScaledOrigin.X - 4 && Movie.Pres.m_kUIMouseCursor.m_v2MouseLoc.x < BottomRight.X * movie.m_v2ScaledDimension.X + movie.m_v2ScaledOrigin.X - 4)
	{
		if (Movie.Pres.m_kUIMouseCursor.m_v2MouseLoc.Y > TopLeft.Y * movie.m_v2ScaledDimension.Y + movie.m_v2ScaledOrigin.Y && Movie.Pres.m_kUIMouseCursor.m_v2MouseLoc.Y < BottomRight.Y * movie.m_v2ScaledDimension.Y + movie.m_v2ScaledOrigin.Y)
		{
			return true;
		}
	}
	return false;
}

function ZoomIn()
{
}
function ZoomOut()
{

}

simulated function CloseScreen()
{
	local XComHQPresentationLayer HQPresLayer;

	HQPresLayer = `HQPRES;

	if(HQPresLayer != none)
	{
		HQPresLayer.m_bExitingFromPhotobooth = true;
	}

	super.CloseScreen();
}

event PreBeginPlay()
{
	super.PreBeginPlay();

	SubscribeToOnCleanupWorld();
	`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
}


simulated function OnGameInviteAccepted(bool bWasSuccessful)
{
	`log(`location @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	if (bWasSuccessful)
	{
		CloseScreen();
	}
}

event Destroyed()
{
	UnsubscribeFromOnCleanupWorld();
	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);

	super.Destroyed();
}

simulated event OnCleanupWorld()
{
	CloseScreen();
	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);
	super.OnCleanupWorld();
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxPhotobooth/Photobooth";
	LibID = "PhotoboothScreen";
	bHideOnLoseFocus = true;
	bAutoSelectFirstNavigable = false;
	DisplayTag = "CameraPhotobooth";
	CameraTag = "CameraPhotobooth";
	previousSelectedIndexOnFocusLost = -1;
	m_iLastTouchedSoldierIndex = 0;

	m_bInitialized = false
	m_bResetting = false;

	m_bGamepadCameraActive = false; //bsg-jneal (5.2.17): gamepad camera controls toggle

	m_iGameIndex = -1;

	//If you change these numbers mirror the change in XComPresentationLayerBase
	m_iPosterSizeX = 800;
	m_iPosterSizeY = 1200;

	m_fCameraFOV = 90

	bUpdateCameraWithFormation = true;
	m_bNeedsCaptureOutlineReset=false
	BGPaddingLeft = 4;
	BGPaddingRight = 4;
	BGPaddingTop = 4;
	BGPaddingBottom = 4;

	ColorSelectorX = 30;
	ColorSelectorY = 230;
	ColorSelectorWidth = 515;
	ColorSelectorHeight = 650;

	m_bRotationEnabled = false;
	m_bRotatingPawn = false;
	bProcessMouseEventsIfNotFocused = false;
	currentState = eUIPropagandaType_Base;

	m_kGenRandomState=eAGCS_Idle

	DefaultSetupSettings = (BackgroundDisplayName = "None", CameraPresetDisplayName = "Full Frontal", BackgroundGradientColor1=-1, BackgroundGradientColor2=-1, bInitialized = false);

	NumPawnsNeedingUpdateAfterFormationChange = 0

	bDestroyPhotoboothPawnsOnCleanup = true

	bChallengeMode = false
	bLadderMode = false
}


class X2Photobooth extends Actor
	dependson(XComAnimNodeBlendDynamic, X2PhotoBooth_PhotoManager)
	config(Content)
	native(Core);

/******************************************/
//		Config Variables
/******************************************/

var config string PhotoboothPostProcessChainName;

enum Photobooth_AnimationFilterType
{
	ePAFT_None,
	ePAFT_Captured,
	ePAFT_TopGun,
	ePAFT_SoldierRifle,
	ePAFT_DuoPose1,
	ePAFT_DuoPose2,
	ePAFT_Grenadier,
	ePAFT_Ranger,
	ePAFT_Sharpshooter,
	ePAFT_PsiOperative,
	ePAFT_Specialist,
	ePAFT_Skirmisher,
	ePAFT_Templar,
	ePAFT_Reaper,
	ePAFT_Memorial,
	// Start Issue #309
	// Similar to X2TacticalGameRulesetDataStructures.EInventorySlot,
	// we add our own things here.
	ePAFT_END_VANILLA_FILTERS,

	// Buffer slots in case Firaxis adds more in the future
	ePAFT_Buffer16,
	ePAFT_Buffer17,
	ePAFT_Buffer18,
	ePAFT_Buffer19,
	ePAFT_Buffer20,
	ePAFT_Buffer21,
	ePAFT_Buffer22,

	ePAFT_BEGIN_MOD_CLASS_FILTERS,
	// Here, mod-defined filters exist
	// We add a bunch of "unstable" filters modders can use
	// to test their stuff first. We reserve the right to
	// remove or rename them in the future.
	// Request and track entries in #320
	ePAFT_Unstable24,
	ePAFT_Unstable25,
	ePAFT_Unstable26,
	ePAFT_Unstable27,
	// ...

	ePAFT_END_MOD_CLASS_FILTERS,
	// End Issue #309
};

enum Photobooth_ParticleEffectType
{
	ePPET_None,
	ePPET_TemplarBladeRight,
	ePPET_TemplarBladeLeft,
	ePPET_TemplarShield,
	// Start Issue #359
	// Similar to above, but we don't need any sort of special marker
	// enums here as these are never used in code (only config)
	// Still going to use buffers though!
	ePPET_Buffer04,
	ePPET_Buffer05,
	ePPET_Buffer06,
	ePPET_Buffer07,
	ePPET_Buffer08,
	ePPET_Buffer09,
	ePPET_Buffer10,
	ePPET_Buffer11,

	ePPET_Unstable12,
	ePPET_Unstable13,
	ePPET_Unstable14,
	ePPET_Unstable15,
	ePPET_Unstable16,
	ePPET_Unstable17,
	ePPET_Unstable18,
	ePPET_Unstable19,
	ePPET_Unstable20,
	ePPET_Unstable21,
	ePPET_Unstable22,
	ePPET_Unstable23,
	ePPET_Unstable24,
	ePPET_Unstable25,
	ePPET_Unstable26,
	ePPET_Unstable27,
	ePPET_Unstable28,
	ePPET_Unstable29,
	// End Issue #359
};

struct native AnimationPoses
{
	var localized string						AnimationDisplayName;
	var name									AnimationName;
	var float									AnimationOffset;
	var Photobooth_AnimationFilterType			AnimType;
	var array<Photobooth_ParticleEffectType>	ParticleEffectTypes;
	var bool									bExcludeFromGroupShots;
	var bool									bExcludeFromTemplar;
};

/* Lists of all animation poses set from the ini */
var config array<AnimationPoses> m_arrAnimationPoses;
var config array<AnimationPoses> m_arrAnimationSparkPoses;
var config array<AnimationPoses> m_arrAnimationBitPoses;
var config array<AnimationPoses> m_arrAnimationGremlinPoses;

enum Photobooth_TeamUsage
{
	ePBT_XCOM,
	ePBT_CHOSEN,
	ePBT_ALL
};

struct native BackgroundPosterOptions
{
	var localized string BackgroundDisplayName;
	var string BackgroundName;
	var Texture2D BackgroundTexture;
	var Photobooth_TeamUsage UsableByTeam;
	var bool bAllowTintingOnRandomize;
};

var config array<BackgroundPosterOptions> m_arrBackgroundOptions;

struct native FilterPosterOptions
{
	var localized string FilterDisplayName;
	var string FilterName;
	var MaterialInterface FilterMI;
	var bool bUsesTintColors;
	var LinearColor OrigColor1;
	var LinearColor OrigColor2;
};

struct native FontOptions
{
	var localized string FontDisplayName;
	var string FontName;
	var bool   AllowedInAsianLanguages;
	var bool   AllowedInCyrillic;
	var bool   AllowedForCaptured;
};

var config array<FilterPosterOptions> m_arrFirstPassFilterOptions;
var config array<FilterPosterOptions> m_arrSecondPassFilterOptions;

var config array<FontOptions> m_arrFontOptions;

/******************************************/
//		Misc Variables
/******************************************/

var int							m_iGameIndex;

var array<int> DuoPose1Indices;
var array<int> DuoPose2Indices;

enum AutoGenCaptureState
{
	eAGCS_Idle,
	eAGCS_TickPhase1,
	eAGCS_TickPhase2,
	eAGCS_TickPhase3,
	eAGCS_Capturing
};

var AutoGenCaptureState			m_kAutoGenCaptureState;

/******************************************/
//		Formation Variables
/******************************************/

var X2PropagandaPhotoTemplateManager m_templateMan;
var array<X2PropagandaPhotoTemplate> m_arrFormations;

var PointInSpace				m_kFormationPIS;
var X2PropagandaPhotoTemplate	m_kFormationTemplate;
var XComBlueprint				m_kFormationBlueprint;
var bool						m_bFormationNeedsUpdate;
var bool						m_bFormationLoading;

var array<Rotator>				ActorRotation;

/******************************************/
//		Camera Variables
/******************************************/

var TPOV			m_kCameraPOV;

/******************************************/
//		UI Variables
/******************************************/

var UIPosterScreen m_backgroundPoster;

var X2PropagandaTextLayoutTemplate m_currentTextLayoutTemplate;
var X2PropagandaTextLayoutTemplateManager m_textLayoutTemplateMan;
var array<X2PropagandaTextLayoutTemplate> m_aTextLayouts;
var int m_currentTextLayoutTemplateIndex;
var array<String> m_PosterStrings;
var array<String> m_PosterFont;
var array<int>	  m_FontSize;
var array<string> m_FontColors;
var array<string> m_SecondaryFontColors;
var int			  m_RandomColors;
var array<int>	  m_PosterStringColors;
var array<bool> m_bChangedDefaultPosterStrings;
var array<int>	  m_PosterIcons;
var int m_iTextBoxListIndex;
var int m_iIconListIndex;
var int m_iCurrentModifyingTextBox;
var int m_iGradientColor1Index;
var int m_iGradientColor2Index;

/******************************************/
//		Soldier Variables
/******************************************/

struct native PoseSoldierData
{	
	var StateObjectReference	UnitRef;
	var XComUnitPawn			ActorPawn;
	var bool					AsyncLoadComplete;
	var delegate<OnPawnCreated> delOnPawnCreated;

	var name					AnimationName;
	var float					AnimationOffset;

	var int						FramesToHide;

	var vector					Location;
	var Rotator					Rotation;
};

/* Current list of soldiers spawned along with pose data set for the soldier. */
var array<PoseSoldierData> m_arrUnits;

/******************************************/
//		Rendering Variables
/******************************************/

enum PhotoboothFrameSetting
{
	ePFS_All,
	ePFS_Torso,
	ePFS_Head
};

struct native PhotoboothCameraPreset
{
	var localized string		DisplayName;
	var string					TemplateName;
	var name					FocusBoneOrSocket;
	var Rotator					ViewingRotation;
	var vector					ViewingOffset;
	var PhotoboothFrameSetting	FrameSetting;
	var array<string>			AllowableFormations;
};

var config array<PhotoboothCameraPreset> m_arrCameraPresets;

struct native PhotoboothCameraSettings
{
	var Rotator Rotation;
	var float	ViewDistance;
	var vector	RotationPoint;
};

var PostProcessChain m_kPosterPostProcessChain;
var PhotoboothEffect m_kPhotoboothEffect;
var PhotoboothEffect m_kPhotoboothShowEffect;

var SceneCapture2DComponent m_kPreviewPosterComponent;
var SceneCapture2DComponent m_kFinalPosterComponent;

var TextureRenderTarget2D m_kPreviewPosterTexture;
var TextureRenderTarget2D m_kFinalPosterTexture;
var TextureRenderTarget2D m_kUIRenderTexture;

// These are in 0..1 range
var array<Vector2D> ScreenCoords;


// These are in 0..TextureSize
var int m_iOnScreenX;
var int m_iOnScreenY;

var int m_iOnScreenSizeX;
var int m_iOnScreenSizeY;

var int m_iPosterSizeX;
var int m_iPosterSizeY;

var float m_fMaxXPercentage;
var float m_fMaxYPercentage;

/******************************************/
//		Autogen Variables
/******************************************/

enum Photobooth_TextLayoutState
{
	ePBTLS_Auto,
	ePBTLS_DeadSoldier,
	ePBTLS_PromotedSoldier,
	ePBTLS_BondedSoldier,
	ePBTLS_CapturedSoldier,
	ePBTLS_HeadShot,
	ePBTLS_NONE
};

struct native PhotoboothAutoGenSettings
{
	var int								CampaignID;
	var PointInSpace					FormationLocation;
	var X2PropagandaPhotoTemplate		FormationTemplate;

	var array<StateObjectReference>		PossibleSoldiers;
	var array<int>						SoldierAnimIndex;

	var TPOV							CameraPOV;
	var string							CameraPresetDisplayName;
	var string							BackgroundDisplayName;

	var Photobooth_TextLayoutState		TextLayoutState;

	// Headshot specific members
	var int								SizeX;
	var int								SizeY;
	var float							CameraDistance;
	var name							HeadShotAnimName;

	var bool							bChallengeMode;
	var bool							bLadderMode;
};

var PhotoboothAutoGenSettings AutoGenSettings;

enum Photobooth_AutoTextUsage
{
	ePBAT_SOLO,
	ePBAT_DUO,
	ePBAT_SQUAD
};

struct native AutoGeneratedLines
{
	var localized array<string>  ALines;
	var localized array<string>  BLines;
	var localized array<string>  OpLines;
};

var localized array<string> m_arrSoloALines;
var localized array<string> m_arrSoloALines_Male;
var localized array<string> m_arrSoloALines_Female;
var localized array<string> m_arrSoloBLines;
var localized array<string> m_arrSoloBLines_Male;
var localized array<string> m_arrSoloBLines_Female;
var localized array<string> m_arrSoloOpLines;

var localized array<string> m_arrSoloMemorialBLines;
var localized array<string> m_arrSoloMemorialBLines_Male;
var localized array<string> m_arrSoloMemorialBLines_Female;

var localized array<string> m_arrDuoALines;
var localized array<string> m_arrDuoALines_Male;
var localized array<string> m_arrDuoALines_Female;
var localized array<string> m_arrDuoBLines;
var localized array<string> m_arrDuoBLines_Male;
var localized array<string> m_arrDuoBLines_Female;
var localized array<string> m_arrDuoOpLines;

var localized array<string> m_arrSquadALines;
var localized array<string> m_arrSquadBLines;
var localized array<string> m_arrSquadOpLines;

var localized array<string> m_arrCapturedLines;

var localized string m_PromotedString;
var localized string m_CapturedString;
var localized string m_CallsignString;

var localized string m_ChallengeModeStr;
var localized string m_ChallengeModeScoreLabel;

struct native AutoTextPercentages
{
	var string FormationName;
	var array<int> LineChances;
	var int OpLineChance;
};

var config array<AutoTextPercentages> arrAutoTextChances;


struct native PhotoboothDefaultSettings
{
	var X2PropagandaPhotoTemplate		FormationTemplate;

	var array<StateObjectReference>		PossibleSoldiers;
	var array<String>					GeneratedText;
	var array<int>						FontNum;
	var array<int>						FontColor;
	var array<int>						SoldierAnimIndex;
	var int								TextLayoutNum;
	var int								BackgroundGradientColor1;
	var int								BackgroundGradientColor2;

	var string							BackgroundDisplayName;
	var string							CameraPresetDisplayName;

	var Photobooth_TextLayoutState		TextLayoutState;

	var bool							bInitialized;
	var bool							bBackgroundTinting;
};

/** A fence to track when ReadPixels has completed on the rendering thread. */
var private native const RenderCommandFence ReadPixelsFence;

var array<Color> PixelData;

var Photobooth_TextLayoutState UserTextLayoutState;

var config bool bAsyncPawnLoading;

var config LinearColor CapturedTintColor1;
var config LinearColor CapturedTintColor2;

struct native DeferredReleasePawnInfo
{
	var XComUnitPawn			ActorPawn;
	var int						FramesToDeferRelease;
};

var array<DeferredReleasePawnInfo> DeferredReleasePawns;

// Special particle systems and notifies for the Templar weapons (unused but xpack content expects it).
var ParticleSystem      TemplarShardBladeFX_L;
var ParticleSystem      TemplarShardBladeFX_R;

struct native PhotoboothParticleEffects
{
	var string							PSTemplateName;
	var name							SocketName;
	var Photobooth_ParticleEffectType	ParticleEffectType;
	var AnimNotify_StopParticleEffect	StopNotify;
	var AnimNotify_PlayParticleEffect	PlayNotify;
};

var config array<PhotoboothParticleEffects> ParticleEffects;

var X2Camera_Fixed FixedTacticalAutoGenCamera;

var array<Vector> OriginalFormationPoints;
var array<Vector> CurrentFormationPoints;

struct native PoseFormationRestrictionInfo
{
	var name			AnimationName;
	var float			AnimationOffset;
	var name			FormationName;
	var array<string>	LocationTags;
};

var config array<PoseFormationRestrictionInfo> PoseFormationRestrictions;

var bool bFullStop;

/******************************************/
//		Callback Variables
/******************************************/

var delegate<OnPosterCreated> m_kOnPosterCreated;
delegate OnPosterCreated(StateObjectReference UnitRef);
delegate OnPawnCreated();

/******************************************/
//		CPP Functions
/******************************************/

cpptext
{
	virtual void TickSpecial(float DeltaTime);

	void Initialize();

	// Formation Functions
	void ConstructFormation();	
	APointInSpace* GetSoldierPointInSpace(INT index);

	// Capture Functions
}

/******************************************/
//		Static Functions
/******************************************/

static native function X2Photobooth GetPhotobooth();
static native function bool FullStop();

/******************************************/
//		Cleanup Functions
/******************************************/

private native function CleanupPhotobooth();

function RemoveAllSoldierPawns()
{
	local StateObjectReference Unit;
	local int i;

	Unit.ObjectID = 0;

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		SetSoldier(i, Unit);
	}
}

event EndPhotobooth(bool bDestroyPawns)
{
	local int i;
	local MaterialInstanceConstant FilterMIC;
	local LinearColor ParamValue;

	if (FullStop()) return;

	m_kPreviewPosterComponent.SetEnabled(false);
	m_kFinalPosterComponent.SetEnabled(false);

	if (bDestroyPawns)
	{
		RemoveAllSoldierPawns();
	}
	else
	{
		for (i = 0; i < m_arrUnits.Length; ++i)
		{
			if (m_arrUnits[i].ActorPawn != none)
			{
				m_arrUnits[i].ActorPawn.SetVisible(false);
				m_arrUnits[i].ActorPawn = none;
				m_arrUnits[i].delOnPawnCreated = none;
			}
		}

		for (i = 0; i < DeferredReleasePawns.Length; ++i)
		{
			if (DeferredReleasePawns[i].ActorPawn != none)
			{
				DeferredReleasePawns[i].ActorPawn.SetVisible(false);
				DeferredReleasePawns[i].ActorPawn = none;
			}
		}
	}

	for(i = 0; i < m_arrFirstPassFilterOptions.Length; ++i)
	{
		if (m_arrFirstPassFilterOptions[i].FilterMI != none && m_arrFirstPassFilterOptions[i].bUsesTintColors)
		{
			FilterMIC = MaterialInstanceConstant(m_arrFirstPassFilterOptions[i].FilterMI);
			if (FilterMIC != none)
			{
				ParamValue = m_arrFirstPassFilterOptions[i].OrigColor1;
				FilterMIC.SetVectorParameterValue('FirstBackgroundColor', ParamValue);
				ParamValue = m_arrFirstPassFilterOptions[i].OrigColor2;
				FilterMIC.SetVectorParameterValue('SecondBackgroundColor', ParamValue);
			}
		}
	}

	DisablePostProcess();
	CleanupPhotobooth();
}

/******************************************/
//		Misc Functions
/******************************************/

function SetGameIndex(int GameIndex)
{
	if (FullStop()) return;

	m_iGameIndex = GameIndex;
}

/******************************************/
//		Formation Functions
/******************************************/

native function UpdateAllSoldiers();

function MoveFormation(PointInSpace inFormationPoint)
{
	if (FullStop()) return;

	m_kFormationPIS = inFormationPoint;
	m_bFormationNeedsUpdate = true;
}
function ChangeFormation(X2PropagandaPhotoTemplate inFormation)
{
	if (FullStop()) return;

	m_kFormationTemplate = inFormation;
	m_bFormationNeedsUpdate = true;
}

event InitializeFormationData()
{
	m_templateMan = class'X2PropagandaPhotoTemplateManager'.static.GetPropagandaPhotoTemplateManager();
	m_templateMan.InitTemplates();
	m_templateMan.GetUberTemplates("Formation", m_arrFormations);
	if (`ScreenStack.IsInStack(class'UITactical_Photobooth'))
	{
		m_kFormationTemplate = m_arrFormations[0];
	}
	else
	{
		m_kFormationTemplate = m_arrFormations[3]; // Default to Solo Formation
	}
}

native function OnFormationLoad();

/******************************************/
//		Soldier Functions
/******************************************/

native function UpdateSoldier(int LocationIndex, bool bForceUnitUpdate, bool bForceAnimationUpdate);
native function bool UpdateSoldierUnitPhase(int LocationIndex, bool bForceUnitUpdate);
native function UpdateFormationLocations();

function int SetPawnCreatedDelegate(delegate<OnPawnCreated> delOnPawnCreated)
{
	local int i, NumPawnsSet;

	if (FullStop()) return 0;

	NumPawnsSet = 0;
	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if (m_arrUnits[i].UnitRef.ObjectID == 0 || i >= m_kFormationTemplate.NumSoldiers) continue;

		m_arrUnits[i].delOnPawnCreated = delOnPawnCreated;
		++NumPawnsSet;
	}

	return NumPawnsSet;
}

function int SetSoldier(int LocationIndex, StateObjectReference SoldierRef, optional bool HeadShot = false, optional delegate<OnPawnCreated> delOnPawnCreated)
{
	local int IndexReplaced;
	local int i;
	
	if (FullStop()) return -1;

	IndexReplaced = -1;

	if (LocationIndex >= m_arrUnits.Length)
	{
		m_arrUnits.Add(LocationIndex - m_arrUnits.Length + 1);
		ActorRotation.Add(LocationIndex - m_arrUnits.Length + 1);
	}

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if (m_arrUnits[i].UnitRef == SoldierRef)
		{
			m_arrUnits[i].UnitRef.ObjectID = 0;
			IndexReplaced = i;
		}
	}

	m_arrUnits[LocationIndex].UnitRef = SoldierRef;
	m_arrUnits[LocationIndex].delOnPawnCreated = delOnPawnCreated;

	if (IndexReplaced >= 0)
		UpdateSoldierUnitPhase(IndexReplaced, true);

	UpdateSoldierUnitPhase(LocationIndex, true);

	InitializePosterStrings();

	return IndexReplaced;
}

function string GetSoldierName(int index)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;

	if (FullStop()) return "";

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(m_arrUnits[index].UnitRef.ObjectID));

	return Unit.GetFullName();
}

function bool IsAutoGenHeadShot()
{
	return AutoGenSettings.CampaignID > -1 && AutoGenSettings.TextLayoutState == ePBTLS_HeadShot;
}

event bool IsAutoGenHeadShotOrCaptured()
{
	return AutoGenSettings.CampaignID > -1 && (AutoGenSettings.TextLayoutState == ePBTLS_HeadShot || AutoGenSettings.TextLayoutState == ePBTLS_CapturedSoldier);
}

native function SetSoldierAnim(int LocationIndex, Name AnimationName, float AnimationOffset);

event StateObjectReference GetUnitStateObject(XComUnitPawn Unit)
{
	local XComGameState_Unit GameStateUnit;
	local StateObjectReference UnitSOR;

	GameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
	if (GameStateUnit != none)
		UnitSOR.ObjectID = GameStateUnit.ObjectID;
	else
		UnitSOR.ObjectID = 0;

	return UnitSOR;
}

function OnAsyncLoadCompleted(XComGameState_Unit Unit)
{
	local XComGameState_Unit UnitState;
	local int i;

	if (FullStop()) return;

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrUnits[i].UnitRef.ObjectID));
		if (UnitState == Unit)
		{
			m_arrUnits[i].AsyncLoadComplete = true;
		}
	}
}

event CreateSoldierPawn(int SoldierIndex)
{
	local XComGameState_Unit UnitState;
	local PoseSoldierData SoldierData;
	local bool bAutoGenHeadShot;
	local delegate<OnPawnCreated> delOnPawnCreated;

	bAutoGenHeadShot = IsAutoGenHeadShot();

	SoldierData = m_arrUnits[SoldierIndex];
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SoldierData.UnitRef.ObjectID));
	if (SoldierData.ActorPawn == none)
	{
		SoldierData.ActorPawn = UnitState.CreatePawn(self, SoldierData.Location, SoldierData.Rotation);
		SoldierData.ActorPawn.bPhotoboothPawn = true;
		SoldierData.ActorPawn.GotoState('CharacterCustomization');
		XComHumanPawn(SoldierData.ActorPawn).bIgnoreFor3DCursorCollision = true;

		if (!bAutoGenHeadShot)
		{
			SoldierData.ActorPawn.CreateVisualInventoryAttachments(none, XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SoldierData.UnitRef.ObjectID)), , , , true);
		}

		SetUnitRenderChannels(SoldierData.ActorPawn, SoldierData.UnitRef);
		SoldierData.ActorPawn.SetVisible(false);
		SoldierData.FramesToHide = 4;
		SoldierData.AsyncLoadComplete = false;

		delOnPawnCreated = SoldierData.delOnPawnCreated;
		SoldierData.delOnPawnCreated = none;

		m_arrUnits[SoldierIndex] = SoldierData;

		if (delOnPawnCreated != none)
			delOnPawnCreated();

		UpdateSoldier(SoldierIndex, false, true);
	}
}

event AsyncLoadSoldierPackages(int LocationIndex)
{	
	local XComGameState_Unit UnitState;

	if (m_arrUnits[LocationIndex].UnitRef.ObjectID == 0) return;

	m_arrUnits[LocationIndex].AsyncLoadComplete = false;

	if (bAsyncPawnLoading)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrUnits[LocationIndex].UnitRef.ObjectID));
		UnitState.LoadPawnPackagesAsync(self, m_arrUnits[LocationIndex].Location, m_arrUnits[LocationIndex].Rotation, OnAsyncLoadCompleted);
	}
	else
	{
		CreateSoldierPawn(LocationIndex);
	}
}

event ReleaseSoldierPawnDeferred(PoseSoldierData SoldierData)
{
	local DeferredReleasePawnInfo DRPawnInfo;

	if (FullStop()) return;

	if (SoldierData.ActorPawn != none)
	{
		// leaving this in commented out in case there's any temptation to do this again
		//	this solves the memory related crashes that occur when using Stategy Debug Start/Non-Cheat Start/meetAllFactions crashes
		//	and probably other memory-looking  crashes related to Photobooth as well
		//	setting it to none should ensure that GC cleans it up, as long as nothing else is using it.  --Ned 4/11/2017
		//SoldierData.ActorPawn.Destroy();

		SoldierData.ActorPawn.SetVisible(false);
		DRPawnInfo.ActorPawn = SoldierData.ActorPawn;
		DRPawnInfo.FramesToDeferRelease = 1;
		DeferredReleasePawns.AddItem(DRPawnInfo);

		SoldierData.ActorPawn = none;
	}
}

event ReleaseSoldierPawns()
{
	local int i;

	for (i = 0; i < DeferredReleasePawns.Length; ++i)
	{
		if (DeferredReleasePawns[i].FramesToDeferRelease <= 0)
		{
			if (DeferredReleasePawns[i].ActorPawn != none)
			{
				DeferredReleasePawns[i].ActorPawn.Destroy();
				DeferredReleasePawns[i].ActorPawn = none;
				
			}
			DeferredReleasePawns.Remove(i--, 1);
		}
		else
		{
			--DeferredReleasePawns[i].FramesToDeferRelease;
		}
	}
}

event ResetWeapons(int LocationIndex)
{
	local PoseSoldierData SoldierData;
	local Attachment Attach;
	local array<Attachment> ToBeDeleted;
	local array<Attachment> ToBeReset;
	local XComWeapon Weapon;
	local array<XComWeapon> WeaponsToShow;
	local XComGameState_Item WeaponItemState;
	local array<WeaponAttachment> arrWeaponAttachments;
	local SkeletalMeshComponent UnitSkeletalMesh, AttachSkeletalMesh;
	local Object AttachObject;
	local array<string> SplitAttachMeshName;
	local int i;
	local ParticleSystemComponent PSC;

	SoldierData = m_arrUnits[LocationIndex];
	if (SoldierData.ActorPawn != none)
	{
		UnitSkeletalMesh = SoldierData.ActorPawn.Mesh;

		for (i = 0; i < UnitSkeletalMesh.Attachments.Length; ++i)
		{
			if (UnitSkeletalMesh.Attachments[i].Component != none)
			{
				if (UnitSkeletalMesh.Attachments[i].Component.Outer.Name == 'Transient')
				{
					ToBeDeleted.AddItem(UnitSkeletalMesh.Attachments[i]);
					continue;
				}

				Weapon = XComWeapon(UnitSkeletalMesh.Attachments[i].Component.Outer);
				if (Weapon != none)
				{
					if (WeaponsToShow.Find(Weapon) == INDEX_NONE)
					{
						WeaponsToShow.AddItem(Weapon);
					}

					ToBeReset.AddItem(UnitSkeletalMesh.Attachments[i]);
				}
			}
		}

		foreach ToBeDeleted(Attach)
		{
			AttachSkeletalMesh = SkeletalMeshComponent(Attach.Component);
			if (AttachSkeletalMesh != none)
			{
				foreach AttachSkeletalMesh.AttachedComponents(class'ParticleSystemComponent', PSC)
				{
					PSC.SetActive(false);
				}
			}
			UnitSkeletalMesh.DetachComponent(Attach.Component);
			Attach.Component = none;
		}

		// Need to detach all before we can start attaching to default sockets because we can't have more than one attachment per socket
		foreach ToBeReset(Attach)
		{
			UnitSkeletalMesh.DetachComponent(Attach.Component);
		}

		foreach ToBeReset(Attach)
		{
			Weapon = XComWeapon(Attach.Component.Outer);

			if (StaticMeshComponent(Attach.Component) != none)
			{
				AttachObject = StaticMeshComponent(Attach.Component).StaticMesh;
			}
			else if (SkeletalMeshComponent(Attach.Component) != none)
			{
				AttachObject = SkeletalMeshComponent(Attach.Component).SkeletalMesh;
			}

			if (AttachObject != none)
			{
				if ((StaticMeshComponent(Weapon.Mesh) != none && StaticMeshComponent(Weapon.Mesh).StaticMesh == AttachObject) ||
					(SkeletalMeshComponent(Weapon.Mesh) != none && SkeletalMeshComponent(Weapon.Mesh).SkeletalMesh == AttachObject))
				{
					UnitSkeletalMesh.AttachComponentToSocket(Attach.Component, Weapon.DefaultSocket);
				}
				else if (Weapon.m_kGameWeapon != none)
				{
					WeaponItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Weapon.m_kGameWeapon.ObjectID));
					if (WeaponItemState != none)
					{
						arrWeaponAttachments = WeaponItemState.GetWeaponAttachments(false);
						for (i = 0; i < arrWeaponAttachments.Length; ++i)
						{
							if (arrWeaponAttachments[i].AttachToPawn)
							{
								SplitAttachMeshName = SplitString(arrWeaponAttachments[i].AttachMeshName, ".", true);
								if (SplitAttachMeshName.Length > 0 && Name(SplitAttachMeshName[SplitAttachMeshName.Length - 1]) == AttachObject.Name)
								{
									UnitSkeletalMesh.AttachComponentToSocket(Attach.Component, arrWeaponAttachments[i].AttachSocket);
								}
							}
						}
					}
				}
			}
		}

		foreach WeaponsToShow(Weapon)
		{
			Weapon.ShowWeapon();
		}
	}
}

event SetTemplarFocus(int LocationIndex)
{
	local PoseSoldierData SoldierData;
	local XComGameState_Unit UnitState;
	local CustomAnimParams AnimParams;

	SoldierData = m_arrUnits[LocationIndex];
	if (SoldierData.ActorPawn != none)
	{
		if (SoldierData.UnitRef.ObjectID > 0)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SoldierData.UnitRef.ObjectID));
		}

		// Set up Focus Level 1 FX.
		if (UnitState != none && UnitState.GetSoldierClassTemplateName() == 'Templar')
		{
			AnimParams.AnimName = Name("ADD_StartFocus" $ string(1));
			AnimParams.BlendTime = 0.0f;

			if (SoldierData.ActorPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
			{
				SoldierData.ActorPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams);
			}
		}
	}
}

function InitializeParticleNotifies()
{
	local int i;

	for (i = 0; i < ParticleEffects.length; ++i)
	{
		ParticleEffects[i].StopNotify = new(self) class'AnimNotify_StopParticleEffect';
		ParticleEffects[i].StopNotify.PSTemplate = ParticleSystem(DynamicLoadObject(ParticleEffects[i].PSTemplateName, class'ParticleSystem'));
		ParticleEffects[i].StopNotify.SocketName = ParticleEffects[i].SocketName;
		ParticleEffects[i].StopNotify.bImmediate = true;

		ParticleEffects[i].PlayNotify = new(self) class'AnimNotify_PlayParticleEffect';
		ParticleEffects[i].PlayNotify.PSTemplate = ParticleEffects[i].StopNotify.PSTemplate;
		ParticleEffects[i].PlayNotify.SocketName = ParticleEffects[i].SocketName;
		ParticleEffects[i].PlayNotify.bAttach = true;
	}
}

event SetParticleEffects(int LocationIndex)
{
	local PoseSoldierData SoldierData;
	local AnimationPoses AnimPose;
	local PhotoboothParticleEffects Effect;
	local Photobooth_ParticleEffectType EffectType;

	SoldierData = m_arrUnits[LocationIndex];
	if (SoldierData.ActorPawn != none)
	{
		foreach ParticleEffects(Effect)
		{
			SoldierData.ActorPawn.Mesh.StopParticleEffect(Effect.StopNotify);
		}

		foreach m_arrAnimationPoses(AnimPose)
		{
			if (AnimPose.AnimationName == SoldierData.AnimationName && AnimPose.AnimationOffset == SoldierData.AnimationOffset)
			{
				foreach AnimPose.ParticleEffectTypes(EffectType)
				{
					foreach ParticleEffects(Effect)
					{
						if (Effect.ParticleEffectType == EffectType)
						{
							SoldierData.ActorPawn.PlayParticleEffect(Effect.PlayNotify);
						}
					}
				}

				break;
			}
		}
	}
}

event StartClothingBlend(XComUnitPawnNativeBase UnitPawn)
{
	local XComHumanPawn HumanPawn;

	HumanPawn = XComHumanPawn(UnitPawn);
	if (HumanPawn != None)
	{		
		HumanPawn.ClothBlendValue = 0.0f;
		HumanPawn.SetApexClothingMaxDistanceScale_Manual(HumanPawn.ClothBlendValue);
		HumanPawn.BlendClothFromSkinnedPosition();
	}
}

event CheckForSparkUnits(out array<int> outSparkPositions)
{
	local XComGameState_Unit UnitState;
	local int i;

	outSparkPositions.Length = 0;

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if (m_arrUnits[i].UnitRef.ObjectID > 0)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrUnits[i].UnitRef.ObjectID));
			if (UnitState != none && class'X2PhotoboothHelpers'.static.IsLikeSpark(UnitState.GetMyTemplateName()))
			{
				outSparkPositions.AddItem(i);
			}
		}
	}
}

function SetUnitRenderChannels(XComUnitPawn Unit, StateObjectReference UnitRef)
{
	local RenderChannelContainer RenderChannels;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;
	local XComAlienPawn CosmeticPawn;
	local X2GremlinTemplate GremlinTemplate;
	local AnimationPoses CosmeticPawnPose;
	local CustomAnimParams AnimParams;

	RenderChannels.MainScene = !IsAutoGenHeadShot() || !AutoGenSettings.bLadderMode;
	RenderChannels.SecondaryScene = true;

	Unit.UpdateMeshRenderChannels(RenderChannels);

	// Show the unit's gremlin, if he has one
	if (!IsAutoGenHeadShot())
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState != none)
		{
			ItemState = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon);
			if (ItemState != none)
			{
				GremlinTemplate = X2GremlinTemplate(ItemState.GetMyTemplate());
				if (GremlinTemplate != none)
				{
					CosmeticPawn = XComAlienPawn(`PRESBASE.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID, true));
					if (CosmeticPawn != none)
					{
						CosmeticPawn.bPhotoboothPawn = true;
						CosmeticPawn.UpdateMeshRenderChannels(RenderChannels);

						if (GremlinTemplate.WeaponCat == 'sparkbit')
						{
							CosmeticPawnPose = m_arrAnimationBitPoses[`SYNC_RAND(m_arrAnimationBitPoses.Length)];
						}
						else
						{
							CosmeticPawnPose = m_arrAnimationGremlinPoses[`SYNC_RAND(m_arrAnimationGremlinPoses.Length)];
						}

						if (CosmeticPawn.GetAnimTreeController().CanPlayAnimation(CosmeticPawnPose.AnimationName))
						{
							AnimParams.AnimName = CosmeticPawnPose.AnimationName;
							AnimParams.StartOffsetTime = CosmeticPawnPose.AnimationOffset;
							AnimParams.PlayRate = 0.0;
							AnimParams.BlendTime = 0.0;

							CosmeticPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
						}
					}
				}
			}
		}
	}
}

/******************************************/
//		Render Functions
/******************************************/

event InitializeRenderData()
{
	InitializeUI();
	InitializeTextures();
	InitializeCaptures();
	InitializeParticleNotifies();

	UserTextLayoutState = ePBTLS_NONE;
}

native function CalculateCaptureScreenCoordinates(out array<Vector2D> coordinateCorners, out Vector2D ViewSize);

function SetupCaptureBounds()
{
	local PlayerController pc;
	local XComLocalPlayer localPlayer;
	local float aspectRatio;
	
	pc = GetALocalPlayerController();
	localPlayer = XComLocalPlayer(pc.Player);
	if (localPlayer != none)
	{
		aspectRatio = float(m_iPosterSizeX) / float(m_iPosterSizeY);
		m_iOnScreenSizeY = localPlayer.SceneView.SizeY * m_fMaxYPercentage;
		m_iOnScreenSizeX = m_iOnScreenSizeY * aspectRatio;

		if (m_iOnScreenSizeX > (localPlayer.SceneView.SizeX * m_fMaxXPercentage))
		{
			m_iOnScreenSizeX = localPlayer.SceneView.SizeX * m_fMaxXPercentage;
			m_iOnScreenSizeY = m_iOnScreenSizeX / aspectRatio;
		}
				
		m_iOnScreenX = (localPlayer.SceneView.SizeX - m_iOnScreenSizeX) * 0.5;
		m_iOnScreenY = (localPlayer.SceneView.SizeY - m_iOnScreenSizeY) * 0.5;
	}

	if (m_kPhotoboothShowEffect != none)
	{
		m_kPhotoboothShowEffect.X = m_iOnScreenX;
		m_kPhotoboothShowEffect.Y = m_iOnScreenY;

		m_kPhotoboothShowEffect.SizeX = m_iOnScreenSizeX;
		m_kPhotoboothShowEffect.SizeY = m_iOnScreenSizeY;
	}

	ResizeRenderTargets();
}

native function GetFinalPosterSize(out int SizeX, out int SizeY);

simulated function Tick(float DeltaTime)
{
	if (FullStop()) return;

	if (m_kAutoGenCaptureState == eAGCS_Idle)
	{
		SetupCaptureBounds();
		ResizeRenderTargets();
		ResizeFinalRenderTarget(false);
	}
}

function InitializeTextures()
{
	local int FinalSizeX, FinalSizeY;

	GetFinalPosterSize(FinalSizeX, FinalSizeY);
	SetupCaptureBounds();

	if (m_kPreviewPosterTexture == none)
	{
		m_kPreviewPosterTexture = `XENGINE.m_kPhotoboothSoldierTexture;
	}

	if (m_kFinalPosterTexture == none)
	{
		m_kFinalPosterTexture = class'TextureRenderTarget2D'.static.Create(FinalSizeX, FinalSizeY, PF_A8R8G8B8, MakeLinearColor(0, 0, 0, 0), false, false, true, self);
		m_kFinalPosterTexture.SRGB = false;
		m_kFinalPosterTexture.Filter = TF_Linear;
		m_kFinalPosterTexture.bNeedsTwoCopies = true;
	}

	if (m_kUIRenderTexture != none &&
		(m_iPosterSizeX != m_kUIRenderTexture.SizeX || m_iPosterSizeY != m_kUIRenderTexture.SizeY))
	{
		class'TextureRenderTarget2D'.static.Resize(m_kUIRenderTexture, m_iPosterSizeX, m_iPosterSizeY);
	}
}

function ResizeFinalRenderTarget(bool bHeadShot)
{
	local int FinalSizeX, FinalSizeY;

	if (bHeadShot)
	{
		FinalSizeX = AutoGenSettings.SizeX;
		FinalSizeY = AutoGenSettings.SizeY;
	}
	else
	{
		GetFinalPosterSize(FinalSizeX, FinalSizeY);
	}

	if (m_kFinalPosterTexture != none && (FinalSizeX != m_kFinalPosterTexture.SizeX || FinalSizeY != m_kFinalPosterTexture.SizeY))
	{
		class'TextureRenderTarget2D'.static.Resize(m_kFinalPosterTexture, FinalSizeX, FinalSizeY);

		m_kFinalPosterComponent.SetCaptureParameters(
			m_kFinalPosterTexture,
			m_kCameraPOV.FOV, // FOV
			m_kFinalPosterComponent.NearPlane,
			m_kFinalPosterComponent.FarPlane,
			, ,
			0, 0, 0, 0);
	}
}

function ResizeRenderTargets()
{
	if (m_kPreviewPosterTexture != none &&
		(m_iOnScreenSizeX != m_kPreviewPosterTexture.SizeX || m_iOnScreenSizeY != m_kPreviewPosterTexture.SizeY))
	{
		class'TextureRenderTarget2D'.static.Resize(m_kPreviewPosterTexture, m_iOnScreenSizeX, m_iOnScreenSizeY);

		// Set camera parameters to contain the bounding area of BoundingActor
		m_kPreviewPosterComponent.SetCaptureParameters(
			m_kPreviewPosterTexture,
			m_kCameraPOV.FOV, // FOV
			m_kPreviewPosterComponent.NearPlane,
			m_kPreviewPosterComponent.FarPlane,
			, ,
			0, 0, 0, 0);
	}
}

function InitializeCaptures()
{
	m_kPosterPostProcessChain = PostProcessChain(`CONTENT.RequestGameArchetype(PhotoboothPostProcessChainName));
	m_kPreviewPosterComponent.PostProcess = m_kPosterPostProcessChain;
	m_kFinalPosterComponent.PostProcess = m_kPosterPostProcessChain;

	EnablePostProcess();
	HideEntirePoster(true);

	// Set camera parameters to contain the bounding area of BoundingActor
	m_kPreviewPosterComponent.SetCaptureParameters(
		m_kPreviewPosterTexture,
		m_kCameraPOV.FOV);

	m_kFinalPosterComponent.SetCaptureParameters(
		m_kFinalPosterTexture,
		m_kCameraPOV.FOV);

	m_kPreviewPosterComponent.SetEnabled(true);	
}

function SetCameraPOV(TPOV inCameraPOV, optional bool bIgnorePreview = false)
{
	if (FullStop()) return;

	if (inCameraPOV.FOV != m_kPreviewPosterComponent.FieldOfView)
	{
		m_kPreviewPosterComponent.SetCaptureParameters(
			m_kPreviewPosterTexture,
			inCameraPOV.FOV);
	}

	if (inCameraPOV.FOV != m_kFinalPosterComponent.FieldOfView)
	{
		m_kFinalPosterComponent.SetCaptureParameters(
			m_kFinalPosterTexture,
			inCameraPOV.FOV);
	}

	m_kPreviewPosterComponent.SetView(inCameraPOV.Location, inCameraPOV.Rotation);
	m_kFinalPosterComponent.SetView(inCameraPOV.Location, inCameraPOV.Rotation);

	if (inCameraPOV == m_kCameraPOV
		&& inCameraPOV.Location != vect(0, 0, 0)
		&& !bIgnorePreview)
	{
		HideEntirePoster(false);
	}

	m_kCameraPOV = inCameraPOV;
}

function ShowFog(bool bShow)
{
	if (m_kPreviewPosterComponent != none)
		m_kPreviewPosterComponent.bEnableFog = bShow;

	if (m_kFinalPosterComponent != none)
		m_kFinalPosterComponent.bEnableFog = bShow;
}

native function StartReadingPixels(TextureRenderTarget2D RenderTarget);
native function bool ReadingPixelsComplete();

function SavePosterAndFinish()
{
	local array<int> ObjectIDs;
	local int i;
	local EPhotoDataType PhotoType;
	local Photobooth_TextLayoutState LocalTextLayoutState;

	if (m_kAutoGenCaptureState == eAGCS_Capturing)
	{
		if (ReadingPixelsComplete())
		{
			for (i = 0; i < m_arrUnits.Length; ++i)
			{
				if (m_arrUnits[i].UnitRef.ObjectID > 0)
				{
					ObjectIDs.AddItem(m_arrUnits[i].UnitRef.ObjectID);
				}
			}

			PhotoType = ePDT_User;
			if (IsAutoGenHeadShot())
			{
				PhotoType = ePDT_HeadShot;
			}
			else
			{
				LocalTextLayoutState = ePBTLS_NONE;
				if (AutoGenSettings.CampaignID > -1)
				{
					LocalTextLayoutState = AutoGenSettings.TextLayoutState;
				}
				else if (UserTextLayoutState != ePBTLS_NONE)
				{
					LocalTextLayoutState = UserTextLayoutState;
				}

				switch (LocalTextLayoutState)
				{
				case ePBTLS_CapturedSoldier:
					PhotoType = ePDT_Captured;
					break;
				case ePBTLS_PromotedSoldier:
					PhotoType = ePDT_Promoted;
					break;
				case ePBTLS_DeadSoldier:
					PhotoType = ePDT_Dead;
					break;
				case ePBTLS_BondedSoldier:
					PhotoType = ePDT_Bonded;
					break;
				}
			}

			`XENGINE.m_kPhotoManager.AddPosterFromSurfData(PixelData, m_iGameIndex, ObjectIDs, PhotoType,
				m_kFinalPosterTexture.SizeX, m_kFinalPosterTexture.SizeY);

			if (AutoGenSettings.CampaignID > -1)
			{
				SetBackgroundColorOverride(false);
			}

			AutoGenSettings.CampaignID = -1;
			m_kAutoGenCaptureState = eAGCS_Idle;

			if (m_kOnPosterCreated != none)
			{
				m_kOnPosterCreated(AutoGenSettings.PossibleSoldiers[0]);
			}

			m_kFinalPosterComponent.bUseMainScenePostProcessSettings = true;

			UserTextLayoutState = ePBTLS_NONE;
		}
		else
		{
			SetTimer(0.001f, false, nameof(SavePosterAndFinish));
		}
	}
}

function OnPosterFinished(TextureRenderTarget2D RenderTarget)
{
	if (FullStop()) return;

	m_kFinalPosterComponent.m_nRenders = 1;
	m_kFinalPosterComponent.SetEnabled(false);

	if (FixedTacticalAutoGenCamera != none)
	{
		`CAMERASTACK.RemoveCamera(FixedTacticalAutoGenCamera);
		FixedTacticalAutoGenCamera = none;
	}

	StartReadingPixels(RenderTarget);

	SetTimer(0.001f, false, nameof(SavePosterAndFinish));
}

function CreatePoster(optional int FrameDelay, optional delegate<OnPosterCreated> inOnPosterCreated, optional Photobooth_TextLayoutState InUserTextLayoutState = ePBTLS_NONE)
{
	if (FullStop()) return;

	m_kOnPosterCreated = inOnPosterCreated;
	m_kFinalPosterComponent.FrameDelay = FrameDelay;
	m_kFinalPosterComponent.OnCaptureFinished = OnPosterFinished;
	m_kFinalPosterComponent.SetEnabled(true);
	UserTextLayoutState = InUserTextLayoutState;
}

/******************************************/
//		Set Functions
/******************************************/

function InitializeUI()
{
	InitPosterLayouts();
	ConstructTextLayout();
}

function InitPosterLayouts()
{
	m_textLayoutTemplateMan = class'X2PropagandaTextLayoutTemplateManager'.static.GetPropagandaTextLayoutTemplateManager();
	m_textLayoutTemplateMan.InitTemplates();
	m_textLayoutTemplateMan.GetUberTemplates("Text", m_aTextLayouts);

	m_currentTextLayoutTemplateIndex = 0;
}

function ConstructTextLayout()
{
	m_currentTextLayoutTemplate = m_aTextLayouts[m_currentTextLayoutTemplateIndex];

	if (m_PosterStrings.Length < m_currentTextLayoutTemplate.NumTextBoxes)
		m_PosterStrings.Add(m_currentTextLayoutTemplate.NumTextBoxes - m_PosterStrings.Length);
	if (m_PosterFont.Length < m_currentTextLayoutTemplate.NumTextBoxes)
		m_PosterFont.Add(m_currentTextLayoutTemplate.NumTextBoxes - m_PosterFont.Length);
	if (m_FontSize.Length < m_currentTextLayoutTemplate.NumTextBoxes)
		m_FontSize.Add(m_currentTextLayoutTemplate.NumTextBoxes - m_FontSize.Length);
	if (m_PosterStringColors.Length < m_currentTextLayoutTemplate.NumTextBoxes)
		m_PosterStringColors.Add(m_currentTextLayoutTemplate.NumTextBoxes - m_PosterStringColors.Length);

	if (m_FontColors.Length == 0)
		SetupFontColors();

	if (m_backgroundPoster != none)
	{
		`PRESBASE.GetPhotoboothMovie().RemoveScreen(m_backgroundPoster);
	}
	m_backgroundPoster = Spawn(class'UIPosterScreen', self);
	m_backgroundPoster.LibID = name("PosterMC" $ 1 + m_currentTextLayoutTemplate.LayoutIndex);
	m_backgroundPoster.InitScreen(XComPlayerController(`PRESBASE.Owner), `PRESBASE.GetPhotoboothMovie());

	`PRESBASE.GetPhotoboothMovie().LoadScreen(m_backgroundPoster);

	UpdatePosterTexture();
	InitializePosterStrings();
}

function SetCamLookAtNamedLocation()
{
	if (FullStop()) return;

	if (m_backgroundPoster != none)
	{
		m_backgroundPoster.SetCamLookAtNamedLocation();
	}
}

function SetupFontColors()
{
	local XComLinearColorPalette Palette;
	local int i;

	Palette = `CONTENT.GetColorPalette(ePalette_FontColors);
	m_RandomColors = Palette.BaseOptions;
	for (i = 0; i < Palette.Entries.length; i++)
	{
		m_FontColors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, class'XComCharacterCustomization'.default.UIColorBrightnessAdjust));
		m_SecondaryFontColors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Secondary, class'XComCharacterCustomization'.default.UIColorBrightnessAdjust));
	}
}

function UpdatePosterTexture()
{
	m_kUIRenderTexture = `PRESBASE.GetPhotoboothMovie().RenderTexture;

	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.UIRenderTarget = m_kUIRenderTexture;
	}
}

function HidePosterTexture()
{
	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.UIRenderTarget = none;
	}
}

// deprecated function used for initial string implementation
function InitializePosterStrings()
{
	local int i;
	local array<FontOptions> arrFontOptions;

	GetFonts(arrFontOptions);
	for (i = 0; i < m_currentTextLayoutTemplate.NumTextBoxes; i++)
	{
		SetTextBoxString(i, m_PosterStrings[i]);
		if (m_PosterFont[i] == "")
		{
			//randomize font and color for a new string
			m_PosterFont[i] = arrFontOptions[`SYNC_RAND(arrFontOptions.Length)].FontName;
			m_PosterStringColors[i] = `SYNC_RAND(m_RandomColors);
		}

		SetTextBoxFont(i, m_PosterFont[i]);
		SetTextBoxColor(i, m_PosterStringColors[i]);
	}
}

/******************************************/
//		Set Functions
/******************************************/

function SetBackgroundTexture(string BackgroundDisplayName)
{
	local int BackgroundIndex;

	if (FullStop()) return;

	for (BackgroundIndex = 0; BackgroundIndex < m_arrBackgroundOptions.Length; ++BackgroundIndex)
	{
		if (m_arrBackgroundOptions[BackgroundIndex].BackgroundDisplayName == BackgroundDisplayName)
			break;
	}

	if (BackgroundIndex >= m_arrBackgroundOptions.Length)
		return;

	if (m_arrBackgroundOptions[BackgroundIndex].BackgroundTexture == none)
	{
		m_arrBackgroundOptions[BackgroundIndex].BackgroundTexture = Texture2D(`CONTENT.RequestGameArchetype(m_arrBackgroundOptions[BackgroundIndex].BackgroundName));
	}

	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.BackgroundTexture = m_arrBackgroundOptions[BackgroundIndex].BackgroundTexture;

		SetCaptureRenderChannels();
		SetFirstPassFilterTints();
	}
}

function SetCaptureRenderChannels()
{
	if (m_kPhotoboothEffect.BackgroundTexture == none
		|| m_kPhotoboothEffect.bShowInGame == false)
	{
		m_kPreviewPosterComponent.RenderChannels.MainScene = true;
		m_kFinalPosterComponent.RenderChannels.MainScene = true;

		m_kPreviewPosterComponent.bEnableFog = true;
		m_kFinalPosterComponent.bEnableFog = true;
	}
	else
	{
		m_kPreviewPosterComponent.RenderChannels.MainScene = false;
		m_kFinalPosterComponent.RenderChannels.MainScene = false;

		m_kPreviewPosterComponent.bEnableFog = false;
		m_kFinalPosterComponent.bEnableFog = false;
	}

	ReattachComponent(m_kPreviewPosterComponent);
}

function SetFirstPassFilterTints()
{
	local MaterialInstanceConstant FilterMIC;
	local int FilterIndex;
	local LinearColor ParamValue;

	if (m_kPhotoboothEffect != none)
	{
		if (m_kPhotoboothEffect.FirstPassFilterMI != none)
		{
			for (FilterIndex = 0; FilterIndex < m_arrFirstPassFilterOptions.Length; ++FilterIndex)
			{
				if (m_kPhotoboothEffect.FirstPassFilterMI == m_arrFirstPassFilterOptions[FilterIndex].FilterMI &&
					m_arrFirstPassFilterOptions[FilterIndex].bUsesTintColors)
				{
					FilterMIC = MaterialInstanceConstant(m_kPhotoboothEffect.FirstPassFilterMI);
					if (FilterMIC != none)
					{
						if (m_kPhotoboothEffect.bOverrideBackgroundTextureColor)
						{
							ParamValue = m_kPhotoboothEffect.GradientColor1;
							FilterMIC.SetVectorParameterValue('FirstBackgroundColor', ParamValue);
							ParamValue = m_kPhotoboothEffect.GradientColor2;
							FilterMIC.SetVectorParameterValue('SecondBackgroundColor', ParamValue);
						}
						else
						{
							ParamValue = m_arrFirstPassFilterOptions[FilterIndex].OrigColor1;
							FilterMIC.SetVectorParameterValue('FirstBackgroundColor', ParamValue);
							ParamValue = m_arrFirstPassFilterOptions[FilterIndex].OrigColor2;
							FilterMIC.SetVectorParameterValue('SecondBackgroundColor', ParamValue);
						}

						break;
					}
				}
			}
		}
	}
}

function SetFirstPassFilter(int FilterIndex)
{
	local MaterialInstanceConstant FilterMIC;
	local LinearColor ParamValue;

	if (FullStop()) return;

	if (FilterIndex >= m_arrFirstPassFilterOptions.Length)
	{
		m_kPhotoboothEffect.FirstPassFilterMI = none;
	}
	else
	{
		if (m_arrFirstPassFilterOptions[FilterIndex].FilterMI == none)
		{
			m_arrFirstPassFilterOptions[FilterIndex].FilterMI = MaterialInterface(`CONTENT.RequestGameArchetype(m_arrFirstPassFilterOptions[FilterIndex].FilterName));

			if (m_arrFirstPassFilterOptions[FilterIndex].FilterMI != none && m_arrFirstPassFilterOptions[FilterIndex].bUsesTintColors)
			{
				FilterMIC = MaterialInstanceConstant(m_arrFirstPassFilterOptions[FilterIndex].FilterMI);
				if (FilterMIC != none)
				{
					if (FilterMIC.GetVectorParameterValue('FirstBackgroundColor', ParamValue))
					{
						m_arrFirstPassFilterOptions[FilterIndex].OrigColor1 = ParamValue;
					}
					if (FilterMIC.GetVectorParameterValue('SecondBackgroundColor', ParamValue))
					{
						m_arrFirstPassFilterOptions[FilterIndex].OrigColor2 = ParamValue;
					}
				}
			}
		}

		m_kPhotoboothEffect.FirstPassFilterMI = m_arrFirstPassFilterOptions[FilterIndex].FilterMI;

		SetFirstPassFilterTints();
	}
}

function SetSecondPassFilter(int FilterIndex)
{
	if (FullStop()) return;

	if (FilterIndex >= m_arrSecondPassFilterOptions.Length)
	{
		m_kPhotoboothEffect.SecondPassFilterMI = none;
	}
	else
	{
		if (m_arrSecondPassFilterOptions[FilterIndex].FilterMI == none)
		{
			m_arrSecondPassFilterOptions[FilterIndex].FilterMI = MaterialInterface(`CONTENT.RequestGameArchetype(m_arrSecondPassFilterOptions[FilterIndex].FilterName));
		}

		m_kPhotoboothEffect.SecondPassFilterMI = m_arrSecondPassFilterOptions[FilterIndex].FilterMI;
	}
}

function HidePosterElements(bool bHide)
{
	if (FullStop()) return;

	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.bShowInGame = !bHide;
		SetCaptureRenderChannels();
	}
}

function HideEntirePoster(bool bHide)
{
	if (FullStop()) return;

	if (m_kPhotoboothShowEffect != none)
	{
		m_kPhotoboothShowEffect.bShowInGame = !bHide;
		SetCaptureRenderChannels();
	}
}

function EnablePostProcess()
{
	local LocalPlayer LP;
	local int i, j;
	local PostProcessChain PPChain;
	local bool bFoundEffect;

	bFoundEffect = false;
	LP = LocalPlayer(`XWORLDINFO.GetALocalPlayerController().Player);
	for (i = 0; i < LP.PlayerPostProcessChains.Length; i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for (j = 0; j < PPChain.Effects.Length; j++)
		{
			m_kPhotoboothShowEffect = PhotoboothEffect(PPChain.Effects[j]);
			if (m_kPhotoboothShowEffect != none)
			{
				m_kPhotoboothShowEffect.eEffectType = ePBET_ShowPoster;
				m_kPhotoboothShowEffect.bShowInGame = true;
				m_kPhotoboothShowEffect.SoldierRenderTarget = m_kPreviewPosterTexture;
				m_kPhotoboothShowEffect.BackgroundTexture = none;
				m_kPhotoboothShowEffect.UIRenderTarget = none;

				m_kPhotoboothShowEffect.X = m_iOnScreenX;
				m_kPhotoboothShowEffect.Y = m_iOnScreenY;
				m_kPhotoboothShowEffect.SizeX = m_iOnScreenSizeX;
				m_kPhotoboothShowEffect.SizeY = m_iOnScreenSizeY;

				break;
			}
		}

		if (bFoundEffect == true)
		{
			break;
		}
	}

	for (i = 0; i < m_kPosterPostProcessChain.Effects.Length; i++)
	{
		m_kPhotoboothEffect = PhotoboothEffect(m_kPosterPostProcessChain.Effects[i]);
		if (m_kPhotoboothEffect != none)
		{
			m_kPhotoboothEffect.eEffectType = ePBET_GeneratePoster;
			m_kPhotoboothEffect.bShowInGame = true;
			m_kPhotoboothEffect.SoldierRenderTarget = none;
			m_kPhotoboothEffect.BackgroundTexture = none;
			m_kPhotoboothEffect.UIRenderTarget = m_kUIRenderTexture;
			m_kPhotoboothEffect.GradientColor1 = MakeLinearColor(0.0f, 0.0f, 0.0f, 0.0f);
			m_kPhotoboothEffect.GradientColor2 = MakeLinearColor(1.0f, 1.0f, 1.0f, 1.0f);
			m_kPhotoboothEffect.bOverrideBackgroundTextureColor = true;
			break;
		}
	}
}

function DisablePostProcess()
{
	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.bShowInGame = false;
		m_kPhotoboothEffect.SoldierRenderTarget = none;
		m_kPhotoboothEffect.BackgroundTexture = none;
		m_kPhotoboothEffect.UIRenderTarget = none;
		m_kPhotoboothEffect = none;
	}

	if (m_kPhotoboothShowEffect != none)
	{
		m_kPhotoboothShowEffect.bShowInGame = false;
		m_kPhotoboothShowEffect.SoldierRenderTarget = none;
		m_kPhotoboothShowEffect.BackgroundTexture = none;
		m_kPhotoboothShowEffect.UIRenderTarget = none;
		m_kPhotoboothShowEffect = none;
	}
}

function SetLayoutIndex(int inLayoutIndex)
{
	if (FullStop()) return;

	if (inLayoutIndex < 0 || inLayoutIndex >= m_aTextLayouts.Length)
		return;

	m_currentTextLayoutTemplateIndex = inLayoutIndex;
	ConstructTextLayout();
}

function SetTextLayoutByType(TextLayoutType InLayoutType)
{
	local int i;
	local array<X2PropagandaTextLayoutTemplate> MatchingTextLayouts;

	if (FullStop()) return;

	for (i = 0; i < m_aTextLayouts.Length; ++i)
	{
		if (m_aTextLayouts[i].LayoutType == InLayoutType)
		{
			MatchingTextLayouts.AddItem(m_aTextLayouts[i]);
		}
	}

	if (MatchingTextLayouts.Length > 0)
	{
		SetLayoutIndex(MatchingTextLayouts[`SYNC_RAND(MatchingTextLayouts.Length)].LayoutIndex);
	}
	else
	{
		SetLayoutIndex(m_aTextLayouts[`SYNC_RAND(m_aTextLayouts.Length)].LayoutIndex);
	}
}

function SetTextLayoutByNumOfTextBoxes(int InNumTextBoxes)
{
	local int i;
	local array<X2PropagandaTextLayoutTemplate> MatchingTextLayouts;

	// No text layout has more than 3 boxes
	if (InNumTextBoxes < 1 || InNumTextBoxes > 3) return;

	for (i = 0; i < m_aTextLayouts.Length; ++i)
	{
		if (m_aTextLayouts[i].NumTextBoxes == InNumTextBoxes)
		{
			MatchingTextLayouts.AddItem(m_aTextLayouts[i]);
		}
	}

	if (MatchingTextLayouts.Length > 0)
	{
		SetLayoutIndex(MatchingTextLayouts[`SYNC_RAND(MatchingTextLayouts.Length)].LayoutIndex);
	}
	else
	{
		SetLayoutIndex(m_aTextLayouts[`SYNC_RAND(m_aTextLayouts.Length)].LayoutIndex);
	}
}

function SetTextBoxString(int Index, string textString)
{
	if (FullStop()) return;

	//m_bChangedDefaultPosterStrings[Index] = true;
	m_PosterStrings[Index] = textString;
	m_backgroundPoster.mc.FunctionString("posterSetText"$Index + 1, textString);
}

function SetTextBoxFont(int Index, string textFont)
{
	if (FullStop()) return;

	//m_bChangedDefaultPosterStrings[Index] = true;
	m_PosterFont[Index] = textFont;
	m_backgroundPoster.mc.FunctionString("SetTextBoxFont"$Index + 1, textFont);
}

function SetFontSize(int Index, int size)
{
	//m_bChangedDefaultPosterStrings[Index] = true;
	m_FontSize[Index] = size;
	m_backgroundPoster.mc.FunctionNum("SetTextBoxFontSize"$Index + 1, size);
}

function SetTextBoxColor(int Index, int textColor)
{
	if (FullStop()) return;

	//m_bChangedDefaultPosterStrings[Index] = true;
	m_PosterStringColors[Index] = textColor;
	m_backgroundPoster.mc.FunctionString("SetTextBoxFontColor"$Index + 1, m_FontColors[textColor]);
	m_backgroundPoster.mc.FunctionString("SetTextBoxStrokeColor"$Index + 1, m_SecondaryFontColors[textColor]);
	// UI TODO: UI to set up a function for setting the secondary font color using m_SecondaryFontColors
}

function SetIcon(int Index, string ImagePath)
{
	if (FullStop()) return;

	m_backgroundPoster.mc.FunctionString("posterSetIcon"$Index + 1, ImagePath);
}

function SetGradientColor1(LinearColor InColor)
{
	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.GradientColor1 = InColor;
	}
}

function SetGradientColor2(LinearColor InColor)
{
	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.GradientColor2 = InColor;
	}
}

function SetGradientColorIndex1(int InColorIndex)
{
	local XComLinearColorPalette Palette;

	if (FullStop()) return;

	Palette = `CONTENT.GetColorPalette(ePalette_FontColors);

	m_iGradientColor1Index = InColorIndex;
	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.GradientColor1 = Palette.Entries[InColorIndex].Primary;
	}

	SetFirstPassFilterTints();
}

function SetGradientColorIndex2(int InColorIndex)
{
	local XComLinearColorPalette Palette;

	if (FullStop()) return;

	Palette = `CONTENT.GetColorPalette(ePalette_FontColors);
	m_iGradientColor2Index = InColorIndex;
	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.GradientColor2 = Palette.Entries[InColorIndex].Primary;
	}

	SetFirstPassFilterTints();
}

function SetBackgroundColorOverride(bool InOverride)
{
	if (FullStop()) return;

	if (m_kPhotoboothEffect != none)
	{
		m_kPhotoboothEffect.bOverrideBackgroundTextureColor = InOverride;
	}

	SetFirstPassFilterTints();
}

/******************************************/
//		Info Functions
/******************************************/

function GetPosterCorners(out Vector2D TopLeft, out Vector2D BottomRight)
{
	local PlayerController pc;
	local XComLocalPlayer localPlayer;
	local float screenSizeX, screenSizeY;

	if (FullStop()) return;

	pc = GetALocalPlayerController();
	localPlayer = XComLocalPlayer(pc.Player);
	if (localPlayer != none)
	{
		screenSizeX = localPlayer.SceneView.SizeX;
		screenSizeY = localPlayer.SceneView.SizeY;

		TopLeft.X = m_iOnScreenX / screenSizeX;
		TopLeft.Y = m_iOnScreenY / screenSizeY;
		BottomRight.X = (m_iOnScreenX + m_iOnScreenSizeX) / screenSizeX;
		BottomRight.Y = (m_iOnScreenY + m_iOnScreenSizeY) / screenSizeY;
	}
}

function int GetFormations(out array<X2PropagandaPhotoTemplate> outFormations)
{
	local int i;

	if (FullStop()) return -1;

	outFormations = m_arrFormations;
	for (i = 0; i < m_arrFormations.length; ++i)
	{
		if (m_kFormationTemplate == m_arrFormations[i])
			return i;
	}

	return -1;
}

function bool CurrentFormationIsSolo()
{
	return m_kFormationTemplate != none && m_kFormationTemplate.DataName == name("Solo");
}

private function XComGameState_Unit GetUnit(StateObjectReference UnitRef)
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

function int GetNumSoldierSlots()
{
	if (FullStop()) return 0;

	return m_kFormationTemplate.NumSoldiers;
}

function StateObjectReference GetCurrentSoldier(int LocationIndex)
{
	local StateObjectReference Soldier;

	if (LocationIndex < m_arrUnits.Length)
		Soldier = m_arrUnits[LocationIndex].UnitRef;
	else
		Soldier.ObjectID = 0;

	return Soldier;
}

function int GetPossibleSoldiers(int LocationIndex, array<StateObjectReference> inSoldiers, out array<StateObjectReference> outSoldiers)
{
	local int i;
	local int CurrentSoldierIndex;
	local int AddIndex;

	if (FullStop()) return -1;

	outSoldiers.Length = 0;
	CurrentSoldierIndex = -1;

	for (i = 0; i < inSoldiers.Length; ++i)
	{
		if (m_kFormationTemplate.IsUnitAllowed(LocationIndex, GetUnit(inSoldiers[i])))
		{
			AddIndex = outSoldiers.AddItem(inSoldiers[i]);

			if (m_arrUnits[LocationIndex].UnitRef == inSoldiers[i])
				CurrentSoldierIndex = AddIndex;
		}
	}

	return CurrentSoldierIndex;
}

function bool RestrictedFromFormation(int LocationIndex, AnimationPoses AnimPose)
{
	local PoseFormationRestrictionInfo Restriction;
	local string LocTag;

	if (m_kFormationTemplate != none && m_kFormationTemplate.NumSoldiers > LocationIndex)
	{
		foreach PoseFormationRestrictions(Restriction)
		{
			if (Restriction.AnimationName == AnimPose.AnimationName
				&& Restriction.AnimationOffset == AnimPose.AnimationOffset
				&& Restriction.FormationName == m_kFormationTemplate.DataName)
			{
				foreach Restriction.LocationTags(LocTag)
				{
					if (LocTag == m_kFormationTemplate.LocationTags[LocationIndex])
					{
						return true;
					}
				}
			}
		}
	}

	return false;
}

event int GetAnimations(int LocationIndex, out array<AnimationPoses> outAnimations, optional bool bExcludeDuoPoses = false, optional bool bMemorialOnly = false, optional bool bExcludeNonGroupShotPoses = false)
{
	local AnimationPoses AnimPose;
	local int CurrentAnimationIndex;
	local int AddIndex;
	local StateObjectReference Soldier;
	local XComGameState_Unit UnitState;
	local bool bAutoGenerating, bTemplarFilter;
	local array<Photobooth_AnimationFilterType> ClassFilters; // Issue #309, change to array

	if (FullStop()) return -1;

	outAnimations.Length = 0;
	CurrentAnimationIndex = -1;

	if (m_arrUnits[LocationIndex].ActorPawn != none)
	{
		Soldier = m_arrUnits[LocationIndex].UnitRef;
		if (Soldier.ObjectID > 0)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID));
		}

		if (UnitState != none && class'X2PhotoboothHelpers'.static.IsLikeSpark(UnitState.GetMyTemplateName()))
		{
			foreach m_arrAnimationSparkPoses(AnimPose)
			{
				if ((!bMemorialOnly || AnimPose.AnimType == ePAFT_Memorial) // Filter out all non-memorial poses
					&& !RestrictedFromFormation(LocationIndex, AnimPose)
					&& m_arrUnits[LocationIndex].ActorPawn.GetAnimTreeController().CanPlayAnimation(AnimPose.AnimationName))
				{
					AddIndex = outAnimations.AddItem(AnimPose);

					if (AnimPose.AnimationName == m_arrUnits[LocationIndex].AnimationName
						&& AnimPose.AnimationOffset == m_arrUnits[LocationIndex].AnimationOffset)
					{
						CurrentAnimationIndex = AddIndex;
					}
				}
			}
		}
		else
		{
			bAutoGenerating = AutoGenSettings.CampaignID > -1;
			// Issue #309
			bTemplarFilter = class'X2PhotoboothHelpers'.static.IsLikeTemplar(UnitState.GetSoldierClassTemplateName());
			bExcludeDuoPoses = bExcludeDuoPoses || CurrentFormationIsSolo();
			bExcludeNonGroupShotPoses = bExcludeNonGroupShotPoses && GetNumSoldierSlots() > 2;
			
			// Issue #309
			ClassFilters = class'X2PhotoboothHelpers'.static.GetClassFiltersForClass(UnitState.GetSoldierClassTemplateName());

			foreach m_arrAnimationPoses(AnimPose)
			{
				if (AnimPose.AnimType != ePAFT_Captured
					&& (!bAutoGenerating || AnimPose.AnimType != ePAFT_TopGun) // Filter out top gun pose in generated photos
					&& (!bTemplarFilter || (AnimPose.AnimType != ePAFT_SoldierRifle && !AnimPose.bExcludeFromTemplar)) // Filter out rifle poses for Templar in tactical, and new TLE duo poses.
					// Issue #309, cap at ePAFT_END_VANILLA_FILTERS, make soldier class filters work
					&& (AnimPose.AnimType <= ePAFT_DuoPose2 || (AnimPose.AnimType >= ePAFT_Memorial && AnimPose.AnimType < ePAFT_END_VANILLA_FILTERS) || ClassFilters.Find(AnimPose.AnimType) != INDEX_NONE) // Filter out non class matching poses
					&& (!bExcludeDuoPoses || (AnimPose.AnimType != ePAFT_DuoPose1 && AnimPose.AnimType != ePAFT_DuoPose2)) // Filter out Duo Poses
					&& (!bMemorialOnly || AnimPose.AnimType == ePAFT_Memorial) // Filter out all non-memorial poses
					&& !RestrictedFromFormation(LocationIndex, AnimPose) // Always filter out specific poses from specific formation positions.
					&& (!bExcludeNonGroupShotPoses || !AnimPose.bExcludeFromGroupShots) // Filter out marked poses from mob, line and wedge formations. This is different from RestrictedFromFormation above as we don't exclude these poses from the ui drop downs.
					&& m_arrUnits[LocationIndex].ActorPawn.GetAnimTreeController().CanPlayAnimation(AnimPose.AnimationName))
				{
					AddIndex = outAnimations.AddItem(AnimPose);

					if (AnimPose.AnimationName == m_arrUnits[LocationIndex].AnimationName
						&& AnimPose.AnimationOffset == m_arrUnits[LocationIndex].AnimationOffset)
					{
						CurrentAnimationIndex = AddIndex;
					}
				}
			}
		}
	}

	return CurrentAnimationIndex;
}

function bool GetCapturedAnimation(int LocationIndex, out AnimationPoses OutAnimPose)
{
	local int i;
	local array<AnimationPoses> CapturedPoses;

	for (i = 0; i < m_arrAnimationPoses.Length; ++i)
	{
		if (m_arrAnimationPoses[i].AnimType == ePAFT_Captured
			&& m_arrUnits[LocationIndex].ActorPawn != none
			&& m_arrUnits[LocationIndex].ActorPawn.GetAnimTreeController().CanPlayAnimation(m_arrAnimationPoses[i].AnimationName))
		{
			CapturedPoses.AddItem(m_arrAnimationPoses[i]);
		}
	}

	if (CapturedPoses.Length > 0)
	{
		OutAnimPose = CapturedPoses[`SYNC_RAND(CapturedPoses.Length)];
		return true;
	}

	return false;
}

function bool PosterElementsHidden()
{
	if (FullStop()) return false;

	if (m_kPhotoboothEffect != none)
	{
		return !m_kPhotoboothEffect.bShowInGame;
	}

	return false;
}

function int GetBackgrounds(out array<BackgroundPosterOptions> outBackgrounds, Photobooth_TeamUsage BackgroundTeam)
{
	local int outIndex, i;

	if (FullStop()) return -1;

	outIndex = -1;
	outBackgrounds.Length = 0;

	if (m_kPhotoboothEffect != none)
	{
		for (i = 0; i < m_arrBackgroundOptions.Length; ++i)
		{
			if (BackgroundTeam == ePBT_ALL
				|| BackgroundTeam == m_arrBackgroundOptions[i].UsableByTeam)
			{
				if (m_kPhotoboothEffect.BackgroundTexture == none && m_arrBackgroundOptions[i].BackgroundDisplayName == class'UIPhotoboothBase'.default.m_strEmptyOption)
					outIndex = outBackgrounds.Length;
				else if (m_kPhotoboothEffect.BackgroundTexture != none && m_kPhotoboothEffect.BackgroundTexture == m_arrBackgroundOptions[i].BackgroundTexture)
					outIndex = outBackgrounds.Length;

				outBackgrounds.AddItem(m_arrBackgroundOptions[i]);				
			}
		}
	}

	return outIndex;
}

function int GetFirstPassFilters(out array<FilterPosterOptions> outFilters)
{
	local int i;

	if (FullStop()) return -1;

	outFilters = m_arrFirstPassFilterOptions;

	if (m_kPhotoboothEffect != none)
	{
		for (i = 0; i < m_arrFirstPassFilterOptions.Length; ++i)
		{
			if (m_kPhotoboothEffect.FirstPassFilterMI == m_arrFirstPassFilterOptions[i].FilterMI)
				return i;
		}
	}

	return -1;
}

function int GetSecondPassFilters(out array<FilterPosterOptions> outFilters)
{
	local int i;

	if (FullStop()) return -1;

	outFilters = m_arrSecondPassFilterOptions;

	if (m_kPhotoboothEffect != none)
	{
		for (i = 0; i < m_arrSecondPassFilterOptions.Length; ++i)
		{
			if (m_kPhotoboothEffect.SecondPassFilterMI == m_arrSecondPassFilterOptions[i].FilterMI)
				return i;
		}
	}

	return -1;
}

function GetLayouts(out array<X2PropagandaTextLayoutTemplate> outLayouts)
{
	if (FullStop()) return;

	outLayouts = m_aTextLayouts;
}

function GetFonts(out array<FontOptions> outFonts, optional bool bCapturedOnly = false)
{
	local int i;

	if (FullStop()) return;

	outFonts.Remove(0, outFonts.Length);

	for (i = 0; i < m_arrFontOptions.Length; i++)
	{
		if((m_arrFontOptions[i].AllowedInAsianLanguages || (GetLanguage() != "CHN" && GetLanguage() != "CHT" && GetLanguage() != "JPN" && GetLanguage() != "KOR")) &&
			(m_arrFontOptions[i].AllowedInCyrillic || (GetLanguage() != "RUS" && GetLanguage() != "POL")) &&
			(!bCapturedOnly || m_arrFontOptions[i].AllowedForCaptured))
		{
			outFonts.AddItem(m_arrFontOptions[i]);
		}
	}
}

function int GetLayoutIndex()
{
	if (FullStop()) return -1;

	return m_currentTextLayoutTemplateIndex;
}

function int GetNumTextBoxes()
{
	return m_currentTextLayoutTemplate.NumTextBoxes;
}

function string GetTextBoxString(int Index)
{
	local string EmptyString;

	if (FullStop()) return "";

	EmptyString = "";

	if (Index < 0 || Index >= m_PosterStrings.Length)
		return EmptyString;

	return m_PosterStrings[Index];
}

function int GetTextFontIndex(int Index)
{
	local int i;
	local array<FontOptions> fonts;
	GetFonts(fonts);

	for (i = 0; i < fonts.Length; i++)
	{
		if (fonts[i].FontName == m_PosterFont[Index])
			return i;
	}
}

function int GetMaxStringLength(int Index)
{
	if (FullStop()) return 0;

	if (Index < 0 || Index >= m_currentTextLayoutTemplate.MaxChars.Length)
		return 0;

	return m_currentTextLayoutTemplate.MaxChars[Index];
}

function int GetNumIcons()
{
	return m_currentTextLayoutTemplate.NumIcons;
}

function GetCameraPresets(out array<PhotoboothCameraPreset> outCameraPresets, optional bool bExcludeCaptured = true)
{
	local int i;

	if (FullStop()) return;

	for (i = 0; i < m_arrCameraPresets.Length; ++i)
	{
		if ((m_arrCameraPresets[i].AllowableFormations.Length == 0
			|| m_arrCameraPresets[i].AllowableFormations.Find(m_kFormationTemplate.DisplayName) != -1)
			&& (!bExcludeCaptured || m_arrCameraPresets[i].TemplateName != "Captured"))
			outCameraPresets.AddItem(m_arrCameraPresets[i]);
	}
}

native function bool GetCameraPOVForPreset(PhotoboothCameraPreset CameraPreset, out PhotoboothCameraSettings outCameraPOV, optional bool bUpdateViewDistance = true);
native function UpdateViewDistance(out PhotoboothCameraSettings outCameraPOV);

event Box GetExtraBounds(SkeletalMeshComponent SkeletalMC)
{
	local StaticMeshComponent StaticMC;
	local Box BBox;

	BBox.IsValid = 0;

	foreach SkeletalMC.AttachedComponentsOnBone(class'StaticMeshComponent', StaticMC, name("CIN_Root"))
	{
		// should only ever be one.
		BBox.Min = StaticMC.Bounds.Origin - StaticMC.Bounds.BoxExtent;
		BBox.Max = StaticMC.Bounds.Origin + StaticMC.Bounds.BoxExtent;
		BBox.IsValid = 1;
		break;
	}

	return BBox;
}

/******************************************/
//		AutoGen Functions
/******************************************/

function X2PropagandaPhotoTemplate AutoGenSelectFormation(PhotoboothAutoGenSettings Settings)
{
	local int RandInt, i;
	local array<X2PropagandaPhotoTemplate> arrValidFormations;

	if (Settings.FormationTemplate != none)
		return Settings.FormationTemplate;

	for (i = 0; i < m_arrFormations.Length; ++i)
	{
		if (m_arrFormations[i].NumSoldiers >= Settings.PossibleSoldiers.Length)
		{
			arrValidFormations.AddItem(m_arrFormations[i]);
		}
	}

	RandInt = `SYNC_RAND(arrValidFormations.Length);

	return arrValidFormations[RandInt];
}

// Start Issue #309
// There is quite a big drawback in how dual poses are handled. While they *can* be handled like
// normal poses in the standard code paths, it gets hairy when routing through ePBTLS_BondedSoldier.
// On a fundamental level, it assumes that dual poses are always perfectly paired -- there is a "right"
// pose for every "left" pose -- which is fine. However, it implicitly requires that all units
// that go through the ePBTLS_BondedSoldier paths be able to play every single one of the ePBTLS_BondedSoldier
// poses... which works in vanilla because the soldiers available for bonding are all humanoid and share their
// animations. As soon as you add mods to the mix, it gets kind of bad. This is because most of the code chooses
// the pose index first, and then draws poses for each soldier. Thus, we can't do some sort of backtracking to
// find good poses.
// For simplicity, we're making some assumptions here -- specifically, that a unit can either play all of the
// dual animations -- or none! We can lift that in the future if we really want to.
// arrAnimations here is filtered! We only need to handle the paths where no animation could be found.
// End Issue #309
function int GetDuoAnimIndex(int LocationIndex, int DuoAnimIndex, array<AnimationPoses> arrAnimations)
{
	local XComUnitPawn Unit; // Issue #309, use the unit pawn instead
	local int i;
	local array<int> DuoIndices;

	if (FullStop()) return 0;

	Unit = m_arrUnits[LocationIndex].ActorPawn;

	for (i = 0; i < arrAnimations.Length; ++i)
	{
		if (LocationIndex == 0 && arrAnimations[i].AnimType == ePAFT_DuoPose1)
		{
			DuoIndices.AddItem(i);
		}

		if (LocationIndex == 1 && arrAnimations[i].AnimType == ePAFT_DuoPose2)
		{
			DuoIndices.AddItem(i);
		}
	}

	// Issue #309: Check whether the animation can be played
	if (DuoIndices.Length > DuoAnimIndex && Unit.GetAnimTreeController().CanPlayAnimation(arrAnimations[DuoIndices[DuoAnimIndex]].AnimationName))
	{
		return DuoIndices[DuoAnimIndex];
	}

	// Poses are filtered -- just choose a random one.
	return `SYNC_RAND(arrAnimations.Length);
}

function AnimationPoses GetDuoPose(int LocationIndex, int DuoAnimIndex, bool bFirstDuoSoldier)
{
	// Start Issue #309 -- wholesale replacement
	local array<AnimationPoses> arrAnimations;

	GetAnimations(LocationIndex, arrAnimations, , false);

	// Relies on `int(!bFirstDuoSoldier) != LocationIndex`. However, this makes bFirstDuoSoldier obsolete...
	return arrAnimations[GetDuoAnimIndex(LocationIndex, DuoAnimIndex, arrAnimations)];
	// End Issue #309
}

function AutoGenSetSoldiers()
{
	local array<StateObjectReference>	SoldierList, PossibleSoldiers;
	local int RandSoldier, i;

	SoldierList = AutoGenSettings.PossibleSoldiers;

	for (i = 0; i < AutoGenSettings.PossibleSoldiers.Length; ++i)
	{
		GetPossibleSoldiers(i, SoldierList, PossibleSoldiers);

		if (PossibleSoldiers.Length == 0)
			break;

		RandSoldier = `SYNC_RAND(PossibleSoldiers.Length);

		SetSoldier(i, PossibleSoldiers[RandSoldier], AutoGenSettings.TextLayoutState == ePBTLS_HeadShot);
		SoldierList.RemoveItem(PossibleSoldiers[RandSoldier]);
	}
}

function AutoGenSetAnims()
{
	local int RandAnim, i, DuoAnimIndex;
	local array<AnimationPoses> arrAnimations;
	local AnimationPoses AnimPose;
	local bool bAnimPoseFound, bFirstDuoSoldier;

	bFirstDuoSoldier = true;
	if (AutoGenSettings.TextLayoutState == ePBTLS_BondedSoldier)
	{
		DuoAnimIndex = `SYNC_RAND(DuoPose1Indices.length);
	}

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if(m_arrUnits[i].UnitRef.ObjectID == 0) continue;

		bAnimPoseFound = false;
		switch (AutoGenSettings.TextLayoutState)
		{
		case ePBTLS_CapturedSoldier:
			bAnimPoseFound = GetCapturedAnimation(i, AnimPose);
			break;
		case ePBTLS_HeadShot:
			AnimPose.AnimationName = AutoGenSettings.HeadShotAnimName;
			AnimPose.AnimationOffset = 0;

			if (m_arrUnits[i].ActorPawn != none && !m_arrUnits[i].ActorPawn.GetAnimTreeController().CanPlayAnimation(AnimPose.AnimationName))
			{
				//We couldn't play the personality anim specified, try pod idles, which aliens and civilians should have
				AnimPose.AnimationName = 'POD_Idle';
			}
			bAnimPoseFound = true;
			break;
		case ePBTLS_BondedSoldier:
			AnimPose = GetDuoPose(i, DuoAnimIndex, bFirstDuoSoldier);
			bFirstDuoSoldier = false;
			bAnimPoseFound = true;
			break;
		}

		if (bAnimPoseFound)
		{
			SetSoldierAnim(i, AnimPose.AnimationName, AnimPose.AnimationOffset);
		}
		else
		{
			GetAnimations(i, arrAnimations, true, AutoGenSettings.TextLayoutState == ePBTLS_DeadSoldier, true);
			if (arrAnimations.Length > 0)
			{
				RandAnim = `SYNC_RAND(arrAnimations.length);
				SetSoldierAnim(i, arrAnimations[RandAnim].AnimationName, arrAnimations[RandAnim].AnimationOffset);
			}
			else
			{
				SetSoldierAnim(i, 'EmptyAnim', 0);
			}
		}
	}
}

function int GetTotalKills()
{
	local StateObjectReference Soldier;
	local XComGameState_Unit Unit;
	local int TotalKills, i;

	TotalKills = 0;

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		Soldier = m_arrUnits[i].UnitRef;
		if (Soldier.ObjectID > 0)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID));
			TotalKills += Unit.GetNumKills();
		}
	}

	return TotalKills;
}

function int GetTotalMissions()
{
	local StateObjectReference Soldier;
	local XComGameState_Unit Unit;
	local int TotalMissions, i;

	TotalMissions = 0;

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		Soldier = m_arrUnits[i].UnitRef;
		if (Soldier.ObjectID > 0)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID));
			TotalMissions += Unit.GetNumMissions();
		}
	}

	return TotalMissions;
}

function int GetTotalActivePawns()
{
	local int TotalPawns, i;

	if (FullStop()) return 0;

	TotalPawns = 0;

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if (m_arrUnits[i].ActorPawn != none)
		{
			TotalPawns += 1;
		}
	}

	return TotalPawns;
}

function SetAutoTextStrings(Photobooth_AutoTextUsage Usage, optional Photobooth_TextLayoutState textLayoutState = ePBTLS_NONE, optional out PhotoboothDefaultSettings defaultSettings, optional bool bUseDefaultText = false)
{
	local int Roll, LineChanceIndex, i, opLineChance;
	local X2PhotoboothTag LocTag;
	local array<string> GeneratedText;
	local array<FontOptions> arrFontOptions;
	local array<int> GeneratedFont;
	local array<int> GeneratedFontColor;
	local XComGameState_Unit Unit1, Unit2;
	local X2SoldierClassTemplate Template;
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSite;
	local AutoGeneratedLines LinesStruct;
	local bool bAutoGenDeadSoldier, bExcludeNickNames, bCanChooseOperation, bCapturedOnlyFonts;
	local Photobooth_TextLayoutState generatedTextLayoutState;

	if (FullStop()) return;

	Unit1 = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetCurrentSoldier(0).ObjectID));
	Unit2 = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetCurrentSoldier(1).ObjectID));

	LocTag = X2PhotoboothTag(`XEXPANDCONTEXT.FindTag("Photobooth"));

	if (textLayoutState == ePBTLS_NONE)
	{
		generatedTextLayoutState = AutoGenSettings.TextLayoutState;
	}
	else
	{
		generatedTextLayoutState = textLayoutState;
	}

	bAutoGenDeadSoldier = generatedTextLayoutState == ePBTLS_DeadSoldier;
	opLineChance = arrAutoTextChances[Usage].OpLineChance;

	bExcludeNickNames = false;

	switch (Usage)
	{
	case ePBAT_SOLO:
		LinesStruct.ALines = m_arrSoloALines;
		LinesStruct.BLines = bAutoGenDeadSoldier ? m_arrSoloMemorialBLines : m_arrSoloBLines;
		LinesStruct.OpLines = m_arrSoloOpLines;

		if (Unit1 != none)
		{
			LocTag.Kills = Unit1.GetNumKills();
			LocTag.Missions = Unit1.GetNumMissions();
			LocTag.FirstName0 = Unit1.GetFirstName();
			LocTag.LastName0 = Unit1.GetLastName();
			LocTag.Class0 = Unit1.GetSoldierClassTemplate().DisplayName;
			LocTag.NickName0 = Unit1.GetNickName();
			if (LocTag.NickName0 == "''" || LocTag.NickName0 == "")
			{
				for (i = 0; i < LinesStruct.ALines.Length; ++i)
				{
					if (InStr(LinesStruct.ALines[i], "NickName0") >= 0)
					{
						LinesStruct.ALines.Remove(i--, 1);
					}
				}

				for (i = 0; i < LinesStruct.OpLines.Length; ++i)
				{
					if (InStr(LinesStruct.OpLines[i], "NickName0") >= 0)
					{
						LinesStruct.OpLines.Remove(i--, 1);
					}
				}
			}
			else if (!Unit1.IsResistanceHero() && Unit1.GetRank() < 3)
			{
				for (i = 0; i < LinesStruct.ALines.Length; ++i)
				{
					if (InStr(LinesStruct.ALines[i], m_CallsignString) >= 0)
					{
						LinesStruct.ALines.Remove(i--, 1);
					}
				}

				for (i = 0; i < LinesStruct.OpLines.Length; ++i)
				{
					if (InStr(LinesStruct.OpLines[i], m_CallsignString) >= 0)
					{
						LinesStruct.OpLines.Remove(i--, 1);
					}
				}
			}

			if (Unit1.GetNumKills() <= 0)
			{
				opLineChance = 0; // no nickname most likely no kills so this looks bad
			}

			LocTag.RankName0 = Unit1.GetSoldierRankName(); // Issue #408
			//LocTag.Flag = ;

			if (LocTag.RankName0 == LocTag.Class0)
			{
				for (i = 0; i < LinesStruct.ALines.Length; ++i)
				{
					if (InStr(LinesStruct.ALines[i], "RankName0") >= 0 && InStr(LinesStruct.ALines[i], "Class0") >= 0)
					{
						LinesStruct.ALines.Remove(i--, 1);
					}
				}
			}

			Template = Unit1.GetSoldierClassTemplate();
			if (Unit1.kAppearance.iGender == eGender_Male)
			{
				if (bAutoGenDeadSoldier)
				{
					for (i = 0; i < m_arrSoloMemorialBLines_Male.Length; ++i)
					{
						LinesStruct.BLines.AddItem(m_arrSoloMemorialBLines_Male[i]);
					}
				}
				else
				{
					for (i = 0; i < m_arrSoloALines_Male.Length; ++i)
					{
						LinesStruct.ALines.AddItem(m_arrSoloALines_Male[i]);
					}

					for (i = 0; i < m_arrSoloBLines_Male.Length; ++i)
					{
						LinesStruct.BLines.AddItem(m_arrSoloBLines_Male[i]);
					}

					if (Template != none)
					{
						for (i = 0; i < Template.PhotoboothSoloBLines_Male.Length; ++i)
						{
							LinesStruct.BLines.AddItem(Template.PhotoboothSoloBLines_Male[i]);
						}
					}
				}
			}
			else
			{
				if (bAutoGenDeadSoldier)
				{
					for (i = 0; i < m_arrSoloMemorialBLines_Female.Length; ++i)
					{
						LinesStruct.BLines.AddItem(m_arrSoloMemorialBLines_Female[i]);
					}
				}
				else
				{
					for (i = 0; i < m_arrSoloALines_Female.Length; ++i)
					{
						LinesStruct.ALines.AddItem(m_arrSoloALines_Female[i]);
					}

					for (i = 0; i < m_arrSoloBLines_Female.Length; ++i)
					{
						LinesStruct.BLines.AddItem(m_arrSoloBLines_Female[i]);
					}

					if (Template != none)
					{
						for (i = 0; i < Template.PhotoboothSoloBLines_Female.Length; ++i)
						{
							LinesStruct.BLines.AddItem(Template.PhotoboothSoloBLines_Female[i]);
						}
					}
				}
			}
		}
		break;
	case ePBAT_DUO:
		LinesStruct.ALines = m_arrDuoALines;
		LinesStruct.BLines = m_arrDuoBLines;
		LinesStruct.OpLines = m_arrDuoOpLines;

		if (Unit1 != none && Unit2 != none)
		{
			LocTag.Kills = Unit1.GetNumKills() + Unit2.GetNumKills();
			LocTag.Missions = Unit1.GetNumMissions() + Unit2.GetNumMissions();;
			LocTag.FirstName0 = Unit1.GetFirstName();
			LocTag.FirstName1 = Unit2.GetFirstName();
			LocTag.LastName0 = Unit1.GetLastName();
			LocTag.LastName1 = Unit2.GetLastName();
			LocTag.Class0 = Unit1.GetSoldierClassTemplate().DisplayName;
			LocTag.Class1 = Unit2.GetSoldierClassTemplate().DisplayName;
			LocTag.NickName0 = Unit1.GetNickName();
			if (LocTag.NickName0 == "''" || LocTag.NickName0 == "")
			{
				bExcludeNickNames = true;
			}

			LocTag.NickName1 = Unit2.GetNickName();
			if (LocTag.NickName1 == "''" || LocTag.NickName1 == "") //bsg-jneal (5.15.17): added missing second empty string check
			{
				bExcludeNickNames = true;
			}

			if (bExcludeNickNames)
			{
				for (i = 0; i < LinesStruct.ALines.Length; ++i)
				{
					if (InStr(LinesStruct.ALines[i], "NickName0") >= 0)
					{
						LinesStruct.ALines.Remove(i--, 1);
					}
				}
			}

			// Start Issue #408
			LocTag.RankName0 = Unit1.GetSoldierRankName();
			LocTag.RankName1 = Unit2.GetSoldierRankName();
			// End Issue #408
			//LocTag.Flag = ;

			if (Unit1.kAppearance.iGender == Unit2.kAppearance.iGender)
			{
				if (Unit1.kAppearance.iGender == eGender_Male)
				{
					for (i = 0; i < m_arrDuoALines_Male.Length; ++i)
					{
						LinesStruct.ALines.AddItem(m_arrDuoALines_Male[i]);
					}
					for (i = 0; i < m_arrDuoBLines_Male.Length; ++i)
					{
						LinesStruct.BLines.AddItem(m_arrDuoBLines_Male[i]);
					}
				}
				else
				{
					for (i = 0; i < m_arrDuoALines_Female.Length; ++i)
					{
						LinesStruct.ALines.AddItem(m_arrDuoALines_Female[i]);
					}
					for (i = 0; i < m_arrDuoBLines_Female.Length; ++i)
					{
						LinesStruct.BLines.AddItem(m_arrDuoBLines_Female[i]);
					}
				}
			}
		}
		break;
	case ePBAT_SQUAD:
		LocTag.Kills = GetTotalKills();
		LocTag.Missions = GetTotalMissions();
		//LocTag.Flag = ;

		bCanChooseOperation = false;
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
		if (BattleData != none)
		{
			LocTag.Date = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime);
			LocTag.Operation = BattleData.m_strOpName != "" ? BattleData.m_strOpName : "Operation Hidden Blight";
			bCanChooseOperation = true;
		}
		else if (`GAME.GetGeoscape() != none)
		{
			LocTag.Date = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`GAME.GetGeoscape().m_kDateTime);
		}

		MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_MissionSite', true));
		if (MissionSite != none)
		{
			LocTag.Location = MissionSite.GetWorldRegion().GetMyTemplate().DisplayName;
		}

		LinesStruct.ALines = m_arrSquadALines;
		LinesStruct.BLines = m_arrSquadBLines;
		LinesStruct.OpLines = m_arrSquadOpLines;

		if (!bCanChooseOperation)
		{
			for (i = 0; i < LinesStruct.ALines.Length; ++i)
			{
				if (InStr(LinesStruct.ALines[i], "Operation") >= 0)
				{
					LinesStruct.ALines.Remove(i--, 1);
				}
			}

			for (i = 0; i < LinesStruct.BLines.Length; ++i)
			{
				if (InStr(LinesStruct.BLines[i], "Operation") >= 0)
				{
					LinesStruct.BLines.Remove(i--, 1);
				}
			}

			for (i = 0; i < LinesStruct.OpLines.Length; ++i)
			{
				if (InStr(LinesStruct.OpLines[i], "Operation") >= 0)
				{
					LinesStruct.OpLines.Remove(i--, 1);
				}
			}
		}

		if (LocTag.Location == "")
		{
			for (i = 0; i < LinesStruct.ALines.Length; ++i)
			{
				if (InStr(LinesStruct.ALines[i], "Location") >= 0)
				{
					LinesStruct.ALines.Remove(i--, 1);
				}
			}

			for (i = 0; i < LinesStruct.BLines.Length; ++i)
			{
				if (InStr(LinesStruct.BLines[i], "Location") >= 0)
				{
					LinesStruct.BLines.Remove(i--, 1);
				}
			}

			for (i = 0; i < LinesStruct.OpLines.Length; ++i)
			{
				if (InStr(LinesStruct.OpLines[i], "Location") >= 0)
				{
					LinesStruct.OpLines.Remove(i--, 1);
				}
			}
		}
		break;
	}

	LineChanceIndex = 0;
	if (bAutoGenDeadSoldier)
	{
		// Always use B line layout for dead soldiers
		LineChanceIndex = 1;
	}
	else
	{
		Roll = `SYNC_RAND(100) - arrAutoTextChances[Usage].LineChances[LineChanceIndex];
		while (Roll >= 0)
		{
			Roll -= arrAutoTextChances[Usage].LineChances[++LineChanceIndex];
		}
	}

	bCapturedOnlyFonts = false;
	if (generatedTextLayoutState == ePBTLS_CapturedSoldier)
	{
		GeneratedText.AddItem(`XEXPAND.ExpandString(m_arrCapturedLines[`SYNC_RAND(m_arrCapturedLines.Length)]));
		GeneratedText.AddItem(m_CapturedString);
		bCapturedOnlyFonts = true;
	}
	else if (!bAutoGenDeadSoldier && `SYNC_RAND(100) < opLineChance)
	{
		SetTextLayoutByType(eTLT_TripleLine);
		switch (LineChanceIndex)
		{
		case 0:
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.ALines[`SYNC_RAND(LinesStruct.ALines.Length)]));
			GeneratedText.AddItem("");
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.OpLines[`SYNC_RAND(LinesStruct.OpLines.Length)]));
			break;
		case 1:
			GeneratedText.AddItem("");
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.BLines[`SYNC_RAND(LinesStruct.BLines.Length)]));
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.OpLines[`SYNC_RAND(LinesStruct.OpLines.Length)]));
			break;
		case 2:
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.ALines[`SYNC_RAND(LinesStruct.ALines.Length)]));
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.BLines[`SYNC_RAND(LinesStruct.BLines.Length)]));
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.OpLines[`SYNC_RAND(LinesStruct.OpLines.Length)]));
			break;
		}
	}
	else
	{
		switch (LineChanceIndex)
		{
		case 0:
			SetTextLayoutByType(eTLT_SingleLine);
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.ALines[`SYNC_RAND(LinesStruct.ALines.Length)]));
			break;
		case 1:
			SetTextLayoutByType(eTLT_SingleLine);
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.BLines[`SYNC_RAND(LinesStruct.BLines.Length)]));
			break;
		case 2:
			SetTextLayoutByType(eTLT_DoubleLine);
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.ALines[`SYNC_RAND(LinesStruct.ALines.Length)]));
			GeneratedText.AddItem(`XEXPAND.ExpandString(LinesStruct.BLines[`SYNC_RAND(LinesStruct.BLines.Length)]));
			break;
		}
	}

	GetFonts(arrFontOptions, bCapturedOnlyFonts);
	if (defaultSettings.GeneratedText.length > 0 && bUseDefaultText)
	{
		GeneratedText = defaultSettings.GeneratedText;
		GeneratedFont = defaultSettings.FontNum;
		GeneratedFontColor = defaultSettings.FontColor;
		SetLayoutIndex(defaultSettings.TextLayoutNum);
	}
	else
	{
		for (i = 0; i < GeneratedText.Length; i++)
		{
			GeneratedFont.AddItem(`SYNC_RAND(arrFontOptions.Length));
			GeneratedFontColor.AddItem(`SYNC_RAND(m_RandomColors));
		}

		if (generatedTextLayoutState == ePBTLS_PromotedSoldier )
		{
			SetTextLayoutByType(eTLT_Promotion);
			GeneratedText[2] = m_PromotedString;
			GeneratedFont[2] = 0;
			GeneratedFontColor[2] = 2; // silver/grey index
		}

		defaultSettings.TextLayoutNum = m_currentTextLayoutTemplateIndex;
	}

	for (i = 0; i < m_PosterStrings.Length; ++i)
	{
		if (i < GeneratedText.Length)
		{
			SetTextBoxString(i, GeneratedText[i]);
			SetTextBoxFont(i, arrFontOptions[GeneratedFont[i]].FontName);
			SetTextBoxColor(i, GeneratedFontColor[i]);
		}
		else
		{
			SetTextBoxString(i, "");
		}
	}

	if (defaultSettings.GeneratedText.length == 0)
	{
		defaultSettings.GeneratedText = GeneratedText;
		defaultSettings.FontNum = GeneratedFont;
		defaultSettings.FontColor = GeneratedFontColor;
	}
}

function FillDefaultText(out PhotoboothDefaultSettings defaultSettings)
{
	local int i;

	if (FullStop()) return;

	for (i = 0; i < GetNumTextBoxes(); i++)
	{
		defaultSettings.GeneratedText.AddItem(GetTextBoxString(i));
		defaultSettings.FontNum.AddItem(GetTextFontIndex(i));
		defaultSettings.FontColor.AddItem(m_PosterStringColors[i]);
	}
	
}

function AutoGenTextLayout()
{
	if (FullStop()) return;

	if (m_kFormationTemplate.NumSoldiers == 1)
	{
		SetAutoTextStrings(ePBAT_SOLO);
	}
	else if (m_kFormationTemplate.NumSoldiers == 2)
	{
		SetAutoTextStrings(ePBAT_DUO);
	}
	else
	{
		SetAutoTextStrings(ePBAT_SQUAD);
	}
}

function AutoGenChallengeModeTextLayout()
{
	local XComChallengeModeManager ChallengeModeManager;
	local array<string> GeneratedText;
	local int i;
	local array<FontOptions> arrFontOptions;
	local XComGameState_LadderProgress LadderData;

	if (AutoGenSettings.bChallengeMode)
	{
		ChallengeModeManager = XComEngine(Class'GameEngine'.static.GetEngine()).ChallengeModeManager;

		GeneratedText.AddItem(m_ChallengeModeStr);
		GeneratedText.AddItem(m_ChallengeModeScoreLabel @ string(ChallengeModeManager.GetTotalScore()));
	}
	else if (AutoGenSettings.bLadderMode)
	{
		LadderData = XComGameState_LadderProgress( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress' ) );

		GeneratedText.AddItem(m_ChallengeModeScoreLabel @ string(LadderData.CumulativeScore));
		if (LadderData.LadderIndex < 10)
		{
			GeneratedText.AddItem(LadderData.NarrativeLadderNames[LadderData.LadderIndex]);//Mission Name
		}
		else
		{
			GeneratedText.AddItem(LadderData.LadderName);//Mission Name
		}
	}

	SetTextLayoutByNumOfTextBoxes(2);

	GetFonts(arrFontOptions);

	for (i = 0; i < m_PosterStrings.Length; ++i)
	{
		if (i < GeneratedText.Length)
		{
			SetTextBoxString(i, GeneratedText[i]);
			SetTextBoxFont(i, arrFontOptions[`SYNC_RAND(arrFontOptions.Length)].FontName);
			SetTextBoxColor(i, `SYNC_RAND(m_RandomColors));
		}
		else
		{
			SetTextBoxString(i, "");
		}
	}
}

event InterruptAutoGen()
{
	if (FullStop()) return;

	m_kFinalPosterComponent.SetEnabled(false);
	m_kPreviewPosterComponent.SetEnabled(true);
	AutoGenSettings.CampaignID = -1;
	m_kOnPosterCreated = none;
	RemoveAllSoldierPawns();

	if (m_backgroundPoster != none)
	{
		`PRESBASE.GetPhotoboothMovie().RemoveScreen(m_backgroundPoster);
	}

	ResizeFinalRenderTarget(false);
	HidePosterElements(false);

	m_kFinalPosterComponent.bUseMainScenePostProcessSettings = true;

	m_kAutoGenCaptureState = eAGCS_Idle;

	UserTextLayoutState = ePBTLS_NONE;
}

function bool CanTakeAutoPhoto(bool bValidAutoGenSettings)
{
	if (FullStop()) return false;

	return `ScreenStack.IsNotInStack(class'UIArmory_Photobooth', false) &&
		m_kAutoGenCaptureState == eAGCS_Idle &&
		(bValidAutoGenSettings ? AutoGenSettings.CampaignID > -1 : AutoGenSettings.CampaignID <= -1);
}

function SetAutoGenSettings(PhotoboothAutoGenSettings InSettings, optional delegate<OnPosterCreated> inOnPosterCreated)
{
	if (FullStop()) return;

	AutoGenSettings = InSettings;
	m_kOnPosterCreated = inOnPosterCreated;
}

function HidePreview()
{
	if (FullStop()) return;

	m_kPreviewPosterComponent.SetEnabled(false);
	if (m_kPhotoboothShowEffect != none)
	{
		m_kPhotoboothShowEffect.bShowInGame = false;
	}
}

function bool DeferPhase1()
{
	if (FullStop()) return true;

	return m_kFormationBlueprint == none || m_bFormationNeedsUpdate || m_bFormationLoading;
}

function bool DeferPhase2()
{
	local int i, FormationSoldierCount;

	if (FullStop()) return true;

	FormationSoldierCount = 0;
	if (m_kFormationTemplate != none)
	{
		FormationSoldierCount = m_kFormationTemplate.NumSoldiers;
	}

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if (i < FormationSoldierCount && m_arrUnits[i].UnitRef.ObjectID != 0 && m_arrUnits[i].ActorPawn == none)
		{
			return true;
		}
	}

	return false;
}

function bool DeferPhase3()
{
	local int i;

	if (FullStop()) return true;

	if (!m_backgroundPoster.bIsInited)
	{
		return true;
	}

	for (i = 0; i < m_arrUnits.Length; ++i)
	{
		if (m_arrUnits[i].FramesToHide > 0)
		{
			return true;
		}
	}

	return false;
}

function int AutoGenGetFrameDelay()
{
	local int FrameDelay;
	local XComGameState_Unit Unit;

	FrameDelay = 5;

	// Special case for Top Braid hair style as it tends to act like a spring before settling down.
	// May want to do this for non-headshots but those are less offensive as you can see more than just the head.
	if (AutoGenSettings.TextLayoutState == ePBTLS_HeadShot) 
	{
		if (m_arrUnits[0].UnitRef.ObjectID > 0)			
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrUnits[0].UnitRef.ObjectID));
			if (Unit != none)
			{
				if (Unit.kAppearance.nmHaircut == name("DLC_30_Hair_D_TopBraid_M") || Unit.kAppearance.nmHaircut == name("DLC_30_Hair_D_TopBraid_F"))
				{
					FrameDelay = 60;
				}
				else if (Unit.kAppearance.nmHaircut == name("DLC_30_Hair_F_Pigtails_F") || Unit.kAppearance.nmHaircut == name("DLC_30_Hair_F_Pigtails2_F") ||
						 Unit.kAppearance.nmHaircut == name("DLC_30_Hair_F_Pigtails_M") || Unit.kAppearance.nmHaircut == name("DLC_30_Hair_F_Pigtails2_M"))
				{
					FrameDelay = 10;
				}
			}
		}
			
	}

	return FrameDelay;
}

event AutoGenerate()
{
	local array<PhotoboothCameraPreset> arrCameraPresets;
	local PhotoboothCameraPreset CameraPreset;
	local PhotoboothCameraSettings CameraSettings;
	local int i, CameraIndex;

	if (CanTakeAutoPhoto(true))
	{
		m_kFinalPosterComponent.bUseMainScenePostProcessSettings = false;

		// Need to call this in case we are re-entering after being interrupted.
		HidePreview();

		SetGameIndex(AutoGenSettings.CampaignID);

		MoveFormation(AutoGenSettings.FormationLocation);
		ChangeFormation(AutoGenSelectFormation(AutoGenSettings));

		ResizeFinalRenderTarget(AutoGenSettings.TextLayoutState == ePBTLS_HeadShot);

		SetFirstPassFilter(0);
		SetSecondPassFilter(0);

		m_kAutoGenCaptureState = eAGCS_TickPhase1;
	}

	if (m_kAutoGenCaptureState == eAGCS_TickPhase1)
	{
		if (DeferPhase1()) return;

		switch (AutoGenSettings.TextLayoutState)
		{
		case ePBTLS_PromotedSoldier:
			SetTextLayoutByType(eTLT_Promotion);
			break;
		case ePBTLS_CapturedSoldier:
			SetTextLayoutByType(eTLT_Captured);
			SetBackgroundColorOverride(true);
			SetGradientColor1(CapturedTintColor1);
			SetGradientColor2(CapturedTintColor2);
			break;
		case ePBTLS_HeadShot:
			HidePosterTexture();
			break;
		}

		AutoGenSetSoldiers();

		if (AutoGenSettings.TextLayoutState != ePBTLS_HeadShot)
		{
			if (AutoGenSettings.bChallengeMode || AutoGenSettings.bLadderMode)
			{
				AutoGenChallengeModeTextLayout();
			}
			else
			{
				AutoGenTextLayout();
			}
		}

		SetBackgroundTexture(AutoGenSettings.BackgroundDisplayName);

		if (AutoGenSettings.TextLayoutState == ePBTLS_HeadShot && AutoGenSettings.bLadderMode)
		{
			m_kFinalPosterComponent.RenderChannels.MainScene = false;
			m_kFinalPosterComponent.bEnableFog = false;
		}

		m_kAutoGenCaptureState = eAGCS_TickPhase2;
	}

	if (m_kAutoGenCaptureState == eAGCS_TickPhase2)
	{
		if (DeferPhase2()) return;
		
		AutoGenSetAnims();

		m_kAutoGenCaptureState = eAGCS_TickPhase3;
	}

	if(m_kAutoGenCaptureState == eAGCS_TickPhase3)
	{
		if (DeferPhase3()) return;

		SetCameraPOV(AutoGenSettings.CameraPOV, true); // Need to setup Capture's FOV so that camera position can be properly determined
		GetCameraPresets(arrCameraPresets, AutoGenSettings.CameraPresetDisplayName != "Captured");

		if (AutoGenSettings.TextLayoutState == ePBTLS_HeadShot)
		{
			CameraPreset.FocusBoneOrSocket = name("CIN_Target");
			CameraPreset.FrameSetting = ePFS_Head;
		}
		else
		{
			CameraIndex = 0;
			if (AutoGenSettings.CameraPresetDisplayName != "")
			{
				for (i = 0; i < arrCameraPresets.Length; ++i)
				{
					if (arrCameraPresets[i].TemplateName == AutoGenSettings.CameraPresetDisplayName)
					{
						CameraIndex = i;
						break;
					}
				}
			}
			else
			{
				CameraIndex = `SYNC_RAND(arrCameraPresets.Length);
			}

			CameraPreset = arrCameraPresets[CameraIndex];
		}

		if (GetCameraPOVForPreset(CameraPreset, CameraSettings))
		{
			AutoGenSettings.CameraPOV.Rotation = CameraSettings.Rotation;

			if (AutoGenSettings.TextLayoutState == ePBTLS_HeadShot)
			{
				CameraSettings.ViewDistance = AutoGenSettings.CameraDistance;
			}

			AutoGenSettings.CameraPOV.Location = CameraSettings.RotationPoint - CameraSettings.ViewDistance * vector(CameraSettings.Rotation);

			if (!(AutoGenSettings.TextLayoutState == ePBTLS_HeadShot && AutoGenSettings.bLadderMode)
				&& XComTacticalController(GetALocalPlayerController()) != none)
			{
				FixedTacticalAutoGenCamera = new class'X2Camera_Fixed';
				FixedTacticalAutoGenCamera.SetCameraView(AutoGenSettings.CameraPOV);
				FixedTacticalAutoGenCamera.Priority = eCameraPriority_Cinematic;
				`CAMERASTACK.AddCamera(FixedTacticalAutoGenCamera);
			}

			SetCameraPOV(AutoGenSettings.CameraPOV, true);

			m_kFinalPosterComponent.m_nRenders = 2;
			CreatePoster(AutoGenGetFrameDelay(), m_kOnPosterCreated);

			m_kAutoGenCaptureState = eAGCS_Capturing;
		}
	}
}

defaultproperties
{
	Begin Object Class=SceneCapture2DComponent Name=SceneCapture2DComponent0
		bSkipUpdateIfOwnerOccluded = false
		MaxUpdateDist = 0.0
		MaxStreamingUpdateDist = 0.0
		bUpdateMatrices = false
		bEnabled = false
		RenderChannels = (MainScene = true,SecondaryScene = true)
		FrameRate = 0
		NearPlane = 10
		FarPlane = 0
		ViewMode = SceneCapView_Lit
		bEnableAmbient = true
		bEnableSSReflections = true
		bEnablePostProcess = true
		bEnableSSAO = true
		bEnableAlphaMask = true
		bEnableFog = true
		bIsHeadCapture = true
		bIsPhotoboothPreview = true
		ClearColor = (R = 0,G = 0,B = 0,A = 0)
		bUseMainScenePostProcessSettings = true
	End Object
	m_kPreviewPosterComponent=SceneCapture2DComponent0
	Components.Add(SceneCapture2DComponent0)

	Begin Object Class=SceneCapture2DComponent Name=SceneCapture2DComponent1
		bSkipUpdateIfOwnerOccluded = false
		MaxUpdateDist = 0.0
		MaxStreamingUpdateDist = 0.0
		bUpdateMatrices = false
		bEnabled = false
		RenderChannels = (MainScene = true,SecondaryScene = true)
		FrameRate = 0
		m_nRenders = 1
		NearPlane = 10
		FarPlane = 0
		ViewMode = SceneCapView_Lit
		bEnableAmbient = true
		bEnableSSReflections = true
		bEnablePostProcess = true
		bEnableSSAO = true
		bEnableAlphaMask = true
		bEnableFog = true
		bIsHeadCapture = true
		ClearColor = (R = 0,G = 0,B = 0,A = 0)
		bUseMainScenePostProcessSettings = true
	End Object
	m_kFinalPosterComponent=SceneCapture2DComponent1
	Components.Add(SceneCapture2DComponent1)

	//If you change these numbers mirror the change in XComPresentationLayerBase
	m_iPosterSizeX = 800;
	m_iPosterSizeY = 1200;

	m_bFormationNeedsUpdate=false
	m_bFormationLoading=false
	m_iGameIndex=-1

	m_kAutoGenCaptureState=eAGCS_Idle

	TemplarShardBladeFX_L=ParticleSystem'FX_Templar_Shard.P_Shard_Blade_Looping_L'
	TemplarShardBladeFX_R=ParticleSystem'FX_Templar_Shard.P_Shard_Blade_Looping_R'

	m_fMaxXPercentage = 0.37
	m_fMaxYPercentage = 1.0

	bFullStop = false
}

class X2Action_RevealAIBegin extends X2Action_PlayMatinee
	config(Camera);

// How long to pause after kicking off the first sighted NM before continuing with the reveal
var const config float FirstSightedDelay;

var XComGameStateContext_RevealAI RevealContext;
var float RevealFOWRadius;  //A radius in units for how much FOW should be revealed

var private XGUnit MatineeFocusUnitVisualizer;              //Visualizer of the target of the cinematic
var private XComGameState_Unit MatineeFocusUnitState;

var private X2CharacterTemplate MatineeFocusUnitTemplate;	//Character template of the character being revealed
var private XGUnit EnemyUnitVisualizer;                     //The enemy that caused this reveal to happen
var private AnimNodeSequence PointAnim;
var private array<XComUnitPawn> RevealedUnitVisualizers;
var private XComUnitPawn FocusUnitPawn;
var private int FocusUnitIndex;
var private X2Camera_MidpointTimed InitialLookAtCam;

var localized string SurprisedText;

var bool bOnlyFrameAI;

var private float PrePauseGameSpeed;

var private bool bReceivedUIChosenReveal_OnRemoved;
var private bool bAnyEvaluatingStance;
var private bool bCachedCanPlayTheLostCamera;
var private bool bHasCachedCanPlayTheLostCamera;

var XComGameStateHistory History;
var XComGameState_Unit TempUnitState;

function Init()
{	
	
	local X2CharacterTemplate FirstRevealTemplate;
	local XGUnit UnitActor;
	local int Index;
	local X2EventManager EventManager;
	local Object ThisObj;

	super.Init();
	
	RevealContext = XComGameStateContext_RevealAI(StateChangeContext);	

	History = `XCOMHISTORY;

	FirstRevealTemplate = RevealContext.FirstEncounterCharacterTemplate;

	//First make sure that there are units to be revealed
	if(RevealContext.RevealedUnitObjectIDs.Length > 0)
	{		
		for(Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index)
		{
			TempUnitState = XComGameState_Unit(History.GetGameStateForObjectID(RevealContext.RevealedUnitObjectIDs[Index], eReturnType_Reference, RevealContext.AssociatedState.HistoryIndex));
			if( TempUnitState.IsAbleToAct() ) //Only focus on still living enemies
			{
				UnitActor = XGUnit(History.GetVisualizer(TempUnitState.ObjectID));
				if(MatineeFocusUnitVisualizer == none 
					|| (FirstRevealTemplate != none && FirstRevealTemplate.DataName != MatineeFocusUnitVisualizer.GetVisualizedGameState().GetMyTemplateName()))
				{
					// If this is a first encounter, then favor playing the reveal on a unit of that template type. Otherwise 
					// take the first one available. Since the pod leader is always at index 0, this will focus him if possible.
					MatineeFocusUnitVisualizer = UnitActor;		
					MatineeFocusUnitState = TempUnitState;
				}

				RevealedUnitVisualizers.AddItem(UnitActor.GetPawn());
			}
		}

		//We can still end up with an empty RevealedUnitVisualizers if the player killed this entire group with AOE or something before the reveal could take place, so account for that 
		WorldInfo.RemoteEventListeners.AddItem(self);

		EventManager = `XEVENTMGR;
		ThisObj = self;

		EventManager.RegisterForEvent(ThisObj, 'UIChosenReveal_OnRemoved', OnChosenRevealUI_Removed, ELD_Immediate);
	}
	else
	{
		`redscreen("Attempted to plan AI reveal action with no AIs!");
	}
	
	EnemyUnitVisualizer = XGUnit(History.GetVisualizer(RevealContext.CausedRevealUnit_ObjectID));
	if (EnemyUnitVisualizer == None)
	{
		// Revealing unit may be dead?  Select any xcom unit?
		EnemyUnitVisualizer = XGBattle_SP(`BATTLE).GetAIPlayer().GetNearestEnemy(UnitActor.GetLocation());
	}
}

function bool CheckInterrupted()
{
	return false;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	`assert(false);
}

function ResetTimeDilation()
{
	local int Index;
	for (Index = 0; Index < RevealedUnitVisualizers.Length; Index++)
	{
		VisualizationMgr.SetInterruptionSloMoFactor(RevealedUnitVisualizers[Index].GetGameUnit(), 1.0f);
	}
}

function vector GetLookatLocation()
{
	return MatineeFocusUnitVisualizer.GetPawn().GetFeetLocation();
}	

function ShowSurprisedFlyover()
{
	local XGUnitNativeBase Scamperer;
	local XComGameState_Unit ScampererUnitState;
	local int SurprisedUnitID;

	History = `XCOMHISTORY;

	foreach RevealContext.SurprisedScamperUnitIDs(SurprisedUnitID)
	{
		Scamperer = XGUnitNativeBase(History.GetVisualizer(SurprisedUnitID));

		//The surprised unit may have been killed already in blocks visualized earlier.
		ScampererUnitState = XComGameState_Unit(History.GetGameStateForObjectID(SurprisedUnitID, eReturnType_Reference, CurrentHistoryIndex));
		if (ScampererUnitState != None && Scamperer != None && ScampererUnitState.IsAlive() && !ScampererUnitState.IsIncapacitated())
			`PRES.QueueWorldMessage(SurprisedText, Scamperer.GetLocation(), Scamperer.GetVisualizedStateReference(), eColor_Alien, , , Scamperer.m_eTeamVisibilityFlags, , , , , , , , , , , , , true);
	}
}

function bool IsTimedOut()
{
	if (IsMatineePaused())
	{
		return false;
	}

	return super.IsTimedOut();
}

//Override to receive notifications when remote events are fired
// For Future: If we need more of these special UI screens during a reveal
// we will probably want character templates or an X2Effect to decide what
// reveal action should play
event OnRemoteEvent(name RemoteEventName)
{
	super.OnRemoteEvent(RemoteEventName);
	
	// Listen for a possible matinee pause. If it does, show the Chosen UI (Or ask Currie to specifically name the event after the chosen)
	if( RemoteEventName == 'CIN_ChosenRevealUIStart' )
	{
		// Show the Chosen UI
		`PRES.UIChosenRevealScreen();
	}
	else if( (RemoteEventName == 'CIN_ChosenRevealUI') && !bReceivedUIChosenReveal_OnRemoved)
	{
		// Pause
		PauseMatinee();

		XComTacticalController(WorldInfo.GetALocalPlayerController()).SetPause(true);
	}
	else if( RemoteEventName == 'CIN_ChosenRevealDialogueA' )
	{
		`XEVENTMGR.TriggerEvent('Visualizer_ChosenReveal_LipSyncA', self, self);
	}
	else if( RemoteEventName == 'CIN_ChosenRevealDialogueB' )
	{
		`XEVENTMGR.TriggerEvent('Visualizer_ChosenReveal_LipSyncB', self, self);
	}
}

function EventListenerReturn OnChosenRevealUI_Removed(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2MatineeInfo MatineeInfo;

	XComTacticalController(WorldInfo.GetALocalPlayerController()).SetPause(false);

	// Unpause the matinees
	ResumeMatinee();

	MatineeInfo = new class'X2MatineeInfo';
	MatineeInfo.InitFromMatinee(Matinees[0]);
	TimeoutSeconds = ExecutingTime + default.TimeoutSeconds + MatineeInfo.GetMatineeDuration();

	bReceivedUIChosenReveal_OnRemoved = true;

	return ELR_NoInterrupt;
}

function bool IsMatineePaused()
{
	local int i;

	for( i = 0; i < Matinees.Length; ++i )
	{
		if( Matinees[i].bPaused )
		{
			return true;
		}
	}

	return false;
}

function XComGameState_AIGroup GetRevealedGroup()
{
	local XComGameStateContext_RevealAI AIRevealContext;

	History = `XCOMHISTORY;
		AIRevealContext = XComGameStateContext_RevealAI(StateChangeContext);
	if( AIRevealContext.RevealedUnitObjectIDs.Length > 0 )
	{
		TempUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIRevealContext.RevealedUnitObjectIDs[0], eReturnType_Reference, AIRevealContext.AssociatedState.HistoryIndex));

		if( TempUnitState != none )
		{
			return TempUnitState.GetGroupMembership(, AIRevealContext.AssociatedState.HistoryIndex);
		}
	}

	return none;
}

function bool WantsToPlayTheLostCamera()
{
	local XComGameState_AIGroup RevealedGroup;

	if( class'X2Camera_TheLostReveal'.default.EnableLostRevealCam
	   && bOnlyFrameAI )
	{
		RevealedGroup = GetRevealedGroup();
		if( RevealedGroup != none && RevealedGroup.TeamName == eTeam_TheLost )
		{
			return true;
		}
	}

	return false;
}

function bool CanPlayTheLostCamera()
{
	local XComGameState_AIGroup RevealedAIGroup;
	local XComUnitPawnNativeBase ViewingXComPawn; // placeholder for now - consider caching and passing
	local XComUnitPawnNativeBase LostUnitToFollow;
	local vector LostScamperEndPoint, ToLost;

	if( !bHasCachedCanPlayTheLostCamera )
	{
		bHasCachedCanPlayTheLostCamera = true;
		bCachedCanPlayTheLostCamera = false;

		RevealedAIGroup = GetRevealedGroup();

		if( class'X2Camera_TheLostReveal'.static.DetermineViewingUnits(RevealedAIGroup, ViewingXComPawn, LostUnitToFollow, LostScamperEndPoint) )
		{
			if( ViewingXComPawn != none )
			{
				// if the viewing location would be within a tile of the viewing XCom unit, then the Lost camera is not a good frame for the reveal
				ToLost = LostScamperEndPoint - ViewingXComPawn.GetHeadLocation();
				if( (VSize(ToLost) - class'XComWorldData'.const.WORLD_StepSize) > (class'XComWorldData'.const.WORLD_StepSize * class'X2Camera_TheLostReveal'.default.LostRevealCamViewDistance) )
				{
					bCachedCanPlayTheLostCamera = true;
				}
			}
		}
	}

	return bCachedCanPlayTheLostCamera;
}

simulated state Executing
{
	function UpdateUnitVisuals()
	{	
		local int Index;
		local XGUnit Visualizer;
		local EForceVisibilitySetting ForceVisSetting;

		//Iterate all the unit states that are part of the reflex action state. If they are not the
		//reflexing unit, they are enemy units that must be shown to the player. These vis states will
		//be cleaned up / reset by the visibility observer in subsequent frames
		for( Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index )
		{
			Visualizer = XGUnit(`XCOMHISTORY.GetVisualizer(RevealContext.RevealedUnitObjectIDs[Index]));

			if( Visualizer != none )
			{
				if( !MatineeFocusUnitState.GetMyTemplate().bDisableRevealForceVisible )
				{
					ForceVisSetting = eForceVisible;
				}
				else
				{
					ForceVisSetting = eForceNotVisible;
				}
				Visualizer.m_bForceHidden = false;
				Visualizer.SetForceVisibility(ForceVisSetting);
				Visualizer.GetPawn().UpdatePawnVisibility();
			}
		}
	}

	function RequestInitialLookAtCamera()
	{			
		local XComUnitPawn FocusActor;
		
		InitialLookAtCam = new class'X2Camera_MidpointTimed';
		foreach RevealedUnitVisualizers(FocusActor)
		{
			InitialLookAtCam.AddFocusActor(FocusActor);
		}
		InitialLookAtCam.Priority = eCameraPriority_CharacterMovementAndFraming;
		InitialLookAtCam.LookAtDuration = 100.0f; // we'll manually pop it
		InitialLookAtCam.UpdateWhenInactive = true;
		`CAMERASTACK.AddCamera(InitialLookAtCam);
	}

	function RequestLookAtCamera()
	{	
		local X2Camera_MidpointTimed LookAtCam;
		local XGBattle_SP Battle;
		local XComUnitPawn FocusActor;
		local XGUnit FocusUnit;			
		local Vector MoveToPoint;

		History = `XCOMHISTORY;

		LookAtCam = new class'X2Camera_MidpointTimed';
		foreach RevealedUnitVisualizers(FocusActor)
		{
			//Add the destination points for the moving AIs to the look at camera, as well as their current locations
			FocusUnit = XGUnit(FocusActor.GetGameUnit());
			if(FocusUnit != none)
			{
				LookAtCam.AddFocusPoint(FocusActor.Location);
				TempUnitState = XComGameState_Unit(History.GetGameStateForObjectID(FocusUnit.ObjectID));
				MoveToPoint = `XWORLD.GetPositionFromTileCoordinates(TempUnitState.TileLocation);
				LookAtCam.AddFocusPoint(MoveToPoint);
			}
		}
		LookAtCam.LookAtDuration = 10.0f; //This camera will be manually removed in the end reveal
		LookAtCam.Priority = eCameraPriority_CharacterMovementAndFraming;
		LookAtCam.UpdateWhenInactive = true;
		`CAMERASTACK.AddCamera(LookAtCam);

		Battle = XGBattle_SP(`BATTLE);
		Battle.GetAIPlayer().SetAssociatedCamera(LookAtCam);
	}

	function RequestTheLostCamera()
	{
		local XGBattle_SP Battle;
		local X2Camera_TheLostReveal LostRevealCam;

		if( WantsToPlayTheLostCamera() && CanPlayTheLostCamera() )
		{
			LostRevealCam = new class'X2Camera_TheLostReveal';
			LostRevealCam.RevealingLostPod = GetRevealedGroup();
		
			Battle = XGBattle_SP(`BATTLE);	
			Battle.GetAIPlayer().SetAssociatedCamera(LostRevealCam);

			`CAMERASTACK.AddCamera(LostRevealCam);

			UpdateUnitVisuals();
		}
	}

	function bool HasLookAtCameraArrived()
	{
		local X2Camera_MidpointTimed LookAtCam;
		local XGBattle_SP Battle;		

		Battle = XGBattle_SP(`BATTLE);
		LookAtCam = X2Camera_MidpointTimed(Battle.GetAIPlayer().AssociatedCamera);

		return LookAtCam == none || LookAtCam.HasArrived;
	}

	function FaceRevealUnitsTowardsEnemy()
	{
		local Vector FaceVector;

		foreach RevealedUnitVisualizers(FocusUnitPawn)
		{

			FaceVector = EnemyUnitVisualizer.GetLocation() - FocusUnitPawn.Location;
			FaceVector.Z = 0;
			FaceVector = Normal(FaceVector);

			FocusUnitPawn.m_kGameUnit.IdleStateMachine.ForceHeading(FaceVector);
			FocusUnitPawn.LOD_TickRate = 0.0f; //Make sure this unit's tick rate is normal speed
		}
	}

	private function bool ShouldPlayRevealCameras()
	{
		local XComGameStateContext_CinematicSpawn CinematicContext;

		History = `XCOMHISTORY;

		// if this unit was cinematically spawned, then we don't need to do another reveal animation
		foreach History.IterateContextsByClassType(class'XComGameStateContext_CinematicSpawn', CinematicContext,, true)
		{
			foreach CinematicContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', TempUnitState)
			{
				if( TempUnitState.ObjectID == MatineeFocusUnitState.ObjectID)
				{
					return false;
				}
			}
		}

		return true;
	}

	function bool ShouldPlayRevealMatinee()
	{
		local XComGameStateContext_ChangeContainer Context;
		local XComGameState_AIReinforcementSpawner SpawnState;
		local XComGameState_AIUnitData AIUnitData;
		local UnitValue ImmobilizeValue;
		local XComUnitPawn PawnVis;
		//local XComGameState_Unit PriorUnitState;

		// not if glam cams are turned off in the options screen
		if(!`Battle.ProfileSettingsGlamCam() && !MatineeFocusUnitState.GetMyTemplate().bIsChosen)
		{
			return false;
		}

		if(!ShouldPlayRevealCameras())
		{
			return false;
		}

		// not if the reveal focus unit is currently immobilized
		if(MatineeFocusUnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, ImmobilizeValue))
		{
			if(ImmobilizeValue.fValue != 0)
			{
				return false;
			}
		}

		History = `XCOMHISTORY;

		// Determine if this reveal is happening immediately after a spawn. If so, then we don't want to play a further
		// reveal matinee. The spawn animations are considered the reveal matinee in this case.
		foreach History.IterateContextsByClassType(class'XComGameStateContext_ChangeContainer', Context,, true)
		{
			if(Context.AssociatedState.HistoryIndex <= RevealContext.AssociatedState.HistoryIndex // only look in the past
				&& Context.EventChainStartIndex == RevealContext.EventChainStartIndex // only within this chain of action
				&& Context.ChangeInfo == class'XComGameState_AIReinforcementSpawner'.default.SpawnReinforcementsCompleteChangeDesc)
			{
				// check if this change spawned our units
				foreach Context.AssociatedState.IterateByClassType(class'XComGameState_AIUnitData', AIUnitData)
				{
					if(RevealContext.RevealedUnitObjectIDs.Find(AIUnitData.m_iUnitObjectID) != INDEX_NONE)
					{
						foreach Context.AssociatedState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', SpawnState)
						{
							// allow reveals for psi gates
							return SpawnState.SpawnVisualizationType == 'PsiGate';
						}

						// no reinforcement game state, so just allow it by default
						return true;
					}
				}
			}

			// we are iterating into the past, so abort as soon as we pass the start of our event chain
			if(Context.AssociatedState.HistoryIndex < RevealContext.EventChainStartIndex)
			{
				break;
			}
		}

		//// don't reveal the lost groups if there were previously any engaged Lost units prior to this reveal action
		//if( MatineeFocusUnitState.GetTeam() == eTeam_TheLost )
		//{
		//	foreach History.IterateByClassType(class'XComGameState_Unit', PriorUnitState, , , RevealContext.EventChainStartIndex - 1)
		//	{
		//		if( PriorUnitState.GetTeam() == eTeam_TheLost && !PriorUnitState.IsInGreenAlert() )
		//		{
		//			return false;
		//		}
		//	}
		//}

		// Prevent lost matinees if any unit in this group has already done its scamper movement.
		if (MatineeFocusUnitState.GetTeam() == eTeam_TheLost)
		{
			foreach RevealedUnitVisualizers(PawnVis)
			{
				if (PawnVis.m_kGameUnit.m_kBehavior.bScamperMoveVisualized)
				{
					return false;
				}
			}
		}

		return true;
	}

	function SelectAndPlayMatinee()
	{											
		local X2Camera_Matinee MatineeSelectingCamera;
		local name MatineeBaseName;
		local string MatineePrefix;
		local X2CharacterTemplate Template;
		local Rotator MatineeOrientation;
		local Object MapPackage;
		
		Template = MatineeFocusUnitState.GetMyTemplate();
	
		if(Template.GetRevealMatineePrefixFn != none)
		{
			// function takes priority over specified matinee prefix
			MatineePrefix = Template.GetRevealMatineePrefixFn(MatineeFocusUnitState);
		}
		else if(Template.RevealMatineePrefix != "")
		{
			// we have a matinee prefix specified, use that
			MatineePrefix = Template.RevealMatineePrefix;
		}
		else
		{
			// if no explicit matinee prefix specified, just use the first package name as a default
			MatineePrefix = Template.strMatineePackages[0];
		}
		
		// add a camera for the cam matinee
		MatineeSelectingCamera = new class'X2Camera_MatineePodReveal';

		if(!MatineeSelectingCamera.SetMatineeByComment(MatineePrefix $ "_Reveal", MatineeFocusUnitVisualizer, true))
		{
			return;
		}

		Matinees.AddItem(MatineeSelectingCamera.MatineeInfo.Matinee);

		// find the base for the selected matinee. By convention, it's the package name with "_Base" appended to it
		MapPackage = MatineeSelectingCamera.MatineeInfo.Matinee.Outer;
		while(MapPackage.Outer != none) // the map will be the outermost (GetOutermost() is not script accessible)
		{
			MapPackage = MapPackage.Outer;
		}
		MatineeBaseName = name(string(MapPackage.Name) $ "_Base");
		SetMatineeBase(MatineeBaseName);

		// while the reveal unit *should* be facing XCom by now, to be super robust, orient the matinee towards XCom explicitly
		MatineeOrientation = Rotator(EnemyUnitVisualizer.GetLocation() - MatineeFocusUnitVisualizer.GetLocation());
		MatineeOrientation.Pitch = 0;
		MatineeOrientation.Roll = 0;
		SetMatineeLocation(MatineeFocusUnitVisualizer.GetPawn().GetFeetLocation(), MatineeOrientation);

		AddUnitToMatinee('Char1', MatineeFocusUnitState);
		PlayMatinee();
	}

	function DoSoldierVOForSpottingUnit()
	{
		local int Index;
		local bool bAdvent;

		History = `XCOMHISTORY;

		for (Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index)
		{
			TempUnitState = XComGameState_Unit(History.GetGameStateForObjectID(RevealContext.RevealedUnitObjectIDs[Index], eReturnType_Reference, RevealContext.AssociatedState.HistoryIndex));
			if ( TempUnitState.IsAdvent() && !TempUnitState.GetMyTemplate().bIsTurret)
			{
				bAdvent = true;
				break;
			}
		}

		if (bAdvent)
		{
			EnemyUnitVisualizer.UnitSpeak('ADVENTsighting');
		}
	}

	function CreateFOWViewer()
	{
		local DynamicPointInSpace Viewer;
		local Actor TargetActor;
		local XGBattle_SP Battle;

		Battle = XGBattle_SP(`BATTLE);

		TargetActor = `XCOMHISTORY.GetVisualizer(RevealContext.RevealedUnitObjectIDs[0]);
		if( TargetActor != None )
		{
			Viewer = DynamicPointInSpace(`XWORLD.CreateFOWViewer(TargetActor.Location, 1200));
			Viewer.SetObjectID(RevealContext.RevealedUnitObjectIDs[0]);
			Viewer.SetBase(TargetActor);

			`XWORLD.ForceFOWViewerUpdate(Viewer);

			Battle.GetAIPlayer().SetFOWViewer(Viewer);
		}
	}
Begin:

	if( RevealedUnitVisualizers.Length > 0 )
	{
		// Ensure that revealed units have time dilation reset, necessary when they are moving and are revealed as a result of seeing you.
		ResetTimeDilation();

		//Clear the FOW around the alerted enemies	
		CreateFOWViewer();

		if( !bOnlyFrameAI || (WantsToPlayTheLostCamera() && !CanPlayTheLostCamera()) )
		{
			if( !WantsToPlayTheLostCamera() )
			{
				UpdateUnitVisuals();
			}
			`Pres.m_kUIMouseCursor.HideMouseCursor();

			//Instruct the enemies to face towards the enemy that encountered them
			FaceRevealUnitsTowardsEnemy();

			//Pan over to the revealing AI group
			if( !bNewUnitSelected && !MatineeFocusUnitState.GetMyTemplate().bDisableRevealLookAtCamera && ShouldPlayRevealCameras() )
			{
				RequestInitialLookAtCamera();
			}

			if( RevealContext.FirstSightingMoment == none && RevealContext.bDoSoldierVO )
			{
				// We only do soldier VO if we arent doing first sighting narrative
				DoSoldierVOForSpottingUnit();
			}

			// wait for he camera to get over there
			while( InitialLookAtCam != None && !InitialLookAtCam.HasArrived && InitialLookAtCam.IsLookAtValid() )
			{
				Sleep(0.0f);
			}

			// do the normal framing delay so it's consistent with the flow of ability activation
			Sleep(class'X2Action_CameraFrameAbility'.default.FrameDuration * GetDelayModifier());

			// Wait for the reveal units to finish turning. They should already be done due to the camera movement and
			// delay, but just in case
			for (FocusUnitIndex = 0; FocusUnitIndex < RevealedUnitVisualizers.Length; ++FocusUnitIndex)
			{
				FocusUnitPawn = RevealedUnitVisualizers[FocusUnitIndex];
				FocusUnitPawn.LOD_TickRate = 0.0f; //Make sure this unit's tick rate is normal speed
				bAnyEvaluatingStance = bAnyEvaluatingStance || FocusUnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance();
			}
			
			// Wait for all the reveal units to finish evaluating their stance
			while (bAnyEvaluatingStance)
			{
				bAnyEvaluatingStance = false;
				for (FocusUnitIndex = 0; FocusUnitIndex < RevealedUnitVisualizers.Length; ++FocusUnitIndex)
				{
					bAnyEvaluatingStance = bAnyEvaluatingStance || FocusUnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance();
				}

				Sleep(0.0f);
			}

			for (FocusUnitIndex = 0; FocusUnitIndex < RevealedUnitVisualizers.Length; ++FocusUnitIndex)
			{
				FocusUnitPawn = RevealedUnitVisualizers[FocusUnitIndex];
				TempUnitState = XComGameState_Unit(History.GetGameStateForObjectID(FocusUnitPawn.ObjectID, eReturnType_Reference, RevealContext.AssociatedState.HistoryIndex));
				
				if( TempUnitState != None && TempUnitState.GetMyTemplate().bLockdownPodIdleUntilReveal )
				{
					// Jwats: Some Units are locked down after the pod idle to prevent turning
					FocusUnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
				}
			}

			//Select and play a reveal matinee, wait for it to finish
			if( ShouldPlayRevealMatinee() )
			{
				SelectAndPlayMatinee();

				// the base class will modify the timeout after starting the matinee to be the same length as the matinee. So we need
				// to put the timeout back here, since we will be doing other things afterwards
				TimeoutSeconds += default.TimeoutSeconds;

				while( Matinees.Length > 0 )
				{
					Sleep(0.0f);
				}

				if( WantsToPlayTheLostCamera() )
				{
					UpdateUnitVisuals();
				}

				EndMatinee();
			}

			if( RevealContext.SurprisedScamperUnitIDs.Length > 0 )
			{
				ShowSurprisedFlyover();
			}

			if( RevealContext.FirstSightingMoment != none )
			{
				`PRESBASE.UINarrative(RevealContext.FirstSightingMoment);
				Sleep(FirstSightedDelay * GetDelayModifier());
			}

			//Play a narrative moment for sighting this type of enemy
			// 	if( MatineeFocusUnitTemplate != None )
			// 	{
			// 		`PRES.DoNarrativeByCharacterTemplate(MatineeFocusUnitTemplate);
			// 	}

			// Don't remove this camera until after the matinee is done, sometimes the matinee camera finishes before 
			// the matinee animation and we want to ensure we don't go to the look at cursor camera
			if( InitialLookAtCam != None )
			{
				`CAMERASTACK.RemoveCamera(InitialLookAtCam);
				InitialLookAtCam = None;
			}
		}

		// Create a lookat camera for the AI moves that will frame their current locations as well as all their destinations.
		// The initial lookat camera only did their origin locations, which is why we need a new camera.
		if( !bNewUnitSelected && !MatineeFocusUnitState.GetMyTemplate().bDisableRevealLookAtCamera)
		{
			RequestLookAtCamera();
			while( !HasLookAtCameraArrived() )
			{
				Sleep(0.0f);
			}

			RequestTheLostCamera();
		}
	}

	CompleteAction();
}

function CompleteAction()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.CompleteAction();

	// if we are stopped for whatever reason before the action can finish normally, 
	// make sure the initial lookup cam gets removed
	if( InitialLookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(InitialLookAtCam);
		InitialLookAtCam = None;
	}

	WorldInfo.RemoteEventListeners.RemoveItem(self);

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.UnRegisterFromAllEvents(ThisObj);
}

event HandleNewUnitSelection()
{
	if( InitialLookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(InitialLookAtCam);
		InitialLookAtCam = None;
	}
}

DefaultProperties
{	
	RevealFOWRadius = 768.0; //8 tiles
	bUseProximityDither=true
	bReceivedUIChosenReveal_OnRemoved=false

	OutputEventIDs.Add( "Visualizer_ChosenRevealUI_Removed" )
}

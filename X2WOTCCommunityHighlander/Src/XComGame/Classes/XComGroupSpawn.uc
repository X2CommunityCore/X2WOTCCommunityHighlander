class XComGroupSpawn extends Actor
	  placeable
	  native(Core);
	  //hidecategories(Display, Attachment, Collision, Physics, Advanced, Mobile, Debug);

var StaticMeshComponent StaticMesh;
var float Score;

function bool IsLocationInside(const out Vector TestLocation)
{
	local Vector MinPoint;
	local Vector MaxPoint;

	MinPoint = StaticMesh.Bounds.Origin - StaticMesh.Bounds.BoxExtent;
	MaxPoint = StaticMesh.Bounds.Origin + StaticMesh.Bounds.BoxExtent;

	if( TestLocation.X >= MinPoint.X && TestLocation.Y >= MinPoint.Y && TestLocation.Z >= MinPoint.Z &&
		TestLocation.X <= MaxPoint.X && TestLocation.Y <= MaxPoint.Y && TestLocation.Z <= MaxPoint.Z)
	{
		return true;
	}

	return false;
}

function bool IsBoxInside(Vector TestLocation, Vector TestExtents)
{
	local Vector MinPoint, MaxPoint;
	local Vector TestMin, TestMax;

	MinPoint = StaticMesh.Bounds.Origin - StaticMesh.Bounds.BoxExtent;
	MaxPoint = StaticMesh.Bounds.Origin + StaticMesh.Bounds.BoxExtent;

	TestMin = TestLocation;
	TestMax = TestLocation + TestExtents;

	if ((TestMin.X > MaxPoint.X) || (TestMax.X < MinPoint.X))
	{
		return false;
	}
	if ((TestMin.Y > MaxPoint.Y) || (TestMax.Y < MinPoint.Y))
	{
		return false;
	}
	if ((TestMin.Z > MaxPoint.Z) || (TestMax.Z < MinPoint.Z))
	{
		return false;
	}

	return true;
}

// gets all the floor locations that this group spawn encompasses
function GetValidFloorLocations(out array<Vector> FloorPoints, float SpawnSizeOverride = -1)
{
	/// ISSUE #18 - START
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if(DLCInfos[i].GetValidFloorSpawnLocations(FloorPoints, SpawnSizeOverride, self))
		{
			return;
		}
	}

	if (SpawnSizeOverride <= 0) {
		SpawnSizeOverride = 2 + class'CHHelpers'.default.SPAWN_EXTRA_TILE;
	}
	/// Issue #18 - END

	`XWORLD.GetFloorTilePositions(Location, 96 * SpawnSizeOverride, 64 * SpawnSizeOverride, FloorPoints, true);
}

function GetValidFloorLocationsXYZ(out array<Vector> FloorPoints, float TileScaleXY = -1, float TileScaleZ = -1)
{
	if (TileScaleXY <= 0) TileScaleXY = 2;
	if (TileScaleZ <= 0) TileScaleZ = 2;

	`XWORLD.GetFloorTilePositions(Location, 96 * TileScaleXY, 64 * TileScaleZ, FloorPoints, true);
}

// gets all the floor TILES that this group spawn encompasses, within the provided dimensions
function GetValidFloorTilesForMP(out array<TTile> FloorTiles, int iWidth, int iHeight)
{
	local TTile RootTile;

	RootTile = GetTile();

	`XWORLD.GetSpawnTilePossibilities(RootTile, iWidth, iHeight, 1, FloorTiles);
}

function TTile GetTile()
{
	return `XWORLD.GetTileCoordinatesFromPosition(Location);
}

function bool HasValidFloorLocations( float SpawnSizeOverride = -1 )
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<Vector> FloorPoints;

	GetValidFloorLocations(FloorPoints, SpawnSizeOverride);

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if(XComHQ != none)
	{
		return FloorPoints.Length >= XComHQ.Squad.Length;
	}

	// no HQ (possibly in PIE), just fall back to whatever the default is
	return FloorPoints.Length >= class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission();
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object

	Begin Object Class=StaticMeshComponent Name=ExitStaticMeshComponent
		HiddenGame=True
		StaticMesh=StaticMesh'Parcel.Meshes.Parcel_Extraction_3x3'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
	End Object
	Components.Add(ExitStaticMeshComponent)
	StaticMesh = ExitStaticMeshComponent;

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'LayerIcons.Editor.group_spawn'
		HiddenGame=True
		Translation=(X=0,Y=0,Z=64)
	End Object
	Components.Add(Sprite);

	bEdShouldSnap=true

	// half size the sprite but scale the mesh back up so it's normal size
	DrawScale3D=(X=2.0,Y=2.0,Z=2.0)
	DrawScale=0.5

	Layer=Markup
}

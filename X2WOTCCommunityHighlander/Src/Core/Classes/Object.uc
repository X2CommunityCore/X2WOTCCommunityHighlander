/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
//=============================================================================
// Object: The base class all objects.
// This is a built-in Unreal class and it shouldn't be modified by mod authors
//=============================================================================
class Object
	abstract
	native
	noexport;

//=============================================================================
// Unreal base structures.

// Temporary UnrealScript->C++ mirrors.

struct pointer
{
	var native const int Dummy;
};

struct shared_ptr
{
	var native pointer _Ptr;
	var native pointer _Rep;

};

struct {QWORD} qword
{
	var native int A, B;
};

//=============================================================================
// UObject variables.

// Internal variables.
var native private const editconst noexport		pointer VfTableObject;
var native private const editconst				pointer HashNext;
var native private const editconst				qword ObjectFlags;			// This needs to be 8-byte aligned in 32-bit!
var native private const editconst				pointer HashOuterNext;
var native private const editconst				pointer StateFrame;
var native private const editconst noexport		Object Linker;
var native private const editconst noexport		pointer LinkerIndex;
var native private const editconst noexport		int ObjectInternalInteger;
var native private const editconst noexport		int NetIndex;
var native const editconst						Object Outer;
var() native const editconst					name Name;
var native const editconst						class Class;
var() native const editconst					Object ObjectArchetype;
////////////////////////////////////////////////////////////////////////////////////////////////
// IMPORTANT: DO NOT ADD _ANY_ MEMBERS AFTER ObjectArchetype! Add ALL members before it, as the
// C++ code expects it to be the final member of UObject! (see UObject::InitProperties)
////////////////////////////////////////////////////////////////////////////////////////////////


//=============================================================================
// Unreal base structures continued.

struct {DOUBLE} double
{
	var native const int		A;
	var native const int		B;
};

struct ThreadSafeCounter
{
	var native const int		Value;
};

struct BitArray_Mirror
{
	var native const pointer IndirectData;
	var native const int InlineData[4];
	var native const int NumBits;
	var native const int MaxBits;
};

struct SparseArray_Mirror
{
	var native const array<int> Elements;
	var native const BitArray_Mirror AllocationFlags;
	var native const int FirstFreeIndex;
	var native const int NumFreeIndices;
};

struct Set_Mirror
{
	var native const SparseArray_Mirror Elements;
	var native const int InlineHash;
	var native const pointer Hash;
	var native const int HashSize;
};

struct Map_Mirror
{
	var native const Set_Mirror Pairs;
};

struct MultiMap_Mirror
{
	var native const Set_Mirror Pairs;
};

struct UntypedBulkData_Mirror
{
	var native const pointer	VfTable;
	var native const int		BulkDataFlags;
	var native const int		ElementCount;
	var native const int		BulkDataOffsetInFile;
	var native const int 		BulkDataSizeOnDisk;
	var native const int		SavedBulkDataFlags;
	var native const int		SavedElementCount;
	var native const int		SavedBulkDataOffsetInFile;
	var native const int		SavedBulkDataSizeOnDisk;
	var native const pointer	BulkData;
	var native const int		LockStatus;
	var native const pointer	AttachedAr;
	var native const int		bShouldFreeOnEmpty;
};

struct RenderCommandFence_Mirror
{
	var native const transient int NumPendingFences;
};

// needs to match FColorVertexBuffer in C++
struct FColorVertexBuffer_Mirror
{
	var native const pointer	VfTable;
	var native const pointer	VertexData;
	var private const int 		Data;
	var private const int		Stride;
	var private const int 		NumVertices;
};

// needs to match FUVVertexBuffer in C++
struct FUVVertexBuffer_Mirror
{
	var native const pointer	VfTable;
	var native const pointer	VertexData;
	var private const int 		Data;
	var private const int		Stride;
	var private const int 		NumVertices;
};

struct FTangentXVertexBuffer_Mirror
{
	var native const pointer	VfTable;
	var native const pointer	VertexData;
	var private const int 		Data;
	var private const int		Stride;
	var private const int 		NumVertices;
};

struct IndirectArray_Mirror
{
	// FScriptArray
	var native const pointer	Data;
	var native const int		ArrayNum;
	var native const int		ArrayMax;
};

struct Array_Mirror
{
	// FScriptArray
	var native const pointer	Data;
	var native const int		ArrayNum;
	var native const int		ArrayMax;
};

/**
 * Structure mirroring an array of pointers using an inline allocator.
 */
struct InlinePointerArray_Mirror
{
	var private const pointer InlineData;
	var private const Array_Mirror SecondaryData;
};

// A globally unique identifier.
struct immutable Guid
{
	var int A, B, C, D;
};

// A point or direction vector in 3d space.
struct immutable Vector
{
	var() databinding float X, Y, Z;
};

struct immutable Vector4
{
	var() float X, Y, Z, W;
};

struct immutable Vector2D
{
	var() databinding float X, Y;
};

struct immutable TwoVectors
{
	var() Vector	v1, v2;
};

// A plane definition in 3d space.
struct immutable Plane extends Vector
{
	var() float W;
};

// An orthogonal rotation in 3d space.
struct immutable Rotator
{
	var() int Pitch, Yaw, Roll;
};

// Quaternion
struct immutable Quat
{
	var() float X, Y, Z, W;
};

// A packed normal.
struct immutable PackedNormal
{
	var() byte X, Y, Z, W;
};

/**
 * Screen coordinates
 */
struct immutable IntPoint
{
	var() int X, Y;
};

/**
 * A vector of spherical harmonic coefficients.
 */
struct SHVector
{
	// Note: The number of SH coefficients must match NUM_SH_BASIS in SHMath.h!
	// The struct must also be padded to be 16-byte aligned.
	var() float V[9];
	var float Padding[3];
};

/**
 * A vector of spherical harmonic coefficients for each color component.
 */
struct SHVectorRGB
{
	var() SHVector R;
	var() SHVector G;
	var() SHVector B;
};

/**
 * Point Of View type.
 */
struct TPOV
{
	/** Location */
	var() Vector	Location;
	/** Rotation */
	var() Rotator	Rotation;
	/** FOV angle */
	var() float		FOV;

	structdefaultproperties
	{
		FOV=90.f
	}
};

/** Various ways to interpolate TAlphaBlend. */
enum AlphaBlendType
{
	ABT_Linear,
	ABT_Cubic,
	ABT_Sinusoidal,
	ABT_EaseInOutExponent2,
	ABT_EaseInOutExponent3,
	ABT_EaseInOutExponent4,
	ABT_EaseInOutExponent5,
};

/** Structure to encompass Alpha Interpolation. */
struct TAlphaBlend
{
	/** Internal Lerped value for Alpha */
	var const	FLOAT			AlphaIn;
	/** Resulting Alpha value, between 0.f and 1.f */
	var const	FLOAT			AlphaOut;
	/** Target to reach */
	var()		FLOAT			AlphaTarget;
	/** Default blend time */
	var()		FLOAT			BlendTime;
	/** Time left to reach target */
	var	const	FLOAT			BlendTimeToGo;
	/** Type of blending used (Linear, Cubic, etc.) */
	var()		AlphaBlendType	BlendType;

	structdefaultproperties
	{
		BlendTime=0.67f
		BlendType=ABT_Linear
	}
};

// FIRAXIS begin -tsmith
// NOTE: need the eTeam_DONT_USE_X because the enum values are used as bitfields in C++ -tsmith 
enum ETeam
{
	eTeam_None,		// = 0
	eTeam_Neutral,	// = 1
	eTeam_One,		// = 2
	eTeam_DONT_USE_3,
	eTeam_Two,		// = 4
	eTeam_DONT_USE_5,
	eTeam_DONT_USE_6,
	eTeam_DONT_USE_7,
	eTeam_XCom,		// = 8
	eTeam_DONT_USE_9,
	eTeam_DONT_USE_10,
	eTeam_DONT_USE_11,
	eTeam_DONT_USE_12,
	eTeam_DONT_USE_13,
	eTeam_DONT_USE_14,
	eTeam_DONT_USE_15,
	eTeam_Alien,		// = 16
	eTeam_DONT_USE_17,
	eTeam_DONT_USE_18,
	eTeam_DONT_USE_19,
	eTeam_DONT_USE_20,
	eTeam_DONT_USE_21,
	eTeam_DONT_USE_22,
	eTeam_DONT_USE_23,
	eTeam_DONT_USE_24,
	eTeam_DONT_USE_25,
	eTeam_DONT_USE_26,
	eTeam_DONT_USE_27,
	eTeam_DONT_USE_28,
	eTeam_DONT_USE_29,
	eTeam_DONT_USE_30,
	eTeam_DONT_USE_31,
	eTeam_TheLost,		// = 32
	eTeam_DONT_USE_33,
	eTeam_DONT_USE_34,
	eTeam_DONT_USE_35,
	eTeam_DONT_USE_36,
	eTeam_DONT_USE_37,
	eTeam_DONT_USE_38,
	eTeam_DONT_USE_39,
	eTeam_DONT_USE_40,
	eTeam_DONT_USE_41,
	eTeam_DONT_USE_42,
	eTeam_DONT_USE_43,
	eTeam_DONT_USE_44,
	eTeam_DONT_USE_45,
	eTeam_DONT_USE_46,
	eTeam_DONT_USE_47,
	eTeam_DONT_USE_48,
	eTeam_DONT_USE_49,
	eTeam_DONT_USE_50,
	eTeam_DONT_USE_51,
	eTeam_DONT_USE_52,
	eTeam_DONT_USE_53,
	eTeam_DONT_USE_54,
	eTeam_DONT_USE_55,
	eTeam_DONT_USE_56,
	eTeam_DONT_USE_57,
	eTeam_DONT_USE_58,
	eTeam_DONT_USE_59,
	eTeam_DONT_USE_60,
	eTeam_DONT_USE_61,
	eTeam_DONT_USE_62,
	eTeam_DONT_USE_63,
	eTeam_Resistance, 		// = 64
	eTeam_DONT_USE_65,
	eTeam_DONT_USE_66,
	eTeam_DONT_USE_67,
	eTeam_DONT_USE_68,
	eTeam_DONT_USE_69,
	eTeam_DONT_USE_70,
	eTeam_DONT_USE_71,
	eTeam_DONT_USE_72,
	eTeam_DONT_USE_73,
	eTeam_DONT_USE_74,
	eTeam_DONT_USE_75,
	eTeam_DONT_USE_76,
	eTeam_DONT_USE_77,
	eTeam_DONT_USE_78,
	eTeam_DONT_USE_79,
	eTeam_DONT_USE_80,
	eTeam_DONT_USE_81,
	eTeam_DONT_USE_82,
	eTeam_DONT_USE_83,
	eTeam_DONT_USE_84,
	eTeam_DONT_USE_85,
	eTeam_DONT_USE_86,
	eTeam_DONT_USE_87,
	eTeam_DONT_USE_88,
	eTeam_DONT_USE_89,
	eTeam_DONT_USE_90,
	eTeam_DONT_USE_91,
	eTeam_DONT_USE_92,
	eTeam_DONT_USE_93,
	eTeam_DONT_USE_94,
	eTeam_DONT_USE_95,
	eTeam_DONT_USE_96,
	eTeam_DONT_USE_97,
	eTeam_DONT_USE_98,
	eTeam_DONT_USE_99,
	eTeam_DONT_USE_100,
	eTeam_DONT_USE_101,
	eTeam_DONT_USE_102,
	eTeam_DONT_USE_103,
	eTeam_DONT_USE_104,
	eTeam_DONT_USE_105,
	eTeam_DONT_USE_106,
	eTeam_DONT_USE_107,
	eTeam_DONT_USE_108,
	eTeam_DONT_USE_109,
	eTeam_DONT_USE_110,
	eTeam_DONT_USE_111,
	eTeam_DONT_USE_112,
	eTeam_DONT_USE_113,
	eTeam_DONT_USE_114,
	eTeam_DONT_USE_115,
	eTeam_DONT_USE_116,
	eTeam_DONT_USE_117,
	eTeam_DONT_USE_118,
	eTeam_DONT_USE_119,
	eTeam_DONT_USE_120,
	eTeam_DONT_USE_121,
	eTeam_DONT_USE_122,
	eTeam_DONT_USE_123,
	eTeam_DONT_USE_124,
	eTeam_DONT_USE_125,
	eTeam_DONT_USE_126,
	eTeam_All,  // = 127
};
// FIRAXIS end -tsmith

// Generic axis enum.
enum EAxis
{
	AXIS_NONE, // = 0
	AXIS_X, // = 1
	AXIS_Y, // = 2
	AXIS_BLANK, // = 3. Need this because AXIS enum is used as bitfield in C++...
	AXIS_Z // 4
};

enum EInputEvent
{
	IE_Pressed,
	IE_Released,
	IE_Repeat,
	IE_DoubleClick,
	IE_Axis
};

enum EAspectRatioAxisConstraint
{
	AspectRatio_MaintainYFOV,
	AspectRatio_MaintainXFOV,
	AspectRatio_MajorAxisFOV
};

// A color.
struct immutable Color
{
	var() byte B, G, R, A;
};

// A linear color.
struct immutable LinearColor
{
	var() float R, G, B, A;

	structdefaultproperties
	{
		A=1.f
	}
};

// A bounding box.
struct immutable Box
{
	var() vector Min, Max;
	var byte IsValid;
};

// A bounding box and bounding sphere with the same origin.
struct BoxSphereBounds
{
	var() vector	Origin;
	var() vector	BoxExtent;
	var() float		SphereRadius;
};

// a 4x4 matrix
struct immutable Matrix
{
	var() Plane XPlane;
	var() Plane YPlane;
	var() Plane ZPlane;
	var() Plane WPlane;
};

struct Cylinder
{
	var float Radius, Height;
};

// Interpolation data types.
enum EInterpCurveMode
{
	CIM_Linear,
	CIM_CurveAuto,
	CIM_Constant,
	CIM_CurveUser,
	CIM_CurveBreak,
	CIM_CurveAutoClamped
};

// Interpolation data types.
enum EInterpMethodType
{
	IMT_UseFixedTangentEvalAndNewAutoTangents,
	IMT_UseFixedTangentEval,
	IMT_UseBrokenTangentEval
};

struct InterpCurvePointFloat
{
	var() float InVal;
	var() float OutVal;
	var() float ArriveTangent;
	var() float LeaveTangent;
	var() EInterpCurveMode InterpMode;
};
struct InterpCurveFloat
{
	var() array<InterpCurvePointFloat>	Points;
	var   EInterpMethodType				InterpMethod;
};

struct InterpCurvePointVector2D
{
	var() float InVal;
	var() vector2d OutVal;
	var() vector2d ArriveTangent;
	var() vector2d LeaveTangent;
	var() EInterpCurveMode InterpMode;
};
struct InterpCurveVector2D
{
	var() array<InterpCurvePointVector2D>	Points;
	var   EInterpMethodType				InterpMethod;
};

struct InterpCurvePointVector
{
	var() float InVal;
	var() vector OutVal;
	var() vector ArriveTangent;
	var() vector LeaveTangent;
	var() EInterpCurveMode InterpMode;
};
struct InterpCurveVector
{
	var() array<InterpCurvePointVector>	Points;
	var   EInterpMethodType				InterpMethod;
};

struct InterpCurvePointTwoVectors
{
	var() float				InVal;
	var() twovectors		OutVal;
	var() twovectors		ArriveTangent;
	var() twovectors		LeaveTangent;
	var() EInterpCurveMode	InterpMode;
};
struct InterpCurveTwoVectors
{
	var() array<InterpCurvePointTwoVectors>	Points;
	var   EInterpMethodType				InterpMethod;
};

struct InterpCurvePointQuat
{
	var() float InVal;
	var() quat OutVal;
	var() quat ArriveTangent;
	var() quat LeaveTangent;
	var() EInterpCurveMode InterpMode;
};
struct InterpCurveQuat
{
	var() array<InterpCurvePointQuat> Points;
	var   EInterpMethodType				InterpMethod;
};

struct InterpCurvePointLinearColor
{
	var() float InVal;
	var() linearcolor OutVal;
	var() linearcolor ArriveTangent;
	var() linearcolor LeaveTangent;
	var() EInterpCurveMode InterpMode;
};
struct InterpCurveLinearColor
{
	var() array<InterpCurvePointLinearColor>	Points;
	var   EInterpMethodType				InterpMethod;
};

// Base class for raw (baked out) Distribution type
struct RawDistribution
{
	var byte Type;
	var byte Op;
	var byte LookupTableNumElements;
	var byte LookupTableChunkSize;
	var array<float> LookupTable;
	var float LookupTableTimeScale;
	var float LookupTableStartTime;
};

/** A fence used to track rendering thread command execution. */
struct RenderCommandFence
{
	var private native const int NumPendingFences;
};

/** Mirror for FElementId used in generic Octree */
struct OctreeElementId
{
	var private native const pointer Node;
	var private native const int ElementIndex;
};

/** Bone Atom definition */
struct BoneAtom
{
	var	quat	Rotation;
	var	vector	Translation;
	var float	Scale;
};

//=============================================================================
// Constants.

const MaxInt = 0x7fffffff;
const MinInt = 0x80000000;
const Pi = 3.1415926535897932;
const RadToDeg = 57.295779513082321600;	// 180 / Pi
const DegToRad = 0.017453292519943296;		// Pi / 180
const UnrRotToRad = 0.00009587379924285;		// Pi / 32768
const RadToUnrRot = 10430.3783504704527;		// 32768 / Pi
const DegToUnrRot = 182.0444;
const UnrRotToDeg = 0.00549316540360483;
const INDEX_NONE = -1;
const EPSILON_ZERO = 0.0001f;

// Aspect ratio constants
const AspectRatio4x3 = 1.33333;
const AspectRatio5x4 = 1.25;
const AspectRatio16x9 = 1.77778;
const InvAspectRatio4x3 = 0.75;
const InvAspectRatio5x4 = 0.8;
const InvAspectRatio16x9 = 0.56249;

//=============================================================================
// Logging Severity Levels.

/**
 * Determines which ticking group an Actor/Component belongs to
 */
enum ETickingGroup
{
	/**
	 * Any item that needs to be updated before asynchronous work is done
	 */
	TG_PreAsyncWork,
	/**
	 * Any item that can be run in parallel of our async work
	 */
	TG_DuringAsyncWork,
	/**
	 * Any item that needs the async work to be done before being updated
	 */
	TG_PostAsyncWork,
	/**
	 * Any item that needs the update work to be done before being ticked
	 */
	 TG_PostUpdateWork,
	/**
	 * Special Tick Group Specifically for the Emitter Pool. Used to update Particle Locations before the Effect Update happens.
	 */
 	 TG_EmitterPoolWork,
	/** Special effects that need to be updated last */
	 TG_EffectsUpdateWork
};


/**
 * These are the types of PerfMem RunResults you the system understands and can achieve.  They are stored in the table as we
 * will get "valid" numbers but we ran OOM.  We want to list the numbers in the OOM case because there is probably something that
 * jumped up to cause the OOM (e.g. vertex lighting).
 **/
enum EAutomatedRunResult
{
	ARR_Unknown,
	ARR_OOM,
	ARR_Passed,
};


/**
 * Different modes for the DebugBreak() method.
 */
enum EDebugBreakType
{
	DEBUGGER_NativeOnly,

	/** not yet implemented */
	DEBUGGER_ScriptOnly,
	/** not yet implemented */
	DEBUGGER_Both,
};

//=============================================================================
// Basic native operators and functions.


//
// Bool operators.
//

native(129) static final preoperator  bool  !  ( bool A );
native(242) static final operator(24) bool  == ( bool A, bool B );
native(243) static final operator(26) bool  != ( bool A, bool B );
native(130) static final operator(30) bool  && ( bool A, skip bool B );
native(131) static final operator(30) bool  ^^ ( bool A, bool B );
native(132) static final operator(32) bool  || ( bool A, skip bool B );


//
// Byte operators.
//

native(133) static final operator(34) byte *= ( out byte A, byte B );
native(198) static final operator(34) byte *= ( out byte A, float B );
native(134) static final operator(34) byte /= ( out byte A, byte B );
native(135) static final operator(34) byte += ( out byte A, byte B );
native(136) static final operator(34) byte -= ( out byte A, byte B );
native(137) static final preoperator  byte ++ ( out byte A );
native(138) static final preoperator  byte -- ( out byte A );
native(139) static final postoperator byte ++ ( out byte A );
native(140) static final postoperator byte -- ( out byte A );


//
// Integer operators.
//

native(141) static final preoperator  int  ~  ( int A );
native(143) static final preoperator  int  -  ( int A );
native(144) static final operator(16) int  *  ( int A, int B );
native(145) static final operator(16) int  /  ( int A, int B );
native(253) static final operator(18) int  %  ( int A, int B );
native(146) static final operator(20) int  +  ( int A, int B );
native(147) static final operator(20) int  -  ( int A, int B );
native(148) static final operator(22) int  << ( int A, int B );
native(149) static final operator(22) int  >> ( int A, int B );
native(196) static final operator(22) int  >>>( int A, int B );
native(150) static final operator(24) bool <  ( int A, int B );
native(151) static final operator(24) bool >  ( int A, int B );
native(152) static final operator(24) bool <= ( int A, int B );
native(153) static final operator(24) bool >= ( int A, int B );
native(154) static final operator(24) bool == ( int A, int B );
native(155) static final operator(26) bool != ( int A, int B );
native(156) static final operator(28) int  &  ( int A, int B );
native(157) static final operator(28) int  ^  ( int A, int B );
native(158) static final operator(28) int  |  ( int A, int B );
native(159) static final operator(34) int  *= ( out int A, float B );
native(160) static final operator(34) int  /= ( out int A, float B );
native(161) static final operator(34) int  += ( out int A, int B );
native(162) static final operator(34) int  -= ( out int A, int B );
native(163) static final preoperator  int  ++ ( out int A );
native(164) static final preoperator  int  -- ( out int A );
native(165) static final postoperator int  ++ ( out int A );
native(166) static final postoperator int  -- ( out int A );


//
// Integer functions.
//

/** Rand will give you a value between 0 and Max -1 **/
native(167) static final Function     int  Rand  ( int Max );
native(249) static final function     int  Min   ( int A, int B );
native(250) static final function     int  Max   ( int A, int B );
native(251) static final function     int  Clamp ( int V, int A, int B );
native		static final function	string ToHex ( int A );


//
// Float operators.
//

native(169) static final preoperator  float -  ( float A );
native(170) static final operator(12) float ** ( float Base, float Exp );
native(171) static final operator(16) float *  ( float A, float B );
native(172) static final operator(16) float /  ( float A, float B );
native(173) static final operator(18) float %  ( float A, float B );
native(174) static final operator(20) float +  ( float A, float B );
native(175) static final operator(20) float -  ( float A, float B );
native(176) static final operator(24) bool  <  ( float A, float B );
native(177) static final operator(24) bool  >  ( float A, float B );
native(178) static final operator(24) bool  <= ( float A, float B );
native(179) static final operator(24) bool  >= ( float A, float B );
native(180) static final operator(24) bool  == ( float A, float B );
native(210) static final operator(24) bool  ~= ( float A, float B );
native(181) static final operator(26) bool  != ( float A, float B );
native(182) static final operator(34) float *= ( out float A, float B );
native(183) static final operator(34) float /= ( out float A, float B );
native(184) static final operator(34) float += ( out float A, float B );
native(185) static final operator(34) float -= ( out float A, float B );

//
// Float functions.
//

native(186) static final function	float Abs   ( float A );
native(187) static final function	float Sin   ( float A );
native      static final function	float Asin  ( float A );
native(188) static final function	float Cos   ( float A );
native      static final function	float Acos  ( float A );
native(189) static final function	float Tan   ( float A );
native(190) static final function	float Atan  ( float A );
native		static final function	float Atan2 ( float A, float B );
native(191) static final function	float Exp   ( float A );
native(192) static final function	float Loge  ( float A );
native(193) static final function	float Sqrt  ( float A );
native(194) static final function	float Square( float A );
native(195) static final function	float FRand ();
native(244) static final function	float FMin  ( float A, float B );
native(245) static final function	float FMax  ( float A, float B );
native(246) static final function	float FClamp( float V, float A, float B );
native(247) static final function	float Lerp  ( float A, float B, float Alpha );
native(199)	static final function	int   Round	( float A );
native		static final function	int   FFloor	( float A );
native static final function int FCeil(float A);

/**
 * Cubic Spline interpolation.
 * @param	P		end points
 * @param	T		tangent directions at end points
 * @param	Alpha	distance along spline
 * @return	evaluated value.
 */
native		static final function	float FCubicInterp(float P0, float T0, float P1, float T1, float A);

/**
 * Interpolates with ease-in (smoothly approaches B).
 * @param	A		Value to interpolate from.
 * @param	B		Value to interpolate to.
 * @param	Alpha	Interpolant.
 * @param	Exp		Exponent.  Higher values result in more rapid deceleration.
 * @return	Interpolated value.
 */
static final function float FInterpEaseIn(float A, float B, float Alpha, float Exp)
{
	return Lerp(A, B, Alpha**Exp);
}

/**
 * Interpolates with ease-out (smoothly departs A).
 * @param	A		Value to interpolate from.
 * @param	B		Value to interpolate to.
 * @param	Alpha	Interpolant.
 * @param	Exp		Exponent.  Higher values result in more rapid acceleration.
 * @return	Interpolated value.
 */
static final function float FInterpEaseOut(float A, float B, float Alpha, float Exp)
{
	return Lerp(A, B, Alpha**(1/Exp));
}

/**
 * Interpolates with both ease-in and ease-out (smoothly departs A, smoothly approaches B).
 * @param	A		Value to interpolate from.
 * @param	B		Value to interpolate to.
 * @param	Alpha	Interpolant.
 * @param	Exp		Exponent.  Higher values result in more rapid acceleration adn deceleration.
 * @return	Interpolated value.
 */
native static final function float FInterpEaseInOut(float A, float B, float Alpha, float Exp);


/** Return a random number within the given range. */
static final simulated function float RandRange( float InMin, float InMax )
{
    return InMin + (InMax - InMin) * FRand();
}


/**
 * Returns the relative percentage position Value is in the range [Min,Max].
 * Examples:
 * - GetRangeValueByPct( 2, 4, 2 ) == 0
 * - GetRangeValueByPct( 2, 4, 4 ) == 1
 * - GetRangeValueByPct( 2, 4, 3 ) == 0.5
 *
 * @param	Min		Min limit
 * @param	Max		Max limit
 * @param	Value	Value between Range.
 *
 * @return	relative percentage position Value is in the range [Min,Max].
 */

static final simulated function float FPctByRange( float Value, float InMin, float InMax )
{
	return (Value - InMin) / (InMax - InMin);
}


/**
 * Tries to reach Target based on distance from Current position,
 * giving a nice smooth feeling when tracking a position.
 * (Doesn't work well when target teleports)
 *
 * @param		Current			Actual position
 * @param		Target			Target position
 * @param		DeltaTime		time since last tick
 * @param		InterpSpeed		Interpolation speed
 * @return		new interpolated position
 */
native static final function float FInterpTo( float Current, float Target, float DeltaTime, float InterpSpeed );
/** Same as above, but using a constant step */
native static final function float FInterpConstantTo( float Current, float Target, float DeltaTime, float InterpSpeed );


//
// Vector operators.
//

native(211) static final preoperator  vector -     ( vector A );
native(212) static final operator(16) vector *     ( vector A, float B );
native(213) static final operator(16) vector *     ( float A, vector B );
native(296) static final operator(16) vector *     ( vector A, vector B );
native(214) static final operator(16) vector /     ( vector A, float B );
native(215) static final operator(20) vector +     ( vector A, vector B );
native(216) static final operator(20) vector -     ( vector A, vector B );
native(275) static final operator(22) vector <<    ( vector A, rotator B );
native(276) static final operator(22) vector >>    ( vector A, rotator B );
native(217) static final operator(24) bool   ==    ( vector A, vector B );
native(218) static final operator(26) bool   !=    ( vector A, vector B );
native(219) static final operator(16) float  Dot   ( vector A, vector B );
native(220) static final operator(16) vector Cross ( vector A, vector B );
native(221) static final operator(34) vector *=    ( out vector A, float B );
native(297) static final operator(34) vector *=    ( out vector A, vector B );
native(222) static final operator(34) vector /=    ( out vector A, float B );
native(223) static final operator(34) vector +=    ( out vector A, vector B );
native(224) static final operator(34) vector -=    ( out vector A, vector B );

//
// Vector functions.
//

native(225)		static final function	float	VSize		( vector A );
native			static final function	float	VSize2D		( vector A );
native(228)		static final function	float	VSizeSq		( vector A );
native			static final function	float	VSizeSq2D	( vector A );
native(226)		static final function	vector	Normal		( vector A );
native			static final function	vector	VLerp		( vector A, vector B, float Alpha );
native(252)		static final function	vector	VRand		( );
native			static final function	vector	VRandCone	( vector Dir, float ConeHalfAngleRadians );
native			static final function	vector	VRandCone2	( vector Dir, float HorizontalConeHalfAngleRadians, float VerticalConeHalfAngleRadians );
native			static final function	vector	VRandCone3	( vector Dir, float HorizontalConeHalfAngleRadians, float VerticalConeHalfAngleRadians, float RandU, float RandV );
native(300)		static final function	vector	MirrorVectorByNormal( vector InVect, vector InNormal );
native(1500)	static final function	Vector	ProjectOnTo( Vector x, Vector y );
native(1501)	static final function	bool	IsZero( Vector A );
native      	static final function	bool	RayPlaneIntersection( Vector RayOrigin, Vector RayDirection, Plane PlaneToProjectOn, out Vector ProjectedPoint );

/**
 * Tries to reach Target based on distance from Current position,
 * giving a nice smooth feeling when tracking a location.
 * (Doesn't work well when target teleports)
 *
 * @param		Current			Actual location
 * @param		Target			Target location
 * @param		DeltaTime		time since last tick
 * @param		InterpSpeed		Interpolation speed
 * @return		new interpolated position
 */

native static final function vector VInterpTo( vector Current, vector Target, float DeltaTime, float InterpSpeed );

/** Clamps a vector to not be longer than MaxLength. */
native static final function vector ClampLength( vector V, float MaxLength );

/** Returns dot product of two vectors while ignoring the Z component. */
native static final function float NoZDot( vector A, vector B );

simulated final function bool InCylinder( Vector Origin, Rotator Dir, float Width, Vector A, optional bool bIgnoreZ )
{
	local Vector B;
	local Vector VDir;

	if( bIgnoreZ )
	{
		Origin.Z  = 0;
		Dir.Pitch = 0;
		A.Z		  = 0;
	}

	VDir = Vector(Dir);
	B	 = (((A - Origin) DOT VDir) * VDir) + Origin;

	if( VSizeSq(B-A) <= Width * Width )
	{
		return TRUE;
	}

	return FALSE;
}

//
// Rotator operators and functions.
//

native(142) static final operator(24) bool		==  ( rotator A, rotator B );
native(203) static final operator(26) bool		!=  ( rotator A, rotator B );
native(287) static final operator(16) rotator	*   ( rotator A, float    B );
native(288) static final operator(16) rotator	*   ( float    A, rotator B );
native(289) static final operator(16) rotator	/   ( rotator A, float    B );
native(290) static final operator(34) rotator	*=  ( out rotator A, float B  );
native(291) static final operator(34) rotator	/=  ( out rotator A, float B  );
native(316) static final operator(20) rotator	+   ( rotator A, rotator B );
native(317) static final operator(20) rotator	-   ( rotator A, rotator B );
native(318) static final operator(34) rotator	+=  ( out rotator A, rotator B );
native(319) static final operator(34) rotator	-=  ( out rotator A, rotator B );
native		static final operator(24) bool		ClockwiseFrom( int A, int B );

native(229) static final function			GetAxes( rotator A, out vector X, out vector Y, out vector Z );
native(230) static final function					GetUnAxes( rotator A, out vector X, out vector Y, out vector Z );
native      static final function			vector  GetRotatorAxis( rotator A, int Axis );
native(320) static final function	Rotator	RotRand( optional bool bRoll );
native      static final function			Rotator	OrthoRotation( vector X, vector Y, vector Z );
native      static final function			Rotator	Normalize( rotator Rot );
native		static final function			Rotator	RLerp( Rotator A, Rotator B, float Alpha, optional bool bShortestPath );
/** Given rotation R in the space defined by RBasis, return R in "world" space */
native		static final function			Rotator RTransform(rotator R, rotator RBasis);


/**
 * Tries to reach Target based on distance from Current position,
 * giving a nice smooth feeling when tracking a position.
 * (Doesn't work well when target teleports)
 *
 * @param		Current			Actual position
 * @param		Target			Target position
 * @param		DeltaTime		time since last tick
 * @param		InterpSpeed		Interpolation speed, if !bConstantInterpSpeed will perform a continuous lerp, otherwise will interp at constant speed
 * @return		new interpolated position
 */

native static final function Rotator RInterpTo( rotator Current, rotator Target, float DeltaTime, float InterpSpeed, optional bool bConstantInterpSpeed );


/**
 * Returns a Rotator axis within the [-32768,+32767] range in float
 *
 * @param	RotAxis, axis of the rotator
 * @return	Normalized axis value, within the [-32768,+32767] range.
 */
native static final function int NormalizeRotAxis(int Angle);


/** Gives the rotation difference between two Rotators, taking the shortest route between them (in degrees). */
native static final function float RDiff( Rotator A, Rotator B );

/**
 * returns Rotator Size (vector definition applied to rotators)
 * @param	Rotator		R
 * @returns mathematical vector length: Sqrt(Pitch^2 + Yaw^2 + Roll^2)
 */

native static final function float RSize(rotator R);



/**
 * Clamp a rotation Axis.
 * The ViewAxis rotation component must be normalized (within the [-32768,+32767] range).
 * This function will set out_DeltaViewAxis to the delta needed to bring ViewAxis within the [MinLimit,MaxLimit] range.
 *
 * @param	ViewAxis			Rotation Axis to clamp
 * @input	out_DeltaViewAxis	Delta Rotation Axis to be added to ViewAxis rotation (from ProcessViewRotation).
 *								Set to be the Delta to bring ViewAxis within the [MinLimit,MaxLimit] range.
 * @param	MaxLimit			Maximum for Clamp. ViewAxis will not exceed this.
 * @param	MinLimit			Minimum for Clamp. ViewAxis will not go below this.
 */

static final simulated function ClampRotAxis
(
		int		ViewAxis,
	out int		out_DeltaViewAxis,
		int		MaxLimit,
		int		MinLimit
)
{
	local int	DesiredViewAxis;

	ViewAxis		= NormalizeRotAxis( ViewAxis );
	DesiredViewAxis = ViewAxis + out_DeltaViewAxis;

	if( DesiredViewAxis > MaxLimit )
	{
		DesiredViewAxis = MaxLimit;
	}

	if( DesiredViewAxis < MinLimit )
	{
		DesiredViewAxis = MinLimit;
	}

	out_DeltaViewAxis = DesiredViewAxis - ViewAxis;
}

/**
 * Clamp Rotator Axis.
 *
 * @param Current	Input axis angle.
 * @param Center	Center of allowed angle.
 * @param MaxDelta	Maximum delta allowed.
 * @return axis angle clamped between [Center-MaxDelta, Center+MaxDelta]
 */
static final simulated function int ClampRotAxisFromBase(int Current, int Center, int MaxDelta)
{
	local int DeltaFromCenter;

	DeltaFromCenter = NormalizeRotAxis(Current - Center);

	if( DeltaFromCenter > MaxDelta )
	{
		Current	= Center + MaxDelta;
	}
	else if( DeltaFromCenter < -MaxDelta )
	{
		Current	= Center - MaxDelta;
	}

	return Current;
};


/**
 * Clamp Rotator Axis.
 *
 * @param Current	Input axis angle.
 * @param Min		Min allowed angle.
 * @param Max		Max allowed angle.
 * @return axis angle clamped between [Min, Max]
 */
static final simulated function int ClampRotAxisFromRange(int Current, int Min, int Max)
{
	local int Delta, Center;

	Delta = NormalizeRotAxis(Max - Min) / 2;
	Center = NormalizeRotAxis(Max + Min) / 2;

	return ClampRotAxisFromBase(Current, Center, Delta);
};


/**
 * Smooth clamp a rotator axis.
 * This is mainly used to bring smoothly a rotator component within a certain range [MinLimit,MaxLimit].
 * For example to limit smoothly the player's ViewRotation Pitch or Yaw component.
 *
 * @param	fDeltaTime			Elapsed time since this function was last called, for interpolation.
 * @param	ViewAxis			Rotator's Axis' current angle.
 * @input	out_DeltaViewAxis	Delta Value of Axis to be added to ViewAxis (through PlayerController::ProcessViewRotation().
 *								This value gets modified.
 * @param	MaxLimit			Up angle limit.
 * @param	MinLimit			Negative angle limit (value must be negative)
 * @param	InterpolationSpeed	Interpolation Speed to bring ViewAxis within the [MinLimit,MaxLimit] range.
 */

static final simulated function bool SClampRotAxis
(
		float	DeltaTime,
		int		ViewAxis,
	out int		out_DeltaViewAxis,
		int		MaxLimit,
		int		MinLimit,
		float	InterpolationSpeed
)
{
	local bool bClamped;

	// make sure rotation components are normalized
	out_DeltaViewAxis	= NormalizeRotAxis( out_DeltaViewAxis );
	ViewAxis			= NormalizeRotAxis( ViewAxis );

	// forbid player from going beyond limits through fDeltaViewAxis
	if( ViewAxis <= MaxLimit && (ViewAxis + out_DeltaViewAxis) >= MaxLimit )
	{
		out_DeltaViewAxis = MaxLimit - ViewAxis;
		bClamped = TRUE;
	}
	else if( ViewAxis > MaxLimit )
	{
		// if players goes counter interpolation, ignore input
		if( out_DeltaViewAxis > 0 )
		{
			out_DeltaViewAxis = 0.f;
		}
		// if above limit, interpolate back to within limits
		if( (ViewAxis + out_DeltaViewAxis) > MaxLimit )
		{
			out_DeltaViewAxis = FInterpTo(ViewAxis, MaxLimit, DeltaTime, InterpolationSpeed ) - ViewAxis - 1;
		}
	}
	// forbid player from going beyond limits through fDeltaViewAxis
	else if( ViewAxis >= MinLimit && (ViewAxis + out_DeltaViewAxis) <= MinLimit )
	{
		out_DeltaViewAxis = MinLimit - ViewAxis;
		bClamped = TRUE;
	}
	else if( ViewAxis < MinLimit )
	{
		// if players goes counter interpolation, ignore input
		if( out_DeltaViewAxis < 0 )
		{
			out_DeltaViewAxis = 0.f;
		}
		// if above limit, interpolate back to within limits
		if( (ViewAxis + out_DeltaViewAxis) < MinLimit )
		{
			out_DeltaViewAxis += FInterpTo(ViewAxis, MinLimit, DeltaTime, InterpolationSpeed ) - ViewAxis + 1;
		}
	}
	return bClamped;
}

/** Create a Rotation from independant Pitch, Yaw, Roll */
static final function Rotator MakeRotator(int Pitch, int Yaw, int Roll)
{
	local rotator R;

	R.Pitch = Pitch;
	R.Yaw = Yaw;
	R.Roll = Roll;
	return R;
}

//
// String operators.
//

native(112) static final operator(40) string $  ( coerce string A, coerce string B );
native(168) static final operator(40) string @  ( coerce string A, coerce string B );
native(115) static final operator(24) bool   <  ( string A, string B );
native(116) static final operator(24) bool   >  ( string A, string B );
native(120) static final operator(24) bool   <= ( string A, string B );
native(121) static final operator(24) bool   >= ( string A, string B );
native(122) static final operator(24) bool   == ( string A, string B );
native(123) static final operator(26) bool   != ( string A, string B );
native(124) static final operator(24) bool   ~= ( string A, string B );
native(322) static final operator(44) string $= ( out	 string A, coerce string B );
native(323) static final operator(44) string @= ( out    string A, coerce string B );
native(324) static final operator(45) string -= ( out    string A, coerce string B );


//
// String functions.
//

native(125) static final function int    Len    ( coerce string S );
native(126) static final function int    InStr  ( coerce string S, coerce string t, optional bool bSearchFromRight, optional bool bIgnoreCase, optional int StartPos );
native(127) static final function string Mid    ( coerce string S, int i, optional int j );
native(128) static final function string Left   ( coerce string S, int i );
native(234) static final function string Right  ( coerce string S, int i );
native(235) static final function string Caps   ( coerce string S );
native(238) static final function string Locs	( coerce string S);
native(236) static final function string Chr    ( int i );
native(237) static final function int    Asc    ( string S );
native(201) static final function string Repl	( coerce string Src, coerce string Match, coerce string With, optional bool bCaseSensitive );

/**
 * Splits Text on the first Occurrence of Split and returns the remaining
 * part of Text.
 */
static final function string Split(coerce string Text, coerce string SplitStr, optional bool bOmitSplitStr)
{
	local int pos;
	pos = InStr(Text,SplitStr);
	if (pos != -1)
	{
		if (bOmitSplitStr)
		{
			return Mid(Text,pos+Len(SplitStr));
		}
		return Mid(Text,pos);
	}
	else
	{
		return Text;
	}
}

/** Get right most number from an actor name (ie Text == "CoverLink_45" returns "45") */
static final function string GetRightMost( coerce string Text )
{
	local int Idx;
	Idx = InStr(Text,"_");
	while (Idx != -1)
	{
		Text = Mid(Text,Idx+1,Len(Text));
		Idx = InStr(Text,"_");
	}
	return Text;
}

/**
 * Create a single string from an array of strings, using the delimiter specified, optionally ignoring blank members
 *
 * @param	StringArray		the array of strings to join into the single string
 * @param	out_Result		[out] will contain a single string containing all elements of the array, separated by the delimiter specified
 * @param	Delim			the delimiter to insert where array elements are concatenated
 * @param	bIgnoreBlanks	TRUE to skip elements which contain emtpy strings
 */
static final function JoinArray(array<string> StringArray, out string out_Result, optional string delim = ",", optional bool bIgnoreBlanks = true)
{
	local int i;

	out_Result = "";
	for (i = 0; i < StringArray.Length; i++)
	{
		if ( (StringArray[i] != "") || (!bIgnoreBlanks) )
		{
			if (out_Result != "" || (!bIgnoreBlanks && i > 0) )
				out_Result $= delim;

			out_Result $= StringArray[i];
		}
	}
}

/**
 * Breaks up a delimited string into elements of a string array.
 *
 * @param BaseString - The string to break up
 * @param Pieces - The array to fill with the string pieces
 * @param Delim - The string to delimit on
 * @param bCullEmpty - If true, empty strings are not added to the array
 */
native static final function ParseStringIntoArray(string BaseString, out array<string> Pieces, string Delim, bool bCullEmpty);

/**
 * Wrapper for splitting a string into an array of strings using a single expression.
 */
static final function array<string> SplitString( string Source, optional string Delimiter=",", optional bool bCullEmpty )
{
	local array<string> Result;
	ParseStringIntoArray(Source, Result, Delimiter, bCullEmpty);
	return Result;
}

/**
 * Returns the full path name of the specified object (including package and groups), ie CheckObject::GetPathName().
 */
native static final function string PathName(Object CheckObject);


//
// Object operators and functions.
//

native(114) static final operator(24) bool == ( Object A, Object B );
native(119) static final operator(26) bool != ( Object A, Object B );

native		static final operator(24) bool == ( Interface A, Interface B );
native		static final operator(26) bool != ( Interface A, Interface B );

/**
 * Determine if a class is a child of another class.
 *
 * @return	TRUE if TestClass == ParentClass, or if TestClass is a child of ParentClass; FALSE otherwise, or if either
 *			the value for either parameter is 'None'.
 */
native(258) static final function bool ClassIsChildOf( class TestClass, class ParentClass );
native(197) final function bool IsA( name ClassName );


//
// Name operators.
//

native(254) static final operator(24) bool == ( name A, name B );
native(255) static final operator(26) bool != ( name A, name B );

//
//	Matrix operators and functions
//
native		static final operator(34) matrix	*	(Matrix A, Matrix B);

native		static final function	vector	TransformVector(Matrix TM, vector A);
native		static final function	vector	InverseTransformVector(Matrix TM, vector A);
native		static final function	vector	TransformNormal(Matrix TM, vector A);
native		static final function	vector	InverseTransformNormal(Matrix TM, vector A);
native		static final function	matrix	MakeRotationTranslationMatrix(vector Translation, Rotator Rotation);
native		static final function	matrix	MakeRotationMatrix(Rotator Rotation);
native		static final function	rotator	MatrixGetRotator(Matrix TM);
native		static final function	vector	MatrixGetOrigin(Matrix TM);
native		static final function	vector	MatrixGetAxis(Matrix TM, EAxis Axis);

//
// Quaternion functions
//

native		static final function Quat QuatProduct( Quat A, Quat B );
native		static final function float QuatDot( Quat A, Quat B );
native		static final function Quat QuatInvert( Quat A );
native		static final function vector QuatRotateVector( Quat A, vector B );
native		static final function Quat QuatFindBetween( Vector A, Vector B );
native		static final function Quat QuatFromAxisAndAngle( Vector Axis, Float Angle );
native		static final function Quat QuatFromRotator( rotator A );
native		static final function rotator QuatToRotator( Quat A );
native		static final function Quat QuatSlerp( Quat A, Quat B, float Alpha, optional bool bShortestPath );

native(270)	static final operator(16)	Quat +	(Quat A, Quat B);
native(271)	static final operator(16)	Quat -	(Quat A, Quat B);

//
// Vector2D functions
//

native		static final operator(16)	vector2d +	(vector2d A, vector2d B);
native		static final operator(16)	vector2d -	(vector2d A, vector2d B);
native      static final operator(16)   vector2d *  (vector2d A, float B);
native      static final operator(16)   vector2d /  (vector2d A, float B );
native      static final operator(34)   vector2d *= (out vector2d A, float B);
native      static final operator(34)   vector2d /= (out vector2d A, float B);
native      static final operator(34)   vector2d += (out vector2d A, vector2d B);
native	    static final operator(34)   vector2d -= (out vector2d A, vector2d B);

// EPIC ORIG CODE
// native		static final operator(16)	vector2d +	(vector2d A, vector2d B);
// native		static final operator(16)	vector2d -	(vector2d A, vector2d B);

//Firaxis Change: JW START
native(2511) static final preoperator  vector2D -     ( vector2D A );
native(2513) static final operator(16) vector2D *     ( float A, vector2D B );
native(2596) static final operator(16) vector2D *     ( vector2D A, vector2D B );
native(2517) static final operator(24) bool   ==    ( vector2D A, vector2D B );
native(2518) static final operator(26) bool   !=    ( vector2D A, vector2D B );
native(2597) static final operator(34) vector2D *=    ( out vector2D A, vector2D B );

//
// Vector functions.
//

native(2525)	static final function	float	    V2DSize		( vector2D A );
native			static final function	float	    V2DSizeSq	( vector2D A );
native(2526)	static final function	vector2D	V2DNormal	( vector2D A );
native			static final function	vector2D	V2DLerp		( vector2D A, vector2D B, float Alpha );
// FIRAXIS END


/**
 * Returns the value in the Range, relative to Pct.
 * Examples:
 * - GetRangeValueByPct( Range, 0.f ) == Range.X
 * - GetRangeValueByPct( Range, 1.f ) == Range.Y
 * - GetRangeValueByPct( Range, 0.5 ) == (Range.X+Range.Y)/2
 *
 * @param	Range	Range of values. [Range.X,Range.Y]
 * @param	Pct		Relative position in range in percentage. [0,1]
 *
 * @return	the value in the Range, relative to Pct.
 */
static final simulated function float GetRangeValueByPct( Vector2D Range, float Pct )
{
	return ( Range.X + (Range.Y-Range.X) * Pct );
}


/**
 * Returns the relative percentage position Value is in the Range.
 * Examples:
 * - GetRangeValueByPct( Range, Range.X ) == 0
 * - GetRangeValueByPct( Range, Range.Y ) == 1
 * - GetRangeValueByPct( Range, (Range.X+Range.Y)/2 ) == 0.5
 *
 * @param	Range	Range of values. [Range.X,Range.Y]
 * @param	Value	Value between Range.
 *
 * @return	relative percentage position Value is in the Range.
 */
static final simulated function float GetRangePctByValue( Vector2D Range, float Value )
{
	return (Range.Y == Range.X) ? Range.X : (Value - Range.X) / (Range.Y - Range.X);
}

/**
 * Useful for mapping a value in one value range to a different value range.  Output is clamped to the OutputRange.
 * e.g. given that velocities [50..100] correspond to a sound volume of [0.2..1.4], find the
 *      volume for a velocity of 77.
 */
static final simulated native function float GetMappedRangeValue(vector2d InputRange, vector2d OutputRange, float Value);


/** Construct a vector2d variable */
static final function vector2d	vect2d( float InX, float InY )
{
	local vector2d	NewVect2d;

	NewVect2d.X = InX;
	NewVect2d.Y = InY;
	return NewVect2d;
}

/** Evaluate a float curve for an input of InVal */
native static final function float EvalInterpCurveFloat(InterpCurveFloat FloatCurve, float InVal);
/** Evaluate a vector curve for an input of InVal */
native static final function vector EvalInterpCurveVector(InterpCurveVector VectorCurve, float InVal);
/** Evaluate a vector2D curve for an input of InVal */
native static final function vector2D EvalInterpCurveVector2D(InterpCurveVector2D Vector2DCurve, float InVal);

//
// Color functions
//

static final operator(20) color - (color A, color B)
{
	A.R -= B.R;
	A.G -= B.G;
	A.B -= B.B;
	return A;
}

static final operator(16) color * (float A, color B)
{
	B.R *= A;
	B.G *= A;
	B.B *= A;
	return B;
}

static final operator(16) color * (color A, float B)
{
	A.R *= B;
	A.G *= B;
	A.B *= B;
	return A;
}

static final operator(20) color + (color A, color B)
{
	A.R += B.R;
	A.G += B.G;
	A.B += B.B;
	return A;
}

/** Create a Color from independant RGBA components */
static final function Color MakeColor(byte R, byte G, byte B, optional byte A)
{
	local Color C;

	C.R = R;
	C.G = G;
	C.B = B;
	C.A = A;
	return C;
}

/** Util to interpolate between two colors */
static final function Color LerpColor(Color A, Color B, float Alpha)
{
	local vector FloatA, FloatB, FloatResult;
	local float AlphaA, AlphaB, FloatResultAlpha;
	local color Result;
	
	FloatA.X = A.R;
	FloatA.Y = A.G;
	FloatA.Z = A.B;
	AlphaA = A.A;
	
	FloatB.X = B.R;
	FloatB.Y = B.G;
	FloatB.Z = B.B;
	AlphaB = B.A;
	
	FloatResult = FloatA + ((FloatB - FloatA) * FClamp(Alpha, 0.0, 1.0));
	FloatResultAlpha = AlphaA + ((AlphaB - AlphaA) * FClamp(Alpha, 0.0, 1.0));
	
	Result.R = FloatResult.X;
	Result.G = FloatResult.Y;
	Result.B = FloatResult.Z;
	Result.A = FloatResultAlpha;

	return Result;
}

//
// Linear Color Functions
//

/** Create a LinearColor from independant RGBA components. */
static final function LinearColor	MakeLinearColor( float R, float G, float B, float A )
{
	local LinearColor	LC;

	LC.R = R;
	LC.G = G;
	LC.B = B;
	LC.A = A;
	return LC;
}

/** converts a color to a LinearColor
 * @param OldColor the color to convert
 * @return the matching LinearColor
 */
static final function LinearColor ColorToLinearColor(color OldColor)
{
	return MakeLinearColor(float(OldColor.R) / 255.0, float(OldColor.G) / 255.0, float(OldColor.B) / 255.0, float(OldColor.A) / 255.0);
}

static final function LinearColor sRGBColorToLinearColor(color OldColor)
{
	return MakeLinearColor( (float(OldColor.R) / 255.0) ** 2.2, (float(OldColor.G) / 255.0) ** 2.2, (float(OldColor.B) / 255.0) ** 2.2, (float(OldColor.A) / 255.0) ** 2.2);
}

/** multiply the RGB components of a LinearColor by a float */
static final operator(16) LinearColor * (LinearColor LC, float Mult)
{
	LC.R *= Mult;
	LC.G *= Mult;
	LC.B *= Mult;
	return LC;
}

/** subtract the RGB components of B from the RGB components of A */
static final operator(20) LinearColor - (LinearColor A, LinearColor B)
{
	A.R -= B.R;
	A.G -= B.G;
	A.B -= B.B;
	return A;
}

//=============================================================================
// General functions.


// this define allows us to detect code that is directly calling functions that should only be called through a macro, such as
// LogInternal & WarnInternal
`if(`isdefined(FINAL_RELEASE))
	`if(`isdefined(FINAL_RELEASE_DEBUGCONSOLE))
	`define	prevent_direct_calls
	`else
	`define	prevent_direct_calls	private
	`endif
`else
	`define	prevent_direct_calls
`endif

//
// Logging.
//
/**
 * Writes a message to the log.  This function should never be called directly - use the `log macro instead, which has the following signature:
 *
 * log( coerce string Msg, optional bool bCondition=true, optional name LogTag='ScriptLog' );
 *
 * @param	Msg				the string to print to the log
 * @param	bCondition		if specified, the message is only printed to the log if this condition is satisfied.
 * @param	LogTag			if specified, the message will be prepended with this tag in the log file
 *
 */
native(231) final static `{prevent_direct_calls} function LogInternal( coerce string S, optional name Tag );

/**
 * Same as calling LogInternal(SomeMsg, 'Warning');  This function should never be called directly - use the `warn macro instead, which has the following signature:
 *
 * warn( coerce string Msg, optional bool bCondition=true );
 */
native(232) final static `{prevent_direct_calls} function WarnInternal( coerce string S );

native static function string Localize( string SectionName, string KeyName, string PackageName );

/** given a path to a localized key of the form "Package.Section.Name",
 * return the appropriate value from the localization file for the current language
 */
static final function string ParseLocalizedPropertyPath(string PathName)
{
	local array<string> Pieces;

	ParseStringIntoArray(PathName, Pieces, ".", false);
	if (Pieces.length >= 3)
	{
		return Localize(Pieces[1], Pieces[2], Pieces[0]);
	}
	else
	{
		return "";
	}
}

/**
 * Dumps the current script function stack to the log file, useful
 * for debugging.
 */
native static final function ScriptTrace();


/**
 * Gets the current script function stack back so you can log it to a specific log location (e.g. AILog).
 */
native static final function String GetScriptTrace();


/**
 * Script-induced breakpoint.  Useful for examining state with the debugger at a particular point in script.
 *
 * @param	UserFlags		user-defined flags to be used for e.g. indentifying different calls to DebugBreak in the same session
 * @param	DebuggerType	C++ debugger, UScript debugger, or both
 */
native static final function DebugBreak( optional int UserFlags, optional EDebugBreakType DebuggerType=DEBUGGER_NativeOnly );

/**
 * Returns the current calling function's name, useful for
 * debugging.
 */

native static final function Name GetFuncName();

/**
 * Enables/disables script function call trace logging.
 */
native static final function SetUTracing( bool bShouldUTrace );

/**
 * Returns whether script function call trace logging is currently enabled.
 */
native static final function bool IsUTracing();


//
// Goto state and label.
//

/**
 * Transitions to the desired state and label if specified,
 * generating the EndState event in the current state if applicable
 * and BeginState in the new state, unless transitioning to the same
 * state.
 *
 * @param	NewState - new state to transition to
 *
 * @param	Label - optional Label to jump to
 *
 * @param	bForceEvents - optionally force EndState/BeginState to be
 * 			called even if transitioning to the same state.
 *
 * @param	bKeepStack - prevents state stack from being cleared
 */

native(113) final function GotoState( optional name NewState, optional name Label, optional bool bForceEvents, optional bool bKeepStack );


/**
 * Checks the current state and determines whether or not this object
 * is actively in the specified state.  Note: This does work with
 * inherited states.
 *
 * @param	TestState - state to check for
 * @param	bTestStateStack - check the state stack? (does *NOT* work with inherited states in the stack)
 *
 * @return	True if currently in TestState
 */

native(281) final function bool IsInState( name TestState, optional bool bTestStateStack );


/**
 * Returns true if TestState derives from TestParentState.
 */

native final function bool IsChildState(Name TestState, Name TestParentState);


/**
 * Returns the current state name, useful for determining current
 * state similar to IsInState.  Note:  This *doesn't* work with
 * inherited states, in that it will only compare at the lowest
 * state level.
 *
 * @return	Name of the current state
 */

native(284) final function name GetStateName();


/**
 * Pushes the new state onto the state stack, setting it as the
 * current state until a matching PopState() is called.  Note that
 * multiple states may be pushed on top of each other.
 * You may not push the same state multiple times.
 *
 * This will call PushedState when entering the state that was just
 * pushed on the state stack.  It will not call BeginState.
 * @see event PushedState
 * @see event ContinuedState
 *
 * @param	NewState - name of the state to push on the stack
 *
 * @param	NewLabel - optional name of the state label to jump to
 */

native final function PushState(Name NewState, optional Name NewLabel);


/**
 * Pops the current pushed state, returning execution to the previous
 * state at the same code point.  Note: PopState() will have no effect
 * if no state has been pushed onto the stack.
 *
 * This will call PoppedState when entering the state that was just
 * pushed on the state stack.  It will not call EndState.
 * @see event PoppedState
 * @see event PausedState
 *
 * @param	bPopAll - optionally pop all states on the stack to the
 * 			originally executing one
 */

native final function PopState(optional bool bPopAll);


/**
 * Logs the current state stack for debugging purposes.
 */

native final function DumpStateStack();



//
// State notification events
//

/**
 * Called immediately when entering a state, while within the
 * GotoState() call that caused the state change (before any
 * state code is executed).
 */
event BeginState(Name PreviousStateName);

/**
 * Called immediately before going out of the current state, while
 * within the GotoState() call that caused the state change, and
 * before BeginState() is called within the new state.
 */
event EndState(Name NextStateName);

/**
 * Called immediately in the new state that was pushed onto the
 * state stack, before any state code is executed.
 */
event PushedState();

/**
 * Called immediately in the current state that is being popped off
 * of the state stack, before the new state is activated.
 */
event PoppedState();

/**
 * Called on the state that is being paused because of a PushState().
 */
event PausedState();

/**
 * Called on the state that is no longer paused because of a PopState().
 */
event ContinuedState();



//
// Probe messages.
//

native(117) final function Enable( name ProbeFunc );
native(118) final function Disable( name ProbeFunc );


//
// Object handling.
//

native static final function name GetEnum( object E, coerce int i );
native static final function object DynamicLoadObject( string ObjectName, class ObjectClass, optional bool MayFail );
native static final function object FindObject( string ObjectName, class ObjectClass );


//
// Configuration.
//

native(536) final function SaveConfig();
native static final function StaticSaveConfig();

/*
/**
 * Saves the current value for all configurable properties in this object to the .ini file.  The values for any global config
 * properties will be propagated to all child classes.
 *
 * @param	bRefreshInstances	if TRUE, all instances of this class will re-load the values for their configurable properties
 *								from the .ini.  THIS WILL CLOBBER ANY EXISTING VALUES!
 * @param	PropertyName		if specified, only this property's value will be saved.
 */
native(536) final function SaveConfig( optional bool bRefreshInstances, optional string PropertyName );

/**
 * Saves the default values for all configurable properties in this object's class to the .ini file.  The values for any global config
 * properties will be propagated to all child classes.
 *
 * @param	bRefreshInstances	if TRUE, all instances of this class will re-load the values for their configurable properties
 *								from the .ini.  THIS WILL CLOBBER ANY EXISTING VALUES!
 * @param	PropertyName		if specified, only this property's value will be saved.
 */
native static final function StaticSaveConfig( optional bool bRefreshInstances, optional string PropertyName );

/**
 * Resets the values for configurable properties in this object's class back to the values in the corresponding Default*.ini file.
 *
 * @param	bRefreshInstances	if TRUE, all instances of this class will re-load the values for their configurable properties
 *								from the .ini.  THIS WILL CLOBBER ANY EXISTING VALUES!
 * @param	PropertyName		if specified, only this property's value will be reset.
 */
native static final function ResetConfig( optional bool bRefreshInstances, optional string PropertyName );

/**
 * Removes the values for all configurable properties in this object's class from the .ini file.
 *
 * @param	PropertyName		if specified, only this property's value will be removed.
 */
native(537) final function ClearConfig( optional string PropertyName );

/**
 * Removes the values for all configurable properties in this object's class from the .ini file.
 *
 * @param	PropertyName		if specified, only this property's value will be removed.
 */
native static final function StaticClearConfig( optional string PropertyName );
*/

/**
 * Retrieve the names of sections which contain data for the specified PerObjectConfig class.
 *
 * @param	SearchClass			the PerObjectConfig class to retrieve sections for.
 * @param	out_SectionNames	will receive the list of section names that correspond to PerObjectConfig sections of the specified class
 * @param	ObjectOuter			the Outer to use for determining which file to look in.  Specify the same object that is used when creating the PerObjectConfig
 *								objects that sections are being retrieved for. (PerObjectConfig data is generally stored in a file named after the Outer used when
 *								creating those objects, unless the PerObjectConfig class specifies a config file in its class declaration);
 *								specify None to use the transient package as the Outer.
 * @param	MaxResults			the maximum number of section names to retrieve
 *
 * @return	TRUE if the file specified was found and it contained at least 1 section for the specified class
 */
native static final function bool GetPerObjectConfigSections( class SearchClass, out array<string> out_SectionNames, optional Object ObjectOuter, optional int MaxResults=1024 );


//
// Maths
//

/**
 * Calculates the distance of a given Point in world space to a given line,
 * defined by the vector couple (Origin, Direction).
 *
 * @param	Point				point to check distance to Axis
 * @param	Line				unit vector indicating the direction to check against
 * @param	Origin				point of reference used to calculate distance
 * @param	OutClosestPoint		optional point that represents the closest point projected onto Axis
 *
 * @return	distance of Point from line defined by (Origin, Direction)
 */
native final function float PointDistToLine(vector Point, vector Line, vector Origin, optional out vector OutClosestPoint);

/**
 * Returns closest distance from a point to a segment.
 *
 * @param	Point			point to check distance for
 * @param	StartPoint		StartPoint of segment
 * @param	EndPoint		EndPoint of segment
 * @param	OutClosestPoint	Closest point on segment.
 *
 * @return	closest distance from Point to segment defined by (StartPoint, EndPoint).
 */
native final function float PointDistToSegment(Vector Point, Vector StartPoint, Vector EndPoint, optional out Vector OutClosestPoint);

/**
 * Calculates the distance of a given point to the given plane. (defined by a combination of vector and rotator)
 * Rotator.AxisX = U, Rotator.AxisY = Normal, Rotator.AxisZ = V
 *
 * @param	Point				Point to check distance to Orientation
 * @param	Orientation			Rotator indicating the direction to check against
 * @param	Origin				Point of reference used to calculate distance
 * @param	out_ClosestPoint	Optional point that represents the closest point projected onto Plane defined by the couple (Origin, Orientation)
 *
 * @return	distance of Point to plane
 */

simulated final function float PointDistToPlane( Vector Point, Rotator Orientation, Vector Origin, optional out vector out_ClosestPoint )
{
	local vector	AxisX, AxisY, AxisZ, PointNoZ, OriginNoZ;
	local float		fPointZ, fProjDistToAxis;

	// Get orientation axis'
	GetAxes(Orientation, AxisX, AxisY, AxisZ);

	// Remove Z component of Point Location
	fPointZ		= Point dot AxisZ;
	PointNoZ	= Point - fPointZ * AxisZ;

	// Remove Z component of Origin
	OriginNoZ	= Origin - (Origin dot AxisZ) * AxisZ;

	// Projected distance of Point onto AxisX.
	fProjDistToAxis		= (PointNoZ - OriginNoZ) Dot AxisX;
	out_ClosestPoint	= OriginNoZ + fProjDistToAxis * AxisX + fPointZ * AxisZ;

	// return distance to closest point
	return VSize(out_ClosestPoint-Point);
}


/**
* Calculates a point's projection onto a plane
* @param	Point	point to project onto the plane
* @param	A		point on plane
* @param	B		point on plane
* @param	C		point on plane
* @return	projection of point onto the plane defined by ABC
*/
native static final function Vector PointProjectToPlane(Vector Point, Vector A, Vector B, Vector C);

/**
 * Calculates the dotted distance of vector 'Direction' to coordinate system O(AxisX,AxisY,AxisZ).
 *
 * Orientation: (consider 'O' the first person view of the player, and 'Direction' a vector pointing to an enemy)
 * - positive azimuth means enemy is on the right of crosshair. (negative means left).
 * - positive elevation means enemy is on top of crosshair, negative means below.
 *
 * @Note: 'Azimuth' (.X) sign is changed to represent left/right and not front/behind. front/behind is the funtion's return value.
 *
 * @param	OutDotDist	.X = 'Direction' dot AxisX relative to plane (AxisX,AxisZ). (== Cos(Azimuth))
 *						.Y = 'Direction' dot AxisX relative to plane (AxisX,AxisY). (== Sin(Elevation))
 * @param	Direction	direction of target.
 * @param	AxisX		X component of reference system.
 * @param	AxisY		Y component of reference system.
 * @param	AxisZ		Z component of reference system.
 *
 * @return	true if 'Direction' is facing AxisX (Direction dot AxisX >= 0.f)
 */

native static final function bool GetDotDistance
(
	out	Vector2D	OutDotDist,
		Vector		Direction,
		Vector		AxisX,
		Vector		AxisY,
		Vector		AxisZ
);

/**
 * Calculates the angular distance of vector 'Direction' to coordinate system O(AxisX,AxisY,AxisZ).
 *
 * Orientation: (consider 'O' the first person view of the player, and 'Direction' a vector pointing to an enemy)
 * - positive azimuth means enemy is on the right of crosshair. (negative means left).
 * - positive elevation means enemy is on top of crosshair, negative means below.
 *
 * @param	out_AngularDist	.X = Azimuth angle (in radians) of 'Direction' vector compared to plane (AxisX,AxisZ).
 *							.Y = Elevation angle (in radians) of 'Direction' vector compared to plane (AxisX,AxisY).
 * @param	Direction		Direction of target.
 * @param	AxisX			X component of reference system.
 * @param	AxisY			Y component of reference system.
 * @param	AxisZ			Z component of reference system.
 *
 * @output	true if 'Direction' is facing AxisX (Direction dot AxisX >= 0.f)
 */
native static final function bool GetAngularDistance
(
	out	Vector2D	OutAngularDist,
		Vector		Direction,
		Vector		AxisX,
		Vector		AxisY,
		Vector		AxisZ
);

/**
 * Converts Dot distance to angular distance.
 * @see	GetAngularDistance() and GetDotDistance().
 *
 * @param	OutAngDist	Angular distance in radians.
 * @param	DotDist		Dot distance.
 */
native static final function GetAngularFromDotDist( out Vector2D OutAngDist, Vector2D DotDist );


/* transforms angular distance in radians to degrees */
static final simulated function GetAngularDegreesFromRadians( out Vector2D OutFOV )
{
	OutFOV.X = OutFOV.X*RadToDeg;
	OutFOV.Y = OutFOV.Y*RadToDeg;
}

/**
 *	Returns world space angle (in radians) of given vector
 *
 *	@param	Dir		Vector to be converted into heading angle
 */
static final simulated function float GetHeadingAngle( Vector Dir )
{
	local float Angle;

	Angle = Acos( FClamp( Dir.X, -1.f, 1.f ) );
	if( Dir.Y < 0.f )
	{
		Angle *= -1.f;
	}

	return Angle;
}

/**
 *	Gets the difference in world space angles in [-PI,PI] range
 *
 *	@param A1	First angle
 *	@param A2	Second angle
 */
static final simulated function float FindDeltaAngle( float A1, float A2 )
{
	local float Delta;

	// Find the difference
	Delta = A2 - A1;
	// If change is larger than PI
	if( Delta > PI )
	{
		// Flip to negative equivalent
		Delta = Delta - (PI * 2.f);
	}
	else if( delta < -PI )
	{
		// Otherwise, if change is smaller than -PI
		// Flip to positive equivalent
		Delta = Delta + (PI * 2.f);
	}

	// Return delta in [-PI,PI] range
	return Delta;
}

static final simulated function float UnwindHeading( float a )
{
	while( a > PI )
	{
		a -= (PI * 2.0f);
	}

	while( a < -PI )
	{
		a += (PI * 2.0f);
	}

	return a;
}


/**
 * Converts a float value to a 0-255 byte, assuming a range of
 * 0.f to 1.f.
 *
 * @param	inputFloat - float to convert
 *
 * @param	bSigned - optional, assume a range of -1.f to 1.f
 *
 * @return	byte value 0-255
 */

simulated final function byte FloatToByte(float inputFloat, optional bool bSigned)
{
	if (bSigned)
	{
		// handle a 0.02f threshold so we can guarantee valid 0/255 values
		if (inputFloat > 0.98f)
		{
			return 255;
		}
		else if (inputFloat < -0.98f)
		{
			return 0;
		}
		else
		{
			return byte((inputFloat+1.f)*128.f);
		}
	}
	else
	{
		if (inputFloat > 0.9961f)
		{
			return 255;
		}
		else if (inputFloat < 0.004f)
		{
			return 0;
		}
		else
		{
			return byte(inputFloat*255.f);
		}
	}
}


/**
 * Converts a 0-255 byte to a float value, to a range of 0.f
 * to 1.f.
 *
 * @param	inputByte - byte to convert
 *
 * @param	bSigned - optional, spit out -1.f to 1.f instead
 *
 * @return	newly converted value
 */

simulated final function float ByteToFloat(byte inputByte, optional bool bSigned)
{
	if( bSigned )
	{
		return ((float(inputByte)/128.f)-1.f);
	}
	else
	{
		return (float(inputByte)/255.f);
	}
}

/**
 * Returns whether the object is pending kill and about to have references to it NULLed by
 * the garbage collector.
 *
 * @return TRUE if object is pending kill, FALSE otherwise
 */
native final function bool IsPendingKill();

/** @return the name of the package this object resides in */
final function name GetPackageName()
{
	local Object O;

	O = self;
	while (O.Outer != None)
	{
		O = O.Outer;
	}
	return O.Name;
}

/**
 * Script hook to FRotationMatrix::TransformFVector().
 */
native final function vector TransformVectorByRotation(rotator SourceRotation, vector SourceVector, optional bool bInverse);


/**
 *   Returns a string containing a system timestamp
 */
native final function string TimeStamp();

/**
 * Return the system time components.
 */
native final function GetSystemTime( out int Year, out int Month, out int DayOfWeek, out int Day, out int Hour, out int Min, out int Sec, out int MSec );

/** @return the current engine version number for this build */
native final function int GetEngineVersion();

/** @return the changelist number that was used when generating this build */
native final function int GetBuildChangelistNumber();

final function int GetRandomOptionSumFrequency( const out array<float> FreqList )
{
	local float FreqSum, RandVal;
	local int Idx;

	for( Idx = 0; Idx < FreqList.Length; Idx++ )
	{
		FreqSum += FreqList[Idx];
	}

	RandVal = FRand() * FreqSum;
	FreqSum = 0;
	for( Idx = 0; Idx < FreqList.Length; Idx++ )
	{
		FreqSum += FreqList[Idx];
		if( RandVal < FreqSum )
		{
			return Idx;
		}
	}

	return -1;
}

/** @return the three character language identifier currently in use */
native static final function string GetLanguage();

// FIRAXIS Psyonix START

// wrap a given value to the min and max values
final static function float WrapF( float Val, float Min, float Max )
{
	if ( Val > Max )
		return WrapF( Min + ( Val - Max ), Min, Max );
	if ( Val < Min )
		return WrapF( Max - ( Min - Val ), Min, Max );
	return Val;
}

final function int WrapIndex( int Val, int Min, int Max )
{
	if( Val >= Max )
		return Min;
	if( Val < Min )
		return Max - 1;

	return Val;
}

final function float GetTweenedRatio( float InRatio, float Power, float TweenWeight )
{
	local float EaseInRate, EaseOutRate;
	
	InRatio = FClamp( InRatio, 0.0f, 1.0f );
	
	EaseInRate = ( InRatio ** Power ) * TweenWeight;
	EaseOutRate = ( 1.0f - ( ( 1.0f - InRatio ) ** 2.0f ) ) * ( 1.0f - TweenWeight );
	return EaseInRate + EaseOutRate;
}

native final function float Sgn( float Value );

/// <summary>
/// Projects a vector onto another vector.
/// </summary>
static final function Vector ProjectVectorOnto( Vector VectorToProject, Vector VectorToProjectOnto)
{
	local Vector NormalVector;

	NormalVector = Normal(VectorToProjectOnto);
	
	return NormalVector * (VectorToProject dot NormalVector);
}

native final function int GenerateUniqueID ();

// FIRAXIS Psyonix END

// FIRAXIS begin -tsmith
native final function NativeOutputDebugString(string strMsg);

native final function bool IsAsyncLoadingWrapper();
// FIRAXIS end -tsmith

// FIRAXIS BEGIN
// RAM - convert this object into a T3D string
native final function string ToStringT3D();

native final function bool IsPointInBox( const out Vector Point, const out Box TheBox );

native final function bool LineBoxIntersection(Box BBox, Vector Start, Vector End, Vector Direction, Vector OneOverDirection, out Vector HitLocation);

defaultproperties
{
}

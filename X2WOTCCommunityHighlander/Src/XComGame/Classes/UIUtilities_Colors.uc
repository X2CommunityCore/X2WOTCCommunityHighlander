//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Text.uc
//  AUTHOR:  bsteiner
//  PURPOSE: Container of static text formatting helpers.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Colors extends Object
	dependson(UIUtilities)
	native;

enum EWidgetColor
{
	// Prefer to use these!
	eColor_Xcom,
	eColor_Alien,       // bad cover
	eColor_Attention,   // flanking, notice in menus
	eColor_Good,
	eColor_Bad,
	eColor_TheLost,

	// Explicity colors (only use if prototyping)
	eColor_White,
	eColor_Black,
	eColor_Red,
	eColor_Green,
	eColor_Blue,
	eColor_Yellow,
	eColor_Orange,
	eColor_Cyan,
	eColor_Purple,
	eColor_Gray
};

enum EColorShade
{
	eShade_Normal,
	eShade_Light,
	eShade_Dark
};

// TAKEN FROM Colors.as - keep in sync - sbatista
const WHITE_HTML_COLOR			= "FFFFFF"; // White 
const BLACK_HTML_COLOR			= "000000"; // Black
const NORMAL_HTML_COLOR			= "9acbcb"; // Cyan
const FADED_HTML_COLOR			= "546f6f"; // Faded Cyan
const HILITE_HTML_COLOR			= "9acbcb"; // Cyan
const HILITE_TEXT_HTML_COLOR	= "000000"; // Black
const HEADER_HTML_COLOR			= "aca68a"; // Faded Yellow
const DISABLED_HTML_COLOR		= "828282"; // Gray
const GOOD_HTML_COLOR			= "53b45e"; // Green
const BAD_HTML_COLOR			= "bf1e2e"; // Red
const WARNING_HTML_COLOR		= "fdce2b"; // Yellow
const PERK_HTML_COLOR			= "fef4cb"; // Perk / Promotion Yellow
const CASH_HTML_COLOR			= "5CD16C"; // Green
const PSIONIC_HTML_COLOR		= "b6b3e3"; // Purple
const WARNING2_HTML_COLOR		= "e69831"; // Orange
const THELOST_HTML_COLOR		= "acd373"; // nasty green color
const ENGINEERING_HTML_COLOR	= "f7941e"; // Orange engineering
const SCIENCE_HTML_COLOR		= "27aae1"; // Blue science 
const OBJECTIVEICON_HTML_COLOR	= "53b45e"; // background of objective icons on the ability hud

const COVERT_OPS_HTML_COLOR      = "3cedd4";
const FACTION_COLOR_REAPER		= "a28752";
const FACTION_COLOR_TEMPLAR		= "b6b3e3"; //Psi purple 
const FACTION_COLOR_SKIRMISHER  = "bf1e2e"; //Bad red

//------------------------------------------------------------

static function string GetColorLabelFromState( int iState )
{
	switch( iState )
	{
	case eUIState_Normal:   return "cyan";
	case eUIState_Bad:      return "red";
	case eUIState_Warning:  return "yellow";
	case eUIState_Warning2: return "orange";
	case eUIState_Good:     return "green";
	case eUIState_Disabled: return "gray";
	case eUIState_Faded:    return "faded"; 
	case eUIState_Psyonic:  return "purple";
	case eUIState_Highlight:return "cyan";
	case eUIState_Header:	return "yellow";
	case eUIState_Cash:		return "green";
	case eUIState_TheLost:	return "lostgreen";
	default:
		`warn("UI ERROR: GetColorLabelFromState - Unsupported UI state '"$iState$"'");
	}
	return "cyan";
}

static function string GetHexColorFromState( int iState )
{
	local string strColor;

	switch( iState )
	{
	case eUIState_Normal:   strColor = NORMAL_HTML_COLOR;   break;
	case eUIState_Bad:      strColor = BAD_HTML_COLOR;      break;
	case eUIState_Warning:  strColor = WARNING_HTML_COLOR;  break;
	case eUIState_Warning2: strColor = WARNING2_HTML_COLOR; break;
	case eUIState_Good:     strColor = GOOD_HTML_COLOR;     break;
	case eUIState_Disabled: strColor = DISABLED_HTML_COLOR; break;
	case eUIState_Psyonic:	strColor = PSIONIC_HTML_COLOR;	break;
	case eUIState_Highlight:strColor = NORMAL_HTML_COLOR;   break;
	case eUIState_Header:	strColor = HEADER_HTML_COLOR;   break;
	case eUIState_Cash:		strColor = CASH_HTML_COLOR;		break;
	case eUIState_Faded:    strColor = FADED_HTML_COLOR;	break;
	case eUIState_TheLost:	strColor = THELOST_HTML_COLOR;	break;
	default:
		`warn("UI ERROR: GetHexColorFromState - Unsupported UI state '"$iState$"'");
		strColor = BLACK_HTML_COLOR; break;
	}

	return "0x" $ strColor;
}

simulated static function string ConvertWidgetColorToHTML( EWidgetColor eColor )
{
	switch( eColor )
	{
	case eColor_Green:
	case eColor_Good:
		return GOOD_HTML_COLOR;

	case eColor_Red:
	case eColor_Bad:
	case eColor_Alien:
		return BAD_HTML_COLOR;

	case eColor_TheLost:
		return THELOST_HTML_COLOR;

	case eColor_Yellow:
	case eColor_Attention:
		return WARNING_HTML_COLOR;

	case eColor_Orange:
		return WARNING2_HTML_COLOR;

	case eColor_Black:
		return BLACK_HTML_COLOR;

	case eColor_Purple:
		return PSIONIC_HTML_COLOR;

	case eColor_Gray:
		return DISABLED_HTML_COLOR;

	case eColor_White:
		return WHITE_HTML_COLOR;

	case eColor_Xcom:
	case eColor_Cyan:
	case eColor_Blue:
	default:
		return NORMAL_HTML_COLOR;
	}
}

static function Color CreateColor( int eColor, EColorShade eShade=eShade_Normal, optional int A=255 )
{
	local Color kNewColor;
	local EWidgetColor eWColor;

	eWColor = EWidgetColor(eColor);

	switch( eWColor )
	{
		case eColor_Xcom:
		kNewColor = MakeColor(154,203,203,A);
		break;
		case eColor_Bad:
		case eColor_Alien:
		kNewColor = MakeColor(191,30,46,A);
		break;
		case eColor_Attention:
		kNewColor = MakeColor(253,206,43,A);
		break;
		case eColor_Good:
		kNewColor = MakeColor(83,180,94,A);
		break;
		case eColor_TheLost:
		kNewColor = MakeColor(172, 211, 115, A);
		break;
		case eColor_White:
		kNewColor = MakeColor(255,255,255,A);
		break;
		case eColor_Black:
		kNewColor = MakeColor(0,0,0,A);
		break;
		case eColor_Red:
		kNewColor = MakeColor(200,0,0,A);  // Careful: strong Red blows out on consoles/TV
		break;
		case eColor_Orange:
		kNewColor = MakeColor(200,100,0,A);  // Careful: strong Red blows out on consoles/TV
		break;
		case eColor_Green:
		kNewColor = MakeColor(0,255,0,A);
		break;
		case eColor_Blue:
		kNewColor = MakeColor(0,0,255,A);
		break;
		case eColor_Yellow:
		kNewColor = MakeColor(255,255,0,A);
		break;
		case eColor_Cyan:
		kNewColor = MakeColor(51,204,255,A);
		break;
		case eColor_Purple:
		kNewColor = MakeColor(255,0,255,A);
		break;
		case eColor_Gray:
		kNewColor = MakeColor(128,128,128,A);
		break;
	}

	if( eShade == eShade_Light )
	{
		kNewColor.R += (255-kNewColor.R)/2;
		kNewColor.G += (255-kNewColor.G)/2;
		kNewColor.B += (255-kNewColor.B)/2;
	}
	else if( eShade == eShade_Dark )
	{
		kNewColor.R /= 2;
		kNewColor.G /= 2;
		kNewColor.B /= 2;
	}

	return kNewColor;
}


//--------------------------------------------------------------------------------
static function string ColorString( string strValue, Color clrNewColor )
{
	local int iColor;
	local string strColor;

	iColor = (clrNewColor.R << 16) + (clrNewColor.G<<8) + clrNewColor.B;
	strColor = ToHex(iColor);

	return "<font color='#"$strColor$"'>"$strValue$"</font>";
}

static function int ToFlashAlpha( Color kColor )
{
	return (float(kColor.A)/255.0) * 100;
}

static function string LinearColorToFlashHex( LinearColor lColor, optional float BrightnessAdjust = 1.0 )
{
	local int iColor, R, G, B;
	local string strColor;

	R = FClamp(lColor.R * BrightnessAdjust, 0, 1) * 255;
	G = FClamp(lColor.G * BrightnessAdjust, 0, 1) * 255;
	B = FClamp(lColor.B * BrightnessAdjust, 0, 1) * 255; 

	iColor = (R<<16) + (G<<8) + B;
	//strColor = ToHex(iColor);
	//strColor = "0x" $ Right( strColor, 6 );
	strColor = "0x" $ ToHex(iColor);

	return strColor;
}

static function string ColorToFlashHex( Color kColor )
{
	local int iColor;
	local string strColor;

	iColor = (kColor.R << 16) + (kColor.G<<8) + kColor.B;
	strColor = ToHex(iColor);
	strColor = "0x" $ Right( strColor, 6 );

	return strColor;
}

static function string GetColorForFaction(name AssociatedEntity)
{
	local XComGameState_ResistanceFaction FactionState;				// required for Issue #72
	
	switch (AssociatedEntity)
	{
	case 'Faction_Templars':		return FACTION_COLOR_TEMPLAR;
	case 'Faction_Reapers':			return FACTION_COLOR_REAPER;
	case 'Faction_Skirmishers':		return FACTION_COLOR_SKIRMISHER;
	}

	// Begin Issue #72
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState) 
	{
		if(FactionState.GetMyTemplateName() == AssociatedEntity)
		{
			// color code is expected to be returned without the hexadecimal identifying character
			return Right(ColorToFlashHex(FactionState.GetMyTemplate().FactionColor), 6);
		}
	}
	// End Issue #72

	//Fail! Return something for obvious debugging 
	return NORMAL_HTML_COLOR; 
	
}
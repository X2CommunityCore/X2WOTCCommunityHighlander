/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class SkeletalMeshSocket extends Object
	native(SkeletalMesh)
	hidecategories(Object)
	hidecategories(Actor);
	
/** 
 *	Defines a named attachment location on the SkeletalMesh. 
 *	These are set up in editor and used as a shortcut instead of specifying 
 *	everything explicitly to AttachComponent in the SkeletalMeshComponent.
 *	The Outer of a SkeletalMeshSocket should always be the SkeletalMesh.
 */

// Start Issue #281
var()	/* const */ editconst	name	SocketName; // Unconst for Issue #281
var()	/* const */ editconst	name	BoneName;	// Unconst for Issue #281
// Start Issue #281
var()					vector			RelativeLocation;
var()					rotator			RelativeRotation;
var()					vector			RelativeScale;
	
var()	editoronly					SkeletalMesh			PreviewSkelMesh;
var()	const editconst	transient	SkeletalMeshComponent	PreviewSkelComp;
var()	editoronly					StaticMesh				PreviewStaticMesh;
var()	editoronly					ParticleSystem			PreviewParticleSystem;

cpptext
{
	/** Utility that returns the current matrix for this socket. Returns false if socket was not valid (bone not found etc) */
	UBOOL GetSocketMatrix(FMatrix& OutMatrix, class USkeletalMeshComponent* SkelComp) const;
	/** 
	 *	Utility that returns the current matrix for this socket with an offset. Returns false if socket was not valid (bone not found etc) 
	 *	
	 *	@param	OutMatrix		The resulting socket matrix
	 *	@param	SkelComp		The skeletal mesh component that the socket comes from
	 *	@param	InOffset		The additional offset to apply to the socket location
	 *	@param	InRotation		The additional rotation to apply to the socket rotation
	 *
	 *	@return	UBOOL			TRUE if successful, FALSE if not
	 */
	UBOOL GetSocketMatrixWithOffset(FMatrix& OutMatrix, class USkeletalMeshComponent* SkelComp, const FVector& InOffset, const FRotator& InRotation) const;
	/** 
	 *	Utility that returns the current position of this socket with an offset. Returns false if socket was not valid (bone not found etc)
	 *	
	 *	@param	OutPosition		The resulting position
	 *	@param	SkelComp		The skeletal mesh component that the socket comes from
	 *	@param	InOffset		The additional offset to apply to the socket location
	 *	@param	InRotation		The additional rotation to apply to the socket rotation
	 *
	 *	@return	UBOOL			TRUE if successful, FALSE if not
	 */
	UBOOL GetSocketPositionWithOffset(FVector& OutPosition, class USkeletalMeshComponent* SkelComp, const FVector& InOffset, const FRotator& InRotation) const;
}

defaultproperties
{
	RelativeScale=(X=1,Y=1,Z=1)
}

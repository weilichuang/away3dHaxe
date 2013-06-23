package a3d.core.base;

import a3d.animators.IAnimator;
import a3d.materials.MaterialBase;

/**
 * IMaterialOwner provides an interface for objects that can use materials.
 */
interface IMaterialOwner
{
	/**
	 * The material with which to render the object.
	 */
	var material(get,set):MaterialBase;
	/**
	 * The animation used by the material to assemble the vertex code.
	 */
	var animator(get,null):IAnimator; // in most cases, this will in fact be null
}


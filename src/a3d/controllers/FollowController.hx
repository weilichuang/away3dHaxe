package a3d.controllers;

import a3d.entities.Entity;
import a3d.entities.ObjectContainer3D;


/**
 * Controller used to follow behind an object on the XZ plane, with an optional
 * elevation (tiltAngle).
 *
 * @see	a3d.containers.View3D
 */
class FollowController extends HoverController
{
	public function FollowController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, tiltAngle:Float = 45, distance:Float = 700)
	{
		super(targetObject, lookAtObject, 0, tiltAngle, distance);
	}

	override public function update(interpolate:Bool = true):Void
	{
		interpolate = interpolate; // unused: prevents warning

		if (lookAtObject == null)
			return;

		panAngle = _lookAtObject.rotationY - 180;
		super.update();
	}
}

package a3d.controllers;

import flash.geom.Vector3D;

import a3d.entities.Entity;
import a3d.entities.ObjectContainer3D;
import a3d.events.Object3DEvent;

/**
* Extended camera used to automatically look at a specified target object.
*
* @see a3d.containers.View3D
*/
class LookAtController extends ControllerBase
{
	private var _lookAtPosition:Vector3D;
	private var _lookAtObject:ObjectContainer3D;
	private var _origin:Vector3D = new Vector3D(0.0, 0.0, 0.0);

	/**
	 * Creates a new <code>LookAtController</code> object.
	 */
	public function LookAtController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null)
	{
		super(targetObject);

		if (lookAtObject)
			this.lookAtObject = lookAtObject;
		else
			this.lookAtPosition = new Vector3D();
	}

	/**
	* The Vector3D object that the target looks at.
	*/
	private inline function get_lookAtPosition():Vector3D
	{
		return _lookAtPosition;
	}

	private inline function set_lookAtPosition(val:Vector3D):Void
	{
		if (_lookAtObject)
		{
			_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
			_lookAtObject = null;
		}

		_lookAtPosition = val;

		notifyUpdate();
	}

	/**
	* The 3d object that the target looks at.
	*/
	private inline function get_lookAtObject():ObjectContainer3D
	{
		return _lookAtObject;
	}

	private inline function set_lookAtObject(val:ObjectContainer3D):Void
	{
		if (_lookAtPosition)
			_lookAtPosition = null;

		if (_lookAtObject == val)
			return;

		if (_lookAtObject)
			_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);

		_lookAtObject = val;

		if (_lookAtObject)
			_lookAtObject.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);

		notifyUpdate();
	}

	/**
	 * @inheritDoc
	 */
	override public function update(interpolate:Bool = true):Void
	{
		interpolate = interpolate; // prevents unused warning

		if (_targetObject)
		{

			if (_lookAtPosition)
			{
				_targetObject.lookAt(_lookAtPosition);
			}
			else if (_lookAtObject)
			{
				_targetObject.lookAt(_lookAtObject.scene ? _lookAtObject.scenePosition : _lookAtObject.position);
			}
		}
	}

	private function onLookAtObjectChanged(event:Object3DEvent):Void
	{
		notifyUpdate();
	}
}

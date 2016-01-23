package away3d.controllers;

import flash.geom.Vector3D;

import away3d.entities.Entity;
import away3d.containers.ObjectContainer3D;
import away3d.events.Object3DEvent;

/**
* Extended camera used to automatically look at a specified target object.
*
* @see away3d.containers.View3D
*/
class LookAtController extends ControllerBase
{
	/**
	* The Vector3D object that the target looks at.
	*/
	public var lookAtPosition(get, set):Vector3D;
	
	/**
	* The 3d object that the target looks at.
	*/
	public var lookAtObject(get,set):ObjectContainer3D;
	
	private var _lookAtPosition:Vector3D;
	private var _lookAtObject:ObjectContainer3D;
	private var _origin:Vector3D;

	/**
	 * Creates a new <code>LookAtController</code> object.
	 */
	public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null)
	{
		super(targetObject);
		
		_origin = new Vector3D(0.0, 0.0, 0.0);
		
		if (lookAtObject != null)
			this.lookAtObject = lookAtObject;
		else
			this.lookAtPosition = new Vector3D();
	}

	
	private function get_lookAtPosition():Vector3D
	{
		return _lookAtPosition;
	}

	private function set_lookAtPosition(val:Vector3D):Vector3D
	{
		if (_lookAtObject != null)
		{
			_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
			_lookAtObject = null;
		}

		_lookAtPosition = val;

		notifyUpdate();
		
		return _lookAtPosition;
	}

	
	private function get_lookAtObject():ObjectContainer3D
	{
		return _lookAtObject;
	}

	private function set_lookAtObject(val:ObjectContainer3D):ObjectContainer3D
	{
		if (_lookAtPosition != null)
			_lookAtPosition = null;

		if (_lookAtObject == val)
			return _lookAtObject;

		if (_lookAtObject != null)
			_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);

		_lookAtObject = val;

		if (_lookAtObject != null)
			_lookAtObject.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);

		notifyUpdate();
		
		return _lookAtObject;
	}

	/**
	 * @inheritDoc
	 */
	override public function update(interpolate:Bool = true):Void
	{
		if (_targetObject != null)
		{
			if (_lookAtPosition != null)
			{
				_targetObject.lookAt(_lookAtPosition);
			}
			else if (_lookAtObject != null)
			{
				_targetObject.lookAt(_lookAtObject.scene != null ? 
									_lookAtObject.scenePosition : 
									_lookAtObject.position);
			}
		}
	}

	private function onLookAtObjectChanged(event:Object3DEvent):Void
	{
		notifyUpdate();
	}
}

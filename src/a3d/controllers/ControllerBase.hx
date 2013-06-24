package a3d.controllers;


import a3d.entities.Entity;
import a3d.errors.AbstractMethodError;



class ControllerBase
{
	private var _autoUpdate:Bool = true;
	private var _targetObject:Entity;

	private function notifyUpdate():Void
	{
		if (_targetObject && _targetObject.implicitPartition && _autoUpdate)
			_targetObject.implicitPartition.markForUpdate(_targetObject);
	}

	/**
	 * Target object on which the controller acts. Defaults to null.
	 */
	private inline function get_targetObject():Entity
	{
		return _targetObject;
	}

	private inline function set_targetObject(val:Entity):Void
	{
		if (_targetObject == val)
			return;

		if (_targetObject && _autoUpdate)
			_targetObject.controller = null;

		_targetObject = val;

		if (_targetObject && _autoUpdate)
			_targetObject.controller = this;

		notifyUpdate();
	}

	/**
	 * Determines whether the controller applies updates automatically. Defaults to true
	 */
	private inline function get_autoUpdate():Bool
	{
		return _autoUpdate;
	}

	private inline function set_autoUpdate(val:Bool):Void
	{
		if (_autoUpdate == val)
			return;

		_autoUpdate = val;

		if (_targetObject)
		{
			if (_autoUpdate)
				_targetObject.controller = this;
			else
				_targetObject.controller = null;
		}
	}

	/**
	 * Base controller class for dynamically adjusting the propeties of a 3D object.
	 *
	 * @param	targetObject	The 3D object on which to act.
	 */
	public function ControllerBase(targetObject:Entity = null):Void
	{
		this.targetObject = targetObject;
	}

	/**
	 * Manually applies updates to the target 3D object.
	 */
	public function update(interpolate:Bool = true):Void
	{
		throw new AbstractMethodError();
	}
}

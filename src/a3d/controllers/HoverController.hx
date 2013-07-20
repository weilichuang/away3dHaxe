package a3d.controllers;

import flash.geom.Vector3D;


import a3d.entities.Entity;
import a3d.entities.ObjectContainer3D;
import a3d.math.FMath;



/**
 * Extended camera used to hover round a specified target object.
 *
 * @see	a3d.containers.View3D
 */
class HoverController extends LookAtController
{
	/**
	 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
	 *
	 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
	 *
	 * @see	#tiltAngle
	 * @see	#panAngle
	 */
	public var steps(get, set):Int;
	
	/**
	 * Rotation of the camera in degrees around the y axis. Defaults to 0.
	 */
	public var panAngle(get, set):Float;
	
	/**
	 * Elevation angle of the camera in degrees. Defaults to 90.
	 */
	public var tiltAngle(get, set):Float;
	
	/**
	 * Distance between the camera and the specified target. Defaults to 1000.
	 */
	public var distance(get, set):Float;
	
	/**
	 * Minimum bounds for the <code>panAngle</code>. Defaults to -Infinity.
	 *
	 * @see	#panAngle
	 */
	public var minPanAngle(get, set):Float;
	
	/**
	 * Maximum bounds for the <code>panAngle</code>. Defaults to Infinity.
	 *
	 * @see	#panAngle
	 */
	public var maxPanAngle(get, set):Float;
	
	/**
	 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
	 *
	 * @see	#tiltAngle
	 */
	public var minTiltAngle(get, set):Float;
	
	/**
	 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
	 *
	 * @see	#tiltAngle
	 */
	public var maxTiltAngle(get, set):Float;
	
	/**
	 * Fractional difference in distance between the horizontal camera orientation and vertical camera orientation. Defaults to 2.
	 *
	 * @see	#distance
	 */
	public var yFactor(get, set):Float;
	
	/**
	 * Defines whether the value of the pan angle wraps when over 360 degrees or under 0 degrees. Defaults to false.
	 */
	public var wrapPanAngle(get,set):Bool;
	
	public var currentPanAngle:Float = 0;
	public var currentTiltAngle:Float = 90;

	private var _panAngle:Float = 0;
	private var _tiltAngle:Float = 90;
	private var _distance:Float = 1000;
	private var _minPanAngle:Float;
	private var _maxPanAngle:Float;
	private var _minTiltAngle:Float = -90;
	private var _maxTiltAngle:Float = 90;
	private var _steps:Int = 8;
	private var _yFactor:Float = 2;
	private var _wrapPanAngle:Bool = false;

	/**
	 * Creates a new <code>HoverController</code> object.
	 */
	public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, 
						panAngle:Float = 0, tiltAngle:Float = 90, distance:Float = 1000, 
						minTiltAngle:Float = -90, maxTiltAngle:Float = 90, 
						minPanAngle:Float = null, maxPanAngle:Float = null, 
						steps:Int = 8, yFactor:Float = 2, wrapPanAngle:Bool = false)
	{
		super(targetObject, lookAtObject);

		this.distance = distance;
		this.panAngle = panAngle;
		this.tiltAngle = tiltAngle;
		
		if (minPanAngle == null)
		{
			minPanAngle = Math.NEGATIVE_INFINITY;
		}
		
		if (maxPanAngle == null)
		{
			maxPanAngle = Math.POSITIVE_INFINITY;
		}
		
		this.minPanAngle = minPanAngle;
		this.maxPanAngle = maxPanAngle;
		this.minTiltAngle = minTiltAngle;
		this.maxTiltAngle = maxTiltAngle;
		this.steps = steps;
		this.yFactor = yFactor;
		this.wrapPanAngle = wrapPanAngle;

		//values passed in contrustor are applied immediately
		currentPanAngle = _panAngle;
		currentTiltAngle = _tiltAngle;
	}
	
	
	private function get_steps():Int
	{
		return _steps;
	}

	private function set_steps(val:Int):Int
	{
		val = (val < 1) ? 1 : val;

		if (_steps == val)
			return _steps;

		_steps = val;

		notifyUpdate();
		
		return _steps;
	}

	
	private function get_panAngle():Float
	{
		return _panAngle;
	}

	private function set_panAngle(val:Float):Float
	{
		val = FMath.fclamp(val, _minPanAngle, _maxPanAngle);

		if (_panAngle == val)
			return _panAngle;

		_panAngle = val;

		notifyUpdate();
		
		return _panAngle;
	}

	
	private function get_tiltAngle():Float
	{
		return _tiltAngle;
	}

	private function set_tiltAngle(val:Float):Float
	{
		val = FMath.fclamp(val, _minTiltAngle, _maxTiltAngle);

		if (_tiltAngle == val)
			return _tiltAngle;

		_tiltAngle = val;

		notifyUpdate();
		
		return _tiltAngle;
	}

	
	private function get_distance():Float
	{
		return _distance;
	}

	private function set_distance(val:Float):Float
	{
		if (_distance == val)
			return _distance;

		_distance = val;

		notifyUpdate();
		
		return _distance;
	}

	
	private function get_minPanAngle():Float
	{
		return _minPanAngle;
	}

	private function set_minPanAngle(val:Float):Float
	{
		if (_minPanAngle == val)
			return _minPanAngle;

		_minPanAngle = val;

		panAngle = FMath.fclamp(_panAngle, _minPanAngle, _maxPanAngle);

		return _minPanAngle;
	}

	
	private function get_maxPanAngle():Float
	{
		return _maxPanAngle;
	}

	private function set_maxPanAngle(val:Float):Float
	{
		if (_maxPanAngle == val)
			return _maxPanAngle;

		_maxPanAngle = val;

		panAngle = FMath.fclamp(_panAngle, _minPanAngle, _maxPanAngle);
		
		return _maxPanAngle;
	}

	
	private function get_minTiltAngle():Float
	{
		return _minTiltAngle;
	}

	private function set_minTiltAngle(val:Float):Float
	{
		if (_minTiltAngle == val)
			return _minTiltAngle;

		_minTiltAngle = val;

		tiltAngle = FMath.fclamp(_tiltAngle, _minTiltAngle, _maxTiltAngle);

		return _minTiltAngle;
	}

	
	private function get_maxTiltAngle():Float
	{
		return _maxTiltAngle;
	}

	private function set_maxTiltAngle(val:Float):Float
	{
		if (_maxTiltAngle == val)
			return _maxTiltAngle;

		_maxTiltAngle = val;

		tiltAngle = FMath.fclamp(_tiltAngle, _minTiltAngle, _maxTiltAngle);
		
		return _maxTiltAngle;
	}

	
	private function get_yFactor():Float
	{
		return _yFactor;
	}

	private function set_yFactor(val:Float):Float
	{
		if (_yFactor == val)
			return _yFactor;

		_yFactor = val;

		notifyUpdate();
		
		return _yFactor;
	}

	
	private function get_wrapPanAngle():Bool
	{
		return _wrapPanAngle;
	}

	private function set_wrapPanAngle(val:Bool):Bool
	{
		if (_wrapPanAngle == val)
			return _wrapPanAngle;

		_wrapPanAngle = val;

		notifyUpdate();
		
		return _wrapPanAngle;
	}

	/**
	 * Updates the current tilt angle and pan angle values.
	 *
	 * Values are calculated using the defined <code>tiltAngle</code>, <code>panAngle</code> and <code>steps</code> variables.
	 *
	 * @param interpolate   If the update to a target pan- or tiltAngle is interpolated. Default is true.
	 *
	 * @see	#tiltAngle
	 * @see	#panAngle
	 * @see	#steps
	 */
	override public function update(interpolate:Bool = true):Void
	{
		if (_tiltAngle != currentTiltAngle || _panAngle != currentPanAngle)
		{
			notifyUpdate();

			if (_wrapPanAngle) 
			{
				if (_panAngle < 0) 
				{
					currentPanAngle += _panAngle % 360 + 360 - _panAngle;
					_panAngle = _panAngle%360 + 360;
				}
				else 
				{
					currentPanAngle += _panAngle % 360 - _panAngle;
					_panAngle = _panAngle%360;
				}
				
				while (_panAngle - currentPanAngle < -180)
					currentPanAngle -= 360;
				
				while (_panAngle - currentPanAngle > 180)
					currentPanAngle += 360;
			}

			if (interpolate)
			{
				currentTiltAngle += (_tiltAngle - currentTiltAngle) / (steps + 1);
				currentPanAngle += (_panAngle - currentPanAngle) / (steps + 1);
			}
			else
			{
				currentPanAngle = _panAngle;
				currentTiltAngle = _tiltAngle;
			}

			//snap coords if angle differences are close
			if ((Math.abs(tiltAngle - currentTiltAngle) < 0.01) && 
				(Math.abs(_panAngle - currentPanAngle) < 0.01))
			{
				currentTiltAngle = _tiltAngle;
				currentPanAngle = _panAngle;
			}
		}

		var pos:Vector3D = (lookAtObject != null) ? lookAtObject.position : ((lookAtPosition != null) ? lookAtPosition : _origin);
		targetObject.x = pos.x + distance * Math.sin(currentPanAngle * FMath.DEGREES_TO_RADIANS()) * Math.cos(currentTiltAngle * FMath.DEGREES_TO_RADIANS());
		targetObject.z = pos.z + distance * Math.cos(currentPanAngle * FMath.DEGREES_TO_RADIANS()) * Math.cos(currentTiltAngle * FMath.DEGREES_TO_RADIANS());
		targetObject.y = pos.y + distance * Math.sin(currentTiltAngle * FMath.DEGREES_TO_RADIANS()) * yFactor;

		super.update();
	}
}

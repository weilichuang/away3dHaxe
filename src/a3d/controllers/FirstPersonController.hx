package a3d.controllers;


import a3d.entities.Entity;
import a3d.math.MathUtil;



/**
 * Extended camera used to hover round a specified target object.
 *
 * @see	a3d.containers.View3D
 */
class FirstPersonController extends ControllerBase
{
	public var currentPanAngle:Float = 0;
	public var currentTiltAngle:Float = 90;

	private var _panAngle:Float = 0;
	private var _tiltAngle:Float = 90;
	private var _minTiltAngle:Float = -90;
	private var _maxTiltAngle:Float = 90;
	private var _steps:Int = 8;
	private var _walkIncrement:Float = 0;
	private var _strafeIncrement:Float = 0;

	public var fly:Bool = false;

	/**
	 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
	 *
	 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
	 *
	 * @see	#tiltAngle
	 * @see	#panAngle
	 */
	public var steps(get, set):Int;
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

	/**
	 * Rotation of the camera in degrees around the y axis. Defaults to 0.
	 */
	public var panAngle(get, set):Float;
	private function get_panAngle():Float
	{
		return _panAngle;
	}

	private function set_panAngle(val:Float):Float
	{
		if (_panAngle == val)
			return _panAngle;

		_panAngle = val;

		notifyUpdate();
		
		return _panAngle;
	}

	/**
	 * Elevation angle of the camera in degrees. Defaults to 90.
	 */
	public var tiltAngle(get, set):Float;
	private function get_tiltAngle():Float
	{
		return _tiltAngle;
	}

	private function set_tiltAngle(val:Float):Float
	{
		val = MathUtil.fclamp(val, _minTiltAngle, _maxTiltAngle);

		if (_tiltAngle == val)
			return _tiltAngle;

		_tiltAngle = val;

		notifyUpdate();
		
		return _tiltAngle;
	}

	/**
	 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
	 *
	 * @see	#tiltAngle
	 */
	public var minTiltAngle(get, set):Float;
	private function get_minTiltAngle():Float
	{
		return _minTiltAngle;
	}

	private function set_minTiltAngle(val:Float):Float
	{
		if (_minTiltAngle == val)
			return _minTiltAngle;

		_minTiltAngle = val;

		tiltAngle = MathUtil.fclamp(_tiltAngle, _minTiltAngle, _maxTiltAngle);

		return _minTiltAngle;
	}

	/**
	 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
	 *
	 * @see	#tiltAngle
	 */
	public var maxTiltAngle(get, set):Float;
	private function get_maxTiltAngle():Float
	{
		return _maxTiltAngle;
	}

	private function set_maxTiltAngle(val:Float):Float
	{
		if (_maxTiltAngle == val)
			return _maxTiltAngle;

		_maxTiltAngle = val;

		tiltAngle = MathUtil.fclamp(_tiltAngle, _minTiltAngle, _maxTiltAngle);
		return _maxTiltAngle;
	}

	/**
	 * Creates a new <code>HoverController</code> object.
	 */
	public function new(targetObject:Entity = null, panAngle:Float = 0, tiltAngle:Float = 90, minTiltAngle:Float = -90, maxTiltAngle:Float = 90, steps:UInt = 8)
	{
		super(targetObject);

		this.panAngle = panAngle;
		this.tiltAngle = tiltAngle;
		this.minTiltAngle = minTiltAngle;
		this.maxTiltAngle = maxTiltAngle;
		this.steps = steps;

		//values passed in contrustor are applied immediately
		currentPanAngle = _panAngle;
		currentTiltAngle = _tiltAngle;
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

			if (interpolate)
			{
				currentTiltAngle += (_tiltAngle - currentTiltAngle) / (steps + 1);
				currentPanAngle += (_panAngle - currentPanAngle) / (steps + 1);
			}
			else
			{
				currentTiltAngle = _tiltAngle;
				currentPanAngle = _panAngle;
			}

			//snap coords if angle differences are close
			if ((Math.abs(tiltAngle - currentTiltAngle) < 0.01) && (Math.abs(_panAngle - currentPanAngle) < 0.01))
			{

				if (Math.abs(_panAngle) > 360)
				{

					if (_panAngle < 0)
						panAngle = (_panAngle % 360) + 360;
					else
						panAngle = _panAngle % 360;
				}

				currentTiltAngle = _tiltAngle;
				currentPanAngle = _panAngle;
			}
		}

		targetObject.rotationX = currentTiltAngle;
		targetObject.rotationY = currentPanAngle;

		if (_walkIncrement != 0)
		{
			if (fly)
			{
				targetObject.moveForward(_walkIncrement);
			}
			else
			{
				targetObject.x += _walkIncrement * Math.sin(panAngle * MathUtil.DEGREES_TO_RADIANS());
				targetObject.z += _walkIncrement * Math.cos(panAngle * MathUtil.DEGREES_TO_RADIANS());
			}
			_walkIncrement = 0;
		}

		if (_strafeIncrement != 0)
		{
			targetObject.moveRight(_strafeIncrement);
			_strafeIncrement = 0;
		}

	}

	public function incrementWalk(val:Float):Void
	{
		if (val == 0)
			return;

		_walkIncrement += val;

		notifyUpdate();
	}


	public function incrementStrafe(val:Float):Void
	{
		if (val == 0)
			return;

		_strafeIncrement += val;

		notifyUpdate();
	}

}

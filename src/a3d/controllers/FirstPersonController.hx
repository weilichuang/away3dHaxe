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
	private var _steps:UInt = 8;
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
	private inline function get_steps():UInt
	{
		return _steps;
	}

	private inline function set_steps(val:UInt):Void
	{
		val = (val < 1) ? 1 : val;

		if (_steps == val)
			return;

		_steps = val;

		notifyUpdate();
	}

	/**
	 * Rotation of the camera in degrees around the y axis. Defaults to 0.
	 */
	private inline function get_panAngle():Float
	{
		return _panAngle;
	}

	private inline function set_panAngle(val:Float):Void
	{
		if (_panAngle == val)
			return;

		_panAngle = val;

		notifyUpdate();
	}

	/**
	 * Elevation angle of the camera in degrees. Defaults to 90.
	 */
	private inline function get_tiltAngle():Float
	{
		return _tiltAngle;
	}

	private inline function set_tiltAngle(val:Float):Void
	{
		val = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, val));

		if (_tiltAngle == val)
			return;

		_tiltAngle = val;

		notifyUpdate();
	}

	/**
	 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
	 *
	 * @see	#tiltAngle
	 */
	private inline function get_minTiltAngle():Float
	{
		return _minTiltAngle;
	}

	private inline function set_minTiltAngle(val:Float):Void
	{
		if (_minTiltAngle == val)
			return;

		_minTiltAngle = val;

		tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
	}

	/**
	 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
	 *
	 * @see	#tiltAngle
	 */
	private inline function get_maxTiltAngle():Float
	{
		return _maxTiltAngle;
	}

	private inline function set_maxTiltAngle(val:Float):Void
	{
		if (_maxTiltAngle == val)
			return;

		_maxTiltAngle = val;

		tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
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

		if (_walkIncrement)
		{
			if (fly)
			{
				targetObject.moveForward(_walkIncrement);
			}
			else
			{
				targetObject.x += _walkIncrement * Math.sin(panAngle * MathUtil.DEGREES_TO_RADIANS);
				targetObject.z += _walkIncrement * Math.cos(panAngle * MathUtil.DEGREES_TO_RADIANS);
			}
			_walkIncrement = 0;
		}

		if (_strafeIncrement)
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

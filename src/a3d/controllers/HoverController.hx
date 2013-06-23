package a3d.controllers
{
	import flash.geom.Vector3D;


	import a3d.entities.Entity;
	import a3d.entities.ObjectContainer3D;
	import a3d.math.MathUtil;



	/**
	 * Extended camera used to hover round a specified target object.
	 *
	 * @see	a3d.containers.View3D
	 */
	class HoverController extends LookAtController
	{
		public var currentPanAngle:Float = 0;
		public var currentTiltAngle:Float = 90;

		private var _panAngle:Float = 0;
		private var _tiltAngle:Float = 90;
		private var _distance:Float = 1000;
		private var _minPanAngle:Float = -Infinity;
		private var _maxPanAngle:Float = Infinity;
		private var _minTiltAngle:Float = -90;
		private var _maxTiltAngle:Float = 90;
		private var _steps:UInt = 8;
		private var _yFactor:Float = 2;
		private var _wrapPanAngle:Bool = false;

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
			val = Math.max(_minPanAngle, Math.min(_maxPanAngle, val));

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
		 * Distance between the camera and the specified target. Defaults to 1000.
		 */
		private inline function get_distance():Float
		{
			return _distance;
		}

		private inline function set_distance(val:Float):Void
		{
			if (_distance == val)
				return;

			_distance = val;

			notifyUpdate();
		}

		/**
		 * Minimum bounds for the <code>panAngle</code>. Defaults to -Infinity.
		 *
		 * @see	#panAngle
		 */
		private inline function get_minPanAngle():Float
		{
			return _minPanAngle;
		}

		private inline function set_minPanAngle(val:Float):Void
		{
			if (_minPanAngle == val)
				return;

			_minPanAngle = val;

			panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
		}

		/**
		 * Maximum bounds for the <code>panAngle</code>. Defaults to Infinity.
		 *
		 * @see	#panAngle
		 */
		private inline function get_maxPanAngle():Float
		{
			return _maxPanAngle;
		}

		private inline function set_maxPanAngle(val:Float):Void
		{
			if (_maxPanAngle == val)
				return;

			_maxPanAngle = val;

			panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
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
		 * Fractional difference in distance between the horizontal camera orientation and vertical camera orientation. Defaults to 2.
		 *
		 * @see	#distance
		 */
		private inline function get_yFactor():Float
		{
			return _yFactor;
		}

		private inline function set_yFactor(val:Float):Void
		{
			if (_yFactor == val)
				return;

			_yFactor = val;

			notifyUpdate();
		}

		/**
		 * Defines whether the value of the pan angle wraps when over 360 degrees or under 0 degrees. Defaults to false.
		 */
		private inline function get_wrapPanAngle():Bool
		{
			return _wrapPanAngle;
		}

		private inline function set_wrapPanAngle(val:Bool):Void
		{
			if (_wrapPanAngle == val)
				return;

			_wrapPanAngle = val;

			notifyUpdate();
		}

		/**
		 * Creates a new <code>HoverController</code> object.
		 */
		public function HoverController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, panAngle:Float = 0, tiltAngle:Float = 90, distance:Float = 1000, minTiltAngle:Float = -90,
			maxTiltAngle:Float = 90, minPanAngle:Float = NaN, maxPanAngle:Float = NaN, steps:UInt = 8, yFactor:Float = 2, wrapPanAngle:Bool = false)
		{
			super(targetObject, lookAtObject);

			this.distance = distance;
			this.panAngle = panAngle;
			this.tiltAngle = tiltAngle;
			this.minPanAngle = minPanAngle || -Infinity;
			this.maxPanAngle = maxPanAngle || Infinity;
			this.minTiltAngle = minTiltAngle;
			this.maxTiltAngle = maxTiltAngle;
			this.steps = steps;
			this.yFactor = yFactor;
			this.wrapPanAngle = wrapPanAngle;

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

				if (_wrapPanAngle)
				{
					if (_panAngle < 0)
						_panAngle = (_panAngle % 360) + 360;
					else
						_panAngle = _panAngle % 360;

					if (_panAngle - currentPanAngle < -180)
						currentPanAngle -= 360;
					else if (_panAngle - currentPanAngle > 180)
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
				if ((Math.abs(tiltAngle - currentTiltAngle) < 0.01) && (Math.abs(_panAngle - currentPanAngle) < 0.01))
				{
					currentTiltAngle = _tiltAngle;
					currentPanAngle = _panAngle;
				}
			}

			var pos:Vector3D = (lookAtObject) ? lookAtObject.position : (lookAtPosition) ? lookAtPosition : _origin;
			targetObject.x = pos.x + distance * Math.sin(currentPanAngle * MathUtil.DEGREES_TO_RADIANS) * Math.cos(currentTiltAngle * MathUtil.DEGREES_TO_RADIANS);
			targetObject.z = pos.z + distance * Math.cos(currentPanAngle * MathUtil.DEGREES_TO_RADIANS) * Math.cos(currentTiltAngle * MathUtil.DEGREES_TO_RADIANS);
			targetObject.y = pos.y + distance * Math.sin(currentTiltAngle * MathUtil.DEGREES_TO_RADIANS) * yFactor;

			super.update();
		}
	}
}

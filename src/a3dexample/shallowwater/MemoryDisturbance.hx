package a3dexample.shallowwater
{

	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	class MemoryDisturbance
	{
		private var _disturbances:Vector<Vector3D>;
		private var _targetTime:int;
		private var _elapsedTime:UInt;
		private var _startTime:UInt;
		private var _concluded:Bool;
		private var _growthRate:Float;
		private var _growth:Float;

		/*
		 time is the time that the disturbance will last.
		 if -1, disturbance lasts until manually concluded.
		 */
		public function MemoryDisturbance(time:int, speed:Float)
		{
			_targetTime = time;
			_startTime = getTimer();
			_disturbances = new Vector<Vector3D>();
			_growth = 0;
			_growthRate = speed;
		}

		public function get growth():Float
		{
			return _growth;
		}

		public function get disturbances():Vector<Vector3D>
		{
			return _disturbances;
		}

		public function addDisturbance(x:UInt, y:UInt, displacement:Float):Void
		{
			_disturbances.push(new Vector3D(x, y, displacement));
		}

		public function update():Void
		{
			if (_concluded)
				return;

			_growth += _growthRate;
			_growth = _growth > 1 ? 1 : _growth;

			if (_targetTime < 0)
				return;

			_elapsedTime = getTimer() - _startTime;

			if (_elapsedTime >= _targetTime)
				_concluded = true;
		}

		public function get concluded():Bool
		{
			return _concluded;
		}

		public function set concluded(value:Bool):Void
		{
			_concluded = value;
		}
	}
}

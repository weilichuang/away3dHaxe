package a3d.animators.states
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;

	
	import a3d.animators.ParticleAnimator;
	import a3d.animators.data.AnimationRegisterCache;
	import a3d.animators.data.AnimationSubGeometry;
	import a3d.animators.data.ParticlePropertiesMode;
	import a3d.animators.nodes.ParticleScaleNode;
	import a3d.entities.Camera3D;
	import a3d.core.base.IRenderable;
	import a3d.core.managers.Stage3DProxy;

	

	/**
	 * ...
	 */
	class ParticleScaleState extends ParticleStateBase
	{
		private var _particleScaleNode:ParticleScaleNode;
		private var _usesCycle:Bool;
		private var _usesPhase:Bool;
		private var _minScale:Float;
		private var _maxScale:Float;
		private var _cycleDuration:Float;
		private var _cyclePhase:Float;
		private var _scaleData:Vector3D;

		/**
		 * Defines the end scale of the state, when in global mode. Defaults to 1.
		 */
		private inline function get_minScale():Float
		{
			return _minScale;
		}

		private inline function set_minScale(value:Float):Void
		{
			_minScale = value;

			updateScaleData();
		}

		/**
		 * Defines the end scale of the state, when in global mode. Defaults to 1.
		 */
		private inline function get_maxScale():Float
		{
			return _maxScale;
		}

		private inline function set_maxScale(value:Float):Void
		{
			_maxScale = value;

			updateScaleData();
		}

		/**
		 * Defines the duration of the animation in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
		 */
		private inline function get_cycleDuration():Float
		{
			return _cycleDuration;
		}

		private inline function set_cycleDuration(value:Float):Void
		{
			_cycleDuration = value;

			updateScaleData();
		}

		/**
		 * Defines the phase of the cycle in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
		 */
		private inline function get_cyclePhase():Float
		{
			return _cyclePhase;
		}

		private inline function set_cyclePhase(value:Float):Void
		{
			_cyclePhase = value;

			updateScaleData();
		}

		public function ParticleScaleState(animator:ParticleAnimator, particleScaleNode:ParticleScaleNode)
		{
			super(animator, particleScaleNode);

			_particleScaleNode = particleScaleNode;
			_usesCycle = _particleScaleNode.usesCycle;
			_usesPhase = _particleScaleNode.usesPhase;
			_minScale = _particleScaleNode.minScale;
			_maxScale = _particleScaleNode.maxScale;
			_cycleDuration = _particleScaleNode.cycleDuration;
			_cyclePhase = _particleScaleNode.cyclePhase;

			updateScaleData();
		}

		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleScaleNode.SCALE_INDEX);

			if (_particleScaleNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
			{
				if (_usesCycle)
				{
					if (_usesPhase)
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					else
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				}
				else
				{
					animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
				}
			}
			else
			{
				animationRegisterCache.setVertexConst(index, _scaleData.x, _scaleData.y, _scaleData.z, _scaleData.w);
			}
		}

		private function updateScaleData():Void
		{
			if (_particleScaleNode.mode == ParticlePropertiesMode.GLOBAL)
			{
				if (_usesCycle)
				{
					if (_cycleDuration <= 0)
						throw(new Error("the cycle duration must be greater than zero"));
					_scaleData = new Vector3D((_minScale + _maxScale) / 2, Math.abs(_minScale - _maxScale) / 2, Math.PI * 2 / _cycleDuration, _cyclePhase * Math.PI / 180);
				}
				else
				{
					_scaleData = new Vector3D(_minScale, _maxScale - _minScale, 0, 0);
				}
			}
		}
	}
}

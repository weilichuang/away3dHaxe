package a3d.animators.states
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;

	
	import a3d.animators.ParticleAnimator;
	import a3d.animators.data.AnimationRegisterCache;
	import a3d.animators.data.AnimationSubGeometry;
	import a3d.animators.data.ParticlePropertiesMode;
	import a3d.animators.nodes.ParticleAccelerationNode;
	import a3d.entities.Camera3D;
	import a3d.core.base.IRenderable;
	import a3d.core.managers.Stage3DProxy;

	

	/**
	 * ...
	 */
	class ParticleAccelerationState extends ParticleStateBase
	{
		private var _particleAccelerationNode:ParticleAccelerationNode;
		private var _acceleration:Vector3D;
		private var _halfAcceleration:Vector3D;

		/**
		 * Defines the acceleration vector of the state, used when in global mode.
		 */
		private inline function get_acceleration():Vector3D
		{
			return _acceleration;
		}

		private inline function set_acceleration(value:Vector3D):Void
		{
			_acceleration.x = value.x;
			_acceleration.y = value.y;
			_acceleration.z = value.z;

			updateAccelerationData();
		}

		public function ParticleAccelerationState(animator:ParticleAnimator, particleAccelerationNode:ParticleAccelerationNode)
		{
			super(animator, particleAccelerationNode);

			_particleAccelerationNode = particleAccelerationNode;
			_acceleration = _particleAccelerationNode.acceleration;

			updateAccelerationData();
		}

		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			// TODO: not used
			renderable = renderable;
			camera = camera;

			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleAccelerationNode.ACCELERATION_INDEX);

			if (_particleAccelerationNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
			{
				animationSubGeometry.activateVertexBuffer(index, _particleAccelerationNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			else
			{
				animationRegisterCache.setVertexConst(index, _halfAcceleration.x, _halfAcceleration.y, _halfAcceleration.z);
			}
		}

		private function updateAccelerationData():Void
		{
			if (_particleAccelerationNode.mode == ParticlePropertiesMode.GLOBAL)
				_halfAcceleration = new Vector3D(_acceleration.x / 2, _acceleration.y / 2, _acceleration.z / 2);
		}
	}

}

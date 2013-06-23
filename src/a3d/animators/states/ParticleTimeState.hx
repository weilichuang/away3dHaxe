package a3d.animators.states
{
	import flash.display3D.Context3DVertexBufferFormat;

	
	import a3d.animators.ParticleAnimator;
	import a3d.animators.data.AnimationRegisterCache;
	import a3d.animators.data.AnimationSubGeometry;
	import a3d.animators.nodes.ParticleTimeNode;
	import a3d.entities.Camera3D;
	import a3d.core.base.IRenderable;
	import a3d.core.managers.Stage3DProxy;

	

	/**
	 * ...
	 */
	class ParticleTimeState extends ParticleStateBase
	{
		private var _particleTimeNode:ParticleTimeNode;

		public function ParticleTimeState(animator:ParticleAnimator, particleTimeNode:ParticleTimeNode)
		{
			super(animator, particleTimeNode, true);

			_particleTimeNode = particleTimeNode;
		}

		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleTimeNode.TIME_STREAM_INDEX), _particleTimeNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.
				FLOAT_4);

			var particleTime:Float = _time / 1000;
			animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleTimeNode.TIME_CONSTANT_INDEX), particleTime, particleTime, particleTime, particleTime);
		}

	}

}

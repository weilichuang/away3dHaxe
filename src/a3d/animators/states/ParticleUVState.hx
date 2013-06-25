package a3d.animators.states;

import flash.geom.Vector3D;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.nodes.ParticleUVNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;



/**
 * ...
 */
class ParticleUVState extends ParticleStateBase
{

	private var _particleUVNode:ParticleUVNode;

	public function new(animator:ParticleAnimator, particleUVNode:ParticleUVNode)
	{
		super(animator, particleUVNode);

		_particleUVNode = particleUVNode;
	}


	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (animationRegisterCache.needUVAnimation)
		{
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleUVNode.UV_INDEX);
			var data:Vector3D = _particleUVNode.uvData;
			animationRegisterCache.setVertexConst(index, data.x, data.y);
		}
	}

}

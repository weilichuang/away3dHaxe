package a3d.animators.states;

import flash.geom.Matrix3D;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.nodes.ParticleNodeBase;
import a3d.animators.nodes.ParticleRotateToHeadingNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;


/**
 * ...
 */
class ParticleRotateToHeadingState extends ParticleStateBase
{

	private var _matrix:Matrix3D;

	public function new(animator:ParticleAnimator, particleNode:ParticleNodeBase)
	{
		super(animator, particleNode);
		 _matrix = new Matrix3D();
	}

	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (animationRegisterCache.hasBillboard)
		{
			_matrix.copyFrom(renderable.sceneTransform);
			_matrix.append(camera.inverseSceneTransform);
			animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToHeadingNode.MATRIX_INDEX), _matrix);
		}
	}

}

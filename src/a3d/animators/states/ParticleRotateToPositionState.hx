package a3d.animators.states;

import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleRotateToPositionNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;



/**
 * ...
 */
class ParticleRotateToPositionState extends ParticleStateBase
{
	private var _particleRotateToPositionNode:ParticleRotateToPositionNode;
	private var _position:Vector3D;
	private var _matrix:Matrix3D;
	private var _offset:Vector3D;

	/**
	 * Defines the position of the point the particle will rotate to face when in global mode. Defaults to 0,0,0.
	 */
	public var position(get,set):Vector3D;
	private function get_position():Vector3D
	{
		return _position;
	}

	private function set_position(value:Vector3D):Vector3D
	{
		return _position = value;
	}

	public function new(animator:ParticleAnimator, particleRotateToPositionNode:ParticleRotateToPositionNode)
	{
		super(animator, particleRotateToPositionNode);
		
		_matrix = new Matrix3D();

		_particleRotateToPositionNode = particleRotateToPositionNode;
		_position = _particleRotateToPositionNode.position;
	}

	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToPositionNode.POSITION_INDEX);

		if (animationRegisterCache.hasBillboard)
		{
			_matrix.copyFrom(renderable.sceneTransform);
			_matrix.append(camera.inverseSceneTransform);
			animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToPositionNode.MATRIX_INDEX), _matrix);
		}

		if (_particleRotateToPositionNode.mode == ParticlePropertiesMode.GLOBAL)
		{
			_offset = renderable.inverseSceneTransform.transformVector(_position);
			animationRegisterCache.setVertexConst(index, _offset.x, _offset.y, _offset.z);
		}
		else
			animationSubGeometry.activateVertexBuffer(index, _particleRotateToPositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);

	}

}

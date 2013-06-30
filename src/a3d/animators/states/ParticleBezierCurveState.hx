package a3d.animators.states;

import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Vector3D;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleBezierCurveNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;



/**
 * ...
 */
class ParticleBezierCurveState extends ParticleStateBase
{
	private var _particleBezierCurveNode:ParticleBezierCurveNode;
	private var _controlPoint:Vector3D;
	private var _endPoint:Vector3D;

	/**
	 * Defines the default control point of the node, used when in global mode.
	 */
	private function get_controlPoint():Vector3D
	{
		return _controlPoint;
	}

	private function set_controlPoint(value:Vector3D):Void
	{
		_controlPoint = value;
	}

	/**
	 * Defines the default end point of the node, used when in global mode.
	 */
	private function get_endPoint():Vector3D
	{
		return _endPoint;
	}

	private function set_endPoint(value:Vector3D):Void
	{
		_endPoint = value;
	}

	public function new(animator:ParticleAnimator, particleBezierCurveNode:ParticleBezierCurveNode)
	{
		super(animator, particleBezierCurveNode);

		_particleBezierCurveNode = particleBezierCurveNode;
		_controlPoint = _particleBezierCurveNode.controlPoint;
		_endPoint = _particleBezierCurveNode.endPoint;
	}


	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		renderable = renderable;
		camera = camera;

		var controlIndex:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_CONTROL_INDEX);
		var endIndex:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_END_INDEX);

		if (_particleBezierCurveNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
		{
			animationSubGeometry.activateVertexBuffer(controlIndex, _particleBezierCurveNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			animationSubGeometry.activateVertexBuffer(endIndex, _particleBezierCurveNode.dataOffset + 3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
		else
		{
			animationRegisterCache.setVertexConst(controlIndex, _controlPoint.x, _controlPoint.y, _controlPoint.z);
			animationRegisterCache.setVertexConst(endIndex, _endPoint.x, _endPoint.y, _endPoint.z);
		}
	}
}

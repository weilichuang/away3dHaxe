package a3d.animators.states;

import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.nodes.ParticleBillboardNode;
import a3d.animators.ParticleAnimator;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import a3d.math.FMath;
import a3d.math.FMatrix3D;
import flash.geom.Matrix3D;
import flash.geom.Orientation3D;
import flash.geom.Vector3D;
import flash.Vector;

class ParticleBillboardState extends ParticleStateBase
{
	private var _matrix:Matrix3D;

	private var _billboardAxis:Vector3D;

	/**
	 *
	 */
	public function new(animator:ParticleAnimator, particleNode:ParticleBillboardNode)
	{
		super(animator, particleNode);
		billboardAxis = particleNode.billboardAxis;
		_matrix = new Matrix3D();
	}


	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var comps:Vector<Vector3D>;
		if (_billboardAxis != null)
		{
			var pos:Vector3D = renderable.sceneTransform.position;
			var look:Vector3D = camera.sceneTransform.position.subtract(pos);
			var right:Vector3D = look.crossProduct(_billboardAxis);
			right.normalize();
			look = _billboardAxis.crossProduct(right);
			look.normalize();

			//create a quick inverse projection matrix
			_matrix.copyFrom(renderable.sceneTransform);
			comps = FMatrix3D.decompose(_matrix, Orientation3D.AXIS_ANGLE);
			_matrix.copyColumnFrom(0, right);
			_matrix.copyColumnFrom(1, _billboardAxis);
			_matrix.copyColumnFrom(2, look);
			_matrix.copyColumnFrom(3, pos);
			_matrix.appendRotation(-comps[1].w * FMath.RADIANS_TO_DEGREES(), comps[1]);
		}
		else
		{
			//create a quick inverse projection matrix
			_matrix.copyFrom(renderable.sceneTransform);
			_matrix.append(camera.inverseSceneTransform);

			//decompose using axis angle rotations
			comps = FMatrix3D.decompose(_matrix, Orientation3D.AXIS_ANGLE);

			//recreate the matrix with just the rotation data
			_matrix.identity();
			_matrix.appendRotation(-comps[1].w * FMath.RADIANS_TO_DEGREES(), comps[1]);
		}

		//set a new matrix transform constant
		animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleBillboardNode.MATRIX_INDEX), _matrix);
	}

	/**
	 * Defines the billboard axis.
	 */
	public var billboardAxis(get,null):Vector3D;
	private function get_billboardAxis():Vector3D
	{
		return _billboardAxis;
	}

	private function set_billboardAxis(value:Vector3D):Vector3D
	{
		_billboardAxis = value != null ? value.clone() : null;
		if (_billboardAxis != null)
			_billboardAxis.normalize();
		return _billboardAxis;
	}

}

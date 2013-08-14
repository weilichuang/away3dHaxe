package a3d.animators.states;

import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticlePositionNode;
import a3d.animators.ParticleAnimator;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Vector3D;
import flash.Vector;
import haxe.ds.WeakMap;




/**
 * ...
 * @author ...
 */
class ParticlePositionState extends ParticleStateBase
{
	private var _particlePositionNode:ParticlePositionNode;
	private var _position:Vector3D;

	/**
	 * Defines the position of the particle when in global mode. Defaults to 0,0,0.
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

	/**
	 *
	 */
	public function getPositions():Vector<Vector3D>
	{
		return _dynamicProperties;
	}

	public function setPositions(value:Vector<Vector3D>):Void
	{
		_dynamicProperties = value;

		_dynamicPropertiesDirty = new WeakMap<AnimationSubGeometry,Bool>();
	}

	public function new(animator:ParticleAnimator, particlePositionNode:ParticlePositionNode)
	{
		super(animator, particlePositionNode);

		_particlePositionNode = particlePositionNode;
		_position = _particlePositionNode.position;
	}

	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (_particlePositionNode.mode == ParticlePropertiesMode.LOCAL_DYNAMIC && !_dynamicPropertiesDirty.get(animationSubGeometry))
			updateDynamicProperties(animationSubGeometry);

		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticlePositionNode.POSITION_INDEX);

		if (_particlePositionNode.mode == ParticlePropertiesMode.GLOBAL)
			animationRegisterCache.setVertexConst(index, _position.x, _position.y, _position.z);
		else
			animationSubGeometry.activateVertexBuffer(index, _particlePositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
	}
}

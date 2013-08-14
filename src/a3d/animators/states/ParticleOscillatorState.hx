package a3d.animators.states;

import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleOscillatorNode;
import a3d.animators.ParticleAnimator;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.errors.Error;
import flash.geom.Vector3D;





/**
 * ...
 */
class ParticleOscillatorState extends ParticleStateBase
{
	private var _particleOscillatorNode:ParticleOscillatorNode;
	private var _oscillator:Vector3D;
	private var _oscillatorData:Vector3D;

	/**
	 * Defines the default oscillator axis (x, y, z) and cycleDuration (w) of the state, used when in global mode.
	 */
	public var oscillator(get,set):Vector3D;
	private function get_oscillator():Vector3D
	{
		return _oscillator;
	}

	private function set_oscillator(value:Vector3D):Vector3D
	{
		_oscillator = value;

		updateOscillatorData();
		
		return _oscillator;
	}

	public function new(animator:ParticleAnimator, particleOscillatorNode:ParticleOscillatorNode)
	{
		super(animator, particleOscillatorNode);

		_particleOscillatorNode = particleOscillatorNode;
		_oscillator = _particleOscillatorNode.oscillator;

		updateOscillatorData();
	}

	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOscillatorNode.OSCILLATOR_INDEX);

		if (_particleOscillatorNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
			animationSubGeometry.activateVertexBuffer(index, _particleOscillatorNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		else
			animationRegisterCache.setVertexConst(index, _oscillatorData.x, _oscillatorData.y, _oscillatorData.z, _oscillatorData.w);
	}

	private function updateOscillatorData():Void
	{
		if (_particleOscillatorNode.mode == ParticlePropertiesMode.GLOBAL)
		{
			if (_oscillator.w <= 0)
				throw new Error("the cycle duration must greater than zero");
			if (_oscillatorData == null)
				_oscillatorData = new Vector3D();
			_oscillatorData.x = _oscillator.x;
			_oscillatorData.y = _oscillator.y;
			_oscillatorData.z = _oscillator.z;
			_oscillatorData.w = Math.PI * 2 / _oscillator.w;
		}
	}
}

package a3d.animators.states;

import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleOrbitNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;



/**
 * ...
 */
class ParticleOrbitState extends ParticleStateBase
{
	private var _particleOrbitNode:ParticleOrbitNode;
	private var _usesEulers:Bool;
	private var _usesCycle:Bool;
	private var _usesPhase:Bool;
	private var _radius:Float;
	private var _cycleDuration:Float;
	private var _cyclePhase:Float;
	private var _eulers:Vector3D;
	private var _orbitData:Vector3D;
	private var _eulersMatrix:Matrix3D;

	/**
	 * Defines the radius of the orbit when in global mode. Defaults to 100.
	 */
	private inline function get_radius():Float
	{
		return _radius;
	}

	private inline function set_radius(value:Float):Void
	{
		_radius = value;

		updateOrbitData();
	}

	/**
	 * Defines the duration of the orbit in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
	 */
	private inline function get_cycleDuration():Float
	{
		return _cycleDuration;
	}

	private inline function set_cycleDuration(value:Float):Void
	{
		_cycleDuration = value;

		updateOrbitData();
	}

	/**
	 * Defines the phase of the orbit in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
	 */
	private inline function get_cyclePhase():Float
	{
		return _cyclePhase;
	}

	private inline function set_cyclePhase(value:Float):Void
	{
		_cyclePhase = value;

		updateOrbitData();
	}

	/**
	 * Defines the euler rotation in degrees, applied to the orientation of the orbit when in global mode.
	 */
	private inline function get_eulers():Vector3D
	{
		return _eulers;
	}

	private inline function set_eulers(value:Vector3D):Void
	{
		_eulers = value;

		updateOrbitData();

	}

	public function ParticleOrbitState(animator:ParticleAnimator, particleOrbitNode:ParticleOrbitNode)
	{
		super(animator, particleOrbitNode);

		_particleOrbitNode = particleOrbitNode;
		_usesEulers = _particleOrbitNode.usesEulers;
		_usesCycle = _particleOrbitNode.usesCycle;
		_usesPhase = _particleOrbitNode.usesPhase;
		_eulers = _particleOrbitNode.eulers;
		_radius = _particleOrbitNode.radius;
		_cycleDuration = _particleOrbitNode.cycleDuration;
		_cyclePhase = _particleOrbitNode.cyclePhase;
		updateOrbitData();
	}

	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.ORBIT_INDEX);

		if (_particleOrbitNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
		{
			if (_usesPhase)
				animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			else
				animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
		else
		{
			animationRegisterCache.setVertexConst(index, _orbitData.x, _orbitData.y, _orbitData.z, _orbitData.w);
		}

		if (_usesEulers)
			animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.EULERS_INDEX), _eulersMatrix);
	}

	private function updateOrbitData():Void
	{
		if (_usesEulers)
		{
			_eulersMatrix = new Matrix3D();
			_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
			_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
			_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
		}
		if (_particleOrbitNode.mode == ParticlePropertiesMode.GLOBAL)
		{
			_orbitData = new Vector3D(_radius, 0, _radius * Math.PI * 2, _cyclePhase * Math.PI / 180);
			if (_usesCycle)
			{
				if (_cycleDuration <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				_orbitData.y = Math.PI * 2 / _cycleDuration;
			}
			else
				_orbitData.y = Math.PI * 2;
		}
	}
}

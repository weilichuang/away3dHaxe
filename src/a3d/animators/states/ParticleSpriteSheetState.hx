package a3d.animators.states;

import flash.display3D.Context3DVertexBufferFormat;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleSpriteSheetNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;



/**
 * ...
 */
class ParticleSpriteSheetState extends ParticleStateBase
{
	private var _particleSpriteSheetNode:ParticleSpriteSheetNode;
	private var _usesCycle:Bool;
	private var _usesPhase:Bool;
	private var _totalFrames:Int;
	private var _numColumns:Int;
	private var _numRows:Int;
	private var _cycleDuration:Float;
	private var _cyclePhase:Float;
	private var _spriteSheetData:Vector<Float>;

	/**
	 * Defines the cycle phase, when in global mode. Defaults to zero.
	 */
	private inline function get_cyclePhase():Float
	{
		return _cyclePhase;
	}

	private inline function set_cyclePhase(value:Float):Void
	{
		_cyclePhase = value;

		updateSpriteSheetData();
	}

	/**
	 * Defines the cycle duration in seconds, when in global mode. Defaults to 1.
	 */
	private inline function get_cycleDuration():Float
	{
		return _cycleDuration;
	}

	private inline function set_cycleDuration(value:Float):Void
	{
		_cycleDuration = value;

		updateSpriteSheetData();
	}

	public function new(animator:ParticleAnimator, particleSpriteSheetNode:ParticleSpriteSheetNode)
	{
		super(animator, particleSpriteSheetNode);

		_particleSpriteSheetNode = particleSpriteSheetNode;

		_usesCycle = _particleSpriteSheetNode.usesCycle;
		_usesPhase = _particleSpriteSheetNode.usesPhase;
		_totalFrames = _particleSpriteSheetNode._totalFrames;
		_numColumns = _particleSpriteSheetNode.numColumns;
		_numRows = _particleSpriteSheetNode.numRows;
		_cycleDuration = _particleSpriteSheetNode.cycleDuration;
		_cyclePhase = _particleSpriteSheetNode.cyclePhase;

		updateSpriteSheetData();
	}


	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (animationRegisterCache.needUVAnimation)
		{
			animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_0), _spriteSheetData[0], _spriteSheetData[1], _spriteSheetData[2],
				_spriteSheetData[3]);
			if (_usesCycle)
			{
				var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_1);
				if (_particleSpriteSheetNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
				{
					if (_usesPhase)
						animationSubGeometry.activateVertexBuffer(index, _particleSpriteSheetNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
					else
						animationSubGeometry.activateVertexBuffer(index, _particleSpriteSheetNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
				}
				else
				{
					animationRegisterCache.setVertexConst(index, _spriteSheetData[4], _spriteSheetData[5]);
				}
			}
		}
	}

	private function updateSpriteSheetData():Void
	{
		_spriteSheetData = new Vector<Float>(8, true);

		var uTotal:Float = _totalFrames / _numColumns;

		_spriteSheetData[0] = uTotal;
		_spriteSheetData[1] = 1 / _numColumns;
		_spriteSheetData[2] = 1 / _numRows;

		if (_usesCycle)
		{
			if (_cycleDuration <= 0)
				throw(new Error("the cycle duration must be greater than zero"));
			_spriteSheetData[4] = uTotal / _cycleDuration;
			_spriteSheetData[5] = _cycleDuration;
			if (_usesPhase)
				_spriteSheetData[6] = _cyclePhase;
		}
	}
}

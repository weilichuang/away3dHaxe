package a3d.animators.states;

import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.ColorTransform;
import flash.geom.Vector3D;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleInitialColorNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;




class ParticleInitialColorState extends ParticleStateBase
{
	private var _particleInitialColorNode:ParticleInitialColorNode;
	private var _usesMultiplier:Bool;
	private var _usesOffset:Bool;
	private var _initialColor:ColorTransform;
	private var _multiplierData:Vector3D;
	private var _offsetData:Vector3D;

	public function new(animator:ParticleAnimator, particleInitialColorNode:ParticleInitialColorNode)
	{
		super(animator, particleInitialColorNode);

		_particleInitialColorNode = particleInitialColorNode;
		_usesMultiplier = particleInitialColorNode.usesMultiplier;
		_usesOffset = particleInitialColorNode.usesOffset;
		_initialColor = particleInitialColorNode.initialColor;

		updateColorData();
	}

	/**
	 * Defines the initial color transform of the state, when in global mode.
	 */
	private function get_initialColor():ColorTransform
	{
		return _initialColor;
	}

	private function set_initialColor(value:ColorTransform):Void
	{
		_initialColor = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		renderable = renderable;
		camera = camera;

		if (animationRegisterCache.needFragmentAnimation)
		{
			if (_particleInitialColorNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
			{
				var dataOffset:UInt = _particleInitialColorNode.dataOffset;
				if (_usesMultiplier)
				{
					animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.MULTIPLIER_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.
						FLOAT_4);
					dataOffset += 4;
				}
				if (_usesOffset)
				{
					animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.OFFSET_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.
						FLOAT_4);
				}
			}
			else
			{
				if (_usesMultiplier)
					animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.MULTIPLIER_INDEX), _multiplierData.x, _multiplierData.y, _multiplierData.
						z, _multiplierData.w);
				if (_usesOffset)
					animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.OFFSET_INDEX), _offsetData.x, _offsetData.y, _offsetData.
						z, _offsetData.w);
			}
		}
	}

	private function updateColorData():Void
	{
		if (_particleInitialColorNode.mode == ParticlePropertiesMode.GLOBAL)
		{
			if (_usesMultiplier)
				_multiplierData = new Vector3D(_initialColor.redMultiplier, _initialColor.greenMultiplier, _initialColor.blueMultiplier, _initialColor.alphaMultiplier);
			if (_usesOffset)
				_offsetData = new Vector3D(_initialColor.redOffset / 255, _initialColor.greenOffset / 255, _initialColor.blueOffset / 255, _initialColor.alphaOffset / 255);
		}
	}

}

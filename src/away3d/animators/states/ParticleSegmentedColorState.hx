package away3d.animators.states;

import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.data.ColorSegmentPoint;
import away3d.animators.nodes.ParticleSegmentedColorNode;
import away3d.animators.ParticleAnimator;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.cameras.Camera3D;
import flash.geom.ColorTransform;
import flash.Vector;






class ParticleSegmentedColorState extends ParticleStateBase
{
	private var _usesMultiplier:Bool;
	private var _usesOffset:Bool;
	private var _startColor:ColorTransform;
	private var _endColor:ColorTransform;
	private var _segmentPoints:Vector<ColorSegmentPoint>;
	private var _numSegmentPoint:Int;


	private var _timeLifeData:Vector<Float>;
	private var _multiplierData:Vector<Float>;
	private var _offsetData:Vector<Float>;

	/**
	 * Defines the start color transform of the state, when in global mode.
	 */
	public var startColor(get,set):ColorTransform;
	private function get_startColor():ColorTransform
	{
		return _startColor;
	}

	private function set_startColor(value:ColorTransform):ColorTransform
	{
		_startColor = value;

		updateColorData();
		
		return _startColor;
	}

	/**
	 * Defines the end color transform of the state, when in global mode.
	 */
	public var endColor(get,set):ColorTransform;
	private function get_endColor():ColorTransform
	{
		return _endColor;
	}

	private function set_endColor(value:ColorTransform):ColorTransform
	{
		_endColor = value;
		updateColorData();
		return _endColor;
	}

	/**
	 * Defines the number of segments.
	 */
	public var numSegmentPoint(get,null):Int;
	private function get_numSegmentPoint():Int
	{
		return _numSegmentPoint;
	}

	/**
	 * Defines the key points of color
	 */
	public var segmentPoints(get,set):Vector<ColorSegmentPoint>;
	private function get_segmentPoints():Vector<ColorSegmentPoint>
	{
		return _segmentPoints;
	}

	private function set_segmentPoints(value:Vector<ColorSegmentPoint>):Vector<ColorSegmentPoint>
	{
		_segmentPoints = value;
		updateColorData();
		return _segmentPoints;
	}

	public var usesMultiplier(get,null):Bool;
	private function get_usesMultiplier():Bool
	{
		return _usesMultiplier;
	}

	public var usesOffset(get,null):Bool;
	private function get_usesOffset():Bool
	{
		return _usesOffset;
	}


	public function new(animator:ParticleAnimator, particleSegmentedColorNode:ParticleSegmentedColorNode)
	{
		super(animator, particleSegmentedColorNode);

		_usesMultiplier = particleSegmentedColorNode.usesMultiplier;
		_usesOffset = particleSegmentedColorNode.usesOffset;
		_startColor = particleSegmentedColorNode.startColor;
		_endColor = particleSegmentedColorNode.endColor;
		_segmentPoints = particleSegmentedColorNode.segmentPoints;
		_numSegmentPoint = particleSegmentedColorNode.numSegmentPoint;
		updateColorData();
	}

	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (animationRegisterCache.needFragmentAnimation)
		{
			if (_numSegmentPoint > 0)
				animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedColorNode.TIME_DATA_INDEX), _timeLifeData[0], _timeLifeData[1], _timeLifeData[2],
					_timeLifeData[3]);
			if (_usesMultiplier)
				animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedColorNode.START_MULTIPLIER_INDEX), _multiplierData);
			if (_usesOffset)
				animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedColorNode.START_OFFSET_INDEX), _offsetData);
		}
	}

	private function updateColorData():Void
	{
		_timeLifeData = new Vector<Float>();
		_multiplierData = new Vector<Float>();
		_offsetData = new Vector<Float>();

		for (i in 0..._numSegmentPoint)
		{
			if (i == 0)
				_timeLifeData.push(_segmentPoints[i].life);
			else
				_timeLifeData.push(_segmentPoints[i].life - _segmentPoints[i - 1].life);
		}
		if (_numSegmentPoint == 0)
			_timeLifeData.push(1);
		else
			_timeLifeData.push(1 - _segmentPoints[_numSegmentPoint - 1].life);

		if (_usesMultiplier)
		{
			_multiplierData.push(_startColor.redMultiplier);
			_multiplierData.push(_startColor.greenMultiplier);
			_multiplierData.push(_startColor.blueMultiplier);
			_multiplierData.push(_startColor.alphaMultiplier);
			for (i in 0..._numSegmentPoint)
			{
				var time:Float = _timeLifeData[i];
				if (i == 0)
				{
					var point:ColorSegmentPoint = _segmentPoints[i];
					_multiplierData.push((point.color.redMultiplier - _startColor.redMultiplier) / time); 
					_multiplierData.push((point.color.greenMultiplier - _startColor.greenMultiplier) /time); 
					_multiplierData.push((point.color.blueMultiplier - _startColor.blueMultiplier) / time); 
					_multiplierData.push((point.color.alphaMultiplier - _startColor.alphaMultiplier) /time);
				}
				else
				{
					_multiplierData.push((_segmentPoints[i].color.redMultiplier - _segmentPoints[i - 1].color.redMultiplier) / _timeLifeData[i]);
					_multiplierData.push((_segmentPoints[i].color.greenMultiplier - _segmentPoints[i -1].color.greenMultiplier) / _timeLifeData[i]); 
					_multiplierData.push((_segmentPoints[i].color.blueMultiplier - _segmentPoints[i - 1].color.blueMultiplier) / _timeLifeData[i]);
					_multiplierData.push((_segmentPoints[i].color.alphaMultiplier - _segmentPoints[i - 1].color.alphaMultiplier) / _timeLifeData[i]);
				}
			}
			
			if (_numSegmentPoint == 0)
			{
				_multiplierData.push(_endColor.redMultiplier - _startColor.redMultiplier);
				_multiplierData.push(_endColor.greenMultiplier - _startColor.greenMultiplier);
				_multiplierData.push(_endColor.blueMultiplier - _startColor.blueMultiplier);
				_multiplierData.push(_endColor.alphaMultiplier - _startColor.alphaMultiplier);
			}
			else
			{
				_multiplierData.push((_endColor.redMultiplier - _segmentPoints[_numSegmentPoint - 1].color.redMultiplier) / _timeLifeData[_numSegmentPoint]);
				_multiplierData.push((_endColor.greenMultiplier - _segmentPoints[_numSegmentPoint - 1].color.greenMultiplier) /_timeLifeData[_numSegmentPoint]);
				_multiplierData.push((_endColor.blueMultiplier - _segmentPoints[_numSegmentPoint - 1].color.blueMultiplier) / _timeLifeData[_numSegmentPoint]);
				_multiplierData.push((_endColor.alphaMultiplier - _segmentPoints[_numSegmentPoint - 1].color.alphaMultiplier) /_timeLifeData[_numSegmentPoint]);
			}
		}

		if (_usesOffset)
		{
			_offsetData.push(_startColor.redOffset / 255);
			_offsetData.push(_startColor.greenOffset / 255); 
			_offsetData.push(_startColor.blueOffset / 255);
			_offsetData.push(_startColor.alphaOffset / 255);
			for (i in 0..._numSegmentPoint)
			{
				if (i == 0)
				{
					
					_offsetData.push((_segmentPoints[i].color.redOffset - _startColor.redOffset) / _timeLifeData[i] / 255);
					_offsetData.push((_segmentPoints[i].color.greenOffset - _startColor.greenOffset) / _timeLifeData[i] /255); 
					_offsetData.push((_segmentPoints[i].color.blueOffset - _startColor.blueOffset) / _timeLifeData[i] / 255); 
					_offsetData.push((_segmentPoints[i].color.alphaOffset - _startColor.alphaOffset) / _timeLifeData[i] /255);
				}
				else
				{
					_offsetData.push((_segmentPoints[i].color.redOffset - _segmentPoints[i - 1].color.redOffset) / _timeLifeData[i] / 255); 
					_offsetData.push((_segmentPoints[i].color.greenOffset - _segmentPoints[i -1].color.greenOffset) / _timeLifeData[i] / 255);
					_offsetData.push((_segmentPoints[i].color.blueOffset - _segmentPoints[i - 1].color.blueOffset) / _timeLifeData[i] / 255);
					_offsetData.push((_segmentPoints[i].color.alphaOffset - _segmentPoints[i - 1].color.alphaOffset) / _timeLifeData[i] / 255);
				}
			}
			if (_numSegmentPoint == 0)
			{
				_offsetData.push((_endColor.redOffset - _startColor.redOffset) / 255); 
				_offsetData.push((_endColor.greenOffset - _startColor.greenOffset) / 255);
				_offsetData.push((_endColor.blueOffset - _startColor.blueOffset) / 255);
				_offsetData.push((_endColor.alphaOffset - _startColor.alphaOffset) / 255);
			}
			else
			{
				_offsetData.push((_endColor.redOffset - _segmentPoints[_numSegmentPoint - 1].color.redOffset) / _timeLifeData[_numSegmentPoint] / 255);
				_offsetData.push((_endColor.greenOffset - _segmentPoints[_numSegmentPoint - 1].color.greenOffset) / _timeLifeData[_numSegmentPoint] /255);
				_offsetData.push((_endColor.blueOffset - _segmentPoints[_numSegmentPoint - 1].color.blueOffset) / _timeLifeData[_numSegmentPoint] / 255); 
				_offsetData.push((_endColor.alphaOffset - _segmentPoints[_numSegmentPoint - 1].color.alphaOffset) / _timeLifeData[_numSegmentPoint] /255);
			}
		}
		//cut off the data
		_timeLifeData.length = 4;
	}
}

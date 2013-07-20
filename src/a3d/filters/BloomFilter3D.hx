package a3d.filters;

import a3d.math.FMath;
import flash.display3D.textures.Texture;

import a3d.core.managers.Stage3DProxy;
import a3d.filters.tasks.Filter3DBloomCompositeTask;
import a3d.filters.tasks.Filter3DBrightPassTask;
import a3d.filters.tasks.Filter3DHBlurTask;
import a3d.filters.tasks.Filter3DVBlurTask;

class BloomFilter3D extends Filter3DBase
{
	public var exposure(get, set):Float;
	public var blurX(get, set):Int;
	public var blurY(get, set):Int;
	public var threshold(get, set):Float;
	
	private var _brightPassTask:Filter3DBrightPassTask;
	private var _vBlurTask:Filter3DVBlurTask;
	private var _hBlurTask:Filter3DHBlurTask;
	private var _compositeTask:Filter3DBloomCompositeTask;

	public function new(blurX:UInt = 15, blurY:UInt = 15, threshold:Float = .75, exposure:Float = 2, quality:Int = 3)
	{
		super();
		
		_brightPassTask = new Filter3DBrightPassTask(threshold);
		_hBlurTask = new Filter3DHBlurTask(blurX);
		_vBlurTask = new Filter3DVBlurTask(blurY);
		_compositeTask = new Filter3DBloomCompositeTask(exposure);

		quality = FMath.clamp(quality, 0, 4);

		_hBlurTask.textureScale = (4 - quality);
		_vBlurTask.textureScale = (4 - quality);
		// composite's main input texture is from vBlur, so needs to be scaled down
		_compositeTask.textureScale = (4 - quality);

		addTask(_brightPassTask);
		addTask(_hBlurTask);
		addTask(_vBlurTask);
		addTask(_compositeTask);
	}

	override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
	{
		_brightPassTask.target = _hBlurTask.getMainInputTexture(stage3DProxy);
		_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
		_vBlurTask.target = _compositeTask.getMainInputTexture(stage3DProxy);
		// use bright pass's input as composite's input
		_compositeTask.overlayTexture = _brightPassTask.getMainInputTexture(stage3DProxy);

		super.setRenderTargets(mainTarget, stage3DProxy);
	}

	private function get_exposure():Float
	{
		return _compositeTask.exposure;
	}

	private function set_exposure(value:Float):Float
	{
		return _compositeTask.exposure = value;
	}

	
	private function get_blurX():Int
	{
		return _hBlurTask.amount;
	}

	private function set_blurX(value:Int):Int
	{
		return _hBlurTask.amount = value;
	}

	
	private function get_blurY():Int
	{
		return _vBlurTask.amount;
	}

	private function set_blurY(value:Int):Int
	{
		return _vBlurTask.amount = value;
	}

	
	private function get_threshold():Float
	{
		return _brightPassTask.threshold;
	}

	private function set_threshold(value:Float):Float
	{
		return _brightPassTask.threshold = value;
	}
}

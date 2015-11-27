package away3d.textures;

import away3d.textures.BitmapTexture;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.Shader;
import flash.display.ShaderJob;
import flash.errors.Error;
import flash.geom.Point;
import flash.geom.Rectangle;

class SplatBlendBitmapTexture extends BitmapTexture
{
	private var _numSplattingLayers:Int;

	/**
	 *
	 * @param blendingData An array of BitmapData objects to be used for the blend data, as required by TerrainDiffuseMethod.
	 */
	public function new(blendingData:Array<BitmapData>, normalize:Bool = false)
	{
		var bitmapData:BitmapData = blendingData[0].clone();
		var channels:Array<BitmapDataChannel> = [BitmapDataChannel.RED, BitmapDataChannel.GREEN, BitmapDataChannel.BLUE];

		super(bitmapData);

		_numSplattingLayers = blendingData.length;
		if (_numSplattingLayers > 3)
			throw new Error("blendingData can not have more than 3 elements!");

		var rect:Rectangle = bitmapData.rect;
		var origin:Point = new Point();

		for (i in 0...blendingData.length)
		{
			bitmapData.copyChannel(blendingData[i], rect, origin, BitmapDataChannel.RED, channels[i]);
		}

		if (normalize)
			normalizeSplats();
	}

	private function normalizeSplats():Void
	{
		if (_numSplattingLayers <= 1)
			return;
		var shader:Shader = new Shader(new NormalizeKernel());
		shader.data.numLayers = _numSplattingLayers;
		shader.data.src.input = bitmapData;
		new ShaderJob(shader, bitmapData).start(true);
	}

	override public function dispose():Void
	{
		super.dispose();
		bitmapData.dispose();
	}
}

@:file("pb/NormalizeSplats.pbj") class NormalizeKernel extends ByteArray {}

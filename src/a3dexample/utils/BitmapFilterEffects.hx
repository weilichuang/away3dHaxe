package a3dexample.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DisplacementMapFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;

	import a3d.textures.BitmapCubeTexture;


	class BitmapFilterEffects extends Sprite
	{
		[Embed(source = "/pb/Sharpen.pbj", mimeType = "application/octet-stream")]
		public static var SharpenClass:Class;
		[Embed(source = "/pb/NormalMap.pbj", mimeType = "application/octet-stream")]
		public static var NormalMapClass:Class;
		[Embed(source = "/pb/Outline.pbj", mimeType = "application/octet-stream")]
		public static var OutlineClass:Class;

		private static var _bitmap:Bitmap = new Bitmap();

		//sharpen vars
		private static var _sharpenShader:Shader = new Shader(new SharpenClass());
		private static var _sharpenFilters:Array = [new ShaderFilter(_sharpenShader)];

		//normal map vars
		private static var _normalMapShader:Shader = new Shader(new NormalMapClass());
		private static var _normalMapFilters:Array = [new ShaderFilter(_normalMapShader)];

		//outline vars
		private static var _outlineShader:Shader = new Shader(new OutlineClass());
		private static var _outlineFilters:Array = [new ShaderFilter(_outlineShader)];

		static public function sharpen(sourceBitmap:BitmapData, amount:Float = 20, radius:Float = 0.1):BitmapData
		{
			var returnBitmap:BitmapData = new BitmapData(sourceBitmap.width, sourceBitmap.height, sourceBitmap.transparent, 0x0);

			_sharpenShader.data.amount.value = [amount];
			_sharpenShader.data.radius.value = [radius];

			_bitmap.bitmapData = sourceBitmap;
			_bitmap.filters = _sharpenFilters;
			returnBitmap.draw(_bitmap);

			return returnBitmap;
		}

		static public function normalMap(sourceBitmap:BitmapData, amount:Float = 10, softSobel:Float = 1, redMultiplier:Float = -1, greeMultiplier:Float = -1):BitmapData
		{
			var returnBitmap:BitmapData = new BitmapData(sourceBitmap.width, sourceBitmap.height, sourceBitmap.transparent, 0x0);

			_normalMapShader.data.amount.value = [amount]; //0 to 5
			_normalMapShader.data.soft_sobel.value = [softSobel]; //int 0 or 1
			_normalMapShader.data.invert_red.value = [redMultiplier]; //-1 to 1
			_normalMapShader.data.invert_green.value = [greeMultiplier]; //-1 to 1

			_bitmap.bitmapData = sourceBitmap;
			_bitmap.filters = _normalMapFilters;
			returnBitmap.draw(_bitmap);

			return returnBitmap;
		}

		static public function outline(sourceBitmap:BitmapData, differenceMin:Float = 0.15, differenceMax:Float = 1, outputColor:UInt = 0xFFFFFF, backgroundColor:UInt = 0x000000):BitmapData
		{
			differenceMin = differenceMin;
			differenceMax = differenceMax;
			var returnBitmap:BitmapData = new BitmapData(sourceBitmap.width, sourceBitmap.height, sourceBitmap.transparent, 0x0);

			_outlineShader.data.difference.value = [1, 0.15];
			_outlineShader.data.color.value = [((outputColor & 0xFF0000) >> 16) / 255, ((outputColor & 0x00FF00) >> 8) / 255, (outputColor & 0x0000FF) / 255, 1];
			_outlineShader.data.bgcolor.value = [((backgroundColor & 0xFF0000) >> 16) / 255, ((backgroundColor & 0x00FF00) >> 8) / 255, (backgroundColor & 0x0000FF) / 255, 1];

			_bitmap.bitmapData = sourceBitmap;
			_bitmap.filters = _outlineFilters;
			returnBitmap.draw(_bitmap);

			return returnBitmap;
		}

		/**
		 * create vector sky
		 */
		static public function vectorSky(zenithColor:UInt, horizonColor:UInt, nadirColor:UInt, quality:UInt = 8):BitmapCubeTexture
		{
			var xl:UInt = 128 * quality;
			var pinch:UInt = xl / 3.6;

			// sky color from bottom to top;
			var color:Vector<uint> = Vector<uint>([lighten(nadirColor, 50), darken(nadirColor, 25), darken(nadirColor, 5), horizonColor, horizonColor, zenithColor, darken(zenithColor, 25), darken(zenithColor,
				50)]); // clear
			var side:BitmapData = new BitmapData(xl, xl, false, color[1]);
			var top:BitmapData = new BitmapData(xl, xl, false, color[6]);
			var floor:BitmapData = new BitmapData(xl, xl, false, color[1]);

			// side
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(xl, xl, -Math.PI / 2);
			var g:Shape = new Shape();
			g.graphics.beginGradientFill('linear', [color[1], color[2], color[3], color[4], color[5], color[6]], [1, 1, 1, 1, 1, 1], [90, 110, 120, 126, 180, 230], matrix);
			g.graphics.drawRect(0, 0, xl, xl);
			g.graphics.endFill();
			var displacement_map:DisplacementMapFilter = new DisplacementMapFilter(pinchMap(xl, xl), new Point(0, 0), 4, 2, 0, pinch, "clamp");
			g.filters = [displacement_map];
			side.draw(g);

			// top
			g = new Shape();
			matrix = new Matrix();
			matrix.createGradientBox(xl, xl, 0, 0, 0);
			g.graphics.beginGradientFill('radial', [color[7], color[6]], [1, 1], [0, 255], matrix);
			g.graphics.drawEllipse(0, 0, xl, xl);
			g.graphics.endFill();
			top.draw(g);

			// bottom
			g = new Shape();
			matrix = new Matrix();
			matrix.createGradientBox(xl, xl, 0, 0, 0);
			g.graphics.beginGradientFill('radial', [color[0], color[1]], [1, 1], [0, 255], matrix);
			g.graphics.drawEllipse(0, 0, xl, xl);
			g.graphics.endFill();
			floor.draw(g);

			return new BitmapCubeTexture(side, side, top, floor, side, side);
		}

		/**
		 * add sphericale distortion
		 */
		static private function pinchMap(w:UInt, h:UInt):BitmapData
		{
			var b:BitmapData = new BitmapData(w, h, false, 0x000000);
			var vx:UInt = w >> 1;
			var vy:UInt = h >> 1;

			for (var j:UInt = 0; j < h; j++)
			{
				for (var i:UInt = 0; i < w; i++)
				{
					var BCol:Float = 127 + (i - vx) / (vx) * 127 * (1 - Math.pow((j - vy) / (vy), 2));
					var GCol:Float = 127 + (j - vy) / (vy) * 127 * (1 - Math.pow((i - vx) / (vx), 2));
					b.setPixel(i, j, (GCol << 8) | BCol);
				}
			}

			return b;
		}

		/**
		 * lighten color
		 */
		static public function lighten(color:UInt, percent:Float):Float
		{
			if (isNaN(percent) || percent <= 0)
				return color;

			if (percent >= 100)
				return 0xFFFFFF;

			var factor:Float = percent / 100;
			var channel:Float = factor * 255;
			var rgb:Vector<uint> = hexToRgb(color);
			factor = 1 - factor;

			return rgbToHex(channel + rgb[0] * factor, channel + rgb[1] * factor, channel + rgb[2] * factor);
		}

		/**
		 * darken color
		 */
		static public function darken(color:UInt, percent:Float):UInt
		{
			if (isNaN(percent) || percent <= 0)
				return color;

			if (percent >= 100)
				return 0x000000;

			var factor:Float = 1 - (percent / 100);
			var rgb:Vector<uint> = hexToRgb(color);

			return rgbToHex(rgb[0] * factor, rgb[1] * factor, rgb[2] * factor);
		}

		/**
		 * conversion
		 */
		static public function rgbToHex(r:UInt, g:UInt, b:UInt):Float
		{
			return (r << 16 | g << 8 | b);
		}

		static public function hexToRgb(color:UInt):Vector<uint>
		{
			return Vector<uint>([(color & 0xff0000) >> 16, (color & 0x00ff00) >> 8, color & 0x0000ff]);
		}
	}
}

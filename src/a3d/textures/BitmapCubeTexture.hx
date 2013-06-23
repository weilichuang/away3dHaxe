package a3d.textures
{
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;

	
	import a3d.materials.utils.MipmapGenerator;
	import a3d.tools.utils.TextureUtils;

	

	class BitmapCubeTexture extends CubeTextureBase
	{
		private var _bitmapDatas:Vector<BitmapData>;

		//private var _useAlpha : Bool;

		public function BitmapCubeTexture(posX:BitmapData, negX:BitmapData, posY:BitmapData, negY:BitmapData, posZ:BitmapData, negZ:BitmapData)
		{
			super();

			_bitmapDatas = new Vector<BitmapData>(6, true);
			testSize(_bitmapDatas[0] = posX);
			testSize(_bitmapDatas[1] = negX);
			testSize(_bitmapDatas[2] = posY);
			testSize(_bitmapDatas[3] = negY);
			testSize(_bitmapDatas[4] = posZ);
			testSize(_bitmapDatas[5] = negZ);

			setSize(posX.width, posX.height);
		}

		/**
		 * The texture on the cube's right face.
		 */
		private inline function get_positiveX():BitmapData
		{
			return _bitmapDatas[0];
		}

		private inline function set_positiveX(value:BitmapData):Void
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[0] = value;
		}

		/**
		 * The texture on the cube's left face.
		 */
		private inline function get_negativeX():BitmapData
		{
			return _bitmapDatas[1];
		}

		private inline function set_negativeX(value:BitmapData):Void
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[1] = value;
		}

		/**
		 * The texture on the cube's top face.
		 */
		private inline function get_positiveY():BitmapData
		{
			return _bitmapDatas[2];
		}

		private inline function set_positiveY(value:BitmapData):Void
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[2] = value;
		}

		/**
		 * The texture on the cube's bottom face.
		 */
		private inline function get_negativeY():BitmapData
		{
			return _bitmapDatas[3];
		}

		private inline function set_negativeY(value:BitmapData):Void
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[3] = value;
		}

		/**
		 * The texture on the cube's far face.
		 */
		private inline function get_positiveZ():BitmapData
		{
			return _bitmapDatas[4];
		}

		private inline function set_positiveZ(value:BitmapData):Void
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[4] = value;
		}

		/**
		 * The texture on the cube's near face.
		 */
		private inline function get_negativeZ():BitmapData
		{
			return _bitmapDatas[5];
		}

		private inline function set_negativeZ(value:BitmapData):Void
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[5] = value;
		}

		private function testSize(value:BitmapData):Void
		{
			if (value.width != value.height)
				throw new Error("BitmapData should have equal width and height!");
			if (!TextureUtils.isBitmapDataValid(value))
				throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
		}


		override private function uploadContent(texture:TextureBase):Void
		{
			for (var i:Int = 0; i < 6; ++i)
				MipmapGenerator.generateMipMaps(_bitmapDatas[i], texture, null, _bitmapDatas[i].transparent, i);
		}
	}
}

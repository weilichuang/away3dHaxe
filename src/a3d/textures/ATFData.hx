package a3d.textures
{
	import flash.display3D.Context3DTextureFormat;
	import flash.utils.ByteArray;

	/**
	 * @author simo
	 */
	class ATFData
	{

		public static inline var TYPE_NORMAL:Int = 0x0;
		public static inline var TYPE_CUBE:Int = 0x1;

		public var type:Int;
		public var format:String;
		public var width:Int;
		public var height:Int;
		public var numTextures:Int;
		public var data:ByteArray;
		public var totalBytes:Int;

		/** Create a new instance by parsing the given byte array. */
		public function ATFData(data:ByteArray)
		{

			var sign:String = data.readUTFBytes(3);
			if (sign != "ATF")
				throw new Error("ATF parsing error, unknown format " + sign);

			this.totalBytes = (data.readUnsignedByte() << 16) + (data.readUnsignedByte() << 8) + data.readUnsignedByte();

			var tdata:UInt = data.readUnsignedByte();
			var _type:Int = tdata >> 7; // UB[1]
			var _format:Int = tdata & 0x7f; // UB[7]

			switch (_format)
			{
				case 0:
				case 1:
					format = Context3DTextureFormat.BGRA;
					break;
				case 2:
				case 3:
					format = Context3DTextureFormat.COMPRESSED;
					break;
				case 4:
				case 5:
					format = "compressedAlpha";
					break; // explicit string to stay compatible 
				// with older versions
				default:
					throw new Error("Invalid ATF format");
			}

			switch (_type)
			{
				case 0:
					type = ATFData.TYPE_NORMAL;
					break;
				case 1:
					type = ATFData.TYPE_CUBE;
					break;

				default:
					throw new Error("Invalid ATF type");
			}

			this.width = Math.pow(2, data.readUnsignedByte());
			this.height = Math.pow(2, data.readUnsignedByte());
			this.numTextures = data.readUnsignedByte();
			this.data = data;
		}

	}
}

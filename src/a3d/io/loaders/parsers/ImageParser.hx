package a3d.io.loaders.parsers;
	
import a3d.events.AssetEvent;
import a3d.io.library.assets.BitmapDataAsset;
import a3d.textures.ATFTexture;
import a3d.textures.BitmapTexture;
import a3d.textures.Texture2DBase;
import a3d.tools.utils.TextureUtils;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.utils.ByteArray;



/**
 * ImageParser provides a "parser" for natively supported image types (jpg, png). While it simply loads bytes into
 * a loader object, it wraps it in a BitmapDataResource so resource management can happen consistently without
 * exception cases.
 */
class ImageParser extends ParserBase
{
	private var _byteData:ByteArray;
	private var _startedParsing:Bool;
	private var _doneParsing:Bool;
	private var _loader:Loader;

	/**
	 * Creates a new ImageParser object.
	 * @param uri The url or id of the data or file to be parsed.
	 * @param extra The holder for extra contextual data that the parser might need.
	 */
	public function new()
	{
		super(ParserDataFormat.BINARY);
	}

	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */

	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "jpg" || extension == "jpeg" || extension == "png" || extension == "gif" || extension == "bmp" || extension == "atf";
	}


	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:*):Bool
	{
		//shortcut if asset is IFlexAsset
		if (Std.is(data,Bitmap))
			return true;

		if (Std.is(data,BitmapData))
			return true;

		if (!Std.is(data,ByteArray))
			return false;

		var ba:ByteArray = Std.instance(data,ByteArray);
		ba.position = 0;
		if (ba.readUnsignedShort() == 0xffd8)
			return true; // JPEG, maybe check for "JFIF" as well?

		ba.position = 0;
		if (ba.readShort() == 0x424D)
			return true; // BMP

		ba.position = 1;
		if (ba.readUTFBytes(3) == 'PNG')
			return true;

		ba.position = 0;
		if (ba.readUTFBytes(3) == 'GIF' && ba.readShort() == 0x3839 && ba.readByte() == 0x61)
			return true;

		ba.position = 0;
		if (ba.readUTFBytes(3) == 'ATF')
			return true;

		return false;
	}

	/**
	 * @inheritDoc
	 */
	override private function proceedParsing():Bool
	{
		var asset:Texture2DBase;
		if (Std.is(_data,Bitmap))
		{
			asset = new BitmapTexture(Bitmap(_data).bitmapData);
			finalizeAsset(asset, fileName);
			return PARSING_DONE;
		}

		if (Std.is(_data,BitmapData))
		{
			asset = new BitmapTexture(Std.instance(_data,BitmapData));
			finalizeAsset(asset, fileName);
			return PARSING_DONE;
		}

		_byteData = getByteData();
		if (!_startedParsing)
		{
			if (_byteData.readUTFBytes(3) == 'ATF')
			{
				_byteData.position = 0;
				asset = new ATFTexture(_byteData);
				finalizeAsset(asset, fileName);
				return PARSING_DONE;
			}
			else
			{
				_byteData.position = 0;
				_loader = new Loader();
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				_loader.loadBytes(_byteData);
				_startedParsing = true;
			}
		}

		return _doneParsing;
	}

	/**
	 * Called when "loading" is complete.
	 */
	private function onLoadComplete(event:Event):Void
	{
		var bmp:BitmapData = Bitmap(_loader.content).bitmapData;
		var asset:BitmapTexture;

		_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);

		if (!TextureUtils.isBitmapDataValid(bmp))
		{
			var bmdAsset:BitmapDataAsset = new BitmapDataAsset(bmp);
			bmdAsset.name = fileName;

			dispatchEvent(new AssetEvent(AssetEvent.TEXTURE_SIZE_ERROR, bmdAsset));

			bmp = new BitmapData(8, 8, false, 0x0);

			//create chekerboard for this texture rather than a new Default Material
			var i:UInt, j:UInt;
			for (i = 0; i < 8; i++)
			{
				for (j = 0; j < 8; j++)
				{
					if ((j & 1) ^ (i & 1))
						bmp.setPixel(i, j, 0XFFFFFF);
				}
			}
		}

		asset = new BitmapTexture(bmp);
		finalizeAsset(asset, fileName);
		_doneParsing = true;
	}
}

package a3d.io.loaders.parsers;

import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.Endian;
import flash.Vector;


import a3d.animators.VertexAnimationSet;
import a3d.animators.nodes.VertexClipNode;
import a3d.core.base.CompactSubGeometry;
import a3d.core.base.Geometry;
import a3d.entities.Mesh;
import a3d.io.loaders.misc.ResourceDependency;
import a3d.io.loaders.parsers.utils.ParserUtil;
import a3d.materials.MaterialBase;
import a3d.materials.TextureMaterial;
import a3d.materials.TextureMultiPassMaterial;
import a3d.materials.utils.DefaultMaterialManager;
import a3d.textures.Texture2DBase;



/**
 * MD2Parser provides a parser for the MD2 data type.
 */
class MD2Parser extends ParserBase
{
	public static var FPS:int = 6;

	private var _clipNodes:Dictionary = new Dictionary(true);
	private var _byteData:ByteArray;
	private var _startedParsing:Bool;
	private var _parsedHeader:Bool;
	private var _parsedUV:Bool;
	private var _parsedFaces:Bool;
	private var _parsedFrames:Bool;

	private var _ident:UInt;
	private var _version:UInt;
	private var _skinWidth:UInt;
	private var _skinHeight:UInt;
	//private var _frameSize : uint;
	private var _numSkins:UInt;
	private var _numVertices:UInt;
	private var _numST:UInt;
	private var _numTris:UInt;
	//private var _numGlCmds : uint;
	private var _numFrames:UInt;
	private var _offsetSkins:UInt;
	private var _offsetST:UInt;
	private var _offsetTris:UInt;
	private var _offsetFrames:UInt;
	//private var _offsetGlCmds : uint;
	private var _offsetEnd:UInt;

	private var _uvIndices:Vector<Number>;
	private var _indices:Vector<uint>;
	private var _vertIndices:Vector<Number>;

	// the current subgeom being built
	private var _animationSet:VertexAnimationSet = new VertexAnimationSet();
	private var _firstSubGeom:CompactSubGeometry;
	private var _uvs:Vector<Number>;
	private var _finalUV:Vector<Number>;

	private var _materialNames:Vector<String>;
	private var _textureType:String;
	private var _ignoreTexturePath:Bool;
	private var _mesh:Mesh;
	private var _geometry:Geometry;

	private var materialFinal:Bool = false;
	private var geoCreated:Bool = false;

	/**
	 * Creates a new MD2Parser object.
	 * @param uri The url or id of the data or file to be parsed.
	 * @param extra The holder for extra contextual data that the parser might need.
	 */
	public function new(textureType:String = "jpg", ignoreTexturePath:Bool = true)
	{
		super(ParserDataFormat.BINARY);
		_textureType = textureType;
		_ignoreTexturePath = ignoreTexturePath;
	}

	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "md2";
	}

	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:*):Bool
	{
		return (ParserUtil.toString(data, 4) == 'IDP2');
	}

	/**
	 * @inheritDoc
	 */
	override public function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (resourceDependency.assets.length != 1)
			return;

		var asset:Texture2DBase = Std.instance(resourceDependency.assets[0],Texture2DBase);
		if (asset)
		{
			var material:MaterialBase;
			if (materialMode < 2)
				material = new TextureMaterial(asset);
			else
				material = new TextureMultiPassMaterial(asset);

			material.name = _mesh.material.name;
			_mesh.material = material;
			finalizeAsset(material);
			finalizeAsset(_mesh.geometry);
			finalizeAsset(_mesh);
		}
		materialFinal = true;
	}

	/**
	 * @inheritDoc
	 */
	override public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		// apply system default
		if (materialMode < 2)
			_mesh.material = DefaultMaterialManager.getDefaultMaterial();
		else
			_mesh.material = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());

		finalizeAsset(_mesh.geometry);
		finalizeAsset(_mesh);
		materialFinal = true;

	}

	/**
	 * @inheritDoc
	 */
	override private function proceedParsing():Bool
	{
		if (!_startedParsing)
		{
			_byteData = getByteData();
			_startedParsing = true;

			// Reset bytearray read position (which may have been 
			// moved forward by the supportsData() function.)
			_byteData.position = 0;
		}

		while (hasTime())
		{
			if (!_parsedHeader)
			{
				_byteData.endian = Endian.LITTLE_ENDIAN;

				// TODO: Create a mesh only when encountered (if it makes sense
				// for this file format) and return it using finalizeAsset()
				_geometry = new Geometry();
				_mesh = new Mesh(_geometry, null);
				if (materialMode < 2)
					_mesh.material = DefaultMaterialManager.getDefaultMaterial();
				else
					_mesh.material = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());

				//_geometry.animation = new VertexAnimation(2, VertexAnimationMode.ABSOLUTE);
				//_animator = new VertexAnimator(VertexAnimationState(_mesh.animationState));

				// Parse header and decompress body
				parseHeader();
				parseMaterialNames();
			}

			else if (!_parsedUV)
			{
				parseUV();
			}

			else if (!_parsedFaces)
			{
				parseFaces();
			}

			else if (!_parsedFrames)
			{
				parseFrames();
			}
			else if ((geoCreated) && (materialFinal))
				return PARSING_DONE;

			else if (!geoCreated)
			{
				geoCreated = true;
				createDefaultSubGeometry();
				// Force name to be chosen by finalizeAsset()
				_mesh.name = "";
				if (materialFinal)
				{
					finalizeAsset(_mesh.geometry);
					finalizeAsset(_mesh);
				}

				pauseAndRetrieveDependencies();
			}
		}

		return MORE_TO_PARSE;
	}

	/**
	 * Reads in all that MD2 Header data that is declared as private variables.
	 * I know its a lot, and it looks ugly, but only way to do it in Flash
	 */
	private function parseHeader():Void
	{
		_ident = _byteData.readInt();
		_version = _byteData.readInt();
		_skinWidth = _byteData.readInt();
		_skinHeight = _byteData.readInt();
		//skip _frameSize
		_byteData.readInt();
		_numSkins = _byteData.readInt();
		_numVertices = _byteData.readInt();
		_numST = _byteData.readInt();
		_numTris = _byteData.readInt();
		//skip _numGlCmds
		_byteData.readInt();
		_numFrames = _byteData.readInt();
		_offsetSkins = _byteData.readInt();
		_offsetST = _byteData.readInt();
		_offsetTris = _byteData.readInt();
		_offsetFrames = _byteData.readInt();
		//skip _offsetGlCmds
		_byteData.readInt();
		_offsetEnd = _byteData.readInt();

		_parsedHeader = true;
	}

	/**
	 * Parses the file names for the materials.
	 */
	private function parseMaterialNames():Void
	{
		var url:String;
		var name:String;
		var extIndex:int;
		var slashIndex:int;
		_materialNames = new Vector<String>();
		_byteData.position = _offsetSkins;

		var regExp:RegExp = new RegExp("[^a-zA-Z0-9\\_\/.]", "g");
		for (var i:UInt = 0; i < _numSkins; ++i)
		{
			name = _byteData.readUTFBytes(64);
			name = name.replace(regExp, "");
			extIndex = name.lastIndexOf(".");
			if (_ignoreTexturePath)
			{
				slashIndex = name.lastIndexOf("/");
			}
			if (name.toLowerCase().indexOf(".jpg") == -1 && name.toLowerCase().indexOf(".png") == -1)
			{
				name = name.substring(slashIndex + 1, extIndex);
				url = name + "." + _textureType;
			}
			else
			{
				url = name;
			}

			_materialNames[i] = name;
			// only support 1 skin TODO: really?
			if (dependencies.length == 0)
			{
				addDependency(name, new URLRequest(url));
			}
		}

		if (_materialNames.length > 0)
			_mesh.material.name = _materialNames[0];
		else
			materialFinal = true;

	}

	/**
	 * Parses the uv data for the mesh.
	 */
	private function parseUV():Void
	{
		var j:UInt;

		_uvs = new Vector<Number>(_numST * 2);
		_byteData.position = _offsetST;
		for (var i:UInt = 0; i < _numST; i++)
		{
			_uvs[j++] = _byteData.readShort() / _skinWidth;
			_uvs[j++] = _byteData.readShort() / _skinHeight;
		}

		_parsedUV = true;
	}

	/**
	 * Parses unique indices for the faces.
	 */
	private function parseFaces():Void
	{
		var a:UInt, b:UInt, c:UInt, ta:UInt, tb:UInt, tc:UInt;
		var i:UInt;

		_vertIndices = new Vector<Number>();
		_uvIndices = new Vector<Number>();
		_indices = new Vector<uint>();

		_byteData.position = _offsetTris;

		for (i = 0; i < _numTris; i++)
		{
			//collect vertex indices
			a = _byteData.readUnsignedShort();
			b = _byteData.readUnsignedShort();
			c = _byteData.readUnsignedShort();

			//collect uv indices
			ta = _byteData.readUnsignedShort();
			tb = _byteData.readUnsignedShort();
			tc = _byteData.readUnsignedShort();

			addIndex(a, ta);
			addIndex(b, tb);
			addIndex(c, tc);
		}

		var len:UInt = _uvIndices.length;
		_finalUV = new Vector<Number>(len * 2, true);

		for (i = 0; i < len; ++i)
		{
			_finalUV[uint(i << 1)] = _uvs[uint(_uvIndices[i] << 1)];
			_finalUV[uint(((i << 1) + 1))] = _uvs[uint((_uvIndices[i] << 1) + 1)];
		}

		_parsedFaces = true;
	}

	/**
	 * Adds a face index to the list if it doesn't exist yet, based on vertexIndex and uvIndex, and adds the
	 * corresponding vertex and uv data in the correct location.
	 * @param vertexIndex The original index in the vertex list.
	 * @param uvIndex The original index in the uv list.
	 */
	private function addIndex(vertexIndex:UInt, uvIndex:UInt):Void
	{
		var index:int = findIndex(vertexIndex, uvIndex);

		if (index == -1)
		{
			_indices.push(_vertIndices.length);
			_vertIndices.push(vertexIndex);
			_uvIndices.push(uvIndex);
		}
		else
		{
			_indices.push(index);
		}
	}

	/**
	 * Finds the final index corresponding to the original MD2's vertex and uv indices. Returns -1 if it wasn't added yet.
	 * @param vertexIndex The original index in the vertex list.
	 * @param uvIndex The original index in the uv list.
	 * @return The index of the final mesh corresponding to the original vertex and uv index. -1 if it doesn't exist yet.
	 */
	private function findIndex(vertexIndex:UInt, uvIndex:UInt):int
	{
		var len:UInt = _vertIndices.length;

		for (var i:UInt = 0; i < len; ++i)
			if (_vertIndices[i] == vertexIndex && _uvIndices[i] == uvIndex)
				return i;

		return -1;
	}


	/**
	 * Parses all the frame geometries.
	 */
	private function parseFrames():Void
	{
		var sx:Float, sy:Float, sz:Float;
		var tx:Float, ty:Float, tz:Float;
		var geometry:Geometry;
		var subGeom:CompactSubGeometry;
		var vertLen:UInt = _vertIndices.length;
		var fvertices:Vector<Number>;
		var tvertices:Vector<Number>;
		var i:UInt, j:int, k:UInt;
		//var ch : uint;
		var name:String = "";
		var prevClip:VertexClipNode = null;

		_byteData.position = _offsetFrames;

		for (i = 0; i < _numFrames; i++)
		{
			subGeom = new CompactSubGeometry();
			_firstSubGeom ||= subGeom;
			geometry = new Geometry();
			geometry.addSubGeometry(subGeom);
			tvertices = new Vector<Number>();
			fvertices = new Vector<Number>(vertLen * 3, true);

			sx = _byteData.readFloat();
			sy = _byteData.readFloat();
			sz = _byteData.readFloat();

			tx = _byteData.readFloat();
			ty = _byteData.readFloat();
			tz = _byteData.readFloat();

			name = readFrameName();

			// Note, the extra data.position++ in the for loop is there
			// to skip over a byte that holds the "vertex normal index"
			for (j = 0; j < _numVertices; j++, _byteData.position++)
			{
				tvertices.push(sx * _byteData.readUnsignedByte() + tx, sy * _byteData.readUnsignedByte() + ty, sz * _byteData.readUnsignedByte() + tz);
			}

			k = 0;
			for (j = 0; j < vertLen; j++)
			{
				fvertices[k++] = tvertices[uint(_vertIndices[j] * 3)];
				fvertices[k++] = tvertices[uint(_vertIndices[j] * 3 + 2)];
				fvertices[k++] = tvertices[uint(_vertIndices[j] * 3 + 1)];
			}

			subGeom.fromVectors(fvertices, _finalUV, null, null);
			subGeom.updateIndexData(_indices);
			subGeom.vertexNormalData;
			subGeom.vertexTangentData;
			subGeom.autoDeriveVertexNormals = false;
			subGeom.autoDeriveVertexTangents = false;

			var clip:VertexClipNode = _clipNodes[name];

			if (!clip)
			{
				// If another sequence was parsed before this one, starting
				// a new state means the previous one is complete and can
				// hence be finalized.
				if (prevClip)
				{
					finalizeAsset(prevClip);
					_animationSet.addAnimation(prevClip);
				}

				clip = new VertexClipNode();
				clip.name = name;
				clip.stitchFinalFrame = true;

				_clipNodes[name] = clip;

				prevClip = clip;
			}
			clip.addFrame(geometry, 1000 / FPS);
		}

		// Finalize the last state
		if (prevClip)
		{
			finalizeAsset(prevClip);
			_animationSet.addAnimation(prevClip);
		}

		// Force finalizeAsset() to decide name
		finalizeAsset(_animationSet);

		_parsedFrames = true;
	}

	private function readFrameName():String
	{
		var name:String = "";
		var k:UInt = 0;
		for (var j:UInt = 0; j < 16; j++)
		{
			var ch:UInt = _byteData.readUnsignedByte();

			if (uint(ch) > 0x39 && uint(ch) <= 0x7A && k == 0)
			{
				name += String.fromCharCode(ch);
			}

			if (uint(ch) >= 0x30 && uint(ch) <= 0x39)
			{
				k++;
			}
		}
		return name;
	}

	private function createDefaultSubGeometry():Void
	{
		var sub:CompactSubGeometry = new CompactSubGeometry();
		sub.updateData(_firstSubGeom.vertexData);
		sub.updateIndexData(_indices);
		_geometry.addSubGeometry(sub);
	}

}


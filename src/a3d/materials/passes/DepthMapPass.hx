package a3d.materials.passes;

import a3d.core.base.IRenderable;
import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import a3d.math.FMath;
import a3d.math.FMatrix3D;
import a3d.textures.Texture2DBase;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Matrix3D;
import flash.Vector;


class DepthMapPass extends MaterialPassBase
{
	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	public var alphaThreshold(get, set):Float;
	
	public var alphaMask(get, set):Texture2DBase;
	
	private var _data:Vector<Float>;
	private var _alphaThreshold:Float = 0;
	private var _alphaMask:Texture2DBase;

	public function new()
	{
		super();
		_data = Vector.ofArray([1.0, 255.0, 65025.0, 16581375.0,
			1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0,
			0.0, 0.0, 0.0, 0.0]);
	}

	
	private function get_alphaThreshold():Float
	{
		return _alphaThreshold;
	}

	private function set_alphaThreshold(value:Float):Float
	{
		value = FMath.fclamp(value, 0, 1);
		
		if (value == _alphaThreshold)
			return _alphaThreshold;

		if (value == 0 || _alphaThreshold == 0)
			invalidateShaderProgram();

		_alphaThreshold = value;
		_data[8] = _alphaThreshold;
		
		return _alphaThreshold;
	}

	
	private function get_alphaMask():Texture2DBase
	{
		return _alphaMask;
	}

	private function set_alphaMask(value:Texture2DBase):Texture2DBase
	{
		return _alphaMask = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function getVertexCode():String
	{
		var code:String;
		// project
		code = "m44 vt1, vt0, vc0		\n" +
			"mov op, vt1	\n";

		if (_alphaThreshold > 0)
		{
			_numUsedTextures = 1;
			_numUsedStreams = 2;
			code += "mov v0, vt1\n" +
				"mov v1, va1\n";

		}
		else
		{
			_numUsedTextures = 0;
			_numUsedStreams = 1;
			code += "mov v0, vt1\n";
		}

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCode(code:String):String
	{
		var codeF:String =
			"div ft2, v0, v0.w		\n" +
			"mul ft0, fc0, ft2.z	\n" +
			"frc ft0, ft0			\n" +
			"mul ft1, ft0.yzww, fc1	\n";
		
		if (_alphaThreshold > 0)
		{
			var wrap:String = _repeat ? "wrap" : "clamp";
			var filter:String, format:String;
			var enableMipMaps:Bool = _mipmap && _alphaMask.hasMipMaps;
			
			if (_smooth)
				filter = enableMipMaps ? "linear,miplinear" : "linear";
			else
				filter = enableMipMaps ? "nearest,mipnearest" : "nearest";
			
			switch (_alphaMask.format) {
				case Context3DTextureFormat.COMPRESSED:
					format = "dxt1,";
				case Context3DTextureFormat.COMPRESSED_ALPHA:
					format = "dxt5,";
				default:
					format = "";
			}
			codeF += "tex ft3, v1, fs0 <2d," + filter + "," + format + wrap + ">\n" +
				"sub ft3.w, ft3.w, fc2.x\n" +
				"kil ft3.w\n";
		}
		
		codeF += "sub oc, ft0, ft1		\n";
		
		return codeF;
	}

	/**
	 * @inheritDoc
	 */
	override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		if (_alphaThreshold > 0)
			renderable.activateUVBuffer(1, stage3DProxy);

		var context:Context3DProxy = stage3DProxy.context3D;
		var matrix:Matrix3D = FMatrix3D.CALCULATION_MATRIX;
		matrix.copyFrom(renderable.getRenderSceneTransform(camera));
		matrix.append(viewProjection);
		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
		renderable.activateVertexBuffer(0, stage3DProxy);
		context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		var context:Context3DProxy = stage3DProxy.context3D;
		super.activate(stage3DProxy, camera);

		if (_alphaThreshold > 0)
		{
			context.setTextureAt(0, _alphaMask.getTextureForStage3D(stage3DProxy));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 3);
		}
		else
		{
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 2);
		}
	}
}

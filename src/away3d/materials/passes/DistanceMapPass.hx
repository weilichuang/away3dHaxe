package away3d.materials.passes;

import away3d.core.base.IRenderable;
import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import away3d.cameras.Camera3D;
import away3d.math.FMath;
import away3d.math.Matrix3DUtils;
import away3d.textures.Texture2DBase;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;


class DistanceMapPass extends MaterialPassBase
{
	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	public var alphaThreshold(get, set):Float;
	public var alphaMask(get, set):Texture2DBase;
	
	private var _fragmentData:Vector<Float>;
	private var _vertexData:Vector<Float>;
	private var _alphaThreshold:Float;
	private var _alphaMask:Texture2DBase;

	public function new()
	{
		super();
		_fragmentData = Vector.ofArray([1.0, 255.0, 65025.0, 16581375.0,
			1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0,
			0.0, 0.0, 0.0, 0.0]);
		_vertexData = new Vector<Float>(4, true);
		_vertexData[3] = 1;
		_numUsedVertexConstants = 9;
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
		_fragmentData[8] = _alphaThreshold;
		
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
		code = "m44 op, vt0, vc0		\n" +
			"m44 vt1, vt0, vc5		\n" +
			"sub v0, vt1, vc9		\n";

		if (_alphaThreshold > 0)
		{
			code += "mov v1, va1\n";
			_numUsedTextures = 1;
			_numUsedStreams = 2;
		}
		else
		{
			_numUsedTextures = 0;
			_numUsedStreams = 1;
		}

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCode(animationCode:String):String
	{
		var code:String;
		var wrap:String = _repeat ? "wrap" : "clamp";
		var filter:String;

		if (_smooth)
			filter = _mipmap ? "linear,miplinear" : "linear";
		else
			filter = _mipmap ? "nearest,mipnearest" : "nearest";

		// squared distance to view
		code = "dp3 ft2.z, v0.xyz, v0.xyz	\n" +
			"mul ft0, fc0, ft2.z	\n" +
			"frc ft0, ft0			\n" +
			"mul ft1, ft0.yzww, fc1	\n";

		if (_alphaThreshold > 0)
		{
			var format:String;
			switch (_alphaMask.format)
			{
				case Context3DTextureFormat.COMPRESSED:
					format = "dxt1,";
				case Context3DTextureFormat.COMPRESSED_ALPHA:
					format = "dxt5,";
				default:
					format = "";
			}
			code += "tex ft3, v1, fs0 <2d," + filter + "," + format + wrap + ">\n" +
				"sub ft3.w, ft3.w, fc2.x\n" +
				"kil ft3.w\n";
		}

		code += "sub oc, ft0, ft1		\n";

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		var context:Context3DProxy = stage3DProxy.context3D;
		var pos:Vector3D = camera.scenePosition;

		_vertexData[0] = pos.x;
		_vertexData[1] = pos.y;
		_vertexData[2] = pos.z;
		_vertexData[3] = 1;

		var sceneTransform:Matrix3D = renderable.getRenderSceneTransform(camera);

		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, sceneTransform, true);
		context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 9, _vertexData, 1);

		if (_alphaThreshold > 0)
			renderable.activateUVBuffer(1, stage3DProxy);

		var matrix:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
		matrix.copyFrom(sceneTransform);
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

		var f:Float = camera.lens.far;

		f = 1 / (2 * f * f);
		// sqrt(f*f+f*f) is largest possible distance for any frustum, so we need to divide by it. Rarely a tight fit, but with 32 bits precision, it's enough.
		_fragmentData[0] = 1 * f;
		_fragmentData[1] = 255.0 * f;
		_fragmentData[2] = 65025.0 * f;
		_fragmentData[3] = 16581375.0 * f;


		if (_alphaThreshold > 0)
		{
			context.setTextureAt(0, _alphaMask.getTextureForStage3D(stage3DProxy));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentData, 3);
		}
		else
		{
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentData, 2);
		}
	}
}

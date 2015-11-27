package away3d.materials.methods;


import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;


/**
 * FogMethod provides a method to add distance-based fog to a material.
 */
class FogMethod extends EffectMethodBase
{
	/**
	 * The distance from which the fog starts appearing.
	 */
	public var minDistance(get,set):Float;
	/**
	 * The distance at which the fog is densest.
	 */
	public var maxDistance(get, set):Float;
	
	public var fogColor(get, set):UInt;
	
	private var _minDistance:Float = 0;
	private var _maxDistance:Float = 1000;
	private var _fogColor:UInt;
	private var _fogR:Float;
	private var _fogG:Float;
	private var _fogB:Float;

	/**
	 * Creates a new FogMethod object.
	 * @param minDistance The distance from which the fog starts appearing.
	 * @param maxDistance The distance at which the fog is densest.
	 * @param fogColor The colour of the fog.
	 */
	public function new(minDistance:Float, maxDistance:Float, fogColor:UInt = 0x808080)
	{
		super();
		this.minDistance = minDistance;
		this.maxDistance = maxDistance;
		this.fogColor = fogColor;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsProjection = true;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		data[index + 3] = 1;
		data[index + 6] = 0;
		data[index + 7] = 0;
	}

	
	private function get_minDistance():Float
	{
		return _minDistance;
	}

	private function set_minDistance(value:Float):Float
	{
		return _minDistance = value;
	}

	
	private function get_maxDistance():Float
	{
		return _maxDistance;
	}

	private function set_maxDistance(value:Float):Float
	{
		return _maxDistance = value;
	}

	
	private function get_fogColor():UInt
	{
		return _fogColor;
	}

	private function set_fogColor(value:UInt):UInt
	{
		_fogColor = value;
		_fogR = ((value >> 16) & 0xff) / 0xff;
		_fogG = ((value >> 8) & 0xff) / 0xff;
		_fogB = (value & 0xff) / 0xff;
		
		return _fogColor;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		data[index] = _fogR;
		data[index + 1] = _fogG;
		data[index + 2] = _fogB;
		data[index + 4] = _minDistance;
		data[index + 5] = 1 / (_maxDistance - _minDistance);
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var fogColor:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var fogData:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(temp, 1);
		var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var code:String = "";
		vo.fragmentConstantsIndex = fogColor.index * 4;

		code += "sub " + temp2 + ".w, " + _sharedRegisters.projectionFragment + ".z, " + fogData + ".x          \n" +
				"mul " + temp2 + ".w, " + temp2 + ".w, " + fogData + ".y					\n" +
				"sat " + temp2 + ".w, " + temp2 + ".w										\n" +
				"sub " + temp + ", " + fogColor + ", " + targetReg + "\n" + // (fogColor- col)
				"mul " + temp + ", " + temp + ", " + temp2 + ".w					\n" + // (fogColor- col)*fogRatio
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n"; // fogRatio*(fogColor- col) + col

		regCache.removeFragmentTempUsage(temp);

		return code;
	}
}

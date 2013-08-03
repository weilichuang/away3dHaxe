package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.entities.lights.DirectionalLight;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;


/**
 * DitheredShadowMapMethod provides a softened shadowing technique by bilinearly interpolating shadow comparison
 * results of neighbouring pixels.
 */
class FilteredShadowMapMethod extends SimpleShadowMapMethodBase
{
	/**
	 * Creates a new BasicDiffuseMethod object.
	 *
	 * @param castingLight The light casting the shadow
	 */
	public function new(castingLight:DirectionalLight)
	{
		super(castingLight);
	}

	override public function initConstants(vo:MethodVO):Void
	{
		super.initConstants(vo);

		var fragmentData:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		fragmentData[index + 8] = .5;
		var size:Int = castingLight.shadowMapper.depthMapSize;
		fragmentData[index + 9] = size;
		fragmentData[index + 10] = 1 / size;
	}

	/**
	 * @inheritDoc
	 */
	override private function getPlanarFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
		var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();

		var customDataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var depthCol:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var uvReg:ShaderRegisterElement;
		var code:String = "";
		vo.fragmentConstantsIndex = decReg.index * 4;

		regCache.addFragmentTempUsages(depthCol, 1);

		uvReg = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(uvReg, 1);

		code += "mov " + uvReg + ", " + _depthMapCoordReg + "\n" +

				"tex " + depthCol + ", " + _depthMapCoordReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".z, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" + // 0 if in shadow

				"add " + uvReg + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".z\n" + // (1, 0)
				"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".w, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" + // 0 if in shadow

				"mul " + depthCol + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".y\n" +
				"frc " + depthCol + ".x, " + depthCol + ".x\n" +
				"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z\n" +
				"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x\n" +
				"add " + targetReg + ".w, " + uvReg + ".z, " + uvReg + ".w\n" +

				"mov " + uvReg + ".x, " + _depthMapCoordReg + ".x\n" +
				"add " + uvReg + ".y, " + _depthMapCoordReg + ".y, " + customDataReg + ".z\n" + // (0, 1)
				"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".z, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" + // 0 if in shadow

				"add " + uvReg + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".z\n" + // (1, 1)
				"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".w, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" + // 0 if in shadow

				// recalculate fraction, since we ran out of registers :(
				"mul " + depthCol + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".y\n" +
				"frc " + depthCol + ".x, " + depthCol + ".x\n" +
				"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z\n" +
				"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x\n" +
				"add " + uvReg + ".w, " + uvReg + ".z, " + uvReg + ".w\n" +

				"mul " + depthCol + ".x, " + _depthMapCoordReg + ".y, " + customDataReg + ".y\n" +
				"frc " + depthCol + ".x, " + depthCol + ".x\n" +
				"sub " + uvReg + ".w, " + uvReg + ".w, " + targetReg + ".w\n" +
				"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x\n" +
				"add " + targetReg + ".w, " + targetReg + ".w, " + uvReg + ".w\n";

		regCache.removeFragmentTempUsage(depthCol);
		regCache.removeFragmentTempUsage(uvReg);

		vo.texturesIndex = depthMapRegister.index;

		return code;
	}

	override public function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var size:Int = _castingLight.shadowMapper.depthMapSize;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = size;
		data[index + 1] = 1 / size;
	}


	override public function getCascadeFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement,
		targetRegister:ShaderRegisterElement):String
	{
		var code:String;
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		vo.secondaryFragmentConstantsIndex = dataReg.index * 4;
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(temp, 1);
		var predicate:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(predicate, 1);

		code = "tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".x, " + depthProjection + ".z, " + temp + ".z\n" +

				"add " + depthProjection + ".x, " + depthProjection + ".x, " + dataReg + ".y\n" +
				"tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".z, " + depthProjection + ".z, " + temp + ".z\n" +

				"add " + depthProjection + ".y, " + depthProjection + ".y, " + dataReg + ".y\n" +
				"tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".w, " + depthProjection + ".z, " + temp + ".z\n" +

				"sub " + depthProjection + ".x, " + depthProjection + ".x, " + dataReg + ".y\n" +
				"tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".y, " + depthProjection + ".z, " + temp + ".z\n" +

				"mul " + temp + ".xy, " + depthProjection + ".xy, " + dataReg + ".x\n" +
				"frc " + temp + ".xy, " + temp + ".xy\n" +

				// some strange register juggling to prevent agal bugging out
				"sub " + depthProjection + ", " + predicate + ".xyzw, " + predicate + ".zwxy\n" +
				"mul " + depthProjection + ", " + depthProjection + ", " + temp + ".x\n" +

				"add " + predicate + ".xy, " + predicate + ".xy, " + depthProjection + ".zw\n" +

				"sub " + predicate + ".y, " + predicate + ".y, " + predicate + ".x\n" +
				"mul " + predicate + ".y, " + predicate + ".y, " + temp + ".y\n" +
				"add " + targetRegister + ".w, " + predicate + ".x, " + predicate + ".y\n";

		regCache.removeFragmentTempUsage(temp);
		regCache.removeFragmentTempUsage(predicate);
		return code;
	}
}

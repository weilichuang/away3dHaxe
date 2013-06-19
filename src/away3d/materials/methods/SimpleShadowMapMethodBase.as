package away3d.materials.methods
{
	import flash.geom.Vector3D;


	import away3d.entities.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.entities.lights.LightBase;
	import away3d.entities.lights.PointLight;
	import away3d.entities.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;



	public class SimpleShadowMapMethodBase extends ShadowMapMethodBase
	{
		protected var _depthMapCoordReg:ShaderRegisterElement;
		protected var _usePoint:Boolean;

		public function SimpleShadowMapMethodBase(castingLight:LightBase)
		{
			_usePoint = castingLight is PointLight;
			super(castingLight);
		}

		override public function initVO(vo:MethodVO):void
		{
			vo.needsView = true;
			vo.needsGlobalVertexPos = true;
			vo.needsGlobalFragmentPos = _usePoint;
			vo.needsNormals = vo.numLights > 0;
		}

		override public function initConstants(vo:MethodVO):void
		{
			var fragmentData:Vector.<Number> = vo.fragmentData;
			var vertexData:Vector.<Number> = vo.vertexData;
			var index:int = vo.fragmentConstantsIndex;
			fragmentData[index] = 1.0;
			fragmentData[index + 1] = 1 / 255.0;
			fragmentData[index + 2] = 1 / 65025.0;
			fragmentData[index + 3] = 1 / 16581375.0;

			fragmentData[index + 6] = 0;
			fragmentData[index + 7] = 1;

			if (_usePoint)
			{
				fragmentData[index + 8] = 0;
				fragmentData[index + 9] = 0;
				fragmentData[index + 10] = 0;
				fragmentData[index + 11] = 1;
			}

			index = vo.vertexConstantsIndex;
			if (index != -1)
			{
				vertexData[index] = .5;
				vertexData[index + 1] = -.5;
				vertexData[index + 2] = 0.0;
				vertexData[index + 3] = 1.0;
			}
		}

		/**
		 * Wrappers that override the vertex shader need to set this explicitly
		 */
		public function get depthMapCoordReg():ShaderRegisterElement
		{
			return _depthMapCoordReg;
		}

		public function set depthMapCoordReg(value:ShaderRegisterElement):void
		{
			_depthMapCoordReg = value;
		}

		public override function cleanCompilationData():void
		{
			super.cleanCompilationData();

			_depthMapCoordReg = null;
		}

		public override function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _usePoint ? getPointVertexCode(vo, regCache) : getPlanarVertexCode(vo, regCache);
		}

		protected function getPointVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			vo.vertexConstantsIndex = -1;
			return "";
		}

		protected function getPlanarVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var temp:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			var dataReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
			var depthMapProj:ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			_depthMapCoordReg = regCache.getFreeVarying();
			vo.vertexConstantsIndex = dataReg.index * 4;

			// todo: can epsilon be applied here instead of fragment shader?

			code += "m44 " + temp + ", " + _sharedRegisters.globalPositionVertex + ", " + depthMapProj + "\n" +
				"div " + temp + ", " + temp + ", " + temp + ".w\n" +
				"mul " + temp + ".xy, " + temp + ".xy, " + dataReg + ".xy\n" +
				"add " + _depthMapCoordReg + ", " + temp + ", " + dataReg + ".xxwz\n";

			return code;
		}

		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = _usePoint ? getPointFragmentCode(vo, regCache, targetReg) : getPlanarFragmentCode(vo, regCache, targetReg);
			code += "add " + targetReg + ".w, " + targetReg + ".w, fc" + (vo.fragmentConstantsIndex / 4 + 1) + ".y\n" +
				"sat " + targetReg + ".w, " + targetReg + ".w\n";
			return code;
		}

		protected function getPlanarFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			throw new AbstractMethodError();
			vo = vo;
			regCache = regCache;
			targetReg = targetReg;
			return "";
		}

		protected function getPointFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			throw new AbstractMethodError();
			vo = vo;
			regCache = regCache;
			targetReg = targetReg;
			return "";
		}

		public override function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			if (!_usePoint)
				DirectionalShadowMapper(_shadowMapper).depthProjection.copyRawDataTo(vo.vertexData, vo.vertexConstantsIndex + 4, true);
		}

		public function getCascadeFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement,
			targetRegister:ShaderRegisterElement):String
		{
			throw new Error("This shadow method is incompatible with cascade shadows");
		}

		/**
		 * @inheritDoc
		 */
		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var fragmentData:Vector.<Number> = vo.fragmentData;
			var index:int = vo.fragmentConstantsIndex;

			if (_usePoint)
				fragmentData[index + 4] = -Math.pow(1 / ((_castingLight as PointLight).fallOff * _epsilon), 2);
			else
				vo.vertexData[vo.vertexConstantsIndex + 3] = -1 / (DirectionalShadowMapper(_shadowMapper).depth * _epsilon);

			fragmentData[index + 5] = 1 - _alpha;
			if (_usePoint)
			{
				var pos:Vector3D = _castingLight.scenePosition;
				fragmentData[index + 8] = pos.x;
				fragmentData[index + 9] = pos.y;
				fragmentData[index + 10] = pos.z;
				// used to decompress distance
				var f:Number = PointLight(_castingLight).fallOff;
				fragmentData[index + 11] = 1 / (2 * f * f);
			}
			stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
		}

		public function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			throw new Error("This shadow method is incompatible with cascade shadows");
		}
	}
}

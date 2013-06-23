package a3d.materials.passes
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;

	
	import a3d.entities.Camera3D;
	import a3d.core.base.Geometry;
	import a3d.core.base.IRenderable;
	import a3d.core.base.ISubGeometry;
	import a3d.core.base.SubGeometry;
	import a3d.core.base.SubMesh;
	import a3d.core.managers.Stage3DProxy;
	import a3d.entities.Mesh;
	import a3d.math.Matrix3DUtils;

	

	class OutlinePass extends MaterialPassBase
	{
		private var _outlineColor:UInt;
		private var _colorData:Vector<Float>;
		private var _offsetData:Vector<Float>;
		private var _showInnerLines:Bool;
		private var _outlineMeshes:Dictionary;
		private var _dedicatedMeshes:Bool;

		/**
		 *
		 * @param outlineColor
		 * @param outlineSize
		 * @param showInnerLines
		 * @param dedicatedMeshes Create a Mesh specifically for the outlines. This is only useful if the outlines of the existing mesh appear fragmented due to discontinuities in the normals.
		 */
		public function OutlinePass(outlineColor:UInt = 0x000000, outlineSize:Float = 20, showInnerLines:Bool = true, dedicatedMeshes:Bool = false)
		{
			super();
			mipmap = false;
			_colorData = new Vector<Float>(4, true);
			_colorData[3] = 1;
			_offsetData = new Vector<Float>(4, true);
			this.outlineColor = outlineColor;
			this.outlineSize = outlineSize;
			_defaultCulling = Context3DTriangleFace.FRONT;
			_numUsedStreams = 2;
			_numUsedVertexConstants = 6;
			_showInnerLines = showInnerLines;
			_dedicatedMeshes = dedicatedMeshes;
			if (dedicatedMeshes)
				_outlineMeshes = new Dictionary();

			_animatableAttributes = Vector<String>(["va0", "va1"]);
			_animationTargetRegisters = Vector<String>(["vt0", "vt1"]);

		}

		/**
		 * Clears mesh.
		 * TODO: have Object3D broadcast dispose event, so this can be handled automatically?
		 */
		public function clearDedicatedMesh(mesh:Mesh):Void
		{
			if (_dedicatedMeshes)
			{
				for (var i:Int = 0; i < mesh.subMeshes.length; ++i)
				{
					disposeDedicated(mesh.subMeshes[i]);
				}
			}
		}

		private function disposeDedicated(keySubMesh:Object):Void
		{
			var mesh:Mesh;
			mesh = Mesh(_dedicatedMeshes[keySubMesh]);
			mesh.geometry.dispose();
			mesh.dispose();
			delete _dedicatedMeshes[keySubMesh];
		}

		override public function dispose():Void
		{
			super.dispose();

			if (_dedicatedMeshes)
			{
				for (var key:Object in _outlineMeshes)
				{
					disposeDedicated(key);
				}
			}
		}

		private inline function get_showInnerLines():Bool
		{
			return _showInnerLines;
		}

		private inline function set_showInnerLines(value:Bool):Void
		{
			_showInnerLines = value;
		}

		private inline function get_outlineColor():UInt
		{
			return _outlineColor;
		}

		private inline function set_outlineColor(value:UInt):Void
		{
			_outlineColor = value;
			_colorData[0] = ((value >> 16) & 0xff) / 0xff;
			_colorData[1] = ((value >> 8) & 0xff) / 0xff;
			_colorData[2] = (value & 0xff) / 0xff;
		}

		private inline function get_outlineSize():Float
		{
			return _offsetData[0];
		}

		private inline function set_outlineSize(value:Float):Void
		{
			_offsetData[0] = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function getVertexCode():String
		{
			var code:String;
			// offset
			code = "mul vt7, vt1, vc5.x\n" +
				"add vt7, vt7, vt0\n" +
				"mov vt7.w, vt0.w\n" +
				// project and scale to viewport
				"m44 op, vt7, vc0		\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override public function getFragmentCode(animationCode:String):String
		{
			// TODO: not used
			animationCode = animationCode;
			return "mov oc, fc0\n";
		}

		/**
		 * @inheritDoc
		 */
		override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
		{
			var context:Context3D = stage3DProxy.context3D;
			super.activate(stage3DProxy, camera);

			// do not write depth if not drawing inner lines (will cause the overdraw to hide inner lines)
			if (!_showInnerLines)
				context.setDepthTest(false, Context3DCompareMode.LESS);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, _offsetData, 1);
		}


		override public function deactivate(stage3DProxy:Stage3DProxy):Void
		{
			super.deactivate(stage3DProxy);
			if (!_showInnerLines)
				stage3DProxy.context3D.setDepthTest(true, Context3DCompareMode.LESS);
		}


		override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
		{
			var mesh:Mesh, dedicatedRenderable:IRenderable;

			var context:Context3D = stage3DProxy.context3D;
			var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);

			if (_dedicatedMeshes)
			{
				if (_outlineMeshes[renderable] == null)
					_outlineMeshes[renderable] = createDedicatedMesh(SubMesh(renderable).subGeometry)
				mesh = _outlineMeshes[renderable];
				dedicatedRenderable = mesh.subMeshes[0];

				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
				dedicatedRenderable.activateVertexBuffer(0, stage3DProxy);
				dedicatedRenderable.activateVertexNormalBuffer(1, stage3DProxy);
				context.drawTriangles(dedicatedRenderable.getIndexBuffer(stage3DProxy), 0, dedicatedRenderable.numTriangles);
			}
			else
			{
				renderable.activateVertexNormalBuffer(1, stage3DProxy);

				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
				renderable.activateVertexBuffer(0, stage3DProxy);
				context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
			}
		}

		// creates a new mesh in which all vertices are unique
		private function createDedicatedMesh(source:ISubGeometry):Mesh
		{
			var mesh:Mesh = new Mesh(new Geometry(), null);
			var dest:SubGeometry = new SubGeometry();
			var indexLookUp:Array = [];
			var srcIndices:Vector<UInt> = source.indexData;
			var srcVertices:Vector<Float> = source.vertexData;
			var dstIndices:Vector<UInt> = new Vector<UInt>();
			var dstVertices:Vector<Float> = new Vector<Float>();
			var index:Int;
			var x:Float, y:Float, z:Float;
			var key:String;
			var indexCount:Int;
			var vertexCount:Int;
			var len:Int = srcIndices.length;
			var maxIndex:Int;
			var stride:Int = source.vertexStride;
			var offset:Int = source.vertexOffset;

			for (var i:Int = 0; i < len; ++i)
			{
				index = offset + srcIndices[i] * stride;
				x = srcVertices[index];
				y = srcVertices[index + 1];
				z = srcVertices[index + 2];
				key = x.toPrecision(5) + "/" + y.toPrecision(5) + "/" + z.toPrecision(5);

				if (indexLookUp[key])
				{
					index = indexLookUp[key] - 1;
				}
				else
				{
					index = vertexCount / 3;
					indexLookUp[key] = index + 1;
					dstVertices[vertexCount++] = x;
					dstVertices[vertexCount++] = y;
					dstVertices[vertexCount++] = z;
				}

				if (index > maxIndex)
					maxIndex = index;
				dstIndices[indexCount++] = index;
			}

			dest.autoDeriveVertexNormals = true;
			dest.updateVertexData(dstVertices);
			dest.updateIndexData(dstIndices);
			mesh.geometry.addSubGeometry(dest);
			return mesh;
		}
	}
}

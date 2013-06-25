package a3d.core.pick;

import flash.display.Shader;
import flash.display.ShaderJob;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.utils.ByteArray;

import a3d.core.base.SubMesh;

/**
 * PixelBender-based picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
 *
 * @see a3d.entities.Entity#pickingCollider
 * @see a3d.core.pick.RaycastPicker
 */
class PBPickingCollider extends PickingColliderBase implements IPickingCollider
{
	[Embed("/pb/RayTriangleKernel.pbj", mimeType = "application/octet-stream")]
	private var RayTriangleKernelClass:Class;

	private var _findClosestCollision:Bool;

	private var _rayTriangleKernel:Shader;
	private var _lastSubMeshUploaded:SubMesh;
	private var _kernelOutputBuffer:Vector<Float>;

	/**
	 * Creates a new <code>PBPickingCollider</code> object.
	 *
	 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
	 */
	public function PBPickingCollider(findClosestCollision:Bool = false)
	{
		_findClosestCollision = findClosestCollision;

		_kernelOutputBuffer = new Vector<Float>();
		_rayTriangleKernel = new Shader(Std.instance(new RayTriangleKernelClass(),ByteArray));
	}

	/**
	 * @inheritDoc
	 */
	override public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void
	{
		super.setLocalRay(localPosition, localDirection);

		//update ray
		_rayTriangleKernel.data.rayStartPoint.value = [rayPosition.x, rayPosition.y, rayPosition.z];
		_rayTriangleKernel.data.rayDirection.value = [rayDirection.x, rayDirection.y, rayDirection.z];
	}

	/**
	 * @inheritDoc
	 */
	public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Float):Bool
	{
		var cx:Float, cy:Float, cz:Float;
		var u:Float, v:Float, w:Float;
		var indexData:Vector<UInt> = subMesh.indexData;
		var vertexData:Vector<Float> = subMesh.subGeometry.vertexPositionData;
		var uvData:Vector<Float> = subMesh.UVData;
		var numericIndexData:Vector<Float> = Vector<Float>(indexData);
		var indexBufferDims:Point = evaluateArrayAsGrid(numericIndexData);

		// if working on a clone, no need to resend data to pb
		if (!_lastSubMeshUploaded || _lastSubMeshUploaded !== subMesh)
		{
			// send vertices to pb
			var duplicateVertexData:Vector<Float> = vertexData.concat();
			var vertexBufferDims:Point = evaluateArrayAsGrid(duplicateVertexData);
			_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
			_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
			_rayTriangleKernel.data.vertexBufferWidth.value = [vertexBufferDims.x];
			_rayTriangleKernel.data.vertexBuffer.input = duplicateVertexData;
			_rayTriangleKernel.data.bothSides.value = [subMesh.material.bothSides ? 1.0 : 0.0];

			// send indices to pb
			_rayTriangleKernel.data.indexBuffer.width = indexBufferDims.x;
			_rayTriangleKernel.data.indexBuffer.height = indexBufferDims.y;
			_rayTriangleKernel.data.indexBuffer.input = numericIndexData;
		}

		_lastSubMeshUploaded = subMesh;

		// run kernel.
		var shaderJob:ShaderJob = new ShaderJob(_rayTriangleKernel, _kernelOutputBuffer, indexBufferDims.x, indexBufferDims.y);
		shaderJob.start(true);

		// find a proper collision from pb's output
		var i:UInt;
		var t:Float;
		var collisionTriangleIndex:Int = -1;
		var len:UInt = _kernelOutputBuffer.length;
		for (i = 0; i < len; i += 3)
		{
			t = _kernelOutputBuffer[i];
			if (t > 0 && t < shortestCollisionDistance)
			{
				shortestCollisionDistance = t;
				collisionTriangleIndex = i;

				//break loop unless best hit is required
				if (!_findClosestCollision)
					break;
			}
		}

		// Detect collision
		if (collisionTriangleIndex >= 0)
		{

			pickingCollisionVO.rayEntryDistance = shortestCollisionDistance;
			cx = rayPosition.x + shortestCollisionDistance * rayDirection.x;
			cy = rayPosition.y + shortestCollisionDistance * rayDirection.y;
			cz = rayPosition.z + shortestCollisionDistance * rayDirection.z;
			pickingCollisionVO.localPosition = new Vector3D(cx, cy, cz);
			pickingCollisionVO.localNormal = getCollisionNormal(indexData, vertexData, collisionTriangleIndex);
			v = _kernelOutputBuffer[collisionTriangleIndex + 1]; // barycentric coord 1
			w = _kernelOutputBuffer[collisionTriangleIndex + 2]; // barycentric coord 2
			u = 1.0 - v - w;
			pickingCollisionVO.uv = getCollisionUV(indexData, uvData, collisionTriangleIndex, v, w, u, 0, 2);

			return true;
		}

		return false;
	}

	private function evaluateArrayAsGrid(array:Vector<Float>):Point
	{
		var count:UInt = array.length / 3;
		var w:UInt = Math.floor(Math.sqrt(count));
		var h:UInt = w;
		var i:UInt;
		while (w * h < count)
		{
			for (i in 0...w)
			{
				array.push(0.0, 0.0, 0.0);
			}
			h++;
		}
		return new Point(w, h);
	}
}

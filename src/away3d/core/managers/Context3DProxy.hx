package away3d.core.managers;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DStencilAction;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DWrapMode;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.Vector.Vector;

/**
 * ...
 * @author 
 */
class Context3DProxy
{
	public var driverInfo(get, null) : String;
	public var enableErrorChecking(get, set) : Bool;
	public var context3D(get, set):Context3D;
	
	private var _context3D:Context3D;
	private var _curProgram:Program3D;
	private var _curDepthMask:Bool;
	private var _curCompareMode:Context3DCompareMode;
	private var _curSourceFactor:Context3DBlendFactor;
	private var _curDestinationFactor:Context3DBlendFactor;
	private var _curCulling:Context3DTriangleFace;

	public function new(context3D:Context3D) 
	{
		_context3D = context3D;
	}
	
	public inline function clear(red:Float = 0.0, green:Float = 0.0, blue:Float = 0.0, alpha:Float = 1.0, 
								depth:Float = 1.0, stencil:UInt = 0, mask:UInt = 0xffffffff):Void
	{
		_context3D.clear(red, green, blue, alpha, depth, stencil, mask);
	}
	
	public inline function configureBackBuffer(width:Int, height:Int, antiAlias:Int, enableDepthAndStencil:Bool = true, wantsBestResolution:Bool = false):Void
	{
		_context3D.configureBackBuffer(width, height, antiAlias, enableDepthAndStencil, wantsBestResolution);
	}
	
	public inline function createCubeTexture(size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):CubeTexture
	{
		return _context3D.createCubeTexture(size, format, optimizeForRenderToTexture, streamingLevels);
	}
	
	public inline function createIndexBuffer(numIndices:Int):IndexBuffer3D
	{
		return _context3D.createIndexBuffer(numIndices);
	}
	
	public inline function createProgram():Program3D
	{
		return _context3D.createProgram();
	}
	
	public inline function createTexture(width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):Texture
	{
		return _context3D.createTexture(width, height, format, optimizeForRenderToTexture, streamingLevels);
	}
	
	public inline function createVertexBuffer(numVertices:Int, data32PerVertex:Int):VertexBuffer3D
	{
		return _context3D.createVertexBuffer(numVertices, data32PerVertex);
	}
	
	public inline function dispose(recreate:Bool = true):Void
	{
		_context3D.dispose(recreate);
	}
	
	public inline function drawToBitmapData(destination:BitmapData):Void
	{
		_context3D.drawToBitmapData(destination);
	}
	
	public inline function drawTriangles(indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void
	{
		_context3D.drawTriangles(indexBuffer, firstIndex, numTriangles);
	}
	
	public inline function setBlendFactors(sourceFactor:Context3DBlendFactor, destinationFactor:Context3DBlendFactor):Void
	{
		if (_curSourceFactor != sourceFactor || _curDestinationFactor != destinationFactor)
		{
			_curSourceFactor = sourceFactor;
			_curDestinationFactor = destinationFactor;
			_context3D.setBlendFactors(sourceFactor, destinationFactor);
		}
	}
	
	public inline function setColorMask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void
	{
		_context3D.setColorMask(red, green, blue, alpha);
	}
	
	public inline function setCulling(triangleFaceToCull:Context3DTriangleFace):Void
	{
		if (_curCulling != triangleFaceToCull)
		{
			_curCulling = triangleFaceToCull;
			_context3D.setCulling(triangleFaceToCull);
		}
	}
	
	public inline function setDepthTest(depthMask:Bool, passCompareMode:Context3DCompareMode):Void
	{
		if (_curDepthMask != depthMask || _curCompareMode != passCompareMode)
		{
			_curDepthMask = depthMask;
			_curCompareMode = passCompareMode;
			_context3D.setDepthTest(depthMask, passCompareMode);
		}
	}
	
	public inline function setProgram(program:Program3D):Void
	{
		if (program != _curProgram)
		{
			_curProgram = program;
			_context3D.setProgram(_curProgram);
		}
	}
	
	public inline function setProgramConstantsFromByteArray(programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:UInt):Void
	{
		_context3D.setProgramConstantsFromByteArray(programType, firstRegister, numRegisters, data, byteArrayOffset);
	}
	
	public inline function setProgramConstantsFromMatrix(programType:Context3DProgramType, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void
	{
		_context3D.setProgramConstantsFromMatrix(programType, firstRegister, matrix, transposedMatrix);
	}
	
	public inline function setProgramConstantsFromVector(programType:Context3DProgramType, firstRegister:Int, data:Vector<Float>, numRegisters:Int = -1):Void
	{
		_context3D.setProgramConstantsFromVector(programType, firstRegister, data, numRegisters);
	}
	
	public inline function setRenderToBackBuffer():Void
	{
		_context3D.setRenderToBackBuffer();
	}
	
	public inline function setRenderToTexture(texture:TextureBase, enableDepthAndStencil:Bool = false, antiAlias:Int = 0, surfaceSelector:Int = 0):Void
	{
		_context3D.setRenderToTexture(texture, enableDepthAndStencil, antiAlias, surfaceSelector);
	}
	
	public inline function setSamplerStateAt(sampler:Int, wrap:Context3DWrapMode, filter:Context3DTextureFilter, mipfilter:Context3DMipFilter):Void
	{
		_context3D.setSamplerStateAt(sampler, wrap, filter, mipfilter);
	}
	
	public inline function setScissorRectangle(rectangle:Rectangle):Void
	{
		_context3D.setScissorRectangle(rectangle);
	}
	
	public inline function setStencilActions(?triangleFace:Context3DTriangleFace, ?compareMode:Context3DCompareMode, ?actionOnBothPass:Context3DStencilAction, ?actionOnDepthFail:Context3DStencilAction, ?actionOnDepthPassStencilFail:Context3DStencilAction):Void
	{
		_context3D.setStencilActions(triangleFace, compareMode, actionOnBothPass, actionOnDepthFail, actionOnDepthPassStencilFail);
	}
	
	public inline function setStencilReferenceValue(referenceValue:UInt, readMask:UInt = 255, writeMask:UInt = 255):Void
	{
		_context3D.setStencilReferenceValue(referenceValue, readMask, writeMask);
	}
	
	public inline function setTextureAt(sampler:Int, texture:TextureBase):Void
	{
		_context3D.setTextureAt(sampler, texture);
	}
	
	public inline function setVertexBufferAt(index:Int, buffer:VertexBuffer3D, bufferOffset:Int = 0, ?format:Context3DVertexBufferFormat):Void
	{
		_context3D.setVertexBufferAt(index, buffer, bufferOffset, format);
	}
	
	public inline function present():Void
	{
		_context3D.present();
	}
	
	private inline function get_driverInfo():String
	{
		return _context3D.driverInfo;
	}
	
	private inline function get_enableErrorChecking():Bool
	{
		return _context3D.enableErrorChecking;
	}
	
	private inline function set_enableErrorChecking(value:Bool):Bool
	{
		return _context3D.enableErrorChecking = value;
	}
	
	private inline function get_context3D():Context3D
	{
		return _context3D;
	}
	
	private inline function set_context3D(value:Context3D):Context3D
	{
		return _context3D = value;
	}
	
}
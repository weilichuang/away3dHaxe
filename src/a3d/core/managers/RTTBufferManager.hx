package a3d.core.managers;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import a3d.tools.utils.TextureUtils;

class RTTBufferManager extends EventDispatcher
{
	private static var _instances:Dictionary;

	public static function getInstance(stage3DProxy:Stage3DProxy):RTTBufferManager
	{
		if (stage3DProxy == null)
			throw new Error("stage3DProxy key cannot be null!");

		if (_instances == null)
			_instances = new Dictionary();

		if (_instances[stage3DProxy] == null)
			_instances[stage3DProxy] = new RTTBufferManager(new SingletonEnforcer(), stage3DProxy);
		return _instances[stage3DProxy];
	}

	private var _renderToTextureVertexBuffer:VertexBuffer3D;
	private var _renderToScreenVertexBuffer:VertexBuffer3D;

	private var _indexBuffer:IndexBuffer3D;
	private var _stage3DProxy:Stage3DProxy;
	private var _viewWidth:Int = -1;
	private var _viewHeight:Int = -1;
	private var _textureWidth:Int = -1;
	private var _textureHeight:Int = -1;
	private var _renderToTextureRect:Rectangle;
	private var _buffersInvalid:Bool = true;

	private var _textureRatioX:Float;
	private var _textureRatioY:Float;

	public function new(stage3DProxy:Stage3DProxy)
	{
		_renderToTextureRect = new Rectangle();

		_stage3DProxy = stage3DProxy;
	}


	private inline function get_textureRatioX():Float
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _textureRatioX;
	}

	private inline function get_textureRatioY():Float
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _textureRatioY;
	}

	private inline function get_viewWidth():Int
	{
		return _viewWidth;
	}

	private inline function set_viewWidth(value:Int):Void
	{
		if (value == _viewWidth)
			return;
		_viewWidth = value;

		_buffersInvalid = true;

		_textureWidth = TextureUtils.getBestPowerOf2(_viewWidth);

		if (_textureWidth > _viewWidth)
		{
			_renderToTextureRect.x = uint((_textureWidth - _viewWidth) * .5);
			_renderToTextureRect.width = _viewWidth;
		}
		else
		{
			_renderToTextureRect.x = 0;
			_renderToTextureRect.width = _textureWidth;
		}

		dispatchEvent(new Event(Event.RESIZE));
	}

	private inline function get_viewHeight():Int
	{
		return _viewHeight;
	}

	private inline function set_viewHeight(value:Int):Void
	{
		if (value == _viewHeight)
			return;
		_viewHeight = value;

		_buffersInvalid = true;

		_textureHeight = TextureUtils.getBestPowerOf2(_viewHeight);

		if (_textureHeight > _viewHeight)
		{
			_renderToTextureRect.y = uint((_textureHeight - _viewHeight) * .5);
			_renderToTextureRect.height = _viewHeight;
		}
		else
		{
			_renderToTextureRect.y = 0;
			_renderToTextureRect.height = _textureHeight;
		}

		dispatchEvent(new Event(Event.RESIZE));
	}

	private inline function get_renderToTextureVertexBuffer():VertexBuffer3D
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _renderToTextureVertexBuffer;
	}

	private inline function get_renderToScreenVertexBuffer():VertexBuffer3D
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _renderToScreenVertexBuffer;
	}

	private inline function get_indexBuffer():IndexBuffer3D
	{
		return _indexBuffer;
	}

	private inline function get_renderToTextureRect():Rectangle
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _renderToTextureRect;
	}

	private inline function get_textureWidth():Int
	{
		return _textureWidth;
	}

	private inline function get_textureHeight():Int
	{
		return _textureHeight;
	}

	public function dispose():Void
	{
		delete _instances[_stage3DProxy];
		if (_indexBuffer)
		{
			_indexBuffer.dispose();
			_renderToScreenVertexBuffer.dispose();
			_renderToTextureVertexBuffer.dispose();
			_renderToScreenVertexBuffer = null;
			_renderToTextureVertexBuffer = null;
			_indexBuffer = null;
		}
	}

	// todo: place all this in a separate model, since it's used all over the place
	// maybe it even has a place in the core (together with screenRect etc)?
	// needs to be stored per view of course
	private function updateRTTBuffers():Void
	{
		var context:Context3D = _stage3DProxy.context3D;
		var textureVerts:Vector<Float>;
		var screenVerts:Vector<Float>;
		var x:Float, y:Float;

		if (_renderToTextureVertexBuffer == null)
			_renderToTextureVertexBuffer = context.createVertexBuffer(4, 5);
		if (_renderToScreenVertexBuffer == null)
			_renderToScreenVertexBuffer = context.createVertexBuffer(4, 5);

		if (_indexBuffer == null)
		{
			_indexBuffer = context.createIndexBuffer(6);
			_indexBuffer.uploadFromVector(new <uint>[2, 1, 0, 3, 2, 0], 0, 6);
		}

		_textureRatioX = x = Math.min(_viewWidth / _textureWidth, 1);
		_textureRatioY = y = Math.min(_viewHeight / _textureHeight, 1);

		var u1:Float = (1 - x) * .5;
		var u2:Float = (x + 1) * .5;
		var v1:Float = (y + 1) * .5;
		var v2:Float = (1 - y) * .5;

		// last element contains indices for data per vertex that can be passed to the vertex shader if necessary (ie: frustum corners for deferred rendering)
		textureVerts = new <Number>[-x, -y, u1, v1, 0,
			x, -y, u2, v1, 1,
			x, y, u2, v2, 2,
			-x, y, u1, v2, 3];

		screenVerts = new <Number>[-1, -1, u1, v1, 0,
			1, -1, u2, v1, 1,
			1, 1, u2, v2, 2,
			-1, 1, u1, v2, 3];

		_renderToTextureVertexBuffer.uploadFromVector(textureVerts, 0, 4);
		_renderToScreenVertexBuffer.uploadFromVector(screenVerts, 0, 4);

		_buffersInvalid = false;
	}
}

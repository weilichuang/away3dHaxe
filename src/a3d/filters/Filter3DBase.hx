package a3d.filters;

import flash.display3D.textures.Texture;
import flash.Vector;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.filters.tasks.Filter3DTaskBase;

class Filter3DBase
{
	private var _tasks:Vector<Filter3DTaskBase>;
	private var _requireDepthRender:Bool;
	private var _textureWidth:Int;
	private var _textureHeight:Int;

	public function new()
	{
		_tasks = new Vector<Filter3DTaskBase>();
	}

	public var requireDepthRender(get, null):Bool;
	private inline function get_requireDepthRender():Bool
	{
		return _requireDepthRender;
	}

	private function addTask(filter:Filter3DTaskBase):Void
	{
		_tasks.push(filter);
		if(filter.requireDepthRender)
			_requireDepthRender = filter.requireDepthRender;
	}

	public var tasks(get, null):Vector<Filter3DTaskBase>;
	private inline function get_tasks():Vector<Filter3DTaskBase>
	{
		return _tasks;
	}

	public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture
	{
		return _tasks[0].getMainInputTexture(stage3DProxy);
	}
	
	public var textureWidth(get, set):Int;
	private inline function get_textureWidth():Int
	{
		return _textureWidth;
	}

	private inline function set_textureWidth(value:Int):Int
	{
		for (i in 0..._tasks.length)
			_tasks[i].textureWidth = value;
			
		return _textureWidth = value;
	}

	public var textureHeight(get, set):Int;
	private inline function get_textureHeight():Int
	{
		return _textureHeight;
	}

	private inline function set_textureHeight(value:Int):Int
	{
		for (i in 0..._tasks.length)
			_tasks[i].textureHeight = value;
		return _textureHeight = value;
	}

	// link up the filters correctly with the next filter
	public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
	{
		_tasks[_tasks.length - 1].target = mainTarget;
	}

	public function dispose():Void
	{
		for (i in 0..._tasks.length)
			_tasks[i].dispose();
		_tasks.length = 0;
	}

	public function update(stage:Stage3DProxy, camera:Camera3D):Void
	{

	}
}

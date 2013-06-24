package a3d.filters;

import flash.display3D.textures.Texture;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.filters.tasks.Filter3DTaskBase;

class Filter3DBase
{
	private var _tasks:Vector<Filter3DTaskBase>;
	private var _requireDepthRender:Bool;
	private var _textureWidth:Int;
	private var _textureHeight:Int;

	public function Filter3DBase()
	{
		_tasks = new Vector<Filter3DTaskBase>();
	}

	private inline function get_requireDepthRender():Bool
	{
		return _requireDepthRender;
	}

	private function addTask(filter:Filter3DTaskBase):Void
	{
		_tasks.push(filter);
		_requireDepthRender ||= filter.requireDepthRender;
	}

	private inline function get_tasks():Vector<Filter3DTaskBase>
	{
		return _tasks;
	}

	public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture
	{
		return _tasks[0].getMainInputTexture(stage3DProxy);
	}

	private inline function get_textureWidth():Int
	{
		return _textureWidth;
	}

	private inline function set_textureWidth(value:Int):Void
	{
		_textureWidth = value;

		for (var i:Int = 0; i < _tasks.length; ++i)
			_tasks[i].textureWidth = value;
	}

	private inline function get_textureHeight():Int
	{
		return _textureHeight;
	}

	private inline function set_textureHeight(value:Int):Void
	{
		_textureHeight = value;
		for (var i:Int = 0; i < _tasks.length; ++i)
			_tasks[i].textureHeight = value;
	}

	// link up the filters correctly with the next filter
	public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
	{
		_tasks[_tasks.length - 1].target = mainTarget;
	}

	public function dispose():Void
	{
		for (var i:Int = 0; i < _tasks.length; ++i)
			_tasks[i].dispose();
	}

	public function update(stage:Stage3DProxy, camera:Camera3D):Void
	{

	}
}

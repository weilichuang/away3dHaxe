package example;

import away3d.textures.BitmapTexture;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

import away3d.entities.Camera3D;
import away3d.entities.Scene3D;
import away3d.entities.View3D;
import away3d.utils.AwayStats;

class BasicApplication extends Sprite
{
	//engine variables
	private var view:View3D;
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var awayStats:AwayStats;

	public function new()
	{
		super();
		this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}
	
	private function onAddedToStage(e:Event):Void 
	{
		this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		init();
	}
	
	private function init():Void
	{
		
	}
	
	private function createBitmapTexture(cls:Class<BitmapData>):BitmapTexture
	{
		var bitmapData:BitmapData = Std.instance(Type.createInstance(cls, [0, 0]), BitmapData);
		return new BitmapTexture(bitmapData);
	}

	/**
	 * Initialise the engine
	 */
	private function initEngine():Void
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		view = new View3D();
		addChild(view);
		scene = view.scene;
		camera = view.camera;

		awayStats = new AwayStats(view);
		addChild(awayStats);
	}

	/**
	 * Initialise the listeners
	 */
	private function initListeners():Void
	{
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		onResize();
	}

	private function onKeyUp(event:KeyboardEvent):Void
	{
		// TODO Auto-generated method stub

	}

	private function onKeyDown(event:KeyboardEvent):Void
	{
		// TODO Auto-generated method stub

	}

	private function onMouseUp(event:MouseEvent):Void
	{
		// TODO Auto-generated method stub

	}

	private function onMouseDown(event:MouseEvent):Void
	{
		// TODO Auto-generated method stub

	}

	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event):Void
	{
		render();
	}

	private function render():Void
	{
		view.render();
	}

	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
		awayStats.x = stage.stageWidth - awayStats.width;
	}
}

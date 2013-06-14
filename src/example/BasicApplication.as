package example
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;

	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;

	public class BasicApplication extends Sprite
	{
		//engine variables
		protected var view:View3D;
		protected var scene:Scene3D;
		protected var camera:Camera3D;
		private var awayStats:AwayStats;

		public function BasicApplication()
		{
			super();
		}

		/**
		 * Initialise the engine
		 */
		protected function initEngine():void
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
		protected function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}

		protected function onKeyUp(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub

		}

		protected function onKeyDown(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub

		}

		protected function onMouseUp(event:MouseEvent):void
		{
			// TODO Auto-generated method stub

		}

		protected function onMouseDown(event:MouseEvent):void
		{
			// TODO Auto-generated method stub

		}

		/**
		 * Navigation and render loop
		 */
		protected function onEnterFrame(event:Event):void
		{
			render();
		}

		protected function render():void
		{
			view.render();
		}

		/**
		 * stage listener for resize events
		 */
		protected function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
	}
}

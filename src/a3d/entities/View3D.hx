﻿package a3d.entities;

import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Mouse3DManager;
import a3d.core.managers.RTTBufferManager;
import a3d.core.managers.Stage3DManager;
import a3d.core.managers.Stage3DProxy;
import a3d.core.managers.Touch3DManager;
import a3d.core.pick.IPicker;
import a3d.core.render.DefaultRenderer;
import a3d.core.render.DepthRenderer;
import a3d.core.render.Filter3DRenderer;
import a3d.core.render.RendererBase;
import a3d.core.traverse.EntityCollector;
import a3d.events.CameraEvent;
import a3d.events.Scene3DEvent;
import a3d.events.Stage3DEvent;
import a3d.filters.Filter3DBase;
import a3d.math.FMath;
import a3d.textures.Texture2DBase;
import flash.display.Sprite;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.errors.Error;
import flash.events.Event;
import flash.filters.BitmapFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Transform;
import flash.geom.Vector3D;
import flash.Lib;


class View3D extends Sprite
{
	public var depthPrepass(get, set):Bool;
	public var stage3DProxy(get, set):Stage3DProxy;
	/**
	 * Forces mouse-move related events even when the mouse hasn't moved. This allows mouseOver and mouseOut events
	 * etc to be triggered due to changes in the scene graph. Defaults to false.
	 */
	public var forceMouseMove(get, set):Bool;
	public var background(get, set):Texture2DBase;
	/**
	 * Used in a sharedContext. When true, clears the depth buffer prior to rendering this particular
	 * view to avoid depth sorting with lower layers. When false, the depth buffer is not cleared
	 * from the previous (lower) view's render so objects in this view may be occluded by the lower
	 * layer. Defaults to false.
	 */
	public var layeredView(get, set):Bool;
	
	public var filters3d(get, set):Array<Filter3DBase>;
	/**
	 * The renderer used to draw the scene.
	 */
	public var renderer(get, set):RendererBase;
	/**
	 * The background color of the screen. This value is only used when clearAll is set to true.
	 */
	public var backgroundColor(get, set):UInt;
	public var backgroundAlpha(get, set):Float;
	/**
	 * The camera that's used to render the scene for this viewport
	 */
	public var camera(get, set):Camera3D;
	/**
	 * The scene that's used to render for this viewport
	 */
	public var scene(get, set):Scene3D;
	// todo: probably temporary:
	/**
	 * The amount of milliseconds the last render call took
	 */
	public var deltaTime(get, null):Float;
	/**
	 * The amount of anti-aliasing to be used.
	 */
	public var antiAlias(get, set):Int;
	/**
	 * The amount of faces that were pushed through the render pipeline on the last frame render.
	 */
	public var renderedFacesCount(get, null):Int;
	
	/**
	 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
	 * to share the same Context3D object.
	 */
	public var shareContext(get, set):Bool;
	public var mousePicker(get, set):IPicker;
	public var touchPicker(get, set):IPicker;
	/**
	 * The EntityCollector object that will collect all potentially visible entities in the partition tree.
	 *
	 * @see a3d.core.traverse.EntityCollector
	 * @private
	 */
	public var entityCollector(get, null):EntityCollector;
	
	private var _width:Float;
	private var _height:Float;
	private var _localPos:Point;
	private var _globalPos:Point;
	private var _globalPosDirty:Bool;
	private var _scene:Scene3D;
	private var _camera:Camera3D;
	private var _entityCollector:EntityCollector;

	private var _aspectRatio:Float;
	private var _time:Float;
	private var _deltaTime:Float;
	private var _backgroundColor:UInt;
	private var _backgroundAlpha:Float;

	private var _mouse3DManager:Mouse3DManager;

	private var _touch3DManager:Touch3DManager;

	private var _renderer:RendererBase;
	private var _depthRenderer:DepthRenderer;
	private var _addedToStage:Bool;

	private var _forceSoftware:Bool;

	private var _filter3DRenderer:Filter3DRenderer;
	private var _requireDepthRender:Bool;
	private var _depthRender:Texture;
	private var _depthTextureInvalid:Bool;

	private var _hitField:Sprite;
	private var _parentIsStage:Bool;

	private var _background:Texture2DBase;
	private var _stage3DProxy:Stage3DProxy;
	private var _backBufferInvalid:Bool;
	private var _antiAlias:Int;

	private var _rttBufferManager:RTTBufferManager;

	private var _shareContext:Bool;
	private var _scissorRect:Rectangle;
	private var _scissorRectDirty:Bool;
	private var _viewportDirty:Bool;

	private var _depthPrepass:Bool;
	private var _profile:Context3DProfile;
	private var _layeredView:Bool;

	/**
	 *
	 * @param scene
	 * @param camera
	 * @param renderer
	 * @param forceSoftware
	 * @param profile
	 *
	 */
	public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, forceSoftware:Bool = false, profile:Context3DProfile =  null)
	{
		super();

		_profile = profile != null ? profile : Context3DProfile.BASELINE;
		
		if (scene == null)
			scene = new Scene3D();
		_scene = scene;
		_scene.addEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
		
		if (camera == null)
			camera = new Camera3D();
		_camera = camera;
		
		if (renderer == null)
			renderer = new DefaultRenderer();
		_renderer = renderer;
		
		
		_width = 0;
		_height = 0;
		_localPos = new Point();
		_globalPos = new Point();

		_time = 0;
		_backgroundColor = 0x000000;
		_backgroundAlpha = 1;

		_depthTextureInvalid = true;

		_backBufferInvalid = true;

		_shareContext = false;
		_scissorRectDirty = true;
		_viewportDirty = true;

		_layeredView = false;
			
		_depthRenderer = new DepthRenderer();
		_forceSoftware = forceSoftware;

		// todo: entity collector should be defined by renderer
		_entityCollector = _renderer.createEntityCollector();
		_entityCollector.camera = _camera;

		_scissorRect = new Rectangle();

		initHitField();

		_mouse3DManager = new Mouse3DManager();
		_mouse3DManager.enableMouseListeners(this);

		_touch3DManager = new Touch3DManager();
		_touch3DManager.view = this;
		_touch3DManager.enableTouchListeners(this);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		addEventListener(Event.ADDED, onAdded, false, 0, true);


		_camera.addEventListener(CameraEvent.LENS_CHANGED, onLensChanged);

		_camera.partition = _scene.partition;
	}

	
	private inline function get_depthPrepass():Bool
	{
		return _depthPrepass;
	}

	private function set_depthPrepass(value:Bool):Bool
	{
		return _depthPrepass = value;
	}

	private function onScenePartitionChanged(event:Scene3DEvent):Void
	{
		if (_camera != null)
			_camera.partition = scene.partition;
	}

	
	private inline function get_stage3DProxy():Stage3DProxy
	{
		return _stage3DProxy;
	}

	private function set_stage3DProxy(stage3DProxy:Stage3DProxy):Stage3DProxy
	{
		if (_stage3DProxy != null)
		{
			_stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
			_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DRecreated);
		}

		_stage3DProxy = stage3DProxy;

		_stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DRecreated);

		_renderer.stage3DProxy = _depthRenderer.stage3DProxy = _stage3DProxy;

		_globalPosDirty = true;
		_backBufferInvalid = true;
		
		return _stage3DProxy;
	}
	
	private function onContext3DRecreated(event:Stage3DEvent):Void 
	{
		_depthTextureInvalid = true;
	}

	
	private inline function get_forceMouseMove():Bool
	{
		return _mouse3DManager.forceMouseMove;
	}

	private function set_forceMouseMove(value:Bool):Bool
	{
		_mouse3DManager.forceMouseMove = value;
		_touch3DManager.forceTouchMove = value;
		return value;
	}

	
	private inline function get_background():Texture2DBase
	{
		return _background;
	}

	private function set_background(value:Texture2DBase):Texture2DBase
	{
		_background = value;
		_renderer.background = _background;
		return _background;
	}

	
	private inline function get_layeredView():Bool
	{
		return _layeredView;
	}

	private function set_layeredView(value:Bool):Bool
	{
		return _layeredView = value;
	}

	private function initHitField():Void
	{
		_hitField = new Sprite();
		_hitField.alpha = 0;
		_hitField.doubleClickEnabled = true;
		_hitField.graphics.beginFill(0x000000);
		_hitField.graphics.drawRect(0, 0, 100, 100);
		addChild(_hitField);
	}

	/**
	 * Not supported. Use filters3d instead.
	 */
	@:getter(filters) function get_filters():Array<BitmapFilter>
	{
		throw new Error("filters is not supported in View3D. Use filters3d instead.");
		return super.filters;
	}

	/**
	 * Not supported. Use filters3d instead.
	 */
	@:setter(filters) function set_filters(value:Array<BitmapFilter>):Void
	{
		throw new Error("filters is not supported in View3D. Use filters3d instead.");
	}

	
	private function get_filters3d():Array<Filter3DBase>
	{
		return _filter3DRenderer != null ? _filter3DRenderer.filters : null;
	}

	private function set_filters3d(value:Array<Filter3DBase>):Array<Filter3DBase>
	{
		if (value != null && value.length == 0)
			value = null;

		if (_filter3DRenderer != null && value == null)
		{
			_filter3DRenderer.dispose();
			_filter3DRenderer = null;
		}
		else if (_filter3DRenderer == null && value != null)
		{
			_filter3DRenderer = new Filter3DRenderer(stage3DProxy);
			_filter3DRenderer.filters = value;
		}

		if (_filter3DRenderer != null)
		{
			_filter3DRenderer.filters = value;
			_requireDepthRender = _filter3DRenderer.requireDepthRender;
		}
		else
		{
			_requireDepthRender = false;
			if (_depthRender != null)
			{
				_depthRender.dispose();
				_depthRender = null;
			}
		}
		
		return value;
	}

	private inline function get_renderer():RendererBase
	{
		return _renderer;
	}

	private function set_renderer(value:RendererBase):RendererBase
	{
		_renderer.dispose();
		_renderer = value;
		_entityCollector = _renderer.createEntityCollector();
		_entityCollector.camera = _camera;
		_renderer.stage3DProxy = _stage3DProxy;
		_renderer.antiAlias = _antiAlias;
		_renderer.backgroundR = ((_backgroundColor >> 16) & 0xff) / 0xff;
		_renderer.backgroundG = ((_backgroundColor >> 8) & 0xff) / 0xff;
		_renderer.backgroundB = (_backgroundColor & 0xff) / 0xff;
		_renderer.backgroundAlpha = _backgroundAlpha;
		_renderer.viewWidth = _width;
		_renderer.viewHeight = _height;

		_backBufferInvalid = true;
		
		return _renderer;
	}

	
	private function get_backgroundColor():UInt
	{
		return _backgroundColor;
	}

	private function set_backgroundColor(value:UInt):UInt
	{
		_backgroundColor = value;
		_renderer.backgroundR = ((value >> 16) & 0xff) / 0xff;
		_renderer.backgroundG = ((value >> 8) & 0xff) / 0xff;
		_renderer.backgroundB = (value & 0xff) / 0xff;
		return _backgroundColor;
	}

	
	private function get_backgroundAlpha():Float
	{
		return _backgroundAlpha;
	}

	private function set_backgroundAlpha(value:Float):Float
	{
		value = FMath.fclamp(value, 0, 1);

		_renderer.backgroundAlpha = value;
		return _backgroundAlpha = value;
	}

	
	private function get_camera():Camera3D
	{
		return _camera;
	}

	/**
	 * Set camera that's used to render the scene for this viewport
	 */
	private function set_camera(camera:Camera3D):Camera3D
	{
		_camera.removeEventListener(CameraEvent.LENS_CHANGED, onLensChanged);

		_camera = camera;
		_entityCollector.camera = _camera;

		if (_scene != null)
			_camera.partition = _scene.partition;

		_camera.addEventListener(CameraEvent.LENS_CHANGED, onLensChanged);

		_scissorRectDirty = true;
		_viewportDirty = true;
		
		return _camera;
	}

	
	private inline function get_scene():Scene3D
	{
		return _scene;
	}

	/**
	 * Set the scene that's used to render for this viewport
	 */
	private function set_scene(scene:Scene3D):Scene3D
	{
		if(_scene != null)
			_scene.removeEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
		
		_scene = scene;
		_scene.addEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);

		if (_camera != null)
			_camera.partition = _scene.partition;
		
		return _scene;
	}

	
	private function get_deltaTime():Float
	{
		return _deltaTime;
	}

	/**
	 * The width of the viewport. When software rendering is used, this is limited by the
	 * platform to 2048 pixels.
	 */
	@:getter(width) function get_width():Float
	{
		return _width;
	}

	@:setter(width) function set_width(value:Float):Void
	{
		// Backbuffer limitation in software mode. See comment in updateBackBuffer()
		if (_stage3DProxy != null && _stage3DProxy.usesSoftwareRendering && value > 2048)
			value = 2048;

		if (_width == value)
			return;

		if (_rttBufferManager != null)
			_rttBufferManager.viewWidth = Std.int(value);

		_hitField.width = value;
		_width = value;
		_aspectRatio = _width / _height;
		_camera.lens.aspectRatio = _aspectRatio;
		_depthTextureInvalid = true;

		_renderer.viewWidth = value;

		_scissorRect.width = value;

		_backBufferInvalid = true;
		_scissorRectDirty = true;
	}

	/**
	 * The height of the viewport. When software rendering is used, this is limited by the
	 * platform to 2048 pixels.
	 */
	@:getter(height) function get_height():Float
	{
		return _height;
	}

	@:setter(height) function set_height(value:Float):Void
	{
		// Backbuffer limitation in software mode. See comment in updateBackBuffer()
		if (_stage3DProxy != null && _stage3DProxy.usesSoftwareRendering && value > 2048)
			value = 2048;

		if (_height == value)
			return;

		if (_rttBufferManager != null)
			_rttBufferManager.viewHeight = Std.int(value);

		_hitField.height = value;
		_height = value;
		_aspectRatio = _width / _height;
		_camera.lens.aspectRatio = _aspectRatio;
		_depthTextureInvalid = true;

		_renderer.viewHeight = value;

		_scissorRect.height = value;

		_backBufferInvalid = true;
		_scissorRectDirty = true;
	}


	@:setter(x) function set_x(value:Float):Void
	{
		if (x == value)
			return;

		super.x = value;
		_localPos.x =  value;

		_globalPos.x = parent != null ? parent.localToGlobal(_localPos).x : value;
		_globalPosDirty = true;
	}

	@:setter(y) function set_y(value:Float):Void
	{
		if (y == value)
			return;

		super.y = value;
		_localPos.y = value;

		_globalPos.y = parent != null ? parent.localToGlobal(_localPos).y : value;
		_globalPosDirty = true;
	}

	@:setter(visible) function set_visible(value:Bool):Void
	{
		super.visible = value;

		if (_stage3DProxy != null && !_shareContext)
			_stage3DProxy.visible = value;
	}

	
	private inline function get_antiAlias():Int
	{
		return _antiAlias;
	}

	private function set_antiAlias(value:Int):Int
	{
		_antiAlias = value;
		_renderer.antiAlias = value;

		_backBufferInvalid = true;
		
		return _antiAlias;
	}

	
	private inline function get_renderedFacesCount():Int
	{
		return _entityCollector.numTriangles;
	}

	
	private inline function get_shareContext():Bool
	{
		return _shareContext;
	}

	private function set_shareContext(value:Bool):Bool
	{
		if (_shareContext == value)
			return _shareContext;

		_shareContext = value;
		_globalPosDirty = true;
		
		return _shareContext;
	}

	/**
	 * Updates the backbuffer dimensions.
	 */
	private function updateBackBuffer():Void
	{
		// No reason trying to configure back buffer if there is no context available.
		// Doing this anyway (and relying on _stage3DProxy to cache width/height for 
		// context does get available) means usesSoftwareRendering won't be reliable.
		if (_stage3DProxy.context3D != null && !_shareContext)
		{
			if (_width != 0 && _height != 0)
			{
				// Backbuffers are limited to 2048x2048 in software mode and
				// trying to configure the backbuffer to be bigger than that
				// will throw an error. Capping the value is a graceful way of
				// avoiding runtime exceptions for developers who are unable
				// to test their a3d implementation on screens that are 
				// large enough for this error to ever occur.
				if (_stage3DProxy.usesSoftwareRendering)
				{
					// Even though these checks where already made in the width
					// and height setters, at that point we couldn't be sure that
					// the context had even been retrieved and the software flag
					// thus be reliable. Make checks again.
					if (_width > 2048)
						_width = 2048;
					if (_height > 2048)
						_height = 2048;
				}

				_stage3DProxy.configureBackBuffer(Std.int(_width), Std.int(_height), _antiAlias);
				_backBufferInvalid = false;
			}
			else
			{
				width = stage.stageWidth;
				height = stage.stageHeight;
			}
		}
	}

	/**
	 * Renders the view.
	 */
	public function render():Void
	{
		//if context3D has Disposed by the OS,don't render at this frame
		if (!stage3DProxy.recoverFromDisposal())
		{
			_backBufferInvalid = true;
			return;
		}

		// reset or update render settings
		if (_backBufferInvalid)
			updateBackBuffer();

		if (_shareContext && _layeredView)
			stage3DProxy.clearDepthBuffer();

		if (!_parentIsStage)
		{
			var globalPos:Point = parent.localToGlobal(_localPos);
			if (_globalPos.x != globalPos.x || _globalPos.y != globalPos.y)
			{
				_globalPos = globalPos;
				_globalPosDirty = true;
			}
		}

		if (_globalPosDirty)
			updateGlobalPos();

		updateTime();

		updateViewSizeData();

		_entityCollector.clear();

		// collect stuff to render
		_scene.traversePartitions(_entityCollector);

		// update picking
		_mouse3DManager.updateCollider(this);
		_touch3DManager.updateCollider();

		if (_requireDepthRender)
			renderSceneDepthToTexture(_entityCollector);

		// todo: perform depth prepass after light update and before final render
		if (_depthPrepass)
			renderDepthPrepass(_entityCollector);

		_renderer.clearOnRender = !_depthPrepass;

		if (_filter3DRenderer != null && _stage3DProxy.context3D != null)
		{
			_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
			_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
		}
		else
		{
			_renderer.shareContext = _shareContext;
			if (_shareContext)
			{
				_renderer.render(_entityCollector, null, _scissorRect);
			}
			else
			{
				_renderer.render(_entityCollector);
			}

		}

		if (!_shareContext)
		{
			stage3DProxy.present();

			// fire collected mouse events
			_mouse3DManager.fireMouseEvents();
			_touch3DManager.fireTouchEvents();
		}

		// clean up data for this render
		_entityCollector.cleanUp();

		// register that a view has been rendered
		stage3DProxy.bufferClear = false;
	}

	private function updateGlobalPos():Void
	{
		_globalPosDirty = false;

		if (_stage3DProxy == null)
			return;

		if (_shareContext)
		{
			_scissorRect.x = _globalPos.x - _stage3DProxy.x;
			_scissorRect.y = _globalPos.y - _stage3DProxy.y;
		}
		else
		{
			_scissorRect.x = 0;
			_scissorRect.y = 0;
			_stage3DProxy.x = _globalPos.x;
			_stage3DProxy.y = _globalPos.y;
		}

		_scissorRectDirty = true;
	}

	private function updateTime():Void
	{
		var time:Float = Lib.getTimer();
		if (_time == 0)
			_time = time;
		_deltaTime = time - _time;
		_time = time;
	}

	private function updateViewSizeData():Void
	{
		_camera.lens.aspectRatio = _aspectRatio;

		if (_scissorRectDirty)
		{
			_scissorRectDirty = false;
			_camera.lens.updateScissorRect(_scissorRect.x, _scissorRect.y, _scissorRect.width, _scissorRect.height);
		}

		if (_viewportDirty)
		{
			_viewportDirty = false;
			_camera.lens.updateViewport(_stage3DProxy.viewPort.x, _stage3DProxy.viewPort.y, _stage3DProxy.viewPort.width, _stage3DProxy.viewPort.height);
		}

		if (_filter3DRenderer != null || _renderer.renderToTexture)
		{
			_renderer.textureRatioX = _rttBufferManager.textureRatioX;
			_renderer.textureRatioY = _rttBufferManager.textureRatioY;
		}
		else
		{
			_renderer.textureRatioX = 1;
			_renderer.textureRatioY = 1;
		}
	}

	private function renderDepthPrepass(entityCollector:EntityCollector):Void
	{
		_depthRenderer.disableColor = true;
		if (_filter3DRenderer  != null || _renderer.renderToTexture)
		{
			_depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
			_depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
			_depthRenderer.render(entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
		}
		else
		{
			_depthRenderer.textureRatioX = 1;
			_depthRenderer.textureRatioY = 1;
			_depthRenderer.render(entityCollector);
		}
		_depthRenderer.disableColor = false;
	}

	private function renderSceneDepthToTexture(entityCollector:EntityCollector):Void
	{
		if (_depthTextureInvalid || _depthRender == null)
			initDepthTexture(_stage3DProxy.context3D);
		_depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
		_depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
		_depthRenderer.render(entityCollector, _depthRender);
	}

	private function initDepthTexture(context:Context3DProxy):Void
	{
		_depthTextureInvalid = false;

		if (_depthRender != null)
			_depthRender.dispose();

		_depthRender = context.createTexture(_rttBufferManager.textureWidth, _rttBufferManager.textureHeight, Context3DTextureFormat.BGRA, true);
	}

	/**
	 * Disposes all memory occupied by the view. This will also dispose the renderer.
	 */
	public function dispose():Void
	{
		_stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
		_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DRecreated);
		
		if (!shareContext)
		{
			_stage3DProxy.dispose();
		}
		_renderer.dispose();

		if (_depthRender != null)
			_depthRender.dispose();

		if (_rttBufferManager != null)
			_rttBufferManager.dispose();

		_mouse3DManager.disableMouseListeners(this);
		_mouse3DManager.dispose();

		_touch3DManager.disableTouchListeners(this);
		_touch3DManager.dispose();

		_rttBufferManager = null;
		_depthRender = null;
		_mouse3DManager = null;
		_touch3DManager = null;
		_depthRenderer = null;
		_stage3DProxy = null;
		_renderer = null;
		_entityCollector = null;
	}

	/**
	 * Calculates the projected position in screen space of the given scene position.
	 *
	 * @param point3d the position vector of the point to be projected.
	 * @return The absolute screen position of the given scene coordinates.
	 */
	public function project(point3d:Vector3D):Vector3D
	{
		var v:Vector3D = _camera.project(point3d);

		v.x = (v.x + 1.0) * _width * 0.5;
		v.y = (v.y + 1.0) * _height * 0.5;

		return v;
	}

	/**
	 * Calculates the scene position of the given screen coordinates.
	 *
	 * eg. unproject(view.mouseX, view.mouseY, 500) returns the scene position of the mouse 500 units into the screen.
	 *
	 * @param sX The absolute x coordinate in 2D relative to View3D, representing the screenX coordinate.
	 * @param sY The absolute y coordinate in 2D relative to View3D, representing the screenY coordinate.
	 * @param sZ The distance into the screen, representing the screenZ coordinate.
	 * @param v the destination Vector3D object
	 * @return The scene position of the given screen coordinates.
	 */
	public function unproject(sX:Float, sY:Float, sZ:Float, v:Vector3D = null):Vector3D
	{
		return _camera.unproject((sX * 2 - _width) / _stage3DProxy.width, (sY * 2 - _height) / _stage3DProxy.height, sZ, v);
	}

	/**
	 * Calculates the ray in scene space from the camera to the given screen coordinates.
	 *
	 * eg. getRay(view.mouseX, view.mouseY, 500) returns the ray from the camera to a position under the mouse, 500 units into the screen.
	 *
	 * @param sX The absolute x coordinate in 2D relative to View3D, representing the screenX coordinate.
	 * @param sY The absolute y coordinate in 2D relative to View3D, representing the screenY coordinate.
	 * @param sZ The distance into the screen, representing the screenZ coordinate.
	 * @return The ray from the camera to the scene space position of the given screen coordinates.
	 */
	public function getRay(sX:Float, sY:Float, sZ:Float):Vector3D
	{
		return _camera.getRay((sX * 2 - _width) / _width, (sY * 2 - _height) / _height, sZ);
	}

	
	private inline function get_mousePicker():IPicker
	{
		return _mouse3DManager.mousePicker;
	}

	private function set_mousePicker(value:IPicker):IPicker
	{
		return _mouse3DManager.mousePicker = value;
	}

	
	private inline function get_touchPicker():IPicker
	{
		return _touch3DManager.touchPicker;
	}

	private function set_touchPicker(value:IPicker):IPicker
	{
		return _touch3DManager.touchPicker = value;
	}

	
	private inline function get_entityCollector():EntityCollector
	{
		return _entityCollector;
	}

	private function onLensChanged(event:CameraEvent):Void
	{
		_scissorRectDirty = true;
		_viewportDirty = true;
	}

	/**
	 * When added to the stage, retrieve a Stage3D instance
	 */
	private function onAddedToStage(event:Event):Void
	{
		if (_addedToStage)
			return;

		_addedToStage = true;

		if (_stage3DProxy == null)
		{
			_stage3DProxy = Stage3DManager.getInstance(stage).getFreeStage3DProxy(_forceSoftware, _profile);
			_stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
			_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DRecreated);
		}

		_globalPosDirty = true;

		_rttBufferManager = RTTBufferManager.getInstance(_stage3DProxy);

		_renderer.stage3DProxy = _depthRenderer.stage3DProxy = _stage3DProxy;

		//default wiidth/height to stageWidth/stageHeight
		if (_width == 0)
			width = stage.stageWidth;
		else
			_rttBufferManager.viewWidth = Std.int(_width);
		if (_height == 0)
			height = stage.stageHeight;
		else
			_rttBufferManager.viewHeight = Std.int(height);

		if (_shareContext)
			_mouse3DManager.addViewLayer(this);
	}

	private function onAdded(event:Event):Void
	{
		_parentIsStage = (parent == stage);

		_globalPos = parent.localToGlobal(_localPos);
		_globalPosDirty = true;
	}

	private function onViewportUpdated(event:Stage3DEvent):Void
	{
		if (_shareContext)
		{
			_scissorRect.x = _globalPos.x - _stage3DProxy.x;
			_scissorRect.y = _globalPos.y - _stage3DProxy.y;
			_scissorRectDirty = true;
		}

		_viewportDirty = true;
	}

	// dead ends:
	@:setter(z) function set_z(value:Float):Void
	{
	}

	@:setter(scaleZ) function set_scaleZ(value:Float):Void
	{
	}

	@:setter(rotation) function set_rotation(value:Float):Void
	{
	}

	@:setter(rotationX) function set_rotationX(value:Float):Void
	{
	}

	@:setter(rotationY) function set_rotationY(value:Float):Void
	{
	}

	@:setter(rotationZ) function set_rotationZ(value:Float):Void
	{
	}

	@:setter(transform) function set_transform(value:Transform):Void
	{
	}

	@:setter(scaleX) function set_scaleX(value:Float):Void
	{
	}

	@:setter(scaleY) function set_scaleY(value:Float):Void
	{
	}
}

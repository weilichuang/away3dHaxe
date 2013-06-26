package a3d.core.managers;

import a3d.events.Stage3DEvent;
import a3d.utils.Debug;
import flash.display.Shape;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DClearMask;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Program3D;
import flash.display3D.textures.TextureBase;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Rectangle;


@:meta(Event(name = "enterFrame", type = "flash.events.Event"))
@:meta(Event(name = "exitFrame", type = "flash.events.Event"))

/**
 * Stage3DProxy provides a proxy class to manage a single Stage3D instance as well as handling the creation and
 * attachment of the Context3D (and in turn the back buffer) is uses. Stage3DProxy should never be created directly,
 * but requested through Stage3DManager.
 *
 * @see a3d.core.managers.Stage3DProxy
 *
 * todo: consider moving all creation methods (createVertexBuffer etc) in here, so that disposal can occur here
 * along with the context, instead of scattered throughout the framework
 */
class Stage3DProxy extends EventDispatcher
{
	private static var _frameEventDriver:Shape = new Shape();

	private var _context3D:Context3D;
	private var _stage3DIndex:Int = -1;

	private var _usesSoftwareRendering:Bool;
	private var _profile:String;
	private var _stage3D:Stage3D;
	private var _activeProgram3D:Program3D;
	private var _stage3DManager:Stage3DManager;
	private var _backBufferWidth:Int;
	private var _backBufferHeight:Int;
	private var _antiAlias:Int;
	private var _enableDepthAndStencil:Bool;
	private var _contextRequested:Bool;
	//private var _activeVertexBuffers : Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8, true);
	//private var _activeTextures : Vector<TextureBase> = new Vector<TextureBase>(8, true);
	private var _renderTarget:TextureBase;
	private var _renderSurfaceSelector:Int;
	private var _scissorRect:Rectangle;
	private var _color:UInt;
	private var _backBufferDirty:Bool;
	private var _viewPort:Rectangle;
	private var _enterFrame:Event;
	private var _exitFrame:Event;
	private var _viewportUpdated:Stage3DEvent;
	private var _viewportDirty:Bool;
	private var _bufferClear:Bool;
	private var _mouse3DManager:Mouse3DManager;
	private var _touch3DManager:Touch3DManager;

	/**
	 * Creates a Stage3DProxy object. This method should not be called directly. Creation of Stage3DProxy objects should
	 * be handled by Stage3DManager.
	 * @param stage3DIndex The index of the Stage3D to be proxied.
	 * @param stage3D The Stage3D to be proxied.
	 * @param stage3DManager
	 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
	 */
	public function new(stage3DIndex:Int, stage3D:Stage3D, stage3DManager:Stage3DManager, forceSoftware:Bool = false, profile:String = "baseline")
	{
		_stage3DIndex = stage3DIndex;
		_stage3D = stage3D;
		_stage3D.x = 0;
		_stage3D.y = 0;
		_stage3D.visible = true;
		_stage3DManager = stage3DManager;
		_viewPort = new Rectangle();
		_enableDepthAndStencil = true;

		// whatever happens, be sure this has highest priority
		_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, 1000, false);
		requestContext(forceSoftware, profile);
	}

	private inline function get_profile():String
	{
		return _profile;
	}

	/**
	 * Disposes the Stage3DProxy object, freeing the Context3D attached to the Stage3D.
	 */
	public function dispose():Void
	{
		_stage3DManager.removeStage3DProxy(this);
		_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
		freeContext3D();
		_stage3D = null;
		_stage3DManager = null;
		_stage3DIndex = -1;
	}

	/**
	 * Configures the back buffer associated with the Stage3D object.
	 * @param backBufferWidth The width of the backbuffer.
	 * @param backBufferHeight The height of the backbuffer.
	 * @param antiAlias The amount of anti-aliasing to use.
	 * @param enableDepthAndStencil Indicates whether the back buffer contains a depth and stencil buffer.
	 */
	public function configureBackBuffer(backBufferWidth:Int, backBufferHeight:Int, antiAlias:Int, enableDepthAndStencil:Bool):Void
	{
		var oldWidth:Int = _backBufferWidth;
		var oldHeight:Int = _backBufferHeight;

		_viewPort.width = backBufferWidth;
		_viewPort.height = backBufferHeight;
		_backBufferWidth = backBufferWidth;
		_backBufferHeight = backBufferHeight;

		if (oldWidth != _backBufferWidth || oldHeight != _backBufferHeight)
			notifyViewportUpdated();

		_antiAlias = antiAlias;
		_enableDepthAndStencil = enableDepthAndStencil;

		if (_context3D != null)
			_context3D.configureBackBuffer(backBufferWidth, backBufferHeight, antiAlias, enableDepthAndStencil);
	}

	/*
	 * Indicates whether the depth and stencil buffer is used
	 */
	private inline function get_enableDepthAndStencil():Bool
	{
		return _enableDepthAndStencil;
	}

	private inline function set_enableDepthAndStencil(enableDepthAndStencil:Bool):Void
	{
		_enableDepthAndStencil = enableDepthAndStencil;
		_backBufferDirty = true;
	}

	private inline function get_renderTarget():TextureBase
	{
		return _renderTarget;
	}

	private inline function get_renderSurfaceSelector():Int
	{
		return _renderSurfaceSelector;
	}

	public function setRenderTarget(target:TextureBase, enableDepthAndStencil:Bool = false, surfaceSelector:Int = 0):Void
	{
		if (_renderTarget == target && surfaceSelector == _renderSurfaceSelector && _enableDepthAndStencil == enableDepthAndStencil)
			return;
		_renderTarget = target;
		_renderSurfaceSelector = surfaceSelector;
		_enableDepthAndStencil = enableDepthAndStencil;

		if (target)
			_context3D.setRenderToTexture(target, enableDepthAndStencil, _antiAlias, surfaceSelector);
		else
			_context3D.setRenderToBackBuffer();
	}

	/*
	 * Clear and reset the back buffer when using a shared context
	 */
	public function clear():Void
	{
		if (_context3D == null)
			return;

		if (_backBufferDirty)
		{
			configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
			_backBufferDirty = false;
		}

		_context3D.clear(
			((_color >> 16) & 0xff) / 255.0,
			((_color >> 8) & 0xff) / 255.0,
			(_color & 0xff) / 255.0,
			((_color >> 24) & 0xff) / 255.0);

		_bufferClear = true;
	}


	/*
	 * Display the back rendering buffer
	 */
	public function present():Void
	{
		if (_context3D == null)
			return;

		_context3D.present();

		_activeProgram3D = null;

		if (_mouse3DManager)
			_mouse3DManager.fireMouseEvents();
	}

	/**
	 * Registers an event listener object with an EventDispatcher object so that the listener receives notification of an event. Special case for enterframe and exitframe events - will switch Stage3DProxy into automatic render mode.
	 * You can register event listeners on all nodes in the display list for a specific type of event, phase, and priority.
	 *
	 * @param type The type of event.
	 * @param listener The listener function that processes the event.
	 * @param useCapture Determines whether the listener works in the capture phase or the target and bubbling phases. If useCapture is set to true, the listener processes the event only during the capture phase and not in the target or bubbling phase. If useCapture is false, the listener processes the event only during the target or bubbling phase. To listen for the event in all three phases, call addEventListener twice, once with useCapture set to true, then again with useCapture set to false.
	 * @param priority The priority level of the event listener. The priority is designated by a signed 32-bit integer. The higher the number, the higher the priority. All listeners with priority n are processed before listeners of priority n-1. If two or more listeners share the same priority, they are processed in the order in which they were added. The default priority is 0.
	 * @param useWeakReference Determines whether the reference to the listener is strong or weak. A strong reference (the default) prevents your listener from being garbage-collected. A weak reference does not.
	 */
	override public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);

		if ((type == Event.ENTER_FRAME || type == Event.EXIT_FRAME) && !_frameEventDriver.hasEventListener(Event.ENTER_FRAME))
			_frameEventDriver.addEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture, priority, useWeakReference);
	}

	/**
	 * Removes a listener from the EventDispatcher object. Special case for enterframe and exitframe events - will switch Stage3DProxy out of automatic render mode.
	 * If there is no matching listener registered with the EventDispatcher object, a call to this method has no effect.
	 *
	 * @param type The type of event.
	 * @param listener The listener object to remove.
	 * @param useCapture Specifies whether the listener was registered for the capture phase or the target and bubbling phases. If the listener was registered for both the capture phase and the target and bubbling phases, two calls to removeEventListener() are required to remove both, one call with useCapture() set to true, and another call with useCapture() set to false.
	 */
	override public function removeEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false):Void
	{
		super.removeEventListener(type, listener, useCapture);

		// Remove the main rendering listener if no EnterFrame listeners remain
		if (!hasEventListener(Event.ENTER_FRAME) && !hasEventListener(Event.EXIT_FRAME) && _frameEventDriver.hasEventListener(Event.ENTER_FRAME))
			_frameEventDriver.removeEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture);
	}

	private inline function get_scissorRect():Rectangle
	{
		return _scissorRect;
	}

	private inline function set_scissorRect(value:Rectangle):Void
	{
		_scissorRect = value;
		_context3D.setScissorRectangle(_scissorRect);
	}

	/**
	 * The index of the Stage3D which is managed by this instance of Stage3DProxy.
	 */
	private inline function get_stage3DIndex():Int
	{
		return _stage3DIndex;
	}

	/**
	 * The base Stage3D object associated with this proxy.
	 */
	private inline function get_stage3D():Stage3D
	{
		return _stage3D;
	}

	/**
	 * The Context3D object associated with the given Stage3D object.
	 */
	private inline function get_context3D():Context3D
	{
		return _context3D;
	}

	/**
	 * The driver information as reported by the Context3D object (if any)
	*/
	private inline function get_driverInfo():String
	{
		return _context3D ? _context3D.driverInfo : null;
	}


	/**
	 * Indicates whether the Stage3D managed by this proxy is running in software mode.
	 * Remember to wait for the CONTEXT3D_CREATED event before checking this property,
	 * as only then will it be guaranteed to be accurate.
	*/
	private inline function get_usesSoftwareRendering():Bool
	{
		return _usesSoftwareRendering;
	}


	/**
	 * The x position of the Stage3D.
	 */
	private inline function get_x():Float
	{
		return _stage3D.x;
	}

	private inline function set_x(value:Float):Void
	{
		if (_viewPort.x == value)
			return;

		_stage3D.x = _viewPort.x = value;

		notifyViewportUpdated();
	}

	/**
	 * The y position of the Stage3D.
	 */
	private inline function get_y():Float
	{
		return _stage3D.y;
	}

	private inline function set_y(value:Float):Void
	{
		if (_viewPort.y == value)
			return;

		_stage3D.y = _viewPort.y = value;

		notifyViewportUpdated();
	}


	/**
	 * The width of the Stage3D.
	 */
	private inline function get_width():Int
	{
		return _backBufferWidth;
	}

	private inline function set_width(width:Int):Void
	{
		if (_viewPort.width == width)
			return;

		_backBufferWidth = _viewPort.width = width;
		_backBufferDirty = true;

		notifyViewportUpdated();
	}

	/**
	 * The height of the Stage3D.
	 */
	private inline function get_height():Int
	{
		return _backBufferHeight;
	}

	private inline function set_height(height:Int):Void
	{
		if (_viewPort.height == height)
			return;

		_backBufferHeight = _viewPort.height = height;
		_backBufferDirty = true;

		notifyViewportUpdated();
	}

	/**
	 * The antiAliasing of the Stage3D.
	 */
	private inline function get_antiAlias():Int
	{
		return _antiAlias;
	}

	private inline function set_antiAlias(antiAlias:Int):Void
	{
		_antiAlias = antiAlias;
		_backBufferDirty = true;
	}

	/**
	 * A viewPort rectangle equivalent of the Stage3D size and position.
	 */
	private inline function get_viewPort():Rectangle
	{
		_viewportDirty = false;

		return _viewPort;
	}

	/**
	 * The background color of the Stage3D.
	 */
	private inline function get_color():UInt
	{
		return _color;
	}

	private inline function set_color(color:UInt):Void
	{
		_color = color;
	}


	/**
	 * The visibility of the Stage3D.
	 */
	private inline function get_visible():Bool
	{
		return _stage3D.visible;
	}

	private inline function set_visible(value:Bool):Void
	{
		_stage3D.visible = value;
	}


	/**
	 * The freshly cleared state of the backbuffer before any rendering
	 */
	private inline function get_bufferClear():Bool
	{
		return _bufferClear;
	}

	private inline function set_bufferClear(newBufferClear:Bool):Void
	{
		_bufferClear = newBufferClear;
	}

	/*
	 * Access to fire mouseevents across multiple layered view3D instances
	 */
	private inline function get_mouse3DManager():Mouse3DManager
	{
		return _mouse3DManager;
	}

	private inline function set_mouse3DManager(value:Mouse3DManager):Void
	{
		_mouse3DManager = value;
	}

	private inline function get_touch3DManager():Touch3DManager
	{
		return _touch3DManager;
	}

	private inline function set_touch3DManager(value:Touch3DManager):Void
	{
		_touch3DManager = value;
	}


	/**
	 * Frees the Context3D associated with this Stage3DProxy.
	 */
	private function freeContext3D():Void
	{
		if (_context3D)
		{
			_context3D.dispose();
			dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
		}
		_context3D = null;
	}

	/*
	 * Called whenever the Context3D is retrieved or lost.
	 * @param event The event dispatched.
	*/
	private function onContext3DUpdate(event:Event):Void
	{
		if (_stage3D.context3D)
		{
			var hadContext:Bool = (_context3D != null);
			_context3D = _stage3D.context3D;
			_context3D.enableErrorChecking = Debug.active;

			_usesSoftwareRendering = (_context3D.driverInfo.indexOf('Software') == 0);

			// Only configure back buffer if width and height have been set,
			// which they may not have been if View3D.render() has yet to be
			// invoked for the first time.
			if (_backBufferWidth && _backBufferHeight)
				_context3D.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);

			// Dispatch the appropriate event depending on whether context was
			// created for the first time or recreated after a device loss.
			dispatchEvent(new Stage3DEvent(hadContext ? Stage3DEvent.CONTEXT3D_RECREATED : Stage3DEvent.CONTEXT3D_CREATED));

		}
		else
		{
			throw new Error("Rendering context lost!");
		}
	}

	/**
	 * Requests a Context3D object to attach to the managed Stage3D.
	 */
	private function requestContext(forceSoftware:Bool = false, profile:String = "baseline"):Void
	{
		// If forcing software, we can be certain that the
		// returned Context3D will be running software mode.
		// If not, we can't be sure and should stick to the
		// old value (will likely be same if re-requesting.)
		_usesSoftwareRendering = forceSoftware;
		_profile = profile;

		// ugly stuff for backward compatibility
		var renderMode:String = forceSoftware ? Context3DRenderMode.SOFTWARE : Context3DRenderMode.AUTO;
		if (profile == "baseline")
			_stage3D.requestContext3D(renderMode);
		else
		{
			try
			{
				_stage3D["requestContext3D"](renderMode, profile);
			}
			catch (error:Error)
			{
				throw "An error occurred creating a context using the given profile. Profiles are not supported for the SDK this was compiled with.";
			}
		}

		_contextRequested = true;
	}

	/**
	 * The Enter_Frame handler for processing the proxy.ENTER_FRAME and proxy.EXIT_FRAME event handlers.
	 * Typically the proxy.ENTER_FRAME listener would render the layers for this Stage3D instance.
	 */
	private function onEnterFrame(event:Event):Void
	{
		if (_context3D == null)
			return;

		// Clear the stage3D instance
		clear();

		//notify the enterframe listeners
		notifyEnterFrame();

		// Call the present() to render the frame
		present();

		//notify the exitframe listeners
		notifyExitFrame();
	}
	
	private function notifyViewportUpdated():Void
	{
		if (_viewportDirty)
			return;

		_viewportDirty = true;

		if (!hasEventListener(Stage3DEvent.VIEWPORT_UPDATED))
			return;

		//TODO: investigate bug causing coercion error
		//if (!_viewportUpdated)
		_viewportUpdated = new Stage3DEvent(Stage3DEvent.VIEWPORT_UPDATED);

		dispatchEvent(_viewportUpdated);
	}

	private function notifyEnterFrame():Void
	{
		if (!hasEventListener(Event.ENTER_FRAME))
			return;

		if (!_enterFrame)
			_enterFrame = new Event(Event.ENTER_FRAME);

		dispatchEvent(_enterFrame);
	}

	private function notifyExitFrame():Void
	{
		if (!hasEventListener(Event.EXIT_FRAME))
			return;

		if (!_exitFrame)
			_exitFrame = new Event(Event.EXIT_FRAME);

		dispatchEvent(_exitFrame);
	}

	public function recoverFromDisposal():Bool
	{
		if (_context3D == null)
			return false;
		if (_context3D.driverInfo == "Disposed")
		{
			_context3D = null;
			dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
			return false;
		}
		return true;
	}

	public function clearDepthBuffer():Void
	{
		if (_context3D == null)
			return;
		_context3D.clear(0, 0, 0, 1, 1, 0, Context3DClearMask.DEPTH);
	}
}

package away3d.materials.passes;

import away3d.Away3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.IAnimationSet;
import away3d.core.base.IRenderable;
import away3d.core.managers.AGALProgram3DCache;
import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import away3d.cameras.Camera3D;
import away3d.errors.AbstractMethodError;
import away3d.materials.BlendMode;
import away3d.materials.lightpickers.LightPickerBase;
import away3d.materials.MaterialBase;
import away3d.debug.Debug;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Program3D;
import flash.display3D.textures.TextureBase;
import flash.errors.ArgumentError;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.Lib;
import flash.Vector;


/**
 * MaterialPassBase provides an abstract base class for material shader passes.
 *
 * Vertex stream index 0 is reserved for vertex positions.
 * Vertex shader constants index 0-3 are reserved for projections, constant 4 for viewport positioning
 * Vertex shader constant index 4 is reserved for render-to-texture scaling
 */
class MaterialPassBase extends EventDispatcher
{
	// keep track of previously rendered usage for faster cleanup of old vertex buffer streams and textures
	private static var _previousUsedStream:Int = 0;
	private static var _previousUsedTex:Int = 0;
	
	
	/**
	 * The material to which this pass belongs.
	 */
	public var material(get, set):MaterialBase;
	/**
	 * Indicate whether this pass should write to the depth buffer or not. Ignored when blending is enabled.
	 */
	public var writeDepth(get, set):Bool;
	/**
	 * Defines whether any used textures should use mipmapping.
	 */
	public var mipmap(get, set):Bool;
	/**
	 * Defines whether smoothing should be applied to any used textures.
	 */
	public var smooth(get, set):Bool;
	/**
	 * Defines whether textures should be tiled.
	 */
	public var repeat(get, set):Bool;
	/**
	 * Defines whether or not the material should perform backface culling.
	 */
	public var bothSides(get, set):Bool;
	public var depthCompareMode(get, set):Context3DCompareMode;
	/**
	 * The animation used to add vertex code to the shader code.
	 */
	public var animationSet(get, set):IAnimationSet;
	/**
	 * Specifies whether this pass renders to texture
	 */
	public var renderToTexture(get, null):Bool;
	/**
	 * The amount of used vertex streams in the vertex code. Used by the animation code generation to know from which index on streams are available.
	 */
	public var numUsedStreams(get, null):Int;
	/**
	 * The amount of used vertex constants in the vertex code. Used by the animation code generation to know from which index on registers are available.
	 */
	public var numUsedVertexConstants(get, null):Int;
	public var numUsedVaryings(get, null):Int;
	public var numUsedFragmentConstants(get, null):Int;
	public var needFragmentAnimation(get, null):Bool;
	/**
	 * Indicates whether the pass requires
	 */
	public var needUVAnimation(get, null):Bool;
	public var lightPicker(get, set):LightPickerBase;
	public var alphaPremultiplied(get, set):Bool;
	
	private var _material:MaterialBase;
	private var _animationSet:IAnimationSet;

	private var _program3D:Program3D;
	private var _program3Did:Int = -1;
	private var _context3D:Context3DProxy;

	// agal props. these NEED to be set by subclasses!
	// todo: can we perhaps figure these out manually by checking read operations in the bytecode, so other sources can be safely updated?
	private var _numUsedStreams:Int = 1;
	private var _numUsedTextures:Int;
	private var _numUsedVertexConstants:Int = 5;
	private var _numUsedFragmentConstants:Int;
	private var _numUsedVaryings:Int;

	private var _smooth:Bool = true;
	private var _repeat:Bool = false;
	private var _mipmap:Bool = true;
	private var _depthCompareMode:Context3DCompareMode;

	private var _blendFactorSource:Context3DBlendFactor;
	private var _blendFactorDest:Context3DBlendFactor;

	private var _enableBlending:Bool;

	private var _bothSides:Bool;

	private var _lightPicker:LightPickerBase;
	private var _animatableAttributes:Vector<String>;
	private var _animationTargetRegisters:Vector<String>;
	private var _shadedTarget:String;

	private var _defaultCulling:Context3DTriangleFace;

	private var _renderToTexture:Bool;

	// render state mementos for render-to-texture passes
	private var _oldTarget:TextureBase;
	private var _oldSurface:Int;
	private var _oldDepthStencil:Bool;
	private var _oldRect:Rectangle;

	private var _alphaPremultiplied:Bool;
	private var _needFragmentAnimation:Bool;
	private var _needUVAnimation:Bool;
	private var _UVTarget:String;
	private var _UVSource:String;

	private var _writeDepth:Bool = true;

	public var animationRegisterCache:AnimationRegisterCache;

	/**
	 * Creates a new MaterialPassBase object.
	 *
	 * @param renderToTexture
	 */
	public function new(renderToTexture:Bool = false)
	{
		super();
		
		_renderToTexture = renderToTexture;

		_depthCompareMode = Context3DCompareMode.LESS_EQUAL;

		_blendFactorSource = Context3DBlendFactor.ONE;
		_blendFactorDest = Context3DBlendFactor.ZERO;

		_animatableAttributes = Vector.ofArray(["va0"]);
		_animationTargetRegisters = Vector.ofArray(["vt0"]);
		_shadedTarget = "ft0";

		_defaultCulling = Context3DTriangleFace.BACK;
	}

	public function getProgram3Did():Int
	{
		return _program3Did;
	}

	public function setProgram3Did(value:Int):Void
	{
		_program3Did = value;
	}

	public function getProgram3D():Program3D
	{
		return _program3D;
	}

	public function setProgram3D(p:Program3D):Void
	{
		_program3D = p;
	}

	
	private function get_material():MaterialBase
	{
		return _material;
	}

	private function set_material(value:MaterialBase):MaterialBase
	{
		return _material = value;
	}

	
	private function get_writeDepth():Bool
	{
		return _writeDepth;
	}

	private function set_writeDepth(value:Bool):Bool
	{
		return _writeDepth = value;
	}

	
	private function get_mipmap():Bool
	{
		return _mipmap;
	}

	private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return _mipmap;
		_mipmap = value;
		invalidateShaderProgram();
		return _mipmap;
	}


	
	private function get_smooth():Bool
	{
		return _smooth;
	}

	private function set_smooth(value:Bool):Bool
	{
		if (_smooth == value)
			return _smooth;
		_smooth = value;
		invalidateShaderProgram();
		return _smooth;
	}

	
	private function get_repeat():Bool
	{
		return _repeat;
	}

	private function set_repeat(value:Bool):Bool
	{
		if (_repeat == value)
			return _repeat;
		_repeat = value;
		invalidateShaderProgram();
		return _repeat;
	}

	
	private function get_bothSides():Bool
	{
		return _bothSides;
	}

	private function set_bothSides(value:Bool):Bool
	{
		return _bothSides = value;
	}

	
	private function get_depthCompareMode():Context3DCompareMode
	{
		return _depthCompareMode;
	}

	private function set_depthCompareMode(value:Context3DCompareMode):Context3DCompareMode
	{
		return _depthCompareMode = value;
	}

	
	private function get_animationSet():IAnimationSet
	{
		return _animationSet;
	}

	private function set_animationSet(value:IAnimationSet):IAnimationSet
	{
		if (_animationSet == value)
			return _animationSet;

		_animationSet = value;

		invalidateShaderProgram();
		
		return _animationSet;
	}

	
	private function get_renderToTexture():Bool
	{
		return _renderToTexture;
	}

	/**
	 * Cleans up any resources used by the current object.
	 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
	 */
	public function dispose():Void
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);

		AGALProgram3DCache.getInstance().freeProgram3D(_program3Did);
	}

	
	private function get_numUsedStreams():Int
	{
		return _numUsedStreams;
	}

	
	private function get_numUsedVertexConstants():Int
	{
		return _numUsedVertexConstants;
	}

	
	private function get_numUsedVaryings():Int
	{
		return _numUsedVaryings;
	}

	
	private function get_numUsedFragmentConstants():Int
	{
		return _numUsedFragmentConstants;
	}

	
	private function get_needFragmentAnimation():Bool
	{
		return _needFragmentAnimation;
	}

	
	private function get_needUVAnimation():Bool
	{
		return _needUVAnimation;
	}

	/**
	 * Sets up the animation state. This needs to be called before render()
	 *
	 * @private
	 */
	public function updateAnimationState(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		renderable.animator.setRenderState(stage3DProxy, renderable, _numUsedVertexConstants, _numUsedStreams, camera);
	}

	/**
	 * Renders an object to the current render target.
	 *
	 * @private
	 */
	public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		throw new AbstractMethodError();
	}

	public function getVertexCode():String
	{
		throw new AbstractMethodError();
	}

	public function getFragmentCode(fragmentAnimatorCode:String):String
	{
		throw new AbstractMethodError();
	}

	public function setBlendMode(value:BlendMode):Void
	{
		switch (value)
		{
			case BlendMode.NORMAL:
				_blendFactorSource = Context3DBlendFactor.ONE;
				_blendFactorDest = Context3DBlendFactor.ZERO;
				_enableBlending = false;
			case BlendMode.LAYER:
				_blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
				_blendFactorDest = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				_enableBlending = true;
			case BlendMode.MULTIPLY:
				_blendFactorSource = Context3DBlendFactor.ZERO;
				_blendFactorDest = Context3DBlendFactor.SOURCE_COLOR;
				_enableBlending = true;	
			case BlendMode.ADD:
				_blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
				_blendFactorDest = Context3DBlendFactor.ONE;
				_enableBlending = true;
			case BlendMode.ALPHA:
				_blendFactorSource = Context3DBlendFactor.ZERO;
				_blendFactorDest = Context3DBlendFactor.SOURCE_ALPHA;
				_enableBlending = true;	
			default:
				throw new ArgumentError("Unsupported blend mode!");
		}
	}

	public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		var context:Context3DProxy = stage3DProxy.context3D;

		context.setDepthTest(_writeDepth && !_enableBlending, _depthCompareMode);
		if (_enableBlending)
			context.setBlendFactors(_blendFactorSource, _blendFactorDest);

		if (_context3D != context || _program3D == null)
		{
			_context3D = context;
			updateProgram(stage3DProxy);
			dispatchEvent(new Event(Event.CHANGE));
		}

		var prevUsed:Int = _previousUsedStream;
		for (i in _numUsedStreams...prevUsed)
		{
			context.setVertexBufferAt(i, null);
		}

		prevUsed = _previousUsedTex;
		for (i in _numUsedTextures...prevUsed)
			context.setTextureAt(i, null);

		if (_animationSet != null && !_animationSet.usesCPU)
			_animationSet.activate(stage3DProxy, this);

		context.setProgram(_program3D);

		context.setCulling(_bothSides ? Context3DTriangleFace.NONE : _defaultCulling);

		if (_renderToTexture)
		{
			_oldTarget = stage3DProxy.renderTarget;
			_oldSurface = stage3DProxy.renderSurfaceSelector;
			_oldDepthStencil = stage3DProxy.enableDepthAndStencil;
			_oldRect = stage3DProxy.scissorRect;
		}
	}

	/**
	 * Turns off streams starting from a certain offset
	 *
	 * @private
	 */
	public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		_previousUsedStream = _numUsedStreams;
		_previousUsedTex = _numUsedTextures;

		if (_animationSet != null && !_animationSet.usesCPU)
			_animationSet.deactivate(stage3DProxy, this);

		if (_renderToTexture)
		{
			// kindly restore state
			stage3DProxy.setRenderTarget(_oldTarget, _oldDepthStencil, _oldSurface);
			stage3DProxy.scissorRect = _oldRect;
		}

		stage3DProxy.context3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
	}

	/**
	 * Marks the shader program as invalid, so it will be recompiled before the next render.
	 *
	 * @param updateMaterial Indicates whether the invalidation should be performed on the entire material. Should always pass "true" unless it's called from the material itself.
	 */
	public function invalidateShaderProgram(updateMaterial:Bool = true):Void
	{
		_program3D = null;

		if (_material != null && updateMaterial)
			_material.invalidatePasses(this);
	}

	/**
	 * Compiles the shader program.
	 * @param polyOffsetReg An optional register that contains an amount by which to inflate the model (used in single object depth map rendering).
	 */
	public function updateProgram(stage3DProxy:Stage3DProxy):Void
	{
		var animatorCode:String = "";
		var UVAnimatorCode:String = "";
		var fragmentAnimatorCode:String = "";
		var vertexCode:String = getVertexCode();

		if (_animationSet != null && !_animationSet.usesCPU)
		{
			animatorCode = _animationSet.getAGALVertexCode(this, _animatableAttributes, _animationTargetRegisters, stage3DProxy.profile);
			if (_needFragmentAnimation)
				fragmentAnimatorCode = _animationSet.getAGALFragmentCode(this, _shadedTarget, stage3DProxy.profile);
			if (_needUVAnimation)
				UVAnimatorCode = _animationSet.getAGALUVCode(this, _UVSource, _UVTarget);
			_animationSet.doneAGALCode(this);
		}
		else
		{
			var len:Int = _animatableAttributes.length;

			// simply write attributes to targets, do not animate them
			// projection will pick up on targets[0] to do the projection
			for (i in 0...len)
				animatorCode += "mov " + _animationTargetRegisters[i] + ", " + _animatableAttributes[i] + "\n";
			if (_needUVAnimation)
				UVAnimatorCode = "mov " + _UVTarget + "," + _UVSource + "\n";
		}

		vertexCode = animatorCode + UVAnimatorCode + vertexCode;

		var fragmentCode:String = getFragmentCode(fragmentAnimatorCode);
		if (Debug.active)
		{
			Debug.trace("Compiling AGAL Code:");
			Debug.trace("--------------------");
			Debug.trace(vertexCode);
			Debug.trace("--------------------");
			Debug.trace(fragmentCode);
		}
		AGALProgram3DCache.getInstance().setProgram3D(this, vertexCode, fragmentCode);
	}

	
	private function get_lightPicker():LightPickerBase
	{
		return _lightPicker;
	}

	private function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
			
		_lightPicker = value;
		
		if (_lightPicker != null)
			_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
			
		updateLights();
		
		return _lightPicker;
	}

	private function onLightsChange(event:Event):Void
	{
		updateLights();
	}

	// need to implement if pass is light-dependent
	private function updateLights():Void
	{

	}

	
	private function get_alphaPremultiplied():Bool
	{
		return _alphaPremultiplied;
	}

	private function set_alphaPremultiplied(value:Bool):Bool
	{
		_alphaPremultiplied = value;
		invalidateShaderProgram(false);
		return _alphaPremultiplied;
	}
}

package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.passes.MaterialPassBase;
import a3d.materials.passes.OutlinePass;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;


/**
 * OutlineMethod provides a shading method to add outlines to an object.
 */
class OutlineMethod extends EffectMethodBase
{
	/**
	 * Indicates whether or not strokes should be potentially drawn over the existing model.
	 * Set this to true to draw outlines for geometry overlapping in the view, useful to achieve a cel-shaded drawing outline.
	 * Setting this to false will only cause the outline to appear around the 2D projection of the geometry.
	 */
	public var showInnerLines(get,set):Bool;
	/**
	 * The colour of the outline.
	 */
	public var outlineColor(get,set):UInt;
	/**
	 * The size of the outline.
	 */
	public var outlineSize(get, set):Float;
	
	private var _outlinePass:OutlinePass;

	/**
	 * Creates a new OutlineMethod object.
	 * @param outlineColor The colour of the outline stroke
	 * @param outlineSize The size of the outline stroke
	 * @param showInnerLines Indicates whether or not strokes should be potentially drawn over the existing model.
	 * @param dedicatedWaterProofMesh Used to stitch holes appearing due to mismatching normals for overlapping vertices. Warning: this will create a new mesh that is incompatible with animations!
	 */
	public function new(outlineColor:UInt = 0x000000, outlineSize:Float = 1, showInnerLines:Bool = true, dedicatedWaterProofMesh:Bool = false)
	{
		super();
		_passes = new Vector<MaterialPassBase>();
		_outlinePass = new OutlinePass(outlineColor, outlineSize, showInnerLines, dedicatedWaterProofMesh);
		_passes.push(_outlinePass);
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
	}

	
	private function get_showInnerLines():Bool
	{
		return _outlinePass.showInnerLines;
	}

	private function set_showInnerLines(value:Bool):Bool
	{
		return _outlinePass.showInnerLines = value;
	}

	
	private function get_outlineColor():UInt
	{
		return _outlinePass.outlineColor;
	}

	private function set_outlineColor(value:UInt):UInt
	{
		return _outlinePass.outlineColor = value;
	}

	
	private function get_outlineSize():Float
	{
		return _outlinePass.outlineSize;
	}

	private function set_outlineSize(value:Float):Float
	{
		return _outlinePass.outlineSize = value;
	}

	override public function reset():Void
	{
		super.reset();
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		return "";
	}
}

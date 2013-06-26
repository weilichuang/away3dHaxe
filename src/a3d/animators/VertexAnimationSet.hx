package a3d.animators;

import flash.display3D.Context3D;
import flash.utils.Dictionary;
import flash.Vector;


import a3d.animators.data.VertexAnimationMode;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.passes.MaterialPassBase;



/**
 * The animation data set used by vertex-based animators, containing vertex animation state data.
 *
 * @see a3d.animators.VertexAnimator
 */
class VertexAnimationSet extends AnimationSetBase implements IAnimationSet
{
	private var _numPoses:UInt;
	private var _blendMode:String;
	private var _streamIndices:Dictionary = new Dictionary(true);
	private var _useNormals:Dictionary = new Dictionary(true);
	private var _useTangents:Dictionary = new Dictionary(true);
	private var _uploadNormals:Bool;
	private var _uploadTangents:Bool;

	/**
	 * Returns the number of poses made available at once to the GPU animation code.
	 */
	private inline function get_numPoses():UInt
	{
		return _numPoses;
	}

	/**
	 * Returns the active blend mode of the vertex animator object.
	 */
	private inline function get_blendMode():String
	{
		return _blendMode;
	}

	/**
	 * Returns whether or not normal data is used in last set GPU pass of the vertex shader.
	 */
	private inline function get_useNormals():Bool
	{
		return _uploadNormals;
	}

	/**
	 * Creates a new <code>VertexAnimationSet</code> object.
	 *
	 * @param numPoses The number of poses made available at once to the GPU animation code.
	 * @param blendMode Optional value for setting the animation mode of the vertex animator object.
	 *
	 * @see a3d.animators.data.VertexAnimationMode
	 */
	public function new(numPoses:UInt = 2, blendMode:String = "absolute")
	{
		super();
		_numPoses = numPoses;
		_blendMode = blendMode;

	}

	/**
	 * @inheritDoc
	 */
	public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector<String>, targetRegisters:Vector<String>, profile:String):String
	{
		if (_blendMode == VertexAnimationMode.ABSOLUTE)
			return getAbsoluteAGALCode(pass, sourceRegisters, targetRegisters);
		else
			return getAdditiveAGALCode(pass, sourceRegisters, targetRegisters);
	}


	/**
	 * @inheritDoc
	 */
	public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void
	{
		_uploadNormals = Bool(_useNormals[pass]);
		_uploadTangents = Bool(_useTangents[pass]);
	}

	/**
	 * @inheritDoc
	 */
	public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void
	{
		var index:Int = _streamIndices[pass];
		var context:Context3D = stage3DProxy.context3D;
		context.setVertexBufferAt(index, null);
		if (_uploadNormals)
			context.setVertexBufferAt(index + 1, null);
		if (_uploadTangents)
			context.setVertexBufferAt(index + 2, null);
	}

	/**
	 * @inheritDoc
	 */
	public function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String
	{
		return "";
	}

	/**
	 * @inheritDoc
	 */
	public function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String
	{
		return "mov " + UVTarget + "," + UVSource + "\n";
	}

	/**
	 * @inheritDoc
	 */
	public function doneAGALCode(pass:MaterialPassBase):Void
	{

	}

	/**
	 * Generates the vertex AGAL code for absolute blending.
	 */
	private function getAbsoluteAGALCode(pass:MaterialPassBase, sourceRegisters:Vector<String>, targetRegisters:Vector<String>):String
	{
		var code:String = "";
		var temp1:String = findTempReg(targetRegisters);
		var temp2:String = findTempReg(targetRegisters, temp1);
		var regs:Array = ["x", "y", "z", "w"];
		var len:UInt = sourceRegisters.length;
		var constantReg:String = "vc" + pass.numUsedVertexConstants;
		var useTangents:Bool = Bool(_useTangents[pass] = len > 2);
		_useNormals[pass] = len > 1;

		if (len > 2)
			len = 2;
		var streamIndex:UInt = _streamIndices[pass] = pass.numUsedStreams;

		for (i in 0...len)
		{
			code += "mul " + temp1 + ", " + sourceRegisters[i] + ", " + constantReg + "." + regs[0] + "\n";

			for (j in 1..._numPoses)
			{
				code += "mul " + temp2 + ", va" + streamIndex + ", " + constantReg + "." + regs[j] + "\n";

				if (j < _numPoses - 1)
					code += "add " + temp1 + ", " + temp1 + ", " + temp2 + "\n";

				++streamIndex;
			}

			code += "add " + targetRegisters[i] + ", " + temp1 + ", " + temp2 + "\n";
		}

		// add code for bitangents if tangents are used
		if (useTangents)
		{
			code += "dp3 " + temp1 + ".x, " + sourceRegisters[2] + ", " + targetRegisters[1] + "\n" +
				"mul " + temp1 + ", " + targetRegisters[1] + ", " + temp1 + ".x			 \n" +
				"sub " + targetRegisters[2] + ", " + sourceRegisters[2] + ", " + temp1 + "\n";
		}
		return code;
	}

	/**
	 * Generates the vertex AGAL code for additive blending.
	 */
	private function getAdditiveAGALCode(pass:MaterialPassBase, sourceRegisters:Vector<String>, targetRegisters:Vector<String>):String
	{
		var code:String = "";
		var len:UInt = sourceRegisters.length;
		var regs:Array = ["x", "y", "z", "w"];
		var temp1:String = findTempReg(targetRegisters);
		var k:UInt;
		var useTangents:Bool = Bool(_useTangents[pass] = len > 2);
		var useNormals:Bool = Bool(_useNormals[pass] = len > 1);
		var streamIndex:UInt = _streamIndices[pass] = pass.numUsedStreams;

		if (len > 2)
			len = 2;

		code += "mov  " + targetRegisters[0] + ", " + sourceRegisters[0] + "\n";
		if (useNormals)
			code += "mov " + targetRegisters[1] + ", " + sourceRegisters[1] + "\n";

		for (i in 0...len)
		{
			for (j in 0..._numPoses)
			{
				code += "mul " + temp1 + ", va" + (streamIndex + k) + ", vc" + pass.numUsedVertexConstants + "." + regs[j] + "\n" +
					"add " + targetRegisters[i] + ", " + targetRegisters[i] + ", " + temp1 + "\n";
				k++;
			}
		}

		if (useTangents)
		{
			code += "dp3 " + temp1 + ".x, " + sourceRegisters[2] + ", " + targetRegisters[1] + "\n" +
				"mul " + temp1 + ", " + targetRegisters[1] + ", " + temp1 + ".x			 \n" +
				"sub " + targetRegisters[2] + ", " + sourceRegisters[2] + ", " + temp1 + "\n";
		}

		return code;
	}
}

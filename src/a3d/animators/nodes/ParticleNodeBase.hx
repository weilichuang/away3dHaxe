package a3d.animators.nodes;

import flash.utils.getQualifiedClassName;
import flash.Vector;


import a3d.animators.ParticleAnimationSet;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ParticleProperties;
import a3d.materials.passes.MaterialPassBase;



/**
 * Provides an abstract base class for particle animation nodes.
 */
class ParticleNodeBase extends AnimationNodeBase
{
	private var _mode:UInt;
	private var _priority:Int;

	private var _dataLength:UInt = 3;
	private var _oneData:Vector<Float>;

	public var dataOffset:UInt;

	/**
	 * Returns the property mode of the particle animation node. Typically set in the node constructor
	 *
	 * @see a3d.animators.data.ParticlePropertiesMode
	 */
	private inline function get_mode():UInt
	{
		return _mode;
	}

	/**
	 * Returns the priority of the particle animation node, used to order the agal generated in a particle animation set. Set automatically on instantiation.
	 *
	 * @see a3d.animators.ParticleAnimationSet
	 * @see #getAGALVertexCode
	 */
	private inline function get_priority():Int
	{
		return _priority;
	}

	/**
	 * Returns the length of the data used by the node when in <code>LOCAL_STATIC</code> mode. Used to generate the local static data of the particle animation set.
	 *
	 * @see a3d.animators.ParticleAnimationSet
	 * @see #getAGALVertexCode
	 */
	private inline function get_dataLength():Int
	{
		return _dataLength;
	}

	/**
	 * Returns the generated data vector of the node after one particle pass during the generation of all local static data of the particle animation set.
	 *
	 * @see a3d.animators.ParticleAnimationSet
	 * @see #generatePropertyOfOneParticle
	 */
	private inline function get_oneData():Vector<Float>
	{
		return _oneData;
	}

	//modes alias
	private static var GLOBAL:String = 'Global';
	private static var LOCAL_STATIC:String = 'LocalStatic';
	private static var LOCAL_DYNAMIC:String = 'LocalDynamic';

	//modes list
	private static var MODES:Object =
		{
			0: GLOBAL,
			1: LOCAL_STATIC,
			2: LOCAL_DYNAMIC
		};

	/**
	 *
	 * @param	particleNodeClass - class of ParticleNodeBase child e.g ParticleBillboardNode, ParticleFollowNode...
	 * @param	particleNodeMode  - mode of particle node ParticlePropertiesMode.GLOBAL, ParticlePropertiesMode.LOCAL_DYNAMIC or ParticlePropertiesMode.LOCAL_STATIC
	 * @return 	particle node name
	 */
	public static function getParticleNodeName(particleNodeClass:Object, particleNodeMode:UInt):String
	{
		var nodeName:String = particleNodeClass['ANIMATION_NODE_NAME'];

		if (nodeName == "" || nodeName == null)
			nodeName = getNodeNameFromClass(particleNodeClass);

		return nodeName + MODES[particleNodeMode];
	}

	private static function getNodeNameFromClass(particleNodeClass:Object):String
	{
		return getQualifiedClassName(particleNodeClass).replace('Node', '').split('::')[1];
	}

	/**
	 * Creates a new <code>ParticleNodeBase</code> object.
	 *
	 * @param               name            Defines the generic name of the particle animation node.
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param               dataLength      Defines the length of the data used by the node when in <code>LOCAL_STATIC</code> mode.
	 * @param    [optional] priority        the priority of the particle animation node, used to order the agal generated in a particle animation set. Defaults to 1.
	 */
	public function new(name:String, mode:UInt, dataLength:UInt, priority:Int = 1)
	{
		name = name + MODES[mode];

		this.name = name;
		_mode = mode;
		_priority = priority;
		_dataLength = dataLength;

		_oneData = new Vector<Float>(_dataLength, true);
	}

	/**
	 * Returns the AGAL code of the particle animation node for use in the vertex shader.
	 */
	public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;
		animationRegisterCache = animationRegisterCache;
		return "";
	}

	/**
	 * Returns the AGAL code of the particle animation node for use in the fragment shader.
	 */
	public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;
		animationRegisterCache = animationRegisterCache;
		return "";
	}

	/**
	 * Returns the AGAL code of the particle animation node for use in the fragment shader when UV coordinates are required.
	 */
	public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;
		animationRegisterCache = animationRegisterCache;
		return "";
	}

	/**
	 * Called internally by the particle animation set when assigning the set of static properties originally defined by the initParticleFunc of the set.
	 *
	 * @see a3d.animators.ParticleAnimationSet#initParticleFunc
	 */
	public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{

	}

	/**
	 * Called internally by the particle animation set when determining the requirements of the particle animation node AGAL.
	 */
	public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{

	}
}

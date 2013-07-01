package a3d.animators.states;

import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.Vector;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticleAnimationData;
import a3d.animators.nodes.ParticleNodeBase;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;

import haxe.ds.WeakMap;

/**
 * ...
 */
class ParticleStateBase extends AnimationStateBase
{
	private var _particleNode:ParticleNodeBase;

	private var _dynamicProperties:Vector<Vector3D>;
	private var _dynamicPropertiesDirty:WeakMap<AnimationSubGeometry,Bool>;

	private var _needUpdateTime:Bool;

	public function new(animator:ParticleAnimator, particleNode:ParticleNodeBase, needUpdateTime:Bool = false)
	{
		super(animator, particleNode);

		_particleNode = particleNode;
		_needUpdateTime = needUpdateTime;
		
		_dynamicProperties = new Vector<Vector3D>();
		_dynamicPropertiesDirty = new WeakMap<AnimationSubGeometry,Bool>();
	}

	public var needUpdateTime(get,null):Bool;
	private function get_needUpdateTime():Bool
	{
		return _needUpdateTime;
	}

	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{

	}

	private function updateDynamicProperties(animationSubGeometry:AnimationSubGeometry):Void
	{
		_dynamicPropertiesDirty.set(animationSubGeometry,true);

		var animationParticles:Vector<ParticleAnimationData> = animationSubGeometry.animationParticles;
		var vertexData:Vector<Float> = animationSubGeometry.vertexData;
		var totalLenOfOneVertex:Int = animationSubGeometry.totalLenOfOneVertex;
		var dataLength:Int = _particleNode.dataLength;
		var dataOffset:Int = _particleNode.dataOffset;
		var vertexLength:Int;
//			var particleOffset:UInt;
		var startingOffset:Int;
		var vertexOffset:Int;
		var data:Vector3D;
		var animationParticle:ParticleAnimationData;

//			var numParticles:UInt = _positions.length/dataLength;
		var numParticles:Int = _dynamicProperties.length;
		var i:Int = 0;
		var j:Int = 0;
		var k:Int = 0;

		//loop through all particles
		while (i < numParticles)
		{
			//loop through each particle data for the current particle
			while (j < numParticles && 
				(animationParticle = animationParticles[j]).index == i)
			{
				data = _dynamicProperties[i];
				vertexLength = animationParticle.numVertices * totalLenOfOneVertex;
				startingOffset = animationParticle.startVertexIndex * totalLenOfOneVertex + dataOffset;
				//loop through each vertex in the particle data
				k = 0; 
				while (k < vertexLength)
				{
					vertexOffset = startingOffset + k;
//					particleOffset = i * dataLength;
					//loop through all vertex data for the current particle data
					var m:Int = 0;
					while (m < vertexLength)
					{
						vertexOffset = startingOffset + m;
						vertexData[vertexOffset++] = data.x;
						vertexData[vertexOffset++] = data.y;
						vertexData[vertexOffset++] = data.z;

						if (dataLength == 4)
							vertexData[vertexOffset++] = data.w;
							
						m += totalLenOfOneVertex;
					}
					//loop through each value in the particle vertex
//					switch(dataLength) 
					//{
//						case 4:
//							vertexData[vertexOffset++] = _positions[particleOffset++];
//						case 3:
//							vertexData[vertexOffset++] = _positions[particleOffset++];
//						case 2:
//							vertexData[vertexOffset++] = _positions[particleOffset++];
//						case 1:
//							vertexData[vertexOffset++] = _positions[particleOffset++];
//					}
					k += totalLenOfOneVertex;
				}
				j++;
			}
			i++;
		}

		animationSubGeometry.invalidateBuffer();
	}

}

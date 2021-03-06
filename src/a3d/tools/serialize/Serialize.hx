package a3d.tools.serialize;

import a3d.animators.data.JointPose;
import a3d.animators.data.Skeleton;
import a3d.animators.data.SkeletonJoint;
import a3d.animators.data.SkeletonPose;
import a3d.animators.IAnimator;
import a3d.core.base.ISubGeometry;
import a3d.core.base.SkinnedSubGeometry;
import a3d.core.base.SubMesh;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.entities.Scene3D;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.MaterialBase;

class Serialize
{
	public static var tabSize:Int = 2;

	public function new()
	{
	}

	public static function serializeScene(scene:Scene3D, serializer:SerializerBase):Void
	{
		for (i in 0...scene.numChildren)
		{
			serializeObjectContainer(scene.getChildAt(i), serializer);
		}
	}

	public static function serializeObjectContainer(objectContainer3D:ObjectContainer3D, serializer:SerializerBase):Void
	{
		if (Std.is(objectContainer3D,Mesh))
		{
			serializeMesh(Std.instance(objectContainer3D ,Mesh), serializer); // do not indent any extra for first level here
		}
		else
		{
			serializeObjectContainerInternal(objectContainer3D, serializer, true /* serializeChildrenAndEnd */);
		}
	}

	public static function serializeMesh(mesh:Mesh, serializer:SerializerBase):Void
	{
		serializeObjectContainerInternal(Std.instance(mesh,ObjectContainer3D), serializer, false /* serializeChildrenAndEnd */);
		serializer.writeBool("castsShadows", mesh.castsShadows);

		if (mesh.animator != null)
		{
			serializeAnimationState(mesh.animator, serializer);
		}

		if (mesh.material != null)
		{
			serializeMaterial(mesh.material, serializer);
		}

		if (mesh.subMeshes.length > 0)
		{
			for (subMesh in mesh.subMeshes)
			{
				serializeSubMesh(subMesh, serializer);
			}
		}
		serializeChildren(Std.instance(mesh,ObjectContainer3D), serializer);
		serializer.endObject();
	}

	public static function serializeAnimationState(animator:IAnimator, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(animator), null);
		serializeAnimator(animator, serializer);
		serializer.endObject();
	}

	public static function serializeAnimator(animator:IAnimator, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(animator), null);
		serializer.endObject();
	}

	public static function serializeSubMesh(subMesh:SubMesh, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(subMesh), null);
		if (subMesh.material != null)
		{
			serializeMaterial(subMesh.material, serializer);
		}
		if (subMesh.subGeometry != null)
		{
			serializeSubGeometry(subMesh.subGeometry, serializer);
		}
		serializer.endObject();
	}

	public static function serializeMaterial(material:MaterialBase, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(material), material.name);

		if (Std.is(material.lightPicker,StaticLightPicker))
		{
			serializer.writeString("lights", Std.instance(material.lightPicker,StaticLightPicker).lights.toString());
		}
		serializer.writeBool("mipmap", material.mipmap);
		serializer.writeBool("smooth", material.smooth);
		serializer.writeBool("repeat", material.repeat);
		serializer.writeBool("bothSides", material.bothSides);
		serializer.writeString("blendMode", material.blendMode.getName());
		serializer.writeBool("requiresBlending", material.requiresBlending);
		serializer.writeUint("uniqueId", material.uniqueId);
		serializer.writeUint("numPasses", material.numPasses);
		serializer.endObject();
	}

	public static function serializeSubGeometry(subGeometry:ISubGeometry, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(subGeometry), null);
		serializer.writeUint("numTriangles", subGeometry.numTriangles);
		if (subGeometry.indexData != null)
		{
			serializer.writeUint("numIndices", subGeometry.indexData.length);
		}
		serializer.writeUint("numVertices", subGeometry.numVertices);
		if (subGeometry.UVData != null)
		{
			serializer.writeUint("numUVs", subGeometry.UVData.length);
		}
		var skinnedSubGeometry:SkinnedSubGeometry = Std.instance(subGeometry,SkinnedSubGeometry);
		if (skinnedSubGeometry != null)
		{
			if (skinnedSubGeometry.jointWeightsData != null)
			{
				serializer.writeUint("numJointWeights", skinnedSubGeometry.jointWeightsData.length);
			}
			if (skinnedSubGeometry.jointIndexData != null)
			{
				serializer.writeUint("numJointIndexes", skinnedSubGeometry.jointIndexData.length);
			}
		}
		serializer.endObject();
	}

	public static function serializeSkeletonJoint(skeletonJoint:SkeletonJoint, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(skeletonJoint), skeletonJoint.name);
		serializer.writeInt("parentIndex", skeletonJoint.parentIndex);
		serializer.writeTransform("inverseBindPose", skeletonJoint.inverseBindPose);
		serializer.endObject();
	}

	public static function serializeSkeleton(skeleton:Skeleton, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(skeleton), skeleton.name);
		for (skeletonJoint in skeleton.joints)
		{
			serializeSkeletonJoint(skeletonJoint, serializer);
		}
		serializer.endObject();
	}

	public static function serializeJointPose(jointPose:JointPose, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(jointPose), jointPose.name);
		serializer.writeVector3D("translation", jointPose.translation);
		serializer.writeQuaternion("orientation", jointPose.orientation);
		serializer.endObject();
	}

	public static function serializeSkeletonPose(skeletonPose:SkeletonPose, serializer:SerializerBase):Void
	{
		serializer.beginObject(classNameFromInstance(skeletonPose), "" /*skeletonPose.name*/);
		serializer.writeUint("numJointPoses", skeletonPose.numJointPoses);
		for (jointPose in skeletonPose.jointPoses)
		{
			serializeJointPose(jointPose, serializer);
		}
		serializer.endObject();
	}

	// private stuff - shouldn't ever need to call externally

	private static function serializeChildren(parent:ObjectContainer3D, serializer:SerializerBase):Void
	{
		for (i in 0...parent.numChildren)
		{
			serializeObjectContainer(parent.getChildAt(i), serializer);
		}
	}

	private static function classNameFromInstance(instance:Dynamic):String
	{
		return Type.getClassName(instance);
	}

	private static function serializeObjectContainerInternal(objectContainer:ObjectContainer3D, serializer:SerializerBase, serializeChildrenAndEnd:Bool):Void
	{
		serializer.beginObject(classNameFromInstance(objectContainer), objectContainer.name);
		serializer.writeTransform("transform", objectContainer.transform.rawData);
		if (serializeChildrenAndEnd)
		{
			serializeChildren(objectContainer, serializer);
			serializer.endObject();
		}
	}
}

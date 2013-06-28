package a3d.entities;


import a3d.animators.IAnimator;
import a3d.core.base.Geometry;
import a3d.core.base.IMaterialOwner;
import a3d.core.base.ISubGeometry;
import a3d.core.base.Object3D;
import a3d.core.base.SubGeometry;
import a3d.core.base.SubMesh;
import a3d.core.partition.EntityNode;
import a3d.core.partition.MeshNode;
import a3d.events.GeometryEvent;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.materials.MaterialBase;
import a3d.materials.utils.DefaultMaterialManager;
import flash.Vector;



/**
 * Mesh is an instance of a Geometry, augmenting it with a presence in the scene graph, a material, and an animation
 * state. It consists out of SubMeshes, which in turn correspond to SubGeometries. SubMeshes allow different parts
 * of the geometry to be assigned different materials.
 */
class Mesh extends Entity implements IMaterialOwner implements IAsset
{
	private var _subMeshes:Vector<SubMesh>;
	private var _geometry:Geometry;
	private var _material:MaterialBase;
	private var _animator:IAnimator;
	private var _castsShadows:Bool;
	private var _shareAnimationGeometry:Bool;

	/**
	 * Create a new Mesh object.
	 *
	 * @param geometry					The geometry used by the mesh that provides it with its shape.
	 * @param material	[optional]		The material with which to render the Mesh.
	 */
	public function new(geometry:Geometry, material:MaterialBase = null)
	{
		super();
		
		_subMeshes = new Vector<SubMesh>();
		_shareAnimationGeometry = true;
		 _castsShadows = true;

		this.geometry = geometry != null ? geometry : new Geometry(); //this should never happen, but if people insist on trying to create their meshes before they have geometry to fill it, it becomes necessary

		this.material = material != null ?  material : DefaultMaterialManager.getDefaultMaterial(this);
	}

	public function bakeTransformations():Void
	{
		geometry.applyTransformation(transform);
		transform.identity();
	}

	override private function get_assetType():String
	{
		return AssetType.MESH;
	}


	private function onGeometryBoundsInvalid(event:GeometryEvent):Void
	{
		invalidateBounds();
	}

	/**
	 * Indicates whether or not the Mesh can cast shadows. Default value is <code>true</code>.
	 */
	public var castsShadows(get, set):Bool;
	private inline function get_castsShadows():Bool
	{
		return _castsShadows;
	}

	private inline function set_castsShadows(value:Bool):Bool
	{
		return _castsShadows = value;
	}

	/**
	 * Defines the animator of the mesh. Act on the mesh's geometry.  Default value is <code>null</code>.
	 */
	public var animator(get, set):IAnimator;
	private inline function get_animator():IAnimator
	{
		return _animator;
	}

	private inline function set_animator(value:IAnimator):IAnimator
	{
		if (_animator != null)
			_animator.removeOwner(this);

		_animator = value;

		// cause material to be unregistered and registered again to work with the new animation type (if possible)
		var oldMaterial:MaterialBase = material;
		material = null;
		material = oldMaterial;

		var len:Int = _subMeshes.length;
		var subMesh:SubMesh;

		// reassign for each SubMesh
		for (i in 0...len)
		{
			subMesh = _subMeshes[i];
			oldMaterial = subMesh.material;
			if (oldMaterial != null)
			{
				subMesh.material = null;
				subMesh.material = oldMaterial;
			}
		}

		if (_animator != null)
			_animator.addOwner(this);
			
		return _animator;
	}

	/**
	 * The geometry used by the mesh that provides it with its shape.
	 */
	public var geometry(get, set):Geometry;
	private inline function get_geometry():Geometry
	{
		return _geometry;
	}

	private inline function set_geometry(value:Geometry):Geometry
	{
		if (_geometry != null)
		{
			_geometry.removeEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
			_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
			_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);

			for (i in 0..._subMeshes.length)
			{
				_subMeshes[i].dispose();
			}
			_subMeshes.length = 0;
		}

		_geometry = value;
		if (_geometry != null)
		{
			_geometry.addEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
			_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
			_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);

			var subGeoms:Vector<ISubGeometry> = _geometry.subGeometries;
			for (i in 0...subGeoms.length)
				addSubMesh(subGeoms[i]);
		}

		if (_material != null)
		{
			// reregister material in case geometry has a different animation
			_material.removeOwner(this);
			_material.addOwner(this);
		}
		
		return _geometry;
	}

	/**
	 * The material with which to render the Mesh.
	 */
	public var material(get, set):MaterialBase;
	private inline function get_material():MaterialBase
	{
		return _material;
	}

	private inline function set_material(value:MaterialBase):MaterialBase
	{
		if (value == _material)
			return _material;
		if (_material != null)
			_material.removeOwner(this);
		_material = value;
		if (_material != null)
			_material.addOwner(this);
			
		return _material;
	}

	/**
	 * The SubMeshes out of which the Mesh consists. Every SubMesh can be assigned a material to override the Mesh's
	 * material.
	 */
	public var subMeshes(get, null):Vector<SubMesh>;
	private inline function get_subMeshes():Vector<SubMesh>
	{
		// Since this getter is invoked every iteration of the render loop, and
		// the geometry construct could affect the sub-meshes, the geometry is
		// validated here to give it a chance to rebuild.
		_geometry.validate();

		return _subMeshes;
	}

	/**
	 * Indicates whether or not the mesh share the same animation geometry.
	 */
	public var shareAnimationGeometry(get, set):Bool;
	private inline function get_shareAnimationGeometry():Bool
	{
		return _shareAnimationGeometry;
	}

	private inline function set_shareAnimationGeometry(value:Bool):Bool
	{
		return _shareAnimationGeometry = value;
	}

	/**
	 * Clears the animation geometry of this mesh. It will cause animation to generate a new animation geometry. Work only when shareAnimationGeometry is false.
	 */
	public function clearAnimationGeometry():Void
	{
		var len:Int = _subMeshes.length;
		for (i in 0...len)
		{
			_subMeshes[i].animationSubGeometry = null;
		}
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		super.dispose();

		material = null;
		geometry = null;
	}

	/**
	 * Disposes mesh including the animator and children. This is a merely a convenience method.
	 * @return
	 */
	public function disposeWithAnimatorAndChildren():Void
	{
		disposeWithChildren();

		if (_animator != null)
			_animator.dispose();
	}

	/**
	 * Clones this Mesh instance along with all it's children, while re-using the same
	 * material, geometry and animation set. The returned result will be a copy of this mesh,
	 * containing copies of all of it's children.
	 *
	 * Properties that are re-used (i.e. not cloned) by the new copy include name,
	 * geometry, and material. Properties that are cloned or created anew for the copy
	 * include subMeshes, children of the mesh, and the animator.
	 *
	 * If you want to copy just the mesh, reusing it's geometry and material while not
	 * cloning it's children, the simplest way is to create a new mesh manually:
	 *
	 * <code>
	 * var clone : Mesh = new Mesh(original.geometry, original.material);
	 * </code>
	*/
	override public function clone():Object3D
	{
		var clone:Mesh = new Mesh(_geometry, _material);
		clone.transform = transform;
		clone.pivotPoint = pivotPoint;
		clone.partition = partition;
		clone.bounds = _bounds.clone();
		clone.name = name;
		clone.castsShadows = castsShadows;
		clone.shareAnimationGeometry = shareAnimationGeometry;
		clone.mouseEnabled = this.mouseEnabled;
		clone.mouseChildren = this.mouseChildren;
		//this is of course no proper cloning
		//maybe use this instead?: http://blog.another-d-mention.ro/programming/how-to-clone-duplicate-an-object-in-actionscript-3/
		clone.extra = this.extra;

		var len:Int = _subMeshes.length;
		for (i in 0...len)
		{
			clone._subMeshes[i].material = _subMeshes[i].material;
		}

		len = numChildren;
		for (i in 0...len)
		{
			clone.addChild(Std.instance(getChildAt(i).clone(),ObjectContainer3D));
		}

		if (_animator != null)
		{
			clone.animator = _animator.clone();
		}

		return clone;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
		_bounds.fromGeometry(_geometry);
		_boundsInvalid = false;
	}

	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new MeshNode(this);
	}

	/**
	 * Called when a SubGeometry was added to the Geometry.
	 */
	private function onSubGeometryAdded(event:GeometryEvent):Void
	{
		addSubMesh(event.subGeometry);
	}

	/**
	 * Called when a SubGeometry was removed from the Geometry.
	 */
	private function onSubGeometryRemoved(event:GeometryEvent):Void
	{
		var subMesh:SubMesh;
		var subGeom:ISubGeometry = event.subGeometry;
		var len:Int = _subMeshes.length;
		var i:UInt;

		// Important! This has to be done here, and not delayed until the
		// next render loop, since this may be caused by the geometry being
		// rebuilt IN THE RENDER LOOP. Invalidating and waiting will delay
		// it until the NEXT RENDER FRAME which is probably not desirable.

		for (i in 0...len)
		{
			subMesh = _subMeshes[i];
			if (subMesh.subGeometry == subGeom)
			{
				subMesh.dispose();
				_subMeshes.splice(i, 1);
				break;
			}
		}

		--len;
		for (i in 0...len)
		{
			_subMeshes[i].index = i;
		}
	}

	/**
	 * Adds a SubMesh wrapping a SubGeometry.
	 */
	private function addSubMesh(subGeometry:ISubGeometry):Void
	{
		var subMesh:SubMesh = new SubMesh(subGeometry, this, null);
		var len:Int = _subMeshes.length;
		subMesh.index = len;
		_subMeshes[len] = subMesh;
		invalidateBounds();
	}

	public function getSubMeshForSubGeometry(subGeometry:SubGeometry):SubMesh
	{
		return _subMeshes[_geometry.subGeometries.indexOf(subGeometry)];
	}

	override public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
	{
		_pickingCollider.setLocalRay(pickingCollisionVO.localRayPosition, pickingCollisionVO.localRayDirection);
		pickingCollisionVO.renderable = null;
		var len:Int = _subMeshes.length;
		for (i in 0...len)
		{
			var subMesh:SubMesh = _subMeshes[i];

			//var ignoreFacesLookingAway:Bool = _material ? !_material.bothSides : true;
			if (_pickingCollider.testSubMeshCollision(subMesh, pickingCollisionVO, shortestCollisionDistance))
			{
				shortestCollisionDistance = pickingCollisionVO.rayEntryDistance;
				pickingCollisionVO.renderable = subMesh;
				if (!findClosest)
					return true;
			}
		}

		return pickingCollisionVO.renderable != null;
	}
}

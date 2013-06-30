package a3d.events;

import flash.events.Event;

import a3d.io.library.assets.IAsset;

class AssetEvent extends Event
{
	public static inline var ASSET_COMPLETE:String = "assetComplete";
	public static inline var ENTITY_COMPLETE:String = "entityComplete";
	public static inline var SKYBOX_COMPLETE:String = "skyboxComplete";
	public static inline var CAMERA_COMPLETE:String = "cameraComplete";
	public static inline var MESH_COMPLETE:String = "meshComplete";
	public static inline var GEOMETRY_COMPLETE:String = "geometryComplete";
	public static inline var SKELETON_COMPLETE:String = "skeletonComplete";
	public static inline var SKELETON_POSE_COMPLETE:String = "skeletonPoseComplete";
	public static inline var CONTAINER_COMPLETE:String = "containerComplete";
	public static inline var TEXTURE_COMPLETE:String = "textureComplete";
	public static inline var TEXTURE_PROJECTOR_COMPLETE:String = "textureProjectorComplete";
	public static inline var MATERIAL_COMPLETE:String = "materialComplete";
	public static inline var ANIMATOR_COMPLETE:String = "animatorComplete";
	public static inline var ANIMATION_SET_COMPLETE:String = "animationSetComplete";
	public static inline var ANIMATION_STATE_COMPLETE:String = "animationStateComplete";
	public static inline var ANIMATION_NODE_COMPLETE:String = "animationNodeComplete";
	public static inline var STATE_TRANSITION_COMPLETE:String = "stateTransitionComplete";
	public static inline var SEGMENT_SET_COMPLETE:String = "segmentSetComplete";
	public static inline var LIGHT_COMPLETE:String = "lightComplete";
	public static inline var LIGHTPICKER_COMPLETE:String = "lightPickerComplete";
	public static inline var EFFECTMETHOD_COMPLETE:String = "effectMethodComplete";
	public static inline var SHADOWMAPMETHOD_COMPLETE:String = "shadowMapMethodComplete";

	public static inline var ASSET_RENAME:String = 'assetRename';
	public static inline var ASSET_CONFLICT_RESOLVED:String = 'assetConflictResolved';

	public static inline var TEXTURE_SIZE_ERROR:String = 'textureSizeError';

	private var _asset:IAsset;
	private var _prevName:String;

	public function new(type:String, asset:IAsset = null, prevName:String = null)
	{
		super(type);

		_asset = asset;
		_prevName = prevName != null ? prevName : (_asset != null ? _asset.name : null);
	}

	public var asset(get, null):IAsset;

	private function get_asset():IAsset
	{
		return _asset;
	}

	public var assetPrevName(get, null):String;
	private function get_assetPrevName():String
	{
		return _prevName;
	}


	override public function clone():Event
	{
		return new AssetEvent(type, asset, assetPrevName);
	}
}

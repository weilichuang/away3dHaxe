package a3d.core.managers;

import flash.display.Stage;
import flash.display3D.Context3DProfile;
import flash.errors.Error;
import haxe.ds.ObjectMap;
import flash.Vector;

/**
 * The Stage3DManager class provides a multiton object that handles management for Stage3D objects. Stage3D objects
 * should not be requested directly, but are exposed by a Stage3DProxy.
 *
 * @see a3d.core.managers.Stage3DProxy
 */
class Stage3DManager
{
	
	private static var _instances:ObjectMap<Stage,Stage3DManager>;
	private static var _stageProxies:Vector<Stage3DProxy>;
	private static var _numStageProxies:Int = 0;

	/**
	 * Gets a Stage3DManager instance for the given Stage object.
	 * @param stage The Stage object that contains the Stage3D objects to be managed.
	 * @return The Stage3DManager instance for the given Stage object.
	 */
	public static function getInstance(stage:Stage):Stage3DManager
	{
		if (_instances == null)
			_instances = new ObjectMap();
			
		var manager:Stage3DManager = _instances.get(stage);
		if (manager == null)
		{
			manager = new Stage3DManager(stage);
			_instances.set(stage, manager);
		}
		return manager;
	}
	
	/**
	 * Checks if a new stage3DProxy can be created and managed by the class.
	 * @return true if there is one slot free for a new stage3DProxy
	 */
	public var hasFreeStage3DProxy(get, null):Bool;
	/**
	 * Returns the amount of stage3DProxy objects that can be created and managed by the class
	 * @return the amount of free slots
	 */
	public var numProxySlotsFree(get, null):Int;
	/**
	 * Returns the amount of Stage3DProxy objects currently managed by the class.
	 * @return the amount of slots used
	 */
	public var numProxySlotsUsed(get, null):Int;
	/**
	 * Returns the maximum amount of Stage3DProxy objects that can be managed by the class
	 * @return the maximum amount of Stage3DProxy objects that can be managed by the class
	 */
	public var numProxySlotsTotal(get, null):Int;
	
	private var _stage:Stage;

	/**
	 * Creates a new Stage3DManager class.
	 * @param stage The Stage object that contains the Stage3D objects to be managed.
	 * @private
	 */
	public function new(stage:Stage)
	{
		_stage = stage;

		if (_stageProxies == null)
			_stageProxies = new Vector<Stage3DProxy>(_stage.stage3Ds.length, true);
	}

	/**
	 * Requests the Stage3DProxy for the given index.
	 * @param index The index of the requested Stage3D.
	 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
	 * @param profile The compatibility profile, an enumeration of Context3DProfile
	 * @return The Stage3DProxy for the given index.
	 */
	public function getStage3DProxy(index:Int = 0, forceSoftware:Bool = false, profile:Context3DProfile = null):Stage3DProxy
	{
		if (_stageProxies[index] == null)
		{
			_numStageProxies++;
			_stageProxies[index] = new Stage3DProxy(index, _stage.stage3Ds[index], this, forceSoftware, profile);
		}

		return _stageProxies[index];
	}

	/**
	 * Removes a Stage3DProxy from the manager.
	 * @param stage3DProxy
	 * @private
	 */
	public function removeStage3DProxy(stage3DProxy:Stage3DProxy):Void
	{
		_numStageProxies--;
		_stageProxies[stage3DProxy.stage3DIndex] = null;
	}

	/**
	 * Get the next available stage3DProxy. An error is thrown if there are no Stage3DProxies available
	 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
	 * @param profile The compatibility profile, an enumeration of Context3DProfile
	 * @return The allocated stage3DProxy
	 */
	public function getFreeStage3DProxy(forceSoftware:Bool = false, profile:Context3DProfile = null):Stage3DProxy
	{
		var len:Int = _stageProxies.length;
		for (i in 0...len)
		{
			if (_stageProxies[i] == null)
			{
				getStage3DProxy(i, forceSoftware, profile);
				_stageProxies[i].width = _stage.stageWidth;
				_stageProxies[i].height = _stage.stageHeight;
				return _stageProxies[i];
			}
		}

		throw new Error("Too many Stage3D instances used!");
		return null;
	}

	
	private function get_hasFreeStage3DProxy():Bool
	{
		return _numStageProxies < _stageProxies.length ? true : false;
	}

	
	private function get_numProxySlotsFree():Int
	{
		return _stageProxies.length - _numStageProxies;
	}

	
	private function get_numProxySlotsUsed():Int
	{
		return _numStageProxies;
	}

	private function get_numProxySlotsTotal():Int
	{
		return _stageProxies.length;
	}
}

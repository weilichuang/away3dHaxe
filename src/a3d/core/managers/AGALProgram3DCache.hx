package a3d.core.managers;

import a3d.A3d;
import a3d.events.Stage3DEvent;
import a3d.materials.passes.MaterialPassBase;
import a3d.utils.Debug;
import com.adobe.utils.AGALMiniAssembler;
import flash.display3D.Context3DProgramType;
import flash.display3D.Program3D;
import flash.errors.Error;
import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;

//TODO 重命名
class AGALProgram3DCache
{
	private static var _instance:AGALProgram3DCache;
	private static var _currentId:Int = 0;

	private var _stage3DProxy:Stage3DProxy;

	private var _program3Ds:StringMap<Program3D>;
	private var _ids:StringMap<Int>;
	private var _usages:Array<Int>;
	private var _keys:Array<String>;

	public function new()
	{
	}
	
	public function initialize(stage3DProxy:Stage3DProxy):Void
	{
		_stage3DProxy = stage3DProxy;
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed, false, 0, true);
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed, false, 0, true);
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DDisposed, false, 0, true);

		_program3Ds = new StringMap<Program3D>();
		_ids = new StringMap<Int>();
		_usages = [];
		_keys = [];
	}

	public static function getInstance():AGALProgram3DCache
	{
		if (_instance == null)
			_instance = new AGALProgram3DCache();
		return _instance;
	}

	private function onContext3DDisposed(event:Stage3DEvent):Void
	{
		var stage3DProxy:Stage3DProxy = Std.instance(event.target,Stage3DProxy);
		stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
		stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed);
		stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DDisposed);
		
		_instance.dispose();
		_instance.initialize(stage3DProxy);
	}

	public function dispose():Void
	{
		var keys:Iterator<String> = _program3Ds.keys();
		for (key in keys)
			destroyProgram(key);

		_keys = null;
		_program3Ds = null;
		_usages = null;
	}

	public function setProgram3D(pass:MaterialPassBase, vertexCode:String, fragmentCode:String):Void
	{
		var stageIndex:Int = _stage3DProxy.stage3DIndex;
		var program:Program3D;
		var key:String = getKey(vertexCode, fragmentCode);

		if (!_program3Ds.exists(key))
		{
			_keys[_currentId] = key;
			_usages[_currentId] = 0;
			_ids.set(key, _currentId);
			++_currentId;
			program = _stage3DProxy.context3D.createProgram();

			var vertexByteCode:ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, vertexCode);
			var fragmentByteCode:ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, fragmentCode);

			program.upload(vertexByteCode, fragmentByteCode);

			_program3Ds.set(key, program);
		}

		var oldId:Int = pass.getProgram3Did();
		var newId:Int = _ids.get(key);

		if (oldId != newId)
		{
			if (oldId >= 0)
				freeProgram3D(oldId);
			_usages[newId]++;
		}

		pass.setProgram3Did(newId);
		pass.setProgram3D(_program3Ds.get(key));
	}

	public function freeProgram3D(programId:Int):Void
	{
		_usages[programId]--;
		if (_usages[programId] == 0)
			destroyProgram(_keys[programId]);
	}

	private function destroyProgram(key:String):Void
	{
		_program3Ds.get(key).dispose();
		_program3Ds.remove(key);
		_ids.set(key, -1);
	}

	private inline function getKey(vertexCode:String, fragmentCode:String):String
	{
		return vertexCode + "---" + fragmentCode;
	}
}

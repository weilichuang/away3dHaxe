package a3d.animators
{
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	
	import a3d.animators.data.SpriteSheetAnimationFrame;
	import a3d.animators.states.ISpriteSheetAnimationState;
	import a3d.animators.states.SpriteSheetAnimationState;
	import a3d.animators.transitions.IAnimationTransition;
	import a3d.entities.Camera3D;
	import a3d.core.base.IRenderable;
	import a3d.core.base.SubMesh;
	import a3d.core.managers.Stage3DProxy;
	import a3d.materials.MaterialBase;
	import a3d.materials.SpriteSheetMaterial;
	import a3d.materials.TextureMaterial;
	import a3d.materials.passes.MaterialPassBase;

	

	/**
	 * Provides an interface for assigning uv-based sprite sheet animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	class SpriteSheetAnimator extends AnimatorBase implements IAnimator
	{
		private var _activeSpriteSheetState:ISpriteSheetAnimationState;
		private var _spriteSheetAnimationSet:SpriteSheetAnimationSet;
		private var _frame:SpriteSheetAnimationFrame = new SpriteSheetAnimationFrame();
		private var _vectorFrame:Vector<Float>;
		private var _fps:UInt = 10;
		private var _ms:UInt = 100;
		private var _lastTime:UInt;
		private var _reverse:Bool;
		private var _backAndForth:Bool;
		private var _specsDirty:Bool;
		private var _mapDirty:Bool;

		/**
		 * Creates a new <code>SpriteSheetAnimator</code> object.
		 * @param spriteSheetAnimationSet  The animation data set containing the sprite sheet animation states used by the animator.
		 */
		public function SpriteSheetAnimator(spriteSheetAnimationSet:SpriteSheetAnimationSet)
		{
			super(spriteSheetAnimationSet);
			_spriteSheetAnimationSet = spriteSheetAnimationSet;
			_vectorFrame = new Vector<Float>();
		}

		/* Set the playrate of the animation in frames per second (not depending on player fps)*/
		private inline function set_fps(val:UInt):Void
		{
			_ms = 1000 / val;
			_fps = val;
		}

		private inline function get_fps():UInt
		{
			return _fps;
		}

		/* If true, reverse causes the animation to play backwards*/
		private inline function set_reverse(b:Bool):Void
		{
			_reverse = b;
			_specsDirty = true;
		}

		private inline function get_reverse():Bool
		{
			return _reverse;
		}

		/* If true, backAndForth causes the animation to play backwards and forward alternatively. Starting forward.*/
		private inline function set_backAndForth(b:Bool):Void
		{
			_backAndForth = b;
			_specsDirty = true;
		}

		private inline function get_backAndForth():Bool
		{
			return _backAndForth;
		}

		/* sets the animation pointer to a given frame and plays from there. Equivalent to ActionScript, the first frame is at 1, not 0.*/
		public function gotoAndPlay(frameNumber:UInt):Void
		{
			gotoFrame(frameNumber, true);
		}

		/* sets the animation pointer to a given frame and stops there. Equivalent to ActionScript, the first frame is at 1, not 0.*/
		public function gotoAndStop(frameNumber:UInt):Void
		{
			gotoFrame(frameNumber, false);
		}

		/* returns the current frame*/
		private inline function get_currentFrameNumber():UInt
		{
			return SpriteSheetAnimationState(_activeState).currentFrameNumber;
		}

		/* returns the total amount of frame for the current animation*/
		private inline function get_totalFrames():UInt
		{
			return SpriteSheetAnimationState(_activeState).totalFrames;
		}

		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
		{
			var material:MaterialBase = renderable.material;
			if (material == null || !Std.is(material,TextureMaterial))
				return;

			var subMesh:SubMesh = renderable as SubMesh;
			if (subMesh == null)
				return;

			//because textures are already uploaded, we can't offset the uv's yet
			var swapped:Bool;

			if (material is SpriteSheetMaterial && _mapDirty)
				swapped = SpriteSheetMaterial(material).swap(_frame.mapID);

			if (!swapped)
			{
				_vectorFrame[0] = _frame.offsetU;
				_vectorFrame[1] = _frame.offsetV;
				_vectorFrame[2] = _frame.scaleU;
				_vectorFrame[3] = _frame.scaleV;
			}

			//vc[vertexConstantOffset]
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _vectorFrame);
		}

		/**
		 * @inheritDoc
		 */
		public function play(name:String, transition:IAnimationTransition = null, offset:Float = NaN):Void
		{
			transition = transition;
			offset = offset;
			if (_activeAnimationName == name)
				return;

			_activeAnimationName = name;

			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");

			_activeNode = _animationSet.getAnimation(name);
			_activeState = getAnimationState(_activeNode);
			_frame = SpriteSheetAnimationState(_activeState).currentFrameData;
			_activeSpriteSheetState = _activeState as ISpriteSheetAnimationState;

			start();
		}

		/**
		 * Applies the calculated time delta to the active animation state node.
		 */
		override private function updateDeltaTime(dt:Float):Void
		{
			if (_specsDirty)
			{
				SpriteSheetAnimationState(_activeSpriteSheetState).reverse = _reverse;
				SpriteSheetAnimationState(_activeSpriteSheetState).backAndForth = _backAndForth;
				_specsDirty = false;
			}

			_absoluteTime += dt;
			var now:Int = getTimer();

			if ((now - _lastTime) > _ms)
			{
				_mapDirty = true;
				_activeSpriteSheetState.update(_absoluteTime);
				_frame = SpriteSheetAnimationState(_activeSpriteSheetState).currentFrameData;
				_lastTime = now;

			}
			else
			{
				_mapDirty = false;
			}

		}

		public function testGPUCompatibility(pass:MaterialPassBase):Void
		{
		}

		public function clone():IAnimator
		{
			return new SpriteSheetAnimator(_spriteSheetAnimationSet);
		}

		private function gotoFrame(frameNumber:UInt, doPlay:Bool):Void
		{
			if (!_activeState)
				return;
			SpriteSheetAnimationState(_activeState).currentFrameNumber = (frameNumber == 0) ? frameNumber : frameNumber - 1;
			var currentMapID:UInt = _frame.mapID;
			_frame = SpriteSheetAnimationState(_activeSpriteSheetState).currentFrameData;

			if (doPlay)
			{
				start();
			}
			else
			{
				if (currentMapID != _frame.mapID)
				{
					_mapDirty = true;
					setTimeout(stop, _fps);
				}
				else
				{
					stop();
				}

			}
		}

	}
}

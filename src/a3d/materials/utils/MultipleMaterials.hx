package a3d.materials.utils
{
	import a3d.materials.MaterialBase;

	class MultipleMaterials
	{
		private var _left:MaterialBase;
		private var _right:MaterialBase;
		private var _bottom:MaterialBase;
		private var _top:MaterialBase;
		private var _front:MaterialBase;
		private var _back:MaterialBase;

		/**
		* Creates a new <code>MultipleMaterials</code> object.
		* Class can hold up to 6 materials. Class is designed to work as typed object for materials setters in a multitude of classes such as Cube, LatheExtrude (with thickness) etc...
		*
		* @param	front:MaterialBase		[optional] The front material.
		* @param	back:MaterialBase		[optional] The back material.
		* @param	left:MaterialBase		[optional] The left material.
		* @param	right:MaterialBase		[optional] The right material.
		* @param	top:MaterialBase		[optional] The top material.
		* @param	down:MaterialBase		[optional] The down material.
		*/

		public function MultipleMaterials(front:MaterialBase = null, back:MaterialBase = null, left:MaterialBase = null, right:MaterialBase = null, top:MaterialBase = null)
		{
			_left = left;
			_right = right;
			_bottom = bottom;
			_top = top;
			_front = front;
			_back = back;
		}

		/**
		* Defines the material applied to the left side of the cube.
		*/
		private inline function get_left():MaterialBase
		{
			return _left;
		}

		private inline function set_left(val:MaterialBase):Void
		{
			if (_left == val)
				return;

			_left = val;
		}

		/**
		* Defines the material applied to the right side of the cube.
		*/
		private inline function get_right():MaterialBase
		{
			return _right;
		}

		private inline function set_right(val:MaterialBase):Void
		{
			if (_right == val)
				return;

			_right = val;
		}

		/**
		* Defines the material applied to the bottom side of the cube.
		*/
		private inline function get_bottom():MaterialBase
		{
			return _bottom;
		}

		private inline function set_bottom(val:MaterialBase):Void
		{
			if (_bottom == val)
				return;

			_bottom = val;
		}

		/**
		* Defines the material applied to the top side of the cube.
		*/
		private inline function get_top():MaterialBase
		{
			return _top;
		}

		private inline function set_top(val:MaterialBase):Void
		{
			if (_top == val)
				return;

			_top = val;
		}

		/**
		* Defines the material applied to the front side of the cube.
		*/
		private inline function get_front():MaterialBase
		{
			return _front;
		}

		private inline function set_front(val:MaterialBase):Void
		{
			if (_front == val)
				return;

			_front = val;
		}

		/**
		* Defines the material applied to the back side of the cube.
		*/
		private inline function get_back():MaterialBase
		{
			return _back;
		}

		private inline function set_back(val:MaterialBase):Void
		{
			if (_back == val)
				return;

			_back = val;
		}

	}
}

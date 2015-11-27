package away3d.materials;

/**
 * ...
 * @author 
 */
enum BlendMode
{
	NORMAL;
	/**
	 * Indicates the light map should be added into the calculated shading result.
	 * This can be used to add pre-calculated lighting or global illumination.
	 */
	ADD;
	ALPHA;
	DARKEN;
	DIFFERENCE;
	ERASE;
	HARDLIGHT;
	INVERT;
	LAYER;
	LIGHTEN;
	/**
	 * Indicates the light map should be multiplied with the calculated shading result.
	 * This can be used to add pre-calculated shadows or occlusion.
	 */
	MULTIPLY;
	OVERLAY;
	SCREEN;
	SHADER;
	MIX;
}
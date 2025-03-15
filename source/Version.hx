package;

/**
 * Helper object for semantic versioning.
 * @see   http://semver.org/
 */
class Version
{
	public var prefix(default, null):String;
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):Int;

	public function new(Prefix:String, Major:Int, Minor:Int, Patch:Int)
	{
                prefix = Prefix;
		major = Major;
		minor = Minor;
		patch = Patch;
	}

	public function toString(includePrefix:Bool = true):String
	{
		return '${includePrefix ? prefix : ''}v$major.$minor.$patch';
	}
}

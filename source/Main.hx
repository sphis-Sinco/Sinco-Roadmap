package;

import flixel.FlxG;
import flixel.FlxGame;
import funkin.util.plugins.ScreenshotPlugin;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, PlayState));
		ScreenshotPlugin.initialize();
	}
}

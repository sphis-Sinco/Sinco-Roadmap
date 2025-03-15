package;

import flixel.FlxSprite;
import sinlib.utilities.FileManager;
import sinlib.utilities.TryCatch;

class StopIcon extends FlxSprite
{
	public var stop_icon_scale = 4;
	public var stop_icon_pixel = 1;
	public var stop_icon_x_offset = 1;
	public var stop_icon_y_offset = 1;

	public var stopvalues:Map<String, Array<Dynamic>> = [
		'newgrounds' => [
			true,
			{
				frames: [0, 1],
				fps: 6
			}
		],
	];

	override public function new(stopSuffix:String = 'default')
	{
		super();

		stop_icon_pixel = 1 * stop_icon_scale;
		stop_icon_x_offset = 1 * stop_icon_pixel;
		stop_icon_y_offset = stop_icon_x_offset + (1 * stop_icon_pixel);

		var ezStopValues:Array<Dynamic> = [false];

		TryCatch.tryCatch(() ->
		{
			ezStopValues = stopvalues.get(stopSuffix.toLowerCase());
		}, {
				errFunc: () ->
				{
					trace('$stopSuffix has no stopvalues entry');
					ezStopValues = [false];
				}
		});

		var animated:Bool = false;

		TryCatch.tryCatch(() ->
		{
			animated = ezStopValues[0];
		}, {
				errFunc: () ->
				{
					animated = false;
				}
		});

		var suffix:String = stopSuffix;

		if (!FileManager.exists(FileManager.getImageFile('stop-$suffix')))
		{
			suffix = 'default';
		}

		loadGraphic(FileManager.getImageFile('stop-$suffix'), animated, 16, 16);

		if (animated)
		{
			trace('$suffix is animated: ${ezStopValues[1]}');
			animation.add('idle', ezStopValues[1].frames, ezStopValues[1].fps);

			animation.play('idle');
		}

		scale.set(stop_icon_scale, stop_icon_scale);
	}
}

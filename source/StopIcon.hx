package;

import flixel.FlxSprite;
import sinlib.utilities.FileManager;

class StopIcon extends FlxSprite
{
	public var stop_icon_scale = 4;
	public var stop_icon_pixel = 1;
	public var stop_icon_x_offset = 1;
	public var stop_icon_y_offset = 1;

        public var stopvalues:Map<String, Array<Dynamic>> = [
                'default' => [false],
                'newgrounds' => [true, {
                        frames: [0,1],
                        fps: 6
                }],
                'youtube' => [false]
        ];

	override public function new(stopSuffix:String = 'default')
	{
                super();
                        
                stop_icon_pixel = 1 * stop_icon_scale;
                stop_icon_x_offset = 1 * stop_icon_pixel;
                stop_icon_y_offset = 1 * stop_icon_pixel;

                var ezStopValues = stopvalues.get(stopSuffix.toLowerCase());
                
		loadGraphic(FileManager.getImageFile('stop-$stopSuffix'), ezStopValues[0], 16, 16);

                if (ezStopValues[0])
                {
                        trace('$stopSuffix is animated: ${ezStopValues[1]}');
                        animation.add('idle', ezStopValues[1].frames, ezStopValues[1].fps);

                        animation.play('idle');
                }

		scale.set(stop_icon_scale, stop_icon_scale);
	}
}

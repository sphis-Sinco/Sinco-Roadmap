package;

import RoadmapJson.RoadmapEntry;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import sinlib.utilities.FileManager;
import sinlib.utilities.TryCatch;

class PlayState extends FlxState
{
	public var roadmap:Array<RoadmapEntry>;

	public var roadmapGraphic:FlxTypedGroup<FlxObject>;
	public var roadmapTexts:FlxTypedGroup<FlxText>;

	final line_default_length:Int = 256;

	public var cam:FlxObject;

	override public function create()
	{
		super.create();
		roadmap = getRoadmapData();

		roadmapGraphic = new FlxTypedGroup<FlxObject>();
		add(roadmapGraphic);

		roadmapTexts = new FlxTypedGroup<FlxText>();

		var offset:FlxPoint = new FlxPoint(0, 0);

		var curDay:Int = Date.now().getDate();
		var curMonth:Int = Date.now().getMonth();
		var curYear:Int = Date.now().getFullYear();

		var curDate:String = '$curMonth.$curDay.$curYear';
		trace('curDate: $curDate');

		var prevDate:String = '';

		var index:Int = 1;
		var destinationCounts:Int = 0;
		var pitstopCounts:Int = 0;
		for (entry in roadmap)
		{
			final atEnd:Bool = (index != roadmap.length);

			if (entry.destination)
			{
				destinationCounts++;
			}
			else
			{
				pitstopCounts++;
			}

			final indexString:String = 'Idx: $index';

			var linelen:Int = line_default_length;

			var prevDateArray = prevDate.split('.');
			var entrydateArray = entry.date.split('.');

			final prevdateMonth:Int = Std.parseInt(prevDateArray[0]);
			final prevdateDay:Int = Std.parseInt(prevDateArray[1]);
			final prevdateYear:Int = Std.parseInt(prevDateArray[2]);

			final entrydateMonth:Int = Std.parseInt(entrydateArray[0]);
			final entrydateDay:Int = Std.parseInt(entrydateArray[1]);
			final entrydateYear:Int = Std.parseInt(entrydateArray[2]);

			final MonthDistance:Int = entrydateMonth - prevdateMonth;
			final DayDistance:Int = entrydateDay - prevdateDay;
			final YearDistance:Int = entrydateYear - prevdateYear;

			if (offset.x != 0)
			{
				trace('Time distances ($indexString): $MonthDistance/$DayDistance/$YearDistance');
				linelen = (line_default_length) + ((MonthDistance + DayDistance + YearDistance) * 12);
			}
			trace('line length ($indexString): $linelen');

			var referenceLine:FlxSprite = new FlxSprite();
			referenceLine.makeGraphic(line_default_length, 16);
			referenceLine.screenCenter();

			var line:FlxSprite = new FlxSprite();
			line.makeGraphic(linelen, Std.int(referenceLine.height), (entry.destination ? FlxColor.LIME : FlxColor.WHITE));
			line.setPosition(referenceLine.x, referenceLine.y);
			line.x += offset.x;
			line.y += offset.y;
			if (atEnd)
			{
				roadmapGraphic.add(line);
			}

			var label:FlxText = new FlxText(line.x, 0, 0, "", 16);
			label.text = '${(entry.destination ? 'DESTINATION $destinationCounts' : 'PITSTOP $pitstopCounts')}:\n${entry.label}\nDate: ${entry.date}';

			final label_offset_height:Float = label.height;

			final label_vertical_offset = 4;
			final line_height_w_vert_off = line.height + label_vertical_offset;

			if (index % 2 == 0)
			{
				trace('Swapping from bottom to top ($indexString): ${entry.label}');
				label.y = line.y - (line_height_w_vert_off) - (label_offset_height);
			}
			else
			{
				label.y = line.y + (line_height_w_vert_off) + (label_offset_height / 4);
			}
			roadmapGraphic.add(label);
			roadmapTexts.add(label);

			var icon:String = entry.icon;

			if (icon == 'default'
				&& entry.destination
				|| !FileManager.exists(FileManager.getImageFile('stop-$icon'))
				&& entry.destination)
			{
				icon = 'destination';
			}

			var stopIcon:StopIcon = new StopIcon(icon);
			stopIcon.setPosition(line.x + stopIcon.stop_icon_x_offset - stopIcon.stop_icon_pixel * 2, line.y + stopIcon.stop_icon_y_offset);
			roadmapGraphic.add(stopIcon);

			offset.x += line.width;
			prevDate = entry.date;
			index++;
		}
		cam = new FlxObject(0, -180, 1280, 720);
		add(cam);

		FlxG.camera.follow(cam);
	}

	final scrollSpeed:Float = 10.0;
	final camScrollSpeed:Float = 0.1;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.pressed.LEFT)
		{
			moveHortizontal(scrollSpeed);
		}
		else if (FlxG.keys.pressed.RIGHT)
		{
			moveHortizontal(-scrollSpeed);
		}

		if (FlxG.keys.pressed.UP)
		{
			moveVertical(scrollSpeed);
		}
		else if (FlxG.keys.pressed.DOWN)
		{
			moveVertical(-scrollSpeed);
		}

		if (!FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.justReleased.E)
			{
				zoom(camScrollSpeed);
				camLimits();
			}
			else if (FlxG.keys.justReleased.Q)
			{
				zoom(-camScrollSpeed);
				camLimits();
			}
		}
		else
		{
			if (FlxG.keys.pressed.E)
			{
				zoom(camScrollSpeed);
				camLimits();
			}
			else if (FlxG.keys.pressed.Q)
			{
				zoom(-camScrollSpeed);
				camLimits();
			}
		}

		if (FlxG.keys.pressed.R)
		{
			FlxG.resetState();
		}
	}

	function camLimits()
	{
		if (FlxG.camera.zoom < 1)
		{
			FlxG.camera.zoom = 1;
		}

		if (FlxG.camera.zoom > 2)
		{
			FlxG.camera.zoom = 2;
		}
	}

	function moveHortizontal(speed:Float)
	{
		cam.x -= speed;
	}

	function moveVertical(speed:Float)
	{
		cam.y -= speed;
	}

	function zoom(change:Float)
	{
		FlxG.camera.zoom += change;
	}

	function getRoadmapData():Array<RoadmapEntry>
	{
		/*var http = new haxe.Http("https://raw.githubusercontent.com/sphis-Sinco/Sinco-Roadmap/refs/heads/main/assets/data/roadmap.json");

			http.onData = function(data:Dynamic)
			{
				trace('No http error!');
				trace(data);
				TryCatch.tryCatch(() ->
				{
					return Json.parse(data);
				}, {
						errFunc: () ->
						{
							return FileManager.getJSON(FileManager.getDataFile('roadmap.json'));
						}
				});
			}

			http.onError = function(error)
			{
				trace('http error: $error');
			}

				http.request(); */

		return FileManager.getJSON(FileManager.getDataFile('roadmap.json'));
	}
}

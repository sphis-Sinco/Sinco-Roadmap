package;

import RoadmapJson.RoadmapEntry;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sinlib.utilities.FileManager;

class PlayState extends FlxState
{
	public var roadmap:Array<RoadmapEntry>;

	public var roadmapGraphic:FlxTypedGroup<FlxObject>;
	public var roadmapStops:FlxTypedGroup<StopIcon>;

	final line_default_length:Int = 256;

	public var cam:FlxObject;
	var version:Version = new Version("Sinco Roadmap ", 1, 1, 0);

	override public function create()
	{
		super.create();
		roadmap = getRoadmapData();

		roadmapGraphic = new FlxTypedGroup<FlxObject>();
		add(roadmapGraphic);

		roadmapStops = new FlxTypedGroup<StopIcon>();
		add(roadmapStops);

		var curDay:Int = Date.now().getDate();
		var curMonth:Int = Date.now().getMonth() + 1;
		var curYear:Int = Date.now().getFullYear();

		var curDate:String = '$curMonth.$curDay.$curYear';
		trace('curDate: $curDate');

		roadmap.push({
			date: curDate,
			destination: false,
			doesntCount: true,
			label: 'Now',
			icon: 'now'
		});

		for (entry in roadmap)
		{
			addNewEntryObjects(entry);
		}

		trace('All non-existing stop icon suffixes:\n${StopIcon.doesnt_exist}');

		cam = new FlxObject(0, -180, 1280, 720);
		add(cam);

		FlxG.camera.follow(cam);

		var helpText:FlxText = new FlxText(10, 10, 0,
			'Arrow keys - Move Camera\nQ/E - Zoom in/out\nHolding Shift - increase speed of Camera movement and zooming\nR - Reset\nS - Skip to the end', 16);
		helpText.scrollFactor.set(0, 0);
		add(helpText);
		var versionText:FlxText = new FlxText(10, 10 + helpText.height, 0, version.toString(), 16);
		versionText.scrollFactor.set(0, 0);
		add(versionText);
	}

	var destinationCounts:Int = 0;
	var pitstopCounts:Int = 0;

	var offset:FlxPoint = new FlxPoint(0, 0);

	var prevDate:String = '';

	var index:Int = 1;

	function addNewEntryObjects(entry:RoadmapEntry)
	{
		final atEnd:Bool = (index != roadmap.length);

		if (!entry.doesntCount)
		{
			if (entry.destination)
			{
				destinationCounts++;
			}
			else
			{
				pitstopCounts++;
			}
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

		var MonthDistance:Int = entrydateMonth - prevdateMonth;
		var DayDistance:Int = entrydateDay - prevdateDay;
		var YearDistance:Int = entrydateYear - prevdateYear;

		if (MonthDistance < 0)
		{
			MonthDistance = -MonthDistance;
		}
		if (DayDistance < 0)
		{
			DayDistance = -DayDistance;
		}
		if (YearDistance < 0)
		{
			YearDistance = -YearDistance;
		}

		if (offset.x != 0)
		{
			#if all_traces
			trace('Time distances ($indexString): $MonthDistance/$DayDistance/$YearDistance');
			#end
			linelen = (line_default_length) + (((MonthDistance * 6) + (DayDistance * 3) + (YearDistance * 12)) * 12);
		}
		#if all_traces
		trace('line length ($indexString): $linelen');
		#end

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

		var labelprefix:String = '';

		if (!entry.doesntCount)
		{
			labelprefix = '${(entry.destination ? 'DESTINATION $destinationCounts' : 'PITSTOP $pitstopCounts')}:\n';
		}

		var label:FlxText = new FlxText(line.x, 0, 0, '', 16);
		label.text = '${labelprefix}${entry.label}\nDate: ${entry.date}';

		final label_offset_height:Float = label.height;

		final label_vertical_offset = 4;
		final line_height_w_vert_off = line.height + label_vertical_offset;

		if (index % 2 == 0)
		{
			#if all_traces
			trace('Swapping from bottom to top ($indexString): ${entry.label}');
			#end
			label.y = line.y - (line_height_w_vert_off) - (label_offset_height);
		}
		else
		{
			label.y = line.y + (line_height_w_vert_off) + (label_offset_height / 4);
		}
		roadmapGraphic.add(label);

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

		#if !all_traces
		trace('Made $index/${roadmap.length} entries');
		// trace(entry.date);
		#end

		index++;
	}

	final scrollSpeed:Float = 10.0;
	final camScrollSpeed:Float = 0.1;

	final shiftScrollSpeedMult:Float = 5.0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		horizontalAndVerticalMovement();
		cameraZoom();

		if (FlxG.keys.pressed.R)
		{
			FlxG.resetState();
		}
		if (FlxG.keys.pressed.A)
		{
			cam.x = offset.x;
			cam.y = -180;
		}
		if (FlxG.keys.pressed.S)
		{
			cam.x = 0;
			cam.y = -180;
		}
	}

	function cameraZoom()
	{
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
	}

	function horizontalAndVerticalMovement()
	{
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
	}

	function camLimits()
	{
		if (FlxG.camera.zoom < 0.5)
		{
			FlxG.camera.zoom = 0.5;
		}

		if (FlxG.camera.zoom > 2)
		{
			FlxG.camera.zoom = 2;
		}
	}

	function moveHortizontal(speed:Float)
	{
		var speedVal:Float = speed;
		if (FlxG.keys.pressed.SHIFT)
		{
			speedVal = speed * shiftScrollSpeedMult;
		}

		cam.x -= speedVal;
	}

	function moveVertical(speed:Float)
	{
		var speedVal:Float = speed;
		if (FlxG.keys.pressed.SHIFT)
		{
			speedVal = speed * shiftScrollSpeedMult;
		}

		cam.y -= speedVal;
	}

	function zoom(change:Float)
	{
		FlxG.camera.zoom += change;
	}

	function getRoadmapData():Array<RoadmapEntry>
	{
		/*var http = new haxe.Http('https://raw.githubusercontent.com/sphis-Sinco/Sinco-Roadmap/refs/heads/main/assets/data/roadmap.json');

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

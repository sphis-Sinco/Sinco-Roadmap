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
import sinlib.utilities.TryCatch;

class PlayState extends FlxState
{
	public var roadmap:Array<RoadmapEntry>;

	public var roadmapGraphic:FlxTypedGroup<FlxObject>;
	public var roadmapStops:FlxTypedGroup<StopIcon>;

	public var roadmapOffsetXPositions:Array<Float> = [];

	final line_default_length:Int = 256;

	public var cam:FlxObject;
	public static var version:Version = new Version("Sinco Roadmap ", 1, 2, 1);

	public static var currentNewID:Int = 3;

	var curDate:String;
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

		curDate = '$curMonth.$curDay.$curYear';
		trace('curDate: $curDate');

		roadmap.push({
			date: curDate,
			destination: false,
			doesntCount: true,
			label: 'Now',
			icon: 'now'
		});

		FlxG.save.bind('sinco-roadmap', 'Sinco/ROADMAP');

		if (FlxG.save.data.version == null)
		{
			trace('Null version');
			FlxG.save.data.version = PlayState.version.toString(false);
		}

		FlxG.save.data.previousVersion = FlxG.save.data.version;
		FlxG.save.data.version = PlayState.version.toString(false);

		FlxG.save.data.checkedOutNewStuff = (FlxG.save.data.previousVersion == PlayState.version.toString(false));

		if (FlxG.save.data.checkedOutNewStuff)
		{
			trace('We\'ve played this update (${PlayState.version}) before...');
			FlxG.save.data.newID = PlayState.currentNewID;
		}

		for (entry in roadmap)
		{
			addNewEntryObjects(entry);
		}

		trace('All non-existing stop icon suffixes:\n${StopIcon.doesnt_exist}');

		cam = new FlxObject(0, -180, 1280, 720);
		add(cam);

		FlxG.camera.follow(cam);

		var helpText:FlxText = new FlxText(10, 10, 0,
			'Arrow keys - Move Camera\n'
			+ 'Q/E - Zoom in/out\n'
			+ 'Holding Shift - increase speed of Camera movement and zooming\n'
			+ 'R - Reset\n'
			+ 'A - Skip to the end\n'
			+ 'S - Go to the beginning\n'
			+ 'D - Move to next stop\n'
			+ 'F - Move to previous stop\n',
			16);
		helpText.scrollFactor.set(0, 0);
		add(helpText);
		var versionText:FlxText = new FlxText(10, 10 + helpText.height, 0, version.toString(), 16);
		versionText.scrollFactor.set(0, 0);
		add(versionText);
	}

	var destinationCounts:Int = 0;
	var pitstopCounts:Int = 0;

	var offset:FlxPoint = new FlxPoint(0, 0);

	var nextDate:String = '';

	var index:Int = 1;

	function addNewEntryObjects(entry:RoadmapEntry)
	{
		final atEnd:Bool = (index != roadmap.length);
		final isNew:Bool = (entry.isNew && entry.newID > FlxG.save.data.newID);

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

		var nextDateArray = curDate.split('.');
		TryCatch.tryCatch(() ->
		{
			nextDateArray = roadmap[index + 1].date.split('.');
		});
		var entrydateArray = entry.date.split('.');

		final entrydateMonth:Int = Std.parseInt(entrydateArray[0]);
		final entrydateDay:Int = Std.parseInt(entrydateArray[1]);
		final entrydateYear:Int = Std.parseInt(entrydateArray[2]);

		final nextDateMonth:Int = Std.parseInt(nextDateArray[0]);
		final nextDateDay:Int = Std.parseInt(nextDateArray[1]);
		final nextDateYear:Int = Std.parseInt(nextDateArray[2]);

		var MonthDistance:Int = nextDateMonth - entrydateMonth;
		var DayDistance:Int = nextDateDay - entrydateDay;
		var YearDistance:Int = nextDateYear - entrydateYear;

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

		#if all_traces
		trace('Time distances ($indexString): $MonthDistance/$DayDistance/$YearDistance');
		#end
		linelen = line_default_length + (((MonthDistance * 6) + (DayDistance * 3) + (YearDistance * 12)) * 12);
		#if all_traces
		trace('line length ($indexString): $linelen');
		#end

		var referenceLine:FlxSprite = new FlxSprite();
		referenceLine.makeGraphic(line_default_length, 16);
		referenceLine.screenCenter();

		var lineColor:FlxColor = new FlxColor();
		lineColor = entry.destination ? FlxColor.LIME : FlxColor.WHITE;

		if (isNew)
		{
			lineColor = FlxColor.RED;
		}

		var line:FlxSprite = new FlxSprite();
		line.makeGraphic(linelen, Std.int(referenceLine.height), lineColor);
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

		if (isNew)
		{
			label.color = FlxColor.LIME;
			label.text += '\nNEW!';
		}

		final label_offset_height:Float = label.height;

		final label_vertical_offset = 4;
		final line_height_w_vert_off = line.height + label_vertical_offset;

		if (index % 2 == 0)
		{
			#if all_traces
			// trace('Swapping from bottom to top ($indexString): ${entry.label}');
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
		nextDate = entry.date;

		index++;
		roadmapOffsetXPositions.push(offset.x);

		#if !all_traces
		trace('Made ${index - 1}/${roadmap.length} entries');
		// trace(entry.date);
		#end
	}

	final scrollSpeed:Float = 10.0;
	final camScrollSpeed:Float = 0.1;

	final shiftScrollSpeedMult:Float = 5.0;

	var currentStop:Int = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		horizontalAndVerticalMovement();
		cameraZoom();

		if (FlxG.keys.justReleased.R)
		{
			FlxG.resetState();
		}
		if (FlxG.keys.justReleased.A)
		{
			cam.x = offset.x;
			cam.y = -180;
			currentStop = roadmapOffsetXPositions.length - 1;
		}
		if (FlxG.keys.justReleased.S)
		{
			cam.x = 0;
			cam.y = -180;
			currentStop = 0;
		}
		if (FlxG.keys.justReleased.D)
		{
			currentStop++;

			if (currentStop > roadmapOffsetXPositions.length - 1)
			{
				currentStop--;
				cam.x = offset.x;
			}
			else
			{
				cam.x = roadmapOffsetXPositions[currentStop];
			}

			cam.y = -180;
		}
		if (FlxG.keys.justReleased.F)
		{
			currentStop--;

			if (currentStop < 0)
			{
				currentStop++;
				cam.x = 0;
			}
			else
			{
				cam.x = roadmapOffsetXPositions[currentStop];
			}

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

		currentStop = 0;
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

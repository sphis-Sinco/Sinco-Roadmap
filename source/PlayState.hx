package;

import RoadmapJson.RoadmapEntry;
import flixel.FlxBasic;
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

	public var roadmapGraphic:FlxTypedGroup<FlxBasic>;
	public var roadmapTexts:FlxTypedGroup<FlxText>;

	final line_default_length:Int = 256;

	override public function create()
	{
		super.create();
		roadmap = FileManager.getJSON(FileManager.getDataFile('roadmap.json'));

		roadmapGraphic = new FlxTypedGroup<FlxBasic>();
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
		for (entry in roadmap)
		{
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
				trace('Time distances: $MonthDistance/$DayDistance/$YearDistance');
				linelen = (line_default_length * 2) + (MonthDistance + DayDistance + YearDistance);
			}
			trace('line length: $linelen');

			var referenceLine:FlxSprite = new FlxSprite();
			referenceLine.makeGraphic(line_default_length, 32);
			referenceLine.screenCenter();

			var line:FlxSprite = new FlxSprite();
			line.makeGraphic(linelen, 32, (entry.destination ? FlxColor.LIME : FlxColor.WHITE));
			line.setPosition(referenceLine.x, referenceLine.y);
			line.x += offset.x;
			line.y += offset.y;
			roadmapGraphic.add(line);

			final label_vertical_offset = 4;
			final line_height_w_vert_off = line.height + label_vertical_offset;
			var label:FlxText = new FlxText(line.x, line.y + (line_height_w_vert_off), 0, entry.label, 32);
			if (index % 2 == 0)
			{
				trace('Swapping from bottom to top: ${entry.label}');
				label.y = line.y - (line_height_w_vert_off);
			}
			roadmapGraphic.add(label);
			roadmapTexts.add(label);

			offset.x += line.width;
			prevDate = entry.date;
			index++;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

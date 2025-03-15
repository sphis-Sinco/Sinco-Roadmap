package;

typedef RoadmapEntry =
{
	var date:String;
	var destination:Bool;
	var ?doesntCount:Bool;
	var label:String;
	var icon:String;
	var ?isNew:Bool;
	var ?newID:Int;
}

class RoadmapJsonManager
{

        public static var templateRoadmap:Array<RoadmapEntry> = [
                {
                        "date":"6.9.6969",
                        "destination": true,
			"label": "The 6969 day",
			"icon": "default"
                }
        ];
        
}
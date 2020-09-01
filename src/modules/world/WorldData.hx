package modules.world;

import level.data.Value;
import io.Imports;
import io.Export;
import util.Vector;
import util.Calc;

class WorldData
{
	public var size:Vector;
	public var offset:Vector;
	public var offsets: Map<String, Vector>; 
	public var values:Array<Value>;

	public function new() {
		size = new Vector();
		offset = new Vector();
		values = [];
	}

	public function clone():WorldData
	{
		var data = new WorldData();
		data.size = size.clone();
		data.offset = offset.clone();
		data.values = Calc.cloneArray(values);

		return data;
	}

	public function saveInto(data:Dynamic):Void
	{
		size.saveInto(data, "width", "height");
		offset.saveInto(data, "offsetX", "offsetY");
		Export.values(data, values);
	}

	public function loadFrom(data:Dynamic):Void
	{
		size = Imports.vector(data, "width", "height", OGMO.project.levelDefaultSize);
		offset = Imports.vector(data, "offsetX", "offsetY");
		values = Imports.values(data, OGMO.project.levelValues);
	}
}
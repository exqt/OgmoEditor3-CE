package modules.world;

import level.data.Level;
import js.node.Path;
import util.Fields;
import util.ItemList;
import level.data.Value;
import util.ItemList.ItemListItem;
import level.editor.ui.SidePanel;

class WorldSelectionPanel extends SidePanel
{
	public var holder: JQuery;
	public var worldEditor:WorldEditor;

	public function new(worldEditor:WorldEditor)
	{
		super();
		this.worldEditor = worldEditor;
	}
	
	public function onLevelClick(level:Level):Void
	{
		worldEditor.world.centerCamera(level);
		worldEditor.selected = [level];
		worldEditor.selectedChanged = true;
	}

	override public function populate(into: JQuery)
	{
		holder = into;
		refresh();
	}

	override public function refresh()
	{
		if (holder == null) return;
		
		holder.empty();

		var table = new JQuery("<table class='world-level-list'>");
		var tableHeader = new JQuery("<tr>");
		tableHeader.append("<th>Name</th>");
		tableHeader.append("<th>X</th>");
		tableHeader.append("<th>Y</th>");
		tableHeader.append("<th>W</th>");
		tableHeader.append("<th>H</th>");
		table.append(tableHeader);
		
		for (level in worldEditor.world.levels)
		{
			var row = new JQuery("<tr>");
			row.append("<td>" + Path.basename(level.path, ".json") + "</td>");
			row.append("<td>" + level.data.offset.x + "</td>");
			row.append("<td>" + level.data.offset.y + "</td>");
			row.append("<td>" + level.data.size.x + "</td>");
			row.append("<td>" + level.data.size.y + "</td>");

			row.on('click', (e) -> onLevelClick(level));
			table.append(row);
		}
		
		holder.append(table);
	}
}

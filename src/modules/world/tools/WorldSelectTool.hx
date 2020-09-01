package modules.world.tools;

import js.Browser;
import level.data.Level;
import modules.entities.tools.EntitySelectTool.SelectModes;

class WorldSelectTool extends WorldTool
{
	public var mode:SelectModes = None;
	public var levels:Array<Level>;
	public var selecting:Bool = false;
	public var start:Vector = new Vector();
	public var end:Vector = new Vector();
	public var firstChange:Bool = false;
	public var doubleClickLevel:Level = null;

	override public function drawOverlay()
	{
		if (mode == Select && !start.equals(end))
			EDITOR.overlay.drawRect(start.x, start.y, end.x - start.x, end.y - start.y, Color.green.x(0.2));
		else if (mode == Delete && !start.equals(end))
			EDITOR.overlay.drawRect(start.x, start.y, end.x - start.x, end.y - start.y, Color.red.x(0.2));
	}

	override public function deactivated()
	{
	}

	override public function onKeyPress(key:Int)
	{
	}

	override public function onMouseDown(pos:Vector)
	{
		editor.hovered = [];
		pos.clone(start);
		pos.clone(end);

		// double click
		var hit = editor.getFirstAt(pos);
		if (doubleClickLevel == null && hit.length > 0)
		{
			doubleClickLevel = hit[0];
			Browser.window.setTimeout(() -> doubleClickLevel = null, 400);
		}
		else if (doubleClickLevel != null && hit.length > 0 && hit[0] == doubleClickLevel)
		{
			if (OGMO.ctrl) Popup.openLevelProperties(hit[0]);
			else
			{
				EDITOR.activeWorldEditorMode(false);
				EDITOR.setLevel(hit[0]);
			}
		
			return;
		}

		if (hit.length == 0)
		{
			editor.selected = [];
			mode = Select;
		}
		else if (OGMO.shift)
		{
			editor.toggleSelected(hit);
			if (editor.selected.length > 0) startMove();
			else mode = None;
		}
		else if (editor.selectedContainsAny(hit))
		{
			startMove();
		}
		else
		{
			editor.selected = hit;
			startMove();
		}

		editor.selectedChanged = true;
		EDITOR.dirty();
	}

	public function startMove()
	{
		mode = Move;
		firstChange = false;
		editor.world.snapToGrid(start, start);
		levels = editor.selected;
	}

	override public function onMouseUp(pos:Vector)
	{
		editor.hovered = [];

		if (mode == Select)
		{
			pos.clone(end);

			var hits:Array<Level>;
			if (start.equals(end))
				hits = editor.getFirstAt(start);
			else
				hits = editor.getRect(Rectangle.fromPoints(start, end));

			if (OGMO.shift)
				editor.toggleSelected(hits);
			else
				editor.selected = hits;

			editor.selectedChanged = true;
			mode = None;
			EDITOR.overlayDirty();
		}
		else if (mode == Move)
		{
			mode = None;
			levels = null;
		}

	}

	override public function onMouseMove(pos:Vector)
	{
		EDITOR.dirty();
		if (mode == Select || mode == Delete)
		{
			pos.clone(end);
			editor.selectedChanged = true;
			EDITOR.dirty();

			var hit = editor.getRect(Rectangle.fromPoints(start, end));
			editor.hovered = hit;
		}
		else if (mode == Move)
		{
			// if (!OGMO.ctrl)
			editor.world.snapToGrid(pos, pos);

			if (!pos.equals(start))
			{
				if (!firstChange)
				{
					firstChange = true;
					// EDITOR.level.store("move decals");
				}

				var diff = new Vector(pos.x - start.x, pos.y - start.y);
				for (level in levels)
				{
					level.setOffset(level.data.offset.add(diff));
				}
				
				editor.selectionPanel.refresh();
				editor.selectedChanged = true;
				EDITOR.levelsPanel.refresh();
				EDITOR.dirty();
				pos.clone(start);
			}
		}
		else if (mode == None)
		{
			var hit = editor.getAt(pos);
			var isEqual = hit.length == editor.hovered.length;
			var i = 0;
			while (isEqual && i < hit.length)
			{
				if (editor.hovered.indexOf(hit[i]) < 0) isEqual = false;
				i++;
			}

			if (!isEqual)
			{
				editor.hovered = hit;
				editor.selectedChanged = true;
				EDITOR.dirty();
			}
		}
	}

	override public function onRightDown(pos:Vector)
	{
		pos.clone(start);
		pos.clone(end);
		mode = Delete;
	}

	override public function onRightUp(pos:Vector)
	{
		if (mode == Delete)
		{
			pos.clone(end);

			var hit: Array<Level>;
			var click = start.equals(end);

			if (click) hit = editor.getAt(start);
			else hit = editor.getRect(Rectangle.fromPoints(start, end));

			if (hit.length > 0)
			{
				// EDITOR.level.store("delete decals");
				if (click) editor.remove(hit[0]);
				else for (level in hit) editor.remove(level);
			}

			mode = None;
			editor.selectedChanged = true;
			EDITOR.dirty();
		}
	}
	override public function getIcon():String return "entity-selection";
	override public function getName():String return "Select";
	override public function keyToolAlt():Int return 1;
}
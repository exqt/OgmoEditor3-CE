package modules.world;

import js.node.Path;
import modules.world.World;
import modules.world.tools.WorldSelectTool;
import level.data.Level;
import level.editor.ui.SidePanel;
import rendering.Texture;

class WorldEditor
{
	public var world:World;

	public var brush:Texture;
	public var selected:Array<Level> = [];
	public var hovered:Array<Level> = [];
	public var selectedChanged:Bool = true;
	public var selectionPanel:SidePanel;
	public var selectTool:WorldSelectTool = new WorldSelectTool();

	public function new()
	{
		world = new World();
		selectionPanel = new WorldSelectionPanel(this);
	}

	public function addLevel(level:Level):Void
	{
		if (level == null) return;
		if (level.path == null) return;
		if (world.levels.indexOf(level) != -1) return;
		
		var levelBackup = EDITOR.level;
		var modeBackup = EDITOR.worldEditorMode;
		EDITOR.worldEditorMode = true;

		EDITOR.setLevel(level);
		level.generateLevelTexture();
		world.levels.push(level);
		selectionPanel.refresh();
		
		EDITOR.setLevel(levelBackup);
		EDITOR.worldEditorMode = modeBackup;
		
		var path = FileSystem.normalize(Path.relative(Path.dirname(OGMO.project.path), level.path));
		if (OGMO.project.worldLevelPaths.indexOf(path) == -1)
		{
			OGMO.project.worldLevelPaths.push(path);
		}
	}

	public function toggleSelected(list:Array<Level>):Void
	{
		var removing:Array<Level> = [];
		for (level in list)
		{
			if (selected.indexOf(level) >= 0) removing.push(level);
			else selected.push(level);
		}
		for (level in removing) selected.remove(level);
		selectedChanged = true;
	}

	public function selectedContainsAny(list:Array<Level>):Bool
	{
		for (level in list) if (selected.indexOf(level) >= 0) return true;
		return false;
	}

	public function remove(level:Level):Void
	{
		level.texture.dispose();
		world.levels.remove(level);
		hovered.remove(level);
		selected.remove(level);
		selectionPanel.refresh();

		var path = FileSystem.normalize(Path.relative(Path.dirname(OGMO.project.path), level.path));
		OGMO.project.worldLevelPaths.remove(path);
	}

	public function getFirstAt(pos:Vector):Array<Level>
	{
		var i = world.levels.length - 1;
		while (i >= 0)
		{
			var level = world.levels[i];
			if (level.rect.contains(pos)) return [level];
			i--;
		}
		return [];
	}

	public function getAt(pos:Vector):Array<Level>
	{
		var list:Array<Level> = [];
		var i = world.levels.length - 1;
		while (i >= 0)
		{
			var level = world.levels[i];
			if (level.rect.contains(pos)) list.push(level);
			i--;
		}
		return list;
	}

	public function getRect(rect:Rectangle):Array<Level>
	{
		var list:Array<Level> = [];
		var i = world.levels.length - 1;
		while (i >= 0)
		{
			var level = world.levels[i];
			if (rect.doOverlap(level.rect)) list.push(level);
			i--;
		}
		return list;
	}
	
	public function keyPress(key:Int):Void
	{
		switch (key)
		{
			case Keys.A: 
				if (OGMO.ctrl) 
				{
					selected = world.levels.copy();
					selectedChanged = true;
				}
			case Keys.S:
				if (OGMO.ctrl) world.save();
		}
	}

	public function draw():Void
	{
		for (level in world.levels)
		{
			if (level.texture.loaded && level.texture != null) {
				EDITOR.draw.drawTexture(level.data.offset.x, level.data.offset.y, level.texture);
			}
		}
	}

	public function drawOverlay()
	{
		if (selected.length <= 0) return;

		for (level in selected) 
		{
			var rect = new Rectangle(level.data.offset.x, level.data.offset.y, level.data.size.x, level.data.size.y);
			EDITOR.overlay.drawLineRect(rect, Color.white);
		}
		
		EDITOR.dirty();
	}

	public function loop()
	{
		if (!selectedChanged) return;
		selectedChanged = false;
		selectionPanel.refresh();
		EDITOR.dirty();
	}

	public function refresh() 
	{
		selected.resize(0);
		selectedChanged = true;
	}

	public function createSelectionPanel()
	{
		return new WorldSelectionPanel(this);
	}

	function afterUndoRedo():Void
	{
		selected = [];
		hovered = [];
	}
}

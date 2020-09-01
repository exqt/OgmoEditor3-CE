package modules.world.tools;

import level.editor.Tool;

class WorldTool extends Tool
{
	public var editor(get, never):WorldEditor;
	function get_editor():WorldEditor return cast EDITOR.worldEditor;

	public var world(get, never):World;
	public function get_world():World return cast EDITOR.worldEditor.world;
}

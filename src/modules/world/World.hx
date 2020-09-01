package modules.world;

import level.data.Level;
import level.data.UndoStack;
import level.editor.Editor;
import rendering.Texture;
import js.Browser;
import util.Popup;
import electron.renderer.Remote;
import js.node.Path;
import io.FileSystem;
import io.Export;
import io.Imports;
import project.data.Project;
import util.Matrix;
import util.Rectangle;
import util.Vector;

class World
{
	public var data:WorldData = new WorldData();
	public var levels:Array<Level> = [];
	public var gridSize:Vector = new Vector(16, 16);

	//Not Exported
	public var path:String = null;
	public var lastSavedData:String = null;
	public var deleted:Bool = false;
	public var unsavedID:Int;
	public var unsavedChanges:Bool = false;
	public var gridVisible:Bool = true;
	public var camera:Matrix = new Matrix();
	public var cameraInv:Matrix = new Matrix();
	public var project:Project;
	public var zoomRect:Rectangle = null;
	public var zoomTimer:Int;
	public var loaded:Bool = false;

	public var safeToClose(get, null):Bool;
	public var displayName(get, null):String;
	public var displayNameNoStar(get, null):String;
	public var displayNameNoExtension(get, null):String;
	public var managerPath(get, null):String;
	public var externallyDeleted(get, null):Bool;
	public var externallyModified(get, null):Bool;
	public var zoom(get, null):Float;

	public static function isUnsavedPath(path:String):Bool
	{
		return path.charAt(0) == "#";
	}

	public function new()
	{
		// stack = new UndoStack(this);
	}

	public function load():World
	{
		for (path in OGMO.project.worldLevelPaths)
		{
			var absolutePath = Path.join(Path.dirname(OGMO.project.path), path);
			var level = Imports.level(absolutePath);
			EDITOR.worldEditor.addLevel(level);
		}

		loaded = true;
		return this;
	}

	public function storeUndoThenLoad(data:Dynamic):Void
	{
		storeFull(false, false, "Reload from File");
		// load(data);
	}

	public function save():Void
	{
		for (level in levels)
		{
			if (level.unsavedChanges) level.doSave();
		}
		Export.project(OGMO.project, OGMO.project.path);
	}

	public function attemptClose(action:Void->Void):Void
	{
	}


	/*
		ACTUAL SAVING
	*/

	public function doSave(refresh:Bool = true):Bool
	{
		return true;
	}

	public function doSaveAs():Bool
	{
		OGMO.resetKeys();
		return true;
	}

	/*
		HELPERS
	*/

	// public function getLayerByExportID(exportID:String): Layer
	// {
	// 	for (layer in layers) if (layer.template.exportID == exportID) return layer;
	// 	return null;
	// }

	/*
		UNDO STATE HELPERS
	*/

	public function store(description:String):Void
	{
		// stack.store(description);
	}

	public function storeFull(freezeRight:Bool, freezeBottom:Bool, description:String):Void
	{
		// stack.storeFull(freezeRight, freezeBottom, description);
	}

	/*
		CAMERA
	*/

	public function moveCamera(x:Float, y:Float):Void
	{
		if (x != 0 || y != 0)
		{
			camera.translate(-x, -y);
			updateCameraInverse();
			EDITOR.dirty();
		}
	}

	public function setZoom(zoom:Float) {
		camera.scale(zoom, zoom);
		updateCameraInverse();
		while (camera.a < 0.01) setZoom(0.01);
		while (camera.a > 32) setZoom(-0.001);
		EDITOR.dirty();

		EDITOR.updateZoomReadout();
		EDITOR.handles.refresh();
	}

	public function zoomCamera(zoom:Float):Void
	{
		camera.scale(1 + .1 * zoom, 1 + .1 * zoom);
		updateCameraInverse();
		EDITOR.dirty();

		EDITOR.updateZoomReadout();
		// EDITOR.handles.refresh();
	}

	public function zoomCameraAt(zoom:Float, x:Float, y:Float):Void
	{
		moveCamera(x, y);
		camera.scale(1 + .1 * zoom, 1 + .1 * zoom);
		moveCamera(-x, -y);
		updateCameraInverse();
		while (camera.a < 0.01) zoomCameraAt(0.01, x, y);
		while (camera.a > 32) zoomCameraAt(-0.001, x, y);
		EDITOR.dirty();

		EDITOR.updateZoomReadout();
		// EDITOR.handles.refresh();
	}

	public function updateCameraInverse():Void
	{
		camera.inverse(cameraInv);
	}

	public function centerCamera(level:Level):Void
	{
		camera.setIdentity();
		var center = level.rect.center;
		moveCamera(center.x, center.y);
		updateCameraInverse();
		EDITOR.dirty();
	}

	/*
		GRID
	*/

	public function levelToGrid(pos: Vector, ?into: Vector):Vector
	{
		if (into == null) into = new Vector();

		into.x = Math.floor((pos.x) / gridSize.x);
		into.y = Math.floor((pos.y) / gridSize.y);

		return into;
	}

	public function gridToLevel(pos: Vector, ?into: Vector):Vector
	{
		if (into == null) into = new Vector();

		into.x = pos.x * gridSize.x;
		into.y = pos.y * gridSize.y;

		return into;
	}

	public function snapToGrid(pos: Vector, ?into: Vector):Vector
	{
		if (into == null) into = new Vector();

		levelToGrid(pos, into);
		gridToLevel(into, into);

		return into;
	}


	public function calculateBoundingBox():Rectangle
	{
		var minX = levels[0].data.offset.x;
		var minY = levels[0].data.offset.y;
		var maxX = minX;
		var maxY = minY;

		for (level in levels)
		{
			minX = Math.min(minX, level.data.offset.x);
			minY = Math.min(minY, level.data.offset.y);
			maxX = Math.max(maxX, level.data.offset.x + level.data.size.x);
			maxY = Math.max(maxY, level.data.offset.y + level.data.size.y);
		}
		
		return new Rectangle(minX, minY, maxX - minX, maxY - minY);
	}

	function get_safeToClose():Bool
	{
		return true; // return !unsavedChanges && stack.undoStates.length == 0 && stack.redoStates.length == 0 && path != null;
	}

	function get_displayName():String
	{
		var str = displayNameNoStar;
		if (unsavedChanges)
			str += "*";

		return str;
	}

	function get_displayNameNoStar():String
	{
		var str:String;
		if (path == null)
			str = "Unsaved Level " + (unsavedID + 1);
		else
			str = Path.basename(path);

		return str;
	}

	function get_displayNameNoExtension():String
	{
		var str:String = displayNameNoStar;
		str = Path.basename(str, Path.extname(str));

		return str;
	}

	function get_managerPath():String
	{
		if (path == null)
			return "#" + unsavedID;
		else
			return path;
	}

	function get_externallyDeleted():Bool
	{
		return path != null && !FileSystem.exists(path);
	}

	function get_externallyModified():Bool
	{
		return path != null && FileSystem.exists(path) && FileSystem.loadString(path) != lastSavedData;
	}

	function get_zoom():Float
	{
		return camera.a;
	}
}
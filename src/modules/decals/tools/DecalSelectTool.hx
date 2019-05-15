package modules.decals.tools;

import modules.entities.tools.EntitySelectTool.SelectModes;

class DecalSelectTool extends DecalTool
{
	public static var inClipboard:Array<Decal> = [];

	public var mode:SelectModes = None;
	public var decals:Array<Decal>;
	public var selecting:Bool = false;
	public var start:Vector = new Vector();
	public var end:Vector = new Vector();
	public var firstChange:Bool = false;

	override public function drawOverlay()
	{
		if (mode == Select && !start.equals(end))
			EDITOR.overlay.drawRect(start.x, start.y, end.x - start.x, end.y - start.y, Color.green.x(0.2));
		else if (mode == Delete && !start.equals(end))
			EDITOR.overlay.drawRect(start.x, start.y, end.x - start.x, end.y - start.y, Color.red.x(0.2));
	}

	override public function deactivated()
	{
		layerEditor.hovered = [];
	}

	override public function onKeyPress(key:Int)
	{
		if (OGMO.ctrl)
		{
			if (key == Keys.A)
			{
				layerEditor.selected = [];
				for (decal in (cast layerEditor.layer:DecalLayer).decals)
					layerEditor.selected.push(decal);
				EDITOR.dirty();
			}
			else if (key == Keys.C)
			{
				DecalSelectTool.inClipboard = [];
				for (decal in layerEditor.selected)
					DecalSelectTool.inClipboard.push(decal);
			}
			if (key == Keys.X)
			{
				DecalSelectTool.inClipboard = [];
				for (decal in layerEditor.selected)
					DecalSelectTool.inClipboard.push(decal);

				EDITOR.level.store("cut decals");
				while (layerEditor.selected.length > 0)
					layerEditor.remove(layerEditor.selected[0]);
				EDITOR.dirty();
			}
			else if (key == Keys.V && DecalSelectTool.inClipboard.length > 0)
			{
				EDITOR.level.store("pasted decals");

				layerEditor.selected = [];
				for (decal in DecalSelectTool.inClipboard)
				{
					var clone = new Decal(decal.position.clone(), decal.path, decal.texture, decal.scale.clone(), decal.rotation);
					(cast layerEditor.layer:DecalLayer).decals.push(clone);
					layerEditor.selected.push(clone);
				}

				EDITOR.dirty();
			}
			else if (key == Keys.D && layerEditor.selected.length > 0)
			{
				EDITOR.level.store("duplicated decals");

				var newSelection:Array<Decal>  = [];
				for (decal in layerEditor.selected)
				{
					var clone = new Decal(decal.position.clone().add(new Vector(32, 32)), decal.path, decal.texture, decal.scale.clone(), decal.rotation);
					(cast layerEditor.layer:DecalLayer).decals.push(clone);
					newSelection.push(clone);
				}

				layerEditor.selected = newSelection;

				EDITOR.dirty();
			}
		}
		else if (key == Keys.H)
		{
			EDITOR.level.store("flip decal h");
			for (decal in layerEditor.selected)
				decal.scale.x = -decal.scale.x;
			EDITOR.dirty();
		}
		else if (key == Keys.V)
		{
			EDITOR.level.store("flip decal v");
			for (decal in layerEditor.selected)
				decal.scale.y = -decal.scale.y;
			EDITOR.dirty();
		}
		else if (key == Keys.Delete || key == Keys.Backspace)
		{
			EDITOR.level.store("delete decals");
			while (layerEditor.selected.length > 0)
				layerEditor.remove(layerEditor.selected[0]);
			EDITOR.dirty();
		}
		else if (key == Keys.B)
		{
			EDITOR.level.store("move decal to back");

			for (decal in layerEditor.selected)
			{
				var index = layer.decals.indexOf(decal);
				if (index >= 0)
				{
					layer.decals.splice(index, 1);
					layer.decals.unshift(decal);
				}
			}
			EDITOR.dirty();
		}
		else if (key == Keys.F)
		{
			EDITOR.level.store("move decal to front");

			for (decal in layerEditor.selected)
			{
				var index = layer.decals.indexOf(decal);
				if (index >= 0)
				{
					layer.decals.splice(index, 1);
					layer.decals.push(decal);
				}
			}
			EDITOR.dirty();
		}
	}

	override public function onMouseDown(pos:Vector)
	{
		layerEditor.hovered = [];
		pos.clone(start);
		pos.clone(end);

		var hit = layer.getFirstAt(pos);
		if (hit.length == 0)
		{
			mode = Select;
		}
		else if (OGMO.shift)
		{
			layerEditor.toggleSelected(hit);
			if (layerEditor.selected.length > 0)
				startMove();
			else
				mode = None;
		}
		else if (OGMO.ctrl)
		{
			layerEditor.toggleSelected(hit);
		}
		else if (layerEditor.selectedContainsAny(hit))
		{
			startMove();
		}
		else
		{
			layerEditor.selected = hit;
			startMove();
		}
		
		EDITOR.dirty();
	}

	public function startMove()
	{
		mode = Move;
		firstChange = false;
		layer.snapToGrid(start, start);
		decals = layerEditor.selected;
	}

	override public function onMouseUp(pos:Vector)
	{
		layerEditor.hovered = [];

		if (mode == Select)
		{
			pos.clone(end);

			var hits:Array<Decal>;
			if (start.equals(end))
				hits = layer.getFirstAt(start);
			else
				hits = layer.getRect(Rectangle.fromPoints(start, end));

			if (OGMO.shift)
				layerEditor.toggleSelected(hits);
			else
				layerEditor.selected = hits;

			mode = None;
			EDITOR.overlayDirty();
		}
		else if (mode == Move)
		{
			mode = None;
			decals = null;
		}
	}

	override public function onMouseMove(pos:Vector)
	{
		if (mode == Select || mode == Delete)
		{
			pos.clone(end);
			EDITOR.dirty();

			var hit = layer.getRect(Rectangle.fromPoints(start, end));
			layerEditor.hovered = hit;
		}
		else if (mode == Move)
		{
			if (!OGMO.ctrl)
				layer.snapToGrid(pos, pos);

			if (!pos.equals(start))
			{
				if (!firstChange)
				{
					firstChange = true;
					EDITOR.level.store("move decals");
				}

				var diff = new Vector(pos.x - start.x, pos.y - start.y);
				for (decal in decals)
				{
					decal.position.x += diff.x;
					decal.position.y += diff.y;
				}

				EDITOR.dirty();
				pos.clone(start);
			}
		}
		else if (mode == None)
		{
			var hit = layer.getAt(pos);
			var isEqual = true;
			var i = 0;
			while (isEqual && hit.length == layerEditor.hovered.length && i < hit.length)
			{
				if (layerEditor.hovered.indexOf(hit[i]) < 0) isEqual = false;
				i++;
			}
				
			if (!isEqual)
			{
				layerEditor.hovered = hit;
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

			var hit: Array<Decal>;
			var click = start.equals(end); 

			if (click)
				hit = layer.getAt(start);
			else
				hit = layer.getRect(Rectangle.fromPoints(start, end));

			if (hit.length > 0)
			{
				EDITOR.level.store("delete decals");
				if (click)
					layerEditor.remove(hit[0]);
				else
					for (decal in hit)
						layerEditor.remove(decal);
			}

			mode = None;
			EDITOR.dirty();
		}
	}

	override public function getIcon():String return "entity-selection";
	override public function getName():String return "Select";
	override public function keyToolCtrl():Int return 3;
	override public function keyToolAlt():Int return 2;
	override public function keyToolShift():Int return 1;

}
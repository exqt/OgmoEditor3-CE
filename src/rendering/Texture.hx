package rendering;

import js.lib.Uint8Array;
import js.html.webgl.RenderingContext;
import js.Browser;
import js.html.ImageElement;
import io.FileSystem;
import util.Vector;

/*
	WARNING!
	We assume that all Textures are created AFTER ALL GL Renderers are created
	Also, all Textures are disposed BEFORE ALL GL Renderers are disposed
*/
class Texture
{
	public var path:String;
	public var image: ImageElement;
	public var textures:Map<String, js.html.webgl.Texture> = new Map();
	public var center:Vector;
	public var width(get, null):Int;
	public var height(get, null):Int;
	public var loaded:Bool = false;

	public static function fromString(data: String): Texture
	{
		var image = Browser.document.createImageElement();
		image.src = haxe.io.Path.normalize(data);
		return new Texture(image);
	}
	
	public static function fromFile(path: String): Texture
	{
		path = haxe.io.Path.normalize(path);
		var img = FileSystem.loadImage(path);
		if (img != null)
		{
			var tex = new Texture(img);
			tex.path = path;
			return tex;
		}
		return null;
	}

	// https://stackoverflow.com/questions/8191083/can-one-easily-create-an-html-image-element-from-a-webgl-texture-object
	public static function fromGLTexture(gl: RenderingContext, texture: js.html.webgl.Texture, width: Int, height: Int)
	{
		// Create a framebuffer backed by the texture
		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(RenderingContext.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(RenderingContext.FRAMEBUFFER, RenderingContext.COLOR_ATTACHMENT0, RenderingContext.TEXTURE_2D, texture, 0);

		// Read the contents of the framebuffer
		var data = new Uint8Array(width * height * 4);
		gl.readPixels(0, 0, width, height, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, data);

		gl.deleteFramebuffer(framebuffer);

		// Create a 2D canvas to store the result
		var canvas = Browser.document.createCanvasElement();
		canvas.width = width;
		canvas.height = height;
		var context = canvas.getContext('2d');

		// Copy the pixels to a 2D canvas
		var imageData = context.createImageData(width, height);
		imageData.data.set(data);
		context.putImageData(imageData, 0, 0);

		var image = Browser.document.createImageElement();
		image.src = canvas.toDataURL(); // haxe.io.Path.normalize(data); 
		return new Texture(image);
	}

	public function new(?image: ImageElement)
	{
		if (image == null) return;
		this.image = image;
		
		if (image.width <= 0) image.onload = function() { load(); };
		else load();
	}

	function load():Void
	{
		center = new Vector(image.width / 2, image.height / 2);
		for (name in GLRenderer.renderers.keys())
		{
			if (GLRenderer.renderers[name].loadTextures)
			{
				var gl = GLRenderer.renderers[name].gl;
				var tex = gl.createTexture();
				
				gl.bindTexture(RenderingContext.TEXTURE_2D, tex);
				gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, image);
				gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.NEAREST);
				gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.NEAREST);
				gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_WRAP_S, RenderingContext.CLAMP_TO_EDGE);
				gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_WRAP_T, RenderingContext.CLAMP_TO_EDGE);
				gl.bindTexture(RenderingContext.TEXTURE_2D, null);
				
				textures[name] = tex;
			}
		}

		loaded = true;
	}
	
	public inline function dispose(): Void
	{
		for (name in textures.keys()) GLRenderer.renderers[name].gl.deleteTexture(textures[name]);
		textures = new Map();
	}
	
	inline function get_width(): Int return image.width;
	
	inline function get_height(): Int return image.height;
}
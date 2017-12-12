package go;

import nme.display.BitmapData;

import nme.display.Sprite;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;

import nme.display.OpenGLView;
import nme.gl.GL;
import nme.gl.GLBuffer;
import nme.gl.GLProgram;
import nme.utils.Float32Array;

import nme.Lib;
import nme.display.DisplayObject;

class PostprocessGroup extends Sprite
{

    public var start:Postprocess;
    public var end:Postprocess;

    public function new(start:Postprocess,end:Postprocess):Void
    {
        super();

        this.start = start;
        this.end = end;
        super.addChild(end);
    }

    override public function addChild(child:DisplayObject):DisplayObject 
    {
        start.addChild( child );
        return child;
    }


    override public function addChildAt(child:DisplayObject, index:Int):DisplayObject 
    { 
        return addChild(child);
    }
}


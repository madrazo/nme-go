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

class Effect extends Sprite
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
        return start.addChild(child);
    }

    override public function addChildAt(child:DisplayObject, index:Int):DisplayObject 
    { 
        return start.addChildAt(child,index);
    }

   override public function removeChild(child:DisplayObject):DisplayObject 
   {
        return start.removeChild(child);
   }

   override public function removeChildAt(index:Int):DisplayObject 
   {
        return start.removeChildAt(index);
   }

   override public function removeChildren(beginIndex:Int = 0, endIndex:Int = 0x7FFFFFFF):Void
   {
        return start.removeChildren(beginIndex, endIndex);
   }
}


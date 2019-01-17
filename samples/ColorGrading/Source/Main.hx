package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;

import nme.Assets;
import nme.Lib;

import go.effects.ColorGrading;

class Main extends Sprite
{
    var startTime:Float;
    var mixNode:ColorGrading;

    public function new ()
    {    
        super ();

        var logo = new Bitmap ( Assets.getBitmapData ("assets/baboon.png") );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;

        var lut = new Bitmap ( Assets.getBitmapData ("assets/lut_default.png") );
        //var lut = new Bitmap ( Assets.getBitmapData ("assets/lut_test.png") );
        lut.x =  0;
        lut.y =  0;

        var scale:Float = 1.0;
        mixNode = new ColorGrading(Std.int(stage.stageWidth), Std.int(stage.stageHeight), scale);
        addChild(mixNode);
        mixNode.addChildren(logo,lut);
    }

}


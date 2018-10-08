package;

import nme.display.Bitmap;
import nme.display.Sprite;

import nme.Assets;
import nme.Lib;
import nme.events.Event;

import go.effects.Blur;


class Main extends Sprite {

    var mBlurNode:Blur;
    var startTime:Float;

    public function new () {
        
        super ();

        //target sizes
        var width = stage.stageWidth;
        var height = stage.stageWidth;
        var scale:Float = 1.0/8.0;  //blur using smaller render targets
        var widthScaled = Std.int(width*scale);
        var heightScaled = Std.int(height*scale);

        var data = Assets.getBitmapData ( "assets/nme.png" ) ;
        var logo = new Bitmap ( data );
        logo.x =  ( stage.stageWidth - logo.width ) / 2;
        logo.y =  ( stage.stageHeight - logo.height ) / 2;

        mBlurNode = new Blur(stage.stageWidth, stage.stageHeight, scale);

        addChild(mBlurNode);
        mBlurNode.addChild(logo);
 
        addEventListener(Event.ENTER_FRAME, OnEnterFrame);

        //show fps
        var fps = new nme.display.FPS();
        addChild(fps);
    }

    function OnEnterFrame(inEvent:Event)
    {
        if(mBlurNode!=null)
        {
            var time = Lib.getTimer () - startTime;
            mBlurNode.setBlurAmount( (Math.sin( time*0.003 )+1.0) /200.0 );
        }
    }
}

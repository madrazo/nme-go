package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;

import nme.Assets;
import nme.Lib;

import go.effects.DualFilterBloom;
import go.effects.PingPongBloom;

class Main extends Sprite
{
    var startTime:Float;
    var mBloomNodeArr:Array<Dynamic>;
    var debugText:TextField;
    var currentEffect:Int;
    var logo:Bitmap;

    public function new ()
    {    
        super ();

        mBloomNodeArr = new Array<Dynamic>();
        var data = Assets.getBitmapData ( "assets/nme.png" ) ;
        logo = new Bitmap ( data );
        logo.x =  ( stage.stageWidth - logo.width ) / 2;
        logo.y =  ( stage.stageHeight - logo.height ) / 2;

        var nPasses = 8;
        var blurTargetScale:Float = 1.0/4.0;
        mBloomNodeArr[0] = new DualFilterBloom(stage.stageWidth, stage.stageHeight, nPasses, 0.5);
        mBloomNodeArr[1] = new PingPongBloom(stage.stageWidth, stage.stageHeight, nPasses, blurTargetScale);

        addChild(mBloomNodeArr[currentEffect]);
        mBloomNodeArr[currentEffect].addChild(logo); //add your scene here

        addEventListener(Event.ENTER_FRAME, OnEnterFrame);

        var fps = new nme.display.FPS();
        addChild(fps);
        debugText = new TextField();
        debugText.text = "Ping pong blur";
        debugText.x = 100;
        debugText.y = 100;
        debugText.background = true;
        debugText.autoSize = TextFieldAutoSize.LEFT;
        addChild(debugText);
        startTime = Lib.getTimer();
    }

    function OnEnterFrame(inEvent:Event)
    {
        if(mBloomNodeArr!=null)
        {
            var time = Lib.getTimer () - startTime;
            if(time>5000.0)
            {
                currentEffect = (currentEffect+1)%2;
                debugText.text = currentEffect == 0 ? "Ping pong blur" : "Dual filter blur";
                addChild(mBloomNodeArr[currentEffect]);
                mBloomNodeArr[currentEffect].addChild(logo); //add your scene here
                startTime = Lib.getTimer();
            }
            mBloomNodeArr[currentEffect].setBlurAmount( (Math.sin( time*0.003 )+1.0) /2.0 );
        }
    }
}


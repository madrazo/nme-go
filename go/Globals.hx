package go;

import nme.display.Sprite;
import nme.Lib;
import haxe.ds.Vector;
import nme.gl.GL;
import nme.events.Event;

class Globals extends Sprite
{
    public static var instance(default, null):Globals = new Globals();
    private var mCurrentTime:Float;
    private var mTimeVal:Vector<Float>;
    private var mMouseVal:Vector<Float>;
    private var mResolutionVal:Vector<Float>;
    private var mW:Int;
    private var mH:Int;

    private function new ()
    {
        super();
        mTimeVal = new Vector<Float>(4);
        mMouseVal = new Vector<Float>(2);
        mResolutionVal = new Vector<Float>(4);
        addEventListener(Event.ENTER_FRAME, OnEnterFrame);
        Lib.current.addChild(this); 
    }

    function OnEnterFrame(inEvent:Event)
    {
        mCurrentTime = Lib.getTimer() / 1000;  
        mTimeVal[0] = mCurrentTime/2.0;
        mTimeVal[1] = mCurrentTime;
        mTimeVal[2] = mCurrentTime*2.0;
        mTimeVal[3] = mCurrentTime*3.0;
        mW = Lib.current.stage.stageWidth;
        mH = Lib.current.stage.stageHeight;
        mMouseVal[0] = Lib.current.stage.mouseX / mW;
        mMouseVal[1] = Lib.current.stage.mouseY / mH;
        mResolutionVal[0] = mW;
        mResolutionVal[1] = mH;
        mResolutionVal[2] = 1.0 + 1.0/mW;
        mResolutionVal[3] = 1.0 + 1.0/mH;   
    }

    private inline function getTimeFromStart( startTimeSec:Float ):Float
    {
        return (mCurrentTime - startTimeSec);
    }

    public function getTimerSec():Float
    {
        return mCurrentTime;
    }

    public function setUniforms(timeUniform:Int, startTime:Float, mouseUniform:Int, resolutionUniform:Int)
    {
        if( timeUniform>=0 )
            GL.uniform4f (timeUniform, mTimeVal[0], mTimeVal[1], mTimeVal[2], mTimeVal[3]);

        if( mouseUniform>=0 )
            GL.uniform2f (mouseUniform, mMouseVal[0], mMouseVal[1]);

        if( resolutionUniform>=0 )
            GL.uniform4f (resolutionUniform, mResolutionVal[0], mResolutionVal[1], mResolutionVal[2], mResolutionVal[3]);
    }
}


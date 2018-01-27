package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.MouseEvent;

import nme.Assets;
import nme.Lib;

import go.Postprocess;
import nme.gl.Utils;


class Main extends Sprite {

    var postprocessCopy:Postprocess;
    var postprocessDrawInAccumBuff:Postprocess;
    var postprocessFadeAccumBuff:Postprocess;
    var mParticle:Bitmap;

    public function new () {
        
        super ();

        var bitmap = new Bitmap (Assets.getBitmapData ("assets/nme.png"));
        bitmap.x = (Lib.current.stage.stageWidth - bitmap.width) / 2;
        bitmap.y = (Lib.current.stage.stageHeight - bitmap.height) / 2;
        addChild(bitmap);

        mParticle = new Bitmap (Assets.getBitmapData ("assets/nme.png"));
        mParticle.scaleX = 0.3;
        mParticle.scaleY = 0.3;

        //Create shaders
        var shaderProgram_fadeAccumBuff =  Utils.createProgram(vs, fs_fadeAccumBuff);
        var shaderProgram_drawInAccumBuff =  Utils.createProgram(vs, fs_mix_drawInAccumBuff);
        var shaderProgram_copy =  Utils.createProgram(vs, fs_copy);

        //Create postprocess nodes
        postprocessFadeAccumBuff = new Postprocess(shaderProgram_fadeAccumBuff);
        postprocessDrawInAccumBuff = new Postprocess(shaderProgram_drawInAccumBuff);
        postprocessCopy = new Postprocess(shaderProgram_copy);
 
        
        var rt0 = postprocessFadeAccumBuff.getTarget();
        var rt1 = postprocessFadeAccumBuff.getSwapTarget();
        postprocessDrawInAccumBuff.setTarget(rt1);
        postprocessDrawInAccumBuff.setSwapTarget(rt0);
        postprocessCopy.setTarget(rt0);
        postprocessCopy.setSwapTarget(rt1);

        postprocessFadeAccumBuff.setClearSlot(0,true,0.0,0.1,0,0,true);
        postprocessDrawInAccumBuff.addChildSlot(0,postprocessFadeAccumBuff);
        postprocessDrawInAccumBuff.addChildSlot(1,mParticle);
        postprocessDrawInAccumBuff.setClearSlot(1,true,0.0,0.0,0,0);
        postprocessCopy.addChildSlot(0,postprocessDrawInAccumBuff);
        addChild(postprocessCopy);

        setParticleFadeAmount( 0.1 );
 
        var fps = new nme.display.FPS();
        addChild(fps);
        addEventListener(Event.ENTER_FRAME, OnEnterFrame);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }

    function onMouseMove(inEvent:MouseEvent)
    {
        mParticle.x = inEvent.stageX - (mParticle.width) / 2;
        mParticle.y = inEvent.stageY - (mParticle.height) / 2;
    }

    function OnEnterFrame(inEvent:Event)
    {    
        postprocessFadeAccumBuff.swapTargets();
        postprocessDrawInAccumBuff.swapTargets();
        postprocessCopy.swapTargets();
    }

    function setParticleFadeAmount(value:Float)
    {
        if(postprocessFadeAccumBuff.params!=null)
            postprocessFadeAccumBuff.params[0] = value;
    }

        public var vs = 
"   attribute vec3 vertexPosition;
    attribute vec2 texPosition;
    uniform mat4 NME_MATRIX_MV;
    uniform mat4 NME_MATRIX_P;
    varying vec2   vTexCoord;
    void main() {            
        vTexCoord = texPosition;
        gl_Position = NME_MATRIX_P * NME_MATRIX_MV * vec4(vertexPosition, 1.0);
    }
";


    public var fs_copy = 
"   varying vec2 vTexCoord;
    uniform sampler2D _RenderTexture0;
    void main() {
        gl_FragColor = texture2D(_RenderTexture0, vTexCoord);
    }  
";


    public var fs_mix_drawInAccumBuff = 
"   varying vec2 vTexCoord;
    uniform sampler2D _RenderTexture0;
    uniform sampler2D _RenderTexture1;

    void main() {
        vec4 accumBuff = texture2D(_RenderTexture0, vTexCoord);  
        vec4 particle = texture2D(_RenderTexture1, vTexCoord); 
        gl_FragColor = max(accumBuff,particle);
    }  
";

        public var fs_fadeAccumBuff = 
"   varying vec2 vTexCoord;

    uniform sampler2D _RenderTexture0; //PrevTexture
    uniform vec4 _Params0;
  
    void main() {   
        float gAmount = _Params0.x;
        vec4 accumBuff = texture2D(_RenderTexture0, vTexCoord); 
        gl_FragColor = max(accumBuff - gAmount, 0.0);
    }  
";

}


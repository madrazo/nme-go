package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.display.DisplayObject;

import nme.Assets;
import nme.Lib;

import go.Postprocess;
import go.ShaderBitmap;
import go.PostprocessGroup;
import nme.gl.GLProgram;

class Main extends Sprite {

    var startTime:Float;
    var postprocessMixNode:Postprocess;

    public function new () {
        
        super ();

        var data = Assets.getBitmapData ("assets/nme.png") ;
        var logo = new Bitmap ( data );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;

        var nPasses = 8;
        var blurTargetScale:Float = 1.0/4.0;
        #if mobile
        nPasses = 4;
        blurTargetScale = 1.0/8.0;
        #end
        var pingpongBlur:PostprocessGroup = setPingPongBlur(nPasses, blurTargetScale);
        addChild(pingpongBlur);
        pingpongBlur.addChild(logo); //add your scene here

        addEventListener(Event.ENTER_FRAME, OnEnterFrame);

        var fps = new nme.display.FPS();
        addChild(fps);
        startTime = Lib.getTimer();
    }

    function OnEnterFrame(inEvent:Event)
    {
        if(postprocessMixNode!=null && postprocessMixNode.params!=null)
        {
            var time = Lib.getTimer () - startTime;
            postprocessMixNode.params[0] = (Math.sin( time*0.003 )+1.0) /2.0;
        }
    }
        
    function setPingPongBlur(nPasses:Int, targetScale:Float):PostprocessGroup
    {
        var w = stage.stageWidth;
        var h = stage.stageHeight;
        var w2:Int = Std.int(w*targetScale);
        var h2:Int = Std.int(h*targetScale);

        var shaderProgram_bright =  nme.gl.Utils.createProgram(vs, fs_bright);
        var shaderProgram_kawase =  nme.gl.Utils.createProgram(vs_kawase, fs_kawase);
        var shaderProgram_mix    =  nme.gl.Utils.createProgram(vs, fs_tone_map);

        var postprocessBright = new Postprocess(shaderProgram_bright,w,h);
        postprocessBright.setClear(true,0.0,0.0,0.0,0.0);

        var postprocessKawasePass:Array<Postprocess> = new Array<Postprocess>();
        setPingPongNode(postprocessKawasePass, shaderProgram_kawase, nPasses, w2, h2);
        for(i in 0...nPasses)
        {
            postprocessKawasePass[i].params[0] = i+0.5;
            postprocessKawasePass[i].setClear(true,0.0,0.0,0.0,0.0);
        }

        postprocessMixNode = new Postprocess(shaderProgram_mix,w,h);
        postprocessMixNode.setClearSlot(0,true,0.0,0.0,0.0,0.0);

        var firstKawasePass = postprocessKawasePass[0];
        var lastKawasePass = postprocessKawasePass[postprocessKawasePass.length-1]; 

        postprocessMixNode.addChildSlot(0,lastKawasePass); //blur image on slot0
        postprocessMixNode.setTarget(postprocessBright.getTarget(),1); //original scene on slot1
        firstKawasePass.addChild(postprocessBright);

        return new PostprocessGroup(postprocessBright,postprocessMixNode);
    }


    function setPingPongNode(postprocessPasses:Array<Postprocess>, shaderProgram:GLProgram, nPasses:Int, w:Int, h:Int)
    {
        var isPingPong = true;
        for(i in 0...nPasses)
            postprocessPasses[i] = new Postprocess(shaderProgram,w,h);
        for(i in 1...nPasses)
            postprocessPasses[i].addChild(postprocessPasses[i-1]);
        if(isPingPong)
            for(i in 2...nPasses)
                postprocessPasses[i].setTarget(postprocessPasses[i%2].getTarget());
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

    public var fs_bright = 
"
    varying vec2 vTexCoord;
    uniform sampler2D _Texture0;
    const vec3 W = vec3(0.299, 0.587, 0.114);

    void main() 
    { 
        vec4 color = texture2D(_Texture0, vTexCoord); 
        float luminance = dot(color.rgb, W);
        vec3 threshold = 1.0-W;
        vec3 one_minus_threshold = W;
        gl_FragColor.rgb = (color.rgb*luminance - threshold)/one_minus_threshold;
        gl_FragColor.a = color.a;
    }  
";

    public var vs_kawase = 
"
    attribute vec3 vertexPosition;
    attribute vec2 texPosition;
    uniform mat4 NME_MATRIX_MV;
    uniform mat4 NME_MATRIX_P;
    uniform vec4 _Params0; //_Params0.x : iteration pixels plus half pixel
    uniform vec4 _ScreenParams; //_ScreenParams.zw : pixel size
    varying vec2 TopLeft;
    varying vec2 TopRight;
    varying vec2 BottomRight;
    varying vec2 BottomLeft;

    void main() 
    {       
        gl_Position = NME_MATRIX_P * NME_MATRIX_MV * vec4(vertexPosition, 1.0);
        vec2 dUV = _ScreenParams.zw * _Params0.x;
        TopLeft     = vec2(texPosition.x - dUV.x, texPosition.y + dUV.y); 
        TopRight    = vec2(texPosition.x + dUV.x, texPosition.y + dUV.y);
        BottomRight = vec2(texPosition.x + dUV.x, texPosition.y - dUV.y);
        BottomLeft  = vec2(texPosition.x - dUV.x, texPosition.y - dUV.y);
    }
";

    public var fs_kawase = 
"
    varying vec2 TopLeft;
    varying vec2 TopRight;
    varying vec2 BottomRight;
    varying vec2 BottomLeft;
    uniform sampler2D _Texture0;   
      
    void main() {  
        vec4 accum = texture2D(_Texture0, TopLeft);
        accum += texture2D(_Texture0, TopRight);
        accum += texture2D(_Texture0, BottomRight);
        accum += texture2D(_Texture0, BottomLeft);
        gl_FragColor =  accum * 0.25;
    }
";

    public var fs_tone_map = 
"   varying vec2 vTexCoord;
    uniform sampler2D _RenderTexture0;
    uniform sampler2D _RenderTexture1;
    uniform vec4 _Params0;  //_Params0.x : control blur amount
    const float exposure = 6.0;

    void main() {
        vec4 original = texture2D(_RenderTexture1, vTexCoord); 
        vec4 blur = texture2D(_RenderTexture0, vTexCoord); 
        gl_FragColor.rgb = mix(original.rgb,blur.rgb,mix(0.0,0.75,_Params0.x))*(exposure/(exposure-(exposure-1.0)*_Params0.x)); 
        gl_FragColor.a = original.a;
    }  
";

}


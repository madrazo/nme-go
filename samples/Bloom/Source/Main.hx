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
        //var bloomNode:PostprocessGroup = setPingPongBloom(nPasses, blurTargetScale);
        var bloomNode:PostprocessGroup = setDualFilterBloom(nPasses, blurTargetScale);
        addChild(bloomNode);
        bloomNode.addChild(logo); //add your scene here

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
        
    function setDualFilterBloom(nPasses:Int, targetScale:Float):PostprocessGroup
    {
        if(nPasses<=2)
            return null;

        var w = stage.stageWidth;
        var h = stage.stageHeight;

        var shaderProgram_bright =  nme.gl.Utils.createProgram(vs, fs_bright);
        var shaderProgram_downfilter =  nme.gl.Utils.createProgram(vs_downfilter, fs_downfilter);
        var shaderProgram_upfilter =  nme.gl.Utils.createProgram(vs_upfilter, fs_upfilter);
        var shaderProgram_mix    =  nme.gl.Utils.createProgram(vs, fs_tone_map);

        var postprocessBright = new Postprocess(shaderProgram_bright,w,h);
        postprocessBright.setClear(true,0.0,0.0,0.0,0.0);

        var postprocessDualFilterPass:Array<Postprocess> = new Array<Postprocess>();
        var nPassesDown = Std.int(nPasses/2);
        setPyramidNode(postprocessDualFilterPass, shaderProgram_downfilter, shaderProgram_upfilter, nPassesDown, w, h);
        for(i in 0...postprocessDualFilterPass.length)
            postprocessDualFilterPass[i].setClear(true,0.0,0.0,0.0,0.0);

        postprocessMixNode = new Postprocess(shaderProgram_mix,w,h);
        postprocessMixNode.setClearSlot(0,true,0.0,0.0,0.0,0.0);

        var firstDualFilterPass = postprocessDualFilterPass[0];
        var lastDualFilterPassPass = postprocessDualFilterPass[postprocessDualFilterPass.length-1]; 

        postprocessMixNode.addChildSlot(0,lastDualFilterPassPass); //blur image on slot0
        postprocessMixNode.setTarget(postprocessBright.getTarget(),1); //original scene on slot1
        firstDualFilterPass.addChild(postprocessBright);

        return new PostprocessGroup(postprocessBright,postprocessMixNode);
    }

    function setPyramidNode(postprocessPasses:Array<Postprocess>, shaderProgramDown:GLProgram, shaderProgramUp:GLProgram, nPassesDown:Int, w:Int, h:Int)
    {
        var targetScale = 0.5;
        var w2:Int = Std.int(w*targetScale);
        var h2:Int = Std.int(h*targetScale);
        for(i in 0...nPassesDown)
        {
            postprocessPasses[i] = new Postprocess(shaderProgramDown,w2,h2);
            postprocessPasses[nPassesDown*2-i] = new Postprocess(shaderProgramUp,w2,h2);
            w2 = Std.int(w2*targetScale);
            h2 = Std.int(h2*targetScale);
        }
        postprocessPasses[nPassesDown] = new Postprocess(shaderProgramUp,w2,h2);

        for(i in 1...postprocessPasses.length)
            postprocessPasses[i].addChild(postprocessPasses[i-1]);
        for(i in 0...nPassesDown)
            postprocessPasses[postprocessPasses.length-i-1].setTarget(postprocessPasses[i].getTarget());
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

    public var vs_upfilter = 
"
    attribute vec3 vertexPosition;
    attribute vec2 texPosition;
    uniform mat4 NME_MATRIX_MV;
    uniform mat4 NME_MATRIX_P;
    uniform vec4 _ScreenParams; //_ScreenParams.zw : pixel size
    varying vec2 TopLeft;
    varying vec2 TopRight;
    varying vec2 BottomRight;
    varying vec2 BottomLeft;
    varying vec2 Top;
    varying vec2 Left;
    varying vec2 Right;
    varying vec2 Bottom;

    void main() 
    {       
        gl_Position = NME_MATRIX_P * NME_MATRIX_MV * vec4(vertexPosition, 1.0);
        vec2 dUV = _ScreenParams.zw;
        vec2 dUV2 = _ScreenParams.zw * 1.5;
        TopLeft     = vec2(texPosition.x - dUV.x, texPosition.y + dUV.y); 
        TopRight    = vec2(texPosition.x + dUV.x, texPosition.y + dUV.y);
        BottomRight = vec2(texPosition.x + dUV.x, texPosition.y - dUV.y);
        BottomLeft  = vec2(texPosition.x - dUV.x, texPosition.y - dUV.y);
        Top     = vec2(texPosition.x, texPosition.y + dUV2.y); 
        Left    = vec2(texPosition.x + dUV2.x, texPosition.y);
        Right   = vec2(texPosition.x - dUV2.x, texPosition.y);
        Bottom  = vec2(texPosition.x, texPosition.y - dUV2.y);
    }
";

    public var vs_downfilter = 
"
    attribute vec3 vertexPosition;
    attribute vec2 texPosition;
    uniform mat4 NME_MATRIX_MV;
    uniform mat4 NME_MATRIX_P;
    uniform vec4 _ScreenParams; //_ScreenParams.zw : pixel size
    varying vec2 TopLeft;
    varying vec2 TopRight;
    varying vec2 BottomRight;
    varying vec2 BottomLeft;
    varying vec2 vTexCoord;

    void main() 
    {       
        gl_Position = NME_MATRIX_P * NME_MATRIX_MV * vec4(vertexPosition, 1.0);
        vec2 dUV = _ScreenParams.zw * 0.5;
        TopLeft     = vec2(texPosition.x - dUV.x, texPosition.y + dUV.y); 
        TopRight    = vec2(texPosition.x + dUV.x, texPosition.y + dUV.y);
        BottomRight = vec2(texPosition.x + dUV.x, texPosition.y - dUV.y);
        BottomLeft  = vec2(texPosition.x - dUV.x, texPosition.y - dUV.y);
        vTexCoord   =  texPosition;
    }
";



    public var fs_downfilter = 
"
    varying vec2 TopLeft;
    varying vec2 TopRight;
    varying vec2 BottomRight;
    varying vec2 BottomLeft;
    varying vec2 vTexCoord;
    uniform sampler2D _Texture0;   
      
    void main() {  
        vec4 accum = texture2D(_Texture0, TopLeft);
        accum += texture2D(_Texture0, TopRight);
        accum += texture2D(_Texture0, BottomRight);
        accum += texture2D(_Texture0, BottomLeft);
        vec4 center = texture2D(_Texture0, BottomLeft);
        gl_FragColor =  accum * 0.125 + center * 0.5;
    }
";
    public var fs_upfilter = 
"
    varying vec2 TopLeft;
    varying vec2 TopRight;
    varying vec2 BottomRight;
    varying vec2 BottomLeft;
    varying vec2 Top;
    varying vec2 Left;
    varying vec2 Right;
    varying vec2 Bottom;

    uniform sampler2D _Texture0;   
      
    void main() {  
        vec4 accum = texture2D(_Texture0, TopLeft);
        accum += texture2D(_Texture0, TopRight);
        accum += texture2D(_Texture0, BottomRight);
        accum += texture2D(_Texture0, BottomLeft);
        vec4 accum2 = texture2D(_Texture0, Top);
        accum2 += texture2D(_Texture0, Left);
        accum2 += texture2D(_Texture0, Right);
        accum2 += texture2D(_Texture0, Bottom);
        gl_FragColor =  accum * 0.1666666 + accum2 * 0.0833333;
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



    function setPingPongBloom(nPasses:Int, targetScale:Float):PostprocessGroup
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


}


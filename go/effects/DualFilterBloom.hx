package go.effects;

import go.Effect;
import go.Postprocess;

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

class DualFilterBloom extends go.Effect
{

    private var mPostprocessMixNode:Postprocess;

    public function new( wx:Int, hx:Int, nPasses:Int = 8 , targetScale:Float = 0.5 ):Void
    {
#if mobile
        wx = Std.int(wx*targetScale);
        hx = Std.int(hx*targetScale);
#end
        var shaderProgram_bright        =  nme.gl.Utils.createProgram(vs, fs_bright);
        var shaderProgram_downfilter    =  nme.gl.Utils.createProgram(vs_downfilter, fs_downfilter);
        var shaderProgram_upfilter      =  nme.gl.Utils.createProgram(vs_upfilter, fs_upfilter);
        var shaderProgram_mix           =  nme.gl.Utils.createProgram(vs, fs_tone_map);

        var postprocessBright = new Postprocess(shaderProgram_bright,wx,hx);
        postprocessBright.setClear(true,0.0,0.0,0.0,0.0);

        var postprocessDualFilterPass:Array<Postprocess> = new Array<Postprocess>();
        var nPassesDown = Std.int(nPasses/2);
        setPyramidNode(postprocessDualFilterPass, shaderProgram_downfilter, shaderProgram_upfilter, nPassesDown, wx, hx, targetScale);
        for(i in 0...postprocessDualFilterPass.length)
            postprocessDualFilterPass[i].setClear(true,0.0,0.0,0.0,0.0);

        mPostprocessMixNode = new Postprocess(shaderProgram_mix,wx,hx);
        mPostprocessMixNode.setClearSlot(0,true,0.0,0.0,0.0,0.0);

        var firstDualFilterPass = postprocessDualFilterPass[0];
        var lastDualFilterPassPass = postprocessDualFilterPass[postprocessDualFilterPass.length-1]; 

        mPostprocessMixNode.addChildSlot(0,lastDualFilterPassPass); //blur image on slot0
        mPostprocessMixNode.setTarget(postprocessBright.getTarget(),1); //original scene on slot1
        firstDualFilterPass.addChild(postprocessBright);

        super(postprocessBright, mPostprocessMixNode);
    }

    private function setPyramidNode(postprocessPasses:Array<Postprocess>, shaderProgramDown:GLProgram, shaderProgramUp:GLProgram, nPassesDown:Int, wx:Int, hx:Int, targetScale:Float)
    {
        var w2:Int = Std.int(wx*targetScale);
        var h2:Int = Std.int(hx*targetScale);
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

    public function setBlurAmount( amount:Float )
    {
        if(mPostprocessMixNode.params!=null)
        {
            mPostprocessMixNode.params[0] = amount;
        }
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
    uniform sampler2D _RenderTexture0;
    const vec3 W = vec3(0.299, 0.587, 0.114);

    void main() 
    { 
        vec4 color = texture2D(_RenderTexture0, vTexCoord); 
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
    uniform sampler2D _RenderTexture0;   
      
    void main() {  
        vec4 accum = texture2D(_RenderTexture0, TopLeft);
        accum += texture2D(_RenderTexture0, TopRight);
        accum += texture2D(_RenderTexture0, BottomRight);
        accum += texture2D(_RenderTexture0, BottomLeft);
        vec4 center = texture2D(_RenderTexture0, BottomLeft);
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

    uniform sampler2D _RenderTexture0;   
      
    void main() {  
        vec4 accum = texture2D(_RenderTexture0, TopLeft);
        accum += texture2D(_RenderTexture0, TopRight);
        accum += texture2D(_RenderTexture0, BottomRight);
        accum += texture2D(_RenderTexture0, BottomLeft);
        vec4 accum2 = texture2D(_RenderTexture0, Top);
        accum2 += texture2D(_RenderTexture0, Left);
        accum2 += texture2D(_RenderTexture0, Right);
        accum2 += texture2D(_RenderTexture0, Bottom);
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


}
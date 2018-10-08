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

class PingPongBloom extends go.Effect
{
    private var mPostprocessMixNode:Postprocess;

    public function new( wx:Int, hx:Int, nPasses:Int = 8 , targetScale:Float = 0.5 ):Void
    {
#if mobile
        wx = Std.int( wx*targetScale );
        hx = Std.int( hx*targetScale );
#end
        var shaderProgram_bright =  nme.gl.Utils.createProgram( vs, fs_bright );
        var shaderProgram_kawase =  nme.gl.Utils.createProgram( vs_kawase, fs_kawase );
        var shaderProgram_mix    =  nme.gl.Utils.createProgram( vs, fs_tone_map );

        var postprocessBright = new Postprocess( shaderProgram_bright, wx, hx );
        postprocessBright.setClear( true, 0.0, 0.0, 0.0, 0.0);

        var postprocessKawasePass:Array<Postprocess> = new Array<Postprocess>();
        setPingPongNode( postprocessKawasePass, shaderProgram_kawase, nPasses, wx, hx );
        for( i in 0...nPasses )
        {
            postprocessKawasePass[i].params[ 0 ] = i + 0.5;
            postprocessKawasePass[i].setClear( true, 0.0, 0.0, 0.0, 0.0 );
        }

        mPostprocessMixNode = new Postprocess( shaderProgram_mix, wx, hx);
        mPostprocessMixNode.setClearSlot( 0, true, 0.0, 0.0, 0.0, 0.0);

        var firstKawasePass = postprocessKawasePass[ 0 ];
        var lastKawasePass = postprocessKawasePass[ postprocessKawasePass.length-1 ]; 

        mPostprocessMixNode.addChildSlot(0, lastKawasePass); //blur image on slot0
        mPostprocessMixNode.setTarget( postprocessBright.getTarget(),1); //original scene on slot1
        firstKawasePass.addChild( postprocessBright );

        super( postprocessBright, mPostprocessMixNode );
    }

    function setPingPongNode(postprocessPasses:Array<Postprocess>, shaderProgram:GLProgram, nPasses:Int, wx:Int, hx:Int)
    {
        var isPingPong = true;
        for(i in 0...nPasses)
            postprocessPasses[i] = new Postprocess(shaderProgram,wx,hx);
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
    uniform sampler2D _RenderTexture0;   
      
    void main() {  
        vec4 accum = texture2D(_RenderTexture0, TopLeft);
        accum += texture2D(_RenderTexture0, TopRight);
        accum += texture2D(_RenderTexture0, BottomRight);
        accum += texture2D(_RenderTexture0, BottomLeft);
        gl_FragColor =  accum * 0.25;
    }
";

    public var fs_tone_map = 
"
    varying vec2 vTexCoord;
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

    public function setBlurAmount( amount:Float )
    {
        if(mPostprocessMixNode.params!=null)
        {
            mPostprocessMixNode.params[0] = amount;
        }
    }
}
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

class Blur extends go.Effect
{
    private var postprocessVBlur:Postprocess;
    private var postprocessHBlur:Postprocess;

    public function new( wx:Int, hx:Int, targetScale:Float = 0.5 ):Void
    {
#if mobile
        wx = Std.int( wx*targetScale );
        hx = Std.int( hx*targetScale );
#end
        //shaders and postprocess nodes
        var shaderProgram_vblur =  nme.gl.Utils.createProgram(vs, fs_vblur);
        var shaderProgram_hblur =  nme.gl.Utils.createProgram(vs, fs_hblur);
        postprocessVBlur = new Postprocess(shaderProgram_vblur, null, wx, hx);
        postprocessHBlur = new Postprocess(shaderProgram_hblur, null, wx, hx);
        postprocessVBlur.setClear(true,0.0,1,1,1);
        postprocessHBlur.setClear(true,0.0,1,1,1);
        postprocessHBlur.addChild(postprocessVBlur);
        super( postprocessVBlur, postprocessHBlur );
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

        public var fs_vblur = 
"   varying vec2 vTexCoord;

    uniform sampler2D _RenderTexture0; 
    uniform vec4 _Params0;  //_Params0.x : control blur amount
  
    void main() {  
        vec4 sum = vec4(0.0);
        vec2 tc = vTexCoord;
        float blur = _Params0.x; //0.005;//radius/resolution; 
        
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y - 4.0*blur)) * 0.05;
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y - 3.0*blur)) * 0.09;
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y - 2.0*blur)) * 0.12;
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y - 1.0*blur)) * 0.15;
        
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y)) * 0.16;
        
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y + 1.0*blur)) * 0.15;
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y + 2.0*blur)) * 0.12;
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y + 3.0*blur)) * 0.09;
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y + 4.0*blur)) * 0.05;

        gl_FragColor = sum;
    }  
";

        public var fs_hblur = 
"   varying vec2 vTexCoord;

    uniform sampler2D _RenderTexture0; 
    uniform vec4 _Params0;  //_Params0.x : control blur amount

    void main() {  
        vec4 sum = vec4(0.0);
        vec2 tc = vTexCoord;
        float blur = _Params0.x; //0.005;//radius/resolution; 
        
        sum += texture2D(_RenderTexture0, vec2(tc.x - 4.0*blur, tc.y)) * 0.05;
        sum += texture2D(_RenderTexture0, vec2(tc.x - 3.0*blur, tc.y)) * 0.09;
        sum += texture2D(_RenderTexture0, vec2(tc.x - 2.0*blur, tc.y)) * 0.12;
        sum += texture2D(_RenderTexture0, vec2(tc.x - 1.0*blur, tc.y)) * 0.15;
        
        sum += texture2D(_RenderTexture0, vec2(tc.x, tc.y)) * 0.16;
        
        sum += texture2D(_RenderTexture0, vec2(tc.x + 1.0*blur, tc.y)) * 0.15;
        sum += texture2D(_RenderTexture0, vec2(tc.x + 2.0*blur, tc.y)) * 0.12;
        sum += texture2D(_RenderTexture0, vec2(tc.x + 3.0*blur, tc.y)) * 0.09;
        sum += texture2D(_RenderTexture0, vec2(tc.x + 4.0*blur, tc.y)) * 0.05;

        gl_FragColor = sum;
    }  
";


    public function setBlurAmount( amount:Float )
    {
        if(postprocessVBlur.params!=null && postprocessVBlur.params!=null)
        {
            postprocessVBlur.params[0] = amount;
            postprocessHBlur.params[0] = amount;
        }
    }
}
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

class Mix extends go.Effect
{
    private var postprocessMixNode:Postprocess;

    public function new( wx:Int, hx:Int, targetScale:Float = 0.5 ):Void
    {
#if mobile
        wx = Std.int( wx*targetScale );
        hx = Std.int( hx*targetScale );
#end
        var shaderProgram_mix =  nme.gl.Utils.createProgram(vs, fs_mix);
        postprocessMixNode = new Postprocess(shaderProgram_mix, null, wx, hx);

        super( postprocessMixNode, postprocessMixNode );
    }

    public function addChildren( s0:DisplayObject, s1:DisplayObject)
    {
        postprocessMixNode.addChildSlot(0,s0); //same as addChild
        postprocessMixNode.addChildSlot(1,s1);        
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

    //Pixel shader with two render textures
    public var fs_mix = 
"   varying vec2 vTexCoord;

    uniform sampler2D _RenderTexture0;
    uniform sampler2D _RenderTexture1;
    uniform vec4 _Params0; //could use (sin( _Time.y*0.01 )+1.0) /2.0 
  
    void main() {
        // Set the output color of our current pixel  
        vec4 c1 = texture2D(_RenderTexture0, vTexCoord).rgba;  
        vec4 c2 = texture2D(_RenderTexture1, vTexCoord).rgba;  
        gl_FragColor = mix(c1,c2,_Params0.x);
    }  
";


    public function setAmount( amount:Float )
    {
        if( postprocessMixNode.params!=null )
        {
            //access with _Param0.x in shader
            postprocessMixNode.params[0] = amount;
        }
    }
}
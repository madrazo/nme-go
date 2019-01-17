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

class ColorGrading extends go.Effect
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

        postprocessMixNode.params[0] = 4.0*16.0/wx;
        postprocessMixNode.params[1] = 4.0*16.0/hx;

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
    uniform vec4 _Params0;

    #define float2 vec2
    #define float3 vec3
    #define float4 vec4
    #define frac fract
    #define trunc floor
    #define lerp mix

    vec2 transformPixel(vec2 inCoord)
    {
        vec2 index = inCoord * vec2(_Params0.x,_Params0.y);
        index.y = 1.0-index.y;
        return index;
    }

    void main() {
        // Set the output color of our current pixel  
        vec4 baseTexture = texture2D(_RenderTexture0, vTexCoord).rgba;  

#if 0
        vec2 index = baseTexture.rg * vec2(_Params0.x,_Params0.y);
        index.y = 1.0-index.y;
        vec4 c2 = texture2D(_RenderTexture1,index).rgba; 
        if(index.x<=_Params0.x)
        {
        //    c2.r = 1.0;
        //    c2.a = 1.0;
        }
        gl_FragColor = c2;
#endif





        float size = 16.0;
        float sizeRoot = 4.0;
        
        float width = (sizeRoot * size);
        float height = ((size / sizeRoot) * size);
        float2 wh = float2(width, height);

        float red = baseTexture.r * (size - 1.0);
        float redinterpol = frac(red);

        float green = baseTexture.g * (size - 1.0);
        float greeninterpol = frac(green);

        float blue = baseTexture.b * (size - 1.0);
        float blueinterpol = frac(blue);

        //Blue base value

        float row = trunc(blue / sizeRoot);
        float col = trunc(mod(blue,sizeRoot));

        float2 blueBaseTable = float2(trunc(col * size), trunc(row * size));

        float4 b0r1g0;
        float4 b0r0g1;
        float4 b0r1g1;
        float4 b1r0g0;
        float4 b1r1g0;
        float4 b1r0g1;
        float4 b1r1g1;

        //We need to read 8 values (like in a 3d LUT) and interpolate between them.
        //This cannot be done with default hardware filtering so I am doing it manually.
        //Note that we must not interpolate when on the borders of tables!

        //Red 0 and 1, Green 0

        float4 b0r0g0 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red, blueBaseTable.y + green) / wh));

        if (red < size - 1.0)
            b0r1g0 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red + 1.0, blueBaseTable.y + green) / wh));
        else
            b0r1g0 = b0r0g0;

        // Green 1

        if (green < size - 1.0)
        {
            //Red 0 and 1

            b0r0g1 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red, blueBaseTable.y + green + 1.0) / wh));

            if (red < size - 1.0)
                b0r1g1 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red + 1.0, blueBaseTable.y + green + 1.0) / wh));
            else
                b0r1g1 = b0r0g1;
        }
        else
        {
            b0r0g1 = b0r0g0;
            b0r1g1 = b0r0g1;
        }

        if (blue < size - 1.0)
        {
            blue += 1.0;
            row = trunc(blue / sizeRoot);
            col = trunc(mod(blue,sizeRoot));

            blueBaseTable = float2(trunc(col * size), trunc(row * size));

            b1r0g0 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red, blueBaseTable.y + green) / wh));

            if (red < size - 1.0)
                b1r1g0 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red + 1.0, blueBaseTable.y + green) / wh));
            else
                b1r1g0 = b0r0g0;

            // Green 1

            if (green < size - 1.0)
            {
                //Red 0 and 1

                b1r0g1 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red, blueBaseTable.y + green + 1.0) / wh));

                if (red < size - 1.0)
                    b1r1g1 = texture2D(_RenderTexture1, transformPixel(float2(blueBaseTable.x + red + 1.0, blueBaseTable.y + green + 1.0) / wh));
                else
                    b1r1g1 = b0r0g1;
            }
            else
            {
                b1r0g1 = b0r0g0;
                b1r1g1 = b0r0g1;
            }
        }
        else
        {
            b1r0g0 = b0r0g0;
            b1r1g0 = b0r1g0;
            b1r0g1 = b0r0g0;
            b1r1g1 = b0r1g1;
        }

        float4 result = lerp(lerp(b0r0g0, b0r1g0, redinterpol), lerp(b0r0g1, b0r1g1, redinterpol), greeninterpol);
        float4 result2 = lerp(lerp(b1r0g0, b1r1g0, redinterpol), lerp(b1r0g1, b1r1g1, redinterpol), greeninterpol);

        result = lerp(result, result2, blueinterpol);


        gl_FragColor = result;
    }  
";


    public function setAmount( amount:Float )
    {
        if( postprocessMixNode.params!=null )
        {
            //access with _Param0.x in shader
            //postprocessMixNode.params[0] = amount;
        }
    }
}
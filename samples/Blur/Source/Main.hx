package;

import nme.display.Bitmap;
import nme.display.Sprite;

import nme.Assets;
import nme.Lib;

import go.Postprocess;

class Main extends Sprite {

    public function new () {
        
        super ();

        //target sizes
        var width = stage.stageWidth;
        var height = stage.stageWidth;
        var scale:Float = 1.0/8.0;  //blur using smaller render targets
        var widthScaled = Std.int(width*scale);
        var heightScaled = Std.int(height*scale);

        //shaders and postprocess nodes
        var shaderProgram_vblur =  nme.gl.Utils.createProgram(vs, fs_vblur);
        var shaderProgram_hblur =  nme.gl.Utils.createProgram(vs, fs_hblur);
        var postprocessVBlur:Postprocess = new Postprocess(shaderProgram_vblur, null, widthScaled,heightScaled);
        var postprocessHBlur:Postprocess = new Postprocess(shaderProgram_hblur, null, widthScaled,heightScaled);
        postprocessVBlur.setClear(true,0.0,1,1,1);
        postprocessHBlur.setClear(true,0.0,1,1,1);

        //Displaying a bitmap
        var bitmap = new Bitmap (Assets.getBitmapData ("assets/nme.png"));
        bitmap.x = (Lib.current.stage.stageWidth - bitmap.width) / 2;
        bitmap.y = (Lib.current.stage.stageHeight - bitmap.height) / 2;

        postprocessVBlur.addChild(bitmap);
        postprocessHBlur.addChild(postprocessVBlur);
        addChild(postprocessHBlur);

        //show fps
        var fps = new nme.display.FPS();
        addChild(fps);
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
  
    void main() {  
        vec4 sum = vec4(0.0);
        vec2 tc = vTexCoord;
        float blur = 0.005;//radius/resolution; 
        
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

    void main() {  
        vec4 sum = vec4(0.0);
        vec2 tc = vTexCoord;
        float blur = 0.005;//radius/resolution; 
        
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

}

package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;

import nme.Assets;

import go.ShaderBitmap;
import go.Postprocess;

class Main extends Sprite {

    public function new () {
        
        super ();

        //Displaying a Bitmap
        var logo = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;

        var logo2 = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo2.x =  (stage.stageWidth - logo.width) / 2 + 100;
        logo2.y =  (stage.stageHeight - logo.height) / 2;


        //Objects that use OGLView
        {


            var shaderProgram_mix =  nme.gl.Utils.createProgram(vs, fs_mix);
            var postprocessNode:Postprocess = new Postprocess(shaderProgram_mix/*, null, 800,600*/);

            var shaderProgram_copy =  nme.gl.Utils.createProgram(vs, fs_copy);
            var postprocessNodeC1:Postprocess = new Postprocess(shaderProgram_copy/*, null, 800,600*/);

            var shaderProgram_copy2 =  nme.gl.Utils.createProgram(vs, fs_copy2);
            var postprocessNodeC2:Postprocess = new Postprocess(shaderProgram_copy2/*, null, 800,600*/);

            postprocessNodeC1.drawOffline(true);
            postprocessNodeC2.drawOffline(true);
            postprocessNode.inTargetInput(0,postprocessNodeC1);
            postprocessNode.inTargetInput(1,postprocessNodeC2);

            addChild(postprocessNode);
            postprocessNode.addChild(postprocessNodeC1);
//            postprocessNode.addChild(postprocessNodeC2);
            postprocessNodeC1.addChild(logo);
//            postprocessNodeC2.addChild(logo2);



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

        public var fs_copy = 
"   varying vec2 vTexCoord;
    uniform sampler2D _RenderTexture0;
    void main() {
        gl_FragColor = texture2D(_RenderTexture0, vTexCoord).rgba;  
    }  
";
        public var fs_copy2 = 
"   varying vec2 vTexCoord;
    uniform sampler2D _RenderTexture0;
    void main() {
        gl_FragColor = texture2D(_RenderTexture0, vTexCoord).bgra;  
    }  
";


//Pixel shader with two render textures
        public var fs_mix = 
"   varying vec2 vTexCoord;

    uniform sampler2D _RenderTexture0;
    uniform sampler2D _RenderTexture1;
    //uniform float _Time;
    //uniform vec2 _Mouse;
    //uniform vec4 _ScreenParams;
  
    void main() {
        // Set the output color of our current pixel  
        vec4 c1 = texture2D(_RenderTexture0, vTexCoord).rgba;  
        vec4 c2 = texture2D(_RenderTexture1, vTexCoord).rgba;  
        gl_FragColor = mix(c1,c2,0.5);
//gl_FragColor = c1;
    }  
";
}

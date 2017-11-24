package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;

import nme.Assets;
import nme.Lib;

import go.ShaderBitmap;
import go.Postprocess;

class Main extends Sprite {

    var startTime:Float;
    var postprocessMixNode:Postprocess;

    public function new () {
        
        super ();

        //Displaying a Bitmap
        var logo = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;

        var logo2 = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo2.x =  (stage.stageWidth - logo.width) / 2 + 100;
        logo2.y =  (stage.stageHeight - logo.height) / 2;

        //Postprocess node with 2 render textures shader (needs addChildSlot 0 and 1)
        var shaderProgram_mix =  nme.gl.Utils.createProgram(vs, fs_mix);
        postprocessMixNode = new Postprocess(shaderProgram_mix);

        var shaderProgram_copy =  nme.gl.Utils.createProgram(vs, fs_copy);
        var postprocessChildExampleNode:Postprocess = new Postprocess(shaderProgram_copy);
        //postprocessChildExampleNode.setClear(true,0.0,0.0,0.0,0.0);
        postprocessChildExampleNode.addChild(logo2);

        postprocessMixNode.addChildSlot(0,postprocessChildExampleNode); //same as addChild
        postprocessMixNode.addChildSlot(1,logo);
        //postprocessMixNode.setClearSlot(0,true,0.0,0.0,0.0,0.0);
        //postprocessMixNode.setClearSlot(1,true,0.0,0.0,0.0,0.0);
        addChild(postprocessMixNode);

        startTime = Lib.getTimer();
        addEventListener(Event.ENTER_FRAME, OnEnterFrame);
    }

    function OnEnterFrame(inEvent:Event)
    {          
        var time = Lib.getTimer() - startTime;
        //access with _Param0.x in shader
        postprocessMixNode.params[0] = (Math.sin( time*0.01 )+1.0) /2.0;
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
        gl_FragColor = texture2D(_RenderTexture0, vTexCoord).brga;  
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
    uniform vec4 _Params0;
  
    void main() {
        // Set the output color of our current pixel  
        vec4 c1 = texture2D(_RenderTexture0, vTexCoord).rgba;  
        vec4 c2 = texture2D(_RenderTexture1, vTexCoord).rgba;  
        gl_FragColor = mix(c1,c2,_Params0.x);
    }  
";

}

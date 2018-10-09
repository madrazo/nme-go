package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;

import nme.Assets;
import nme.Lib;

import go.effects.Mix;
import go.Postprocess;

class Main extends Sprite {

    var startTime:Float;
    var mixNode:Mix;

    public function new () {
        
        super ();

        //Displaying a Bitmap
        var logo = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;

        var logo2 = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo2.x =  (stage.stageWidth - logo.width) / 2 + 100;
        logo2.y =  (stage.stageHeight - logo.height) / 2;


        var shaderProgram_copy =  nme.gl.Utils.createProgram(vs, fs_copy);
        var postprocessChildExampleNode:Postprocess = new Postprocess(shaderProgram_copy);
        postprocessChildExampleNode.addChild(logo2);

        var scale:Float = 1.0;
        mixNode = new Mix(Std.int(stage.stageWidth), Std.int(stage.stageHeight), scale);
        addChild(mixNode);
        //mixNode.addChildren(logo,logo2);
        mixNode.addChildren( postprocessChildExampleNode, logo);

        startTime = Lib.getTimer();
        addEventListener(Event.ENTER_FRAME, OnEnterFrame);
    }

    function OnEnterFrame(inEvent:Event)
    {          
        var time = Lib.getTimer() - startTime;
        mixNode.setAmount( (Math.sin( time*0.01 )+1.0) /2.0 );
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

}

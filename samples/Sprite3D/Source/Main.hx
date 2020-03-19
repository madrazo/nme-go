package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.Assets;
import nme.Lib;
import go.Sprite3D;

class Main extends Sprite {

    public function new () {
        
        super ();
	
        //Displaying a Bitmap
        var logo = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;
        addChild(logo);

	    var s = new go.Sprite3D("assets", "Box.gltf");
        addChild(s);

        // Dark blue background: For NME, use "opaqueBackground" instead of "clearColor"
        //GL.clearColor(0.0, 0.0, 0.4, 0.0);
        //nme.Lib.stage.opaqueBackground = 0x000066;

    }
}

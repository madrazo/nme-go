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

	    //var box = new go.Sprite3D("assets", "Box.gltf");
        //addChild(box);

	    var boxTextured = new go.Sprite3D("assets", "BoxTextured.gltf");
        addChild(boxTextured);

        //nme.Lib.stage.opaqueBackground = 0x000066;

    }
}

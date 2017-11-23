# nme-go
NME Graphics Objects: node-based programable GPU effects on top of GLView

Initially developed by Bamtang Games

ShaderBitmap: Similar to a "Bitmap" that has a shader program and 0, 1, 2 or more "BitmapData" (textures) as inputs

Postprocess: It's a postprocess node. Its children are drawn on a render target and a shader is applied. You can have "ShaderPostprocess" nodes as parent/children of other "ShaderPostprocess" nodes. In comparisson, "ShaderBitmap" only applies a shader and doesn't generate a render target.

Work in progress. Getting some ideas from http://gratin.gforge.inria.fr/

Installation:
After install Haxe and NME. Download Git or Zip. Use command "haxelib dev nme-go your_path/nme-go" 

Usage:
Add "<haxelib name="nme-go" />" to your index.nmml / index.xml
Add to your code
import go.ShaderBitmap; 
import go.Postprocess;

See the samples:
open command prompt in your_path/nme-go/samples/DisplayingAShaderBitmap and run command "nme"

Note:
elephant1_*.png textures by Cocos2d-x under MIT License
NME logo by NME under MIT License

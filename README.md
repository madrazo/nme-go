# nme-go
NME Graphics Objects: node-based programable GPU effects on top of GLView
 >Initially developed by Bamtang Games

## Motivation: 

There are [some AS3 API for Shaders](https://help.adobe.com/en_US/as3/dev/WS065D20A7-F721-4a0c-8581-4D188E6FD606.html) however they are limited and hard to implement. With `nme-go` you just make a new object and use addChild.

## Graphic Objects: 

### ShaderBitmap: 

Similar to a `Bitmap` that has a shader program and 0, 1, 2 or more `BitmapData` (textures) as inputs

### Postprocess: 

It's a postprocess node. Its children are drawn on a render target and a shader is applied. You can have `Postprocess` nodes as parent/children of other `Postprocess` nodes. In comparisson, "ShaderBitmap" only applies a shader and doesn't generate a render target.

Work in progress. Getting some ideas from [Gratin](http://gratin.gforge.inria.fr/)

## Installation:
After install Haxe and NME. Download Git or Zip. Use command ```haxelib dev nme-go your_path/nme-go``` 

## Usage:
Add ```<haxelib name="nme-go" />``` to your `_.nmml_` / `_.xml_` configuration file
Add to your code
```
import go.ShaderBitmap; 
import go.Postprocess;
```

## Run the sample:
open command prompt in `nme-go/samples/DisplayingAShaderBitmap` and run command ```nme```, ```nme android```, ```nme winrt```, etc.

 >Notes:
 >elephant1_*.png textures by Cocos2d-x under MIT License
 >NME logo by NME under MIT License

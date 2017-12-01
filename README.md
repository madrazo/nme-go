# nme-go
NME Graphics Objects: node-based programable GPU effects on top of GLView (tested on [NME](https://github.com/haxenme/nme), may work in [OpenFL](http://www.openfl.org/))
 >Initially developed by [Bamtang Games](http://www.bamtang.com)

## Motivation: 

There are [some AS3 API for Shaders](https://help.adobe.com/en_US/as3/dev/WS065D20A7-F721-4a0c-8581-4D188E6FD606.html) however they are limited and hard to implement. With `nme-go` you just make a new object and use addChild.

## Graphics Objects: 

### ShaderBitmap: 

Similar to a `Bitmap` that has a shader program and 0, 1, 2 or more `BitmapData` (textures) as inputs

### Postprocess: 

It's a postprocess node. Its children are drawn on a render target and a shader is applied. You can have `Postprocess` nodes as parent/children of other `Postprocess` nodes. In comparisson, `ShaderBitmap` only applies a shader and doesn't generate a render target.

## Installation:
After installing Haxe and NME, download by Git or Zip. Use command: ```haxelib dev nme-go your_path/nme-go``` 

## Usage:
Add ```<haxelib name="nme-go" />``` to your `_.nmml_` / `_.xml_` configuration file.

Add to your code:
```
import go.ShaderBitmap; 
import go.Postprocess;
```

## Run the sample:
Open command prompt in `nme-go/samples/DisplayingAShaderBitmap` and run command ```nme```, ```nme android```, ```nme winrt```, etc.

## Writting shaders:

### Vertex shader base
```
attribute vec3 vertexPosition;
attribute vec2 texPosition;
uniform mat4 NME_MATRIX_MV;
uniform mat4 NME_MATRIX_P;
varying vec2   vTexCoord;
void main() {            
    vTexCoord = texPosition;
    gl_Position = NME_MATRIX_P * NME_MATRIX_MV * vec4(vertexPosition, 1.0);
}
```

## Pixel shader base

```
varying vec2 vTexCoord;
uniform sampler2D _Texture0;         //optional: can be none or multiple textures (_Texture1, _Texture2...)
uniform vec4 _Time;                  //optional: seconds [t/20, t, t*2, t*3]
uniform vec2 _Mouse;                 //optional: xy mouse position in range 0 to 1
uniform vec4 _ScreenParams;          //optional: xy are render target width/heights in pixels. z is 1.0 + 1.0/width and w is 1.0 + 1.0/height.
uniform vec4 _Params0;               //optional: custom parameter values (optional: _Params1, _Params2...)
uniform sampler2D _RenderTexture0;   //optional (Postprocess): input textures from render targets 

void main() {  
    gl_FragColor = texture2D(_Texture0, vTexCoord).rgba;
}  
```

 >Notes:

 >Work in progress. Getting some ideas from [Designing Gratin A GPU-Tailored Node-Based System](http://jcgt.org/published/0004/04/03/)

 >elephant1_*.png textures by Cocos2d-x under MIT License

 >NME logo by NME under MIT License

# nme-go
NME Graphics Objects: node-based programable GPU effects on top of GLView (tested on [NME](https://github.com/haxenme/nme), may work in [OpenFL](http://www.openfl.org/))
 >Initially developed by [Bamtang Games](http://www.bamtang.com)

## Motivation: 

There are [some AS3 API for Shaders](https://help.adobe.com/en_US/as3/dev/WS065D20A7-F721-4a0c-8581-4D188E6FD606.html) however they are limited and hard to implement. With `nme-go` you just make a new object and use addChild.

## Graphics Objects: 

### ShaderBitmap: 

Similar to a `Bitmap` that has a shader program and 0, 1, 2 or more `BitmapData` (textures) as inputs

### Postprocess: 

It's a postprocess node. Its children are drawn on a render target and a shader is applied. You can have `Postprocess` nodes as parent/children of other `Postprocess` nodes. In comparisson, `ShaderBitmap` only applies a shader and doesn't generate a render target. You can use addChildrenSlot or setTarget with a slot>0 to have more than one RenderTexture as inputs, e.g. to implement a "mix" shader (currently 2 slots implemented).

### PostprocessGroup: 

Use a single node that require various Postprocess objects to add/remove Child from the stage easily. Indicate the start (last child) and end (parent) Postprocess when making a new PostprocessGroup object.

### RenderTarget: 

RenderTargets are created automatically for each Postprocess object. You can set/get Targets manually to reuse RenderTargets or set as input on a Postprocess slot (from another non-children Postprocess output).

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
uniform vec4 _ScreenParams;          //optional: render target [width, height, 1.0/width, 1.0/height] in pixels.
uniform vec4 _Params0;               //optional: custom four parameter values (optional: _Params1, _Params2...)
uniform sampler2D _RenderTexture0;   //optional (Postprocess): input textures from render targets 

void main() {  
    gl_FragColor = texture2D(_Texture0, vTexCoord).rgba;
}  
```

* Notes, links and references:
  - Work in progress. 
  - elephant1_*.png textures by Cocos2d-x under MIT License
  - NME logo by NME under MIT License
  - Bjorge 2015, [Bandwidth-Efficient Rendering](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-26-50/siggraph2015_2D00_mmg_2D00_marius_2D00_slides.pdf)
  - Kawase 2003, [Frame Buffer Post-processing Effects in DOUBLE-S.T.E.A.L (Wreckless)](http://www.daionet.gr.jp/~masa/archives/GDC2003_DSTEAL.ppt)
  - Oat 2004, [Real-Time 3D Scene Post-processing](http://www.chrisoat.com/papers/Oat-ScenePostprocessing.pdf)
  - Vergne 2015, [Designing Gratin A GPU-Tailored Node-Based System](http://jcgt.org/published/0004/04/03/)

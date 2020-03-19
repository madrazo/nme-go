package go;

import gltf.GLTF;
import gltf.types.Buffer;
import nme.utils.ByteArray;
import nme.gl.Utils;
import nme.utils.Int16Array;    
import nme.geom.Vector3D;

import nme.display.BitmapData;

import nme.display.Sprite;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;

import nme.display.OpenGLView;
import nme.gl.GL;
import nme.gl.GLBuffer;
import nme.gl.GLProgram;
import nme.utils.Float32Array;


import go.nme.gl.GL3Utils;

import nme.Lib;
import nme.Assets;
import go.Controls;

class Sprite3D extends Sprite
{
    private var shaderProgram:GLProgram;
    private var posAttribute:Int;
    private var normalAttribute:Int;
    private var vertexBuffer:GLBuffer;
    private var normalBuffer:GLBuffer;
    private var elementBuffer:GLBuffer;
    private var view:OpenGLView;
    
    private var m_vertices:Array<Float>;
    private var m_verticesArray:Float32Array;
    
    private var h:Int;
    private var w:Int;
    
    private var m_positionX:Float;
    private var m_positionY:Float;
    private var m_projectionMatrix:Matrix3D;
    private var m_modelViewMatrix:Matrix3D;
    
    //private var m_projectionMatrixUniform:Int;
    //private var m_modelViewMatrixUniform:Int;
    
    private var positionAttribute:Int;
    private var timeUniform:Int;
    private var mouseUniform:Int;
    private var resolutionUniform:Int;

    private var paramsUniform:Array<Int>;
    public  var params:Array<Float>;
    
    private var startTime:Float;
    
    private var m_windowWidth:Float;
    private var m_windowHeight:Float;

    //textures
    private var m_textures:Array<BitmapData>;
    private var m_textureName:Array<Int>;
    private var m_normalName:Int;
    private var m_texAttribute:Int;
    private var m_texcoord:Array<Float>;
    private var m_texBuffer:GLBuffer;
    private var m_texArray:Float32Array;
    static private inline var s_samplerName:String = "_Texture";
    static private inline var s_paramsName:String = "_Params";
    
    private var nIndices:Int;

       private  var matrixID:Dynamic;
       private  var viewMatrixID:Dynamic;
       private  var modelMatrixID:Dynamic;
       private  var lightID:Dynamic;



    private var m_controls:Controls;


    public function new(sourceDir:String, sourceFile:String, w:Int=-1, h:Int=-1):Void
    {
        super(); 

        this.x = x;
        this.y = y;
        if(w>8 && h>8)
        {
            this.w = w;
            this.h = h;
        }
        else
        {
            this.w = Lib.current.stage.stageWidth;
            this.h = Lib.current.stage.stageHeight;
        }
	
	var jsonData:String = Assets.getText (sourceDir + "/" + sourceFile);
        var jsonParse = GLTF.parse(jsonData);

        var binaryBuffers:Array<haxe.io.Bytes> = [];
        for(buf in jsonParse.buffers)
        {
            var binaryBuffer:ByteArray = Assets.getBytes (sourceDir + "/" + buf.uri);
            binaryBuffers.push(binaryBuffer);
        }

        var box = GLTF.load(jsonParse, binaryBuffers);

	
	
	
	
        m_positionY = -1;
        
	//this.shaderProgram = shaderProgram;
	// Create and compile our GLSL program from the shaders
        if (!GL3Utils.isGLES3compat())
        {
            vertShader = GL3Utils.vsToGLES2(vertShader);
            fragShader = GL3Utils.fsToGLES2(fragShader);
        }
        shaderProgram = Utils.createProgram(vertShader,fragShader);

#if 0
//todo
        if(textures!=null)
        {
            m_textures = textures;
            this.w = textures[0].width;
            this.h = textures[0].height;
            
            m_texBuffer = GL.createBuffer ();    
            m_texcoord = [
                    1.0, 1.0,
                    0.0, 1.0,
                    1.0, 0.0,
                    0.0, 0.0
                ];
            m_texArray = new Float32Array (m_texcoord);
            GL.bindBuffer (GL.ARRAY_BUFFER, m_texBuffer);    
            GL.bufferData (GL.ARRAY_BUFFER, m_texArray , GL.STATIC_DRAW);

            m_texAttribute = GL.getAttribLocation (shaderProgram, "texPosition");

            m_textureName = new Array<Int>();
            for(i in 0...m_textures.length)
                m_textureName[i] = GL.getUniformLocation(shaderProgram, s_samplerName+i); 
        }
#end            
        //vertexAttribute = GL.getAttribLocation (shaderProgram, "vertexPosition");
        posAttribute = 0;
        //var uvAttrib = 2;
        normalAttribute = 1;
        if (!GL3Utils.isGLES3compat())
        {
            posAttribute = GL.getAttribLocation(shaderProgram, "vertexPosition_modelspace");
            //uvAttrib = GL.getAttribLocation(shaderProgram, "vertexUV");
            normalAttribute = GL.getAttribLocation(shaderProgram, "vertexNormal_modelspace");
        }

        // Get a handle for our "LightPosition" uniform
        //GL.useProgram(shaderProgram);
        lightID  = GL.getUniformLocation(shaderProgram, "LightPosition_worldspace");


    
        //m_projectionMatrixUniform = GL.getUniformLocation (shadershaderProgramram, "NME_MATRIX_P");
        //m_modelViewMatrixUniform = GL.getUniformLocation (shaderProgram, "NME_MATRIX_MV");

        // Get a handle for our "MVP" uniform
         matrixID = GL.getUniformLocation(shaderProgram, "MVP");
         viewMatrixID  = GL.getUniformLocation(shaderProgram, "V");
         modelMatrixID  = GL.getUniformLocation(shaderProgram, "M");


        #if 0
        timeUniform = GL.getUniformLocation (shaderProgram, "_Time");
        resolutionUniform = GL.getUniformLocation (shaderProgram, "_ScreenParams");
        mouseUniform = GL.getUniformLocation (shaderProgram, "_Mouse");

        var paramsUniform0:Int = GL.getUniformLocation (shaderProgram, s_paramsName+0);
        if (paramsUniform0>0)
        {
            paramsUniform = [];
            params = [];
            paramsUniform[0] = paramsUniform0;
            var i:Int=1;
            while ( i<paramsUniform.length && paramsUniform[i]>0 ) 
            {
                paramsUniform[i] = GL.getUniformLocation (shaderProgram, s_paramsName+i);
                i++;
            }
        }
        
        resetTime();
        vertexBuffer = GL.createBuffer ();  
        #end

        var indexed_vertices:haxe.ds.Vector<Float> = box.meshes[0].primitives[0].getFloatAttributeValues("POSITION");
        //var indexed_uvs:Array<Float> = [];
        var indexed_normals:haxe.ds.Vector<Float> = box.meshes[0].primitives[0].getFloatAttributeValues("NORMAL");
        var indices:haxe.ds.Vector<Int> = box.meshes[0].primitives[0].getIndexValues();



        nIndices = indices.length;
        vertexBuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(indexed_vertices), GL.STATIC_DRAW);
        
        normalBuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, normalBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(indexed_normals), GL.STATIC_DRAW);
        // Generate a buffer for the indices
        elementBuffer = GL.createBuffer();
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, elementBuffer);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Int16Array(indices), GL.STATIC_DRAW);







        view = new OpenGLView ();
          
        view.render = renderView;
        addChild(view);
        
        //rebuildMatrix();

        m_controls = new Controls(); //todo
    }
    
    public function resetTime()
    {
        startTime = Globals.instance.getTimerSec();
    }
/*
    public function setSize( w:Int, h:Int ):Void 
    {
        this.w = w;
        this.h = h;
        rebuildMatrix();
    }
    
    private function rebuildMatrix():Void 
    {
        var x2 = w;
        var x1 = 0;
        var y2 = h;
        var y1 = 0;
        m_vertices = [
            x2, y2, 10,
            x1, y2, 10,
            x2, y1, 10,
            x1, y1, 10
            
        ];
        m_verticesArray = new Float32Array (m_vertices);
        GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);    
        GL.bufferData (GL.ARRAY_BUFFER, m_verticesArray , GL.STATIC_DRAW);
    }
*/
    private inline function bindTextures():Void 
    {
        if(m_textures!=null)
        {
            GL.bindBuffer (GL.ARRAY_BUFFER, m_texBuffer);    
            GL.enableVertexAttribArray (m_texAttribute);
            GL.vertexAttribPointer (m_texAttribute, 2, GL.FLOAT, false, 0, 0);
            for( i in 0...m_textures.length )
            {
                if( m_textureName[i]>0 )
                { 
                    GL.activeTexture(GL.TEXTURE0+(i));
                    GL.bindBitmapDataTexture( m_textures[i] );
                    GL.uniform1i( m_textureName[i], i );
                }
            }
        }
    }
    
    private inline function unbindTextures():Void 
    {
        GL.bindTexture( GL.TEXTURE_2D, null );
        //if(m_textures!=null)
        //{
        //    GL.activeTexture(GL.TEXTURE1);
        //    GL.bindTexture(GL.TEXTURE_2D, null);
        //    GL.activeTexture(GL.TEXTURE0);  
        //    GL.bindTexture(GL.TEXTURE_2D, null);
        //    GL.disableVertexAttribArray(m_texAttribute);
        //}
    }
    
    function renderView (rect:Rectangle):Void
    {


        // Enable depth test
        GL.enable(GL.DEPTH_TEST);
        // Accept fragment if it closer to the camera than the former one
//        GL.depthFunc(GL.LESS); 

        // Cull triangles which normal is not towards the camera
        //GL.enable(GL.CULL_FACE);



        GL.useProgram (shaderProgram);



        var lightPos = new nme.geom.Vector3D(4,4,4);
        GL.uniform3f(lightID, lightPos.x, lightPos.y, lightPos.z);

        
        #if 0
        Globals.instance.setUniforms(timeUniform, startTime, mouseUniform, resolutionUniform);
        if( paramsUniform!= null )
        {
            var i:Int = 0;
            var j:Int = 0;
            while(j<paramsUniform.length && paramsUniform[j]>0)
            {
                GL.uniform4f (paramsUniform[j], params[i++], params[i++], params[i++], params[i++]);
                j++;
            }
        }
        #end

        if( m_positionX != x || m_positionY != y )
        {
            m_positionX = x;
            m_positionY = y;
            m_modelViewMatrix = Matrix3D.create2D (m_positionX, m_positionY, 1, 0);
        }
	

        if( rect.width!=m_windowWidth || rect.height!=m_windowHeight ) {
            m_windowWidth  = rect.width;
            m_windowHeight = rect.height ;
            m_projectionMatrix = Matrix3D.createOrtho (0, rect.width, rect.height, 0, 1000, -1000);
        }


        //GL.uniformMatrix3D (m_projectionMatrixUniform, false, m_projectionMatrix);
        //GL.uniformMatrix3D (m_modelViewMatrixUniform, false, m_modelViewMatrix);
        //GL.uniformMatrix3D (matrixID, false, m_modelViewMatrix);
        //GL.uniformMatrix3D (viewMatrixID, false, m_modelViewMatrix);
        //GL.uniformMatrix3D (modelMatrixID, false, m_modelViewMatrix);

        

        // Compute the MVP matrix from keyboard and mouse input 
        m_controls.computeMatricesFromInputs();
        var model = new Matrix3D();
        var view = m_controls.getViewMatrix();
        var projection = m_controls.getProjectionMatrix();
        var mvp = model;
        mvp.append(view);
        mvp.append(projection);
        GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));
        GL.uniformMatrix4fv(modelMatrixID, false, Float32Array.fromMatrix(model));
        GL.uniformMatrix4fv(viewMatrixID, false, Float32Array.fromMatrix(view));
    
        //bindTextures();
        GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
        GL.enableVertexAttribArray (posAttribute);
        GL.vertexAttribPointer (posAttribute, 3, GL.FLOAT, false, 0, 0);

        
        //normal
        GL.bindBuffer (GL.ARRAY_BUFFER, normalBuffer);
        GL.enableVertexAttribArray (normalAttribute);
        GL.vertexAttribPointer (normalAttribute, 3, GL.FLOAT, false, 0, 0);
        
        //GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);

        // Index buffer
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, elementBuffer);
        // Draw the triangles !
        GL.drawElements(GL.TRIANGLES, nIndices, GL.UNSIGNED_SHORT, 0);

        GL.bindBuffer (GL.ELEMENT_ARRAY_BUFFER, null);  


        //unbindTextures();
  

        GL.useProgram (null);
        GL.disableVertexAttribArray(posAttribute);

        GL.disableVertexAttribArray(normalAttribute);


        //NME: Disable if enabled per frame
        GL.disable(GL.DEPTH_TEST);
        
    }



       private var fragShader:String = 
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Interpolated values from the vertex shaders
//in vec2 UV;
in vec3 Position_worldspace;
in vec3 Normal_cameraspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;

// Ouput data
out vec4 color;

// Values that stay constant for the whole mesh.
//uniform sampler2D myTextureSampler;
uniform mat4 MV;
uniform vec3 LightPosition_worldspace;

void main(){
    // Light emission properties
    // You probably want to put them as uniforms
    vec3 LightColor = vec3(1,1,1);
    float LightPower = 50.0;
    
    // Material properties
    //vec3 MaterialDiffuseColor = texture( myTextureSampler, UV ).rgb;
    vec3 MaterialDiffuseColor = vec3(0.1,0.1,0.1);
    vec3 MaterialAmbientColor = vec3(0.1,0.1,0.1) * MaterialDiffuseColor;
    vec3 MaterialSpecularColor = vec3(0.3,0.3,0.3);

    // Distance to the light
    float distance = length( LightPosition_worldspace - Position_worldspace );

    // Normal of the computed fragment, in camera space
    vec3 n = normalize( Normal_cameraspace );
    // Direction of the light (from the fragment to the light)
    vec3 l = normalize( LightDirection_cameraspace );
    // Cosine of the angle between the normal and the light direction, 
    // clamped above 0
    //  - light is at the vertical of the triangle -> 1
    //  - light is perpendicular to the triangle -> 0
    //  - light is behind the triangle -> 0
    float cosTheta = clamp( dot( n,l ), 0.0 , 1.0);
    
    // Eye vector (towards the camera)
    vec3 E = normalize(EyeDirection_cameraspace);
    // Direction in which the triangle reflects the light
    vec3 R = reflect(-l,n);
    // Cosine of the angle between the Eye vector and the Reflect vector,
    // clamped to 0
    //  - Looking into the reflection -> 1
    //  - Looking elsewhere -> < 1
    float cosAlpha = clamp( dot( E,R ), 0.0, 1.0);
    
    vec3 col =
        // Ambient : simulates indirect lighting
        MaterialAmbientColor +
        // Diffuse : color of the object
        MaterialDiffuseColor * LightColor * LightPower * cosTheta / (distance*distance) +
        // Specular : reflective highlight, like a mirror
        MaterialSpecularColor * LightColor * LightPower * pow(cosAlpha,5.0) / (distance*distance);
        
    color = vec4(col,1.0); 
}
";


      private var vertShader:String =
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Input vertex data, different for all executions of this shader.
layout(location = 0) in vec3 vertexPosition_modelspace;
//layout(location = 2) in vec2 vertexUV;
layout(location = 1) in  vec3 vertexNormal_modelspace;

// Output data ; will be interpolated for each fragment.
//out vec2 UV;
out vec3 Position_worldspace;
out vec3 Normal_cameraspace;
out vec3 EyeDirection_cameraspace;
out vec3 LightDirection_cameraspace;

// Values that stay constant for the whole mesh.
uniform mat4 MVP;
uniform mat4 V;
uniform mat4 M;
uniform vec3 LightPosition_worldspace;

void main(){
  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1.0);

    // Position of the vertex, in worldspace : M * position
    Position_worldspace = (M * vec4(vertexPosition_modelspace,1)).xyz;
    
    // Vector that goes from the vertex to the camera, in camera space.
    // In camera space, the camera is at the origin (0,0,0).
    vec3 vertexPosition_cameraspace = ( V * M * vec4(vertexPosition_modelspace,1)).xyz;
    EyeDirection_cameraspace = vec3(0,0,0) - vertexPosition_cameraspace;

    // Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
    vec3 LightPosition_cameraspace = ( V * vec4(LightPosition_worldspace,1)).xyz;
    LightDirection_cameraspace = LightPosition_cameraspace + EyeDirection_cameraspace;
    
    // Normal of the the vertex, in camera space
    Normal_cameraspace = ( V * M * vec4(vertexNormal_modelspace,0)).xyz; // Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.
    

  // The color of each vertex will be interpolated
  // to produce the color of each fragment
  //UV = vertexUV;
}
";


}


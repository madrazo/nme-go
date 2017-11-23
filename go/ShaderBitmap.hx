package go;

import nme.display.BitmapData;

import nme.display.Sprite;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;

import nme.display.OpenGLView;
import nme.gl.GL;
import nme.gl.GLBuffer;
import nme.gl.GLProgram;
import nme.utils.Float32Array;

import nme.Lib;

class ShaderBitmap extends Sprite
{
    private var shaderProgram:GLProgram;
    private var vertexAttribute:Int;
    private var vertexBuffer:GLBuffer;
    private var view:OpenGLView;
    
    private var m_vertices:Array<Float>;
    private var m_verticesArray:Float32Array;
    
    private var h:Int;
    private var w:Int;
    
    private var m_positionX:Float;
    private var m_positionY:Float;
    private var m_projectionMatrix:Matrix3D;
    private var m_modelViewMatrix:Matrix3D;
    
    private var m_projectionMatrixUniform:Int;
    private var m_modelViewMatrixUniform:Int;
    
    private var positionAttribute:Int;
    private var timeUniform:Int;
    private var mouseUniform:Int;
    private var resolutionUniform:Int;

    private var paramsUniform:Array<Int>;
    public  var params:Array<Float>;
    
    private var startTime:Int;
    
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

    public function new(shaderProgram:GLProgram, textures:Array<BitmapData>=null, w:Int=-1, h:Int=-1):Void
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
        m_positionY = -1;
        this.shaderProgram = shaderProgram;

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
            
        vertexAttribute = GL.getAttribLocation (shaderProgram, "vertexPosition");
    
        m_projectionMatrixUniform = GL.getUniformLocation (shaderProgram, "NME_MATRIX_P");
        m_modelViewMatrixUniform = GL.getUniformLocation (shaderProgram, "NME_MATRIX_MV");
        
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
        
        startTime = Lib.getTimer ();
        vertexBuffer = GL.createBuffer ();  
        
        view = new OpenGLView ();
          
        view.render = renderView;
        addChild(view);
        
        rebuildMatrix();
    }
    
    public function setSize( w:Int, h:Int ):Void 
    {
        this.w = w;
        this.h = h;
        rebuildMatrix();
    }
    
    private function rebuildMatrix():Void 
    {
        var x2 = w / 2;
        var x1 = -x2;
        var y2 = h / 2;
        var y1 = -y2;
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
                    GL.activeTexture(GL.TEXTURE0+i);
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
        GL.useProgram (shaderProgram);
        
        GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
        GL.enableVertexAttribArray (vertexAttribute);
        GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);
        
        if( timeUniform>=0 )
        {
            var time = Lib.getTimer () - startTime;
            GL.uniform1f (timeUniform, time / 1000);
        }

        if( mouseUniform>=0 )
            GL.uniform2f (mouseUniform, (Lib.current.stage.mouseX / Lib.current.stage.stageWidth) * 2 - 1, (Lib.current.stage.mouseY / Lib.current.stage.stageHeight) * 2 - 1);

        if( resolutionUniform>=0 )
            GL.uniform4f (resolutionUniform, rect.width, rect.height, 1.0 + 1.0/rect.width, 1.0 + 1.0/rect.height);
        
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
        GL.uniformMatrix3D (m_projectionMatrixUniform, false, m_projectionMatrix);
        GL.uniformMatrix3D (m_modelViewMatrixUniform, false, m_modelViewMatrix);
    
        bindTextures();
        
        GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);

        unbindTextures();
    
        GL.bindBuffer (GL.ARRAY_BUFFER, null);    
        GL.useProgram (null);
        GL.disableVertexAttribArray(vertexAttribute);
        
    }
}


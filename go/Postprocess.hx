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
import nme.display.DisplayObject;

class Postprocess extends Sprite
{
    private var shaderProgram:GLProgram;
    private var vertexAttribute:Int;
    private var vertexBuffer:GLBuffer;
    private var viewStart:OpenGLView;
    private var viewEnd:OpenGLView;
    
    private var m_vertices:Array<Float>;
    private var m_verticesArray:Float32Array;
    
    private var h:Int;
    private var w:Int;
    private var h2:Float;
    private var w2:Float;
    
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
    
    private var startTime:Float;
    
    private var m_windowWidth:Float;
    private var m_windowHeight:Float;

    //textures
    private var m_textures:Array<BitmapData>;
    private var m_textureName:Array<Int>;
    private var m_renderTextureName:Array<Int>;
    private var m_normalName:Int;
    private var m_texAttribute:Int;
    private var m_texcoord:Array<Float>;
    private var m_texBuffer:GLBuffer;
    private var m_texArray:Float32Array;

    private var m_clear:Bool;
    private var m_clear_r:Float;
    private var m_clear_g:Float;
    private var m_clear_b:Float;
    private var m_clear_alpha:Float;
    private var mDrawOffline:Bool;

    public var mInTargets:Array<PostprocessIN>;

    static private inline var s_samplerName:String = "_Texture";
    static private inline var s_renderSamplerName:String = "_RenderTexture";
    static private inline var s_paramsName:String = "_Params";

    public function new(shaderProgram:GLProgram, textures:Array<BitmapData>=null, w:Int=-1, h:Int=-1):Void
    {
        super(); 
        mInTargets = [];
        mInTargets[0] = new PostprocessIN();
        super.addChild(mInTargets[0]);

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


        if(textures!=null && textures.length>0)
        {
            m_textures = textures;
            m_textureName = new Array<Int>();
            for(i in 0...m_textures.length)
                m_textureName[i] = GL.getUniformLocation (shaderProgram, s_samplerName+i); 
        }
	
        m_renderTextureName = new Array<Int>();
        m_renderTextureName[0] = GL.getUniformLocation (shaderProgram, s_renderSamplerName+"0"); 
        
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
        
        resetTime();
        vertexBuffer = GL.createBuffer ();
        
        viewEnd = new OpenGLView ();            
        viewEnd.render = renderViewEnd;

        viewStart = new OpenGLView ();           
        viewStart.render = renderviewStart;

        super.addChild(viewStart);
        super.addChild(viewEnd);

        rebuildMatrix();
	
	w2 = 1.0 + 1.0/w;
	h2 = 1.0 + 1.0/h;

        //test: fill with red color
        //setClear( true, 0.5, 1.0, 0, 0 );
    }

    public function resetTime()
    {
        startTime = Globals.instance.getTimerSec();
    }

    public function addChildSlot( slot:Int, child:DisplayObject )
    {
        if(mInTargets[slot]==null)
        {
            mInTargets[slot] = new PostprocessIN();
            super.addChild(mInTargets[slot]);
        }
        mInTargets[slot].addChild( child );
    }

    public function addChildAt_Slot( slot:Int, child:DisplayObject, index:Int )
    {
        if(mInTargets[slot]==null)
        {
            mInTargets[slot] = new PostprocessIN();
            super.addChild(mInTargets[slot]);
        }
        mInTargets[slot].addChildAt( child, index );
    }
    
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
        var y2 = 0;
        var y1 = h;
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
        GL.bindBuffer (GL.ARRAY_BUFFER, m_texBuffer);    
        GL.enableVertexAttribArray (m_texAttribute);
        GL.vertexAttribPointer (m_texAttribute, 2, GL.FLOAT, false, 0, 0);

        var overrideTexture:nme.gl.GLTexture =  mInTargets[0].getTexture();
        m_renderTextureName[0] = GL.getUniformLocation(shaderProgram, s_renderSamplerName+"0"); 
        GL.activeTexture(GL.TEXTURE0);
        if( overrideTexture!=null )
        {
            GL.bindTexture( GL.TEXTURE_2D, overrideTexture );
        }
        else
        {
            trace("error");
        }
        GL.uniform1i( m_renderTextureName[0], 0 );

        if( mInTargets[1]!=null )
        {
            m_renderTextureName[1] = GL.getUniformLocation(shaderProgram, s_renderSamplerName+"1"); 
            if( m_renderTextureName[1]>0 )
            {
                GL.activeTexture(GL.TEXTURE0+1);
                GL.bindTexture( GL.TEXTURE_2D, mInTargets[1].getTexture() );
                GL.uniform1i( m_renderTextureName[1], 1 );
            }
            else
            {
                trace("error");
            }
        }

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
    }
    
    function renderviewStart (rect:Rectangle):Void
    {
        #if 0 //desktop
        // Fix if app is resized.
        if ( appscale > 1.0 )
            GL.viewport(0,0,APP_WIDTH,APP_HEIGHT);
        #end
    }

    public function setClear( value:Bool, alpha:Float = 0.0, r:Float = 0.0, g:Float = 0.0, b:Float = 0.0, slot:Int=0 )
    {
        setClearSlot( 0, value, alpha, r, g , b);
    }

    public function setClearSlot( slot:Int, value:Bool, alpha:Float = 0.0, r:Float = 0.0, g:Float = 0.0, b:Float = 0.0)
    {
        if(mInTargets[slot]==null)
        {
            trace("error. needs SetChildSlot first");
            return;
        }
        mInTargets[slot].setClear( value, alpha, r, g , b);
    }

    private function renderViewEnd (rect:Rectangle):Void
    {       
        #if 0 //desktop
        if ( appscale > 1.0 )
            GL.viewport( 0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageWidthHeight);
        #end

        GL.useProgram (shaderProgram);
        
        GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
        GL.enableVertexAttribArray (vertexAttribute);
        GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);
        
        Globals.instance.setUniforms(timeUniform, startTime, mouseUniform, -1);
 
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

        if( w!=m_windowWidth || h!=m_windowHeight ) {
            m_windowWidth  = w;
            m_windowHeight = h ;
	    w2 = 1.0 + 1.0/m_windowWidth;
	    h2 = 1.0 + 1.0/m_windowHeight;
            m_projectionMatrix = Matrix3D.createOrtho (0, w, h, 0, 1000, -1000);
        }
        if( resolutionUniform>=0 )
            GL.uniform4f (resolutionUniform, w, h, w2, h2);
        GL.uniformMatrix3D (m_projectionMatrixUniform, false, m_projectionMatrix);
        GL.uniformMatrix3D (m_modelViewMatrixUniform, false, m_modelViewMatrix);
    
        bindTextures();
        
        GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);

        unbindTextures();
    
        GL.bindBuffer (GL.ARRAY_BUFFER, null);    
        GL.useProgram (null);
        GL.disableVertexAttribArray(vertexAttribute);

    }

    override public function addChild(child:DisplayObject):DisplayObject 
    {
        addChildSlot(0, child); 
        return child;
    }

    override public function addChildAt(child:DisplayObject, index:Int):DisplayObject 
    {
        addChildAt_Slot(0, child, index); 
        return child;
    }
}


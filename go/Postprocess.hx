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
    private var m_shaderProgram:GLProgram;
    private var m_vertexAttribute:Int;
    private var m_vertexBuffer:GLBuffer;
    private var m_viewStart:OpenGLView;
    private var m_viewEnd:OpenGLView;
    
    private var m_vertices:Array<Float>;
    private var m_verticesArray:Float32Array;
    
    private var m_h:Int;
    private var m_w:Int;
    private var m_invH:Float;
    private var m_invW:Float;
    
    private var m_positionX:Float;
    private var m_positionY:Float;
    private var m_projectionMatrix:Matrix3D;
    private var m_modelViewMatrix:Matrix3D;
    
    private var m_projectionMatrixUniform:Int;
    private var m_modelViewMatrixUniform:Int;
    
    private var m_timeUniform:Int;
    private var m_mouseUniform:Int;
    private var m_resolutionUniform:Int;

    private var m_textureUniformArr:Array<Int>;
    private var m_rendertextureUniformArr:Array<Int>;
    private var m_paramsUniformArr:Array<Int>;
    private var m_swapTextureName:Int;

    private var m_startTime:Float;
    
    private var m_windowWidth:Float;
    private var m_windowHeight:Float;

    private var m_textures:Array<BitmapData>;
    public  var params:Array<Float>;


    private var m_texAttribute:Int;
    private var m_texcoord:Array<Float>;
    private var m_texBuffer:GLBuffer;
    private var m_texArray:Float32Array;

    private var m_clear:Bool;
    private var m_clear_r:Float;
    private var m_clear_g:Float;
    private var m_clear_b:Float;
    private var m_clear_alpha:Float;

    public var m_InTargetSlots:Array<PostprocessIN>;

    static private inline var s_samplerName:String       = "_Texture";
    static private inline var s_renderSamplerName:String = "_RenderTexture";
    static private inline var s_swapSamplerName:String   = "_SwapTexture";
    static private inline var s_paramsName:String        = "_Params";

    public function new(shaderProgram:GLProgram, textures:Array<BitmapData>=null, w:Int=-1, h:Int=-1):Void
    {
        super(); 
        m_InTargetSlots = [];
        m_InTargetSlots[0] = new PostprocessIN(w,h);
        super.addChild(m_InTargetSlots[0]);

        this.x = x;
        this.y = y;
        if(w>8 && h>8)
        {
            m_w = w;
            m_h = h;
        }
        else
        {
            m_w = Lib.current.stage.stageWidth;
            m_h = Lib.current.stage.stageHeight;
        }
        m_invW = 1.0/m_w;
        m_invH = 1.0/m_h;
        m_positionY = -1;
        m_shaderProgram = shaderProgram;


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

        m_texAttribute = GL.getAttribLocation (m_shaderProgram, "texPosition");
        m_textures = textures;

        var testLocation:Int;

        testLocation = GL.getUniformLocation(m_shaderProgram, s_samplerName+0);
        if(testLocation>0) 
            fillUniformLocationArray(m_textureUniformArr = [], s_samplerName, testLocation);
    
        testLocation = GL.getUniformLocation(m_shaderProgram, s_renderSamplerName+0);
        if(testLocation>0) 
            fillUniformLocationArray(m_rendertextureUniformArr = [], s_renderSamplerName, testLocation);

        testLocation = GL.getUniformLocation(m_shaderProgram, s_paramsName+0);
        if(testLocation>0) 
        {
            params = [];
                fillUniformLocationArray(m_paramsUniformArr = [], s_paramsName, testLocation);
        }

        m_swapTextureName = GL.getUniformLocation(m_shaderProgram, s_swapSamplerName);
        m_vertexAttribute = GL.getAttribLocation (m_shaderProgram, "vertexPosition");

        m_projectionMatrixUniform = GL.getUniformLocation (m_shaderProgram, "NME_MATRIX_P");
        m_modelViewMatrixUniform = GL.getUniformLocation (m_shaderProgram, "NME_MATRIX_MV");
        
        m_timeUniform = GL.getUniformLocation (m_shaderProgram, "_Time");
        m_resolutionUniform = GL.getUniformLocation (m_shaderProgram, "_ScreenParams");
        m_mouseUniform = GL.getUniformLocation (m_shaderProgram, "_Mouse");

        resetTime();
        m_vertexBuffer = GL.createBuffer();
        
        m_viewEnd = new OpenGLView();            
        m_viewEnd.render = renderViewEnd;

        m_viewStart = new OpenGLView();           
        m_viewStart.render = renderViewStart;

        super.addChild(m_viewStart);
        super.addChild(m_viewEnd);

        rebuildMatrix();

        //test: fill with red color
        //setClear( true, 0.5, 1.0, 0, 0 );
    }

    private inline function fillUniformLocationArray(locationArray:Array<Int>, uniformBaseName:String, testLocation:Int)
    {
        var i:Int = 0;
        while(testLocation>0)
        {
            locationArray[i++] = testLocation;
            testLocation = GL.getUniformLocation(m_shaderProgram, uniformBaseName+i);
        }
    }

    public function resetTime()
    {
        m_startTime = Globals.instance.getTimerSec();
    }

    private function initSlot( slot:Int )
    {
        if(m_InTargetSlots[slot]==null)
        {
            m_InTargetSlots[slot] = new PostprocessIN(m_w,m_h);
            super.addChild(m_InTargetSlots[slot]);
        }
    }

    public function setTarget( target:go.RenderTarget, slot:Int = 0 )
    {
        initSlot( slot );
        m_InTargetSlots[slot].setTarget( target );
    }

    public function setSwapTarget( target:go.RenderTarget, slot:Int = 0 )
    {
        initSlot( slot );
        m_InTargetSlots[slot].setSwapTarget( target );
    }

    public function swapTargets(slot:Int = 0)
    {
        initSlot( slot );
        m_InTargetSlots[slot].swapTargets();
    }

    public function getTarget( slot:Int = 0 ):go.RenderTarget
    {
        initSlot( slot );
        return m_InTargetSlots[slot].getTarget();
    }

    public function getSwapTarget( slot:Int = 0 ):go.RenderTarget
    {
        initSlot( slot );
        return m_InTargetSlots[slot].getSwapTarget();
    }

#if debug
    public function setSlotName( name:String, slot:Int = 0 )
    {
        initSlot( slot );
        m_InTargetSlots[slot].name = name;
    }

    public function getSlotName( slot:Int = 0 )
    {
        initSlot( slot );
        return m_InTargetSlots[slot].name;
    }
#end

    public function addChildSlot( slot:Int, child:DisplayObject )
    {
        initSlot( slot );
        m_InTargetSlots[slot].addChild( child );
    }

    public function addChildAt_Slot( slot:Int, child:DisplayObject, index:Int )
    {
        initSlot( slot );
        m_InTargetSlots[slot].addChildAt( child, index );
    }
    
    public function removeChildSlot( slot:Int, child:DisplayObject )
    {
        if(m_InTargetSlots[slot]!=null)
            m_InTargetSlots[slot].removeChild( child );
    }

    public function removeChildrenSlot( slot:Int, beginIndex:Int = 0, endIndex:Int = 0x7FFFFFFF)
    {
        if(m_InTargetSlots[slot]!=null)
        {
            beginIndex++;
            if(endIndex == 0x7FFFFFFF)
                endIndex = m_InTargetSlots[slot].numChildren - 2;
            else
                endIndex = endIndex - 2;

            if(beginIndex<=endIndex && endIndex>0)
                m_InTargetSlots[slot].removeChildren(beginIndex, endIndex);
        }
    }

    public function removeChildAt_Slot( slot:Int, index:Int ):DisplayObject 
    {
        if(m_InTargetSlots[slot]!=null)
           return m_InTargetSlots[slot].removeChildAt( (index+1) );
       return null;
    }
    
    public function setSize( w:Int, h:Int ):Void 
    {
        m_w = w;
        m_h = h;
        rebuildMatrix();
    }
    
    private function rebuildMatrix():Void 
    {
        var x2 = m_w;
        var x1 = 0;
        var y2 = 0;
        var y1 = m_h;
        m_vertices = [
            x2, y2, 10,
            x1, y2, 10,
            x2, y1, 10,
            x1, y1, 10
            
        ];
        m_verticesArray = new Float32Array (m_vertices);
        GL.bindBuffer (GL.ARRAY_BUFFER, m_vertexBuffer);    
        GL.bufferData (GL.ARRAY_BUFFER, m_verticesArray , GL.STATIC_DRAW);
    }

    private inline function bindTextures():Void 
    {
        var activeTextureSlot:Int = 0;
        GL.bindBuffer (GL.ARRAY_BUFFER, m_texBuffer);    
        GL.enableVertexAttribArray (m_texAttribute);
        GL.vertexAttribPointer (m_texAttribute, 2, GL.FLOAT, false, 0, 0);

        if( m_rendertextureUniformArr!=null )
        {
            for(i in 0...m_rendertextureUniformArr.length)
            {
                #if debug
                if(m_InTargetSlots[i]==null)
                    throw("Error, no initialized slot for _RenderTexture"+i);
                #end
                GL.activeTexture(GL.TEXTURE0+(activeTextureSlot));
                var targetTexture:nme.gl.GLTexture =  m_InTargetSlots[i].getTexture();
                GL.bindTexture( GL.TEXTURE_2D, targetTexture );
                GL.uniform1i( m_rendertextureUniformArr[i], activeTextureSlot );
                activeTextureSlot++;
            }
        }
/*
        if(m_swapTextureName>=0)
        {
            GL.activeTexture(GL.TEXTURE0+(activeTextureSlot));
            var swapTexture:nme.gl.GLTexture =  mInTargets[0].getTexture();
            GL.bindTexture( GL.TEXTURE_2D, swapTexture );
            GL.uniform1i( m_swapTextureName, activeTextureSlot );
            activeTextureSlot++;
        }
*/
        if( m_textureUniformArr!=null )
        {
            //GL.bindBuffer (GL.ARRAY_BUFFER, m_texBuffer);    
            //GL.enableVertexAttribArray (m_texAttribute);
            //GL.vertexAttribPointer (m_texAttribute, 2, GL.FLOAT, false, 0, 0);
            #if debug
            if(m_textures==null)
                throw("Error, you didn't provide a texture array. Did you mean _RenderTexture0 instead of _Texture0?");
            #end

            for( i in 0...m_textureUniformArr.length )
            {
                #if debug
                if(m_textures[i]==null)
                    throw("Error, you didn't provide a texture in the array. Did you mean _RenderTexture"+i+" instead of _Texture"+i+"?");
                #end
                GL.activeTexture(GL.TEXTURE0+(activeTextureSlot));
                GL.bindBitmapDataTexture( m_textures[i] );
                GL.uniform1i( m_textureUniformArr[i], activeTextureSlot );
                activeTextureSlot++;
            }
        }
    }
    
    private inline function unbindTextures():Void 
    {
        GL.bindTexture( GL.TEXTURE_2D, null );
    }
    
    function renderViewStart (rect:Rectangle):Void
    {
        #if 0 //desktop
        // Fix if app is resized.
        if ( appscale > 1.0 )
            GL.viewport(0,0,APP_WIDTH,APP_HEIGHT);
        #end
    }

    public function setClear( value:Bool, alpha:Float = 0.0, r:Float = 0.0, g:Float = 0.0, b:Float = 0.0, once:Bool=false )
    {
        setClearSlot( 0, value, alpha, r, g , b, once);
    }

    public function setClearSlot( slot:Int, value:Bool, alpha:Float = 0.0, r:Float = 0.0, g:Float = 0.0, b:Float = 0.0, once:Bool=false)
    {
        initSlot( slot );
        m_InTargetSlots[slot].setClear( value, alpha, r, g , b, once);
    }

    private function renderViewEnd (rect:Rectangle):Void
    {       
        #if 0 //desktop
        if ( appscale > 1.0 )
            GL.viewport( 0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
        #end

        GL.useProgram (m_shaderProgram);
        
        GL.bindBuffer (GL.ARRAY_BUFFER, m_vertexBuffer);
        GL.enableVertexAttribArray (m_vertexAttribute);
        GL.vertexAttribPointer (m_vertexAttribute, 3, GL.FLOAT, false, 0, 0);
        
        Globals.instance.setUniforms(m_timeUniform, m_startTime, m_mouseUniform, -1);
 
        if( m_paramsUniformArr!= null )
        {
            var i:Int = 0;
            var j:Int = 0;
            while(j<m_paramsUniformArr.length && m_paramsUniformArr[j]>0)
            {
                GL.uniform4f (m_paramsUniformArr[j], params[i++], params[i++], params[i++], params[i++]);
                j++;
            }
        }

        if( m_positionX != x || m_positionY != y )
        {
            m_positionX = x;
            m_positionY = y;
            m_modelViewMatrix = Matrix3D.create2D (m_positionX, m_positionY, 1, 0);
        }

        if( m_w!=m_windowWidth || m_h!=m_windowHeight ) {
            m_windowWidth  = m_w;
            m_windowHeight = m_h ;
            m_invW = /*1.0 +*/ 1.0/m_windowWidth;
            m_invH = /*1.0 +*/ 1.0/m_windowHeight;
            m_projectionMatrix = Matrix3D.createOrtho (0, m_w, m_h, 0, 1000, -1000);
        }
        if( m_resolutionUniform>=0 )
            GL.uniform4f(m_resolutionUniform, m_w, m_h, m_invW, m_invH);
        GL.uniformMatrix3D (m_projectionMatrixUniform, false, m_projectionMatrix);
        GL.uniformMatrix3D (m_modelViewMatrixUniform, false, m_modelViewMatrix);
    
        bindTextures();
        
        GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);

        unbindTextures();
    
        GL.bindBuffer (GL.ARRAY_BUFFER, null);    
        GL.useProgram (null);
        GL.disableVertexAttribArray(m_vertexAttribute);

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
    
    override public function removeChild(child:DisplayObject):DisplayObject 
    {
        removeChildSlot(0, child); 
        return child;
    }

    override public function removeChildAt(index:Int):DisplayObject 
    {
        return removeChildAt_Slot(0, index); 
    }

    override public function removeChildren(beginIndex:Int = 0, endIndex:Int = 0x7FFFFFFF):Void 
    {
        removeChildrenSlot(0, beginIndex, endIndex);
    }

}


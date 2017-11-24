package go;

//import nme.display.BitmapData;

import nme.display.Sprite;
//import nme.geom.Matrix3D;
import nme.geom.Rectangle;

import nme.display.OpenGLView;
import nme.gl.GL;
///import nme.gl.GLBuffer;
//import nme.gl.GLProgram;
//import nme.utils.Float32Array;

import nme.Lib;
import nme.display.DisplayObject;

class PostprocessIN extends Sprite
{
    private var viewStart:OpenGLView;
    private var viewEnd:OpenGLView;
    
    private var h:Int;
    private var w:Int;

    private var m_clear:Bool;
    private var m_clear_r:Float;
    private var m_clear_g:Float;
    private var m_clear_b:Float;
    private var m_clear_alpha:Float;

    public var m_target:RenderTarget;
    public static var sCurrentTarget:RenderTarget;
    private var mRestoreTarget:RenderTarget;

    public function new(w:Int=-1, h:Int=-1):Void
    {
        super(); 

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
        
        viewEnd = new OpenGLView ();            
        viewEnd.render = renderViewEnd;

        viewStart = new OpenGLView ();           
        viewStart.render = renderviewStart;

        super.addChild(viewStart);
        super.addChild(viewEnd);
    }

    public function getTexture():nme.gl.GLTexture
    {
        return m_target==null? null : m_target.getTexture();
    }
    
    public function setSize( w:Int, h:Int ):Void 
    {
        this.w = w;
        this.h = h;
    }

    function renderviewStart (rect:Rectangle):Void
    {
        if( m_target == null )
            m_target = getTarget( Std.int(rect.width), Std.int(rect.height) );

        mRestoreTarget = sCurrentTarget;
        sCurrentTarget = m_target;

        //startRenderToTexture
        GL.bindFramebuffer( GL.FRAMEBUFFER, m_target.getFramebuffer() );

#if 0 //desktop
        // Fix if app is resized.
        if ( appscale > 1.0 )
            GL.viewport(0,0,APP_WIDTH,APP_HEIGHT);
#end
        if ( m_clear )
        {
            GL.clearColor( m_clear_r, m_clear_g, m_clear_b, m_clear_alpha );
            GL.clear( GL.COLOR_BUFFER_BIT );
        }
}

    private function getTarget( w:Int = -1, h:Int = -1 ):RenderTarget
    {
        return new RenderTarget( w, h );
    }

    public function setClear( value:Bool, alpha:Float = 0.0, r:Float = 0.0, g:Float = 0.0, b:Float = 0.0 )
    {
        m_clear = value;
        m_clear_alpha = alpha;
        m_clear_r = r;
        m_clear_g = g;
        m_clear_b = b;
    }

    private function renderViewEnd (rect:Rectangle):Void
    {       
        if( mRestoreTarget!=null )
        {
            sCurrentTarget = mRestoreTarget;
            GL.bindFramebuffer( GL.FRAMEBUFFER, mRestoreTarget.getFramebuffer() );
        }
        else
        {
            sCurrentTarget = null;
            GL.bindFramebuffer( GL.FRAMEBUFFER, null );
        }
    }

    override public function addChild(child:DisplayObject):DisplayObject 
    {
      super.addChildAt(child, numChildren-1); 
      return child;
    }

    override public function addChildAt(child:DisplayObject, index:Int):DisplayObject 
    {
      index++;
      var max = numChildren-1;
      if(index>max)
        index = max;

      super.addChildAt(child, index);
      return child;
    }
}


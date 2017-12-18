package go;

import nme.display.Sprite;
import nme.geom.Rectangle;

import nme.display.OpenGLView;
import nme.gl.GL;

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
    public var m_swapTarget:RenderTarget;
    public static var sCurrentTarget:RenderTarget;
    private var mRestoreTarget:RenderTarget;

    public function new(w:Int=-1, h:Int=-1):Void
    {
        super(); 

        this.w = ( w>=8 ? w: Lib.current.stage.stageWidth );
        this.h = ( h>=8 ? h: Lib.current.stage.stageHeight );
        
        viewEnd = new OpenGLView ();            
        viewEnd.render = renderViewEnd;

        viewStart = new OpenGLView ();           
        viewStart.render = renderviewStart;

        super.addChild(viewStart);
        super.addChild(viewEnd);
    }

    public function getTexture():nme.gl.GLTexture
    {
        return getTarget().getTexture();
    }
    
    //public function setSize( w:Int, h:Int ):Void 
    //{
    //    this.w = w;
    //    this.h = h;
    //}

    function renderviewStart (rect:Rectangle):Void
    {
        var target = getTarget();

        mRestoreTarget = sCurrentTarget;
        sCurrentTarget = target;

        //startRenderToTexture
        GL.bindFramebuffer( GL.FRAMEBUFFER, target.getFramebuffer() );
        GL.viewport(0,0,target.w,target.h);
        if ( m_clear )
        {
            GL.clearColor( m_clear_r, m_clear_g, m_clear_b, m_clear_alpha );
            GL.clear( GL.COLOR_BUFFER_BIT );
        }
}

    public function getTarget():RenderTarget
    {
        if( m_target == null )
           m_target = new RenderTarget( Std.int(w), Std.int(h) );
        return m_target;
    }

    public function setTarget( target:RenderTarget )
    {
        m_target = target;
    }

    public function getSwapTarget():RenderTarget
    {
        if( m_swapTarget == null )
           m_swapTarget = new RenderTarget( Std.int(w), Std.int(h) );
        return m_swapTarget;
    }

    public function setSwapTarget( target:RenderTarget )
    {
        m_swapTarget = target;
    }

    public function swapTargets()
    {
        var temp = getTarget();
        m_target = getSwapTarget();
        m_swapTarget = temp;
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
            GL.viewport(0,0,mRestoreTarget.w,mRestoreTarget.h);
        }
        else
        {
            sCurrentTarget = null;
            GL.bindFramebuffer( GL.FRAMEBUFFER, null );
            GL.viewport(0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
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


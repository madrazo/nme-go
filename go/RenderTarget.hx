package go;

import nme.gl.GL;
import nme.gl.GLFramebuffer;
import nme.gl.GLTexture;
import nme.Lib;

class RenderTarget
{
    public function new( w:Int= -1, h:Int = -1 ):Void
    {
        m_width = ( w>=8 ? w: Lib.current.stage.stageWidth );
        m_height = ( h >= 8 ? h: Lib.current.stage.stageHeight );
#if debug
        name = "Rendertarget: " + (nTarget++);
#end
    }

    public function getTexture():GLTexture
    {
        if ( m_fbo_texture == null )
        {
            m_fbo_texture = GL.createTexture();
        }
        return m_fbo_texture;
    }

    public function getFramebuffer():GLFramebuffer
    {
        if ( m_fbo == null )
        {
            m_fbo = GL.createFramebuffer();
            m_fbo_texture = getTexture();
            initRenderToTexture( m_fbo_texture, m_fbo, m_width, m_height );
        }
        return m_fbo;
    }

    public function assertSize( w:Int, h:Int ):Void
    {
        if ( m_width != w || m_height != h )
        {
            throw( "RenderTarget: Size (" + w + "," + h + ") is different from created render, use another slot to start a new target(" + m_width + "," + m_height + ")" );
        }
    }

    private function initRenderToTexture( fbo_texture:GLTexture, fbo:GLFramebuffer, screen_width:Int, screen_height:Int/*, ? slot:Int = 0*/ )
    {
        GL.activeTexture( GL.TEXTURE0 );
        GL.bindTexture( GL.TEXTURE_2D, fbo_texture );
        GL.texParameteri( GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR );
        GL.texParameteri( GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR );
        GL.texParameteri( GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE );
        GL.texParameteri( GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE );
        GL.texImage2D( GL.TEXTURE_2D, 0, GL.RGBA, screen_width, screen_height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null );
        GL.bindTexture( GL.TEXTURE_2D, null );

        //Framebuffer to link everything together
        GL.bindFramebuffer( GL.FRAMEBUFFER, fbo );
        GL.framebufferTexture2D( GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, fbo_texture, 0 );

        var status = GL.checkFramebufferStatus( GL.FRAMEBUFFER );
        if ( status != GL.FRAMEBUFFER_COMPLETE )
        {
            trace( "glCheckFramebufferStatus: error " + status );
            return;
        }
        GL.bindFramebuffer( GL.FRAMEBUFFER, null );
    }

    public function freeGPU()
    {
        if( m_fbo_texture != null )
        {
            GL.deleteTexture( m_fbo_texture );
            m_fbo_texture = null;
        }
        if( m_fbo!=null )
        {
            GL.deleteFramebuffer( m_fbo );
            m_fbo = null;
        }
    }

    private var m_fbo:GLFramebuffer;
    private var m_fbo_texture:GLTexture;
    private var m_width:Int;
    private var m_height:Int;
    public var w(get, null):Int;
    public var h(get, null):Int;
    public function get_w(){ return m_width; }
    public function get_h(){ return m_height; }
#if debug
    static private var nTarget:Int = 0;
    public var name:String;
#end
}


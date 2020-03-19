
package;

import nme.Lib;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.events.Event;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.ui.Keyboard;
import GLM;

class Controls {
    
    private var m_viewMatrix:Matrix3D;
    private var m_projectionMatrix:Matrix3D;

    public inline function getViewMatrix():Matrix3D {
        return m_viewMatrix;
    }

    public inline function getProjectionMatrix():Matrix3D {
        return m_projectionMatrix;
    }

    public function new ()
    {        
        // Initial position : on +Z //-Z
        m_position = new Vector3D(0,0,-5);
        // Initial horizontal angle : toward -Z //+Z
        horizontalAngle = 0;//3.14;
        // Initial vertical angle : none
        verticalAngle = 0;
        // Initial Field of View
        initialFoV = 45.0;


        m_oldxpos = -1;
        m_oldypos = -1;
        Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, onKeyDown);
        Lib.current.stage.addEventListener (KeyboardEvent.KEY_UP, onKeyUp);
        Lib.current.stage.addEventListener (MouseEvent.MOUSE_MOVE, onMouseMove);
        m_lastTime = haxe.Timer.stamp();
  }


  public function computeMatricesFromInputs():Void {

      // Compute time difference between current and last frame
      var currentTime = haxe.Timer.stamp();
      var deltaTime:Float = (currentTime-m_lastTime);

      // Get mouse position
      //m_xpos and m_ypos are set on onMouseMove

      var dx = (m_oldxpos-m_xpos);
      var dy = (m_oldypos-m_ypos);
      //trace("h:"+m_oldxpos+","+m_xpos+","+dx);

      //Reset mouse position for next frame
      m_oldxpos = m_xpos;
      m_oldypos = m_ypos;

      // Compute new orientation
      horizontalAngle += m_mouseSpeed * dx;
      //verticalAngle   += m_mouseSpeed * dy;


      // Direction : Spherical coordinates to Cartesian coordinates conversion
      var direction:Vector3D = new Vector3D( 
        Math.cos(verticalAngle) * Math.sin(horizontalAngle),
        Math.sin(verticalAngle),
        Math.cos(verticalAngle) * Math.cos(horizontalAngle)
      );

      // Right vector
      var right:Vector3D = new Vector3D(
        Math.sin(horizontalAngle - 3.14/2.0),
        0,
        Math.cos(horizontalAngle - 3.14/2.0)
      );

      // Up vector
      var up:Vector3D = right.crossProduct( direction );

      // Move forward
      if(upKey)
      {
        var keyDirection = direction.clone();
        keyDirection.scaleBy(deltaTime * m_speed);
        m_position.incrementBy( keyDirection );
      }
      // Move backward
      if(downKey)
      {
        var keyDirection = direction.clone();
        keyDirection.scaleBy(deltaTime * (-m_speed));
        m_position.incrementBy( keyDirection );
      }
      // Strafe right
      if(rightKey)
      {
        var keyDirection = right.clone();
        keyDirection.scaleBy(deltaTime * (-m_speed));
        m_position.incrementBy( keyDirection );
      }
      // Strafe left
      if(leftKey)
      {
        var keyDirection = right.clone();
        keyDirection.scaleBy(deltaTime * (m_speed));
        m_position.incrementBy( keyDirection );
      }

      var aspect = 4 / 3;
      var zNear = 0.1;
      var zFar = 1000;
      var fov = initialFoV * Math.PI / 180;
      m_projectionMatrix = GLM.perspective(fov, aspect, zNear, zFar);
      
      m_viewMatrix = GLM.lookAt(
        m_position, // Camera is at (4,3,-3), in World Space
        m_position.add(direction), // 
        up // Head is up (set to 0,-1,0 to look upside-down)
      );

      // For the next frame, the "last time" will be "now"
      m_lastTime = currentTime;
  }


  public function onKeyDown (event:KeyboardEvent):Void 
  {
      switch (event.keyCode) {
        case Keyboard.DOWN: downKey = true;
        case Keyboard.LEFT: leftKey = true;
        case Keyboard.RIGHT: rightKey = true;
        case Keyboard.UP: upKey = true;
      }
  }
  
  public function onKeyUp (event:KeyboardEvent):Void 
  {
      switch (event.keyCode) {
        case Keyboard.DOWN: downKey = false;
        case Keyboard.LEFT: leftKey = false;
        case Keyboard.RIGHT: rightKey = false;
        case Keyboard.UP: upKey = false;
      }
  }
  
  public function onMouseMove(event:MouseEvent)
  { 
      m_xpos = event.stageX;
      m_ypos = event.stageY;
      if(m_oldxpos == -1 && m_oldypos == -1)
      {
          m_oldxpos = m_xpos;
          m_oldypos = m_ypos;
      }
  }


 static private inline var m_speed:Float = 3.0;
 static private inline var m_mouseSpeed = 0.005;

 private var m_lastTime:Float;
 private var m_position:Vector3D;
 private var upKey:Bool;
 private var downKey:Bool;
 private var rightKey:Bool;
 private var leftKey:Bool;

 private var m_xpos:Float;
 private var m_ypos:Float;
 private var m_oldxpos:Float;
 private var m_oldypos:Float;


 private var horizontalAngle:Float = 3.14;
 private var verticalAngle:Float   = 0;
 private var initialFoV = 45.0;
    
}

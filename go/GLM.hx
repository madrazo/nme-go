package go;


import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.Vector;


class GLM {
    
  static public inline function INDEX(i:Int, j:Int):Int
  {
    return i*4+j;
  }

  static public function lookAt(eye:Vector3D, center:Vector3D, up:Vector3D):Matrix3D
  {
        if (center == null) center = new Vector3D(0,0,-1);
        if (up == null) up = new Vector3D(0,1,0);

        eye.z = -eye.z; //OK?

        var f:Vector3D;
        var s:Vector3D;
        var u:Vector3D;
        f = center.subtract(eye);
        f.normalize();
        s = up.crossProduct(f);
        s.normalize();
        u = f.crossProduct(s);

        var raw:nme.Vector<Float> = [1.0, 0.0, 0.0, 0.0, 
                                     0.0, 1.0, 0.0, 0.0, 
                                     0.0, 0.0, 1.0, 0.0, 
                                     0.0, 0.0, 0.0, 1.0];

        raw[INDEX(0,0)] = s.x;
        raw[INDEX(1,0)] = s.y;
        raw[INDEX(2,0)] = s.z;

        raw[INDEX(0,1)] = u.x;
        raw[INDEX(1,1)] = u.y;
        raw[INDEX(2,1)] = u.z;

        raw[INDEX(0,2)] = f.x;
        raw[INDEX(1,2)] = f.y;
        raw[INDEX(2,2)] = f.z;

        raw[INDEX(3,0)] = -s.dotProduct(eye);
        raw[INDEX(3,1)] = -u.dotProduct(eye);
        raw[INDEX(3,2)] = -f.dotProduct(eye);

        eye.z = -eye.z; //revert?

        return new Matrix3D(raw);
    }

    static public function perspective(fieldOfViewY:Float, aspectRatio:Float, zNear:Float, zFar:Float):Matrix3D
    {  
        var yScale = 1.0 / Math.tan (fieldOfViewY / 2.0);
        var xScale = yScale / aspectRatio;

        xScale = -xScale; //ok?

        var raw:nme.Vector<Float> = [1.0, 0.0, 0.0, 0.0, 
                                     0.0, 1.0, 0.0, 0.0, 
                                     0.0, 0.0, 1.0, 0.0, 
                                     0.0, 0.0, 0.0, 1.0];
    
        raw[INDEX(0,0)] = xScale;
        raw[INDEX(1,1)] = yScale;
        raw[INDEX(2,2)] = zFar / (zFar - zNear);
        raw[INDEX(2,3)] = 1.0;
        raw[INDEX(3,2)] =(zNear * zFar) / (zNear - zFar);
        raw[INDEX(3,3)] =0.0;

        return new Matrix3D(raw); 
    }    
    
}

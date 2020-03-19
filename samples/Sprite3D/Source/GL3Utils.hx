
package;

import nme.Assets;
import nme.gl.GL;


class GL3Utils {
    
    static public function vsToGLES2(source:String):String
    {
        var lines:Array<String> = source.split("\n");
        var result:StringBuf = new StringBuf();
        var bFirstLine:Bool = true;

        for(line in lines)
        {
            var fullLine = line.split("//");
            var line2 = fullLine[0]; //Remove comments
            if(bFirstLine && line2.indexOf("#version")>=0)
            {
                bFirstLine = false;
                continue;
            }
            var words:Array<String> = line2.split(" in ");
            if(words.length>=2)
            {
                var layout:Array<String> = words[0].split("layout");
                if(layout.length>=2)
                {
                    var location:Array<String> = layout[1].split("(");
                    location = location[1].split(")");
                    location = location[0].split("=");
                    var locationInt:Int = Std.parseInt(location[1]);
                }
                result.add("attribute ");
                result.add(words[1]);
                result.add("\n");
            }
            else
            {
                words = line2.split(" ");
                if(words[0]=="out")
                {
                    words = line2.split("out ");
                    result.add("varying ");
                    result.add(words[1]);
                    result.add("\n");
                }
                else
                {
                    result.add(line2);
                    result.add("\n");
                }
            }
        //for(i in 1...fullLine.length)
        //{            
            //    result.add("//");
            //    result.add(fullLine[i]);
        //}
       }
       return result.toString();
   }
    
    static public function fsToGLES2(source:String):String
    {
        var lines:Array<String> = source.split("\n");
        var result:StringBuf = new StringBuf();
        var bFirstLine:Bool = true;

        result.add("#define texture texture2D\n");

        for(line in lines)
        {

            var fullLine = line.split("//");
            var line2 = fullLine[0];//Remove coments
            if(bFirstLine && line2.indexOf("#version")>=0)
            {
                bFirstLine = false;
                continue;
            }
            var words:Array<String> = line2.split("out vec4 ");
            if(words.length>=2)
            {
                var outName:String = (words[1].split(";"))[0];
                result.add("#define ");
                result.add(outName);
                result.add(" gl_FragColor\n");
                result.add("\n");
            }
            else
            {
                words = line2.split(" ");
                if(words[0]=="in")
                {
                    words = line2.split("in ");
                    result.add("varying ");
                    result.add(words[1]);
                    result.add("\n");
                }
                else
        {
                    result.add(line2);
                    result.add("\n");
        }
            }
       }
       return result.toString();
   }

   public static function isGLES3compat():Bool
   {
    #if gles3
      initGLVersion();
      return _isGLES3compat;
    #else
      return false;
    #end
   };

   public static function isDesktopGL():Bool
   {
      initGLVersion();
      return !_isGLES;
   };

   //Inits glVersion, isGLES, isGLES3compat, isWebGL
   public static function initGLVersion()
   {
      if(!_glVersionInit)
      {
         var version = StringTools.ltrim(GL.getParameter(GL.VERSION));
         if(version.indexOf("OpenGL ES") >= 0)
         { 
            _isGLES = true;
            _glVersion = Std.parseFloat(version.split(" ")[2]);
            _isGLES3compat = (_glVersion>=3.0);
         }
         else if(version.indexOf("WebGL") >= 0)
         { 
            _isGLES = true; //a kind of GLES
            _isWebGL = true;
            _glVersion = Std.parseFloat(version.split(" ")[1]);
            _isGLES3compat = (_glVersion>=2.0);
         }
         else
         {
            _glVersion = Std.parseFloat(version.split(" ")[0]);
            _isGLES3compat = (_glVersion >= 3.3);
         }
         _glVersionInit = true;
         //trace("version: "+_glVersion+" is GLES: "+(_isGLES?"true":"false")+", is GLES3 compatible:"+(_isGLES3compat?"true":"false"));
     }
   }

   private static var _isGLES:Bool;
   private static var _isWebGL:Bool;
   private static var _isGLES3compat:Bool;
   private static var _glVersion:Float;
   private static var _glVersionInit:Bool;
}

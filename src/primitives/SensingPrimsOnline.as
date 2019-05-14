package primitives
{
   import flash.utils.Dictionary;
   import interpreter.Interpreter;
   
   public class SensingPrimsOnline extends SensingPrims
   {
       
      
      public function SensingPrimsOnline(param1:Scratch, param2:Interpreter)
      {
         super(param1,param2);
      }
      
      override public function addPrimsTo(param1:Dictionary) : void
      {
         var primTable:Dictionary = param1;
         super.addPrimsTo(primTable);
         primTable["getUserName"] = function(param1:*):*
         {
            return ScratchOnline.app.userName;
         };
      }
   }
}

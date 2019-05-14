package primitives
{
   import flash.utils.Dictionary;
   import interpreter.Interpreter;
   
   public class PrimitivesOnline extends Primitives
   {
       
      
      public function PrimitivesOnline(param1:Scratch, param2:Interpreter)
      {
         super(param1,param2);
      }
      
      override protected function addOtherPrims(param1:Dictionary) : void
      {
         new SensingPrimsOnline(app,interp).addPrimsTo(param1);
         new ListPrimsOnline(app,interp).addPrimsTo(param1);
      }
   }
}

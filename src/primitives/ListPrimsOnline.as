package primitives
{
   import interpreter.Interpreter;
   import watchers.ListWatcher;
   
   public class ListPrimsOnline extends ListPrims
   {
       
      
      public function ListPrimsOnline(param1:Scratch, param2:Interpreter)
      {
         super(param1,param2);
      }
      
      override protected function listAppend(param1:ListWatcher, param2:*) : void
      {
         super.listAppend(param1,param2);
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.appendList(param1.listName,param2);
         }
      }
      
      override protected function listSet(param1:ListWatcher, param2:Array) : void
      {
         super.listSet(param1,param2);
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.setList(param1.listName,param1.contents);
         }
      }
      
      override protected function listDelete(param1:ListWatcher, param2:int) : void
      {
         super.listDelete(param1,param2);
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.deleteList(param1.listName,param2);
         }
      }
      
      override protected function listInsert(param1:ListWatcher, param2:int, param3:*) : void
      {
         super.listInsert(param1,param2,param3);
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.insertList(param1.listName,param3,param2);
         }
      }
      
      override protected function listReplace(param1:ListWatcher, param2:int, param3:*) : void
      {
         super.listReplace(param1,param2,param3);
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.replaceList(param1.listName,param3,param2);
         }
      }
   }
}

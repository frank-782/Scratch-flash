package scratch
{
   import flash.utils.ByteArray;
   import interpreter.Interpreter;
   import interpreter.Variable;
   import translation.Translator;
   import ui.media.MediaInfo;
   import util.ProjectIO;
   import util.ServerOnline;
   import watchers.ListWatcher;
   
   public class ScratchRuntimeOnline extends ScratchRuntime
   {
      
      protected static var Cat1svg:Class = ScratchRuntimeOnline_Cat1svg;
      
      protected static var Cat2svg:Class = ScratchRuntimeOnline_Cat2svg;
      
      protected static var Meow:Class = ScratchRuntimeOnline_Meow;
       
      
      public function ScratchRuntimeOnline(param1:Scratch, param2:Interpreter)
      {
         super(param1,param2);
      }
      
      override public function stepRuntime() : void
      {
         if(projectToInstall != null && ScratchOnline.app.serverSettingsReady)
         {
            installProject(projectToInstall);
            if(saveAfterInstall)
            {
               app.setSaveNeeded(true);
            }
            projectToInstall = null;
            saveAfterInstall = false;
         }
         else
         {
            super.stepRuntime();
         }
      }
      
      override public function installProjectFromFile(param1:String, param2:ByteArray) : void
      {
         super.installProjectFromFile(param1,param2);
         ScratchOnline.app.jsEditTitle();
         saveAfterInstall = true;
      }
      
      override public function deleteVariable(param1:String) : void
      {
         var _loc2_:Variable = app.viewedObj().lookupVar(param1);
         if(_loc2_.isPersistent)
         {
            ScratchOnline.app.persistenceManager.deleteVariable(param1);
            ScratchOnline.app.persistentDataCount--;
         }
         super.deleteVariable(param1);
      }
      
      override public function renameVariable(param1:String, param2:String) : void
      {
         var _loc3_:Variable = app.viewedObj().lookupVar(param1);
         if(_loc3_.isPersistent)
         {
            ScratchOnline.app.persistenceManager.renameVariable(param1,param2);
         }
         super.renameVariable(param1,param2);
      }
      
      override protected function doUndelete(param1:*, param2:int, param3:int, param4:*) : void
      {
         if(param1 is MediaInfo && param4 == "backpack")
         {
            ScratchOnline.app.backpackPart.insertAndSave(param1);
         }
         else
         {
            super.doUndelete(param1,param2,param3,param4);
         }
      }
      
      override public function updateVariable(param1:Variable) : void
      {
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.updateVariable(param1.name,param1.value);
         }
      }
      
      override public function makeVariable(param1:Object) : Variable
      {
         var _loc2_:Variable = super.makeVariable(param1);
         if(param1.isPersistent)
         {
            _loc2_.isPersistent = true;
            ScratchOnline.app.usesPersistentData = true;
            ScratchOnline.app.persistentDataCount++;
         }
         return _loc2_;
      }
      
      override public function makeListWatcher() : ListWatcher
      {
         var _loc1_:ListWatcher = super.makeListWatcher();
         if(_loc1_.isPersistent)
         {
            ScratchOnline.app.usesPersistentData = true;
            ScratchOnline.app.persistentDataCount++;
         }
         return _loc1_;
      }
      
      override public function installNewProject() : void
      {
         var _loc1_:ScratchStage = new ScratchStageOnline();
         var _loc2_:ScratchSprite = new ScratchSprite();
         _loc2_.costumes = [new ScratchCostume(Translator.map("costume1"),new Cat1svg()),new ScratchCostume(Translator.map("costume2"),new Cat2svg())];
         _loc2_.showCostume(0);
         _loc2_.sounds = [new ScratchSound(Translator.map("meow"),new Meow())];
         _loc1_.addChild(_loc2_);
         app.saveForRevert(new ProjectIO(app).encodeProjectAsZipFile(_loc1_),true);
         app.oldWebsiteURL = "";
         installProject(_loc1_);
      }
      
      override public function startGreenFlags(param1:Boolean = false) : void
      {
         if(param1)
         {
            (app.server as ServerOnline).recordPlay();
         }
         super.startGreenFlags(param1);
      }
   }
}

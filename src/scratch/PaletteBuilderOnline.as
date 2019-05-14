package scratch
{
   import interpreter.PersistenceManager;
   import uiwidgets.VariableSettings;
   import uiwidgets.VariableSettingsOnline;
   
   public class PaletteBuilderOnline extends PaletteBuilder
   {
       
      
      public function PaletteBuilderOnline(param1:Scratch)
      {
         super(param1);
      }
      
      override protected function createVar(param1:String, param2:VariableSettings) : *
      {
         var app:ScratchOnline = null;
         var v:* = undefined;
         var name:String = param1;
         var settings:VariableSettings = param2;
         var varSettings:VariableSettingsOnline = settings as VariableSettingsOnline;
         if(varSettings.isPersistent)
         {
            app = ScratchOnline.app;
            app.persistentDataCount++;
            name = "☁ " + name;
            if(!app.usesPersistentData)
            {
               app.usesPersistentData = true;
               app.persistenceManager.addEventListener(PersistenceManager.READY,function():void
               {
                  if(settings.isList)
                  {
                     app.persistenceManager.setList(name,[]);
                  }
                  else
                  {
                     app.persistenceManager.createVariable(name);
                  }
               });
               app.persistenceManager.connect(app.serverSettings.cloud_data_host);
            }
            else if(settings.isList)
            {
               app.persistenceManager.setList(name,[]);
            }
            else
            {
               app.persistenceManager.createVariable(name);
            }
            return;
         }
         v = super.createVar(name,varSettings);
         return v;
      }
      
      override protected function makeVarSettings(param1:Boolean, param2:Boolean) : VariableSettings
      {
         return new VariableSettingsOnline(param1,param2,ScratchOnline.app.isLoggedIn(),ScratchOnline.app.isScratcher());
      }
   }
}

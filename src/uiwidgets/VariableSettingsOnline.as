package uiwidgets
{
   import assets.Resources;
   import flash.text.TextField;
   import translation.Translator;
   
   public class VariableSettingsOnline extends VariableSettings
   {
       
      
      public var isPersistent:Boolean;
      
      private var loggedIn:Boolean;
      
      private var isScratcher:Boolean;
      
      private var cloudButton:IconButton;
      
      private var cloudLabel:TextField;
      
      public function VariableSettingsOnline(param1:Boolean, param2:Boolean, param3:Boolean, param4:Boolean)
      {
         this.loggedIn = param3;
         this.isScratcher = param4;
         super(param1,param2);
         var _loc5_:Boolean = !param1 && param3 && param4 && ScratchOnline.app.isCloudDataEnabled();
         this.cloudLabel.visible = _loc5_;
         this.cloudButton.visible = _loc5_;
         if(_loc5_)
         {
            drawLine();
         }
      }
      
      public static function strings() : Array
      {
         return ["Cloud list (stored on server)","Cloud variable (stored on server)","requires sign in","limit reached"];
      }
      
      override protected function addLabels() : void
      {
         super.addLabels();
         addChild(this.cloudLabel = Resources.makeLabel(Translator.map(!!isList?"Cloud list (stored on server)":"Cloud variable (stored on server)"),CSS.normalTextFormat));
      }
      
      override protected function addButtons() : void
      {
         var setCloud:Function = null;
         setCloud = function(param1:IconButton):void
         {
            isPersistent = !isPersistent;
            updateButtons();
         };
         super.addButtons();
         addChild(this.cloudButton = new IconButton(setCloud,"checkbox"));
         this.cloudButton.disableMouseover();
         this.updateCloudButtonAndLabel();
      }
      
      override protected function updateButtons() : void
      {
         if(this.isPersistent)
         {
            isLocal = false;
            this.cloudButton.setOn(true);
            localButton.setDisabled(true,0.2);
            localLabel.alpha = 0.5;
         }
         else
         {
            this.cloudButton.setDisabled(isLocal,0.2);
            this.cloudLabel.alpha = !!isLocal?Number(0.5):Number(1);
            super.updateButtons();
         }
         globalButton.setOn(!isLocal);
         this.updateCloudButtonAndLabel();
      }
      
      private function updateCloudButtonAndLabel() : void
      {
         if(ScratchOnline.app.persistentDataCount >= 10)
         {
            this.cloudLabel.text = this.cloudLabel.text.replace(Translator.map("stored on server"),Translator.map("limit reached"));
            this.cloudLabel.alpha = 0.5;
            this.cloudButton.setDisabled(true,0.2);
         }
      }
      
      override protected function fixLayout() : void
      {
         super.fixLayout();
         var _loc1_:int = 15;
         var _loc2_:int = 45;
         this.cloudButton.x = _loc1_;
         this.cloudButton.y = _loc2_ + 3;
         this.cloudLabel.x = _loc1_ + 16;
         this.cloudLabel.y = _loc2_;
      }
   }
}

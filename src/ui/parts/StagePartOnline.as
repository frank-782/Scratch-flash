package ui.parts
{
   import flash.text.TextFormat;
   import translation.Translator;
   import uiwidgets.EditableLabel;
   
   public class StagePartOnline extends StagePart
   {
       
      
      public function StagePartOnline(param1:Scratch)
      {
         super(param1);
      }
      
      override protected function fixLayout() : void
      {
         super.fixLayout();
         if(ScratchOnline.app.isLoggedIn())
         {
            projectInfo.y = projectInfo.y + 2;
         }
      }
      
      override protected function getProjectTitle(param1:TextFormat) : EditableLabel
      {
         return new EditableLabel(ScratchOnline.app.jsEditTitle,param1);
      }
      
      override protected function updateProjectInfo() : void
      {
         var _loc1_:* = null;
         var _loc2_:* = null;
         if(app.projectOwner == "")
         {
            projectInfo.text = "";
            if(app.projectID == "")
            {
               projectTitle.setEditable(true);
            }
         }
         else
         {
            _loc1_ = Translator.map("by") + " ";
            _loc2_ = " (" + Translator.map(!!app.projectIsPrivate?"unshared":"shared") + ")";
            if(ScratchOnline.app.userName == app.projectOwner)
            {
               projectInfo.text = _loc1_ + app.projectOwner + _loc2_;
               projectTitle.setEditable(true);
            }
            else
            {
               projectInfo.text = _loc1_ + app.projectOwner;
            }
         }
      }
   }
}

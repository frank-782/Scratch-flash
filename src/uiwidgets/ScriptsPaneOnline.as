package uiwidgets
{
   import ui.media.MediaInfoOnline;
   import util.ServerOnline;
   
   public class ScriptsPaneOnline extends ScriptsPane
   {
       
      
      public function ScriptsPaneOnline(param1:Scratch)
      {
         super(param1);
      }
      
      override public function handleDrop(param1:*) : Boolean
      {
         var _loc2_:MediaInfoOnline = param1 as MediaInfoOnline;
         if(_loc2_ && _loc2_.fromBackpack)
         {
            if(super.handleDrop(param1))
            {
               ServerOnline.getInstance().logUseItemFromBackpack(util.JSON.stringify({
                  "target":ScratchOnline.app.projectID,
                  "item":_loc2_.backpackRecord(),
                  "uipart":"scriptspane"
               }));
               return true;
            }
            return false;
         }
         return super.handleDrop(param1);
      }
   }
}

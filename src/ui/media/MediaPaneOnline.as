package ui.media
{
   import util.ServerOnline;
   
   public class MediaPaneOnline extends MediaPane
   {
       
      
      public function MediaPaneOnline(param1:Scratch, param2:String)
      {
         super(param1,param2);
      }
      
      override public function handleDrop(param1:*) : Boolean
      {
         var _loc2_:MediaInfoOnline = param1 as MediaInfoOnline;
         if(_loc2_ && _loc2_.fromBackpack)
         {
            if(ScratchOnline.app.dropMediaInfo(param1))
            {
               ServerOnline.getInstance().logUseItemFromBackpack(util.JSON.stringify({
                  "target":ScratchOnline.app.projectID,
                  "item":_loc2_.backpackRecord(),
                  "uipart":"mediapane"
               }));
            }
            return true;
         }
         return super.handleDrop(param1);
      }
   }
}

package svgeditor
{
   import ui.media.MediaInfoOnline;
   import ui.parts.ImagesPart;
   import util.ServerOnline;
   
   public class SVGEditOnline extends SVGEdit
   {
       
      
      public function SVGEditOnline(param1:Scratch, param2:ImagesPart)
      {
         super(param1,param2);
      }
      
      override public function handleDrop(param1:*) : Boolean
      {
         var _loc2_:MediaInfoOnline = null;
         if(super.handleDrop(param1))
         {
            _loc2_ = param1 as MediaInfoOnline;
            if(_loc2_ && _loc2_.fromBackpack)
            {
               ServerOnline.getInstance().logUseItemFromBackpack(util.JSON.stringify({
                  "target":ScratchOnline.app.projectID,
                  "item":_loc2_.backpackRecord(),
                  "uipart":"svgimageedit"
               }));
            }
            return true;
         }
         return false;
      }
   }
}

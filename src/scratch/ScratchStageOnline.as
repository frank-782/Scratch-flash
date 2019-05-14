package scratch
{
   import ui.media.MediaInfoOnline;
   import util.ProjectIOOnline;
   import util.ServerOnline;
   
   public class ScratchStageOnline extends ScratchStage
   {
       
      
      public function ScratchStageOnline()
      {
         super();
      }
      
      override public function handleDrop(param1:*) : Boolean
      {
         var app:Scratch = null;
         var handled:Boolean = false;
         var obj:* = param1;
         if(super.handleDrop(obj))
         {
            return true;
         }
         app = ScratchOnline.app as Scratch;
         var mio:MediaInfoOnline = obj as MediaInfoOnline;
         if(mio && mio.fromBackpack)
         {
            var addSpriteForCostume:Function = function(param1:ScratchCostume):void
            {
               var _loc2_:ScratchSprite = new ScratchSprite(param1.costumeName);
               _loc2_.setInitialCostume(param1.duplicate());
               app.addNewSprite(_loc2_,false,true);
            };
            handled = false;
            if(obj.mysprite)
            {
               app.addNewSprite(obj.mysprite.duplicate(),false,true);
               handled = true;
            }
            if(obj.objType == "sprite")
            {
               var addDroppedSprite:Function = function(param1:ScratchSprite):void
               {
                  param1.objName = obj.objName;
                  app.addNewSprite(param1,false,true);
               };
               new ProjectIOOnline(ScratchOnline.app).fetchSprite(obj.md5,addDroppedSprite);
               handled = true;
            }
            if(obj.mycostume)
            {
               addSpriteForCostume(obj.mycostume);
               handled = true;
            }
            if(obj.objType == "image")
            {
               new ProjectIOOnline(ScratchOnline.app).fetchImage(obj.md5,obj.objName,obj.objWidth,addSpriteForCostume);
               handled = true;
            }
            if(handled)
            {
               ServerOnline.getInstance().logUseItemFromBackpack(util.JSON.stringify({
                  "target":ScratchOnline.app.projectID,
                  "item":obj.backpackRecord(),
                  "uipart":"scratchstage"
               }));
               return true;
            }
         }
         return false;
      }
      
      override public function updateInfo() : void
      {
         super.updateInfo();
         info.hasCloudData = ScratchOnline.app.usesPersistentData;
      }
   }
}

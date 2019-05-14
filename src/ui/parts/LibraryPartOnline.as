package ui.parts
{
   import flash.display.BitmapData;
   import flash.geom.Point;
   import scratch.ScratchCostume;
   import scratch.ScratchSprite;
   import translation.Translator;
   import ui.media.MediaInfoOnline;
   import uiwidgets.IconButton;
   import util.ProjectIO;
   import util.ServerOnline;
   
   public class LibraryPartOnline extends LibraryPart
   {
       
      
      public function LibraryPartOnline(param1:ScratchOnline)
      {
         super(param1);
      }
      
      override public function handleDrop(param1:*) : Boolean
      {
         var _loc2_:MediaInfoOnline = null;
         if(this.realHandleDrop(param1))
         {
            _loc2_ = param1 as MediaInfoOnline;
            if(_loc2_ && _loc2_.fromBackpack)
            {
               ServerOnline.getInstance().logUseItemFromBackpack(util.JSON.stringify({
                  "target":ScratchOnline.app.projectID,
                  "item":_loc2_.backpackRecord(),
                  "uipart":"librarypart"
               }));
            }
            return true;
         }
         return false;
      }
      
      private function realHandleDrop(param1:*) : Boolean
      {
         var obj:* = param1;
         var item:MediaInfoOnline = obj as MediaInfoOnline;
         if(!item)
         {
            return false;
         }
         var dropP:Point = spritesPane.globalToLocal(new Point(item.x,item.y));
         if(!item.fromBackpack && item.mysprite)
         {
            changeThumbnailOrder(item.mysprite,dropP.x,dropP.y);
            return true;
         }
         if(item.fromBackpack)
         {
            var addSpriteForCostume:Function = function(param1:ScratchCostume):void
            {
               var _loc2_:ScratchSprite = new ScratchSprite(param1.costumeName);
               _loc2_.setInitialCostume(param1.duplicate());
               app.addNewSprite(_loc2_,false,true);
            };
            if(item.mysprite)
            {
               app.addNewSprite(item.mysprite.duplicate());
               return true;
            }
            if("sprite" == item.objType)
            {
               new ProjectIO(app).fetchSprite(item.md5,app.addNewSprite);
               return true;
            }
            if(item.mycostume)
            {
               addSpriteForCostume(item.mycostume);
               return true;
            }
            if("image" == item.objType)
            {
               new ProjectIO(app).fetchImage(item.md5,item.objName,item.objWidth,addSpriteForCostume);
               return true;
            }
         }
         return false;
      }
      
      override protected function spriteFromCamera(param1:IconButton) : void
      {
         var savePhoto:Function = null;
         var b:IconButton = param1;
         savePhoto = function(param1:BitmapData):void
         {
            try
            {
               ScratchOnline.app.logImageImported("photo.png",true);
            }
            catch(error:Error)
            {
            }
            var _loc2_:ScratchSprite = new ScratchSprite();
            _loc2_.setInitialCostume(new ScratchCostume(Translator.map("photo1"),param1));
            app.addNewSprite(_loc2_);
            app.closeCameraDialog();
         };
         app.openCameraDialog(savePhoto);
      }
      
      override protected function backdropFromCamera(param1:IconButton) : void
      {
         var savePhoto:Function = null;
         var b:IconButton = param1;
         savePhoto = function(param1:BitmapData):void
         {
            try
            {
               ScratchOnline.app.logImageImported("photo.png",true);
            }
            catch(error:Error)
            {
            }
            addBackdrop(new ScratchCostume(Translator.map("photo1"),param1));
            app.closeCameraDialog();
         };
         app.openCameraDialog(savePhoto);
      }
   }
}

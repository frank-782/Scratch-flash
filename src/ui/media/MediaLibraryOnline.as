package ui.media
{
   import scratch.ScratchCostume;
   import scratch.ScratchSound;
   import scratch.ScratchSprite;
   import uiwidgets.Button;
   import util.ProjectIOOnline;
   
   public class MediaLibraryOnline extends MediaLibrary
   {
       
      
      private var viewDocsBtn:Button;
      
      private var showMyExtensionsBtn:Button;
      
      private var createExtensionsBtn:Button;
      
      private var myExtensions:Array;
      
      private var w:int;
      
      private var h:int;
      
      public function MediaLibraryOnline(param1:Scratch, param2:String, param3:Function)
      {
         this.myExtensions = [];
         super(param1,param2,param3);
      }
      
      override public function setWidthHeight(param1:int, param2:int) : void
      {
         super.setWidthHeight(param1,param2);
         this.w = param1;
         this.h = param2;
         if(this.showMyExtensionsBtn)
         {
            this.showMyExtensionsBtn.x = 50;
            this.showMyExtensionsBtn.y = 200;
            this.viewDocsBtn.x = 50;
            this.viewDocsBtn.y = 240;
            this.createExtensionsBtn.x = 50;
            this.createExtensionsBtn.y = 280;
         }
      }
      
      public function showMyExtensions() : void
      {
         this.viewDocsBtn.visible = true;
         this.createExtensionsBtn.visible = false;
         while(resultsPane.numChildren > 0)
         {
            resultsPane.removeChildAt(0);
         }
         appendItems(this.myExtensions);
      }
      
      override protected function uploadCostume(param1:ScratchCostume, param2:Function) : void
      {
         var costume:ScratchCostume = param1;
         var whenDone:Function = param2;
         try
         {
            ScratchOnline.app.logImageImported(costume.baseLayerMD5,false);
         }
         catch(error:Error)
         {
            try
            {
               if(ScratchCostume.isSVGData(costume.baseLayerData))
               {
                  ScratchOnline.app.logImageImported(".svg",false);
               }
            }
            catch(error:Error)
            {
            }
         }
         if(ScratchOnline.app.isLoggedIn())
         {
            app.addLoadProgressBox("Uploading image...");
            costume.prepareToSave();
            new ProjectIOOnline(ScratchOnline.app).uploadAsset(costume.baseLayerMD5,"",costume.baseLayerData,whenDone);
         }
         else
         {
            super.uploadCostume(costume,whenDone);
         }
      }
      
      override protected function uploadSprite(param1:ScratchSprite, param2:Function) : void
      {
         if(ScratchOnline.app.isLoggedIn())
         {
            app.addLoadProgressBox("Uploading sprite...");
            new ProjectIOOnline(ScratchOnline.app).uploadSprite(param1,param2);
         }
         else
         {
            super.uploadSprite(param1,param2);
         }
      }
      
      override protected function gifImported(param1:Array) : void
      {
         var uploadComplete:Function = null;
         var uploadCount:int = 0;
         var c:ScratchCostume = null;
         var newCostumes:Array = param1;
         uploadComplete = function():void
         {
            uploadCount++;
            if(uploadCount >= newCostumes.length)
            {
               app.removeLoadProgressBox();
               whenDone(newCostumes);
            }
         };
         if(!ScratchOnline.app.isLoggedIn())
         {
            super.gifImported(newCostumes);
            return;
         }
         uploadCount = 0;
         app.addLoadProgressBox("Uploading image...");
         var i:int = 0;
         while(i < newCostumes.length)
         {
            c = newCostumes[i];
            c.prepareToSave();
            new ProjectIOOnline(ScratchOnline.app).uploadAsset(c.baseLayerMD5,"",c.baseLayerData,uploadComplete);
            i++;
         }
      }
      
      override protected function startSoundUpload(param1:ScratchSound, param2:String, param3:Function) : void
      {
         if(param1 && ScratchOnline.app.isLoggedIn())
         {
            param1.prepareToSave();
            app.addLoadProgressBox("Uploading sound...");
            new ProjectIOOnline(ScratchOnline.app).uploadAsset(param1.md5,"",param1.soundData,param3);
         }
         else
         {
            super.startSoundUpload(param1,param2,param3);
         }
      }
   }
}

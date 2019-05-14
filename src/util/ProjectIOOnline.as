package util
{
   import by.blooddy.crypto.MD5;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.events.SecurityErrorEvent;
   import flash.external.ExternalInterface;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.utils.ByteArray;
   import flash.utils.setTimeout;
   import logging.LogLevel;
   import scratch.ScratchCostume;
   import scratch.ScratchSprite;
   import scratch.ScratchStage;
   import scratch.ScratchStageOnline;
   import translation.Translator;
   
   public class ProjectIOOnline extends ProjectIO
   {
      
      private static var serverAssets:Object = {};
       
      
      public function ProjectIOOnline(param1:ScratchOnline)
      {
         super(param1);
      }
      
      public static function strings() : Array
      {
         return ["Loading project...","of","assets loaded","bytes loaded","Installing...","Uploading sprite...","Saving changes...","Saving...","Saved","Error!","Project did not load."];
      }
      
      private static function addCallServerErrorInfo(param1:Object) : Object
      {
         var _loc3_:* = null;
         var _loc2_:Object = ServerOnline.getInstance().callServerErrorInfo;
         if(_loc2_)
         {
            for(_loc3_ in _loc2_)
            {
               if(_loc2_.hasOwnProperty(_loc3_))
               {
                  param1[_loc3_] = _loc2_[_loc3_].toString();
               }
            }
         }
         else
         {
            param1["errorEvent"] = "[no event]";
         }
         return param1;
      }
      
      override protected function getScratchStage() : ScratchStage
      {
         return new ScratchStageOnline();
      }
      
      public function fetchOldProjectURL(param1:String) : void
      {
         var progressHandler:Function = null;
         var completeHandler:Function = null;
         var loader:URLLoader = null;
         var url:String = param1;
         progressHandler = function(param1:ProgressEvent):void
         {
            if(!app.lp)
            {
               app.addLoadProgressBox("Loading project...");
            }
            app.lp.setProgress(param1.bytesLoaded / param1.bytesTotal);
            app.lp.setInfo(param1.bytesLoaded + " " + Translator.map("of") + " " + param1.bytesTotal + " " + Translator.map("bytes loaded"));
         };
         completeHandler = function(param1:Event):void
         {
            app.lp.setTitle("Installing...");
            app.oldWebsiteURL = url;
            app.runtime.installProjectFromData(loader.data);
         };
         app.runtime.stopAll();
         app.runtime.installEmptyProject();
         loader = new URLLoader();
         loader.dataFormat = URLLoaderDataFormat.BINARY;
         loader.addEventListener(ProgressEvent.PROGRESS,progressHandler);
         loader.addEventListener(Event.COMPLETE,completeHandler);
         loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,app.runtime.projectLoadFailed);
         loader.addEventListener(IOErrorEvent.IO_ERROR,app.runtime.projectLoadFailed);
         app.addLoadProgressBox("Loading project...");
         app.loadInProgress = true;
         try
         {
            loader.load(new URLRequest(url));
            return;
         }
         catch(error:*)
         {
            app.runtime.projectLoadFailed();
            loader = null;
            return;
         }
      }
      
      public function uploadProject(param1:ScratchStage, param2:String, param3:Boolean, param4:Function) : void
      {
         var projectJSON:String = null;
         var projectDataSaved:Boolean = false;
         var info:String = null;
         var allAssetsUploaded:Function = null;
         var projectSaved:Function = null;
         var timerTask:Function = null;
         var proj:ScratchStage = param1;
         var projectID:String = param2;
         var createNew:Boolean = param3;
         var onSuccess:Function = param4;
         allAssetsUploaded = function():void
         {
            if(createNew)
            {
               ServerOnline.getInstance().createProject(projectSaved,app.projectName(),projectJSON,projectID);
            }
            else
            {
               ServerOnline.getInstance().setProject(projectID,projectJSON,projectSaved);
            }
         };
         projectSaved = function(param1:String):void
         {
            if(didUploadSucceed(param1))
            {
               projectDataSaved = true;
               app.removeLoadProgressBox();
               proj.clearPenLayer();
               (app as ScratchOnline).setSaveStatus("Saved");
               onSuccess(param1);
            }
            else
            {
               app.logMessage("Project save failed.",addCallServerErrorInfo({
                  "response":param1,
                  "data":projectJSON
               }));
               app.removeLoadProgressBox();
               ScratchOnline.app.saveFailed();
            }
         };
         timerTask = function():void
         {
            if(projectDataSaved)
            {
               return;
            }
            if(app.lp)
            {
               info = info + "*";
               if(info.length > 10)
               {
                  info = "*";
               }
               app.lp.setInfo(info);
               setTimeout(timerTask,500);
            }
         };
         delete proj.info.penTrails;
         proj.savePenLayer();
         proj.updateInfo();
         recordImagesAndSounds(proj.allObjects(),true);
         var hadProjectID:Boolean = projectID && projectID.length > 0;
         createNew = createNew || !hadProjectID;
         projectJSON = JSON.stringify(proj);
         projectDataSaved = false;
         info = "*";
         ScratchOnline.app.setSaveStatus("Saving...");
         if(images.length + sounds.length > 0)
         {
            app.addLoadProgressBox("Saving changes...");
         }
         this.uploadImagesAndSounds(allAssetsUploaded);
         timerTask();
      }
      
      public function uploadSprite(param1:ScratchSprite, param2:Function) : void
      {
         var spriteJSONSaved:Function = null;
         var allAssetsUploaded:Function = null;
         var assetsSaved:Boolean = false;
         var jsonSaved:Boolean = false;
         var md5:String = null;
         var spr:ScratchSprite = param1;
         var onSuccess:Function = param2;
         spriteJSONSaved = function():void
         {
            jsonSaved = true;
            checkDone();
         };
         allAssetsUploaded = function():void
         {
            assetsSaved = true;
            checkDone();
         };
         var checkDone:Function = function():void
         {
            if(jsonSaved && assetsSaved)
            {
               app.removeLoadProgressBox();
               onSuccess(md5 + ".json");
            }
         };
         app.addLoadProgressBox("Uploading sprite...");
         recordImagesAndSounds([spr],true);
         this.uploadImagesAndSounds(allAssetsUploaded);
         var jsonData:ByteArray = new ByteArray();
         jsonData.writeUTFBytes(JSON.stringify(spr));
         md5 = MD5.hashBytes(jsonData);
         this.uploadAsset(md5,".json",jsonData,spriteJSONSaved);
      }
      
      private function uploadImagesAndSounds(param1:Function) : void
      {
         var assetUploadDone:Function = null;
         var i:int = 0;
         var md5:String = null;
         var data:ByteArray = null;
         var ext:String = null;
         var totalAssets:int = 0;
         var uploaded:int = 0;
         var whenDone:Function = param1;
         assetUploadDone = function():void
         {
            uploaded++;
            if(app.lp)
            {
               app.lp.setProgress(uploaded / totalAssets);
               app.lp.setInfo(uploaded + " of " + totalAssets + " assets uploaded");
            }
            if(uploaded == totalAssets)
            {
               whenDone();
            }
         };
         totalAssets = images.length + sounds.length;
         if(totalAssets == 0)
         {
            whenDone();
         }
         uploaded = 0;
         i = 0;
         while(i < images.length)
         {
            md5 = images[i][0];
            data = images[i][1];
            ext = ScratchCostume.fileExtension(data);
            this.uploadAsset(md5,ext,data,assetUploadDone);
            i++;
         }
         i = 0;
         while(i < sounds.length)
         {
            md5 = sounds[i][0];
            data = sounds[i][1];
            this.uploadAsset(md5,".wav",data,assetUploadDone);
            i++;
         }
      }
      
      public function uploadAsset(param1:String, param2:String, param3:ByteArray, param4:Function) : void
      {
         var uploadDone:Function = null;
         var md5:String = param1;
         var dotExt:String = param2;
         var data:ByteArray = param3;
         var whenDone:Function = param4;
         uploadDone = function(param1:String):void
         {
            if(didUploadSucceed(param1,md5))
            {
               recordServerAsset(md5);
               whenDone();
            }
            else
            {
               app.removeLoadProgressBox();
               ScratchOnline.app.saveFailed();
            }
         };
         if(data.length == 0)
         {
            app.log(LogLevel.WARNING,"Skipping upload of empty asset",{
               "md5":md5,
               "dotExt":dotExt
            });
            whenDone();
            return;
         }
         if(md5.indexOf(".") < 0)
         {
            md5 = md5 + dotExt;
         }
         ServerOnline.getInstance().setAsset(md5,data,uploadDone);
      }
      
      private function didUploadSucceed(param1:String, param2:String = "") : Boolean
      {
         var _loc3_:* = false;
         var _loc4_:* = undefined;
         if(param1)
         {
            if(param1 == param2)
            {
               return true;
            }
            if(param1 == "true")
            {
               return true;
            }
            _loc3_ = param1.indexOf("<html>") > -1;
            _loc4_ = {};
            try
            {
               _loc4_ = JSON.parse(param1);
            }
            catch(e:*)
            {
            }
            if(_loc4_.status == "ok")
            {
               return true;
            }
            if(_loc4_.status == "unauthorized" || _loc3_)
            {
               (app as ScratchOnline).setUserFromJS("");
               return false;
            }
         }
         return false;
      }
      
      public function fetchProject(param1:String, param2:String, param3:String = null) : void
      {
         var whenDone:Function = null;
         var retried:Boolean = false;
         var projectOwner:String = param1;
         var projectID:String = param2;
         var cacheBuster:String = param3;
         whenDone = function(param1:ByteArray):void
         {
            var host:String = null;
            var i:int = 0;
            var info:Object = null;
            var projectData:ByteArray = param1;
            if(projectData && projectData.length > 50)
            {
               if(ObjReader.isOldProject(projectData))
               {
                  app.oldWebsiteURL = ServerOnline.getInstance().projectURL(projectID);
                  app.lp.setTitle("Installing...");
                  app.runtime.installProjectFromData(projectData);
               }
               else if(isNewProject(projectData))
               {
                  app.lp.setTitle("Installing...");
                  app.runtime.installProjectFromData(projectData);
               }
               else
               {
                  app.saveForRevert(projectData,false,true);
                  try
                  {
                     downloadProjectAssets(projectData);
                  }
                  catch(e:*)
                  {
                     Scratch.app.removeLoadProgressBox();
                     if(e is Error)
                     {
                        Scratch.app.logException(e);
                     }
                     else
                     {
                        Scratch.app.logMessage(e);
                     }
                     Scratch.app.loadProjectFailed();
                  }
               }
            }
            else if(projectID.length < 8)
            {
               host = !!Scratch.app.jsEnabled?ExternalInterface.call("window.document.location.host.toString"):"scratch.mit.edu";
               i = host.indexOf(":");
               if(i > -1)
               {
                  host = host.slice(0,i);
               }
               app.oldWebsiteURL = ScratchOnline.app.hostProtocol + "://" + host + "/static/projects/" + projectOwner + "/" + projectID + ".sb";
               fetchOldProjectURL(app.oldWebsiteURL);
            }
            else
            {
               info = ServerOnline.getInstance().callServerErrorInfo;
               if(info && info.errorEvent is SecurityErrorEvent && !retried)
               {
                  retried = true;
                  app.addLoadProgressBox("Retrying...");
                  setTimeout(function():void
                  {
                     app.addLoadProgressBox("Loading project...");
                     ServerOnline.getInstance().getProject(projectID,whenDone,cacheBuster);
                  },2000);
               }
               else
               {
                  app.logMessage("Project load failed. retried=" + retried,addCallServerErrorInfo({}));
                  app.runtime.projectLoadFailed();
               }
            }
         };
         retried = false;
         app.oldWebsiteURL = "";
         app.addLoadProgressBox("Loading project...");
         app.loadInProgress = true;
         ServerOnline.getInstance().getProject(projectID,whenDone,cacheBuster);
      }
      
      private function isNewProject(param1:ByteArray) : Boolean
      {
         if(param1.length < 2)
         {
            return false;
         }
         param1.position = 0;
         var _loc2_:String = param1.readUTFBytes(2);
         param1.position = 0;
         return "PK" == _loc2_;
      }
      
      override public function fetchAsset(param1:String, param2:Function) : URLLoader
      {
         var gotData:Function = null;
         var md5:String = param1;
         var whenDone:Function = param2;
         gotData = function(param1:ByteArray):void
         {
            recordServerAsset(md5);
            whenDone(md5,param1);
         };
         return ServerOnline.getInstance().getAsset(md5,gotData);
      }
      
      override protected function recordedAssetID(param1:String, param2:Object, param3:Boolean) : int
      {
         var _loc4_:int = super.recordedAssetID(param1,param2,param3);
         if(_loc4_ == -2 && param3 && this.serverHasAsset(param1))
         {
            return -1;
         }
         return _loc4_;
      }
      
      override public function decodeProjectFromZipFile(param1:ByteArray) : ScratchStage
      {
         return super.decodeFromZipFile(param1) as ScratchStageOnline;
      }
      
      private function recordServerAsset(param1:String) : void
      {
         serverAssets[param1] = null;
      }
      
      private function serverHasAsset(param1:String) : Boolean
      {
         return param1 in serverAssets;


   }
}

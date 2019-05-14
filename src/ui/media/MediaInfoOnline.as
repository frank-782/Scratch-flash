package ui.media
{
   import flash.display.DisplayObject;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.net.URLLoader;
   import flash.utils.ByteArray;
   import logging.LogLevel;
   import scratch.ScratchCostume;
   import scratch.ScratchObj;
   import svgutils.SVGImporter;
   import ui.parts.BackpackPart;
   import ui.parts.UIPart;
   import util.ServerOnline;
   
   public class MediaInfoOnline extends MediaInfo
   {
       
      
      public var fromBackpack:Boolean;
      
      private var loaders:Array;
      
      public function MediaInfoOnline(param1:*, param2:ScratchObj = null)
      {
         this.loaders = [];
         super(param1,param2);
      }
      
      override public function computeThumbnail() : Boolean
      {
         if(super.computeThumbnail())
         {
            return true;
         }
         var _loc1_:String = fileType(md5);
         if(["gif","png","jpg","jpeg","svg"].indexOf(_loc1_) > -1)
         {
            this.setImageThumbnail(md5);
         }
         else if(_loc1_ == "json")
         {
            this.setSpriteThumbnail();
         }
         else
         {
            return false;
         }
         return true;
      }
      
      override public function objToGrab(param1:MouseEvent) : *
      {
         var _loc2_:MediaInfoOnline = super.objToGrab(param1);
         if(this.getBackpack())
         {
            _loc2_.fromBackpack = true;
         }
         return _loc2_;
      }
      
      private function stopLoading() : void
      {
         var _loc1_:URLLoader = null;
         for each(_loc1_ in this.loaders)
         {
            if(_loc1_)
            {
               _loc1_.close();
            }
         }
         this.loaders = [];
      }
      
      private function setImageThumbnail(param1:String) : void
      {
         var importer:SVGImporter = null;
         var gotSVGData:Function = null;
         var svgImagesLoaded:Function = null;
         var gotImageData:Function = null;
         var imageError:Function = null;
         var imageDecoded:Function = null;
         var md5:String = param1;
         gotSVGData = function(param1:ByteArray):void
         {
            if(param1)
            {
               importer = new SVGImporter(XML(param1));
               importer.loadAllImages(svgImagesLoaded);
            }
            else
            {
               imageError(null);
            }
         };
         svgImagesLoaded = function():void
         {
            var _loc1_:ScratchCostume = new ScratchCostume("",null);
            _loc1_.setSVGRoot(importer.root,false);
            setThumbnailFromCostume(_loc1_);
         };
         gotImageData = function(param1:ByteArray):void
         {
            var _loc2_:Loader = null;
            if(param1)
            {
               _loc2_ = new Loader();
               _loc2_.contentLoaderInfo.addEventListener(Event.COMPLETE,imageDecoded);
               _loc2_.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,imageError);
               _loc2_.loadBytes(param1);
            }
            else
            {
               imageError(null);
            }
         };
         imageError = function(param1:IOErrorEvent):void
         {
            Scratch.app.log(LogLevel.WARNING,"MediaInfoOnline failed to set thumbnail",{"md5":md5});
         };
         imageDecoded = function(param1:Event):void
         {
            var _loc2_:ScratchCostume = new ScratchCostume("",param1.target.content.bitmapData,ScratchCostume.kCalculateCenter,ScratchCostume.kCalculateCenter,bitmapResolution);
            setThumbnailFromCostume(_loc2_);
         };
         this.loaders.push(ServerOnline.getInstance().getAsset(md5,fileType(md5) == "svg"?gotSVGData:gotImageData));
      }
      
      private function setThumbnailFromCostume(param1:ScratchCostume) : void
      {
         var _loc2_:int = param1.width();
         isBackdrop = _loc2_ == 480 || _loc2_ == 960;
         setThumbnailBM(param1.thumbnail(thumbnailWidth,thumbnailHeight,isBackdrop));
         if(forBackpack)
         {
            updateLabelAndInfo(forBackpack);
         }
      }
      
      private function setSpriteThumbnail() : void
      {
         var gotJSONData:Function = null;
         gotJSONData = function(param1:String):void
         {
            var _loc3_:Array = null;
            var _loc4_:Object = null;
            var _loc5_:String = null;
            if(!param1)
            {
               return;
            }
            var _loc2_:Object = JSON.parse(param1);
            if(_loc2_.objName is String)
            {
               setInfo(_loc2_.objName);
            }
            if(_loc2_.costumes is Array && _loc2_.currentCostumeIndex is Number)
            {
               _loc3_ = _loc2_.costumes;
               _loc4_ = _loc3_[Math.round(_loc2_.currentCostumeIndex) % _loc3_.length];
               _loc5_ = !!_loc4_?_loc4_.baseLayerMD5:null;
               if(_loc5_)
               {
                  setImageThumbnail(_loc5_);
               }
            }
         };
         this.loaders.push(ServerOnline.getInstance().getAsset(md5,gotJSONData));
      }
      
      override protected function deleteMe(param1:* = null) : void
      {
         this.stopLoading();
         var _loc2_:BackpackPart = this.getBackpack() as BackpackPart;
         if(_loc2_)
         {
            Scratch.app.runtime.recordForUndelete(this,0,0,0,"backpack");
            _loc2_.deleteItem(this);
         }
         else
         {
            super.deleteMe(param1);
         }
      }
      
      override protected function getBackpack() : UIPart
      {
         var _loc1_:DisplayObject = parent;
         while(_loc1_ != null)
         {
            if(_loc1_ is BackpackPart)
            {
               return _loc1_ as BackpackPart;
            }
            _loc1_ = _loc1_.parent;
         }
         return null;
      }
   }
}

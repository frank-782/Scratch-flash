package util
{
   import blocks.Block;
   import flash.display.DisplayObject;
   import flash.events.Event;
   import flash.geom.Rectangle;
   import flash.net.FileReference;
   import flash.utils.ByteArray;
   import logging.LogLevel;
   import scratch.ScratchCostume;
   import scratch.ScratchObj;
   import scratch.ScratchSound;
   import scratch.ScratchSprite;
   import uiwidgets.DialogBox;
   
   public class MediaLibBuilder
   {
      
      private static var processed:Array;
      
      private static var result:String;
       
      
      public function MediaLibBuilder()
      {
         super();
      }
      
      public static function exportMedia() : void
      {
         var saved:Function = null;
         saved = function():void
         {
            var _loc1_:ScratchCostume = null;
            var _loc2_:ScratchObj = null;
            var _loc3_:ScratchSound = null;
            for each(_loc1_ in Scratch.app.stagePane.costumes)
            {
               addCostume(_loc1_,"backdrop");
            }
            for each(_loc2_ in Scratch.app.stagePane.sprites())
            {
               for each(_loc1_ in _loc2_.costumes)
               {
                  addCostume(_loc1_,"costume");
               }
            }
            for each(_loc2_ in Scratch.app.stagePane.allObjects())
            {
               for each(_loc3_ in _loc2_.sounds)
               {
                  addSound(_loc3_);
               }
            }
            finish();
         };
         start();
         ScratchOnline.app.setSaveNeeded();
         ScratchOnline.app.saveNow(true,saved);
      }
      
      public static function exportSprites() : void
      {
         var sprites:Array = null;
         var spr:ScratchSprite = null;
         var uploadSprite:Function = function(param1:ScratchSprite):void
         {
            var spriteSaved:Function = null;
            var spr:ScratchSprite = param1;
            spriteSaved = function(param1:String):void
            {
               addSprite(spr,param1);
               if(++uploadCount == sprites.length)
               {
                  finish();
               }
            };
            new ProjectIOOnline(ScratchOnline.app).uploadSprite(spr.copyToShare(),spriteSaved);
         };
         start();
         var uploadCount:int = 0;
         sprites = Scratch.app.stagePane.sprites();
         for each(spr in sprites)
         {
            uploadSprite(spr);
         }
      }
      
      public static function checkJSONFile() : void
      {
         var fileLoaded:Function = null;
         fileLoaded = function(param1:Event):void
         {
            var _loc3_:Array = null;
            var _loc4_:String = null;
            var _loc2_:ByteArray = FileReference(param1.target).data;
            try
            {
               _loc4_ = _loc2_.readUTFBytes(_loc2_.length);
//               _loc3_ = JSON.parse(_loc4_) as Array;
            }
            catch(e:*)
            {
            }
            if(_loc3_)
            {
               DialogBox.notify("Success!","JSON parsed. " + _loc3_.length + " items",Scratch.app.stage);
            }
            else
            {
               DialogBox.notify("Error","Bad JSON file. Missing comma?",Scratch.app.stage);
            }
         };
         Scratch.loadSingleFile(fileLoaded);
      }
      
      private static function addCostume(param1:ScratchCostume, param2:String) : void
      {
         var _loc3_:String = param1.baseLayerMD5;
         if(processed.indexOf(_loc3_) != -1)
         {
            return;
         }
         processed.push(_loc3_);
         var _loc4_:String = "  {";
         _loc4_ = _loc4_ + pair("name",param1.costumeName);
         _loc4_ = _loc4_ + pair("md5",_loc3_);
         _loc4_ = _loc4_ + pair("type",param2);
         _loc4_ = _loc4_ + pair("tags",[]);
         _loc4_ = _loc4_ + pair("info",costumeWidthHeight(param1),true);
         result = result + _loc4_;
      }
      
      private static function costumeWidthHeight(param1:ScratchCostume) : Array
      {
         var _loc2_:DisplayObject = param1.displayObj();
         var _loc3_:Rectangle = _loc2_.getBounds(_loc2_);
         return [Math.ceil(_loc3_.width),Math.ceil(_loc3_.height)];
      }
      
      private static function addSound(param1:ScratchSound) : void
      {
         var _loc2_:String = param1.md5;
         if(processed.indexOf(_loc2_) != -1)
         {
            return;
         }
         processed.push(_loc2_);
         var _loc3_:Number = Math.round(param1.sampleCount * 1000 / param1.rate) / 1000;
         var _loc4_:String = "  {";
         _loc4_ = _loc4_ + pair("name",param1.soundName);
         _loc4_ = _loc4_ + pair("md5",_loc2_);
         _loc4_ = _loc4_ + pair("type","sound");
         _loc4_ = _loc4_ + pair("tags",[]);
         _loc4_ = _loc4_ + pair("info",[_loc3_],true);
         result = result + _loc4_;
      }
      
      private static function addSprite(param1:ScratchSprite, param2:String) : void
      {
         if(processed.indexOf(param2) != -1)
         {
            return;
         }
         processed.push(param2);
         var _loc3_:String = "  {";
         _loc3_ = _loc3_ + pair("name",param1.objName);
         _loc3_ = _loc3_ + pair("md5",param2);
         _loc3_ = _loc3_ + pair("type","sprite");
         _loc3_ = _loc3_ + pair("tags",[]);
         _loc3_ = _loc3_ + pair("info",[countScripts(param1),param1.costumes.length,param1.sounds.length],true);
         result = result + _loc3_;
      }
      
      private static function countScripts(param1:ScratchSprite) : int
      {
         var _loc2_:int = 0;
         var _loc3_:Block = null;
         for each(_loc3_ in param1.scripts)
         {
            if(_loc3_.isHat)
            {
               _loc2_++;
            }
         }
         return _loc2_;
      }
      
      private static function start() : void
      {
         result = "[\n";
         processed = [];
      }
      
      private static function finish() : void
      {
         if(result.length < 5)
         {
            result = "[]";
         }
         else
         {
            result = result.substring(0,result.length - 2) + "\n]\n";
         }
         Scratch.app.log(LogLevel.INFO,result);
      }
      
      private static function pair(param1:String, param2:*, param3:Boolean = false) : String
      {
//         return "\"" + param1 + "\": " + JSON.stringify(param2) + (!!param3?"},\n":", ");
      }
   }
}

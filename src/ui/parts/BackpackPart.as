package ui.parts
{
   import blocks.Block;
   import blocks.BlockIO;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.net.SharedObject;
   import flash.text.TextField;
   import flash.utils.ByteArray;
   import scratch.ScratchCostume;
   import scratch.ScratchSound;
   import scratch.ScratchSprite;
   import translation.Translator;
   import ui.media.MediaInfo;
   import ui.media.MediaInfoOnline;
   import uiwidgets.ScrollFrame;
   import uiwidgets.ScrollFrameContents;
   import util.Base64Encoder;
   import util.CachedTimer;
   import util.ProjectIOOnline;
   import util.ServerOnline;
   import util.Transition;
   
   public class BackpackPart extends UIPart
   {
      
      public static var localAssets:Object = {};
       
      
      public const fullHeight:int = 135;
      
      public const closedHeight:int = 17;
      
      public var openAmount:int = 17;
      
      private const backpackBarH:int = 20;
      
      private const checkInterval:uint = 3000;
      
      private var shape:Shape;
      
      private var title:TextField;
      
      private var arrow:Shape;
      
      private var contentsFrame:ScrollFrame;
      
      private var contents:ScrollFrameContents;
      
      private var animationRunning:Boolean;
      
      private var lastThumbnailCheckTime:uint;
      
      private var onlineApp:ScratchOnline;
      
      private const disableLocalStorage:Boolean = true;
      
      public function BackpackPart(param1:ScratchOnline)
      {
         super();
         this.app = this.onlineApp = param1;
         addChild(this.shape = new Shape());
         addChild(this.title = makeLabel("",CSS.titleFormat));
         addChild(this.arrow = new Shape());
         this.addContentsPane();
         addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown);
         this.updateTranslation();
      }
      
      public static function strings() : Array
      {
         return ["Backpack"];
      }
      
      public function updateTranslation() : void
      {
         this.title.text = Translator.map("Backpack");
      }
      
      public function loadBackpack() : void
      {
         this.fetchInitialContents();
      }
      
      public function setWidthHeight(param1:int, param2:int) : void
      {
         this.w = param1;
         this.h = param2;
         var _loc3_:Graphics = this.shape.graphics;
         _loc3_.clear();
         drawTopBar(_loc3_,CSS.titleBarColors,getTopBarPath(param1,this.backpackBarH),param1,this.backpackBarH);
         if(this.openAmount > this.closedHeight)
         {
            this.drawArrowDown();
         }
         else
         {
            this.drawArrowUp();
         }
         _loc3_.lineStyle(1,CSS.borderColor);
         _loc3_.drawRect(0,this.backpackBarH,param1,param2 - this.backpackBarH);
         this.fixLayout();
      }
      
      private function fixLayout() : void
      {
         this.title.x = 16;
         this.title.y = -1;
         this.arrow.x = (w - this.arrow.width) / 2;
         this.arrow.y = 5;
         this.contentsFrame.x = 1;
         this.contentsFrame.y = this.backpackBarH + 1;
         this.contentsFrame.setWidthHeight(w - 1,h - this.contentsFrame.y);
      }
      
      private function drawArrowUp() : void
      {
         var _loc1_:Graphics = this.arrow.graphics;
         _loc1_.clear();
         _loc1_.beginFill(CSS.arrowColor);
         _loc1_.moveTo(0,8);
         _loc1_.lineTo(10,8);
         _loc1_.lineTo(5,0);
         _loc1_.endFill();
      }
      
      private function drawArrowDown() : void
      {
         var _loc1_:Graphics = this.arrow.graphics;
         _loc1_.clear();
         _loc1_.beginFill(CSS.arrowColor);
         _loc1_.moveTo(0,2);
         _loc1_.lineTo(10,2);
         _loc1_.lineTo(5,10);
         _loc1_.endFill();
      }
      
      private function addContentsPane() : void
      {
         this.contents = new ScrollFrameContents();
         this.contents.color = CSS.panelColor;
         this.contentsFrame = new ScrollFrame();
         this.contentsFrame.setContents(this.contents);
         addChild(this.contentsFrame);
      }
      
      public function handleDrop(param1:*) : Boolean
      {
         var _loc2_:MediaInfoOnline = null;
         var _loc3_:ScratchSprite = null;
         if(param1 is MediaInfo)
         {
            this.insertAndSave(param1);
            return true;
         }
         if(param1 is Block)
         {
            _loc2_ = new MediaInfoOnline(param1);
            _loc2_.x = param1.x;
            this.insertAndSave(_loc2_);
            return false;
         }
         if(param1 is ScratchSprite)
         {
            _loc3_ = param1.duplicate();
            if(this.onlineApp.stagePane.scaleX != 1)
            {
               _loc3_.scaleX = _loc3_.scaleY = _loc3_.scaleX / this.onlineApp.stagePane.scaleX;
            }
            this.insertAndSave(new MediaInfoOnline(_loc3_));
            return false;
         }
         return false;
      }
      
      public function insertAndSave(param1:MediaInfoOnline) : void
      {
         var _loc2_:Boolean = param1.fromBackpack;
         if(param1.owner)
         {
            if(param1.mycostume)
            {
               param1.mycostume = param1.mycostume.duplicate();
            }
            if(param1.mysound)
            {
               param1.mysound = param1.mysound.duplicate();
            }
         }
         param1.owner = null;
         param1.fromBackpack = true;
         param1.updateLabelAndInfo(true);
         param1.computeThumbnail();
         this.insertItem(param1);
         if(param1.mysprite)
         {
            this.saveSpriteToServer(param1);
         }
         this.saveToServer();
         if(this.openAmount < this.fullHeight)
         {
            this.toggleOpenClose();
         }
         this.computeMD5IfNeeded(param1);
         ServerOnline.getInstance().logAddItemToBackpack(util.JSON.stringify({
            "source":ScratchOnline.app.projectID,
            "wasAlreadyInBackPack":_loc2_,
            "item":param1.backpackRecord()
         }));
      }
      
      private function saveSpriteToServer(param1:MediaInfo) : void
      {
         var uploadDone:Function = null;
         var item:MediaInfo = param1;
         uploadDone = function(param1:String):void
         {
            item.md5 = param1;
            saveToServer();
         };
         new ProjectIOOnline(this.onlineApp).uploadSprite(item.mysprite.copyToShare(),uploadDone);
      }
      
      private function fetchInitialContents() : void
      {
         var gotBackpack:Function = null;
         gotBackpack = function(param1:String):void
         {
            removeAllItems();
            if(!param1)
            {
               return;
            }
            var _loc2_:Array = JSON.parse(param1) as Array;
            if(!_loc2_)
            {
               return;
            }
            addAllItems(_loc2_);
            fixItemLayout();
         };
         if(this.onlineApp.isLoggedIn())
         {
            ServerOnline.getInstance().getBackpack(this.onlineApp.userName,gotBackpack);
         }
         else
         {
            this.readFromLocalStorage();
         }
      }
      
      private function fetchNewItemsFromServer(param1:Function) : void
      {
         var gotBackpack:Function = null;
         var whenDone:Function = param1;
         gotBackpack = function(param1:String):void
         {
            var _loc2_:Array = null;
            var _loc3_:Array = null;
            var _loc4_:MediaInfo = null;
            var _loc5_:Array = null;
            var _loc6_:Object = null;
            if(param1)
            {
               _loc2_ = JSON.parse(param1) as Array;
               if(_loc2_ && _loc2_.length > 0)
               {
                  _loc3_ = [];
                  for each(_loc4_ in allItems())
                  {
                     _loc3_.push(_loc4_.md5);
                  }
                  _loc5_ = [];
                  for each(_loc6_ in _loc2_)
                  {
                     if(_loc3_.indexOf(_loc6_.md5) < 0)
                     {
                        _loc5_.push(_loc6_);
                     }
                  }
                  addAllItems(_loc5_);
               }
            }
            if(whenDone != null)
            {
               whenDone();
            }
         };
         ServerOnline.getInstance().getBackpack(this.onlineApp.userName,gotBackpack);
      }
      
      private function saveToServer() : void
      {
         var done:Function = null;
         var item:MediaInfo = null;
         var elements:Array = null;
         done = function(param1:String):void
         {
         };
         for each(item in this.allItems())
         {
            this.computeMD5IfNeeded(item);
         }
         elements = [];
         for each(item in this.allItems())
         {
            if(item.md5 && item.md5.length > 0 || item.scripts)
            {
               elements.push(item.backpackRecord());
            }
         }
         if(this.onlineApp.isLoggedIn())
         {
            ServerOnline.getInstance().setBackpack(util.JSON.stringify(elements),this.onlineApp.userName,done);
         }
         else
         {
            this.saveToLocalStorage(elements);
         }
      }
      
      private function computeMD5IfNeeded(param1:MediaInfo) : void
      {
         var item:MediaInfo = param1;
         var WasEdited:int = -10;
         var count:int = 0;
         var md5Missing:Boolean = !(item.md5 && item.md5.length > 0 || item.scripts);
         if(item.mycostume && (md5Missing || item.mycostume.baseLayerID == WasEdited))
         {
            item.mycostume.prepareToSave();
            item.md5 = item.mycostume.baseLayerMD5;
            count++;
         }
         if(item.mysound && (md5Missing || item.mysound.soundID == WasEdited || item.mysound.format == "squeak"))
         {
            item.mysound.prepareToSave();
            item.md5 = item.mysound.md5;
            new ProjectIOOnline(this.onlineApp).uploadAsset(item.md5,".wav",item.mysound.soundData,function():void
            {
            });
            count++;
         }
         if(count > 0)
         {
            this.onlineApp.setSaveNeeded(true);
         }
      }
      
      private function removeDuplicates() : void
      {
         var _loc2_:MediaInfo = null;
         var _loc1_:Array = [];
         for each(_loc2_ in this.allItems())
         {
            if(_loc2_.md5)
            {
               if(_loc1_.indexOf(_loc2_.md5) < 0)
               {
                  _loc1_.push(_loc2_.md5);
               }
               else
               {
                  this.contents.removeChild(_loc2_);
               }
            }
         }
         this.fixItemLayout();
      }
      
      private function saveToLocalStorage(param1:Array) : void
      {
         var _loc3_:MediaInfo = null;
         var _loc4_:SharedObject = null;
         if(this.disableLocalStorage || !this.onlineApp.isOffline)
         {
            return;
         }
         var _loc2_:Object = {};
         for each(_loc3_ in this.allItems())
         {
            this.recordAssetsIn(_loc3_,_loc2_);
         }
         _loc4_ = SharedObject.getLocal("Scratch");
         _loc4_.data.backpack = util.JSON.stringify(param1);
         _loc4_.data.backpackAssets = _loc2_;
         _loc4_.flush();
      }
      
      private function recordAssetsIn(param1:MediaInfo, param2:Object) : void
      {
         var _loc3_:ScratchCostume = null;
         var _loc4_:ScratchSound = null;
         if(param1.mycostume)
         {
            _loc3_ = param1.mycostume;
            _loc3_.prepareToSave();
            if(_loc3_.baseLayerData)
            {
               param2[_loc3_.baseLayerMD5] = Base64Encoder.encode(_loc3_.baseLayerData);
            }
            else
            {
               this.recordAsset(_loc3_.baseLayerMD5,param2);
            }
         }
         else if(param1.mysound)
         {
            _loc4_ = param1.mysound;
            if(_loc4_.soundData)
            {
               param2[_loc4_.md5] = Base64Encoder.encode(_loc4_.soundData);
            }
            else
            {
               this.recordAsset(_loc4_.md5,param2);
            }
         }
         else
         {
            this.recordAsset(param1.md5,param2);
         }
      }
      
      private function recordAsset(param1:String, param2:Object) : void
      {
         var gotAsset:Function = null;
         var md5:String = param1;
         var dict:Object = param2;
         gotAsset = function(param1:ByteArray):void
         {
            dict[md5] = Base64Encoder.encode(param1);
         };
         ServerOnline.getInstance().getAsset(md5,gotAsset);
      }
      
      private function readFromLocalStorage() : void
      {
         var _loc2_:* = null;
         if(this.disableLocalStorage || !this.onlineApp.isOffline)
         {
            return;
         }
         var _loc1_:SharedObject = SharedObject.getLocal("Scratch");
         if(_loc1_.data.backpackAssets)
         {
            localAssets = {};
            for(_loc2_ in _loc1_.data.backpackAssets)
            {
               localAssets[_loc2_] = Base64Encoder.decode(_loc1_.data.backpackAssets[_loc2_]);
            }
         }
         this.removeAllItems();
         if(_loc1_.data.backpack)
         {
            this.addAllItems(util.JSON.parse(_loc1_.data.backpack) as Array);
         }
      }
      
      public function deleteItem(param1:MediaInfo) : void
      {
         this.contents.removeChild(param1);
         this.onlineApp.runtime.recordForUndelete(param1,0,0,0,"backpack");
         this.saveToServer();
         this.fixItemLayout();
         ServerOnline.getInstance().logDeleteItemFromBackpack(util.JSON.stringify({"item":param1.backpackRecord()}));
      }
      
      private function addAllItems(param1:Array) : void
      {
         var _loc2_:Object = null;
         var _loc3_:MediaInfo = null;
         if(param1.length == 0)
         {
            return;
         }
         for each(_loc2_ in param1)
         {
            if("script" == _loc2_.type)
            {
               if(_loc2_.md5 && !_loc2_.script)
               {
                  _loc2_.script = _loc2_.md5;
                  delete _loc2_.md5;
               }
               if(!_loc2_.scripts)
               {
                  _loc2_.scripts = [];
               }
               if(_loc2_.script is String)
               {
                  _loc2_.scripts.push(BlockIO.stackToArray(BlockIO.stringToStack(_loc2_.script)));
               }
            }
            if(["image","script","sound","sprite"].indexOf(_loc2_.type) >= 0)
            {
               _loc3_ = new MediaInfoOnline(_loc2_);
               _loc3_.updateLabelAndInfo(true);
               _loc3_.computeThumbnail();
               this.contents.addChild(_loc3_);
            }
         }
         this.fixItemLayout();
      }
      
      private function insertItem(param1:MediaInfoOnline) : void
      {
         var _loc2_:int = 0;
         var _loc3_:MediaInfoOnline = null;
         var _loc4_:int = 0;
         for each(_loc3_ in this.allItems())
         {
            if(_loc3_.md5 && _loc3_.md5 == param1.md5)
            {
               this.contents.removeChild(_loc3_);
            }
         }
         _loc4_ = this.contents.globalToLocal(param1.localToGlobal(new Point(0,0))).x;
         _loc2_ = 0;
         while(_loc2_ < this.contents.numChildren)
         {
            if(this.contents.getChildAt(_loc2_).x > _loc4_)
            {
               break;
            }
            _loc2_++;
         }
         param1.addDeleteButton();
         param1.fromBackpack = true;
         this.contents.addChildAt(param1,_loc2_);
         this.fixItemLayout();
      }
      
      private function allItems() : Array
      {
         var _loc3_:MediaInfo = null;
         var _loc1_:Array = [];
         var _loc2_:int = 0;
         while(_loc2_ < this.contents.numChildren)
         {
            _loc3_ = this.contents.getChildAt(_loc2_) as MediaInfo;
            if(_loc3_)
            {
               _loc1_.push(_loc3_);
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      private function removeAllItems() : void
      {
         while(this.contents.numChildren > 0)
         {
            this.contents.removeChildAt(0);
         }
      }
      
      private function fixItemLayout() : void
      {
         var _loc2_:MediaInfo = null;
         var _loc1_:int = 10;
         for each(_loc2_ in this.allItems())
         {
            _loc2_.x = _loc1_;
            _loc2_.y = 2;
            _loc1_ = _loc1_ + (_loc2_.frameWidth + 10);
         }
      }
      
      private function mouseDown(param1:MouseEvent) : void
      {
         var _loc2_:Point = globalToLocal(new Point(param1.stageX,param1.stageY));
         if(_loc2_.y > 0 && _loc2_.y < this.backpackBarH)
         {
            this.toggleOpenClose();
            param1.stopImmediatePropagation();
         }
      }
      
      private function toggleOpenClose() : void
      {
         var setOpenAmount:Function = null;
         var animationDone:Function = null;
         setOpenAmount = function(param1:int):void
         {
            openAmount = param1;
            onlineApp.fixLayout();
         };
         animationDone = function():void
         {
            animationRunning = false;
            if(openAmount == fullHeight)
            {
               addEventListener(Event.ENTER_FRAME,updateThumbnails);
            }
            else
            {
               removeEventListener(Event.ENTER_FRAME,updateThumbnails);
            }
         };
         var backpack:BackpackPart = this;
         if(this.animationRunning)
         {
            return;
         }
         var h:int = this.openAmount < this.fullHeight?int(this.fullHeight):int(this.closedHeight);
         this.animationRunning = true;
         Transition.cubic(setOpenAmount,this.openAmount,h,0.1,animationDone);
      }
      
      private function updateThumbnails(param1:Event) : void
      {
         var _loc2_:MediaInfo = null;
         if(CachedTimer.getCachedTimer() - this.lastThumbnailCheckTime > this.checkInterval)
         {
            for each(_loc2_ in this.allItems())
            {
               _loc2_.updateMediaThumbnail();
            }
            this.lastThumbnailCheckTime = CachedTimer.getCachedTimer();
         }
      }
   }
}

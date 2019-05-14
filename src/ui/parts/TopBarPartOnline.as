package ui.parts
{
   import assets.Resources;
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   import translation.Translator;
   import uiwidgets.IconButton;
   import uiwidgets.Menu;
   import uiwidgets.SimpleTooltips;
   
   public class TopBarPartOnline extends TopBarPart
   {
      
      private static const exclamationIcon:Class = TopBarPartOnline_exclamationIcon;
       
      
      private const saveStatusFormat:TextFormat = new TextFormat(CSS.font,11,CSS.white,false);
      
      private const saveStatusAlertFormat:TextFormat = new TextFormat(CSS.font,12,CSS.white,true);
      
      private var tipsButton:IconButton;
      
      private var aboutButton:IconButton;
      
      private var signInMenu:IconButton;
      
      private var joinButton:IconButton;
      
      private var myStuffButton:IconButton;
      
      private var remixButton:IconButton;
      
      private var projectPageButton:IconButton;
      
      private var shareButton:IconButton;
      
      private var openInScratchButton:IconButton;
      
      private var shareForbiddenFlag:DisplayObject;
      
      private var saveStatus:TextField;
      
      private var transitionNotice:Sprite;
      
      private var websiteButton:IconButton;
      
      public function TopBarPartOnline(param1:Scratch, param2:Boolean)
      {
         super(param1);
         if(param2)
         {
            fileMenu.visible = false;
            editMenu.visible = false;
            this.tipsButton.visible = false;
            this.aboutButton.visible = false;
            this.websiteButton.visible = true && !param1.isMicroworld;
         }
      }
      
      public static function strings() : Array
      {
         if(Scratch.app)
         {
            ScratchOnline.app.signInPressed(Menu.dummyButton());
         }
         return ["Tips","Sign in","See project page","Remix","Share","About","Save a copy of this project and add your own ideas."];
      }
      
      override protected function addButtons() : void
      {
         var _loc1_:int = 0;
         super.addButtons();
         if(!app.isExtensionDevMode)
         {
            this.addLogo();
         }
         this.addMyStuffButton();
         this.addProjectButton();
         this.addRemixButton();
         this.addShareButton();
         this.addSaveStatus();
         this.addEmbeddedEditorButton();
         this.addOpenInScratchButton();
         if(app.isMicroworld)
         {
            _loc1_ = 0;
            while(_loc1_ < this.numChildren)
            {
               this.getChildAt(_loc1_).visible = false;
               _loc1_++;
            }
         }
      }
      
      override protected function removeTextButtons() : void
      {
         super.removeTextButtons();
         if(this.tipsButton.parent)
         {
            removeChild(this.tipsButton);
            removeChild(this.aboutButton);
            removeChild(this.signInMenu);
            removeChild(this.joinButton);
            removeChild(this.projectPageButton);
            removeChild(this.remixButton);
            removeChild(this.shareButton);
         }
      }
      
      override public function updateTranslation() : void
      {
         super.updateTranslation();
         this.addProjectButton();
         this.addRemixButton();
         this.addShareButton();
         this.refresh();
      }
      
      override protected function fixLogoLayout() : int
      {
         var _loc1_:int = 0;
         if(app.isExtensionDevMode)
         {
            return super.fixLogoLayout();
         }
         _loc1_ = 0;
         if(logoButton)
         {
            logoButton.x = _loc1_;
            logoButton.y = 2;
            _loc1_ = _loc1_ + (logoButton.width + 9);
         }
         return _loc1_;
      }
      
      override protected function fixLayout() : void
      {
         super.fixLayout();
         var _loc1_:int = editMenu.x + editMenu.width;
         var _loc2_:int = editMenu.y;
         if(this.tipsButton.visible)
         {
            _loc1_ = _loc1_ + (buttonSpace + this.tipsButton.width);
            this.tipsButton.x = _loc1_ - this.tipsButton.width;
            this.tipsButton.y = _loc2_;
         }
         if(this.aboutButton.visible)
         {
            _loc1_ = _loc1_ + (buttonSpace + this.aboutButton.width);
            this.aboutButton.x = _loc1_ - this.aboutButton.width;
            this.aboutButton.y = _loc2_;
         }
         _loc1_ = w;
         if(this.websiteButton.visible)
         {
            _loc1_ = _loc1_ - (this.websiteButton.width + 3);
            this.websiteButton.x = _loc1_;
            this.websiteButton.y = _loc2_ - 2;
         }
         if(this.signInMenu.visible)
         {
            _loc1_ = _loc1_ - (this.signInMenu.width + 8);
            this.signInMenu.x = _loc1_;
            this.signInMenu.y = _loc2_;
         }
         if(this.myStuffButton.visible)
         {
            _loc1_ = _loc1_ - (this.myStuffButton.width + 8);
            this.myStuffButton.x = _loc1_;
            this.myStuffButton.y = _loc2_;
         }
         if(this.joinButton.visible)
         {
            _loc1_ = _loc1_ - (this.joinButton.width + 8);
            this.joinButton.x = _loc1_;
            this.joinButton.y = _loc2_;
         }
         _loc1_ = w;
         _loc2_ = h + 5;
         if(this.projectPageButton.visible)
         {
            _loc1_ = _loc1_ - (this.projectPageButton.width + 5);
            this.projectPageButton.x = _loc1_;
            this.projectPageButton.y = _loc2_;
         }
         if(this.remixButton.visible)
         {
            _loc1_ = _loc1_ - (this.remixButton.width + 5);
            this.remixButton.x = _loc1_;
            this.remixButton.y = _loc2_;
         }
         if(this.shareButton.visible)
         {
            _loc1_ = _loc1_ - (this.shareButton.width + 5);
            this.shareButton.x = _loc1_;
            this.shareButton.y = _loc2_;
            this.shareForbiddenFlag.x = this.shareButton.x + this.shareButton.width - this.shareForbiddenFlag.width * 0.75;
            this.shareForbiddenFlag.y = this.shareButton.y - this.shareForbiddenFlag.height * 0.25;
         }
         if(app.isMicroworld)
         {
            _loc1_ = _loc1_ - (this.openInScratchButton.width + 5);
            this.openInScratchButton.x = _loc1_;
         }
         this.fixStatusLayout();
      }
      
      override public function refresh() : void
      {
         this.projectPageButton.visible = app.projectID != "" && !app.isMicroworld;
         this.signInMenu.visible = true;
         this.setUserName(!!ScratchOnline.app.isLoggedIn()?ScratchOnline.app.userName:Translator.map("Sign in"));
         if(ScratchOnline.app.isLoggedIn() && app.projectID != "")
         {
            if(app.isMicroworld)
            {
               this.myStuffButton.visible = false;
               this.remixButton.visible = false;
               this.shareButton.visible = false;
               this.signInMenu.visible = false;
               this.projectPageButton.visible = false;
            }
            else
            {
               this.myStuffButton.visible = true;
               this.remixButton.visible = app.projectOwner != ScratchOnline.app.userName;
               this.shareButton.visible = !this.remixButton.visible && app.projectIsPrivate;
            }
         }
         else if(ScratchOnline.app.isEmbedded && !ScratchOnline.app.isMicroworld || app.isOffline)
         {
            this.myStuffButton.visible = false;
            this.remixButton.visible = false;
            this.projectPageButton.visible = false;
            this.shareButton.visible = false;
            this.signInMenu.visible = false;
         }
         else
         {
            this.myStuffButton.visible = false;
            this.remixButton.visible = app.projectID != "" && app.projectOwner != ScratchOnline.app.userName;
            this.shareButton.visible = false;
            this.signInMenu.visible = !app.isMicroworld;
         }
         if(ScratchOnline.app.serverSettings)
         {
            this.shareForbiddenFlag.visible = this.shareButton.visible && !ScratchOnline.app.serverSettings.user_is_social;
         }
         else
         {
            this.shareForbiddenFlag.visible = false;
         }
         this.joinButton.visible = this.signInMenu.visible && !ScratchOnline.app.isLoggedIn();
         this.openInScratchButton.visible = Scratch.app.isMicroworld && ScratchOnline.app.isLoggedIn();
         super.refresh();
      }
      
      private function addLogo() : void
      {
         logoButton = new IconButton(app.logoButtonPressed,"scratchlogo");
         logoButton.isMomentary = true;
         addChild(logoButton);
      }
      
      override protected function addTextButtons() : void
      {
         var aboutClicked:Function = null;
         var showTipsWindow:Function = null;
         aboutClicked = function(param1:*):void
         {
            if(ScratchOnline.app.isEmbedded || app.isOffline)
            {
               navigateToURL(new URLRequest(ScratchOnline.app.hostProtocol + "://scratch.mit.edu/about/"));
            }
            else
            {
               ScratchOnline.app.saveAndRedirectTo("about");
            }
         };
         showTipsWindow = function(param1:*):void
         {
            ScratchOnline.app.showTip("home");
         };
         super.addTextButtons();
         addChild(this.tipsButton = makeMenuButton("Tips",showTipsWindow));
         addChild(this.aboutButton = makeMenuButton("About",aboutClicked));
         addChild(this.signInMenu = makeMenuButton("Sign in",ScratchOnline.app.signInPressed,true));
         addChild(this.joinButton = makeMenuButton("Join Scratch",ScratchOnline.app.joinPressed));
      }
      
      private function addMyStuffButton() : void
      {
         addChild(this.myStuffButton = new IconButton(ScratchOnline.app.myStuffPressed,"myStuff"));
         this.myStuffButton.isMomentary = true;
      }
      
      private function addProjectButton() : void
      {
         this.projectPageButton = new IconButton(ScratchOnline.app.returnToProjectPage,this.makeFlipButtonImg(true),this.makeFlipButtonImg(false));
         this.projectPageButton.isMomentary = true;
         addChild(this.projectPageButton);
      }
      
      private function addRemixButton() : void
      {
         var _loc1_:int = CSS.buttonLabelOverColor;
         this.remixButton = new IconButton(ScratchOnline.app.remixButtonPressed,makeButtonImg("Remix",_loc1_,true),makeButtonImg("Remix",_loc1_,false));
         this.remixButton.isMomentary = true;
         SimpleTooltips.add(this.remixButton,{
            "text":"Save a copy of this project and add your own ideas.",
            "direction":"bottom"
         });
         addChild(this.remixButton);
      }
      
      private function addShareButton() : void
      {
         var _loc1_:int = CSS.topBarColor();
         this.shareButton = new IconButton(ScratchOnline.app.shareButtonPressed,makeButtonImg("Share",_loc1_,true),makeButtonImg("Share",_loc1_,false));
         this.shareButton.isMomentary = true;
         addChild(this.shareButton);
         this.shareForbiddenFlag = new exclamationIcon();
         this.shareForbiddenFlag.visible = false;
         addChild(this.shareForbiddenFlag);
      }
      
      private function addEmbeddedEditorButton() : void
      {
         var showWebsite:Function = null;
         showWebsite = function(param1:IconButton):void
         {
            navigateToURL(new URLRequest("http://scratch.mit.edu"));
         };
         var c:int = CSS.overColor;
         this.websiteButton = new IconButton(showWebsite,makeButtonImg("Go to scratch.mit.edu",c,true),makeButtonImg("Go to scratch.mit.edu",c,false));
         this.websiteButton.isMomentary = true;
         addChild(this.websiteButton);
         this.websiteButton.visible = false;
      }
      
      private function addOpenInScratchButton() : void
      {
         this.openInScratchButton = new IconButton(ScratchOnline.app.openInScratch,this.makeOpenInScratchButtonImg(true),this.makeOpenInScratchButtonImg(false));
         addChild(this.openInScratchButton);
      }
      
      private function makeFlipButtonImg(param1:Boolean) : Sprite
      {
         var _loc7_:Bitmap = null;
         var _loc2_:Sprite = new Sprite();
         var _loc3_:TextField = makeLabel(Translator.map("See project page"),CSS.topBarButtonFormat,2,2);
         _loc3_.textColor = CSS.white;
         _loc2_.addChild(_loc3_);
         var _loc4_:int = _loc3_.textWidth + 44;
         var _loc5_:int = 22;
         var _loc6_:Graphics = _loc2_.graphics;
         _loc6_.clear();
         _loc6_.beginFill(CSS.overColor);
         _loc6_.drawRoundRect(0,0,_loc4_,_loc5_,8,8);
         _loc6_.endFill();
         _loc7_ = Resources.createBmp("projectPageFlip");
         _loc7_.x = 5;
         _loc7_.y = -1;
         _loc2_.addChild(_loc7_);
         _loc3_.x = _loc7_.x + _loc7_.width + 1;
         return _loc2_;
      }
      
      private function makeOpenInScratchButtonImg(param1:Boolean) : Sprite
      {
         var _loc2_:Sprite = null;
         _loc2_ = new Sprite();
         var _loc3_:TextField = makeLabel(Translator.map("Save and open in Scratch"),CSS.topBarButtonFormat,2,2);
         _loc3_.textColor = CSS.white;
         _loc2_.addChild(_loc3_);
         var _loc4_:int = _loc3_.textWidth + 35;
         var _loc5_:int = 22;
         var _loc6_:Graphics = _loc2_.graphics;
         _loc6_.clear();
         _loc6_.beginFill(CSS.overColor);
         _loc6_.drawRoundRect(0,0,_loc4_,_loc5_,8,8);
         _loc6_.endFill();
         _loc3_.x = 5;
         var _loc7_:Bitmap = Resources.createBmp("openInScratch");
         _loc7_.x = _loc3_.width + _loc3_.x + 5;
         _loc7_.y = 11 - _loc7_.height / 2;
         _loc2_.addChild(_loc7_);
         return _loc2_;
      }
      
      private function setUserName(param1:String) : void
      {
         var _loc2_:Sprite = makeButtonLabel(param1,CSS.buttonLabelOverColor,true);
         var _loc3_:Sprite = makeButtonLabel(param1,CSS.white,true);
         this.signInMenu.setImage(_loc2_,_loc3_);
      }
      
      public function setSaveStatus(param1:String, param2:Boolean, param3:Dictionary) : void
      {
         if(param1 == this.saveStatus.text)
         {
            return;
         }
         this.saveStatus.text = Translator.map(param1,param3);
         this.saveStatus.setTextFormat(!!param2?this.saveStatusAlertFormat:this.saveStatusFormat);
         this.saveStatus.alpha = !!param2?Number(1):Number(0.6);
         this.fixStatusLayout();
      }
      
      private function fixStatusLayout() : void
      {
         this.saveStatus.x = this.myStuffButton.x - this.saveStatus.textWidth - 15;
         this.saveStatus.y = 6;
      }
      
      private function addSaveStatus() : void
      {
         addChild(this.saveStatus = makeLabel("",this.saveStatusFormat));
         this.saveStatus.addEventListener(MouseEvent.MOUSE_DOWN,ScratchOnline.app.saveStatusClicked);
      }
      
      public function showTransitionNotice(param1:String) : void
      {
         this.hideTransitionNotice();
         this.transitionNotice = new Sprite();
         var _loc2_:int = app.stage.stageWidth - app.tabsRight() - 11;
         var _loc3_:Graphics = this.transitionNotice.graphics;
         _loc3_.beginFill(16302972);
         _loc3_.drawRect(0,0,_loc2_,22);
         _loc3_.endFill();
         var _loc4_:TextField = makeLabel(Translator.map(param1),CSS.topBarButtonFormat,3,2);
         this.transitionNotice.addChild(_loc4_);
         this.transitionNotice.x = w - _loc2_ - 5;
         this.transitionNotice.y = h + 5;
         addChild(this.transitionNotice);
      }
      
      public function hideTransitionNotice() : void
      {
         if(this.transitionNotice)
         {
            removeChild(this.transitionNotice);
            this.transitionNotice = null;
         }
      }
   }
}

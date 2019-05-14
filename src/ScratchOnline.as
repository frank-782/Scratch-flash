package
{
   import blocks.Block;
   import blocks.BlockIO;
   import by.blooddy.crypto.MD5;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Loader;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.ErrorEvent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.SecurityErrorEvent;
   import flash.external.ExternalInterface;
   import flash.geom.Point;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import flash.system.Security;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.setTimeout;
   import interpreter.InterpreterOnline;
   import interpreter.PersistenceManager;
   import logging.LogEntry;
   import logging.LogLevel;
   import mx.utils.URLUtil;
   import raven.RavenClient;
   import scratch.PaletteBuilder;
   import scratch.PaletteBuilderOnline;
   import scratch.ScratchComment;
   import scratch.ScratchCostume;
   import scratch.ScratchObj;
   import scratch.ScratchRuntimeOnline;
   import scratch.ScratchSound;
   import scratch.ScratchSprite;
   import scratch.ScratchStage;
   import scratch.ScratchStageOnline;
   import translation.TranslatableStrings;
   import translation.Translator;
   import ui.media.MediaInfo;
   import ui.media.MediaInfoOnline;
   import ui.media.MediaLibrary;
   import ui.media.MediaLibraryOnline;
   import ui.media.MediaPane;
   import ui.media.MediaPaneOnline;
   import ui.parts.BackpackPart;
   import ui.parts.ImagesPartOnline;
   import ui.parts.LibraryPart;
   import ui.parts.LibraryPartOnline;
   import ui.parts.ScriptsPartOnline;
   import ui.parts.StagePart;
   import ui.parts.StagePartOnline;
   import ui.parts.TopBarPartOnline;
   import uiwidgets.DialogBox;
   import uiwidgets.IconButton;
   import uiwidgets.Menu;
   import uiwidgets.VariableSettingsOnline;
   import util.Base64Encoder;
   import util.CachedTimer;
   import util.MediaLibBuilder;
   import util.ProjectIOOnline;
   import util.ServerOnline;
   import watchers.ListWatcher;
   
   public class ScratchOnline extends Scratch
   {
      
      public static var app:ScratchOnline;
      
      private static var productionDSN:String = "https://30e9939302d345bda64d0621165f8933@sentry.io/19106";
      
      private static var stagingDSN:String = "https://205d1eb57985495aa26eb4bbb5313358@sentry.io/20103";
       
      
      private var rc:RavenClient;
      
      public var persistenceManager:PersistenceManager;
      
      public var usesPersistentData:Boolean;
      
      public var userName:String = "";
      
      public var persistentDataCount:int = 0;
      
      public var serverSettingsReady:Boolean = true;
      
      public var serverSettings:Object = null;
      
      public var session:Object = null;
      
      public var isEmbedded:Boolean;
      
      private var topBarOnline:TopBarPartOnline;
      
      private var scriptsPartOnline:ScriptsPartOnline;
      
      public var stagePaneOnline:ScratchStageOnline;
      
      private var imagesPartOnline:ImagesPartOnline;
      
      public var backpackPart:BackpackPart;
      
      private var tipsWereOpen:Boolean = false;
      
      private var wasLoggedOut:Boolean = false;
      
      public var serverOnline:ServerOnline;
      
      private var editAfterLoad:Boolean;
      
      private const SENTRY_SEVERITY:int = LogLevel.LEVEL.indexOf(LogLevel.ERROR);
      
      private var remixRequested:Boolean = false;
      
      private var copyRequested:Boolean = false;
      
      private var saveFailDialog:DialogBox;
      
      private var saveTimerContext:Dictionary;
      
      private const MIN_AUTO_SAVE_INTERVAL:int = 120000.0;
      
      private const SAVE_CHECK_INTERVAL:int = 5000.0;
      
      private var autosaveInterval:int = 120000.0;
      
      private var lastCheckTime:int;
      
      private var nextSaveTime:int;
      
      private var lastSaveFailed:Boolean;
      
      private var saveRetryDelay:int;
      
      private var saveFailureTolerance:int = 3;
      
      private var saveInProgress:Boolean;
      
      private var saveStatus:String = "";
      
      private var saveStatusAlert:Boolean = false;
      
      private var originalProjOnServer:Boolean;
      
      public function ScratchOnline()
      {
         this.saveTimerContext = new Dictionary();
         super();
      }
      
      override protected function initialize() : void
      {
         this.rc = new RavenClient(this.getSentryDSN());
         Scratch.app = ScratchOnline.app = this;
         isArmCPU = jsEnabled && ExternalInterface.call("window.navigator.userAgent.toString").indexOf("CrOS arm") > -1;
         server = this.serverOnline = new ServerOnline();
         this.persistenceManager = new PersistenceManager(this);
         this.isEmbedded = this.checkEmbedded();
         super.initialize();
         this.log(LogLevel.INFO,"SWF Initialized",{"version":versionString});
      }
      
      protected function getSentryDSN() : String
      {
         return loaderInfo.url.indexOf("scratch.ly") > -1?stagingDSN:productionDSN;
      }
      
      override protected function initTopBarPart() : void
      {
         topBarPart = this.topBarOnline = new TopBarPartOnline(this,this.isEmbedded);
      }
      
      override protected function initScriptsPart() : void
      {
         scriptsPart = this.scriptsPartOnline = new ScriptsPartOnline(this);
      }
      
      override protected function initImagesPart() : void
      {
         imagesPart = this.imagesPartOnline = new ImagesPartOnline(this);
      }
      
      override protected function initInterpreter() : void
      {
         interp = new InterpreterOnline(this);
      }
      
      override protected function initRuntime() : void
      {
         runtime = new ScratchRuntimeOnline(this,interp);
      }
      
      override protected function initServer() : void
      {
      }
      
      override protected function getStagePart() : StagePart
      {
         return new StagePartOnline(this);
      }
      
      override protected function getLibraryPart() : LibraryPart
      {
         return new LibraryPartOnline(this);
      }
      
      override public function getMediaPane(param1:Scratch, param2:String) : MediaPane
      {
         return new MediaPaneOnline(param1,param2);
      }
      
      override public function getMediaLibrary(param1:String, param2:Function) : MediaLibrary
      {
         return new MediaLibraryOnline(this,param1,param2);
      }
      
      override public function getScratchStage() : ScratchStage
      {
         return new ScratchStageOnline();
      }
      
      override public function strings() : Array
      {
         var _loc1_:Array = ["Account settings","Because you have a new Scratch account, any changes to cloud data won\'t be saved yet. Keep participating on the site you\'ll be able to use cloud data soon!","Can’t find network connection or reach server.","Click \"Save now\" to try again or \"Download\" to save","Copying...","Creating...","Download","Go to My Stuff","My Class","My Classes","My Stuff","Not saved; network or server problem.","Profile","Remixing...","Save as a copy","Saving...","Sign in to save","Sign out","This project uses Cloud data ‒ a feature that is available only to signed in users.","Want to save? Click remix"];
         return super.strings().concat(_loc1_).concat(ProjectIOOnline.strings()).concat(PersistenceManager.strings()).concat(TopBarPartOnline.strings()).concat(VariableSettingsOnline.strings());
      }
      
      override protected function addParts() : void
      {
         super.addParts();
         this.backpackPart = new BackpackPart(this);
         addChild(this.backpackPart);
      }
      
      override protected function startInEditMode() : Boolean
      {
         return super.startInEditMode() || this.isEmbedded || loaderInfo.parameters["project_isNew"] == "true";
      }
      
      override public function presentationModeWasChanged(param1:Boolean) : void
      {
         super.presentationModeWasChanged(param1);
         this.jsSetPresentationMode(param1);
         this.closeTips();
      }
      
      override protected function shouldShowGreenFlag() : Boolean
      {
         return super.shouldShowGreenFlag() || this.isEmbedded;
      }
      
      override public function setEditMode(param1:Boolean) : void
      {
         if(param1 && loadInProgress)
         {
            this.editAfterLoad = true;
            return;
         }
         super.setEditMode(param1);
         if(editMode && !isMicroworld)
         {
            show(this.backpackPart);
         }
         else
         {
            hide(this.backpackPart);
         }
         this.jsSetFlashDragDrop(editMode);
         this.jsCaptureRightClick();
         this.refreshCloudLists();
      }
      
      override protected function updateContentArea(param1:int, param2:int, param3:int, param4:int, param5:int) : void
      {
         this.backpackPart.openAmount = this.isLoggedIn() && this.backpackPart.visible?int(Math.max(this.backpackPart.closedHeight,this.backpackPart.openAmount)):0;
         param4 = param4 - this.backpackPart.openAmount;
         super.updateContentArea(param1,param2,param3,param4,param5);
         this.backpackPart.x = param1;
         this.backpackPart.y = param5 - this.backpackPart.openAmount - 1;
         this.backpackPart.setWidthHeight(param3,this.backpackPart.fullHeight);
      }
      
      override public function createMediaInfo(param1:*, param2:ScratchObj = null) : MediaInfo
      {
         return new MediaInfoOnline(param1,param2);
      }
      
      override public function translationChanged() : void
      {
         super.translationChanged();
         this.backpackPart.updateTranslation();
      }
      
      override protected function canExportInternals() : Boolean
      {
         return !this.isEmbedded;
      }
      
      override protected function addEditMenuItems(param1:*, param2:Menu) : void
      {
         if((param1 as IconButton).lastEvent.shiftKey && this.canExportInternals())
         {
            param2.addLine();
            param2.addItem("Export translation strings: commands",TranslatableStrings.exportCommands);
            param2.addItem("Export translation strings: UI",TranslatableStrings.exportUIStrings);
            param2.addItem("Export help screen names",TranslatableStrings.exportHelpScreenNames);
            param2.addLine();
            param2.addItem("Edit block colors",editBlockColors);
            param2.addLine();
            param2.addItem("MediaLib - media",MediaLibBuilder.exportMedia);
            param2.addItem("MediaLib - sprites",MediaLibBuilder.exportSprites);
            param2.addItem("MediaLib - check JSON file",MediaLibBuilder.checkJSONFile);
         }
      }
      
      public function isScratcher() : Boolean
      {
         return this.isLoggedIn() && this.serverSettings && this.serverSettings.user_groups && this.serverSettings.user_groups.indexOf("Scratchers") > -1;
      }
      
      override public function loadProjectFailed() : void
      {
         super.loadProjectFailed();
         var _loc1_:Shape = new Shape();
         _loc1_.graphics.beginFill(13421772);
         _loc1_.graphics.drawRect(-1000,-1000,10000,10000);
         stage.addChild(_loc1_);
         if(editMode)
         {
            DialogBox.notify("Error!","The project failed to load\nand the Scratch Team has been notified.\nPress OK to leave this page.",stage,false,this.leavePage);
         }
         else
         {
            DialogBox.notify("Error!","The project failed to load\nand the Scratch Team has been notified.",stage,false,this.leavePage);
         }
      }
      
      private function leavePage(param1:*) : void
      {
         var ignore:* = param1;
         ExternalInterface.call("window.eval","document.location.hash = \"player\";");
         setTimeout(function():void
         {
            DialogBox.notify("Error!","The project failed to load\nand the Scratch Team has been notified.",stage,false,leavePage);
         },100);
      }
      
      override public function logException(param1:Error) : void
      {
         this.rc.setExtras();
         this.rc.captureException(param1,null,versionString);
         logger.log(LogLevel.ERROR,param1.toString());
      }
      
      override public function log(param1:String, param2:String, param3:Object = null) : LogEntry
      {
         var _loc4_:LogEntry = super.log(param1,param2,param3);
         if(_loc4_.severity <= this.SENTRY_SEVERITY)
         {
            this.rc.setExtras(param3);
            this.rc.captureMessage(param2,versionString);
         }
         return _loc4_;
      }
      
      public function logImageImported(param1:String, param2:Boolean) : void
      {
         var _loc3_:int = param1.indexOf(".");
         if(_loc3_ > 0)
         {
            param1 = param1.slice(_loc3_).toLowerCase();
         }
         externalCall("JSlogImageAdded",null,Scratch.app.projectID,param1,!param2);
      }
      
      override protected function addFileMenuItems(param1:*, param2:Menu) : void
      {
         var saveNow:Function = null;
         var saveAsACopy:Function = null;
         var goToMyStuff:Function = null;
         var b:* = param1;
         var m:Menu = param2;
         saveNow = function():void
         {
            if(shouldSave())
            {
               saveProject(true);
            }
         };
         saveAsACopy = function():void
         {
            copyRequested = true;
            saveProject(true);
         };
         goToMyStuff = function():void
         {
            saveAndRedirectTo("mystuff");
         };
         if(this.isLoggedIn())
         {
            if(this.canSave())
            {
               m.addItem("Save now",saveNow);
            }
            if(this.userName == projectOwner)
            {
               m.addItem("Save as a copy",saveAsACopy);
            }
            m.addItem("Go to My Stuff",goToMyStuff);
            m.addLine();
         }
         if(this.isLoggedIn() && projectOwner == this.userName)
         {
            if(runtime.recording || runtime.ready >= 0)
            {
               m.addItem("Download to your computer",exportProjectToFile);
               m.addLine();
               m.addItem("Stop Video",runtime.stopVideo);
            }
            else
            {
               m.addItem("Upload from your computer",runtime.selectProjectFile);
               m.addItem("Download to your computer",exportProjectToFile);
               m.addLine();
               m.addItem("Record & Export Video",runtime.exportToVideo);
            }
         }
         else
         {
            m.addItem("Upload from your computer",runtime.selectProjectFile);
            m.addItem("Download to your computer",exportProjectToFile);
            m.addLine();
         }
         if(canUndoRevert())
         {
            m.addItem("Undo Revert",undoRevert);
         }
         else if(canRevert())
         {
            m.addItem("Revert",revertToOriginalProject);
         }
         if(b.lastEvent.shiftKey)
         {
            m.addLine();
            m.addItem("Save Project Summary",saveSummary);
            m.addItem("Show version details",showVersionDetails);
         }
      }
      
      override protected function makeVersionDetailsDialog() : DialogBox
      {
         var _loc1_:DialogBox = super.makeVersionDetailsDialog();
         _loc1_.addField("scratch-flash-online",kGitHashFieldWidth,"6d489c3");
         return _loc1_;
      }
      
      override protected function handleStartupParameters() : void
      {
         var _loc5_:String = null;
         var _loc1_:String = loaderInfo.parameters["project"];
         var _loc2_:String = loaderInfo.parameters["project_id"];
         var _loc3_:String = loaderInfo.parameters["autostart"];
         var _loc4_:ProjectIOOnline = new ProjectIOOnline(this);
         if(_loc1_)
         {
            autostart = true;
            if(_loc3_ != null)
            {
               autostart = _loc3_.toLowerCase() == "true";
            }
            this.serverSettingsReady = true;
            this.setupExternalInterface(true);
            _loc4_.fetchOldProjectURL(_loc1_);
         }
         else if(_loc2_)
         {
            autostart = false;
            if(loaderInfo.parameters["project_isNew"] == "true")
            {
               this.createProjectFromJS(loaderInfo.parameters["project_creator"],_loc2_,loaderInfo.parameters["project_title"]);
            }
            else
            {
               autostart = _loc3_ && _loc3_.toLowerCase() == "true";
               this.projectID = _loc2_;
               projectOwner = loaderInfo.parameters["project_creator"];
               projectIsPrivate = loaderInfo.parameters["project_isPublished"] != "true";
               setProjectName(loaderInfo.parameters["project_title"]);
               _loc5_ = !!loaderInfo.parameters["project_modifiedDate"]?MD5.hash(loaderInfo.parameters["project_modifiedDate"]):null;
               _loc4_.fetchProject(projectOwner,_loc2_,_loc5_);
            }
            this.backpackPart.loadBackpack();
            this.setupExternalInterface(false);
            this.jsCaptureRightClick();
            isSmallPlayer = stage.width < 400;
            jsEditorReady();
         }
         else
         {
            this.setupExternalInterface(false);
            this.jsCaptureRightClick();
            isSmallPlayer = stage.width < 400;
            jsEditorReady();
         }
         if(loaderInfo.parameters["debugOps"] != null && loaderInfo.parameters["debugOpCmd"] != null)
         {
            debugOps = loaderInfo.parameters["debugOps"] == "true";
            debugOpCmd = loaderInfo.parameters["debugOpCmd"];
         }
      }
      
      override protected function step(param1:Event) : void
      {
         super.step(param1);
         if(editMode)
         {
            this.checkForAutoSave();
         }
      }
      
      override public function projectLoaded() : void
      {
         super.projectLoaded();
         this.updateSaveStatus();
         if(this.usesPersistentData)
         {
            if(this.isLoggedIn())
            {
               if(this.serverSettings && this.serverSettings.user_groups)
               {
                  if(this.serverSettings.user_groups.indexOf("Scratchers") > -1)
                  {
                     this.persistenceManager.connect(this.serverSettings.cloud_data_host);
                  }
                  else
                  {
                     this.jsSetProjectBanner("Because you have a new Scratch account, any changes to cloud data won\'t be saved yet. Keep participating on the site you\'ll be able to use cloud data soon!");
                  }
               }
            }
            else
            {
               this.jsSetProjectBanner("This project uses Cloud data ‒ a feature that is available only to signed in users.");
            }
         }
         this.jsReportStats();
         if(!editMode && this.editAfterLoad)
         {
            this.editAfterLoad = false;
            this.setEditMode(true);
         }
      }
      
      public function shareButtonPressed(param1:*) : void
      {
         var saveDone:Function = null;
         var ignore:* = param1;
         saveDone = function():void
         {
            jsShareProject();
            projectIsPrivate = false;
            stagePart.refresh();
            topBarPart.refresh();
         };
         if(runtime.hasUnofficialExtensions())
         {
            DialogBox.notify("Not Allowed to Share","This project uses experimental extensions and cannot be shared on the website.",Scratch.app.stage);
            return;
         }
         if(this.canSave())
         {
            this.saveProject(true,saveDone);
         }
      }
      
      public function returnToProjectPage(param1:*) : void
      {
         var showProjectPage:Function = null;
         var ignore:* = param1;
         showProjectPage = function():void
         {
            jsSetEditMode(false);
         };
         if(this.shouldSave())
         {
            this.saveProject(true,showProjectPage);
         }
         else
         {
            showProjectPage();
         }
      }
      
      public function myStuffPressed(param1:*) : void
      {
         this.saveAndRedirectTo("mystuff");
      }
      
      override public function logoButtonPressed(param1:IconButton) : void
      {
         if(this.isEmbedded || isOffline)
         {
            navigateToURL(new URLRequest(hostProtocol + "://scratch.mit.edu"));
         }
         else
         {
            this.saveAndRedirectTo("home");
         }
      }
      
      public function saveAndRedirectTo(param1:String) : void
      {
         var saveDone:Function = null;
         var where:String = param1;
         saveDone = function():void
         {
            jsRedirectTo(where);
         };
         if(this.shouldSave())
         {
            this.saveProject(true,saveDone);
         }
         else
         {
            this.jsRedirectTo(where);
         }
      }
      
      public function isLoggedIn() : Boolean
      {
         return this.userName != null && this.userName != "" && !this.wasLoggedOut;
      }
      
      public function signInPressed(param1:IconButton) : void
      {
         if(this.isLoggedIn())
         {
            this.showSignInMenu(param1);
         }
         else
         {
            this.jsSignIn("save",this.userName);
         }
      }
      
      public function joinPressed(param1:IconButton) : void
      {
         this.jsJoinScratch("save");
      }
      
      protected function showSignInMenu(param1:IconButton) : void
      {
         var goToProfile:Function = null;
         var goToMyStuff:Function = null;
         var goToMyClasses:Function = null;
         var goToMyClass:Function = null;
         var goToAccountSettings:Function = null;
         var goToLogout:Function = null;
         var menuButton:IconButton = param1;
         goToProfile = function():void
         {
            saveAndRedirectTo("profile");
         };
         goToMyStuff = function():void
         {
            saveAndRedirectTo("mystuff");
         };
         goToMyClasses = function():void
         {
            saveAndRedirectTo("myclasses");
         };
         goToMyClass = function():void
         {
            saveAndRedirectTo("myclass");
         };
         goToAccountSettings = function():void
         {
            saveAndRedirectTo("settings");
         };
         goToLogout = function():void
         {
            if(shouldSave())
            {
               saveProject(true,jsSignOut);
            }
            else
            {
               jsSignOut();
            }
         };
         this.closeTips();
         var m:Menu = new Menu(null,"Sign in",CSS.topBarColor(),28);
         m.addItem("Profile",goToProfile);
         m.addItem("My Stuff",goToMyStuff);
         if(this.session.permissions["educator"])
         {
            m.addItem("My Classes",goToMyClasses);
         }
         if(this.session.permissions["student"])
         {
            m.addItem("My Class",goToMyClass);
         }
         m.addItem("Account settings",goToAccountSettings);
         m.addLine();
         m.addItem("Sign out",goToLogout);
         m.showOnStage(stage,Math.min(menuButton.x,topBarPart.w - m.width - 5),topBarPart.bottom() - 1);
      }
      
      private function getServerSettings() : void
      {
         var gotSettings:Function = null;
         var gotSession:Function = null;
         gotSettings = function(param1:String):void
         {
            serverSettings = !!param1?JSON.parse(param1):{};
            var _loc2_:int = 1000 * int(serverSettings["autosave_interval"]);
            autosaveInterval = Math.max(_loc2_,MIN_AUTO_SAVE_INTERVAL);
            serverOnline.getSession(gotSession);
         };
         gotSession = function(param1:String):void
         {
            session = !!param1?JSON.parse(param1):{};
            session.flags = session.flags || {};
            session.permissions = session.permissions || {};
            session.user = session.user || {};
            topBarOnline.refresh();
            serverSettingsReady = true;
         };
         this.serverSettingsReady = false;
         this.serverOnline.getSettings(gotSettings);
      }
      
      override public function getPaletteBuilder() : PaletteBuilder
      {
         return new PaletteBuilderOnline(this);
      }
      
      public function isCloudDataEnabled() : Boolean
      {
         if(!this.serverSettings)
         {
            return false;
         }
         return this.serverSettings.cloud_data_enabled;
      }
      
      public function isUserStaff() : Boolean
      {
         if(!this.serverSettings)
         {
            return false;
         }
         return this.serverSettings.user_admin;
      }
      
      private function jsReportStats() : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSsetProjectStats",stagePane.scriptCount(),stagePane.spriteCount(),this.usesPersistentData,oldWebsiteURL);
         }
      }
      
      public function getProjectURL() : String
      {
         return this.serverOnline.getProjectURL();
      }
      
      private function checkEmbedded() : Boolean
      {
         if(jsEnabled)
         {
            return ExternalInterface.call("JSeditorIsEmbedded");
         }
         return false;
      }
      
      private function jsCaptureRightClick() : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JScaptureRightClick",true);
         }
      }
      
      public function jsEditTitle() : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSeditTitle",projectName());
         }
      }
      
      private function jsSetEditMode(param1:Boolean) : void
      {
         var _loc2_:Boolean = false;
         if(jsEnabled)
         {
            _loc2_ = ExternalInterface.call("JSsetEditMode",param1);
            if(!_loc2_)
            {
               jsThrowError("Calling JSsetEditMode() failed.");
            }
         }
      }
      
      private function jsIsUniqueTitle(param1:String) : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSisUniqueTitle",param1);
         }
      }
      
      public function jsOpenMediaLibrary(param1:String) : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSopenMediaLibrary",param1);
         }
      }
      
      private function jsSignIn(param1:String = "", param2:String = "") : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSlogin",param1,param2);
         }
      }
      
      private function jsJoinScratch(param1:String = "") : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSjoinScratch",param1);
         }
      }
      
      private function jsSignOut() : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSlogout");
         }
      }
      
      private function jsShareProject() : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSshareProject");
         }
      }
      
      private function jsRedirectTo(param1:String, param2:Boolean = false) : void
      {
         var _loc3_:Object = null;
         if(jsEnabled)
         {
            _loc3_ = {
               "creator":this.userName,
               "id":this.projectID,
               "isPrivate":this.projectIsPrivate,
               "title":this.projectName()
            };
            ExternalInterface.call("JSredirectTo",param1,param2,_loc3_);
         }
      }
      
      private function jsSetFlashDragDrop(param1:Boolean) : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSsetFlashDragDrop",param1);
         }
      }
      
      public function jsSetPresentationMode(param1:Boolean) : void
      {
         var _loc2_:Boolean = false;
         if(jsEnabled)
         {
            _loc2_ = ExternalInterface.call("JSsetPresentationMode",param1);
            if(!_loc2_)
            {
               jsThrowError("Calling JSsetPresentationMode() failed.");
            }
         }
      }
      
      public function openInScratch(param1:IconButton) : void
      {
         if(!ScratchOnline.app.isLoggedIn())
         {
            this.jsSignIn("openInScratch",this.userName);
         }
         else
         {
            ScratchOnline.app.remixProjectFromJS();
         }
      }
      
      public function remixButtonPressed(param1:* = null) : void
      {
         if(!this.isLoggedIn())
         {
            this.jsSignIn("remix",this.userName);
            return;
         }
         ExternalInterface.call("JSremixProject");
      }
      
      public function remixProjectFromJS() : void
      {
         var saveDone:Function = null;
         saveDone = function():void
         {
            projectIsPrivate = true;
            stagePart.refresh();
            topBarPart.refresh();
         };
         if(!loadInProgress)
         {
            this.remixRequested = true;
            this.saveProject(true,saveDone);
         }
      }
      
      public function saveStatusClicked(param1:*) : void
      {
         if(!saveNeeded)
         {
            return;
         }
         if(projectOwner.length > 0 && projectOwner != this.userName)
         {
            this.remixButtonPressed(null);
         }
         else if(!this.isLoggedIn())
         {
            this.jsSignIn("save",this.userName);
         }
         else if(this.shouldSave())
         {
            this.saveProject(true);
         }
      }
      
      public function showSaveFailDialog(param1:Boolean) : void
      {
         var tryAgain:Function = null;
         var show:Boolean = param1;
         tryAgain = function():void
         {
            if(shouldSave())
            {
               saveProject(true);
            }
         };
         if(show == (this.saveFailDialog != null))
         {
            return;
         }
         if(show)
         {
            this.saveFailDialog = new DialogBox();
            this.saveFailDialog.leftJustify = true;
            this.saveFailDialog.addTitle("Project not saved!");
            this.saveFailDialog.addText("Changes not saved yet; network not connecting.\n" + "Trying again in {sec}...\n\n" + "Click \"Save now\" to try again or \"Download\" to save\n" + "a copy of the project file on your computer.");
            this.saveFailDialog.addButton("Save now",tryAgain);
            this.saveFailDialog.addButton("Download",exportProjectToFile);
            this.saveFailDialog.showOnStage(stage);
         }
         else
         {
            this.saveFailDialog.cancel();
            this.saveFailDialog = null;
         }
      }
      
      public function handleExternalLogout() : void
      {
         if(!this.isLoggedIn() || !editMode)
         {
            return;
         }
         this.wasLoggedOut = true;
         this.setSaveNeeded(true);
         this.jsSetProjectBanner("You need to <a href=\"javascript:JSlogin(\'save\', \'" + this.userName + "\')\">sign in</a> as " + this.userName + ". Or you can <a href=\"javascript:JSdownloadProject()\">download your project</a> and save it on your computer.",true);
         this.refreshUserAndProject();
         this.clearSaveInProgress(false);
         this.updateSaveStatus();
      }
      
      public function dropMediaInfo(param1:MediaInfo) : Boolean
      {
         var addSpriteCostumes:Function = null;
         var item:MediaInfo = param1;
         addSpriteCostumes = function(param1:ScratchSprite):void
         {
            var _loc2_:ScratchCostume = null;
            for each(_loc2_ in param1.costumes)
            {
               addCostume(_loc2_.duplicate());
            }
         };
         if(!(item is MediaInfoOnline) || !(item as MediaInfoOnline).fromBackpack)
         {
            return false;
         }
         if(item.objType == "image")
         {
            this.fetchAndAddCostume(item.md5,item.objName,item.objWidth);
         }
         else if(item.objType == "sound")
         {
            this.fetchAndAddSound(item.md5,item.objName);
         }
         else if(item.mycostume)
         {
            addCostume(item.mycostume.duplicate());
         }
         else if(item.mysound)
         {
            addSound(item.mysound.duplicate());
         }
         else if(item.scripts)
         {
            if(!isShowing(scriptsPart as DisplayObject) || !scriptsPane.hitTestPoint(item.x,item.y))
            {
               return false;
            }
            this.addScriptsFromBackpack(item);
         }
         else if(item.mysprite)
         {
            addSpriteCostumes(item.mysprite);
         }
         else if(item.objType == "sprite")
         {
            new ProjectIOOnline(this).fetchSprite(item.md5,addSpriteCostumes);
         }
         return true;
      }
      
      private function addScriptsFromBackpack(param1:MediaInfo) : void
      {
         var _loc4_:* = undefined;
         var _loc5_:DisplayObject = null;
         var _loc2_:Point = new Point(50,50);
         if(isShowing(scriptsPart as DisplayObject))
         {
            _loc2_ = scriptsPane.globalToLocal(new Point(param1.x,param1.y));
         }
         else
         {
            _loc2_ = new Point(50,50);
         }
         var _loc3_:Array = [];
         for each(_loc4_ in param1.scripts)
         {
            _loc5_ = null;
            if(_loc4_ is Block)
            {
               _loc5_ = BlockIO.arrayToStack(BlockIO.stackToArray(_loc4_));
            }
            if(_loc4_ is ScratchComment)
            {
               _loc5_ = ScratchComment.fromArray(_loc4_.toArray());
            }
            if(_loc5_)
            {
               _loc5_.x = _loc2_.x;
               _loc5_.y = _loc2_.y;
               _loc2_.y = _loc2_.y + _loc5_.height;
               _loc3_.push(_loc5_);
               scriptsPane.addChild(_loc5_);
            }
         }
         scriptsPane.updateSize();
         scriptsPane.saveScripts();
         setTab("scripts");
      }
      
      public function fetchAndAddCostume(param1:String, param2:String, param3:int = 0) : void
      {
         new ProjectIOOnline(this).fetchImage(param1,param2,param3,addCostume);
      }
      
      public function fetchAndAddSound(param1:String, param2:String) : void
      {
         new ProjectIOOnline(this).fetchSound(param1,param2,addSound);
      }
      
      private function checkForAutoSave() : void
      {
         if(isOffline)
         {
            return;
         }
         var _loc1_:int = this.nextSaveTime - CachedTimer.getCachedTimer();
         var _loc2_:int = int(Math.max((_loc1_ + 999) / 1000,0));
         if(this.saveTimerContext["sec"] != _loc2_)
         {
            this.saveTimerContext["sec"] = _loc2_;
            this.topBarOnline.setSaveStatus(this.saveStatus,this.saveStatusAlert,this.saveTimerContext);
            if(this.saveFailDialog)
            {
               this.saveFailDialog.updateContext(this.saveTimerContext);
            }
         }
         if(CachedTimer.getCachedTimer() - this.lastCheckTime < 5000)
         {
            return;
         }
         this.lastCheckTime = CachedTimer.getCachedTimer();
         if(saveNeeded && !this.saveInProgress && _loc1_ <= 0 && interp.threadCount() == 0 && this.shouldSave())
         {
            this.saveProject(false);
         }
         else if(!this.lastSaveFailed)
         {
            this.updateSaveStatus();
         }
      }
      
      override public function handleTool(param1:String, param2:MouseEvent) : void
      {
         super.handleTool(param1,param2);
         if(param1 == "help")
         {
            this.showTip("scratchUI");
         }
      }
      
      override public function showTip(param1:String) : void
      {
         if(this.isEmbedded)
         {
            navigateToURL(new URLRequest(hostProtocol + "://scratch.mit.edu/help/"));
         }
         if(jsEnabled)
         {
            ExternalInterface.call("tip_bar_api.open",param1);
         }
      }
      
      override public function closeTips() : void
      {
         if(jsEnabled)
         {
            this.tipsWereOpen = ExternalInterface.call("tip_bar_api.close");
         }
      }
      
      override public function reopenTips() : void
      {
         if(jsEnabled && this.tipsWereOpen)
         {
            ExternalInterface.call("tip_bar_api.open");
            this.tipsWereOpen = false;
         }
      }
      
      override public function tipsWidth() : int
      {
         return !!this.isEmbedded?0:int(tipsBarClosedWidth);
      }
      
      public function getLoadTimeCloudToken() : String
      {
         return loaderInfo.parameters["cloudToken"];
      }
      
      public function getCdnToken() : String
      {
         return loaderInfo.parameters["cdnToken"];
      }
      
      public function jsSetProjectBanner(param1:String, param2:Boolean = false) : void
      {
         if(jsEnabled)
         {
            ExternalInterface.call("JSsetProjectBanner",Translator.map(param1),param2);
         }
      }
      
      override protected function setupExternalInterface(param1:Boolean) : void
      {
         var oldWebsitePlayer:Boolean = param1;
         if(!isOffline)
         {
            Security.allowDomain("scratch.mit.edu");
            Security.allowDomain("cdn.scratch.mit.edu");
            Security.allowDomain("staging.scratch.mit.edu");
            Security.allowDomain("scratch.ly");
            Security.allowDomain("*.scratch.ly");
            Security.allowDomain("github.io");
            Security.allowDomain("localhost");
         }
         super.setupExternalInterface(oldWebsitePlayer);
         if(!jsEnabled)
         {
            return;
         }
         if(oldWebsitePlayer)
         {
            try
            {
               ExternalInterface.addCallback("ASloadProject",this.loadProjectFromJS);
               ExternalInterface.addCallback("ASversion",function():String
               {
                  return versionString;
               });
            }
            catch(error:Error)
            {
            }
         }
         else
         {
            try
            {
               ExternalInterface.addCallback("AScreateProject",this.createProjectFromJS);
               ExternalInterface.addCallback("ASdownload",this.downloadFromJS);
               ExternalInterface.addCallback("ASdropFile",this.addFileFromJS);
               ExternalInterface.addCallback("ASdropURL",this.addURLFromJS);
               ExternalInterface.addCallback("ASisEditMode",function():Boolean
               {
                  return editMode;
               });
               ExternalInterface.addCallback("ASisEmpty",function():Boolean
               {
                  return stagePane.isEmpty();
               });
               ExternalInterface.addCallback("ASisUnchanged",function():Boolean
               {
                  return !saveNeeded && !saveInProgress;
               });
               ExternalInterface.addCallback("ASloadProject",this.loadProjectFromJS);
               ExternalInterface.addCallback("ASdumpRecordThumbnail",this.dumpRecordThumbnailFromJS);
               ExternalInterface.addCallback("ASremixProject",this.remixProjectFromJS);
               ExternalInterface.addCallback("ASrightMouseDown",gh.rightMouseDown);
               ExternalInterface.addCallback("ASshouldSave",this.shouldSave);
               ExternalInterface.addCallback("ASsetEditMode",this.setEditMode);
               ExternalInterface.addCallback("ASsetEmbedMode",this.setSmallPlayerMode);
               ExternalInterface.addCallback("ASsetPresentationMode",setPresentationMode);
               ExternalInterface.addCallback("ASsetLoginUser",this.setUserFromJS);
               ExternalInterface.addCallback("ASsetNewProject",this.setNewProjectFromJS);
               ExternalInterface.addCallback("ASsetShared",this.setSharedFromJS);
               ExternalInterface.addCallback("ASsetTitle",stagePart.setProjectName);
               ExternalInterface.addCallback("ASstartRunning",this.startFromJS);
               ExternalInterface.addCallback("ASstopRunning",this.stopFromJS);
               ExternalInterface.addCallback("ASgetProjectJSON",this.getProjectJSONJS);
               ExternalInterface.addCallback("ASsetBackpack",this.setBackpack);
               ExternalInterface.addCallback("ASversion",function():String
               {
                  return versionString;
               });
               ExternalInterface.addCallback("ASwasEdited",function():Boolean
               {
                  return wasEdited;
               });
               ExternalInterface.addCallback("AScanShare",function():Boolean
               {
                  return !runtime.hasUnofficialExtensions();
               });
               ExternalInterface.addCallback("ASexportProject",function():void
               {
                  openInScratch(null);
               });
               return;
            }
            catch(error:Error)
            {
               return;
            }
         }
      }
      
      private function refreshCloudLists() : void
      {
         var _loc3_:ListWatcher = null;
         var _loc1_:Sprite = app.stagePane.getUILayer();
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.numChildren)
         {
            _loc3_ = _loc1_.getChildAt(_loc2_) as ListWatcher;
            if(_loc3_ && _loc3_.isPersistent)
            {
               _loc3_.updateContents();
            }
            _loc2_++;
         }
      }
      
      private function setSmallPlayerMode(param1:Boolean) : void
      {
         isSmallPlayer = param1;
         if(isSmallPlayer)
         {
            editMode = false;
         }
         this.setEditMode(editMode);
      }
      
      private function downloadFromJS() : void
      {
         var download:Function = null;
         download = function(param1:*):void
         {
            exportProjectToFile(true);
         };
         DialogBox.confirm("Download project to local computer?",stage,download);
      }
      
      private function dumpRecordThumbnailFromJS() : String
      {
         return Base64Encoder.encode(stagePane.projectThumbnailPNG());
      }
      
      private function addFileFromJS(param1:String, param2:String, param3:int, param4:int) : void
      {
         var errorHandler:Function = null;
         var loadDone:Function = null;
         var i:int = 0;
         var assetName:String = null;
         var decoder:Loader = null;
         var fileName:String = param1;
         var contents:String = param2;
         var x:int = param3;
         var y:int = param4;
         errorHandler = function(param1:ErrorEvent):void
         {
         };
         loadDone = function(param1:Event):void
         {
            var _loc2_:BitmapData = ScratchCostume.scaleForScratch(param1.target.content.bitmapData);
            addCostume(new ScratchCostume(assetName,_loc2_));
         };
         var addCostume:Function = function(param1:ScratchCostume):void
         {
            addCostume(param1);
         };
         var data:ByteArray = Base64Encoder.decode(contents.slice(contents.indexOf(",") + 1));
         if(data.length == 0)
         {
            return;
         }
         assetName = fileName;
         if((i = assetName.lastIndexOf(".")) == assetName.length - 4)
         {
            assetName = assetName.slice(0,-4);
         }
         if(ScratchSound.isWAV(data))
         {
            addSound(new ScratchSound(assetName,data));
         }
         else if(ScratchCostume.isSVGData(data))
         {
            addCostume(new ScratchCostume(assetName,data));
         }
         else
         {
            decoder = new Loader();
            decoder.contentLoaderInfo.addEventListener(Event.COMPLETE,loadDone);
            decoder.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
            decoder.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
            decoder.loadBytes(data);
         }
         this.setSaveNeeded(true);
      }
      
      private function addURLFromJS(param1:String, param2:int, param3:int) : void
      {
         var addAsset:Function = null;
         var url:String = param1;
         var x:int = param2;
         var y:int = param3;
         addAsset = function(param1:String):void
         {
            if(!param1)
            {
               return;
            }
            var _loc2_:String = url;
            var _loc3_:String = "";
            var _loc4_:int = url.lastIndexOf(".");
            if(_loc4_ >= 0)
            {
               _loc3_ = url.slice(_loc4_).toLowerCase();
               _loc2_ = url.slice(0,_loc4_);
            }
            _loc4_ = _loc2_.lastIndexOf("/");
            if(_loc4_ >= 0)
            {
               _loc2_ = _loc2_.slice(_loc4_ + 1);
            }
            if(_loc3_ == ".wav" || _loc3_ == ".mp3")
            {
               fetchAndAddSound(param1,_loc2_);
            }
            else
            {
               fetchAndAddCostume(param1,_loc2_);
            }
         };
         if(!URLUtil.isHttpURL(url))
         {
            return;
         }
         this.serverOnline.saveImageAssetFromURL(url,addAsset);
      }
      
      private function createProjectFromJS(param1:String, param2:String = null, param3:String = null) : void
      {
         if(param2 && param2 == this.projectID)
         {
            return;
         }
         this.log(LogLevel.INFO,"SWF AScreateProject",{"owner":param1});
         if(!param1)
         {
            param1 = "";
         }
         runtime.stopAll();
         this.userName = param1;
         this.forceCreateNewAndUpload();
      }
      
      protected function loadProjectFromJS(param1:String, param2:String, param3:String, param4:Boolean, param5:Boolean = true) : void
      {
         var _loc6_:ProjectIOOnline = null;
         if(param2 && param2 == this.projectID)
         {
            return;
         }
         this.log(LogLevel.INFO,"SWF ASloadProject",{
            "id":param2,
            "owner":param1,
            "title":param3,
            "isPrivate":param4,
            "autostart":param5
         });
         if(!param1)
         {
            param1 = "";
         }
         if(!param2)
         {
            param2 = "";
         }
         if(!param3)
         {
            param3 = "";
         }
         runtime.stopAll();
         saveNeeded = false;
         this.projectID = param2;
         this.projectOwner = param1;
         this.projectIsPrivate = param4;
         this.autostart = param5;
         setProjectName(param3);
         if(param2 == "")
         {
            startNewProject(param1,param2);
            this.userName = param1;
            if(this.isLoggedIn())
            {
               this.saveProject(false);
            }
         }
         else
         {
            _loc6_ = new ProjectIOOnline(this);
            _loc6_.fetchProject(projectOwner,param2);
         }
      }
      
      override protected function doRevert() : void
      {
         if(this.originalProjOnServer)
         {
            addLoadProgressBox("Reverting...");
            new ProjectIOOnline(this).downloadProjectAssets(originalProj);
         }
         else
         {
            super.doRevert();
         }
      }
      
      override public function saveForRevert(param1:ByteArray, param2:Boolean, param3:Boolean = false) : void
      {
         super.saveForRevert(param1,param2,param3);
         this.originalProjOnServer = param3;
      }
      
      public function setUserFromJS(param1:String, param2:String = "") : void
      {
         var _loc3_:Boolean = false;
         if(!param1)
         {
            param1 = "";
         }
         this.wasLoggedOut = this.userName && !param1;
         this.userName = param1;
         this.getServerSettings();
         this.backpackPart.loadBackpack();
         this.refreshUserAndProject();
         fixLayout();
         if(!loadInProgress)
         {
            if(this.isLoggedIn())
            {
               _loc3_ = this.userName == projectOwner || !projectOwner;
               switch(param2)
               {
                  case "save":
                     if(!this.saveInProgress && _loc3_)
                     {
                        this.saveProject(true);
                     }
                     break;
                  case "remix":
                     if(!this.saveInProgress && !_loc3_)
                     {
                        this.remixButtonPressed();
                     }
               }
            }
            this.updateSaveStatus();
         }
      }
      
      private function setNewProjectFromJS(param1:String, param2:String) : void
      {
         var projectSaved:Function = null;
         var newProjectID:String = param1;
         var newTitle:String = param2;
         projectSaved = function():void
         {
            setTimeout(function():void
            {
               jsRedirectTo(newProjectID,true);
            },1000);
         };
         projectID = newProjectID;
         projectOwner = this.userName;
         projectIsPrivate = true;
         setProjectName(newTitle);
         saveNeeded = true;
         if(this.canSave())
         {
            this.saveProject(false,projectSaved);
         }
      }
      
      private function handleSaveResponse(param1:String) : void
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         var _loc4_:* = undefined;
         var _loc5_:* = undefined;
         var _loc6_:String = null;
         if(param1)
         {
            _loc2_ = util.JSON.parse(param1);
            if(_loc2_)
            {
               _loc3_ = 1000 * int(_loc2_["autosave-interval"]);
               if(_loc3_ >= this.MIN_AUTO_SAVE_INTERVAL)
               {
                  this.autosaveInterval = _loc3_;
               }
               _loc4_ = _loc2_["content-title"];
               if(_loc4_ != null)
               {
                  setProjectName(Base64Encoder.decode(_loc4_.toString()).toString());
               }
               _loc5_ = _loc2_["content-name"];
               if(_loc5_ != null)
               {
                  _loc6_ = projectID;
                  projectID = _loc5_.toString();
                  if(_loc6_ != projectID)
                  {
                     this.persistenceManager.prepareForCopyOrRemix();
                  }
               }
            }
         }
      }
      
      protected function saveProject(param1:Boolean, param2:Function = null) : void
      {
         var thumbnailSaved:Function = null;
         var uploadSucceeded:Function = null;
         var saveStartTime:int = 0;
         var oldProjectID:String = null;
         var projectThumbnail:ByteArray = null;
         var explicitSave:Boolean = param1;
         var whenDone:Function = param2;
         thumbnailSaved = function(param1:*):void
         {
            if(oldProjectID != projectID)
            {
               jsRedirectTo(projectID,true);
            }
         };
         uploadSucceeded = function(param1:String):void
         {
            clearSaveInProgress(false);
            log(LogLevel.INFO,"Project saved!",{"msecs":CachedTimer.getCachedTimer() - saveStartTime});
            handleSaveResponse(param1);
            serverOnline.setProjectThumbnail(projectID,projectThumbnail,thumbnailSaved);
            if(projectOwner != userName)
            {
               projectOwner = userName;
               refreshUserAndProject();
            }
            remixRequested = copyRequested = false;
            topBarOnline.hideTransitionNotice();
            if(whenDone != null)
            {
               whenDone();
            }
         };
         if(this.saveInProgress)
         {
            return;
         }
         if(!this.lastSaveFailed)
         {
            this.saveFailureTolerance = !!explicitSave?1:3;
         }
         this.log(LogLevel.INFO,"SWF saving project",{
            "id":projectID,
            "owner":this.userName,
            "title":projectName()
         });
         if(this.remixRequested)
         {
            this.topBarOnline.showTransitionNotice("Remixing...");
         }
         else if(this.copyRequested)
         {
            this.topBarOnline.showTransitionNotice("Copying...");
         }
         saveStartTime = CachedTimer.getCachedTimer();
         oldProjectID = projectID;
         projectThumbnail = stagePane.projectThumbnailPNG();
         new ProjectIOOnline(this).uploadProject(stagePane,projectID,this.remixRequested || this.copyRequested,uploadSucceeded);
         this.saveInProgress = true;
         this.clearSaveNeeded();
         this.updateSaveStatus();
      }
      
      public function saveFailed() : void
      {
         if(this.saveInProgress)
         {
            this.setSaveNeeded();
         }
         this.reportSaveFailure();
      }
      
      private function setSharedFromJS(param1:Boolean) : void
      {
         projectIsPrivate = !param1;
         this.refreshUserAndProject();
      }
      
      private function refreshUserAndProject() : void
      {
         topBarPart.refresh();
         stagePart.refresh();
         this.log(LogLevel.INFO,"Refresh",{
            "user":this.userName,
            "owner":projectOwner,
            "id":projectID,
            "isPrivate":projectIsPrivate
         });
      }
      
      private function startFromJS() : void
      {
         if(stagePart)
         {
            stagePart.playButtonPressed(null);
         }
      }
      
      private function stopFromJS() : void
      {
         runtime.stopAll();
      }
      
      private function getProjectJSONJS() : String
      {
         return escape(util.JSON.stringify(app.stagePane));
      }
      
      private function setBackpack(param1:String) : void
      {
         var done:Function = null;
         var json:String = param1;
         done = function():void
         {
         };
         this.serverOnline.setBackpack(json,this.userName,done);
      }
      
      public function cloudConnectionReady() : Boolean
      {
         if(!this.usesPersistentData)
         {
            return true;
         }
         return this.persistenceManager.ready;
      }
      
      private function clearProject() : void
      {
         startNewProject("","");
         if(!isOffline)
         {
            setProjectName("Untitled");
         }
         this.refreshUserAndProject();
      }
      
      private function forceCreateNewAndUpload() : void
      {
         var projectCreated:Function = null;
         projectCreated = function(param1:String):void
         {
            clearSaveInProgress(false);
            topBarOnline.hideTransitionNotice();
            handleSaveResponse(param1);
            refreshUserAndProject();
            jsRedirectTo(projectID,true);
         };
         this.clearProject();
         startNewProject(this.userName,"");
         if(this.userName && this.userName.length > 0)
         {
            this.saveInProgress = true;
            this.topBarOnline.showTransitionNotice("Creating...");
            new ProjectIOOnline(this).uploadProject(stagePane,null,true,projectCreated);
         }
      }
      
      override protected function createNewProject(param1:* = null) : void
      {
         var createNew:Function = null;
         var ignore:* = param1;
         var clearAndRedirect:Function = function():void
         {
            clearProject();
            jsRedirectTo("editor",true);
         };
         createNew = function():void
         {
            if(isOffline || isEmbedded || !isLoggedIn())
            {
               if(stagePane.isEmpty())
               {
                  clearAndRedirect();
               }
               else
               {
                  DialogBox.confirm("Discard contents of the current project?",app.stage,function(param1:DialogBox):void
                  {
                     clearAndRedirect();
                  });
               }
            }
            else
            {
               forceCreateNewAndUpload();
            }
         };
         if(this.shouldSave())
         {
            this.saveProject(true,createNew);
         }
         else
         {
            createNew();
         }
      }
      
      override public function setSaveNeeded(param1:Boolean = false) : void
      {
         super.setSaveNeeded(param1);
         this.lastCheckTime = -1000000;
         if(param1)
         {
            this.nextSaveTime = -1000000;
         }
         this.updateSaveStatus();
      }
      
      override protected function clearSaveNeeded() : void
      {
         super.clearSaveNeeded();
         this.nextSaveTime = CachedTimer.getCachedTimer() + this.autosaveInterval;
         this.showSaveFailDialog(false);
         this.setSaveStatus("Saved");
      }
      
      public function setSaveStatus(param1:String, param2:Boolean = false) : void
      {
         this.saveStatus = param1;
         this.saveStatusAlert = param2;
         this.topBarOnline.setSaveStatus(this.saveStatus,this.saveStatusAlert,this.saveTimerContext);
      }
      
      public function clearSaveInProgress(param1:Boolean) : void
      {
         this.saveInProgress = false;
         this.lastSaveFailed = param1;
      }
      
      public function reportSaveFailure() : void
      {
         removeLoadProgressBox();
         stagePane.clearPenLayer();
         var _loc1_:Boolean = !this.isLoggedIn() || this.wasLoggedOut;
         if(!_loc1_)
         {
            this.saveFailureTolerance--;
            if(this.saveFailureTolerance <= 0)
            {
               this.showSaveFailDialog(true);
            }
            this.saveRetryDelay = !!this.lastSaveFailed?int(Math.min(2 * this.saveRetryDelay,this.autosaveInterval)):int(this.SAVE_CHECK_INTERVAL);
            this.nextSaveTime = CachedTimer.getCachedTimer() + this.saveRetryDelay;
         }
         this.clearSaveInProgress(true);
         this.setSaveStatus("Changes not saved; " + (!!_loc1_?"please sign in to save.":"network not connecting. Trying again in {sec}..."),true);
      }
      
      public function updateSaveStatus() : void
      {
         if(this.saveInProgress)
         {
            this.setSaveStatus("Saving...");
         }
         else if(saveNeeded)
         {
            if(!this.canSave())
            {
               if(!this.isLoggedIn())
               {
                  this.setSaveStatus("Sign in to save",true);
               }
               else if(projectOwner != this.userName)
               {
                  this.setSaveStatus("Want to save? Click remix",true);
               }
               else if(loadInProgress)
               {
                  this.setSaveStatus("Project loading...");
               }
               else if(projectID == "")
               {
                  this.setSaveStatus("Not saved: no project ID",true);
               }
            }
            else
            {
               this.setSaveStatus("Save now",true);
            }
         }
         else if(wasEdited)
         {
            this.setSaveStatus("Saved");
         }
         else
         {
            this.setSaveStatus("");
         }
      }
      
      private function shouldSave() : Boolean
      {
         return saveNeeded && editMode && this.canSave();
      }
      
      // private function canSave() : Boolean
      // {
      //    return this.isLoggedIn() && projectOwner == this.userName && projectID != "" && !loadInProgress;
      // }
      
      public function saveNow(param1:Boolean, param2:Function) : void
      {
         if(!this.canSave())
         {
            return;
         }
         if(saveNeeded)
         {
            this.saveProject(param1,param2);
         }
         else
         {
            param2();
         }
      }
   }
}

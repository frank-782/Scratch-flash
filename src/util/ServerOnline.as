package util
{
   //import by.blooddy.crypto.serialization.JSON;
   import by.blooddy.crypto.MD5;
   import flash.events.HTTPStatusEvent;
   import flash.external.ExternalInterface;
   import flash.utils.ByteArray;
   import logging.LogLevel;
   
   public class ServerOnline extends Server
   {
      
      private static var instance:ServerOnline;
       
      
      private var lastThumbMD5:String;
      
      public function ServerOnline()
      {
         super();
         ServerOnline.instance = this;
      }
      
      public static function getInstance() : ServerOnline
      {
         return instance;
      }
      
      override protected function setDefaultURLs() : void
      {
         URLs.sitePrefix = "https://scratch.mit.edu/";
         URLs.siteCdnPrefix = "https://cdn.scratch.mit.edu/";
         URLs.assetPrefix = "https://assets.scratch.mit.edu/";
         URLs.assetCdnPrefix = "https://cdn.assets.scratch.mit.edu/";
         URLs.projectPrefix = "https://projects.scratch.mit.edu/";
         URLs.projectCdnPrefix = "https://cdn.projects.scratch.mit.edu/";
         URLs.internalAPI = "internalapi/";
         URLs.siteAPI = "site-api/";
         URLs.staticFiles = "scratchr2/static/";
      }
      
      public function getProjectURL() : String
      {
         return !!Scratch.app.projectID?URLs.sitePrefix + "projects/" + Scratch.app.projectID + "/":"";
      }
      
      public function recordPlay() : void
      {
         if(Scratch.app.projectID)
         {
            serverGet(URLs.sitePrefix + "projects/" + Scratch.app.projectID + "/run/",function(param1:*):void
            {
               ScratchOnline.app.log(LogLevel.INFO,"Play recorded");
            });
         }
      }
      
      public function setAsset(param1:String, param2:ByteArray, param3:Function) : void
      {
         var _loc4_:* = URLs.assetPrefix + URLs.internalAPI + "asset/" + param1 + "/set/";
         var _loc5_:int = param1.indexOf(".");
         var _loc6_:String = _loc5_ > 0?param1.substr(_loc5_ + 1):null;
         var _loc7_:String = "application/octet-stream";
         if(_loc6_ == "json")
         {
            _loc7_ = "application/json";
         }
         else if(_loc6_ == "svg")
         {
            _loc7_ = "image/svg+xml";
         }
         else if(_loc6_ == "png")
         {
            _loc7_ = "image/png";
         }
         else if(_loc6_ == "jpg" || _loc6_ == "jpeg")
         {
            _loc7_ = "image/jpeg";
         }
         else if(_loc6_ == "wav")
         {
            _loc7_ = "audio/wav";
         }
         else if(_loc6_ == "mp3")
         {
            _loc7_ = "audio/x-mpeg-3";
         }
         callServer(_loc4_,param2,_loc7_,param3);
      }
      
      override protected function getCdnStaticSiteURL() : String
      {
         var _loc1_:* = ScratchOnline.app.getCdnToken();
         if(_loc1_)
         {
            _loc1_ = "__" + _loc1_ + "__/";
         }
         else
         {
            _loc1_ = "";
         }
         return super.getCdnStaticSiteURL() + _loc1_;
      }
      
      public function saveImageAssetFromURL(param1:String, param2:Function) : void
      {
         var _loc3_:String = param1.slice(7);
         var _loc4_:* = URLs.sitePrefix + URLs.internalAPI + "asset/" + _loc3_ + "/setfromurl/";
         serverGet(_loc4_,param2);
      }
      
      public function getBackpack(param1:String, param2:Function) : void
      {
         var _loc3_:* = URLs.sitePrefix + URLs.internalAPI + "backpack/" + param1 + "/get/";
         serverGet(_loc3_,param2);
      }
      
      public function setBackpack(param1:String, param2:String, param3:Function) : void
      {
         var _loc4_:* = URLs.sitePrefix + URLs.internalAPI + "backpack/" + param2 + "/set/";
         callServer(_loc4_,param1,"application/json",param3);
      }
      
      public function getSettings(param1:Function) : void
      {
         var _loc2_:* = URLs.sitePrefix + URLs.internalAPI + "swf-settings/";
         serverGet(_loc2_,param1);
      }
      
      public function getSession(param1:Function) : void
      {
         var _loc2_:* = URLs.sitePrefix + "session/";
         serverGet(_loc2_,param1);
      }
      
      public function getCloudToken(param1:String, param2:Function) : void
      {
         var _loc3_:* = URLs.sitePrefix + "projects/" + param1 + "/cloud_token/";
         serverGet(_loc3_,param2);
      }
      
      public function createProject(param1:Function, param2:String, param3:String, param4:String = null) : void
      {
         var _loc5_:* = URLs.projectPrefix + URLs.internalAPI + "project/new/set/";
         var _loc6_:Object = {"title":param2};
         if(param4 && param4 != "")
         {
            _loc6_["original_id"] = param4;
            if(ScratchOnline.app.userName != ScratchOnline.app.projectOwner)
            {
               _loc6_["is_remix"] = 1;
            }
            else
            {
               _loc6_["is_copy"] = 1;
            }
         }
         callServer(_loc5_,param3,"application/json",param1,_loc6_);
      }
      
      public function getProject(param1:String, param2:Function, param3:String = null) : void
      {
         if(!param3)
         {
            param3 = new Date().getTime().toString(16);
         }
         if(URLs.sitePrefix.indexOf("edu:") > -1)
         {
            param3 = "";
         }
         var _loc4_:String = URLs.projectCdnPrefix + URLs.internalAPI + "project/" + param1 + "/get/" + param3;
         serverGet(_loc4_,param2);
      }
      
      public function getProjectSaveURL(param1:String) : String
      {
         return URLs.projectPrefix + URLs.internalAPI + "project/" + param1 + "/set/";
      }
      
      public function setProject(param1:String, param2:String, param3:Function) : void
      {
         callServer(this.getProjectSaveURL(param1),param2,"application/json",param3);
      }
      
      public function projectURL(param1:String) : String
      {
         return "http://scratch.mit.edu/services/download/" + param1 + "/";
      }
      
      public function setProjectThumbnail(param1:String, param2:ByteArray, param3:Function) : void
      {
         var _loc5_:* = null;
         var _loc4_:String = param1 + "_" + MD5.hashBytes(param2);
         if(!this.lastThumbMD5 || this.lastThumbMD5 != _loc4_)
         {
            this.lastThumbMD5 = _loc4_;
            _loc5_ = URLs.sitePrefix + URLs.internalAPI + "project/thumbnail/" + param1 + "/set/";
            callServer(_loc5_,param2,"image/png",param3);
         }
         else
         {
            param3(null);
         }
      }
      
      override public function getLanguageList(param1:Function) : void
      {
         var _loc2_:* = this.getCdnStaticSiteURL() + "locale/" + "lang_list.txt";
         serverGet(_loc2_,param1);
      }
      
      override public function getPOFile(param1:String, param2:Function) : void
      {
         var _loc3_:* = this.getCdnStaticSiteURL() + "locale/" + param1 + ".po";
         serverGet(_loc3_,param2);
      }
      
      override public function getSelectedLang(param1:Function) : void
      {
         var gotLanguage:Function = null;
         var whenDone:Function = param1;
         gotLanguage = function(param1:String):void
         {
            var _loc2_:Object = null;
            if(param1)
            {
               try
               {
                  _loc2_ = JSON.parse(param1);
               }
               catch(e:*)
               {
               }
               if(_loc2_ && _loc2_.lang is String)
               {
                  whenDone(_loc2_.lang);
               }
            }
         };
         var url:String = URLs.sitePrefix + URLs.siteAPI + "i18n/get-preferred-language/";
         serverGet(url,gotLanguage);
      }
      
      override public function setSelectedLang(param1:String) : void
      {
         var doNothing:Function = null;
         var lang:String = param1;
         doNothing = function(param1:String):void
         {
         };
         var url:String = URLs.sitePrefix + URLs.siteAPI + "i18n/set-preferred-language/";
         if(lang == "")
         {
            lang = "en";
         }
         Scratch.app.externalCall("window.tip_bar_api.updateLanguage",null,lang);
         url = url + ("?lang=" + encodeURIComponent(lang));
         callServer(url,null,null,doNothing);
      }
      
      public function logAddItemToBackpack(param1:String) : void
      {
         var doNothing:Function = null;
         var jsonData:String = param1;
         doNothing = function(param1:String):void
         {
         };
         var url:String = URLs.sitePrefix + "log/add-item-to-backpack/";
         callServer(url,jsonData,"application/json",doNothing);
      }
      
      public function logUseItemFromBackpack(param1:String) : void
      {
         var doNothing:Function = null;
         var jsonData:String = param1;
         doNothing = function(param1:String):void
         {
         };
         var url:String = URLs.sitePrefix + "log/use-item-from-backpack/";
         callServer(url,jsonData,"application/json",doNothing);
      }
      
      public function logDeleteItemFromBackpack(param1:String) : void
      {
         var doNothing:Function = null;
         var jsonData:String = param1;
         doNothing = function(param1:String):void
         {
         };
         var url:String = URLs.sitePrefix + "log/delete-item-from-backpack/";
         callServer(url,jsonData,"application/json",doNothing);
      }
      
      override protected function onCallServerHttpStatus(param1:String, param2:*, param3:HTTPStatusEvent) : void
      {
         if(param3.status == 403 && param2)
         {
            ScratchOnline.app.handleExternalLogout();
         }
      }
      
      override public function getCSRF() : String
      {
         return !!ScratchOnline.app.jsEnabled?ExternalInterface.call("getCookie","scratchcsrftoken"):null;
      }
   }
}

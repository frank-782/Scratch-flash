package raven
{
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestHeader;
   import flash.net.URLRequestMethod;
   import flash.system.Security;
   
   public class RavenMessageSender
   {
       
      
      private var _config:RavenConfig;
      
      private var _hasAccess:Boolean;
      
      private var messagesSent:Object;
      
      public function RavenMessageSender(param1:RavenConfig)
      {
         this.messagesSent = new Object();
         super();
         this._config = param1;
         this._hasAccess = true;
         Security.loadPolicyFile(this._config.uri + "api/" + this._config.projectID + "/crossdomain.xml");
      }
      
      public function send(param1:String, param2:Number, param3:String) : void
      {
         var message:String = param1;
         var timestamp:Number = param2;
         var md5:String = param3;
         if(!this._hasAccess || md5 in this.messagesSent)
         {
            return;
         }
         var signature:String = RavenUtils.getSignature(message,timestamp,this._config.privateKey);
         var loader:URLLoader = new URLLoader();
         loader.addEventListener(Event.COMPLETE,function(param1:Event):void
         {
            onLoadComplete(param1,md5);
         });
         loader.addEventListener(IOErrorEvent.IO_ERROR,this.onLoadFail);
         loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.onLoadFail);
         var request:URLRequest = new URLRequest(this._config.uri + "api/" + this._config.projectID + "/store/");
         request.method = URLRequestMethod.POST;
         request.requestHeaders.push(new URLRequestHeader("x-sentry-auth",this.buildAuthHeader(signature,timestamp)));
         request.requestHeaders.push(new URLRequestHeader("content-type","application/octet-stream"));
         request.data = message;
         loader.load(request);
      }
      
      private function buildAuthHeader(param1:String, param2:Number) : String
      {
         var _loc3_:* = "Sentry sentry_version=2.0,sentry_signature=";
         _loc3_ = _loc3_ + param1;
         _loc3_ = _loc3_ + ",sentry_timestamp=";
         _loc3_ = _loc3_ + param2;
         _loc3_ = _loc3_ + ",sentry_key=";
         _loc3_ = _loc3_ + this._config.publicKey;
         _loc3_ = _loc3_ + ",sentry_client=";
         _loc3_ = _loc3_ + RavenClient.NAME;
         return _loc3_;
      }
      
      private function onLoadFail(param1:Event) : void
      {
         var _loc2_:URLLoader = URLLoader(param1.target);
         _loc2_.removeEventListener(Event.COMPLETE,this.onLoadComplete);
         _loc2_.removeEventListener(IOErrorEvent.IO_ERROR,this.onLoadFail);
         _loc2_.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,this.onLoadFail);
         if(param1.type == SecurityErrorEvent.SECURITY_ERROR)
         {
            this._hasAccess = false;
         }
      }
      
      private function onLoadComplete(param1:Event, param2:String) : void
      {
         this.messagesSent[param2] = true;
         var _loc3_:URLLoader = URLLoader(param1.target);
         _loc3_.removeEventListener(Event.COMPLETE,this.onLoadComplete);
         _loc3_.removeEventListener(IOErrorEvent.IO_ERROR,this.onLoadFail);
         _loc3_.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,this.onLoadFail);
      }
   }
}

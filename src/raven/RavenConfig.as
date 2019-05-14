package raven
{
   import com.adobe.net.URI;
   
   public class RavenConfig
   {
       
      
      private var _uriObject:URI;
      
      private var _dsn:String;
      
      private var _uri:String;
      
      private var _path:String;
      
      private var _project:String;
      
      private var _publicKey:String;
      
      private var _privateKey:String;
      
      public function RavenConfig(param1:String)
      {
         super();
         this._dsn = param1;
         this._uriObject = new URI(this._dsn);
         this.parseDSN();
      }
      
      private function parseDSN() : void
      {
         var _loc2_:String = null;
         this._uri = this._uriObject.scheme + "://" + this._uriObject.authority;
         this._uri = this._uri + (!!this._uriObject.port?":" + this._uriObject.port:"");
         var _loc1_:Array = this._uriObject.path.split("/");
         _loc1_.shift();
         this._path = "";
         if(_loc1_.length == 0)
         {
            this._project = "";
         }
         else
         {
            this._project = _loc1_.pop();
            for each(_loc2_ in _loc1_)
            {
               this._path = this._path + (_loc2_ + "/");
            }
         }
         this._uri = this._uri + ("/" + this._path);
         this._privateKey = this._uriObject.password;
         this._publicKey = this._uriObject.username;
      }
      
      public function get uri() : String
      {
         return this._uri;
      }
      
      public function get publicKey() : String
      {
         return this._publicKey;
      }
      
      public function get privateKey() : String
      {
         return this._privateKey;
      }
      
      public function get projectID() : String
      {
         return this._project;
      }
      
      public function get dsn() : String
      {
         return this._dsn;
      }
   }
}

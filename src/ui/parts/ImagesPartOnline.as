package ui.parts
{
   import flash.display.BitmapData;
   import svgeditor.BitmapEditOnline;
   import svgeditor.SVGEditOnline;
   
   public class ImagesPartOnline extends ImagesPart
   {
       
      
      public function ImagesPartOnline(param1:Scratch)
      {
         super(param1);
      }
      
      override protected function addEditor(param1:Boolean) : void
      {
         if(param1)
         {
            addChild(editor = new SVGEditOnline(app,this));
         }
         else
         {
            addChild(editor = new BitmapEditOnline(app,this));
         }
      }
      
      override protected function savePhotoAsCostume(param1:BitmapData) : void
      {
         try
         {
            ScratchOnline.app.logImageImported("photo.png",true);
         }
         catch(error:Error)
         {
         }
         super.savePhotoAsCostume(param1);
      }
   }
}

package ui.parts
{
   import uiwidgets.ScriptsPane;
   import uiwidgets.ScriptsPaneOnline;
   import uiwidgets.ScrollFrame;
   
   public class ScriptsPartOnline extends ScriptsPart
   {
       
      
      public function ScriptsPartOnline(param1:Scratch)
      {
         super(param1);
      }
      
      override protected function addScriptsPane() : ScriptsPane
      {
         var _loc1_:ScriptsPane = new ScriptsPaneOnline(app);
         scriptsFrame = new ScrollFrame();
         scriptsFrame.setContents(_loc1_);
         addChild(scriptsFrame);
         return _loc1_;
      }
   }
}

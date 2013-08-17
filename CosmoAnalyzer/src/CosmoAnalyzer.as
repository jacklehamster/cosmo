package
{
	import com.cosmo.core.Cosmo;
	import com.cosmo.core.ICosmo;
	import com.cosmo.core.LocalCosmo;
	import com.cosmo.core.ServerCosmo;
	import com.cosmo.spot.ISpot;
	import com.synco.utils.SyncoUtil;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.SyncEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	
	public class CosmoAnalyzer extends Sprite
	{
		private var cosmo:ICosmo = Cosmo.getLocal("cosmo");
//		private var cosmo:ICosmo = Cosmo.getServer("http://vincent.netau.net/cosmo2.php");//LocalCosmo();
		private var spot:ISpot = cosmo.getSpot("wormsy");
		
		private var log:TextField = new TextField();
		private var tf:TextField = new TextField();
		private var input:TextField = new TextField();
		public function CosmoAnalyzer()
		{	
			log.mouseEnabled = false;
			log.autoSize = TextFieldAutoSize.LEFT;
			log.textColor = 0xBBBBBB;
			addChild(log);
			(cosmo as Cosmo).addEventListener("log",
				function(e:TextEvent):void {
					//log.appendText(e.text+"\n");
				});
			
			input.multiline = false;
			input.type = TextFieldType.INPUT;
			input.border = true;
			input.addEventListener(KeyboardEvent.KEY_DOWN,onKey);
			addChild(input);
			
			tf.multiline = true;
			tf.type = TextFieldType.DYNAMIC;
			addChild(tf);
			
			spot.addEventListener(SyncEvent.SYNC,onSync);
			
			stage.addEventListener(Event.RENDER,onResize);
			stage.invalidate();
			onSync(null);
		}
		
		private function onKey(e:KeyboardEvent):void {
			input.textColor = 0;;
			if(e.keyCode==Keyboard.ENTER) {
				var list:Array = [];
				try {
					var action:String = input.text;
					var actionSplit:Array = action.split(" ");
					switch(actionSplit[0]) {
						case "lock":
							var property:String = actionSplit[1];
							input.text = "";
							spot.addLock(property,actionSplit[2]);
							break;
						default:
							var command:Array = action.split("=");
							var value:Object = JSON.parse(command[1]);
							list.push([command[0],value]);
							input.text = "";
							for each(var pair:Array in list) {
								spot.setProperty(pair[0],pair[1]);
							}
					}
				}
				catch(error:Error) {
					trace(error);
					input.textColor = 0xFF0000;
				}
			}
		}
		
		private function onResize(e:Event):void {
			tf.width = stage.stageWidth;
			tf.height = stage.stageHeight-20;
			input.y = tf.height;
			input.width = stage.stageWidth;
			input.height = stage.stageHeight - input.y;
		}
		
		private function onSync(e:SyncEvent):void {
			tf.text = JSON.stringify(spot.data,null,'\t');
		}
	}
}
package com.cosmo.core
{
	import com.cosmo.spot.Spot;
	
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;

	public class LocalCosmo extends Cosmo
	{
		static private const MAX_SLOTS:int = 100;
		
		private var prefix:String;
		private var myconnection:LocalConnection = new LocalConnection();
		private var outboundConnections:Vector.<LocalConnection> = new Vector.<LocalConnection>(MAX_SLOTS);
		private var myindex:int;
		
		public function LocalCosmo(name:String)
		{
			prefix = name+"_";
			myconnection.client = { localSend:receiveLocal };
			myindex = -1;
			for(var i:int=0;i<MAX_SLOTS;i++) {
				registerConnection(i);
				if(myindex<0) {
					try {
						myconnection.connect(prefix+i);
						myindex = i;
					}
					catch(error:Error) {
						unregisterConnection(i);
					}
				}
			}
		}
		
		override public function setProperty(roomName:String,property:String,value:Object):void {
			for (var i:int=0;i<outboundConnections.length;i++) {
				if(outboundConnections[i]) {
					outboundConnections[i].send(prefix+i,"localSend",roomName,[property,value],myindex);
				}
			}
		}
		
		private function receiveLocal(roomName,messages:Array,from:int):void {
			if(!outboundConnections[from]) {
				outboundConnections[from] = registerConnection(from);
			}
			(getSpot(roomName) as Spot).receiveMessages(messages);
		}
		
		private function registerConnection(index:int):void {
			var connection:LocalConnection = new LocalConnection();
			connection.addEventListener(StatusEvent.STATUS,
				function(e:StatusEvent):void {
					if(e.level=="error") {
						unregisterConnection(index);
					}
				});
			outboundConnections[index] = connection;
		}
		
		private function unregisterConnection(index:int):void {
			delete outboundConnections[index];
		}
	}
}
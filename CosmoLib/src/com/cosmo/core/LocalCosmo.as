package com.cosmo.core
{
	import com.cosmo.spot.Spot;
	import com.cosmo.spot.ISpot;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;

	public class LocalCosmo extends BaseCosmo
	{
		static private const MAX_SLOTS:int = 100;
		
		private var myconnection:LocalConnection = new LocalConnection();
		private var outboundConnections:Vector.<LocalConnection> = new Vector.<LocalConnection>(MAX_SLOTS);
		private var myindex:int;
		
		public function LocalCosmo()
		{
			myconnection.client = { broadcast:receiveLocal };
			myindex = -1;
			for(var i:int=0;i<MAX_SLOTS;i++) {
				registerConnection(i);
				if(myindex<0) {
					try {
						myconnection.connect("cosmo"+i);
						myindex = i;
					}
					catch(error:Error) {
						unregisterConnection(i);
					}
				}
			}
		}
		
		override public function send(roomName:String,msg:Object):void {
			for (var i:int=0;i<outboundConnections.length;i++) {
				if(outboundConnections[i]) {
					outboundConnections[i].send("cosmo"+i,"broadcast",roomName,msg,myindex);
				}
			}
		}
		
		private function receiveLocal(roomName,msg:Object,from:int):void {
			if(!outboundConnections[from]) {
				outboundConnections[from] = registerConnection(from);
			}
			distributeData(roomName,msg);
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
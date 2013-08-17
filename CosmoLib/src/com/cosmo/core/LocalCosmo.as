package com.cosmo.core
{
	import com.cosmo.spot.ISpot;
	import com.cosmo.spot.Spot;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;

	public class LocalCosmo extends Cosmo
	{
		static private const MAX_SLOTS:int = 100;
		
		private var prefix:String;
		private var myconnection:LocalConnection = new LocalConnection();
		private var outboundConnections:Vector.<LocalConnection> = new Vector.<LocalConnection>(MAX_SLOTS);
		private var connectionPending:Vector.<Number> = new Vector.<Number>(MAX_SLOTS);
		private var myindex:int;
		
		public function LocalCosmo(name:String)
		{
			prefix = name+"_";
			myconnection.client = { localSend:receiveLocal, hello:hello };
			myindex = -1;
			for(var i:int=0;i<MAX_SLOTS;i++) {
				registerConnection(i);
				if(myindex<0) {
					try {
						myconnection.connect(prefix+i);
						myindex = i;
					}
					catch(error:Error) {
					}
				}
			}
			for(i=0;i<MAX_SLOTS;i++) {
				if(i!=myindex) {
					outboundConnections[i].send(prefix+i,"hello",myindex);
					unregisterConnection(i);;
				}
			}
		}
		
		override public function get personalCode():String {
			if(!system.personalCode)
				system.personalCode = (Math.random()+""+new Date().time).split(".")[1];
			return system.personalCode;
		}
		
		override protected function broadcast(roomName:String,messages:Array,callback:Function):Boolean {
			var hasPendingConnection:Boolean = false;
			for (var i:int=0;i<outboundConnections.length;i++) {
				if(outboundConnections[i] && connectionPending[i]) {
					hasPendingConnection = true;
				}
			}
			if(hasPendingConnection)
				return false;
			var now:Number = new Date().time;
			analyzeMessages(messages);
			for(i=0;i<outboundConnections.length;i++) {
				if(outboundConnections[i]) {
					outboundConnections[i].send(prefix+i,"localSend",roomName,messages,myindex);
					connectionPending[i] = now;
				}
			}
			SyncoUtil.callAsyncOnce(callback,[null]);
			return true;
		}
		
		private function analyzeMessages(messages:Array):void {
			var now:Number = new Date().time;
			for each(var pair:Array in messages) {
				var json:String = JSON.stringify(pair[1]);
				json = json.split("%TIMESTAMP%").join(now);
				pair[1] = JSON.parse(json);
			}
		}
		
		private function receiveLocal(roomName,messages:Array,from:int):void {
			if(!outboundConnections[from]) {
				registerConnection(from);
			}
			(getSpot(roomName) as Spot).receiveMessages(messages);
		}
		
		private function hello(from:int):void {
			if(!outboundConnections[from]) {
				registerConnection(from);
			}
			for each(var spot:ISpot in spots) {
				var messages:Array = [];
				for(var i:String in spot.data) {
					messages.push([i,spot.data[i]]);
				}
				outboundConnections[from].send(prefix+from,"localSend",spot.roomName,messages,myindex);
			}
		}
		
		private function registerConnection(index:int):void {
			var connection:LocalConnection = new LocalConnection();
			connection.addEventListener(StatusEvent.STATUS,
				function(e:StatusEvent):void {
					if(e.level=="error") {
						unregisterConnection(index);
					}
					connectionPending[index] = 0;
				});
			outboundConnections[index] = connection;
		}
		
		private function unregisterConnection(index:int):void {
			outboundConnections[index] = null;
		}
	}
}
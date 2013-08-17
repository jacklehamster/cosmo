package com.cosmo.core
{
	import com.cosmo.spot.ISpot;
	import com.cosmo.spot.ServerSpot;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Timer;

	public class ServerCosmo extends Cosmo
	{
		public var server:String;
		
		public function ServerCosmo(server:String)
		{
			super();
			this.server = server;
		}
		
		override protected function broadcast(roomName:String,messages:Array,callback:Function):Boolean {
			var spot:ServerSpot = getSpot(roomName) as ServerSpot;
			if(!spot.channel)
				return false;
			
			var loader:URLLoader = new URLLoader();
			var url:String = server;
			var request:URLRequest = new URLRequest(url);
			request.data = new URLVariables();
			request.data.action="post";
			request.data.channel = spot.channel;
			var toSend:String = JSON.stringify(messages);
			toSend = toSend.substr(1,toSend.length-2);
			if(toSend.indexOf("%TIMESTAMP%")>=0) {
				request.data.timestamp=1;
			}
			request.data.data = toSend;
			request.data.count = spot.count;
			loader.addEventListener(Event.COMPLETE,callback);
			loader.addEventListener(IOErrorEvent.IO_ERROR,onError);
			loader.load(request);
			return true;
		}
		
		private function onError(e:IOErrorEvent):void {
			trace(e);
		}
		
		override protected function createSpot(roomName:String):ISpot {
			return new ServerSpot(roomName,this);
		}		
	}
}
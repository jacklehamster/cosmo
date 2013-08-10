package com.cosmo.core
{
	import com.cosmo.spot.ISpot;
	import com.cosmo.spot.ServerSpot;
	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;

	public class ServerCosmo extends Cosmo
	{
		public var server:String;
		public function ServerCosmo(server:String)
		{
			super();
			this.server = server;
		}
		
		override public function send(roomName:String,messages:Array):void {
			broadcast(roomName,messages);
		}
		
		private function broadcast(roomName:String,messages:Array):void {
			var spot:ServerSpot = getSpot(roomName) as ServerSpot;
			var loader:URLLoader = new URLLoader();
			var url:String = server;
			var request:URLRequest = new URLRequest(url);
			request.data = new URLVariables();
			request.data.action="post";
			request.data.channel = spot.channel;
			var toSend:String = JSON.stringify(messages);
			toSend = toSend.substr(1,toSend.length-2);
			request.data.data = toSend;
			request.data.count = spot.count;
			loader.load(request);
		}
		
		override protected function createSpot(roomName:String):ISpot {
			return new ServerSpot(roomName,this);
		}		
	}
}
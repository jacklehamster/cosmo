package com.cosmo.core
{
	import com.cosmo.spot.ServerSpot;
	import com.cosmo.spot.ISpot;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;

	public class ServerCosmo extends BaseCosmo
	{
		public var server:String;
		public function ServerCosmo(server:String)
		{
			super();
			this.server = server;
		}
		
		override public function send(roomName:String,msg:Object):void {
			broadcast(roomName,msg);
		}
		
		private function broadcast(roomName:String,msg:Object):void {
			var spot:ServerSpot = getSpot(roomName) as ServerSpot;
			var loader:URLLoader = new URLLoader();
			var url:String = server;
			var request:URLRequest = new URLRequest(url);
			request.data = new URLVariables();
			request.data.action="post";
			request.data.channel = spot.channel;
			request.data.data = JSON.stringify(msg);
			request.data.count = spot.count;
			loader.load(request);
		}
		
		override protected function createSpot(roomName:String):ISpot {
			return new ServerSpot(roomName,this);
		}		
	}
}
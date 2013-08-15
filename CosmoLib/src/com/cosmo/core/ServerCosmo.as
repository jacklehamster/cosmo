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
		static public const PACETIME:int = 100;
		public var server:String, pendingData:Object = {};
		private var paceTimer:Timer = new Timer(PACETIME,1);
		
		public function ServerCosmo(server:String)
		{
			super();
			this.server = server;
			paceTimer.addEventListener(TimerEvent.TIMER_COMPLETE,broadcastAll);
		}
		
		override public function setProperty(roomName:String,path:String,value:Object):void {
			if(!pendingData[roomName]) {
				pendingData[roomName] = {};
			}
			pendingData[roomName][path] = value;
			SyncoUtil.callAsyncOnce(broadcastAll);
		}
		
		private function broadcastAll(e:TimerEvent=null):void {
			if(!paceTimer.running) {
				for(var roomName:String in pendingData) {
					broadcast(roomName);
				}
			}
		}
		
		public function broadcast(roomName:String):void {
			if(!pendingData[roomName])
				return ;
			var spot:ServerSpot = getSpot(roomName) as ServerSpot;
			if(!spot.channel)
				return ;
			var messages:Array = [];
			for(var i:String in pendingData[roomName]) {
				messages.push([i,pendingData[roomName][i]]);
			}
			delete pendingData[roomName];
			
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
			loader.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					broadcast(roomName);
				});
			loader.addEventListener(IOErrorEvent.IO_ERROR,onError);
			loader.load(request);
			
			paceTimer.reset();
			paceTimer.start();
		}
		
		private function onError(e:IOErrorEvent):void {
			trace(e);
		}
		
		override protected function createSpot(roomName:String):ISpot {
			return new ServerSpot(roomName,this);
		}		
	}
}
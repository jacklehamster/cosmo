package com.cosmo.core
{
	import com.cosmo.spot.ISpot;
	import com.cosmo.spot.Spot;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.net.SharedObject;
	import flash.utils.Timer;

	public class Cosmo extends EventDispatcher
		implements ICosmo
	{
		protected var spots:Object = {};
		static private var instances:Object = {};
		private var pendingData:Object = {};
		static public const PACETIME:int = 100;
		private var paceTimer:Timer = new Timer(PACETIME,1);
		private var _system:Object = {};
		
		public function Cosmo()
		{
			paceTimer.addEventListener(TimerEvent.TIMER_COMPLETE,broadcastAll);
		}
		
		public function get lobby():ISpot
		{
			return getSpot("lobby");
		}
		
		public function get system():Object {
			return _system;
		}
		
		public function getSpot(roomName:String):ISpot
		{
			var spot:ISpot = spots[roomName] as ISpot;
			if(!spot) {
				spots[roomName] = spot = createSpot(roomName);
				lobby.setProperty("rooms."+roomName,true);
			}
			return spot;
		}
		
		public function get personalCode():String {
			if(!_system.personalCode) {
				
				var sharedObject:SharedObject = SharedObject.getLocal("cosmo_code");
				if(!sharedObject.data.passcode) {
					sharedObject.data.passcode = (Math.random()+""+new Date().time).split(".")[1];
					sharedObject.flush();
				}
				_system.personalCode = sharedObject.data.passcode;
			}
			return _system.personalCode;
		}
		
		protected function createSpot(roomName:String):ISpot {
			return new Spot(roomName,this);
		}
		
		static public function getServer(server:String):ServerCosmo {
			return instances["server_"+server] || (instances["server_"+server] = new ServerCosmo(server));
		}
		
		static public function getLocal(name:String):LocalCosmo {
			return instances["local_"+name] || (instances["local_"+name] = new LocalCosmo(name));
		}
		
		public function setProperty(roomName:String,path:String,value:Object,personalCode:String):void {
			if(!pendingData[roomName]) {
				pendingData[roomName] = {};
			}
			pendingData[roomName][path] = {value:value,code:personalCode};
			SyncoUtil.callAsyncOnce(broadcastAll);
		}
		
		private function broadcastAll(e:TimerEvent=null):void {
			if(!paceTimer.running) {
				for(var roomName:String in pendingData) {
					var messages:Array = [];
					for(var i:String in pendingData[roomName]) {
						var info:Object = pendingData[roomName][i];
						messages.push(!info.code ? [i,info.value] : [i,info.value,info.code]);
					}
					if(broadcast(roomName,messages,onBroadcast)) {
						delete pendingData[roomName];
					}
				}
				paceTimer.reset();
				paceTimer.start();
			}
		}
		
		public function refresh():void {
			broadcastAll();
		}
		
		private function onBroadcast(e:Event):void {
			refresh();
		}
		
		protected function broadcast(roomName:String,messages:Array,callback:Function):Boolean {
			return false;
		}
		
		public function log(...params):void {
			trace(params);
		}
	}
}
package com.cosmo.spot
{
	import com.cosmo.core.BaseCosmo;
	import com.cosmo.core.ServerCosmo;
	import com.cosmo.util.JSONUtil;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public class ServerSpot extends Spot
	{
		private var _count:int = 1;
		public var getLocation:String;
		private var updateTimer:Timer;
		private var _channel:String;
		
		public function ServerSpot(roomName:String, cosmo:BaseCosmo)
		{
			super(roomName, cosmo);
			enter();
		}
		
		private function enter():void {
			var cosmo:ServerCosmo = this.cosmo as ServerCosmo;
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(cosmo.server);
			request.data = new URLVariables();
			request.data.action = "enter";
			request.data.room = roomName;
			loader.addEventListener(Event.COMPLETE,onEnter);
			loader.load(request);
		}
		
		private function onEnter(e:Event):void {
			var loader:URLLoader = e.currentTarget as URLLoader;
			var split:Array = loader.data.split("/");
			_channel = split[split.length-1];
			getLocation = "http://"+loader.data;
			fetchData(onFirstFetch);
		}
		
		public function get channel():String {
			return _channel;
		}
		
		public function get count():int {
			return _count;
		}
		
		private function onFirstFetch(e:Event):void {
			updateTimer = new Timer(100);
			updateTimer.addEventListener(TimerEvent.TIMER,onUpdateTimer);
			updateTimer.start();
		}
		
		private function onUpdateTimer(e:TimerEvent):void {
			fetchData();
		}
		
		private function fetchData(callback:Function=null):void {
			if(getLocation) {
				var loader:CosmoLoader = new CosmoLoader();
				var url:String = updateTimer?getLocation+"/"+count+".json":getLocation+"/data.json";//?"+new Date().time;
				var request:URLRequest = new URLRequest(url);
				loader.addEventListener(Event.COMPLETE,callback!=null?callback:updateTimer?onUpdate:onData);
				loader.load(request);
				loader.url = url;
				loader.count = count;
			}
		}
		
		private function onUpdate(e:Event):void {
			var loader:CosmoLoader = e.currentTarget as CosmoLoader;
			if(loader.count==count && loader.data.length) {
				_count++;
				var msg:Object = JSONUtil.parse(loader.data);
				receiveData(msg);
			}
		}
		
		private function onData(e:Event):void {
			var loader:URLLoader = e.currentTarget as URLLoader;
			var msg:Object = JSONUtil.parse(loader.data);
			for(var o:String in msg) {
				data[o] = msg[o];
			}
		}
	}
}
import flash.net.URLLoader;

internal class CosmoLoader extends URLLoader {
	public var count:int;
	public var url:String;
}
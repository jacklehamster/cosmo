package com.cosmo.spot
{
	import com.cosmo.core.BaseCosmo;
	import com.cosmo.core.ServerCosmo;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	public class CosmoSpot extends Spot
	{
		public var getLocation:String;
		public function CosmoSpot(roomName:String, cosmo:BaseCosmo)
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
		}
		
		private function onEnter(e:Event):void {
			var loader:URLLoader = e.currentTarget as URLLoader;
			trace(loader.data);
		}
	}
}
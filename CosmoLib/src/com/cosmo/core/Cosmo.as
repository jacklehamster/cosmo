package com.cosmo.core
{
	import com.cosmo.spot.ISpot;
	import com.cosmo.spot.Spot;
	
	import flash.events.EventDispatcher;

	public class Cosmo extends EventDispatcher
		implements ICosmo
	{
		private var spots:Object = {};
		
		public function Cosmo()
		{
		}
		
		public function get lobby():ISpot
		{
			return getSpot("lobby");
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
		
		protected function createSpot(roomName:String):ISpot {
			return new Spot(roomName,this);
		}
		
		public function send(roomName:String,messages:Array):void {
			//	needs overwrite
		}
	}
}
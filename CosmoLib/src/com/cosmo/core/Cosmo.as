package com.cosmo.core
{
	import com.cosmo.spot.ISpot;
	import com.cosmo.spot.Spot;
	
	import flash.events.EventDispatcher;

	public class Cosmo extends EventDispatcher
		implements ICosmo
	{
		private var spots:Object = {};
		static private var instances:Object = {};
		
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
		
		public function setProperty(roomName:String,property:String,value:Object):void {
			//	needs overwrite
		}
		
		static public function getServer(server:String):ServerCosmo {
			return instances["server_"+server] || (instances["server_"+server] = new ServerCosmo(server));
		}
		
		static public function getLocal(name:String):LocalCosmo {
			return instances["local_"+name] || (instances["local_"+name] = new LocalCosmo(name));
		}
	}
}
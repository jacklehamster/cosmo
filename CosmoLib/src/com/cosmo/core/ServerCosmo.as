package com.cosmo.core
{
	import com.cosmo.spot.CosmoSpot;
	import com.cosmo.spot.ISpot;

	public class ServerCosmo extends BaseCosmo
	{
		public var server:String;
		public function ServerCosmo(server:String)
		{
			super();
			this.server = server;
		}
		
		override public function send(roomName:String,msg:Object):void {
			
		}
		
		override protected function createSpot(roomName:String):ISpot {
			return new CosmoSpot(roomName,this);
		}		
	}
}
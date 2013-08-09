package com.cosmo.spot
{
	import com.cosmo.core.BaseCosmo;
	import com.cosmo.core.LocalCosmo;
	import com.cosmo.util.JSONUtil;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.EventDispatcher;
	import flash.events.SyncEvent;

	[Event(name="sync", type="flash.events.SyncEvent")]
	public class Spot extends EventDispatcher implements ISpot
	{
		protected var _data:Object = {}, _changeList:Array = [], _roomName:String;
		protected var cosmo:BaseCosmo;
		public function Spot(roomName:String,cosmo:BaseCosmo)
		{
			_roomName = roomName;
			this.cosmo = cosmo;
		}
		
		public function get roomName():String {
			return _roomName;
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function setProperty(property:String,value:Object=null):void {
			if(!propertyEqual(property,value))
				cosmo.send(roomName,[property,JSONUtil.stringify(value)]);
		}
		
		protected function propertyEqual(name:String,value:Object):Boolean {
			return JSONUtil.stringify(value)==name;
		}
		
		public function receiveData(msg:Object):Boolean {
			var pair:Array = msg as Array;
			try {
				var name:String = pair[0];
				var access:Array = name.split(".");
				var leaf:Object = data;
				var leafName:String = name;
				for(var i:int=0;i<access.length;i++) {
					leafName = access[i];
					if(i<access.length-1) {
						if(typeof(leaf[leafName])!="object" || !leaf.hasOwnProperty(leafName)) {
							
							leaf[leafName] = {};
						}
						leaf = leaf[leafName];
					}
				}
				var newValue:Object = JSONUtil.parse(pair[1]);
				var change:Object = {newValue:newValue};
				if(leaf.hasOwnProperty(leafName)) {
					change.oldValue = data[name];
				}
				if(newValue===null) {
					delete leaf[leafName];
					change.code=="delete";
				}
				else {
					if(!leafName.length && (leaf is Array)) {
						leaf.push(newValue);
					}
					else
						leaf[leafName] = newValue;
					change.code=="change";
				}
				addChanges(change);
			}
			catch(error:Error) {
				trace("Malformed message:",JSONUtil.stringify(msg));
				return false;
			}
			return true;
		}
		
		protected function addChanges(change:Object):void {
			_changeList.push(change);
			SyncoUtil.callAsyncOnce(dispatchSync);
		}
		
		private function dispatchSync():void {
			var changeList:Array = _changeList;
			_changeList = [];
			dispatchEvent(new SyncEvent(SyncEvent.SYNC,false,false,changeList));
		}
	}
}
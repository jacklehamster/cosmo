package com.cosmo.spot
{
	import com.cosmo.core.Cosmo;
	import com.cosmo.util.JSONUtil;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.EventDispatcher;
	import flash.events.SyncEvent;

	[Event(name="sync", type="flash.events.SyncEvent")]
	public class Spot extends EventDispatcher implements ISpot
	{
		protected var _data:Object = {}, _changeList:Array = [], _roomName:String;
		protected var cosmo:Cosmo, pendingData:Object = {};
		public function Spot(roomName:String,cosmo:Cosmo)
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
		
		public function setProperty(property:String,value:Object):void {
			cosmo.setProperty(roomName,property,value);
		}
		
		public function receiveMessages(messages:Array):void {
			for each(var pair:Array in messages) {
//				try {
					var name:String = pair[0];
					var newValue:Object = pair[1];
					var access:Array = name.split(".");
					var leaf:Object = data;
					var preLeaf:Object = null, preName:String = null;
					var leafName:String = name;
					for(var i:int=0;i<access.length;i++) {
						leafName = access[i];
						if(leaf is Array && leafName!="" && newValue!==null) {
							var index:Number = parseFloat(leafName);
							if(index!=int(index) || index<0 || index>leaf.length) {
								var o:Object = {};
								for(var n:int=0;n<leaf.length;n++) {
									o[n] = leaf[n];
								}
								leaf = preLeaf[preName] = o;
							}
						}
						if(i<access.length-1) {
							if(typeof(leaf[leafName])!="object") {
								leaf[leafName] = {};
							}
							preLeaf = leaf; preName = leafName;
							leaf = leaf[leafName];
						}
					}
					var change:Object = {newValue:newValue};
					if(leaf.hasOwnProperty(leafName)) {
						change.oldValue = data[name];
					}
					if(newValue===null) {
						if(leaf is Array)
							(leaf as Array).splice(leafName,1);
						else
							delete leaf[leafName];
						change.code=="delete";
					}
					else {
						if(leafName=="" && (leaf is Array))
							leaf.push(newValue);
						else
							leaf[leafName] = newValue;
						change.code=="change";
					}
					addChanges(change);
//				}
//				catch(error:Error) {
//					trace("Malformed message:",JSONUtil.stringify(pair),error);
//				}
			}
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
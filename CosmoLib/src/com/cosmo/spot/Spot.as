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
		static private const LOCK_NONE:int = 0;
		static private const LOCK_KEY:int = 1;
		static private const LOCK_LOCKED:int = 2;
		static private const LOCK_MULTIKEY:int = LOCK_KEY | 4;
		
		protected var _data:Object = {}, _changeList:Array = [], _roomName:String;
		protected var cosmo:Cosmo, pendingData:Object = {};
		
		public function Spot(roomName:String,cosmo:Cosmo)
		{
			_roomName = roomName;
			this.cosmo = cosmo;
			data._system = cosmo.system;
		}

		private function get personalCode():String {
			return cosmo.personalCode;
		}

		public function get roomName():String {
			return _roomName;
		}
		
		public function get data():Object {
			return _data;
		}
		
		public function setProperty(property:String,value:Object):void {
			var myCode:String = personalCode;
			var lockStatus:int = getLock(property,myCode);
			if(!(lockStatus & LOCK_LOCKED)) {
				cosmo.setProperty(roomName,property,value,lockStatus & LOCK_KEY?myCode:null);
				if((lockStatus & LOCK_MULTIKEY) == LOCK_KEY) {	//	changes can be immediate if the item is locked
					receiveMessages([[property,value,myCode]]);
				}
			}
		}
		
		public function addLock(property:String,code:String=null):void {
			setProperty(property+"._lock.codes."+(code?code:personalCode),1);
		}
		
		private function getLock(property:String,passcode:String):int {
			var access:Array = property.split(".");
			var leaf:Object = data;
			var leafName:String = null;
			var lockStatus:int = LOCK_NONE;
			for(var i:int=0;i<access.length;i++) {
				var newLock:int = checkObjectLock(leaf,passcode);
				if(newLock & LOCK_LOCKED) {
					return LOCK_LOCKED;
				}
				else if(newLock & LOCK_KEY) {
					lockStatus = newLock;
				}
				leafName = access[i];
				if(typeof(leaf[leafName])!="object") {
					break;
				}
				leaf = leaf[leafName];
			}
			newLock = checkObjectLock(leaf,passcode);
			if(newLock & LOCK_LOCKED) {
				return LOCK_LOCKED;
			}
			else if(newLock & LOCK_KEY) {
				lockStatus = newLock;
			}
			return lockStatus;
		}
		
		public function locked(property:String):Boolean {
			return getLock(property,personalCode)!=LOCK_LOCKED;
		}
		
		private function checkObjectLock(object:Object,passcode:String):int {
			if(object===_data._system) {
				return LOCK_LOCKED;
			}
			var code:int = LOCK_NONE;
			var lock:Object = object && object.hasOwnProperty("_lock") ? object._lock : null;
			if(lock && lock.codes) {
				var numKeys:int = countKeys(lock.codes);
				if(numKeys>1)
					code |= LOCK_MULTIKEY;
				else if(numKeys==1)
					code |= LOCK_KEY;
				if(!lock.codes[passcode])
					code |= LOCK_LOCKED;
			}
			return code;
		}
		
		private function countKeys(codes:Object):int {
			var count:int = 0;
			for(var i:String in codes) {
				count++;
			}
			return count;
		}
		
		public function receiveMessages(messages:Array):void {
			for each(var pair:Array in messages) {
				try {
					var name:String = pair[0];
					var newValue:Object = pair[1];
					var passcode:String = pair[2];
					
					var access:Array = name.split(".");
					var leaf:Object = data;
					var preLeaf:Object = null, preName:String = null;
					var leafName:String = name;
					for(var i:int=0;i<access.length;i++) {
						if(checkObjectLock(leaf,passcode) & LOCK_LOCKED) {
							leaf = null;
							break;	//	can't change locked properties
						}
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
					if(!leaf || (checkObjectLock(leaf[leafName],passcode) & LOCK_LOCKED))
						continue;
					var change:Object = {name:name};
					if(leaf.hasOwnProperty(leafName)) {
						change.oldValue = leaf[leafName];
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
					if(newValue!=change.oldValue)
						addChanges(change);
				}
				catch(error:Error) {
					trace("Malformed message:",JSONUtil.stringify(pair),error);
				}
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
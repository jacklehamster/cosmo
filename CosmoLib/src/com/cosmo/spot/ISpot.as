package com.cosmo.spot
{
	import flash.events.IEventDispatcher;

	public interface ISpot extends IEventDispatcher
	{
		function get roomName():String;
		function get data():Object;
		function setProperty(property:String,value:Object):void;
		function addLock(property:String,code:String=null):void;
		function locked(property:String):Boolean;
	}
}
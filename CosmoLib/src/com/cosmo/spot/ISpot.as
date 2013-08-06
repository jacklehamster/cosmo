package com.cosmo.spot
{
	import flash.events.IEventDispatcher;

	public interface ISpot extends IEventDispatcher
	{
		function get roomName():String;
		function get data():Object;
		function setProperty(name:String,value:Object=null):void
	}
}
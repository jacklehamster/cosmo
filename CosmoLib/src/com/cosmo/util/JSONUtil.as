package com.cosmo.util
{
	public class JSONUtil
	{
		static public function parse(text:String):Object {
			return JSON.parse(text);
		}
		
		static public function stringify(value:Object):String {
			return JSON.stringify(value);
		}
	}
}
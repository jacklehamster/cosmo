package com.cosmo.core
{
	import com.cosmo.spot.ISpot;

	public interface ICosmo
	{
		function get lobby():ISpot;
		function getSpot(name:String):ISpot;
	}
}
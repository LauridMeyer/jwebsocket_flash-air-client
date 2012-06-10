package com.lauridmeyer.jwebsocket.clients
{
	import flash.display.Sprite;

	public class TokenPlugin extends Sprite
	{
		public var ns:String="";
		public var socket:JwebsocketAS3Client;
		
		public function TokenPlugin()
		{
		}
		
		public function registered(client:JwebsocketAS3Client):void
		{
			this.socket=client;
		}
		
		public function processToken(data:Object):void
		{
		}
	}
}
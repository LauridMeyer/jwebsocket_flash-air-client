package com.lauridmeyer.jwebsocket.clients
{
	//import com.adobe.serialization.json.JSON;
	
	import flash.system.Security;
	
	import net.gimite.websocket.IWebSocketLogger;
	import net.gimite.websocket.WebSocket;
	import net.gimite.websocket.WebSocketEvent;

	public class JwebsocketAS3Client implements IWebSocketLogger
	{
		private var callerUrl:String;
		private var debug:Boolean = false;
		private var manualPolicyFileLoaded:Boolean = false;
		private var ServerAdress:String="localhost";
		private var webSockets:Array = [];
		private var plugins:Array=[];
		private var loggedOn:Boolean=false;
		
		public function JwebsocketAS3Client(url:String):void{
			ServerAdress=url;
		}
		
		public function registerPlugIn(plugin:TokenPlugin):void{
			trace("register Plugin:"+plugin.ns);
			plugins.push(plugin);
			plugin.registered(this);
		}
		
		public function connect():void{
			var protocols:Array=["org.jwebsocket.json"];
			this.create(0,"ws://"+ServerAdress+":8787/jWebSocket/jWebSocket",protocols);
		}
		
		public function setCallerUrl(url:String):void {
			callerUrl = url;
		}
		
		public function setDebug(val:Boolean):void {
			debug = val;
			if (val) {
				log("debug enabled");
			}
		}
		
		private function loadDefaultPolicyFile(wsUrl:String):void {
			var policyUrl:String = "xmlsocket://" + ServerAdress + ":843";
			log("policy file: " + policyUrl);
			Security.loadPolicyFile(policyUrl);
		}
		
		public function loadManualPolicyFile(policyUrl:String):void {
			log("policy file: " + policyUrl);
			Security.loadPolicyFile(policyUrl);
			manualPolicyFileLoaded = true;
		}
		
		public function log(message:String):void {
			if (debug) {
				trace("log:"+message);
			}
		}
		
		public function error(message:String):void {
			trace("error:"+message);
		}
		
		private function parseEvent(event:WebSocketEvent):Object {
			var webSocket:WebSocket = event.target as WebSocket;
			var eventObj:Object = {};
			eventObj.type = event.type;
			eventObj.webSocketId = webSocket.getId();
			eventObj.readyState = webSocket.getReadyState();
			eventObj.protocol = webSocket.getAcceptedProtocol();
			if (event.message !== null) {
				eventObj.message = event.message;
			}
			if (event.wasClean) {
				eventObj.wasClean = event.wasClean;
			}
			if (event.code) {
				eventObj.code = event.code;
			}
			if (event.reason !== null) {
				eventObj.reason = event.reason;
			}
			return eventObj;
		}
		
		public function create(
			webSocketId:int,
			url:String, protocols:Array,
			proxyHost:String = null, proxyPort:int = 0,
			headers:String = null):void {
			if (!manualPolicyFileLoaded) {
				loadDefaultPolicyFile(url);
			}
			var newSocket:WebSocket = new WebSocket(
				webSocketId, url, protocols, "http://"+ServerAdress+"/", proxyHost, proxyPort,
				"", headers, this);
			newSocket.addEventListener("open", onSocketEvent);
			newSocket.addEventListener("close", onSocketEvent);
			newSocket.addEventListener("error", onSocketEvent);
			newSocket.addEventListener("message", onSocketEvent);
			webSockets[webSocketId] = newSocket;
		}
		
		public function send(webSocketId:int, encData:String):int {
			var webSocket:WebSocket = webSockets[webSocketId];
			return webSocket.send(encData);
		}
		
		public function close(webSocketId:int):void {
			var webSocket:WebSocket = webSockets[webSocketId];
			webSocket.close();
		}
		
		/**
		 * Socket event handler.
		 */
		public function onSocketEvent(event:WebSocketEvent):void {
			var eventObj:Object = parseEvent(event);
			if(eventObj.message!=null){
				if(debug){
					trace("recieved JSON:"+decodeURL(eventObj.message));
				}
				var data:Object=JSON.parse(decodeURL(eventObj.message));
				if(data.type=="welcome" && !loggedOn){
					login();
					loggedOn=false;
				}else{
					for(var i:Number=0;i<plugins.length;i++){
						if(plugins[i].ns==data.ns){
							plugins[i].processToken(data);
						}
					}
				}
			}
		}
		private function login(username:String="guest",password:String="guest"){
			var login:String="{\"ns\":\"org.jwebsocket.plugins.system\",\"type\":\"login\",\"username\":\"guest\",\"password\":\"guest\",\"encoding\":null,\"pool\":null,\"utid\":1}";
			send(0,login);
		}
		
		private function decodeURL(msg:String):String{
			msg=msg.split("%20").join(" "); 
			msg=msg.split("%22").join("\"");
			msg=msg.split("%23").join("#");
			msg=msg.split("%24").join("$");
			msg=msg.split("%25").join("%");
			msg=msg.split("%26").join("&");
			msg=msg.split("%2C").join(",");
			msg=msg.split("%3A").join(":"); 
			msg=msg.split("%3B").join(";"); 
			msg=msg.split("%3C").join("<");
			msg=msg.split("%3E").join("="); 
			msg=msg.split("%3F").join(">");
			msg=msg.split("%40").join("@");
			msg=msg.split("%5B").join("[");
			msg=msg.split("%5C").join("\\"); 
			msg=msg.split("%5D").join("]"); 
			msg=msg.split("%5E").join("^");
			msg=msg.split("%60").join("'"); 
			msg=msg.split("%7B").join("{"); 
			msg=msg.split("%7C").join("|"); 
			msg=msg.split("%7D").join("}"); 
			return msg;
		}
	}
}
'use strict'
var app = Elm.Main.init({ 
	node: document.getElementById('app')
});

app.ports.sendRequest.subscribe(function(data) {	
	window.external.invoke(JSON.stringify(data));
});

function sendResponse(str) {
	app.ports.receiveResponse.send(str);
}

var xhrInFlight = 0

function xhrDidFinish() {
	xhrInFlight -= 1;
	postDocument();
};

var open = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
	xhrInFlight += 1;

	this.addEventListener("load", function() {
		var body = this.responseText.trim();

		if (body.length == 0) { return } // Nothing to parse if the body is empty

		webkit.messageHandlers.xhr.postMessage(JSON.stringify({
			"url": this.responseURL,
			"status": this.status,
			"headers": this.getAllResponseHeaders().trim(),
			"body": body
		}));
	});

	this.addEventListener("load", xhrDidFinish);
	this.addEventListener("error", xhrDidFinish);
	this.addEventListener("abort", xhrDidFinish);

	open.apply(this, arguments);
};

var previousHTML = "";
function postDocument() {
	if (xhrInFlight > 0) { return }
	if (document.readyState !== "complete") { return }
	if (document.querySelector("meta[http-equiv='refresh']") !== null) { return }
	let html = window.document.documentElement.outerHTML;
	if (html === previousHTML) { return }
	webkit.messageHandlers.document.postMessage(html);
};

document.onreadystatechange = postDocument;

var observer = new MutationObserver(postDocument);

observer.observe(window.document.documentElement, {
	childList: true,
	attributes: true,
	subtree: true
});

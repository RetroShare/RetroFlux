var anfrage = null;

function erzeugeAnfrage() {
	try {
		anfrage = new XMLHttpRequest();
	} catch (versuchmicrosoft) {
		try {
			anfrage = new ActiveXObject("Msxml2.XMLHTTP");
		} catch (anderesmicrosoft) {
			try {
				anfrage = new ActiveXObject("Microsoft.XMLHTTP");
			} catch (fehlschlag) {
				anfrage = null;
			}
		}
	}

	if (anfrage == null) {
		alert("Fehler Anfrage-Objekt!");
	}
}
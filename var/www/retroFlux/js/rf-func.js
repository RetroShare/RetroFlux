$(document).ready(function() {
	$("#shareTable").tablesorter();
});
$(document).ready(function() {
	$("#searchTable").tablesorter();
});
$(document).ready(function() {
	$("#peersTable").tablesorter();
});
$(document).ready(function() {
	$("#chatlobbyTable").tablesorter();
});
$(document).ready(function() {
	$("#doc").fadeIn();
});

function getRSCFile(){
   document.getElementById("upfile").click();
}

function timedRefresh(timeoutPeriod) {
	//setTimeout("location.reload(true);",timeoutPeriod);
}

function changeDisplayCache() {
	if (document.getElementById('hideCache').checked) {
		var rows = document.getElementById('shareTable').getElementsByTagName("tbody")[0].getElementsByTagName("tr");
		for ( i = 0; i < rows.length; i++) {
			//var anchor = rows[i].getElementsByTagName("td")[0].getElementsByTagName("a")[0];
			var anchor = rows[i].getElementsByTagName("td")[0];
			//alert(anchor.innerHTML);
			if (anchor.innerHTML.match(/^\b([a-f0-9]{40})\b$/g)) {
				//rows[i].style.display = "none";
				$(rows[i]).fadeOut();
			}
		}
	} else {
		var rows = document.getElementById('shareTable').getElementsByTagName("tbody")[0].getElementsByTagName("tr");
		for ( i = 0; i < rows.length; i++) {
			//rows[i].style.display = "";
			$(rows[i]).fadeIn();
		}
	}
}

function changeDisplayOffline() {
	if (document.getElementById('hideOffline').checked) {
		var rows = document.getElementById('peersTable').getElementsByTagName("tbody")[0].getElementsByTagName("tr");
		for ( i = 0; i < rows.length; i++) {
			var anchor = rows[i].getElementsByTagName("td")[3];
			if (anchor.innerHTML.match(/^OFFLINE$/g)) {
				$(rows[i]).fadeOut();
			}
		}
	} else {
		var rows = document.getElementById('peersTable').getElementsByTagName("tbody")[0].getElementsByTagName("tr");
		for ( i = 0; i < rows.length; i++) {
			$(rows[i]).fadeIn();
		}
	}
}

function getSystemStatus() {
	erzeugeAnfrage();
	var url = "status-ajax.cgi";
	anfrage.open("GET", url, true);
	anfrage.onreadystatechange = updateStatusSeite;
	anfrage.send(null);
}

function updateStatusSeite() {
	if (anfrage.readyState == 4) {
		if (anfrage.status == 200) {
			var jsonData = eval('(' + anfrage.responseText + ')');

			var newPeers = jsonData.peers;
			var newConnected = jsonData.connected;
			var newNetstatus = jsonData.netstatus;
			var newDown = jsonData.download;
			var newUp = jsonData.upload;

			var peers = document.getElementById("peers");
			var connected = document.getElementById("connected");
			var netstatus = document.getElementById("netstatus");
			var download = document.getElementById("download");
			var upload = document.getElementById("upload");

			replaceText(peers, newPeers);
			replaceText(connected, newConnected);
			replaceText(netstatus, newNetstatus);
			replaceText(download, newDown);
			replaceText(upload, newUp);

		} else {
			//alert("ERROR!");
		}
	}
}

function updateCollectionSite() {
	if (anfrage.readyState == 4) {
		if (anfrage.status == 200) {
			var jsonData = eval('(' + anfrage.responseText + ')');
			var newHashes = jsonData.hashes;
			
			//var allFileHashes = [];
			for (var i = 0; i < newHashes.length; i++) {
				var fhtab = document.getElementById(newHashes[i]);
	            $(fhtab).fadeOut();
		        //alert(allFileHashes[i]);
		        //Do something
		    }

		} else {
			//alert("ERROR!");
		}
	}
}

function removePeer(peergpg) {
	erzeugeAnfrage();
	var url = "peer-ajax.cgi?action=removepeer&gpgid=" + peergpg;
	anfrage.open("GET", url, true);
	// anfrage.onreadystatechange = updateDownloadFile;
	anfrage.send(null);
	var dftab = document.getElementById(peergpg);
	$(dftab).fadeOut();
}

function downloadFile(filename, filesize, filehash) {
	erzeugeAnfrage();
	var url = "file-ajax.cgi?action=startdownload&name=" + filename + "&size=" + filesize + "&hash=" + filehash;
	anfrage.open("GET", url, true);
	// anfrage.onreadystatechange = updateDownloadFile;
	anfrage.send(null);
	var dftab = document.getElementById(filehash);
	$(dftab).fadeOut();
}

function downloadAllFiles() {
	erzeugeAnfrage();
	var url = "file-ajax.cgi";
	anfrage.open("POST", url, true);
	anfrage.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	
	var shareTableTmp = document.getElementById('shareTable');
	var shareTableRowLength = shareTableTmp.rows.length;
	var shareTableRows = shareTableTmp.rows;
	var allFilesVal = "";
	
	for (i = 1; i < shareTableRowLength; i++) {
		var shareTableCells = shareTableTmp.rows.item(i).cells;
		var shareTableCellLength = shareTableCells.length;
		var shareTableCellVal = shareTableCells.item(2);
		// var shareTableShareFile = shareTableCells.item(2).form.shareFile.onclick;
		allFilesVal += shareTableCellVal.innerHTML;
	}
	
	//var allFilesSplit = allFilesVal.split('</form><form name="sharedwnfile" method="get">');
	var allFilesReplace1 = allFilesVal.replace(/<form name="sharedwnfile" method="get">/g,'');
	var allFilesReplace2 = allFilesReplace1.replace(/<\/form>/g,'');
	
	anfrage.onreadystatechange = updateCollectionSite;
	anfrage.send("action=startdownloadallfiles&allfiles="+encodeURIComponent(allFilesReplace2));
}

function updateDownloadFile() {
	if (anfrage.readyState == 4) {
		if (anfrage.status == 200) {
			var jsonData = eval('(' + anfrage.responseText + ')');
			if (jsonData.status == 1) {
				var tab = document.getElementById(jsonData.hash);
				$(tab).fadeOut();
			}
		} else {
			//alert("ERROR!");
		}
	}
}

function restartDownload(filename, filesize, filehash) {
	erzeugeAnfrage();
	var url = "file-ajax.cgi?action=restartdownload&name=" + filename + "&size=" + filesize + "&hash=" + filehash;
	anfrage.open("GET", url, true);
	// anfrage.onreadystatechange = restartSharelist;
	anfrage.send(null);
	var rdtab = document.getElementById(filehash);
	$(rdtab).fadeOut();
	$(rdtab).fadeIn("slow");
}

function pauseDownload(filename, filesize, filehash) {
	erzeugeAnfrage();
	var url = "file-ajax.cgi?action=pausedownload&name=" + filename + "&size=" + filesize + "&hash=" + filehash;
	anfrage.open("GET", url, true);
	// anfrage.onreadystatechange = restartSharelist;
	anfrage.send(null);
	var pdtab = document.getElementById(filehash);
	$(pdtab).fadeOut();
	$(pdtab).fadeIn("slow");
}

function joinChatlobby(lobbyid) {
	erzeugeAnfrage();
	var url = "chatlobby-ajax.cgi?action=joinlobby&lobbyid=" + lobbyid;
	anfrage.open("GET", url, true);
	anfrage.onreadystatechange = location.reload(true);
	anfrage.send(null);
	//var rdtab = document.getElementById(lobbyid);
	//$(rdtab).fadeOut();
	//$(rdtab).fadeIn("slow");
}

function leaveChatlobby(lobbyid) {
	erzeugeAnfrage();
	var url = "chatlobby-ajax.cgi?action=leavelobby&lobbyid=" + lobbyid;
	anfrage.open("GET", url, true);
	anfrage.onreadystatechange = location.reload(true);
	anfrage.send(null);
	//var rdtab = document.getElementById(lobbyid);
	//$(rdtab).fadeOut();
	//$(rdtab).fadeIn("slow");
}

function restartSharelist() {
	if (anfrage.readyState == 4) {
		if (anfrage.status == 200) {
			var jsonData = eval('(' + anfrage.responseText + ')');
			if (jsonData.status == 1) {
				var tab = document.getElementById(jsonData.hash);
                location.reload(true);
			}
		} else {
			//alert("ERROR!");
		}
	}
}

function stopDownload(filename, filesize, filehash) {
	erzeugeAnfrage();
	var url = "file-ajax.cgi?action=stopdownload&name=" + filename + "&size=" + filesize + "&hash=" + filehash;
	anfrage.open("GET", url, true);
	// anfrage.onreadystatechange = updateSharelist;
	anfrage.send(null);
	var sdtab = document.getElementById(filehash);
	$(sdtab).fadeOut();
}

function updateSharelist() {
	if (anfrage.readyState == 4) {
		if (anfrage.status == 200) {
			var jsonData = eval('(' + anfrage.responseText + ')');
			if (jsonData.status == 1) {
				var tab = document.getElementById(jsonData.hash);
				$(tab).fadeOut();
			}
		} else {
			//alert("ERROR!");
		}
	}
}
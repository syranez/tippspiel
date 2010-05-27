BEGIN {
	FS = ";"
	print "# Für jedes Spiel kann ein Tipp abgegeben werden. Man kann auch nur selektiv Spiele tippen."
	print "# Ab dem Achtelfinale können zusätzlich auch die Mannschaften getippt werden."
	print "# Beachte: Ersetze nur die jeweiligen '-' mit Deinen Tipps. Unlesbare Datensätze werden ignoriert."
	print

	# Ab dieser Match-ID stehen die Teams noch nicht fest und können daher auch getippt werden.
	TIPP_TEAMS_TOO = 49
	count = 1
	tipps = "Tipp: (-:-)"
	gruppe = ""
}

{
	if ( count >= TIPP_TEAMS_TOO ) {
		$6 = "(-)";
		$7 = "(-)";
		
	}

	getGroup($2);
	printf("Spiel %2s - %16s: %-20sversus%20s: %s\n", $1, gruppe, $6, $7, tipps);
	count++;
}

function getGroup(groupCode) {
	if ( groupCode == "GroupA") {
		gruppe = "Gruppe A"
	} else 	if ( groupCode == "GroupB") {
		gruppe = "Gruppe B"
	} else 	if ( groupCode == "GroupC") {
		gruppe = "Gruppe C"
	} else if ( groupCode == "GroupD") {
		gruppe = "Gruppe D"
	} else if ( groupCode == "GroupE") {
		gruppe = "Gruppe E"
	} else if ( groupCode == "GroupF") {
		gruppe = "Gruppe F"
	} else if ( groupCode == "GroupG") {
		gruppe = "Gruppe G"
	} else if ( groupCode == "GroupH") {
		gruppe = "Gruppe H"
	} else if ( match(groupCode, "AF*") ) {
		gruppe = "Achtelfinale " substr(groupCode, 3, 1)
	} else if ( match(groupCode, "VF*") ) {
		gruppe = "Viertelfinale " substr(groupCode, 3, 1)
	} else if ( match(groupCode, "HF*") ) {
		gruppe = "Halbfinale " substr(groupCode, 3, 1)
	} else if ( match(groupCode, "P3") ) {
		gruppe = "Spiel um Platz 3"
	} else {
		gruppe = "Finale"
	}
}

BEGIN {
	ab = 49;
	team1 = "-";
	team2 = "-";
	tipp_team1 = "";
	tipp_team2 = "";
}


function getTipp() {
	tipp_position = index($0, "Tipp: (") + 7;
	tipp = substr($0, tipp_position, 10);

	tipp_doppelpunkt = index(tipp, ":");
	tipp_team1 = substr(tipp, 0, tipp_doppelpunkt - 1 )

	tipp_klammer = index(tipp, ")");
	tipp_team2 = substr(tipp, tipp_doppelpunkt + 1, tipp_klammer  - (tipp_doppelpunkt+1) )
}

{
	tempSplit[1] = "";
	split($2, tempSplit, ":");

	getTipp();
	
	print tempSplit[1] ";" team1 ";" team2 ";" tipp_team1 ";" tipp_team2

	count++;
}

#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper; #debug

#use CGI::Carp qw(fatalsToBrowser);

#
# Settings
#

# Name of game
my $GameName;

# Matches count where game players are set, not tip players.
my $PlayersSetCount;

# Turnier data table
my @TD_Table;

# Gamer data table
my @GamerData_Table;

# Count of Gamers
my $GamerCount = 0;

# Gamer_Points contains the scored Points for each Gamer
my %Gamer_Points;

# Interpret TableData as #1;GroupA;07.06.2008;18:00;Basel;Schweiz;Tschechien;-;-
my @TDC = qw(ID TYPE DATE CLOCK PLACE FIRST SECOND FIRST_SCORE SECOND_SCORE);
my %TD = map { $TDC[$_] => $_ } 0 .. $#TDC;

# Interpret PD_Table
my @GDC = qw(ID FIRST SECOND FIRST_SCORE SECOND_SCORE);
my %GD = map { $GDC[$_] => $_ } 0 .. $#GDC;

# Long names for rounds
my %longname = (
    (map { ("Group$_" => "Gruppe $_") } "A" .. "Z"),
    "AF*" => "Achtelfinale",
    "VF*" => "Viertelfinale",
    "HF*" => "Halbfinale",
    "P3" => "Spiel um Platz 3",
    "FINAL" => "Finale"
    );

# No data available yet
my $NO_DATA = "-";

# URI of the tip game.
my $TIPP_GAME_URI = "http://www.minaga-church.de/cgi-bin/tippspiel/tippspiel.pl";

my @ZEILEN;

#
# Code
#

# Lese und parse Argumente
# Read Argument
my $ArgumentString = $ENV{'QUERY_STRING'} || '';
my @Arguments = split(/&/,$ArgumentString);
my @Temp;

my $GameData = "NONE";
my $Gamer = "NONE";

foreach (@Arguments) {
   @Temp = split(/=/,$_);
   
   if ( $Temp[0] eq "id" ) {
      $GameData = $Temp[1];
   }
   elsif ( $Temp[0] eq "user" ) {
      $Gamer = $Temp[1];
   }
}

if ( $GameData ne "wm2006" and $GameData ne "em2008" ) {
   $GameData = "wm2010";
}


# Get data of game
readGameData($GameData);

if ( $Gamer ne "NONE" ) {
extractGamersData($Gamer);
}

print PrintDocument($GameData);

#
# Print Stuff
#

# Erzeugt die Webseite
# Argumente: 0: Turnier
# Return: -
sub PrintDocument {

    # Punktetabelle der Spieler
    my $OUTPUT;

    if ( $_[0] eq "wm2006" ) {
        $PlayersSetCount = 48;
        $GameName = "Weltmeisterschaft 2006";
        $OUTPUT .=
            PrintRounds("GroupA", "GroupB", "GroupC", "GroupD", "GroupE", "GroupG", "GroupH", "AF*", "VF*", "HF*", "P3", "FINAL");
    }
    elsif ( $_[0] eq "wm2010" ) {
        $PlayersSetCount = 48;
        $GameName = "Weltmeisterschaft 2010";
        $OUTPUT .=
            PrintRounds("GroupA", "GroupB", "GroupC", "GroupD", "GroupE", "GroupG", "GroupH", "AF*", "VF*", "HF*", "P3", "FINAL");

    }
    elsif ( $_[0] eq "em2008" ) {
        $PlayersSetCount = 24;
        $GameName = "Europameisterschaft 2008";
        $OUTPUT .=
            PrintRounds("GroupA", "GroupB", "GroupC", "GroupD", "VF*", "HF*", "FINAL");
    }

    return PrintHTMLHeader().PrintHTMLTop().PrintGamerTable().$OUTPUT."</body></html>\n";
}

# Schreibt den HTML-Header
# Argumente: -
# Return: HTML-String
#	<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"> \n \
sub PrintHTMLHeader {
    return <<EOT;
Content-type: text/html

<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head><title>$GameName</title>
<link rel=\"stylesheet\" type=\"text/css\" href=\"http://www.minaga-church.de/tippspiel/tipgame.css\" />
<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
</head>
EOT
}

sub PrintHTMLTop {
    my $CTIME_String = localtime(time);

    return
        "<body><div align=\"center\"> \
        <span id=\"TG_Header_Title\">$GameName</span>"
        . PrintFreeSpace()
        . "<span id=\"TG_Header_StatsCreated\">Statistik erstellt am $CTIME_String.</span> \
        </div>"
        . PrintFreeSpace();
}

# Schreibt die Punktetabelle der Spieler
# Argumente: -
# Return: HTML-String
sub PrintGamerTable {
    my $HighestPoints;
    my @Gamers;
    my $Position = 1;
    my $Points = 0;
    my $RowColor = 0;
    my $OUTPUT =
        "<div align=\"center\">"
        .PrintHeader("Spieler Statistik")
        ."<table style=\"background-color:#BABADC;border-spacing:2px;text-align:center\"> \
        <tr> \
            <td id=\"TG_Player_HeadRank\">Position</td> \
            <td id=\"TG_Player_HeadPlayer\">Spieler</td> \
            <td id=\"TG_Player_HeadPoints\">Punkte</td> \
        </tr>";

    readGamersData();
    my @Result = crappyHashSort();
    my $prePoints = 0;

    for ( my $i = 0; $i < 2*(my $Anzahl = keys(%Gamer_Points)); $i += 2 ) {
 	if ( $prePoints == $Result[$i+1] ) {
        	$Position--;
	}      
        $OUTPUT .= "<tr class=\"TG_MTS_ContentRow".$RowColor."\"> \
                <td>".$Position."</td> \
                <td><a href=\"".$TIPP_GAME_URI."?id=".$GameData."\&amp;user=".$Result[$i]."\">".$Result[$i]."</a></td> \
                <td>".$Result[$i+1]."</td> \
            </tr>";
	$prePoints = $Result[$i+1];
        $Position++;
        $RowColor = ($RowColor+1)%2;
    }

    return $OUTPUT."</table></div>".PrintFreeSpace();
}

sub PrintRounds(@) {
    return join "", map { PrintRound($_) } @_;
}

# Schreibt den HTML-Quelltext fuer eine Runde des Turniers
# Argumente: 0: Rundenname ; 1: Runden-ID
# Return: HTML-String
sub PrintRound($) {
    my ($RoundID) = @_;
    my $RoundName = $longname{$RoundID};

    my $OUTPUT =
        "<div align=\"center\"> \
        <table width=\"80%\"><tr><td>"
        .PrintRoundData($RoundName, $RoundID)
        ."</td><td>";

    if ( $RoundID =~ /^Group/ )
    {
        if ( not isNoDataOverallAvailable($RoundID) ) {
            $OUTPUT .= PrintRoundTable($RoundName, $RoundID);
        }
    }

    # Schreibe extra Tabelle, falls nun auch die Mannschaften vom Spieler getippt wurden
    # Normalerweise alles ueber den Gruppenphasen.
    else {
        if ( $Gamer ne "NONE" ) {
            $OUTPUT .= PrintRoundTipp($RoundName, $RoundID);
        }
    }

    return $OUTPUT."</td></tr></table></div>".PrintFreeSpace();
}

# Schreibt die Begegnungen der jeweiligen Turnierrunde und evtl. die Tipps
# Argumente: 0: Rundenname ; 1: Runden-ID
# Return: HTML-String
sub PrintRoundData {
    my $RoundName = shift;
    my $RoundID = shift;
    my $MatchID = 0;
    my $RowColor = 0;
    my $TablePosition = 1;

    # Header
    my $OUTPUT =
        "<div align=\"center\">"
        .PrintHeader($RoundName)
        . "<table class=\"TG_MTS_Table\"> \
        <tr> \
            <td>Datum</td> \
            <td>Uhrzeit</td> \
            <td>Ort</td> \
            <td>Spiel</td> \
            <td>Ergebnis</td>";
        if ( isGamer($Gamer) and ($RoundID =~ /^Group/) ) {
            $OUTPUT .= "<td>Tipp</td>";
        }

        $OUTPUT .= "</tr>";

    # Matches
    for ( $MatchID = 0; $MatchID <= $#TD_Table; $MatchID++ )
    {
        if ( isMatchTyp($MatchID, $RoundID) ) {
            $OUTPUT .=
                "<tr class=\"TG_MTS_ContentRow".$RowColor."\"> \
                <td>$TD_Table[$MatchID][$TD{DATE}]</td> \
                <td>$TD_Table[$MatchID][$TD{CLOCK}]</td> \
                <td>$TD_Table[$MatchID][$TD{PLACE}]</td> \
                <td>$TD_Table[$MatchID][$TD{FIRST}] - $TD_Table[$MatchID][$TD{SECOND}]</td>";
		if ( $TD_Table[$MatchID][$TD{FIRST_SCORE}] eq '' ) {
			$OUTPUT .= "<td>-</td>";
		}
		else {
	                $OUTPUT .= "<td>$TD_Table[$MatchID][$TD{FIRST_SCORE}] : $TD_Table[$MatchID][$TD{SECOND_SCORE}]</td>";
		}
                if ( isGamer($Gamer) and ($RoundID =~ /^Group/) ) {
                    if ( compareTipAndResult($MatchID) == 0 )
                    {
                        # kein korrekter Tipp
                        $OUTPUT .= "<td><span> \
                            <font style=\"color:#FF0000\">".$GamerData_Table[$MatchID][$GD{FIRST_SCORE}]."</font> : \
                            <font style=\"color:#FF0000\">".$GamerData_Table[$MatchID][$GD{SECOND_SCORE}]."</font></span></td>";
                    }
                    elsif ( compareTipAndResult($MatchID) == 1 )
                    {
                        # Tendenz richtig
                        $OUTPUT .= "<td><span> \
                            <font style=\"color:orange\">".$GamerData_Table[$MatchID][$GD{FIRST_SCORE}]."</font> : \
                            <font style=\"color:orange\">".$GamerData_Table[$MatchID][$GD{SECOND_SCORE}]."</font></span></td>";
                    }
                    elsif ( compareTipAndResult($MatchID) == 3 )
                    {
                        # richtiger Tipp
                        $OUTPUT .= "<td><span> \
                            <font style=\"color:green\">".$GamerData_Table[$MatchID][$GD{FIRST_SCORE}]."</font> : \
                            <font style=\"color:green\">".$GamerData_Table[$MatchID][$GD{SECOND_SCORE}]."</font></span></td>";
                    }
                    else
                    {
                        if ( isGamerDataAvailable($MatchID) ) {
                            $OUTPUT .= "<td><span> \
                                <font>".$GamerData_Table[$MatchID][$GD{FIRST_SCORE}]."</font> : \
                                <font>".$GamerData_Table[$MatchID][$GD{SECOND_SCORE}]."</font></span></td>";
                        }
                        else {
                            $OUTPUT .= "<td></td>";
                        }
                    }
                }

                $OUTPUT .= "</tr>";
                $RowColor = ($RowColor+1)%2;
        }
    }

    return $OUTPUT."</table></div>";
}

# Schreibt die Tabelle fuer die Gruppenbegegnungen
# Argumente: 0: Rundenname ; 1: Runden-ID
# Return: HTML-String
sub PrintRoundTable {
    my $RoundName = shift;
    my $RoundID = shift;
    my $MatchID = 0;
    my $RowColor = 0;
    my $TablePosition = 1;
    my %Teams;
    my %ShotTors;
    my %GotTors;

    my $OUTPUT =
        "<div align=\"center\">"
        .PrintHeader("Tabelle")
        ."<table class=\"TG_MTS_Table\"> \
        <tr> \
            <td>Platz</td> \
            <td>Mannschaft</td> \
            <td>Tore</td> \
            <td>Punkte</td></tr>";

    # Tabellendaten berechnen
    for ( $MatchID = 0; $MatchID <= $#TD_Table; $MatchID++ ) {
        if ( isMatchTyp($MatchID, $RoundID) and isDataAvailable($MatchID) ) {
            $Teams{$TD_Table[$MatchID][$TD{FIRST}]} += 0;
	    $Teams{$TD_Table[$MatchID][$TD{SECOND}]} += 0;

            $ShotTors{$TD_Table[$MatchID][$TD{FIRST}]} += $TD_Table[$MatchID][$TD{FIRST_SCORE}];
            $ShotTors{$TD_Table[$MatchID][$TD{SECOND}]} += $TD_Table[$MatchID][$TD{SECOND_SCORE}];
            $GotTors{$TD_Table[$MatchID][$TD{FIRST}]} += $TD_Table[$MatchID][$TD{SECOND_SCORE}];
            $GotTors{$TD_Table[$MatchID][$TD{SECOND}]} += $TD_Table[$MatchID][$TD{FIRST_SCORE}];

            # Erster Spieler
            if ( $TD_Table[$MatchID][$TD{FIRST_SCORE}] > $TD_Table[$MatchID][$TD{SECOND_SCORE}] ) {
                # Spieler 1 hat gewonnen
                $Teams{$TD_Table[$MatchID][$TD{FIRST}]} += 3;
            }

            elsif ( $TD_Table[$MatchID][$TD{FIRST_SCORE}] == $TD_Table[$MatchID][$TD{SECOND_SCORE}] ) {
                    # Unentschieden
                    $Teams{$TD_Table[$MatchID][$TD{FIRST}]} += 1;
            }

            # Zweiter Spieler
            if ( $TD_Table[$MatchID][$TD{SECOND_SCORE}] > $TD_Table[$MatchID][$TD{FIRST_SCORE}] ) {
                # Spieler 2 hat gewonnen
                $Teams{$TD_Table[$MatchID][$TD{SECOND}]} += 3;
            }

            elsif ( $TD_Table[$MatchID][$TD{SECOND_SCORE}] == $TD_Table[$MatchID][$TD{FIRST_SCORE}] ) {
                # Unentschieden
                $Teams{$TD_Table[$MatchID][$TD{SECOND}]} += 1;
            }
        }
    }

    # Reihenfolge berechnen
    my $TeamCount = keys(%Teams);
    my @sortKeys;
    my $HighestPoints = 0;
    my $Player;

    while ( (my $Anzahl = keys(%Teams)) > 0 )
    {
        $HighestPoints = 0;
        @sortKeys = sort keys %Teams;

        foreach (@sortKeys)
        {
            if ( $Teams{$_} >= $HighestPoints )
            {
                $Player = $_;
                $HighestPoints = $Teams{$_};
            }
        }

        # hat jemand auch so viele Punkte?
        foreach (@sortKeys)
        {
            if ( $Teams{$_} == $HighestPoints and $_ ne $Player )
            {
                # Tordifferenz berechnen
                if ( $ShotTors{$_}-$GotTors{$_} >= $ShotTors{$Player}-$GotTors{$Player} )
                {
                    $Player = $_;
                }
                # Was wenn es gleich ist?
            }
        }

        my $Position = $TeamCount - $Anzahl + 1;
        $OUTPUT .=
                "<tr class=\"TG_MTS_ContentRow".$RowColor."\"> \
                <td>".$Position."</td> \
                <td>".$Player."</td> \
                <td>".$ShotTors{$Player}." : ".$GotTors{$Player}."</td> \
                <td>".$Teams{$Player}."</td></tr>";
        $RowColor = ($RowColor+1)%2;
        delete $Teams{$Player}; delete $ShotTors{$Player}; delete $GotTors{$Player};
    }

    return $OUTPUT."</table></div>";
}

# Gibt den Tipp des Spielers fuer die jeweilige Runde aus
# Argumente: 0: Rundenname ; 1: Round-ID
# Return: HTML-String
sub PrintRoundTipp {
    my $RoundName = shift;
    my $RoundID = shift;
    my $MatchID = 0;
    my $RowColor = 0;

    my $OUTPUT =
        "<div align=\"center\">"
        .PrintHeader("Tipp")
        . "<table class=\"TG_MTS_Table\"> \
        <tr id=\"PSSG_Server_HeadRow\">  \
            <td>Spiel</td> \
            <td>Ergebnis</td></tr>";

    for ( $MatchID = $PlayersSetCount; $MatchID <= $#TD_Table; $MatchID++ ) {
        if ( isMatchTyp($MatchID, $RoundID) ) {
            $OUTPUT .=
                "<tr class=\"TG_MTS_ContentRow".$RowColor."\"> \
                <td> \
                <span>".$GamerData_Table[$MatchID][$GD{FIRST}] ."</span> - <span>". $GamerData_Table[$MatchID][$GD{SECOND}] ."</span></td> \
                <td><span>".$GamerData_Table[$MatchID][$GD{FIRST_SCORE}] ."</span> : <span>". $GamerData_Table[$MatchID][$GD{SECOND_SCORE}] ."</span></td> \
                </tr>";
                $RowColor = ($RowColor+1)%2;
        }
    }

    return $OUTPUT."</table></div>";
}

# Schreibt einen Freiraum
# Argumente: -
# Return: HTML-String
sub PrintFreeSpace {
    return "<br /><br /><br />";
}

# Schreibt den Titel einer Tabelle
# Argumente: 0: Titel
# Return: HTML-String
sub PrintHeader {
    return "<span class=\"TG_MTS_TextTitle\">".$_[0]."</span>";
}

#
# Datenauswertung
#

# Liest die Turnierdaten aus
# Argumente: Name des Turniers
# Return: -
sub readGameData {
    my @DataSet;
    my $i = 0;
    my $j = 0;

    # Read $GameData
    open(file_GameData, "<$_[0]/$_[0]") || die "File $_[0] not found.";
    my @Zeilen = <file_GameData>;
    close(file_GameData);

    # Interpret $GameData
    foreach(@Zeilen) {
        @DataSet = split(/;/,$_);
        foreach(@DataSet) {
            $TD_Table[$i][$j] = $_;
            $j++;
        }
        $i++;
        $j = 0;
    }
}

sub readGamersData {
	opendir(DIR,$GameData."/players/") || die "Could not open Players Folder: $! $GameData";
	my @Entrys = readdir(DIR);
	closedir(DIR);
	foreach(@Entrys)
	{
        if ( $_ ne '.' and $_ ne ".." ) {
            $GamerCount++;
            GivePoints($_,0);
            extractGamerPoints($_);
        }
	}
}

sub extractGamersData {
    my $Gamer = shift;
    my $GamerPoints;    # pro Match
    my @DataSet;
    my $i = 0;
    my $j = 0;

    # Read data of $Gamer
    open(file_Player, "<$GameData/players/$Gamer") || die "$_[0] not found.";
    my @Lines = <file_Player>;
    close(file_Player);

    # Interpret $GameData
    foreach(@Lines) {
        @DataSet = split(/;/,$_);
        foreach(@DataSet) {
            $GamerData_Table[$i][$j] = $_;
            $j++;
        }
        $i++;
        $j = 0;
    }
}

# Berechnet die Punkte jedes Spielers
# Argumente: 0: Spieler
# Return: -
sub extractGamerPoints {
    my $Gamer = shift;
    my $GamerPoints;    # pro Match

    my @DataSet;
    my $i = 0;
    my $j = 0;

    # Read data of $Gamer
    open(file_Player, "<$GameData/players/$Gamer") || die "$_[0] not found.";
    my @Lines = <file_Player>;
    close(file_Player);

    # Interpret $GameData
    foreach(@Lines) {
        @DataSet = split(/;/,$_);
        foreach(@DataSet) {
            $GamerData_Table[$i][$j] = $_;
            $j++;
        }
        $i++;
        $j = 0;
    }

    # Give Points for Matches, where the opponents were known before game begin.
    for ( $i = 0; $i < $PlayersSetCount; $i++ ) {
        $GamerPoints = compareTipAndResult($i);
        if ( $GamerPoints != -1 ) { GivePoints($Gamer,$GamerPoints); }
    }

    # Give extra points for matches, where the game teams are correct set by gamer
    for ( $i = $PlayersSetCount; $i <= $#TD_Table; $i++ ) {
        if ( compareSetTeams($i) == 1 ) {
            # one team is correct
            GivePoints($Gamer,1);
        }
        elsif ( compareSetTeams($i) == 2 ) {
            # set teams are correct
            GivePoints($Gamer,2);
            # go check the result
            $GamerPoints = compareTipAndResult($i);
            if ( $GamerPoints != -1 ) { GivePoints($Gamer,$GamerPoints); }
        }
    }
}

# Vergleicht für Match-ID $_[0] das Ergebnis mit dem Tipp
# Argument: 0: Match-ID
# Return: 1: wenn Unentschieden ; 3: Richtiger Tipp ; 0: Falscher Tipp
sub compareTipAndResult {
    if ( isDataAvailable($_[0]) and isGamerDataAvailable($_[0]) ) {
        if ( isTippCorrect($_[0]) ) {
            # Richtigen Tipp abgegeben
            return 3;
        }
        elsif ( isWinnerTippCorrect($_[0]) ) {
            return 1;
        }

        # Keinen richtigen Tipp gegeben
        return 0;
    }

    # NO DATA available
    return -1;
}

# Vergleicht die gesetzen Teams im KO-Modus
# Pro richtig gesetztem Team gibt es einen Punkt.
# Aufruf compareSetTeams($Player,$i);
sub compareSetTeams {
    my $MatchID = shift;

    if ( isDataAvailable($MatchID) and isGamerDataAvailable($MatchID) ) {
        if ( isGamersTeamTipCorrect($MatchID, $TD{FIRST}, $GD{FIRST}) and
            isGamersTeamTipCorrect($MatchID, $TD{SECOND}, $GD{SECOND}) ) {
            # Wenn der Spieler beide Teams richtig gesetzt hat, gibt es zwei Punkte
            return 2;
        }
        elsif ( isGamersTeamTipCorrect($MatchID, $TD{FIRST}, $GD{FIRST}) or
                isGamersTeamTipCorrect($MatchID, $TD{SECOND}, $GD{SECOND}) ) {
            # Wenn der Spieler ein Team richtig gesetzt hat, gibt es einen Punkt
            return 1;
        }
    }

    return 0;
}

# Berechnet den Sieger eines Spiels
# Argumente: 0: Erstes Team ; 1: Zweites Team
# Return: 1: Erstes Team hat gewonnen ; 2: Zweites Team hat gewonnen ; 0: Unentschieden
sub MatchWinner {
    if ( $_[0] > $_[1] ) {
        # Erstes Team hat gewonnen
        return 1;
    }
    elsif ( $_[1] > $_[0] ) {
        # Zweites Team hat gewonnen
        return 2;
    }

    # Unentschieden
    return 0;
}

#
# Data Manipulation
#

# Gibt $Gamer $GamerPoints Punkte;
# Argumente: 0: $Gamer ; 1: $GamerPoints
# Return: -
# Aufruf: GivePoints($Gamer, $GamerPoints);
sub GivePoints {
    $Gamer_Points{$_[0]} += $_[1];
}

#
# is-Functions
#

# Überprueft, ob die Daten fuer Spiel $_[0] verfuegbar sind
# Argument: Spiel-ID
# Return: 0, wenn nein ; 1, wenn ja
sub isDataAvailable {
        ($TD_Table[$_[0]][$TD{FIRST}] eq $NO_DATA
    or
        $TD_Table[$_[0]][$TD{FIRST_SCORE}] eq $NO_DATA
    or
        $TD_Table[$_[0]][$TD{SECOND_SCORE}] eq $NO_DATA) ? return 0 : return 1;
}

sub isGamerDataAvailable {
        #($GamerData_Table[$_[0]][$GD{FIRST}] eq $NO_DATA
    #or (
        $GamerData_Table[$_[0]][$GD{FIRST_SCORE}] eq $NO_DATA
    #and
        # $GamerData_Table[$_[0]][$GD{SECOND_SCORE}] eq $NO_DATA) )
         ? return 0 : return 1;
}

# Überprüft, ob keine Daten fuer Argument 0 vorliegen
# Argument: 0: Group-ID
# Return: 1, wenn keine Daten vorliegen ; 0: wenn Daten vorliegen
sub isNoDataOverallAvailable {
    for ( my $i = 0; $i <= $#TD_Table; $i++ )
    {
        if ( ($TD_Table[$i][$TD{TYPE}] eq $_[0]) and isDataAvailable($i) ) {
            return 0;
        }
    }

    return 1;
}

# Überprueft, ob der Spieler das richtige Team gesetzt hat.
# Argumente: Spiel-ID und $TD_FIRST / $TD_SECOND und $PD_FIRST / $PD_SECOND
# Return: 0, wenn nein ; 1, wenn ja
# Aufruf: isGamersTeamTipCorrect($MatchID,$TD_FIRST,$PD_FIRST);
sub isGamersTeamTipCorrect {
    $TD_Table[$_[0]][$_[1]] eq $GamerData_Table[$_[0]][$_[2]] ? return 1 : return 0;
}

# Überprueft, ob der Spieltyp von Argument 0 gleich Argument 1 ist.
# Argument: Spiel-ID, Spieltyp
# Return 0, wenn nein ; 1, wenn ja
# Aufruf: isMatchTyp($MatchID, $MatchTyp);
sub isMatchTyp {
    $TD_Table[$_[0]][$TD{TYPE}] =~ /^$_[1]/ ? return 1 : return 0;
}

# Überprueft, ob Argument 0 nicht gleich "NONE" ist.
# Argument: $Gamer
# Return 0, wenn nein ; 1, wenn ja
# Aufruf: isGamer($Gamer);
sub isGamer {
    $_[0] ne "NONE" ? return 1 : return 0;
}

# Überprüft, ob der Tipp korrekt ist
# Argument: $_[0]: Match-ID
# Return: 1, wenn korrekt ; 0; wenn nicht korrekt
sub isTippCorrect {
        $GamerData_Table[$_[0]][$GD{FIRST_SCORE}] == $TD_Table[$_[0]][$TD{FIRST_SCORE}]
    and
        $GamerData_Table[$_[0]][$GD{SECOND_SCORE}] == $TD_Table[$_[0]][$TD{SECOND_SCORE}] ? return 1 : return 0;
}

# Überprüft, ob der Gewinner korrekt getippt wurde
# Argument: $_[0]: Match-ID
# Return: 1, wenn korrekt ; 0; wenn nicht korrekt
sub isWinnerTippCorrect {
        MatchWinner($GamerData_Table[$_[0]][$GD{FIRST_SCORE}],$GamerData_Table[$_[0]][$GD{SECOND_SCORE}])
    eq
        MatchWinner($TD_Table[$_[0]][$TD{FIRST_SCORE}],$TD_Table[$_[0]][$TD{SECOND_SCORE}]) ? return 1 : return 0;
}

#
#   some nasty stuff
#

sub crappyHashSort {
    my $i = 0;
    my @sortierteSchluessel = sort keys %Gamer_Points;
    my @V;
    my $Dubletten = -1;
    my $Number = 0;
    my @Result;
    my $ResultCounter = 0;

    # Read values
    foreach(@sortierteSchluessel) {
        $V[$i] = $Gamer_Points{$_};
        $i++;
    }

    my @sortedValues = sort {$b <=> $a} @V;

    foreach(@sortedValues){
        if ( $_ != $Dubletten ) {
            $Number = $_;
            $Dubletten = $_;
            foreach(@sortierteSchluessel){
                if ( $Gamer_Points{$_} == $Number ) {
                    $Result[$ResultCounter] = $_;
                    $ResultCounter++;
                    $Result[$ResultCounter] = $Number;
                    $ResultCounter++;
                    delete $Gamer_Points{'$_'};
                }
            }
        }
    }

    return @Result;
}

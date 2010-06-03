#!/bin/bash
#
# Erwartet als ersten Parameter den Namen der Datei mit den Tipps eines Spielers.
# Diese wird bereinigt und geparst. Eine TipFile wird auf stdout geschrieben.

cat $1 |
	# Lösche unnützes Zeug, z. B. Kommentare und Leerzeilen
	sed '/^$/d' |
	sed '/^#/d' |
	
	# Parse die Tipps des Benutzers
	awk -f generateUserTipFile.awk

#!/bin/bash
# Lösche unnützes Zeug, z. B. Kommentare und Leerzeilen

cat $1 |
	sed '/^$/d' |
	sed '/^#/d' |
	
	awk -f helper/generateUserTipFile.awk

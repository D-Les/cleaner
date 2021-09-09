#!/bin/bash

DATA=""

#======================================================================
#------------------------Flagi skryptu---------------------------------
#======================================================================
while getopts ":d:h" opt
do

	case "${opt}" in
	
	h)
		echo ""
		echo "Przy wykorzystaniu parametru -d mozna zdefiniowac date od ktorej pliki maja byc modyfikowane"
		echo "Format wprowadzanej daty to rrrr-mm-dd"
		echo "Domyslna data: 2021-09-02"
		echo ""
		exit 1
		;;
	d)
		DATA="${OPTARG}"
		;;
	*)
		break
		;;
esac
done

if [ "$DATA" = "" ] ; then
	DATA="2021-05-02"
fi
echo "Ustawiona data -> $DATA"
#======================================================================
#------------------------Info startowe---------------------------------
#======================================================================
echo "Uruchomiles program majacy za zadanie wyczyscic pozostalosci po uzytkowniku"
echo "Zweryfikuj w kodzie porgramu czy zostaly zmodyfikowane wszystkie wartosci na poprawne"
echo "Zalecane wykonanie programu w trybie Super Usera"
echo ""
echo ""
echo "Nacisnij enter aby kontynuowac"

while [ true ] ; do
	read -t 3 -n 1
	if [ $? = 0 ] ; then
		break ;
	fi
done


#======================================================================
#------------------------Funkcje---------------------------------------
#======================================================================
random_date() {
	len=$(wc -l "$1"| awk '{ print $1 }')
	los=$(( $RANDOM % $len +1))
	#FIL= $(head -n "$los" "$1" | tail -n +"$los") - sciezka pliku
	if [ -f $(head -n "$los" "$1" | tail -n +"$los") ] ; then
		touch -r $(head -n "$los" "$1" | tail -n +"$los") $2 2>/dev/null
	fi
}


#======================================================================
#------------------------Czyszczenie historii--------------------------
#======================================================================
#--------------czyszczenie plikow dla wszystkich uzytkownikow----------

cat /etc/passwd | grep -P '^.*:.*:[0-9]+:[0-9]+:.*:.+:' | cut -d ':' -f 6 | uniq > passwd.txt

# w programie nadal wykorzystwane jest nadpisywanie >
# nie bylem pewien czy pliki te beda dzialaly poprawnie gdy zostana nadpisane za pomoca shred
while read pass; do
#----------------------------bash-------------------------------------
	if [ -f "$pass/.bash_history" ] ; then
		> "$pass/.bash_history"
	fi
#-------------------------nano-------------------------------------
	if [ -f "$pass/.nano_history" ] ; then
		> "$pass/.nano_history"
	fi
#------------------------vim--------------------------
	if [ -f "$pass/.viminfo" ] ; then
		> "$pass/.viminfo"
	fi
#------------------------my_sql------------------------------------
	if [ -f "$pass/.mysql_history" ] ; then
		> "$pass/.mysql_history"
	fi
#------------------------mc/mcedit--------------------------
	if [ -f "$pass/.local/share/mc/history" ] ; then
		> "$pass/.local/share/mc/history"
	fi
#------------------------mc/mcedit--------------------------
	if [ -f "$pass/.ssh/known_hosts" ] ; then
		shred -u "$pass/.ssh/known_hosts"
	fi

done < passwd.txt

#--------------------------swp files--------------------------
echo -en "\tCzyszczenie plikow .swp....."
find / -iname '*.sw[klmnop]' 2>&1 >swps.txt | grep -v "Permission denied" >&2
while read swps; do
	if echo "$swpd"; then
		shred -u "$swpd" 
	fi
done < swps.txt
echo "OK"

#mozliwe edytory
echo -en "\tCzyszczenie pozostalych plikow _history...."
if history -c ; then
	history -c
fi
find / -type f -iname '*_history*' 2>&1 > hist.txt| grep -v 'Permission denied' >&2
while read his; do
	> "$his"
done < hist.txt
echo "OK"




#======================================================================
#------------------------Czyszczenie backup----------------------------
#======================================================================

#------------------------Znajdz pliki bat------------------------------
echo -en "\tSzukanie plikow bat.........."
find / -iname '*.bat' -type f 2>&1 >bat.txt | grep -v "Permission denied" >&2
echo "OK"

#------------------------Znajdz pliki bak------------------------------
echo -en "\tSzukanie plikow bak.........."
find / -iname '*.bak' -type f 2>&1 >bak.txt | grep -v "Permission denied" >&2
echo "OK"
#------------------------Usun pliki bak------------------------------
echo -en "\tUsuwanie plikow bak.........."
while read bk; do
	shred -u "$bk"
done < bak.txt
echo "OK"
#------------------------Znajdz pliki tmp------------------------------
echo -en "\tSzukanie plikow tmp.........."
find / -iname '*.tmp' -type f 2>&1 >tmp.txt | grep -v "Permission denied" >&2
echo "OK"





#======================================================================
#------------------------Czyszczenie logow-----------------------------
#======================================================================

#----------------------Wyszukanie wszystkich logow----------------------
echo -en "\tSzukanie logow.........."
find /var/log | grep -iP '\.log?$' 2>&1 > logs.txt | grep -v 'Permission denied' >&2
find /var/log | grep -iP '\.log\.\d\.gz?$' 2>&1 > logs_gz.txt | grep -v 'Permission denied' >&2
echo "OK"

#--------------------Wyczysz pliki .log i usun pliki log.d.gz-----------
echo -en '\tCzyszczenie logow...........'
while read logi; do
	if [ > "$logi" ] ; then
		 > "$logi"
	fi
done < logs.txt
while read logz; do
	if [ -f "$logz" ] ; then
		shred -u "$logz"
	fi
done < logs_gz.txt
echo 'OK'




#======================================================================
#-----------------Czyszczenie instalowanych pakietow-------------------
#======================================================================
echo -en "\tCzyszczenie /var/cache/apt/archives.........."
find /var/cache/apt/archives -iname '*.deb' -type f 2>&1 | grep -v 'Permission denied' > archive.txt
while read arch; do
	shred -u "$arch"
done < archive.txt
shred -u /var/cache/apt/archives/partial/*
echo "OK"

#======================================================================
#------------Czyszczenie pozostalych plikow deb------------------------
#======================================================================

find / -iname '*.deb' -type f 2>&1 | grep -v 'Permission denied' > rest_of_deb.txt

#======================================================================
#--------------------Czyszczenie aktualizacji--------------------------
#======================================================================

apt-get clean > /dev/null 2>&1
apt-get autoclean > /dev/null 2>&1
apt-get autoremove > /dev/null 2>&1

#======================================================================
#------------------------Czyszczenie dat-------------------------------
#======================================================================

echo -en "\tSzukanie dat do modyfikacji................"
find / -type f ! -newermt "$DATA" 2>&1 | grep -v "Permission denied" > dates.txt
find / -type f -newermt "$DATA" 2>&1 | grep -v "Permission denied" > to_change.txt 
echo "OK"


#-------------------------Modyfikacja dat - zlote dowiazanie-----------------------------

echo -en "\tZmiana dat utworzenia/modyfikacji...................."
while read fil; do
	random_date ./dates.txt "$fil"
done < to_change.txt
echo 'OK'



#======================================================================
#------------------------Koniec programu - czyszczenie-----------------
#======================================================================



shred -u ./dates.txt
shred -u ./to_change.txt
shred -u ./archive.txt
shred -u ./swps.txt
shred -u ./logs.txt
shred -u ./logs_gz.txt
shred -u ./hist.txt
#shred -u ./bat.txt
shred -u ./bak.txt
shred -u ./passwd.txt

echo ""
echo ""
echo "UWAGA! Pliki:"
echo "- tmp.txt"
echo "- bat.txt"
echo "- rest_of_deb.txt"
echo "nalezy przejrzec i manulanie sprawdzic czy znalezione pliki powinny zostac usuniete!"
echo "Po weryfikacji plikow nalezy je usunac komenda 	\" shred -u nazwa_pliku \" "
echo ""
echo "Koniec dzialania programu"




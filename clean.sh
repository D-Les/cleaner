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
	DATA="2021-09-02"
fi

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
	touch -r $(head -n "$los" "$1" | tail -n +"$los") $2

}


#======================================================================
#------------------------Czyszczenie historii--------------------------
#======================================================================

#----------------------------bash-------------------------------------
echo -en "\tCzyszczenie bash_history......"
> ~/.bash_history
echo "OK"

#--------------------------swp files--------------------------
echo -en "\tCzyszczenie plikow .swp....."
find / -iname '*.sw[klmnop]' 2>&1 >swps.txt | grep -v "Permission denied" >&2
while read swps; do
	if echo "$swpd"; then
		rm "$swpd" 
	fi
done < swps.txt
echo "OK"

#-------------------------nano-------------------------------------
echo -en "\tCzyszczebue nano_history......."
if [ -f ~/.nano_history ]; then
	> ~/.nano_history
fi
echo "OK"

#------------------------my_sql------------------------------------
echo -en "\tCzyszczenie mysql_history........"
if [ -f ~/.mysql_history ]; then
	> ~/.mysql_history
fi
echo "OK"

#------------------------vim--------------------------
echo -en '\tCzyszcznie viminfo......'
if [ -f ~/viminfo ]; then
	> ~/.viminfo
fi
echo 'OK'

#------------------------mc/mcedit--------------------------
echo -en "\tCzyszczenie mc......"
if [ -f ~/.local/share/mc/history ]; then
	> ~/.local/share/mc/history
fi
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
	rm "$bk"
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
	if [ rm "$logz" ] ; then
		rm "$logz"
	fi
done < logs_gz.txt
echo 'OK'






#======================================================================
#-----------------Czyszczenie instalowanych pakietow-------------------
#======================================================================
echo -en "\tWykonanie apt-get clean/autoclean................."
apt-get clean
apt-get autoclean
echo "OK"

echo -en "\tRęczne czyszczenie /var/cache/apt/archives.........."
find /var/cache/apt/archives -iname '*.deb' -type f 2>&1 | grep -v 'Permission denied' > archive.txt
while read arch; do
	rm "$arch"
done < archive.txt
rm /var/cache/apt/archives/partial/*
echo "OK"


#======================================================================
#-----------------Czyszczenie /var/cache-------------------
#======================================================================
echo -en "\tWykonanie apt-get clean/autoclean................."
apt-get autoremove
echo "OK"



#======================================================================
#------------------------Czyszczenie dat-------------------------------
#======================================================================

echo -en "\tSzukanie dat do modyfikacji................"
find / -type f ! -newermt "$DATA" 2>&1 | grep -v "Permission denied" > dates.txt
find . -type f -newermt "$DATA" 2>&1 | grep -v "Permission denied" > to_change.txt 
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

: '

if [ -s ./tmp.txt ] ; then
	echo 'Zweryfikuj zawartosc tmp'
else 
	rm ./tmp.txt
fi
rm ./dates.txt
rm ./to_change.txt
rm ./archive.txt
rm ./swps.txt
rm ./logs.txt
rm ./logs_gz.txt
rm ./hist.txt
rm ./bat.txt
rm ./bak.txt
'
echo ""
echo "Koniec dzialania programu"


#Po za wersja testowa nalezy:
#Usunac komentarz czyszczacy utworzone pliki - na ten moment zostaja zapisane w celu potwierdzenia dzialania programu
#Zmiana daty ostatniej modyfikacji ? w poleceniu stat -> wiersz Change

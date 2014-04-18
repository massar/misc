#!/bin/bash

################################################
## rsync-hardlink-based incremental backup
## ignoring most system/cache/etc files, LXC-aware
##
## Jeroen Massar <jeroen@massar.ch>
################################################

# Backup directory to clean (Trailing slash required)
BACKUPDIR=/backup/

NY=`date +%Y`
NM=`date +%m | sed 's/^0//g'`
ND=`date +%d | sed 's/^0//g'`

function verb()
{
	#echo $1
	I=$((I+1))
}

for d in ${BACKUPDIR}*
do
	verb "DIR $d"
	cd $d

	CUR=$(readlink current)

	for b in *
	do
		# Never remove the 'current' and thus last dir
		if [ "$b" = "${CUR}" ];
		then
			verb "$d $b - current backup directory"
			continue
		fi

		# Do not remove the symlink either
		if [ "$b" = "current" ];
		then
			verb "$d $b - current backup directory (link)"
			continue
		fi

		# Split up the date
		T=`echo $b | cut -f1 -d-`
		Y=`echo $b | cut -f2 -d-`
		M=`echo $b | cut -f3 -d-`
		D=`echo $b | cut -f4 -d- | cut -f1 -d_`
		H=`echo $b | cut -f4 -d- | cut -f2 -d_`
		MM=`echo $b | cut -f4 -d- | cut -f3 -d_`

		# If it is not 'backup' or 'incomplete', don't process
		if [ "$T" != "backup" -a "$T" != "incomplete" ];
		then
			verb "$d $b - is not a standard backup directory"
			continue
		fi

		# Check that the date stamp is kinda sane
		if [ "$Y" = "$b" -o -z "$Y" -o -z "$M" -o -z "$D" -o -z "$H" -o -z "$MM" -o "$D" == "${D}_${H}_${MM}" ];
		then
			verb "$d $b - date broken ($Y $M $D $H:${MM})"
			continue
		fi

		#verb "$d $b - OK"

		# Strip leading zeros (otherwise compares go wrong)
		M=`echo $M | sed 's/^0//g'`
		D=`echo $D | sed 's/^0//g'`

		if [ $Y -lt $NY ];
		then
			# Keep Quarterly data + December
			if [ $M -eq 1 -o $M -eq 4 -o $M -eq 7 -o $M -eq 10 -o $M -eq 12 ];
			then
				if [ $D -eq 1 ];
				then
					verb "$d $b - Quarterly"
					continue
				fi
			fi

			verb "$d $b - $(($NY - $Y)) Year Old"
			continue
		fi

		verb "$d $b - NM = ${NM}, M = ${M}"
		if [ $(($NM - $M)) -lt 1 -a $(($ND - $D)) -lt 7 ];
		then
			verb "$d $b - Keeping last 7 days"
			continue
		fi

		# Keep backups of the first and 15th of each month
		if [ $D -eq 1 -o $D -eq 15 ];
		then
			verb "$d $b - Keeping first/half backups"
			continue
		fi

		if [ $(($NM - $M)) -eq 1 -a $H -eq 0 ];
		then
			verb "$d $b - Keeping 1 month old per-day data"
			continue
		fi

		verb "$d $b - Cleaning $(($NM - $M)) Month Old"
		nice -n 20 rm -rf $b

		# If they are only a few days old we want to keep them
	done
done

verb "all done"

exit 0


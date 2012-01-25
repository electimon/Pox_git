#!/bin/sh
#a universal script to make an XO-1 and XO-1.5 compatible Puppy 
#from any woof (almost any) based Puppy Iso
#Please expand this outside of a pupsave if using Puppy.
#gpl3 (see /usr/share/doc) (c) mavrothal, 01micko
#NO WARRANTY

#bit of fun!
clear
echo "Welcome to Create XO Puppy"
xoolpcfunc()
{
echo ""
echo -en "\033[1;33m""\t1""\033[0m" "|" "\033[1;32m" "L""\033[0m" \
"|""\033[1;36m"" ->""\033[0m" "|""\033[1;35m" "X"; echo -e "\033[0m"
echo ""
}
export -f xoolpcfunc
xoolpcfunc

#version
VER=1.0

#workdir
PWD="`pwd`"
CWD="$PWD"

#read config
. $CWD/pkgs_remrc

#ok, we exit on most errors, error function
statusfunc()
{
	if [ "$1" = "0" ];then echo -en "\033[0;32m" OK; echo -e "\033[0m" #green
		else echo -en "\033[0;31m" FAIL; echo -e "\033[0m" && exit #red
	fi	
}
export -f statusfunc

#clear old build
if [ -d build ];then
	echo -e "\\0033[1;31m"
	echo "A previuos build has been detected" 
	echo "You can quit the $0 prog now and save it or delete it"
	echo "and continue."
	echo "Hit \"d\" > \"enter\" to delete and continue or"
	echo "\"enter\" only to quit"
	echo -en "\\0033[0;39m"
	read DELETE
	if [ "$DELETE" = "d" ];then rm -rf build
		echo "Deleted previous build... continuing"
		else 
		echo "Exiting $0 so you can save your previous build"
		xoolpcfunc
		exit 0
	fi
fi

#usage
usagefunc()
{
	cat <<_USAGE
	Usage:
		This program modifies a standard Puppy iso or main sfs/initrd
		to be bootable on the XO olpc hardware, versions XO-1 and XO-1.5
	
		-h|--help	display this usage
		-v|--version	display script version
		-xh|--extended-help 	opens README.txt
		-i|--iso [path/to/isoname]	the full pathname of the Puppy iso
		-m|--manual [name of sfs]	the name of the Puppy main sfs file
		NOTE: with the -m option it is your responsibility
		to select the correct initrd.gz that matches the main
		.sfs and place both in the current directory
	
		(c) Created by mavrothal and 01micko
		@murga-linux puppy forum
		GPLv3. See /usr/share/doc/legal/
		NO WARRANTY
		While all care is taken NO responsibility is accepted
_USAGE
	
	xoolpcfunc
	exit 0
}
export -f usagefunc

case "$#" in
	0) usagefunc ;;
	[3-9])echo "too many arguments"; usagefunc ;;
esac

case $1 in 
	-h|--help) usagefunc && exit 0 ;;
	-v|--version) echo "$VER" && exit 0 ;;
	-xh|--extended-help)cat README.txt|more 
		xoolpcfunc && exit 0 ;;
	-i|--iso) [ ! $2 ] && usagefunc
		ISOPATH=$2 
		ISO="`basename $ISOPATH`" ;;
	-m|--manual) [ ! $2 ] && usagefunc
		ls $CWD|grep "^initrd" >/dev/null 2>&1
		echo -n initrd; statusfunc $?
		ININIT="`ls $CWD|grep "^initrd"`"
		INSFS="`ls $CWD|grep "sfs$"|head -n1`"
		echo "you chose $2"
		sleep 0.5
		echo "the sfs is $INSFS"
		sleep 0.5
		ls $CWD|grep "sfs$" >/dev/null 2>&1 
		echo -n $2; statusfunc $?
		[ "$2" != "$INSFS" ] && echo "ERROR: Not correct sfs.. typo?" && statusfunc 1
		;;
esac

#==============================================================================
#test we are compatible Puppy #changed to any distro by mavrothal 110824
#put in a check for mksquashfs, ..Ubuntu doesn't ship with it. 110825 01micko
if [ -f /etc/DISTRO_SPECS ];then 
	. /etc/DISTRO_SPECS
else 
	MSQY="`which mksquashfs`"
	if [ "$MSQY" = "" ];then
		echo "Sorry, you cant run this $0 without \"$MSQY\""
		echo "Please install \"mksquashfs\" from your package manager"
		echo "and try again"
		statusfunc 1
	else
		echo "You are not running Puppy Linix"
		echo "This should be ok as it seems you have"
		echo "\"$MSQY\""
		echo "Hit enter to keep going"
		read getgoing
		statusfunc 0
	fi
fi

#test kernel for squash 4 support
KERNEL="`uname -r`"
KERNELMAJ="`echo $KERNEL|head -c1`"
KERNELMIN="`echo $KERNEL|cut -d '.' -f3`"
if [[ "$KERNELMAJ" -eq "2" && "$KERNELMIN" -ge "29" ]] || [[ "$KERNELMAJ" -eq "3" ]] ; then
	echo "kernel Ok"
	else echo "kernel too old, exiting" && exit 0
fi

#test for free space
BASEDISK="`echo $CWD|cut -d '/' -f 1,2,3`" #returns eg "/mnt/sda1"
BASEPART="`echo $CWD|cut -d '/' -f 3`" #returns eg "sda1" if not in pupsave
DF="`df -m|grep $BASEPART|awk '{print $4}'`"
#puppy specific
if [ -f /etc/DISTRO_SPECS ];then #puppy test only added 110825 01micko
	. /etc/rc.d/PUPSTATE
	if [[ "$PUPMODE" = "7" || "$PUPMODE" = "13" ]];then
	 echo "You have a USB install to slow media and this program"
	 echo "will fail if you try to run it on the usb media"
	 echo "make absolutely sure you run this in a linux filesystem on a HDD"
	 echo "or if you have over a gigabyte of RAM, make a ramdisk .."
	 echo "...for advanced users only!"
	 echo "Hit enter to continue"
	 read goon
	fi
#cheat!
	if [ "`echo $BASEDISK|grep "root"`" != "" ];then 
	 DF="`cat /tmp/pup_event_sizefreem`"
	fi
fi
if test "$DF" -lt "500" ;then EXIT=1
	echo "space check... disk space free is $DF"
	echo "...not enough space, do this on another partiton"
		else EXIT=0
	echo "space check... disk space free is $DF"
fi
statusfunc $EXIT

#set vars
XODIR="$CWD"
[ ! -d $XODIR/squashdir/squashfs-root ] && mkdir -p $XODIR/squashdir/squashfs-root
SQDIR="$XODIR/squashdir"
SFSROOT="$SQDIR/squashfs-root"
INITDIR="$XODIR"
XOSFS="$XODIR/XO_sfs"
MNTDIR=""

#==============================================================================

#Get stuff off iso
if [ "$ISOPATH" != "" ];then 
	[ ! -d  $CWD/mntiso ] && mkdir $CWD/mntiso
	MNTDIR="$CWD/mntiso"
	echo "mounting $ISO"
	mount $ISOPATH $MNTDIR -o loop
	statusfunc $?
	#exit #testing
	cd $MNTDIR
	echo "looking for sfs files in iso"
	ls|grep "sfs$" >/dev/null 2>&1
	statusfunc $?
	
	SFSTHERE=`ls|grep "sfs$"`
	MAINSFS="`ls $SFSTHERE|grep "sfs$" | grep -v "^z"|grep -v "^a"`"
	ZSFS=`echo $SFSTHERE|grep "zdrv"`
	if [ "$ZSFS" != "" ];then
		echo -e "\\0033[1;34m"
		echo  "a zdrv is present, you can manually search it"
		echo  "for stuff needed or delete it. Hit \"d\" to delete"
		echo  "and enter or just \"enter\" to continue"
		echo -en "\\0033[0;39m"
		read ZDEL
		[ "$ZDEL" != "d" ] && cp zdrv*.sfs $SQDIR #why do we keep it?
	fi
	ASFS=`echo $SFSTHERE|grep "adrv"`
	if [ "$ASFS" != "" ];then
		echo -e "\\0033[1;34m"
		echo  "a adrv is present, you can manually search it"
		echo  "for stuff needed or delete it. Hit \"d\" to delete"
		echo  "and enter or just \"enter\" to continue"
		echo -en "\\0033[0;39m"
		read ADEL
		[ "$ADEL" != "d" ] && cp adrv*.sfs $SQDIR
	fi
	cp $MAINSFS $SQDIR
	cp initrd* $INITDIR
	cd ..
	sync
	umount $MNTDIR
	rm -rf $MNTDIR
	sync
fi

#==============================================================================
#mod main sfs
NUMBER="`ls $SQDIR/*.sfs|wc -l`"
if [ "$NUMBER" -gt "3" ];then echo "Something is wrong! $NUMBER sfs files"
	echo "Should not be more than 3 ... aborting..." && statusfunc 1
fi

cd $SQDIR
for SFS in *.sfs
do echo "unsquashing $SFS"
	unsquashfs -d $SFS.root $SFS	
 	statusfunc $?||break #should unpack everything to squashfs-root, exit on fail
 	sync
 	statusfunc 0 && echo "decompressed $SFS successful"
	rm -f $SFS
	sync
done

# Combine the SFSs in squashfs-root
echo "Merging the SFSs. May take some time..."
ls | grep ".sfs.root" | tac > /tmp/DIRS
MERGE="`cat /tmp/DIRS`"
for LINE in $MERGE 
do 
	cp -aR --remove-destination $LINE/* $SFSROOT/
	sync
	echo "$LINE was merged"
	rm -rf $LINE
	sync
done
rm /tmp/DIRS

# Include extra pets in the build 
# Do it early in case pets have unneeded components
extra_pets=$XODIR/extra_pets
if [ ! -f $extra_pets/*.pet ] ; then
	echo -e "\\0033[1;34m"
	echo "If you want any additional pets in the build"
	echo "add them NOW in the \"extra_pets\" folder and then"
	echo "hit \"a\"  and then  \"enter\" to continue"
	echo "or just \"enter\" to skip this step."
	echo -en "\\0033[0;39m"
	read CONTINUE
		if [ "$CONTINUE" = "a" ];then
			echo "including extra pets in the build"
			echo "The following pets were included in the build" >> $CWD/build.log
			cd $extra_pets
			for p in ./* 
				do 
				PNAME=`echo $p | sed 's/\.pet//'`
				tar xzf $p 2>/dev/null 
				cd $PNAME
				rm -f *.sh *.spec* 2>/dev/null
				find . > /tmp/$PNAME.files
				PREVPATH=''
				cat /tmp/$PNAME.files |
				while read ONELINE
				do
				if [ -d "${ONELINE}" ] ; then
					PREVPATH="$ONELINE"
					echo "$ONELINE" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
				else
					NEWPATH="`dirname "$ONELINE"`"
					[ "$NEWPATH" == "/" ] && continue #ignore top-level files.
					NEWFILE="`basename "$ONELINE"`"
					if [ -e "${ONELINE}" ] ; then #sanity check.
						if [ "$PREVPATH" == "$NEWPATH" ] ; then #sanity check.
							echo " ${NEWFILE}" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
						fi
					fi
				fi
				done					
				cp -aR * $SFSROOT
				if [ $? -ne 0 ]; then
					echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				else
					echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				fi
				cd $extra_pets 
				rm -rf $PNAME
				rm -f /tmp/"$PNAME".files
				sed -i 's/^\.//' $SFSROOT/root/.packages/builtin_files/$PNAME
			done
		fi
else
	echo "including extra pets in the build"
	echo "The following pets were included in the build" >> $CWD/build.log
	cd $extra_pets
	for p in ./* 
		do 
		PNAME=`echo $p | sed 's/\.pet//'`
		tar xzf $p 2>/dev/null 
		cd $PNAME
		rm -f *.sh *.spec* 2>/dev/null
		find . > /tmp/$PNAME.files
		PREVPATH=''
		cat /tmp/$PNAME.files |
		while read ONELINE
		do
		if [ -d "${ONELINE}" ] ; then
			PREVPATH="$ONELINE"
			echo "$ONELINE" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
		else
			NEWPATH="`dirname "$ONELINE"`"
			[ "$NEWPATH" == "/" ] && continue #ignore top-level files.
			NEWFILE="`basename "$ONELINE"`"
			if [ -e "${ONELINE}" ] ; then #sanity check.
				if [ "$PREVPATH" == "$NEWPATH" ] ; then #sanity check.
					echo " ${NEWFILE}" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
				fi
			fi
		fi
		done					
		cp -aR * $SFSROOT
		if [ $? -ne 0 ]; then
			echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
		cd $extra_pets 
		rm -rf $PNAME
		rm -f /tmp/"$PNAME".files
		sed -i 's/^\.//' $SFSROOT/root/.packages/builtin_files/$PNAME
	done
fi

cd $SQDIR
#delete old kernel
rm -rf $SFSROOT/lib/modules/* 
echo "deleting old kernel"
#delete not needed firmware
rm -rf $SFSROOT/lib/firmware/* 
echo "deleting not needed firmware"

. $SFSROOT/etc/DISTRO_SPECS
echo "removing unneeded xorg drivers"

#sort video drivers
#We can compile more drivers for separate distro and store in
#drake, wary, squezze, lupu whatever dir
case "$DISTRO_FILE_PREFIX" in
wary|racy|luki)   XORGDIR="$SFSROOT/usr/X11R7/lib/xorg/modules/drivers" 
		XORGLIBDIR="$SFSROOT/usr/X11R7/lib/"	
		cp -af $XODIR/{wary,racy,luki}/xorg/modules/drivers/* \
		$SFSROOT/usr/X11R7/lib/xorg/modules/drivers/
		;; 
slacko|spup) XORGDIR="$SFSROOT/usr/lib/xorg/modules/drivers"
		XORGLIBDIR="$SFSROOT/usr/lib/"
		cp -af $XODIR/{slacko,spup}/xorg/modules/drivers/* \
		$SFSROOT/usr/lib/xorg/modules/drivers/ 
		;;
lupu|luci) XORGDIR="$SFSROOT/usr/lib/xorg/modules/drivers"
		XORGLIBDIR="$SFSROOT/usr/lib/"
		cp -af $XODIR/{lupu,luci}/xorg/modules/drivers/* \
		$SFSROOT/usr/lib/xorg/modules/drivers/ 
		;;	
drake) XORGDIR="$SFSROOT/usr/lib/xorg/modules/drivers"
		XORGLIBDIR="$SFSROOT/usr/lib/"
		echo "At time of writing, drake has issues on XO hardware"
		cp -af $XODIR/drake/xorg/modules/drivers/* \
		$SFSROOT/usr/lib/xorg/modules/drivers/ 
		;;
squeeze|dpup|squeezed|next|guydog) 
		XORGDIR="$SFSROOT/usr/lib/xorg/modules/drivers"
		XORGLIBDIR="$SFSROOT/usr/lib/"
		cp -af $XODIR/{squeeze,dpup,squeezed,next,guydog}/xorg/modules/drivers/* \
		$SFSROOT/usr/lib/xorg/modules/drivers/ 
		;;		
*)		XORGDIR="$SFSROOT/usr/lib/xorg/modules/drivers" 
		XORGLIBDIR="$SFSROOT/usr/lib/"
		;; #maybe this kinda works?
esac

XMODULES="`ls $XORGDIR \
	|grep -iE -v "chrome|geode|openchrome|sisusb|ztv_drv|v4l"`"

#remove unneeded xorg drivers #are they right?
for drv in $XMODULES
do 
	rm -f $XORGDIR/$drv
 	echo "removing $drv"
done
#some puppies have additonal drivers elsewhere
rm -rf $SFSROOT/usr/lib/xorg/modules/drivers-*
rm -rf $SFSROOT/usr/lib/x/*

echo "removing other useless stuff for XO..."
# remove extra video stuff
echo "extra video libs..."
for v in $XTRA 
do 
	echo "removing $v"
 	rm -f $XORGLIBDIR/$v
done
#remove puppy scripts
echo "unneeded puppy scripts..." 
cd $SFSROOT 
for s in $WOOFSCRIPTS
do  
	echo "removing $s"
 	rm -f usr/sbin/$s
done
 
for i in $OTHER
do  
	echo "removing $i"
 	rm root/Startup/$i
done

#..and DOT desktops
echo "unneeded .desktop files..." 
for desk in $WOOFDESK
do 
	echo "removing $desk"
 	rm -f usr/share/applications/$desk
done 

# Patch xorgwizard
echo "patching xorgwizrd"
patches="$CWD/XO_sfs_patches"
patch -p1 < $patches/xorgwizard.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch xorgwizard. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	cp -a usr/sbin/xorgwizard.orig usr/sbin/xorgwizard
	rm -f usr/sbin/xorgwizard.{orig,rej}
	# some puppies have xorg-setup instead
	patch -p1 usr/sbin/xorg-setup < $patches/xorgwizard.patch
	if [ $? -ne 0 ]; then
		echo "Failed to patch xorg-setup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Patched xorg-setup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
else
	echo "Patched xorgwizard. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

patch -p1 < $patches/xorg.conf0.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch xorg.conf0. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
else
	echo "Patched xorg.conf0. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

# Patch PPM
echo "patching 0setup"
patch -p1 < $patches/0setup.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch 0setup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
else
	echo "Patched 0setup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

# Patch snapmerge
echo "patching snapmergepuppy"
patch -p1 < $patches/snapmerge.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch snapmergepuppy. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
else
	echo "Patched snapmergepuppy. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

# Patch frontend_d
echo "patching pup_event_frontend_d"
patch -p1 < $patches/frontend_d.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch pup_event_frontend_d. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
else
	echo "Patched pup_event_frontend_d. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

# Patch rc.shutdown
echo "patching rc.shutdown"
patch -p1 < $patches/rc.shutdown.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch rc.shutdown. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
else
	echo "Patched rc.shutdown. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

#Add support for the XO internal drives in fstab
echo "Adjusting /etc/fstab for XO internal drives..."
cat << EOF >> $SFSROOT/etc/fstab
/dev/mtdblock0		/.xo-nand	jffs2	defaults,noauto	  0 0
/dev/mmcblk1p2		/.intSD	    ext4	defaults,noauto	  0 0
EOF

# Fix menu font size, in Seamonkey/Firefox
sed -i 's/font-size: 12px !important;/font-size: 16px !important;/' \
 $SFSROOT/root/.mozilla/{seamonkey,firefox}/*.default/chrome/userChrome.css
 
# Fix JWM window tittle hight
sed -i 's/Height>[0-9][0-9]/Height>30/' $SFSROOT/root/.jwm/jwmrc-theme 
sed -i 's/Height>[0-9][0-9]/Height>30/' $SFSROOT/root/.jwmrc
sed -i 's/Height>[0-9][0-9]/Height>30/' $SFSROOT/etc/xdg/templates/_root_.jwmrc
sed -i 's/WINDOWHEIGHT="[0-9][0-9]"/WINDOWHEIGHT="30"/' $SFSROOT/etc/JWMRC
sed -i 's/WINDOWHEIGHT="[0-9][0-9]"/WINDOWHEIGHT="30"/' $SFSROOT/root/.jwm/JWMRC
for i in $SFSROOT/root/.jwm/themes/*-jwmrc 
	do 
		sed -i 's/Height>[0-9][0-9]/Height>30/' $i  
	done

# Fix font size for XFCE4 (Saluki 006+)
sed -i 's/<property name="DPI" type="empty"\/>/<property name="DPI" type="int" value="140"\/>/' $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
sed -i 's/<\/channel>//' $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cat << EOF >> $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
  <property name="Xfce" type="empty">
    <property name="LastCustomDPI" type="int" value="140"/>
  </property>
</channel>
EOF

statusfunc 0

echo "The following buildin packages have been removed from the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
for i in $PACKAGES_REM
	do 
	D="$SFSROOT/root/.packages/builtin_files"
	PKG=$i
	FILES="`cat $D/$PKG`"
	if [ -f $D/$PKG ] ; then
		echo "removing \"$i\""
		for LINE in $FILES
			do
			if [ "`echo $LINE|head -c1`" = "/" ];then
				x=`echo $LINE|sed 's%^\/%%'`
				cd $SFSROOT/$x
			else
				x="$LINE"
				rm $x
			fi
			done
			#fix root/.packages/woof-installed-packages
		grep -v "$PKG" $SFSROOT/root/.packages/woof-installed-packages| \
			while read LINE
				do 
				echo $LINE >> $SFSROOT/root/.packages/woof-installed-packages.tmp
				done
		mv -f $SFSROOT/root/.packages/woof-installed-packages.tmp \
			$SFSROOT/root/.packages/woof-installed-packages		 
		rm $D/$PKG 
		if [ $? -ne 0 ]; then
			echo "Failed to remove $PKG from the build." >> $CWD/build.log
		else
			echo "$PKG was removed." >> $CWD/build.log
		fi
		statusfunc $?
	fi
	done

cd $SQDIR

echo -e "\\0033[1;34m"
echo "Do you want to move some, not frequently used on the XO,"
echo "applications to an \"extras.sfs\" ? "
echo "Hit \"m\"  and then  \"enter\" to move them"
echo "or just \"enter\" to skip this step."
echo -en "\\0033[0;39m"
read CONTINUE
if [ "$CONTINUE" = "m" ];then
	echo "The following buildin packages have been moved into the extras.sfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	mkdir -p $SQDIR/extras
	for i in $PACKAGES_MOVE
		do 
		D="$SFSROOT/root/.packages/builtin_files"
		PKG=$i
		FILES="`cat $D/$PKG`"
		if [ -f $D/$PKG ] ; then
			echo "moving \"$i\""
			for LINE in $FILES
				do
				if [ "`echo $LINE|head -c1`" = "/" ];then
					mkdir -p $SQDIR/extras"$LINE"
					MOVEPATH=$SQDIR/extras"$LINE"/
					x=`echo $LINE|sed 's%^\/%%'`
					cd $$SFSROOT/$x
				else
					x="$LINE"
					mv $x $MOVEPATH
				fi
				done
			#fix root/.packages/woof-installed-packages
			grep -v "$PKG" $SFSROOT/root/.packages/woof-installed-packages| \
				while read LINE
					do 
					echo $LINE >> $SFSROOT/root/.packages/woof-installed-packages.tmp
					done
			mv -f $SFSROOT/root/.packages/woof-installed-packages.tmp \
				$SFSROOT/root/.packages/woof-installed-packages		 
			rm $D/$PKG
			if [ $? -ne 0 ]; then
				echo "Failed to move $PKG into extras.sfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "$PKG was moved " >> $CWD/build.log
			fi
			statusfunc $?
		fi
	done

	cd $SQDIR
	
	if [ ! -f $SFSROOT/usr/bin/geany ] ; then
		if [ -f $SFSROOT/usr/bin/leafpad ] ; then
			sed -i 's/geany/leafpad/' $SFSROOT/usr/local/bin/defaulttexteditor
		else
			sed -i 's/geany/nicoedit/' $SFSROOT/usr/local/bin/defaulttexteditor
		fi
	fi
else
	echo "Nothing moved out of the main sfs"
	echo "Nothing was moved into the extras.sfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi


cd $SFSROOT

# Fix permissions for fido
chmod -R 777 tmp

echo "copying in the XO files"
cp -rf $XOSFS/* ./

statusfunc $?

cd $SQDIR
sync
echo "now compressing the NEW $MAINSFS..."
mksquashfs squashfs-root/ "$MAINSFS"
statusfunc $?
echo "removing expanded filesystem"
rm -rf $SFSROOT 
sync
statusfunc $?

if [ -d $SQDIR/extras ] ; then
	cd $SQDIR
	echo "now compressing the \"extras.sfs\"..."
	mksquashfs extras extras.sfs
	statusfunc $?
	rm -rf extras
	sync
	statusfunc $?
fi

#==============================================================================

#mod the initrd
cd $INITDIR
for DIR in XO*

#get xo hw version
 do VER="`echo $DIR|sed -e 's%^XO%%' -e 's%kernel$%%'`"
	case $VER in
	1)VERDIR=10
		XO=XO1 ;;
	1.5)VERDIR=15
		XO=XO1.5 ;;
	*)echo "not supported" && break && exit 0 ;;
	esac

[ -f boot${VERDIR}/initrd.* ] && rm -f boot${VERDIR}/initrd.*
echo "Making the ${XO} initrd.gz"
mkdir $CWD/initramfs
cd initramfs
# unpack initrd
gunzip -c ../initrd.gz | cpio -i 
statusfunc $?
sync
# Replace kernel modules with OLPC_Puppy ones
rm -rf lib/modules/*
cp -arf ../$DIR/lib/* lib/ 
# modprobe vfat if we are booting from  vfat formatted media
sed -i "s/vfat)/vfat) \\n   modprobe vfat/" init 
sync
# compress initrd
find . -print | cpio -H newc -o | gzip -9 > ../boot${VERDIR}/initrd.gz
statusfunc $?
sync
# Cleanup
cd ..
rm -rf initramfs/*
echo "find kernel and initrd in the $DIR diectory"
done

cd $SQDIR
cd ..

#==============================================================================

#move everything to top level
[ ! -d build ] && mkdir build
echo "copying files into build"
cp -arf $INITDIR/boot* build
mv -f $INITDIR/initrd* build
mv -f $SQDIR/$MAINSFS build 
if [ -f $SQDIR/extras.sfs ] ; then
	mv -f $SQDIR/extras.sfs build
fi
rm -f build/initrd*
rm -f $INITDIR/boot*/initrd*
statusfunc $?

#cleanup
echo "removing working dirs"
rm -rf $SQDIR
rm -rf initramfs

# option to install to a usb drive
echo -e "\\0033[1;34m"
echo "Would you like to copy the build files to a USBstick/SDcard?"
echo "If yes, please mount the USB stick or SDcard *NOW* "
echo "...and then hit \"c\" > enter to continue" 
echo "or just hit enter to finish and transfer the files manually"
read COPY
if [ "$COPY" = "c" ];then
	DEVICE=`df | awk 'END { print $6 }'`
	echo "The files will be transferred to $DEVICE."
	echo "if this is OK, hit \"t\" > enter to continue"
	echo "if not, hit enter to finish and transfer the files manually"
	read TRANSFER
		if [ "$TRANSFER" = "t" ];then
			rm -rf $DEVICE/boot*
			rm -rf $DEVICE/$MAINSFS
			cp -aR build/* $DEVICE/
			sync
		else
			echo "Copy all files in the ./build directory to USB media/SD card"
			echo " Done!"
			sync
		fi
else 
	echo "Copy all files in the ./build directory to USB media/SD card"
	echo " Done!"
fi
echo -en "\\0033[0;39m"

unset DISTRO_FILE_PREFIX #just to make sure, maybe the whole lot? Nah not exported
xoolpcfunc
statusfunc 0 

echo -e "\\0033[1;34m"
echo " Done!"
echo -en "\\0033[0;39m"


VERSION=0.3.1
system=redhat
curdir=`pwd`
RPM=`which rpm`
YUM=`which yum`
APT=`which apt-get`
DPKG=`which dpkg`
WGET=`which wget`
TAR=`which tar`
MAKE=`which make`
IFCONFIG=`which ifconfig`
ARCH=`uname -m`
skip=0
pause(){
	read -p "Press [Enter] key to continue..." fackEnterKey
}

one(){
	echo "one() called"
	pause
}
	
two(){
	echo "two() called"
	        pause
}
	
#change_fb_ip(){
#
#	clear
#	echo "Make sure the fonebridge is connected to eth1"
#	pause
#	echo -n "Enter new ip: "
#	read fbip
	
#	/usr/bin/fonulator --set-ip=$fbip
#	RETVAL=$?
	
	#if command was succesful change the ip in redfone.conf
#	if [ $RETVAL -eq 0 ]; then
#		echo "Changing ip in redfone.conf"
#		sed "/fb/cfb=$fbip" /etc/redfone.conf > temp
#		mv temp /etc/redfone.conf
#	fi
#	pause
#}

change_eth1_ip() {
	
	echo -n "Enter eth1's new ip address: "
	local ip
	read ip
	uci set network.fonebridge.ipaddr=$ip	
	#echo -n "Enter netmask (hit ENTER for default 255.255.255.0: "
	local netmask
	netmask=255.255.255.0
	#read netmask
	uci set network.fonebridge.netmask=$netmask
	uci commit network
	/etc/init.d/network restart
	
	if [ $? -eq 0 ]; then
		echo "IP address changed succesfully"
	fi
	pause

}

check_linux_distro() {

	if [ -f /etc/redhat-release ]; then
    		system=redhat
	else
	
		if [ -f /etc/debian_version ]; then
    			system=debian
		else

			echo "This script works only on redhat or debian based linux"
			exit 1
		fi
	fi

}

check_dependencies() {

	echo "Checking for dependencies"

	echo -n "Checking for libfb libraries: "
	if [ -f /usr/local/lib/libfb.so ]; then
		echo "Yes"
            	LIBFB=1
	else
		LIBFB=0
                echo "No"
                echo "Downloading libfb libraries"
                $WGET http://support.red-fone.com/downloads/fonulator/libfb-2.0.0.tar.gz &> /dev/null

		if [ $? -ne 0 ]; then
                	echo "Could not download libfb sources, download them manually, and run this script again"
                	exit 1
		fi

		$TAR -xzvf libfb-2.0.0.tar.gz &> /dev/null
	
		if [ $system = redhat ]; then
        		echo -n "Checking for libpcap: "
                	$RPM -qa | grep libpcap-devel &> /dev/null
                	if [ $? -eq 0 ]; then
                		echo "Yes"
                	else
				echo "No.. downloading libpcap"
				$YUM install libpcap-devel -y &> /dev/null
				if [ $? -ne 0 ]; then
					echo "Could not install libpcap-devel package"
					exit 1
				fi
			fi

			$RPM -qa | grep libpcap &> /dev/null
			if [ $? -ne 0 ]; then
				$YUM install libpcap -y &> /dev/null
				if [ $? -ne 0 ]; then
					echo "Could not install libpcap package"
					exit 1
				fi
			fi

			echo -n "Checking for libnet: "
                	$RPM -qa | grep libnet &> /dev/null
                	if [ $? -eq 0 ]; then
                        	echo "Yes"
                	else
                        	echo "No.. downloading libnet"
                        	$YUM install libnet -y &> /dev/null
                        	if [ $? -ne 0 ]; then
                                	echo "Could not install libnet package"
                                	exit 1
                        	fi
                	fi
		
		else	#system is debian

			echo -n "Checking for libpcap: "
			$DPKG -l | grep libpcap-dev &> /dev/null
		
			if [ $? -ne 0 ]; then
                		echo "No... downloading libpcap"
                		$APT install libpcap-dev -y &>/dev/null
                		if [ $? -ne 0 ]; then
                        		echo "Could not install libpcap-dev (apt-get install libpcap-dev failed)"
					exit 1
                        	fi
             		else
                		echo "Yes"
               		fi

			echo -n "Checking for libnet: "
                	$DPKG -l | grep libnet1 &>/dev/null
                	if [ $? -ne 0 ]; then
                		echo "No... downloading libnet"
                        	$APT install libnet1 -y &> /dev/null
                        	if [ $? -ne 0 ]; then
                        		echo "Could not install libnet (apt-get install libnet1 failed)"
                        		exit 1
                        	fi

                       		$DPKG -l | grep libnet1-dev &> /dev/null
                        	if [ $? -ne 0 ]; then
                        		$APT install libnet1-dev -y &> /dev/null
					
					if [ $? -ne 0 ]; then
                                        	echo "Could not install libnet-dev"
                                        	exit 1
					fi
                        	fi
            		else
                        	echo "Yes"
                	fi


			echo -n "Checking for libreadline: "
                	$DPKG -l | grep libreadline5-dev &> /dev/null
                	if [ $? -ne 0 ]; then
                		echo "No... downloading libreadline"
                    		$APT install libreadline5-dev -y &> /dev/null
				if [ $? -ne 0 ]; then
                                	echo "Could not install libreadline5-dev"
                                        exit 1
                                fi
                	else
 	               		echo "Yes"
			fi

		fi

		echo -n "Installing libfb... "

                cd libfb-2.0.0
                ./configure &> /dev/null
                $MAKE &> /dev/null
                $MAKE install &> /dev/null
                if [ $? -eq 0 ]; then
                        echo "done"
		else
			echo "Could not install libfb"
			exit 1
                fi
                cd ..
	fi

	#fonulator dependencies only

	case "$1" in
		fonulator)
		if [ $system = redhat ]; then
			echo -n "Checking for argtable2: "
    			$RPM -qa | grep argtable2 &> /dev/null
      			if [ $? -ne 0 ]; then
         			if [ $ARCH = i686 ]; then
                 			echo "No.. downloading argtable2"
                        		$WGET http://support.red-fone.com/downloads/tools/argtable2/argtable2-7-1.i386.rpm &> /dev/null
                      			$RPM -ivh argtable2-7-1.i386.rpm &> /dev/null
                		fi

         			if [ $? -ne 0 ] || [ $ARCH != i686 ]; then
                			echo "Could not install from rpm, Installing from source"
                       			rm -f argtable2-7-1.i386.rpm
                 			$WGET http://support.red-fone.com/downloads/tools/argtable2/argtable2-8.tar.gz &> /dev/null
                			$TAR -xzvf argtable2-8.tar.gz &> /dev/null

                  			cd argtable2-8
                   			./configure --includedir=/usr/include --libdir=/usr/lib &> /dev/null
                 			$MAKE &> /dev/null
                			$MAKE install &> /dev/null
                  			if [ $? -ne 0 ]; then
                				echo "could not install argtable2 libraries.. fonulator will not be installed"
                                                exit 1
                        		fi

                     			cd ..
         			fi
 			else

    				echo "Yes"
   			fi
		else
	
			echo -n "Checking for argtable2: "
               		$DPKG -l | grep libargtable2-dev &> /dev/null
               		if [ $? -ne 0 ]; then
                		echo "No... downloading argtable2 "
                        	$APT install libargtable2-dev -y &> /dev/null
				if [ $? -ne 0 ]; then
                                	echo "could not install argtable2 libraries.. fonulator will not be installed"
                                	exit 1
                                fi
               		else
                		echo "Yes"
                	fi


		fi
		;;

		*)
		;;
	esac


}

download_utilities() {

	echo -n "Checking for fb_flash_util: "
  	which fb_flash_util &> /dev/null
  	if [ $? -eq 0 ]; then
     		echo "Yes"
     		FBFLASH=1
  	else
     		echo "No"
     		FBFLASH=0
  	fi

  	echo -n "Checking for fonulator: "
  	which fonulator &> /dev/null
  	if [ $? -eq 0 ]; then
     		echo "Yes"
     		FONULATOR=1
  	else
     		echo "No"
     		FONULATOR=0
  	fi

	if [ $FBFLASH -eq 1 ] && [ $FONULATOR -eq 1 ]; then
		echo "foneBRIDGE2 utilities already installed"

	else
		if [ $FBFLASH -eq 0 ]; then
			echo "Installing fb_flash_util"
			check_dependencies
			find /usr/src -type f -name "fb*flash*tar*gz*" > fbflash-src
			if [ -s fbflash-src ]; then
				numfbflashsourcefiles=`cat fbflash-src | awk '{ print $1 }' | awk 'END { print NR }'`
				if [ $numfbflashsourcefiles -ne 1 ]; then
					echo "$numfbflashsourcefiles fb_flash_util sources files found:"
                                	cat fbflash-src | awk '{ print $1 }' | awk '{ print NR "\t" $0 }'
                                	echo -n "Select Option [1-$numfbflashsourcefiles]: "
                                	read parse
                                	tmpvar=`expr $numfbflashsourcefiles + 1 - $parse`
                                	fbflashsource=`cat fbflash-src | awk '{ print $1 }' | awk '{ print NR "\t" $0 }' | awk '{print $2 }' | tail -n $tmpvar | head -n 1`
				else

					fbflashsource=`cat fbflash-src`
                                	echo "fb_flash_util sources found in $fbflashsource"

				fi

				echo "unpacking $fbflashsource"
                             	$TAR -xzvf $fbflashsource &> /dev/null
			else
				echo "Downloading fb_flash_util"
                             	$WGET http://support.red-fone.com/fb_flash/fb_flash-2.0.0.tar.gz &> /dev/null
				if [ $? -ne 0 ]; then
                                	echo "Could not download fb_flash_util sources, download them manually, and run this script again"
                                	exit 1
                             	fi
				echo "unpacking fb_flash-2.0.0.tar.gz"
                             	$TAR -xzvf fb_flash-2.0.0.tar.gz &> /dev/null
				
			fi

			echo "Installing fb_flash_util"
                      	cd fb_flash-2.0.0

			if [ $system = debian ]; then
                        	./configure &> /dev/null
                                if [ $? -ne 0 ]; then
                                  	echo "Installing without readline support"
                                  	./configure --without-readline &> /dev/null
                                fi
                     	else
                       		./configure --without-readline &> /dev/null
                        fi

			$MAKE &> /dev/null
                        $MAKE install &> /dev/null

			if [ $? -ne 0 ]; then
				echo "Could not install fb_flash_util"
			else

				echo "fb_flash_util installed succesfully"
			fi
			
			cd ..
			
		fi

		if [ $FONULATOR -eq 0 ]; then
			echo "Installing fonulator"
			check_dependencies fonulator
			find /usr/src -type f -name "fonulator*tar*gz*" > fonulator-src
                    	if [ -s fonulator-src ]; then
				numfonsourcefiles=`cat fonulator-src | awk '{ print $1 }' | awk 'END { print NR }'`

                             	if [ $numfonsourcefiles -ne 1 ]; then
					echo "$numfonsourcefiles fonulator sources files found:"
                                	cat fonulator-src | awk '{ print $1 }' | awk '{ print NR "\t" $0 }'
                                	echo -n "Select Option [1-$numfonsourcefiles]: "
                                	read parse
                                	tmpvar=`expr $numfonsourcefiles + 1 - $parse`
                                	fonsource=`cat fonulator-src | awk '{ print $1 }' | awk '{ print NR "\t" $0 }' | awk '{print $2 }' | tail -n $tmpvar | head -n 1`
				else
                                	fonsource=`cat fonulator-src`
                                	echo "fonulator sources found in $fonsource"
                             	fi
				echo "unpacking $fonsource "
				$TAR -xzvf $fonsource &> /dev/null
			else
				echo "Downloading fonulator"
				$WGET http://support.red-fone.com/downloads/fonulator/fonulator-2.0.1.tar.gz &> /dev/null
				if [ $? -ne 0 ]; then
					echo "Could not download fonulator sources, download them manually, and run this script again"
					exit 1

				fi

				$TAR -xzvf fonulator-2.0.1.tar.gz &> /dev/null
			
			fi
			rm -rf fonulator-src
			cd fonulator-2.0.1
			./configure &> /dev/null
			$MAKE &> /dev/null
                        $MAKE install &> /dev/null

                        if [ $? -ne 0 ]; then
                                echo "Could not install fonulator"
                        else

                                echo "fonulator installed succesfully"
                        fi

                        cd ..
			
		fi
	fi

	pause
	

}

auto_detect() {

	FB_FLASH=`which fb_flash_util`
	if [ $? -ne 0 ]; then
		echo "fb_flash_util not installed, please install utilities and try again"
		exit 1
	fi

	numnics=`$IFCONFIG -a | grep Ethernet | awk '{ print $1 }' | awk 'END { print NR }'`
	echo  "Which Ethernet card will be used with the fonebridge? "
	$IFCONFIG -a | grep Ethernet | awk '{ print $1 }' | awk '{ print NR "\t" $0 }'
	echo -n "Select Option [1-$numnics]: "
	read ethn
	echo $ethn>tmpvar
	cat tmpvar | grep [a-zA-Z] > /dev/null
	if  [ $? -ne 0 ]; then
		isnum=1
	else
		isnum=0
	fi
	
	if [ $isnum = 1 ]; then
		if [ $ethn -ge 1 ] && [ $ethn -le $numnics ]; then
             		validchoice=1
          	else
			validchoice=0
		fi
	fi

	while [ $isnum = 0 ] || [ $validchoice = 0 ]; do
		echo -n "Please enter a valid number from 1 to $numnics: "
		read ethn
		echo $ethn>tmpvar
		cat tmpvar | grep [a-zA-Z] > /dev/null
		if  [ $? -ne 0 ]; then
			isnum=1
			if [ $ethn -ge 1 ] && [ $ethn -le $numnics ] ; then
                  		validchoice=1
			else
				validchoice=0
			fi
		else
			isnum=0
		fi
	done

	rm -f tmpvar
	tmpvar=`expr $numnics + 1 - $ethn`
	ethn=`$IFCONFIG -a | grep Ethernet | awk '{ print $1 }' | awk '{ print NR "\t" $0 }' | awk '{print $2 }' | tail -n $tmpvar | head -n 1`
        echo "You selected $ethn"

	echo -n "Which port of the fonebridge will you be using for TDMoE traffic(1 or 2)? "
	read port

        while [ $port != "1" ] && [ $port != "2" ]; do
          	echo -n "Please select 1 or 2: "
          	read port
        done

	link=`ethtool $ethn | grep Link | cut -d ' ' -f3`
	ethtool $ethn &> /dev/null	
	if [ $? -ne 0 ]; then
           	echo "Could not obtain link status, exiting"
           	return 1
        fi

	if [ $link != yes ]; then
          	echo "**************************************************"
          	echo "* Link is down, please check that the fonebridge *"
          	echo "* is connected to $ethn and powered on, then try  *"
          	echo "* running this script again.                     *"
          	echo "**************************************************"
		pause
		return 1
       	fi

	echo "Trying to query device"
	echo "If there is no response after a few seconds please verify"
	echo "that the foneBRIDGE2 is properly connected to $ethn"

	$FB_FLASH -i $ethn > fonebridge.info
	echo "current port: $port" >> fonebridge.info
	echo "server nic: $ethn" >> fonebridge.info
	echo "foneBRIDGE2 found"
	if [ $port -eq 1 ]; then
		mac=`cat fonebridge.info | grep -i 00:50:c2 | head -n 1 | awk '{print $2}'`
		fb=`cat fonebridge.info | grep IP |  head -n 1 | awk '{print $2}'`
	else
		mac=`cat fonebridge.info | grep -i 00:50:c2 | tail -n 1 | awk '{print $2}'`
		fb=`cat fonebridge.info | grep IP |  tail -n 1 | awk '{print $2}'`
	fi

	server=`cat fonebridge.info | grep "Source MAC" | awk '{print $3}'`
	numP=`cat fonebridge.info | grep Spans | awk '{print $2}'`		
	echo "You have a $numP port fonebridge"
      	echo "IP address of fonebridge port connected to $ethn:  $fb"
      	echo "MAC address of fonebridge port connected to $ethn: $mac"
      	echo "MAC address of $ethn:                              $server"
	
	if [ -e /etc/redfone.conf ]; then
		echo "foneBRIDGE2 configuration file found"
		sed '/server/ c\server='"$server"'' /etc/redfone.conf > redfone.temp
		sed '/fb/ c\fb='"$fb"'' /etc/redfone.conf > redfone.temp	
		echo "Updating /etc/redfone.conf"
		mv redfone.temp /etc/redfone.conf
	else
		#generate a template redfone.conf with default values

		echo "[globals]" > /etc/redfone.conf
		echo "server=$server" >> /etc/redfone.conf
		echo "fb=$mac" >> /etc/redfone.conf 
		echo "priorities=0,1,2,3" >> /etc/redfone.conf
		echo "" >> /etc/redfone.conf

		for i in `seq 1 $numP`; do
			echo "[span$i]" >> /etc/redfone.conf
			echo "framing=esf" >> /etc/redfone.conf
			echo "encoding=b8zs" >> /etc/redfone.conf
			echo "" >> /etc/redfone.conf
		done		
	fi
	pause	

}

generate_redfoneconf() {

	echo "generating /etc/redfone.conf"
	echo "## Automatically Generated REDFONE Config" > redfone.gen
	echo "## Generator Version $VERSION" >> redfone.gen
	echo "" >> redfone.gen
	echo "[globals]" >> redfone.gen
	echo "fb=$fb" >> redfone.gen
	echo "port=$port" >> redfone.gen
	echo "server=$server" >> redfone.gen
	echo "priorities=$priorities" >> redfone.gen
	echo "" >> redfone.gen

	for i in `seq 1 $numP`; do
		let parse=${t1[$i]} 1
	
		if [ $parse -gt -1 ]; then
			echo "[span$i]" >> redfone.gen
     			echo "framing=${framing[$i]}" >> redfone.gen
    			echo "encoding=${encoding[$i]}" >> redfone.gen
			if [ ${rbs[$i]} -eq 1 ]; then
        			echo "rbs" >> redfone.gen
     			fi

     			if [ ${crc4[$i]} -eq 1 ]; then
        			echo "crc4" >> redfone.gen
     			fi
		
			
		fi
		echo "" >> redfone.gen
	done
	
}

generate_zaptelconf()
{
	echo "##Automatically Generated dahdi configuration file" > zaptel.conf
	echo "##Generator Version $VERSION" >> zaptel.conf
	echo "" >> zaptel.conf

	for i in `seq 1 $numP`; do
		let parse=${t1[$i]} 1
		echo -n "dynamic=ethmf,$ethn/$mac/`expr $i - 1`," >> zaptel.conf
 		if [ $parse -eq 1 ]; then
     			echo -n "24," >> zaptel.conf
 		else
     			echo -n "31," >> zaptel.conf
 		fi

		if [ $i -eq $numP ]; then
			echo "1" >> zaptel.conf
     			echo "" >> zaptel.conf
 		else
     			echo "0" >> zaptel.conf
 		fi
	done

	currchan=1
	for i in `seq 1 $numP`; do
		let parse=${t1[$i]} 1
		if [ ${rbs[$i]} -eq 1 ]; then
			echo -n "${rbsign[$i]}=$currchan-" >> zaptel.conf
			if [ $parse -eq 1 ]; then
				let currchan=currchan+23
                        	echo "$currchan" >> zaptel.conf
                        	echo "" >> zaptel.conf
				let currchan=currchan+1
			else
				firstchan=$currchan
				if [ ${framing[$i]} = cas ]; then
					let currchan=currchan+14
                           		echo "$currchan:1101" >> zaptel.conf
                           		let currchan=currchan+1
                           		echo "dchan=$currchan" >> zaptel.conf
                           		let currchan=currchan+1
                           		echo -n "cas=$currchan-" >> zaptel.conf
                           		let currchan=currchan+14
                           		echo "$currchan:1101" >> zaptel.conf
                           		echo "alaw=$firstchan-$currchan" >> zaptel.conf
                           		let currchan=currchan+1
                           		echo "" >> zaptel.conf
				else
					let currchan=currchan+30
                           		echo "$currchan" >> zaptel.conf
                           		echo "alaw=$firstchan-$currchan" >> zaptel.conf
                           		echo "" >> zaptel.conf
                           		let currchan=currchan+1
					
				fi
			
			fi
		else
			
			echo -n "bchan=$currchan-" >> zaptel.conf
			if [ $parse -eq 1 ]; then
				let currchan=currchan+22
                        	echo "$currchan" >> zaptel.conf	
				let currchan=currchan+1
                        	echo "dchan=$currchan" >> zaptel.conf
                        	echo "" >> zaptel.conf		
				let currchan=currchan+1
			else
				firstchan=$currchan
				let currchan=currchan+14
                        	echo "$currchan" >> zaptel.conf
				let currchan=currchan+1
                        	echo "dchan=$currchan" >> zaptel.conf
                        	let currchan=currchan+1
				echo -n "bchan=$currchan-" >> zaptel.conf
				let currchan=currchan+14
                        	echo "$currchan" >> zaptel.conf
				echo "alaw=$firstchan-$currchan" >> zaptel.conf
				echo "" >>zaptel.conf
				let currchan=currchan+1
			fi

		fi

	done

	echo "" >> zaptel.conf
	echo "loadzone=us" >> zaptel.conf
	echo "defaultzone=us" >> zaptel.conf
}
		
generate_zapata () {


	echo ";Automatically Generated $tmpstr configuration file" > zapata.conf
        echo ";Generator Version $VERSION" >> zapata.conf
        echo "" >> zapata.conf

        echo "[trunkgroups]" >> zapata.conf
        echo "" >> zapata.conf

        echo "[channels]" >> zapata.conf
        echo "usecallerid=yes" >> zapata.conf
        echo "hidecallerid=no" >> zapata.conf
        echo "callwaiting=yes" >> zapata.conf
        echo "usecallingpres=yes" >> zapata.conf
        echo "callwaitingcallerid=yes" >> zapata.conf
        echo "threewaycalling=yes" >> zapata.conf
        echo "transfer=yes" >> zapata.conf
        echo "canpark=yes" >> zapata.conf
        echo "cancallforward=yes" >> zapata.conf
        echo "callreturn=yes" >> zapata.conf
        echo "echocancel=no" >> zapata.conf
        echo "echocancelwhenbridged=no" >> zapata.conf
        echo "relaxdtmf=yes" >> zapata.conf
        echo "rxgain=0.0" >> zapata.conf
        echo "txgain=0.0" >> zapata.conf
        echo "group=1" >> zapata.conf
        echo "callgroup=1" >> zapata.conf
        echo "pickupgroup=1" >> zapata.conf
        echo "" >> zapata.conf
	currchan=1
	for i in `seq 1 $numP`; do
		let parse=${t1[$i]} 1
		echo -n "context=" >> zapata.conf
                echo "${context[$i]}" >> zapata.conf
		if [ ${rbs[$i]} -eq 1 ]; then
		#echo -n "context=" >> zapata.conf
        	#echo "${context[$i]}" >> zapata.conf
			echo -n "signalling=" >> zapata.conf
                	echo "${ast_sign[$i]}" >> zapata.conf
			echo -n "channel => $currchan-" >> zapata.conf
			if [ $parse -eq 1 ]; then
				let currchan=currchan+23
				echo "$currchan" >> zapata.conf
				echo "" >> zapata.conf
				let currchan=currchan+1
			else
				let currchan=currchan+1
				if [ ${framing[$i]} = cas ]; then
				
					let currchan=currchan+14
					echo -n "$currchan, " >> zapata.conf
					let currchan=currchan+2
					echo -n "$currchan-" >> zapata.conf
                           		let currchan=currchan+14
					echo "" >> zapata.conf
					let currchan=currchan+1
				else
					let currchan=currchan+30
					echo "$currchan" >> zapata.conf
					echo "" >> zapata.conf
					let currchan=currchan+1
				fi
			fi
		else
			echo "switchtype=${switchtype[$i]}" >> zapata.conf
			echo -n "signalling=" >> zapata.conf
                	echo "${ast_sign[$i]}" >> zapata.conf
                	echo -n "channel => $currchan-" >> zapata.conf
			if [ $parse -eq 1 ]; then
                        	let currchan=currchan+22
				echo "$currchan" >> zapata.conf
                        	echo "" >> zapata.conf
                        	let currchan=currchan+2
				
			else
				firstchan=$currchan
                        	let currchan=currchan+14
				echo -n "$currchan, " >> zapata.conf
                        	let currchan=currchan+2
				echo -n "$currchan-" >> zapata.conf
                        	let currchan=currchan+14
				echo "$currchan" >> zapata.conf
				echo "" >> zapata.conf
                        	let currchan=currchan+1
			fi
		fi
	done
}

sel_clk_src() {

	echo "Select clk source: "
	
	case "$numP" in
		1)
			echo "1. Span 1"
			echo "2. Internal"
			echo -n "Select choice [1-2]: "

			read parse
			case "$parse" in
				1*)
					priorities=0,1,2,3
				;;
				2*)
					priorities=0,0,0,0
				;;
				*)
					echo "Invalid choice, selecting Span 1"
					priorities=0,1,2,3
				;;
			esac
		;;
		2)
			echo "1. Span 1"
			echo "2. Span 2"
                        echo "3. Internal"
                        echo -n "Select choice [1-3]: "
			
			read parse
                        case "$parse" in
                                1*)
                                        priorities=0,1,2,3
                                ;;
                                2*)
                                        priorities=1,0,2,3
                                ;;
                                3*)
                                        priorities=0,0,0,0
                                ;;
				*)
					echo "Invalid choice, selecting Span 1"
                                        priorities=0,1,2,3
				;;
                        esac

		
		;;
		4)
			echo "1. Span 1"
                        echo "2. Span 2"
			echo "3. Span 3"
                        echo "4. Span 4"
                        echo "5. Internal"
                        echo -n "Select choice [1-5]: "
			read parse
                        case "$parse" in
                                1*)
                                        priorities=0,1,2,3
                                ;;
                                2*)
                                        priorities=1,0,2,3
                                ;;
				3*)
					priorities=1,2,0,3
				;;
				4*)
					priorities=1,2,3,0
				;;
                                5*)
                                        priorities=0,0,0,0
                                ;;
                                *)
                                        echo "Invalid choice, selecting Span 1"
                                        priorities=0,1,2,3
                                ;;
                        esac
			

		;;
	esac
		

}

update_config_files() {

	echo "The script will now update the following files: "
	echo " /etc/redfone.conf"
	echo " /etc/dahdi/system.conf"
	echo " /etc/asterisk/chan_dahdi.conf" 
	echo -n "Enter y to continue, n to cancel: "
	read parse
	case "$parse" in
		n*|C*) 
			echo "Configuration not updated, generated files saved in"
			currdir=`pwd`
			echo "$currdir/redfone.conf"
			echo "$currdir/system.conf"
			echo "$currdir/chan_dahdi.conf"
			mv redfone.gen redfone.conf
			mv zaptel.conf system.conf
			mv zapata.conf chan_dahdi.conf
			
		;;
	
		*)	
			echo "Configuration files updated"
			mv redfone.gen /etc/redfone.conf
			mv zaptel.conf /etc/dahdi/system.conf
			mv zapata.conf /etc/asterisk/chan_dahdi.conf
		
		;;
	esac
	pause
	
	

}

configure_spans() {

	clear
	echo "Individual Span Configuration"
#	echo "Are you using ZAPTEL or DAHDI?"
#        echo "  1. Zaptel"
#        echo "  2. DAHDI"
#	read ZORD

#	while [ $ZORD != 1 ] && [ $ZORD != 2 ]; do
#        	echo -n "Invalid option enter 1 or 2: "
#       		read ZORD
#        done

#	if [ $ZORD -eq 1 ]; then
#        	tmpstr=zapata.conf
#        else
#            	tmpstr=chan_dahdi.conf
#        fi

	tmpstr=chan_dahdi.conf
	
	stayinloop=1
	echo -n "Would you like to configure $tmpstr? (yes/no) "
	while [ $stayinloop -eq 1 ]; do
        	read parse
                case "$parse" in
                	Y*|y*)
                	CONFZORD=1
                 	stayinloop=0
                        ;;
                        N*|n*)
                        CONFZORD=0
                        stayinloop=0
                        ;;
                        *)
                        stayinloop=1
                        echo -n "Please enter yes or no: "
                        ;;
                esac
   	done

	for i in `seq 1 $numP`; do
		echo "Span $i..."
        	echo "Is this a T1 or an E1?"
		t1[$i]=-1
		if [ $i -gt 1 ]; then
			echo ""
			echo  "Hit ENTER key to configure Span $i the same as Span `expr $i - 1`: "
			
			if [ ${t1[$i-1]} -eq 0 ]; then
				echo  "Span `expr $i - 1` configured as E1 "
                  		echo  "  framing=${framing[$i-1]}"
                  		echo  "  encoding=${encoding[$i-1]}"
				if [ ${crc4[$i-1]} -eq 1 ]; then
					echo "  crc4" 
				fi
				if [ ${rbs[$i-1]} -eq 1 ]; then
					echo "  signalling=${rbsign[$i-1]}"
				else
					echo "  signalling=${ast_sign[$i-1]}"
					echo "  switchtype=${switchtype[$i-1]}" 
				fi
				echo "  context=${context[$i-1]}"
			fi
			if [ ${t1[$i-1]} -eq 1 ]; then
				echo  "Span `expr $i - 1` configured as T1 "
                  		echo  "  framing=${framing[$i-1]}"
                 		echo  "  encoding=${encoding[$i-1]}"
				
				if [ ${rbs[$i-1]} -eq 1 ]; then
                                        echo "  signalling=${rbsign[$i-1]}"
                                else
                                        echo "  signalling=${ast_sign[$i-1]}"
                                        echo "  switchtype=${switchtype[$i-1]}"
                                fi
				echo "  context=${context[$i-1]}"
                	fi
		fi
			
		    while [ ${t1[$i]} -eq -1 ]; do		
		
			echo -n "Enter T for T1, E for E1: "
			read parse
			case "$parse" in
				E*|e*)
					skip=0
                 			t1[$i]=0
					rbs[$i]=0
					echo "Okay, E1."
					echo -n "Enter framing (cas ccs): "
					read parse
					case "$parse" in
						cas*)
							echo "framing=cas"
							framing[$i]=cas
						;;
						ccs*)
							echo "framing=ccs"
							framing[$i]=ccs
						;;
						*)
							if [ $i -eq 1 ]; then
								framing[$i]=ccs	
								echo "Setting framing to default value: ccs"
							else
								if [ ${t1[$i-1]} -eq ${t1[$i]} ]; then
									framing[$i]=${framing[$i-1]}
									echo "framing=${framing[$i-1]}"
								else
									echo "Setting framing to default value: ccs"
								fi
							fi

						;;
					esac
					echo -n "Enter encoding (ami hdb3): "
					read parse
                 			case "$parse" in
						a*)
                     					echo "encoding=ami"
                     					encoding[$i]=ami	
						;;
						h*)
                     					echo "encoding=hdb3"
                     					encoding[$i]=hdb3		
						;;
						*)
							if [ $i -eq 1 ]; then
                        					encoding[$i]=hdb3
                        					echo "Setting encoding to default value: hdb3"
                     					else
								if [ ${t1[$i-1]} -eq ${t1[$i]} ]; then
									encoding[$i]=${encoding[$i-1]}
                          						echo "encoding=${encoding[$i-1]}"
								else
									encoding[$i]=hdb3
									echo "Setting encoding to default value: hdb3"
								fi
							fi
						;;
					esac
					
					echo -n "Do you need CRC4 support on span $i? [yn] "
					read parse
					case "$parse" in
                     				Y*|y*)
                      					crc4[$i]=1
                     				;;
                     				*)
                      					crc4[$i]=0
                     				;;
                 			esac
				;;

				T*|t*)
					skip=0
					t1[$i]=1
                 			crc4[$i]=0
                 			echo "Okay, T1."
                 			echo -n "Enter framing (sf esf):"
					read parse
                 			case "$parse" in 
						s*|S*)
                     					echo "framing=sf"
                    					 framing[$i]=sf
                     				;;
                     				e*|E*)
                     					echo "framing=esf"
                     					framing[$i]=esf
                     				;;
						*)
							if [ $i -eq 1 ]; then
                        					framing[$i]=esf
                        					echo "Setting to framing to default value: esf"
                     					else
								if [ ${t1[$i-1]} -eq ${t1[$i]} ]; then
									framing[$i]=${framing[$i-1]}
                          						echo "framing=${framing[$i-1]}"
								else
									framing[$i]=esf
                          						echo "Setting to framing to default value: esf"
								fi
							fi
						;;
					esac

					echo -n "Enter encoding (ami b8zs): "
					read parse
                 			case "$parse" in
                     				a*)
                     					echo "encoding=ami"
                     					encoding[$i]=ami
                     				;;
                     				b*)
                     					echo "encoding=b8zs"
                     					encoding[$i]=b8zs
                     				;;
                     				*)
							if [ $i -eq 1 ]; then
								encoding[$i]=esf
                        					echo "Setting encoding to default value: b8zs"
							else
								if [ ${t1[$i-1]} -eq ${t1[$i]} ]; then
									encoding[$i]=${encoding[$i-1]}
									echo "encoding=${encoding[$i-1]}"
								else
									encoding[$i]=b8zs
									echo "Setting encoding to default value: b8zs"
								fi
							fi
						;;
					esac

				;;		
				
				*)
					if [ $i -gt 1 ]; then
						echo -n "Span $i configured as  "
						if [ ${t1[$i-1]} -eq 1 ]; then
							echo "T1"
                     				else
                        				echo "E1"
                     				fi		

						t1[$i]=${t1[$i-1]}
						framing[$i]=${framing[$i-1]}
						encoding[$i]=${encoding[$i-1]}
						rbs[$i]=${rbs[$i-1]}
						crc4[$i]=${crc4[$i-1]}
						rbsign[$i]=${rbsign[$i-1]}
                                        	ast_sign[$i]=${ast_sign[$i-1]}
						switchtype[$i]=${switchtype[$i-1]}
						context[$i]=${context[$i-1]}
						skip=1
					else
						echo "Invalid Choice"
                     				echo -n "  Please enter T1 or E1: "
                     				t1[$i]=-1
					fi
				;;
			esac
		    done
			if [ $skip -ne 1 ]; then
				
				if [ ${t1[$i]} -eq 0 ]; then
					if [ ${framing[$i]} = cas ]; then
						echo  "Select signaling type"
						echo  " 1. FXS Loop Start"
						echo  " 2. FXS Ground Start"
              					echo  " 3. FXS Kewl Start"
              					echo  " 4. FXO Loop Start"
              					echo  " 5. FXO Ground Start"
              					echo  " 6. FXO Kewl Start"
              					echo  " 7. E & M"
              					echo  " 8. E & M Wink"
              					echo  " 9. MFC/R2"
              					echo  -n " Select Option [1-9]: "
					else
						echo  "Select signaling type"
              					echo  " 1. PRI CPE"
              					echo  " 2. PRI NET"
              					echo  " 3. FXS Loop Start"
              					echo  " 4. FXS Ground Start"
              					echo  " 5. FXS Kewl Start"
              					echo  " 6. FXO Loop Start"
              					echo  " 7. FXO Ground Start"
              					echo  " 8. FXO Kewl Start"
              					echo  " 9. E & M"
              					echo  "10. E & M Wink"
              					echo  -n " Select Option [1-10]: "

					fi
				else

					echo  "Select signaling type"
           				echo  " 1. PRI CPE"
           				echo  " 2. PRI NET"
           				echo  " 3. FXS Loop Start"
           				echo  " 4. FXS Ground Start"
           				echo  " 5. FXS Kewl Start"
           				echo  " 6. FXO Loop Start"
           				echo  " 7. FXO Ground Start"
           				echo  " 8. FXO Kewl Start"
           				echo  " 9. E & M"
           				echo  "10. E & M Wink"
           				echo  -n " Select Option [1-10]: "

				fi

				read parse
				echo ""
				echo ""
				if [ ${t1[$i]} -eq 0 ]; then
           				if [ ${framing[$i]} = cas ]; then
             					let parse=parse+2
           				fi
         			fi
			
				case "$parse" in
			
					1|P*|p*|C*|c*)
						rbs[$i]=0
                				ast_sign[$i]=pri_cpe
					;;

					2*|N*|n*)
                				rbs[$i]=0
                				ast_sign[$i]=pri_net
					;;
				
					3*|L*|l*)
                				rbs[$i]=1
                				rbsign[$i]=fxsls
                				ast_sign[$i]=fxs_ls
					;;
			
					4*|G*|g*)
                				rbs[$i]=1
                				rbsign[$i]=fxsgs
                				ast_sign[$i]=fxs_gs

                			;;

                			5*|K*|k*)
                				rbs[$i]=1
                				rbsign[$i]=fxsks
                				ast_sign[$i]=fxs_ks

                			;;

                			6*)
                				rbs[$i]=1
                				rbsign[$i]=fxols
                				ast_sign[$i]=fxo_ls
                			;;
				
					7*)
                				rbs[$i]=1
                				rbsign[$i]=fxogs
                				ast_sign[$i]=fxo_gs

                			;;

                			8*)
                				rbs[$i]=1
                				rbsign[$i]=fxoks
                				ast_sign[$i]=fxo_ks

                			;;

                			9*)
                				rbs[$i]=1
                				rbsign[$i]='e&m'
                				ast_sign[$i]=em

                			;;
				
					10*)
                				rbs[$i]=1
                				rbsign[$i]='e&m'
                				ast_sign[$i]=em_w

                			;;

                			11*)
                				rbs[$i]=1
                				rbsign[$i]=cas
                				ast_sign[$i]=mfcr2

					;;

					*)
						echo "No option selected, setting signaling of Span $i to pri cpe"
                				rbs[$i]=0
						ast_sign[$i]=pri_cpe
					;;
				esac
	
				if [ $CONFZORD -eq 1 ]; then
					if [ ${rbs[$i]} -eq 0 ]; then
						echo  "Select switchtype"
           					echo  " 1. National ISDN 2"
           					echo  " 2. Nortel DMS100"
           					echo  " 3. AT&T 4ESS"
           					echo  " 4. Lucent 5ESS"
           					echo  " 5. EuroISDN"
           					echo  " 6. Old National ISDN 1"
           					echo  " 7. Q.SIG"
           					echo  -n "Select option [1-7]: "
           					read parse
           					echo ""
           					echo ""
						case "$parse" in
							1*|N*|n*)
                						switchtype[$i]=national
							;;

							2*|D*|d*)
								switchtype[$i]=dms100
							;;
						
							3*)
                						switchtype[$i]=4ess

                					;;

                					4*)
                						switchtype[$i]=5ess

                					;;

                					5*)
                						switchtype[$i]=euroisdn

                					;;

                					6*)
                						switchtype[$i]=ni1	
							;;

							7*)
                						switchtype[$i]=qsig
							;;
						esac
					fi
				
					echo  "Select context"
          				echo  " 1. from-pstn"
          				echo  " 2. from-internal"
          				echo  " 3. custom"
          				echo  -n "Select option: [1-3]: "

					read parse
          				echo ""
          				echo ""
          				case "$parse" in

						1*)
                					context[$i]=from-pstn
                				;;

                				2*)
                					context[$i]=from-internal
                				;;

                				3*)
                					echo "Enter name of context"
                					read context[$i]
                				;;
          				esac
				fi
			fi
	done

	echo ""
	sel_clk_src
	generate_redfoneconf
	generate_zaptelconf
	generate_zapata	
	update_config_files	
}

query_fonebridge() {

	/usr/bin/fonulator -vq
	pause
}
tslinknet_license() {

	#run tslinknet, it will take care of itself
	echo ""
	cd /etc/tslinknet
	/etc/tslinknet/tslinknet
	pause

}

reset_defaults() {

	echo "Reseting Defaults..."
	uci set network.lan.proto=dhcp
	uci set network.fonebridge.proto=static
	uci set network.fonebridge.ipaddr=192.168.1.200
	uci set network.fonebridge.netmask=255.255.255.0
	/etc/init.d/network restart
}

write_fb_config() {

	echo "This will save the current configuration to the device"
	echo "so in the case of a power cycle the device will keep its"
	echo "configuration"
	pause
	fonulator --write-config
	pause
}

reboot_fb() {

	fonulator --reboot
}

change_fb_ip() {

	echo "Select the ethernet port to be changed"
	echo "1. fb1"
	echo "2. fb2"
	read fbportnum

	while [ $fbportnum -ne 1 ] && [ $fbportnum -ne 2 ] ; do
		echo "please enter 1 or 2"
		read fbportnum
	done

	echo -n "Enter new ip: "
	read newip

	if [ $fbportnum -eq 1 ]; then
		fonulator --set-ip=$newip
	else
		fonulator --set-ip=$newip --fb2
	fi

	if [ $? -eq 0 ]; then
		if [ $fbportnum -eq 1 ] ; then
			echo "Changing ip in /etc/redfone.conf"
			sed "/fb/cfb=$newip" /etc/redfone.conf > temp
        		mv temp /etc/redfone.conf	
			echo "Warning: The foneBRIDGE2's ip address was changed"
			echo "you will need to make sure that your network card"
			echo "is on the same subnet in order to access the device"
		fi
	fi

	pause
}

configure_T1() {
	
	echo "All spans will be configured as T1 PRI"
	for i in `seq 1 $numP`; do	
		t1[$i]=1
  		framing[$i]=esf
   		encoding[$i]=b8zs
    		rbs[$i]=0
        	crc4[$i]=0
        	rbsign[$i]=0
        	ast_sign[$i]=pri_cpe
        	switchtype[$i]=national
        	context[$i]=from-pstn
	done
	priorities=0,1,2,3
	generate_redfoneconf
	generate_zaptelconf
	generate_zapata
 	update_config_files	
}

configure_E1() {

	echo "All spans will be configured as E1 PRI"
	for i in `seq 1 $numP`; do
                t1[$i]=0
                framing[$i]=ccs
                encoding[$i]=hdb3
                rbs[$i]=0
                crc4[$i]=0
                rbsign[$i]=0
                ast_sign[$i]=pri_cpe
                switchtype[$i]=euroisdn
                context[$i]=from-pstn
        done
	priorities=0,1,2,3
        generate_redfoneconf
        generate_zaptelconf
        generate_zapata
	update_config_files

}

run_diagnostics() {

	serialno=`fb_flash_util -i $ethn | grep Serial | awk '{print $2}'`
	echo "Device Serial Number: $serialno" > $serialno.log
	echo -n "Model: " >> $serialno.log
	case "$numP" in
        	1)
                	echo "  750-4000" >> $serialno.log
               	;;
          	2)
            		echo "  750-5050" >> $serialno.log
             	;;

       		4)      echo "  750-5000" >> $serialno.log
              	;;
        esac

	echo "  IP address: $fb" >> $serialno.log
        echo "  MAC address: $mac" >> $serialno.log
	echo "" >> $serialno.log
	echo "System information" >> $serialno.log
	echo -n " "
	cat /etc/issue | head -n 1 >> $serialno.log
	echo -n " Kernel Version: " >>$serialno.log
	uname -r >> $serialno.log
	echo "" >> $serialno.log
	cat /proc/cpuinfo >> $serialno.log

	echo "" >> $serialno.log
	echo "" >> $serialno.log

	echo "foneBRIDGE2 configuration file /etc/redfone.conf" >> $serialno.log
	cat /etc/redfone.conf >> $serialno.log
	echo "" >> $serialno.log
	echo "" >> $serialno.log

	echo "DAHDI configuration file" >> $serialno.log
	cat /etc/dahdi/system.conf >> $serialno.log

	if [ -f redfone_temp ]; then
		rm -f redfone_temp
	fi
	
	if [ -d /proc/dahdi ]; then
		for i in `seq 1 $numP`; do
        		cat /proc/dahdi/$i | head -n 1 >> redfone_temp
        	done	

		sed -i 's/" (MASTER)/"/g' redfone_temp

		echo "" >> $serialno.log
		echo "" >> $serialno.log
		echo "Dahdi Status:" >> $serialno.log
		for i in `seq 1 $numP`; do                               
        		alarm=`awk 'NR=="'"$i"'"' "redfone_temp" | awk '{print $9}'`
			echo -n "Span $i: " >> $serialno.log
			case "$alarm" in
		
				red|RED)
				echo "red" >> $serialno.log
				;;
			
				YEL*|yel*)
				echo "yellow" >> $serialno.log
				;;
			
				*)
				echo "OK" >> $serialno.log
				;;
			esac
		done
	#cat redfone_temp >> $serialno.log
			rm -f redfone_temp

	else
		echo "dahdi not configured" >> $serialno.log
	fi

	echo "" >> $serialno.log
	echo "" >> $serialno.log
	echo "Network Card Information:" >> $serialno.log
	lspci | grep Eth >> $serialno.log
	echo "" >> $serialno.log	
	echo "driver information for $ethn: " >> $serialno.log
	ethtool -i $ethn >> $serialno.log
	
	echo "" >> $serialno.log

	echo "Interrupts: " >> $serialno.log
	cat /proc/interrupts | head -n 1 >> $serialno.log
	cat /proc/interrupts | grep $ethn >> $serialno.log
	sleep 1
	cat /proc/interrupts | grep $ethn >> $serialno.log

	echo -n "Diagnostics file saved in: "
	currdir=`pwd`
	echo "$currdir/$serialno.log"
	echo "Please attach a copy of this file when contacting support"
	echo ""
	pause
}


show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo " Redfone Configuration helper       "
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1.  Download foneBRIGDE2 utilities"
	echo "2.  Auto detect device"
	echo "3.  Configure Spans"
	echo "4.  Quick T1 configuration (configures all spans as T1 PRI)"
	echo "5.  Quick E1 configuration (configures all spans as E1 PRI)"
	echo "6.  Write foneBRIDGE2 configuration permanently"
	echo "7.  Reboot Fonebridge"
	echo "8.  Change foneBRIDGE2 ip address"
	echo "9.  Run Diagnostics"
	echo "10. Exit"
	echo ""
	
	if [ -e ./fonebridge.info ]; then
		numP=`cat fonebridge.info | grep Spans | awk '{print $2}'`	
		port=`cat fonebridge.info | grep current | awk '{print $3}'`
		ethn=`cat fonebridge.info | grep nic | awk '{print $3}'`
		echo "Detected foneBRIDGE2 device on $ethn: "
		if [ $port -eq 1 ]; then
                	mac=`cat fonebridge.info | grep -i 00:50:c2 | head -n 1 | awk '{print $2}'`
                	fb=`cat fonebridge.info | grep IP |  head -n 1 | awk '{print $2}'`
        	else
                	mac=`cat fonebridge.info | grep -i 00:50:c2 | tail -n 1 | awk '{print $2}'`
                	fb=`cat fonebridge.info | grep IP |  tail -n 1 | awk '{print $2}'`
        	fi
		
		case "$numP" in
			1)
				echo "  750-4000"
			;;
			2)
				echo "  750-5050"
			;;

			4)	echo "  750-5000"
			;;
		esac

        	echo "  IP address: $fb"
        	echo "  MAC address: $mac"
	fi
	echo ""
	echo ""
	

}

read_options(){
	local choice
	read -p "Enter choice [1 - 10] " choice
	case $choice in
		1) download_utilities ;;
		2) auto_detect ;;
		3) configure_spans ;;
		4) configure_T1 ;;
		5) configure_E1 ;;
		6) write_fb_config ;;
		7) reboot_fb ;;
		8) change_fb_ip ;;
		9) run_diagnostics;;
		10) exit 0;;
		11) /bin/bash --login;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
		esac
}

#trap '' SIGINT SIGQUIT SIGTSTP

check_previous_conf () {

	if [ -e /etc/redfone.conf ]; then
		echo "Previous configuration found"
		numP=`cat /etc/redfone.conf | grep span | wc -l`
	fi

}

while true	
do						
	show_menus
	read_options
done



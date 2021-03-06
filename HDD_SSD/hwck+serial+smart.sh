#!/bin/bash
#https://gist.github.com/adobkin/1066874
#http://joxi.net/LmGnGbzURXqM3r
OSNAME=""
OSVER=""
OSVERNUM=""
OSNAME=`uname`
ARCH=`uname -m`

#---------/root/install----------
if  [ ! -d "/root/install" ]; then
        mkdir /root/install
fi
#---------OS Linux-------------
if  [ "$OSNAME" == "Linux" ]; then
    echo $OSNAME
#------CentOS)---------------
    if  [ -r "/etc/redhat-release" ]; then
        OSVER=`cat /etc/redhat-release| cut -d " " -f 1`
        OSVERNUM=`egrep -o '[0-9]+\.[0-9]+' /etc/redhat-release`
    fi
#--------Debian--------------------
	if [[ $(cat /etc/*release|grep -i "NAME="|grep -i debian) ]]; then
  		OSVER="debian"
  		OSVERNUM=$(cat /etc/debian_version)
	fi
#------Ubuntu-------------------------------
	if [[ $(cat /etc/*release|grep -i "NAME="|grep -i ubuntu) ]]; then
  		OSVER="Ubuntu"
  		OSVERNUM=`cat /etc/issue.net|awk '{print $2,$3}'`
	fi
fi

soft() {
    cpuburn_f() {
        if [ ! -f /usr/*bin/cpuburn ]; then
            cd /root/install/
            wget https://cdn.pmylund.com/files/tools/cpuburn/linux/cpuburn-1.0-amd64.tar.gz && tar -xvf cpuburn-1.0-amd64.tar.gz && mv cpuburn/cpuburn /usr/sbin/
        fi
                }
    case $OSVER in
        CentOS )
		OSVERNUMTOP=`echo $OSVERNUM|cut -f1 -d"."`
            centos_install() {
                yum -y install epel-release
                yum -y install htop atop wget smartmontools nc vim pciutils dmidecode nano
                }
            case $OSVERNUMTOP in
                        6 )
                        centos_install
                        yum -y install memtester tar
                        cpuburn_f
                        ;;

                        7 )
                        centos_install
                        cpuburn_f
                        if  [ ! -f /usr/*bin/memtester ]; then
                            yum -y install http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el7/en/x86_64/rpmforge/RPMS/memtester-4.2.0-1.el7.rf.x86_64.rpm
                        fi
                        ;;
             esac
             ;;
        debian )
        echo "debian soft install"
        OSVERNUMTOP=`echo $OSVERNUM|cut -f1 -d"."`
            debian_install() {
                apt-get update
                apt-get -y install smartmontools vim htop memtester ethtool pciutils dmidecode psmisc
                }
            case $OSVERNUMTOP in
                        7 )
                        debian_install
                        cpuburn_f
                        ;;

                        8 )
                        debian_install
                        cpuburn_f
                        ;;

                        9 )
                        debian_install
                        cpuburn_f
                        ;;
            esac
            ;;
        Ubuntu )
        OSVERNUMTOP=`echo $OSVERNUM|cut -f1 -d"."`
            ubuntu_install() {
                apt-get update
                apt-get -y install smartmontools vim htop memtester ethtool pciutils dmidecode psmisc
                }
            case $OSVERNUMTOP in
                        14 )
                        ubuntu_install
                        cpuburn_f
                        ;;

                        16 )
                        ubuntu_install
                        cpuburn_f
                        ;;

                        *)
                        echo "I don't know this Ubuntu version but I don't care"
                        ubuntu_install
                        cpuburn_f
                        ;;
            esac
            ;;
    esac
}

chkmemory() {
    case $OSVER in
        CentOS | debian | Ubuntu )
#-------------autostart_Memtester---------------------------------------------------------------------------------------------------------------------------------------------
            rm -rf /root/install/mem*.log
            let memtotal=$(grep -ri memtotal /proc/meminfo|awk '{print $2}')
                if [[ $memtotal -lt 17000000 ]]; then
                    ram=1-16 ; echo "ram: $ram"
                    free=512 ; echo "free: $free"
                elif [[ $memtotal -ge 17000000 && $memtotal -lt 70000000 ]]; then
                    ram=17-64 ; echo "ram: $ram"
                    free=540 ; echo "free: $free"
                elif [[ $memtotal -ge 70000000 && $memtotal -lt 135000000 ]]; then
                    ram=65-128 ; echo "ram $ram"
                    free=800 ; echo "free is $free"
                elif [[ $memtotal -ge 135000000 && $memtotal -lt 530000000 ]]; then
                    ram=129-512 ; echo "ram $ram"
                    free=1500 ; echo "free is $free"
#-------------------------------------------------------
                else
                    echo "There is more then 512Gb RAM, not tested yet. Run test mannually"
                fi
#-----------start mem_t function-----------------#
            mem_t() {
                for (( i=1;; i++ )); do
                    let memfree=`grep -ri MemFree /proc/meminfo | awk '{print $2}'`/1024
                        if [[ "$memfree" -gt "17000" ]]; then
                            echo "There is still more then 16Gb free RAM, starting cycle "$i", Free memory: "$memfree" Mb, Run memtester #$i"
                            memtester 16000 1 > /root/install/memtest$i.log 2>&1 &
                            sleep 5
                        else
                            echo "There is less then 17GB RAM"
                            let chkmem=`grep -ri MemFree /proc/meminfo | awk '{print $2}'`/1024-$free
                            memtester $chkmem 1 > /root/install/memtest$i.log 2>&1 &
                            sleep 6
                            let memfree=`grep -ri MemFree /proc/meminfo | awk '{print $2}'`/1024
                            echo "==================== memtester has started. You have FreeRAM: $memfree Mb =================="
                            break
                        fi
                done
            }
#-----------end mem_t function-----------------#
        case $ram in
            1-16 )
                echo "There is less then 17GB RAM"
                mem_t
                echo "free is $free"
                echo "ram $ram"
            ;;
            17-64 )
                echo "There is more then 17GB RAM and less then 65GB"
                mem_t
                echo "free is $free"
                echo "ram $ram"
            ;;
            65-128 )
                echo "There is more then 64GB RAM and less then 129GB"
                mem_t
                echo "free is $free"
                echo "ram $ram"
            ;;
            129-512 )
                echo "There is more then 129GB RAM and less then 513GB"
		let memfree=`grep -ri MemFree /proc/meminfo | awk '{print $2}'`/1024
                if [[ $memfree -ge 498000 ]]; then
                    for i in `seq 1 31`; do (memtester 16000 1 >> /root/install/mem$i.log 2>>/root/install/mem$i.log &); done
                    sleep 10
                    mem_t
                else
                    mem_t
                fi
            ;;
            * )
                echo "There is more then 512Gb RAM, not tested yet. Run test mannually"
            ;;
        esac
#-------------autostart_Memtester---------------------------------------------------------------------------------------------------------------------------------------------
        ;;
    esac
}

chkcpu() {
    case $OSVER in
        CentOS )
            cpuburn 2>&1 > /dev/null&
        ;;
        debian)
            cpuburn 2>&1 > /dev/null&
        ;;
        Ubuntu)
            cpuburn 2>&1 > /dev/null&
        ;;
    esac
}
############Serial_number############
smart_serial () {
if [[ -z $(lspci|grep "RAID bus controller") && -z $(fdisk -l 2>/dev/null|grep /dev/nvme) ]]; then
  echo "====== No raid controller detected ======"
  raidcard=NoRaid
elif [[ `lspci|grep -i "RAID bus controller" |wc -l` -eq 1 ]]; then
  if [[ -n `lspci|grep -i "RAID bus controller"|grep "MegaRAID"` ]]; then
    echo "====== MegaRAID raid controller detected ======"
    raidcard=MegaRAID
  elif [[ -n `lspci|grep -i "RAID bus controller"|grep "Hewlett-Packard"` ]]; then
    echo "====== Hewlett-Packard raid controller detected ======"
    raidcard=Hewlett-Packard
  elif [[ -n $(fdisk -l 2>/dev/null|grep /dev/nvme) ]]; then
    echo "====== NVME detected ======"
    raidcard=MVME
  fi
elif [[ `lspci|grep -i "RAID bus controller" |wc -l` -ge 2 ]]; then
  echo "====== 2 or more raid controllers detected ======"
  few=fuck_off
fi
############################
case "$raidcard" in
    NoRaid )
      for i in a b;do smartctl -a /dev/sd$i | egrep -i 'Serial Number'>/dev/null; done;
      if [[ $? -eq 0 ]]; then
        for i in a b c d ; do echo /dev/sd$i;smartctl -a /dev/sd$i | egrep -i 'Serial Number';done
      fi
    ;;
    MegaRAID )
      for i in `seq 0 1` ; do smartctl -a -d megaraid,$i /dev/sg0| egrep -i 'Serial Number' >/dev/null; done;
      if [[ $? -eq 0 ]]; then
        for i in `seq 0 3` ; do smartctl -a -d megaraid,$i /dev/sg0|grep -i "Serial N"; done;
      fi
    ;;
    Hewlett-Packard )
      for i in `seq 0 1` ; do smartctl -d cciss,$i -a /dev/sg0| egrep -i 'Serial Number' >/dev/null ; done
      if [[ $? -eq 0 ]]; then
        for i in `seq 0 11` ; do smartctl -d cciss,$i -a /dev/sg0 | egrep -i 'Serial N'; done
      else
        for i in `seq 0 1` ; do smartctl -a -d sat+cciss,$i /dev/cciss/c0d0 | egrep -i 'Serial N' >/dev/null; done
        if [[ $? -eq 0 ]]; then
          for i in `seq 0 11` ; do smartctl -a -d sat+cciss,$i /dev/cciss/c0d0 | egrep -i 'Serial N'; done
        fi
      fi
    ;;
    * )
    echo "there is not this raid controller in my database"
    $(lspci|grep "RAID bus controller")
    ;;
esac
##############################
#[root@lcimre127 ~]# lspci|grep -i raid
#07:00.0 RAID bus controller: Adaptec AAC-RAID (rev 09)
#for i in 0 1 2 3 4 5 6 ; do smartctl -d sat,0 -a /dev/sg$i|grep "Serial N" ; done
#############################
}
############Serial_number############

#------------------SMART-------------------------------#
smart_test_no_raid() {
  if [[ "-z $(lspci|grep "RAID bus controller")" && "-z $(fdisk -l 2>/dev/null|grep /dev/nvme)" ]]; then
    if [[ $(fdisk -l 2>/dev/null| grep -i dev |egrep -v "(/dev/[brm])"| awk '/:/ {print $2}'| cut -f 1 -d ":"|wc -l) -ge 2 ]];then
      disk=$(fdisk -l 2>/dev/null| grep -i dev |egrep -v "(/dev/[brm])"| awk '/:/ {print $2}'| cut -f 1 -d ":")
      for i in $disk; do echo ===$i===; smartctl -a $i|egrep '^(Self-test|Serial|Device M|  (5|8|9)|196|197|User|# (1|2))|result|remaining|defect';done
      for i in $disk; do (echo ===$i===; smartctl -t long $i>>$MYPATH/result.txt);smartstatus=$?;done
        if [[ "$smartstatus" -ne 0 ]]; then
          smartt="Please, run SMART test mannualy"
        else
          smartt="SMART testing has begun, please check"
        fi
    else
      smartt="Please, run SMART test mannualy"
    fi
  else
      smartt="Please, run SMART test mannualy"
  fi
}
#------------------------------------------------------#



hwinfo() {
    case $OSVER in
        CentOS | debian| Ubuntu)
                #IFACES=`ip link show|egrep "(eth[0-9]*:|enp[0-9]*s[0-9]*:|enp[0-9][a-z][0-9][a-z][0-9]*:|em[0-9]*:|eno[0-9]*:)"|grep "state UP"|awk '{print $2}'|cut -f1,2 -d":"`
		IFACES=`ip link show|grep "state UP"|awk '{print $2}'|cut -f1,2 -d":"`
        let memtotalGB=`head -n1 /proc/meminfo | awk '{print $2}'`/1024/1024
        let memtotalMB=`head -n1 /proc/meminfo | awk '{print $2}'`/1024
        let memtotalKB=`head -n1 /proc/meminfo | awk '{print $2}'`
echo "
------------OS-----------
OS: $OSVER $OSVERNUM $ARCH
---------Hardware--------
CPU:`grep "model name" /proc/cpuinfo | head -n1 | cut -f 2 -d ":"| sed 's/ \{1,\}/ /g'`
CPU count: `cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l`
Cores per 1 CPU: `cat /proc/cpuinfo|grep 'cpu cores' | sed 's|.* ||'|head -n1`
Threads: `cat /proc/cpuinfo |grep processor|wc -l`
RAM: "$memtotalKB"Kb / "$memtotalMB"Mb / ~"$memtotalGB"Gb
---
Disc count: `fdisk -l 2>/dev/null|egrep "* /dev/[^bmr]"|wc -l`
`fdisk -l 2>/dev/null| egrep "* /dev/[^bmr]"|awk '{print $1,$2,$3,$4}'`
---
Ethernet: `ip a|grep inet|egrep -vi "(127.0.0|::|tun)"|awk '{print $2}'|cut -d "/" -f 1|xargs -n 6`
`for i in $IFACES; do echo $i; ethtool $i| grep Speed; done`
lspci:
`lspci | egrep -i "ata|scsi|sas|raid|eth"`
------------------------"
                ;;
    esac
}

soft
chkmemory
chkcpu
hwinfo
smart_serial
smart_test_no_raid

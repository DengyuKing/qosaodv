#/usr/bin/ns -f 
 #====================================================================================
#           AODV over 802.15.4            #
#     Copyright (c) 2003 Samsung/CUNY     #
# - - - - - - - - - - - - - - - - - - - - #
#       Prepared by Jianliang Zheng       #
#        (zheng@ee.ccny.cuny.edu)         #
#====================================================================================

#====================================================================================
# File Name:   802_15_4_aodv.tcl
# Purpose:     Simulation for zigbee Wireless Network using AODV Protocol
# Version:     1.0
# Date:        Aug. 25th 2009
# Author:      Jianliang Zheng
# Modified by: Hou Meng
# Affiliation: Beijing University of Posts & Telecommunications
#====================================================================================

# ===================================================================================
# Define options
# ===================================================================================
set val(chan)           Channel/WirelessChannel    ;# Channel Type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy/802_15_4   ;# network interface type
set val(mac)            Mac/802_15_4               ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
#set val(nn)             25                         ;# number of mobilenodes
set val(rp)             AODV                       ;# routing protocol
set val(x)              50                        ;# X dimension of the topography
set val(y)              50                         ;# Y dimension of the topography

set val(nam)            zigbee_aodv.nam            ;# nam file
set val(traffic)        cbr                        ;# application object: cbr/poisson/ftp
set val(energy)		EnergyModel
set val(init)		1000.0
set val(txPower)	10.0
set val(rxPower)	3.0
set val(idlePower)	1.0;

#read command line arguments
#proc getCmdArgu {argc argv} {
        
        
                set val(nn) [lindex $argv 0]
		set scen [lindex $argv 1]
		set stopTime [lindex $argv 2]
                set tr [lindex $argv 3] 
		puts "$val(nn)"                
                puts "$scen"                
		puts "$stopTime"	
        	puts "$tr"
#}

#getCmdArgu $argc $argv

set appTime1            0.0 ;# in seconds
set appTime2            0.3 ;# in seconds
set appTime3            0.7 ;# in seconds
#set stopTime            100 ;# in seconds
 
#====================================================================================
# Main Program
#====================================================================================
#
# Initialize Simulation
#

# set up simulator object
set ns_ [new Simulator]

# set up trace file
set tracefd [open $tr w]
$ns_ trace-all $tracefd

# set up animation demo
if { "$val(nam)" == "zigbee_aodv.nam"  } {
        set namtrace     [open ./$val(nam) w]
        $ns_ namtrace-all-wireless $namtrace $val(x) $val(y)
}

$ns_ puts-nam-traceall {# nam4wpan #}  ;# inform nam that this is a trace file for wpan (special handling needed)
Mac/802_15_4 wpanNam namStatus on      ;# default = off (should be turned on before other 'wpanNam' commands can work)
#Mac/802_15_4 wpanNam ColFlashClr gold ;# default = gold
#Mac/802_15_4 wpanNam NodeFailClr grey ;# default = grey

# set up topography object
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# create God
set god_ [create-god $val(nn)]

# set up radio propogation model
# for model 'TwoRayGround'
set dist(5m)  7.69113e-06
set dist(9m)  2.37381e-06
set dist(10m) 1.92278e-06
set dist(11m) 1.58908e-06
set dist(12m) 1.33527e-06
set dist(13m) 1.13774e-06
set dist(14m) 9.81011e-07
set dist(15m) 8.54570e-07
set dist(16m) 7.51087e-07
set dist(20m) 4.80696e-07
set dist(25m) 3.07645e-07
set dist(30m) 2.13643e-07
set dist(35m) 1.56962e-07
set dist(40m) 1.20174e-07

Phy/WirelessPhy set CSThresh_ $dist(15m) ;# set up carrier sense threshold
Phy/WirelessPhy set RXThresh_ $dist(15m) ;# set up receive power threshold

set chan_1 [new $val(chan)]

#
# Set up Node
#

# configure node
$ns_ node-config -adhocRouting $val(rp)\
  -llType $val(ll)\
  -macType $val(mac)\
  -ifqType $val(ifq)\
  -ifqLen $val(ifqlen)\
  -antType $val(ant)\
  -propType $val(prop)\
  -phyType $val(netif)\
  -topoInstance $topo\
  -agentTrace ON\
  -routerTrace OFF\
  -macTrace OFF\
  -movementTrace OFF\
  -energyModel $val(energy)\
  -initialEnergy $val(init)\
  -txPower $val(txPower)\
  -rxPower $val(rxPower)\
  -idlePower $val(idlePower)\
  -channel $chan_1

# create nodes: node_(0) to node_(nn-1)
for {set i 0} {$i < $val(nn) } {incr i} {
 set node_($i) [$ns_ node] 
# $node_($i) random-motion 0  ;# disable random motion
}

# set up movements for mobile nodes
source $scen

# defines the node size in nam
for {set i 0} {$i < $val(nn)} {incr i} {
 $ns_ initial_node_pos $node_($i) 2
}

#
# Set up Agent and Appliaction
#

# setup traffic flow between nodes
# set up CBR traffic
proc cbrtraffic { src dst interval starttime } {
   global ns_ node_
   # create an Agent/UDP object
   set udp($src) [new Agent/UDP]
   $ns_ attach-agent $node_($src) $udp($src)  ;# bind Agent/UDP object to node_($src)
   set null($dst) [new Agent/Null]
   $ns_ attach-agent $node_($dst) $null($dst) ;# bind null object to node_($src)
   set cbr($src) [new Application/Traffic/CBR]
   $cbr($src) set packetSize_ 70              ;# set packet size, in Byte
   $cbr($src) set interval_ $interval         ;# set transmit interval
   $cbr($src) set random_ 0                   ;# set random transmit interval
   # $cbr($src) set maxpkts_ 10000             ;# set max amount of transmit packets
   $cbr($src) attach-agent $udp($src)        ;# bind App/Traffic/CBR to Agent/UDP
   $ns_ connect $udp($src) $null($dst)        ;# estabilsh connection between two agents
   $ns_ at $starttime "$cbr($src) start"
}

# set up POISSON traffic
proc poissontraffic { src dst interval starttime } {
   global ns_ node_
   set udp($src) [new Agent/UDP]
   $ns_ attach-agent $node_($src) $udp($src)  ;# bind Agent/UDP object to node_($src)
   set null($dst) [new Agent/Null]
   $ns_ attach-agent $node_($dst) $null($dst) ;# bind null object to node_($src)
   set expl($src) [new Application/Traffic/Exponential]
   $expl($src) set packetSize_ 70             ;# set packet size, in Byte
   $expl($src) set burst_time_ 0              ;# burst_time
   $expl($src) set idle_time_
        [expr $interval*1000.0-70.0*8/250]ms    ;# idle_time + pkt_tx_time = interval
   $expl($src) set rate_ 250k                 ;# data transmit rate
   $expl($src) attach-agent $udp($src)       ;# bind App/Traffic/Exponential to Agent/UDP
   $ns_ connect $udp($src) $null($dst)        ;# estabilsh connection between two agents
   $ns_ at $starttime "$expl($src) start"
}

# set up nam animation demo
if { "$val(traffic)" == "cbr" } {
   puts "nTraffic: $val(traffic)"
   #Mac/802_15_4 wpanCmd ack4data on
   puts [format "Acknowledgement for data: %s" [Mac/802_15_4 wpanCmd ack4data]]
   set lowSpeed 0.5ms
   set highSpeed 1.5ms
   Mac/802_15_4 wpanNam PlaybackRate $lowSpeed
   $ns_ at [expr $appTime1+0.1] "Mac/802_15_4 wpanNam PlaybackRate $highSpeed"
   $ns_ at $appTime2 "Mac/802_15_4 wpanNam PlaybackRate $lowSpeed"
   $ns_ at [expr $appTime2+0.1] "Mac/802_15_4 wpanNam PlaybackRate $highSpeed"
   $ns_ at $appTime3 "Mac/802_15_4 wpanNam PlaybackRate $lowSpeed"
   $ns_ at [expr $appTime3+0.1] "Mac/802_15_4 wpanNam PlaybackRate $highSpeed"
   $val(traffic)traffic 5 8 0.2 $appTime1
   $val(traffic)traffic 7 4 0.2 $appTime2
   $val(traffic)traffic 3 2 0.2 $appTime3
   Mac/802_15_4 wpanNam FlowClr -p AODV -c tomato
   Mac/802_15_4 wpanNam FlowClr -p ARP -c green
   if { "$val(traffic)" == "cbr" } {
    set pktType cbr
   } else {
    set pktType exp
   }
   Mac/802_15_4 wpanNam FlowClr -p $pktType -s 5 -d 8 -c blue
   Mac/802_15_4 wpanNam FlowClr -p $pktType -s 7 -d 4 -c green4
   Mac/802_15_4 wpanNam FlowClr -p $pktType -s 3 -d 2 -c cyan4
   $ns_ at $appTime1 "$node_(5) NodeClr blue"
   $ns_ at $appTime1 "$node_(8) NodeClr blue"
   $ns_ at $appTime1 "$ns_ trace-annotate \"(at $appTime1) $val(traffic) traffic from node 5 to node 8\""
   $ns_ at $appTime2 "$node_(7) NodeClr green4"
   $ns_ at $appTime2 "$node_(4) NodeClr green4"
   $ns_ at $appTime2 "$ns_ trace-annotate \"(at $appTime2) $val(traffic) traffic from node 7 to node 4\""
   $ns_ at $appTime3 "$node_(3) NodeClr cyan3"
   $ns_ at $appTime3 "$node_(2) NodeClr cyan3"
   $ns_ at $appTime3 "$ns_ trace-annotate \"(at $appTime3) $val(traffic) traffic from node 3 to node 2\""
}

# set up FTP traffic
proc ftptraffic { src dst starttime } {
   global ns_ node_
   set tcp($src) [new Agent/TCP]                   
   $tcp($src) set packetSize_ 60              ;# set packet size, in Byte
   set sink($dst) [new Agent/TCPSink]
   $ns_ attach-agent $node_($src) $tcp($src)  ;# bind Agent/TCP object to node_($src)
   $ns_ attach-agent $node_($dst) $sink($dst) ;# bind Agent/TCPSink object to node_($dst)
   $ns_ connect $tcp($src) $sink($dst)        ;# estabilsh connection between two agents
   set ftp($src) [new Application/FTP]
   $ftp($src) attach-agent $tcp($src)        ;# bind Application/FTP to Agent/TCP
   $ns_ at $starttime "$ftp($src) start"
}

# set up nam animation demo
if { "$val(traffic)" == "ftp" } {
   puts "nTraffic: ftp"
   #Mac/802_15_4 wpanCmd ack4data off
   puts [format "Acknowledgement for data: %s" [Mac/802_15_4 wpanCmd ack4data]]
   set lowSpeed 0.20ms
   set highSpeed 1.5ms
   Mac/802_15_4 wpanNam PlaybackRate $lowSpeed
   $ns_ at [expr $appTime1+0.2] "Mac/802_15_4 wpanNam PlaybackRate $highSpeed"
   $ns_ at $appTime2 "Mac/802_15_4 wpanNam PlaybackRate $lowSpeed"
   $ns_ at [expr $appTime2+0.2] "Mac/802_15_4 wpanNam PlaybackRate $highSpeed"
   $ns_ at $appTime3 "Mac/802_15_4 wpanNam PlaybackRate $lowSpeed"
   $ns_ at [expr $appTime3+0.2] "Mac/802_15_4 wpanNam PlaybackRate 1ms"
   ftptraffic 19 6 $appTime1
   ftptraffic 10 4 $appTime2
   ftptraffic 3 2 $appTime3
   Mac/802_15_4 wpanNam FlowClr -p AODV -c tomato
   Mac/802_15_4 wpanNam FlowClr -p ARP -c green
   Mac/802_15_4 wpanNam FlowClr -p tcp -s 19 -d 6 -c blue
   Mac/802_15_4 wpanNam FlowClr -p ack -s 6 -d 19 -c blue
   Mac/802_15_4 wpanNam FlowClr -p tcp -s 10 -d 4 -c green4
   Mac/802_15_4 wpanNam FlowClr -p ack -s 4 -d 10 -c green4
   Mac/802_15_4 wpanNam FlowClr -p tcp -s 3 -d 2 -c cyan4
   Mac/802_15_4 wpanNam FlowClr -p ack -s 2 -d 3 -c cyan4
   $ns_ at $appTime1 "$node_(19) NodeClr blue"
   $ns_ at $appTime1 "$node_(6) NodeClr blue"
   $ns_ at $appTime1 "$ns_ trace-annotate \" (at $appTime1) ftp traffic from node 19 to node 6\""
   $ns_ at $appTime2 "$node_(10) NodeClr green4"
   $ns_ at $appTime2 "$node_(4) NodeClr green4"
   $ns_ at $appTime2 "$ns_ trace-annotate \" (at $appTime2) ftp traffic from node 10 to node 4\""
   $ns_ at $appTime3 "$node_(3) NodeClr cyan3"
   $ns_ at $appTime3 "$node_(2) NodeClr cyan3"
   $ns_ at $appTime3 "$ns_ trace-annotate \" (at $appTime3) ftp traffic from node 3 to node 2\""
}


#
# Finish the Simulation
#

# tell nodes when the simulation ends
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at $stopTime "$node_($i) reset";
}

# call "stop" process at 15.0s
$ns_ at $stopTime "stop"
$ns_ at $stopTime "puts \"nNS EXITING...\""
$ns_ at $stopTime "$ns_ halt"

# define "stop" process
proc stop {} {
    global ns_ tracefd val env
    $ns_ flush-trace
    close $tracefd
    set hasDISPLAY 0
    foreach index [array names env] {
        #puts "$index: $env($index)"
        if { ("$index" == "DISPLAY") && ("$env($index)" != "") } {
                set hasDISPLAY 1
        }
    }
    if { ("$val(nam)" == "wpan_demo1.nam") && ("$hasDISPLAY" == "1") } {
     exec nam wpan_demo1.nam &
    }
}

puts "nStarting Simulation..."

#
# Run Simulation
#

$ns_ run

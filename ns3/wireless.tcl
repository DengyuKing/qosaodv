#Copyright (c) 1997 Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by the Computer Systems
#      Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Header: /cvsroot/nsnam/ns-2/tcl/ex/wireless.tcl,v 1.8 2002/12/23 19:16:30 difa Exp $
#
# Ported from CMU/Monarch's code, nov'98 -Padma.

# ======================================================================
# Default Script Options
# ======================================================================
set val(chan)		Channel/WirelessChannel
set val(prop)		Propagation/TwoRayGround
#set val(netif)		NetIf/SharedMedia
set val(netif)		Phy/WirelessPhy
set val(mac)		Mac/802_11
#set val(mac)		Mac/802_15_4
#set val(ifq)		Queue/DropTail/PriQueue	;# for dsdv
set val(ifq)		Queue/DropTail/PriQueue	;# for dsr
set val(ll)		LL
set val(ant)            Antenna/OmniAntenna

set val(x)		1000		;# X dimension of the topography
set val(y)		1000		;# Y dimension of the topography
#set val(cp)		"../mobility/scene/cbr-50-10-4-512"
#set val(sc)		"../mobility/scene/scen-670x670-50-600-20-0"

set val(ifqlen)		50		;# max packet in ifq
#set val(nn)		20		;# number of nodes
#set val(seed)		0.0
#set val(stop)		1000.0		;# simulation time
#set val(tr)		out.tr		;# trace file
set val(rp)             AODV		;# routing protocol script (dsr or dsdv)
#set val(lm)             "off"		;# log movement
set val(energy)		EnergyModel
set val(initeng)	100
set val(txPower)	0.660
set val(rxPower)	0.395
set val(idlePower)	0.035
set appTime1            0.0 ;# in seconds
set appTime2            0.3 ;# in seconds
set appTime3            0.7 ;# in seconds
set resetime		280 ;
# ======================================================================

#set AgentTrace			ON
#set RouterTrace			ON
#set MacTrace			OFF

set val(nn) [lindex $argv 0]
set scen [lindex $argv 1]
set stopTime [lindex $argv 2]
set tr [lindex $argv 3]
set trace_c [lindex $argv 4]
set str_c [lindex $argv 5] 
puts "$val(nn)"                
puts "$scen"                
puts "$stopTime"	
puts "$tr"
puts "$trace_c"
puts "$str_c"




set ns_	[new Simulator]
set aodv [new Agent/AODV]
Agent/AODV set tcl_trust $trace_c
Agent/AODV set tcl_energy $str_c
set tracefd	[open $tr w]

$ns_ trace-all $tracefd

set namtracefd	[open AODV.nam w]

$ns_ namtrace-all-wireless $namtracefd $val(x) $val(y)

proc finish {} {
	global ns_ tracefd namtracefd
	$ns_ flush-trace
	close $tracefd
	close $namtracefd
	#exec nam AODV.nam &
	exit 0
}

set topo [new Topography]

$topo load_flatgrid $val(x) $val(y)

#Mac/802_15_4 wpanNam namStatus on

set god_ [create-god $val(nn)]
$ns_ node-config -adhocRouting $val(rp)\
	-llType $val(ll)\
	-macType $val(mac)\
	-ifqType $val(ifq)\
	-ifqLen  $val(ifqlen)\
	-antType $val(ant)\
	-propType $val(prop)\
	-phyType $val(netif)\
	-channelType $val(chan)\
	-topoInstance $topo\
	-agentTrace ON\
	-routerTrace ON\
	-macTrace OFF\
	-energyModel $val(energy)\
	-initialEnergy $val(initeng)\
	-txPower $val(txPower)\
	-rxPower $val(rxPower)\
	-idlePower $val(idlePower)\
	-movementTrace OFF



for {set i 0} {$i<$val(nn)} {incr i} {
	set node_($i) [$ns_ node]
       #	$node_($i)random-motion 0;
}

#Mac/802_15_4 wpanNam FlowClr -p AODV -c blue
source $scen
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
   cbrtraffic 5 8 1 $appTime1
   cbrtraffic 7 4 1 $appTime2
   cbrtraffic 3 2 1 $appTime3


for {set i 0} {$i<$val(nn)} {incr i} {
	$ns_ at $resetime  "$node_($i) reset";
}

$ns_ at $stopTime  "finish"

$ns_ run






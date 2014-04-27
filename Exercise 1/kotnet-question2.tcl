#Create simulator
set ns [new Simulator]

$ns color 0 Blue
$ns color 1 Red

#
# Constants
#
set qt DropTail

#trace file
set tf [open kotnet-question2.out.tr w]
$ns trace-all $tf

#nam tracefile
set nf [open kotnet-question2.out.nam w]
$ns namtrace-all $nf

proc finish {} {
	#finalize trace files
	global ns nf tf
	$ns flush-trace
	close $tf
	close $nf
	
	exec nam kotnet-question2.out.nam &
	exit 0
}

#
# create nodes
#

# Kotnet end-user: uploader
set n0 [$ns node]
# Kotnet end-user: downloader
set n1 [$ns node]
# Kotnet router/switch
set n2 [$ns node]
# Kotnet end of modem
set n3 [$ns node]
# Internet end of modem
set n4 [$ns node]
# Virtual node for CATV cable segment
set n5 [$ns node] 
# Download server
set n6 [$ns node] 
# Upload server
set n7 [$ns node] 

# 
# Set-up of links
#

# Modem internal links

# Upload link
$ns simplex-link $n3 $n4 256Kb 0.2ms $qt
# Download link
$ns simplex-link $n4 $n3 4Mb 0.2ms $qt

# LAN links
$ns duplex-link $n0 $n2 10Mb 0.2ms $qt
$ns duplex-link $n1 $n2 10Mb 0.2ms $qt

# Router connection to modem
$ns duplex-link $n2 $n3 10Mb 0.2ms $qt

# CATV cable segment
$ns duplex-link $n4 $n5 100Mb 0.3ms $qt

# Links to download and upload servers
$ns duplex-link $n5 $n6 100Mb 0.3ms $qt
$ns duplex-link $n5 $n7 100Mb 0.3ms $qt

#
# Set-up of connections
#
set tcp [new Agent/TCP]
$ns attach-agent $n6 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n1 $sink
$ns connect $tcp $sink
$tcp set fid_ 0
$tcp set window_ 80

set udp [new Agent/UDP]
$ns attach-agent $n0 $udp
set null [new Agent/Null]
$ns attach-agent $n7 $null
$ns connect $udp $null
$udp set fid_ 1

#
# Set-up of applications
#
set ftp [new Application/FTP]
$ftp attach-agent $tcp

set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set packetSize_ 1500
$cbr set random_ false

#
# Simulation activities
#

$ns at 0.1 "$ftp start"
$ns at 3.0 "$cbr start"

$ns at 6.0 "$cbr stop"
$ns at 9.9 "$ftp stop"

$ns at 10.0 "finish"

$ns run

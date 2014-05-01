# --------------------------------------------------------- #
# Maarten Tegelaers                                         #
# Computer Networks: Transport-layer practicum              #
# Exercise 1: Bandwidth restrictions on KotNet              #
# --------------------------------------------------------- #

# --------------------------------------------------------- #
#  Setup: Simulator                                         #
# --------------------------------------------------------- #
#Create simulator
set ns [new Simulator]

#trace files: nam and tr
set tf [open exercise1.out.tr w]
$ns trace-all $tf

set nf [open exercise1.out.nam w]
$ns namtrace-all $nf

# Finish Procedure: flushes all simulator data to file.
proc finish {} {
   #finalize trace files
   global ns nf tf
   $ns flush-trace
   close $tf
   close $nf
   
   #call nam visualizer
   exec nam exampla.out.nam &
   exit 0  
}

# --------------------------------------------------------- #
#  Setup: Variables                                         #
# --------------------------------------------------------- #
set fidCounter 0
set tailTypeUser DropTail
set tailTypeModem DropTail

# --------------------------------------------------------- #
#  Setup: Procedures                                        #
# --------------------------------------------------------- #
# Initialize a CBR connection with the specified parameters.
proc initCBR{sourceNode  destinationNode 
             sourceAgent destinationAgent
             cbrApp packetSize} {
   global ns fidCounter
             
   # setup udp
   $ns attach-agent $sourceNode $sourceAgent
   $ns attach-agent $destinationNode  $destinationAgent
   $ns connect $sourceAgent $destinationAgent
   
   $sourceAgent set fid_ $fidCounter
   incr fidCounter
   
   # setup cbr
   $cbrApp attach-agent $sourceAgent
   $cbrApp set packetSize_ $packetSize
   $cbrApp set random_ false
}

proc constructCBR{sourceNode destinationNode packetSize} {
   array set cbr {}
   set cbr(source) [new Agent/UDP]
   set cbr(sink) [new Agent/Null]
   set cbr(app) [new Application/Traffic/CBR]
   
   initCBR $sourceNode $destinationNode $cbr(source) $cbr(sink) $cbr(app) $packetSize
   
   return $cbr
}

# --------------------------------------------------------- #
# Initialize a FTP connection with the specified parameters.
proc initFTP{sourceNode destinationNode
             sourceAgent destinationAgent
             windowSize ftpApp} {
   global ns fidCounter
   
   # setup tcp
   $ns attach-agent $sourceNode $sourceAgent
   $ns attach-agent $destinationNode $destinationAgent
   $ns connect $sourceAgent $destinationAgent
            
   $sourceAgent set fid_ $fidCounter
   incr fidCounter
   
   $sourceAgent set window_ $windowSize
   
   # setup ftp
   $ftpApp attach-agent $sourceAgent 
}

proc constructFTP{soureNode destinationNode
                  packetSize windowSize} {
   array set ftp {}
   set ftp(source) [new Agent/TCP]
   set ftp(sink) [new Agent/TCPSink]
   set ftp(app) [new Application/FTP]
   
   initFTP $sourceNode $destinationNode $ftp(source) $ftp(sink) $packetSize $windowSize $ftp(app)
   
   return $ftp           
}

proc initUser {modemNode bandwidth propDelay tailType} {
   global ns
   array set userNodes {}
   
   # Create nodes
   set userNodes(n0) [$ns node]
   set userNodes(n1) [$ns node]
   set userNodes(n2) [$ns node]
   # Create links
   $ns duplex-link $userNodes(n0) $userNodes(n2) $bandwidth $propDelay $tailType
   $ns duplex-link $userNodes(n1) $userNodes(n2) $bandwidth $propDelay $tailType
   $ns duplex-link $userNodes(n2) $modemNode $bandwidth $propDelay $tailType
   
   return $userNodes
}

# --------------------------------------------------------- #
# Create simulation
# --------------------------------------------------------- #
# modem
set n3 [$ns node]
set n4 [$ns node]

$ns simplex-link $n3 $n4 256Kb 0.2ms $tailTypeModem
$ns simplex-link $n4 $n3 4.0Mb 0.2ms $tailTypeModem

# other nodes
set user [initUser $n3 10.0Mb 0.2ms DropTail]
set server [initUser $n4 100.0Mb 0.3ms DropTail]

# applications
set tcp [constructFTP $user(n1) $server(n1) 80]
set cbr [constructCBR $user(n0) $server(n0) 1500]

# Schedule events here
# -----------------------------------------------------------
$ns at 0.1 "$ftp(app) start"
$ns at 9.9 "$ftp(app) stop"

$ns at 3.0 "$cbr(app) start"
$ns at 6.0 "$cbr(app) stop"

# Execute Simulator
# -----------------------------------------------------------
$ns run
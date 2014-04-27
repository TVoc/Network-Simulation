#Create simulator
set ns [new Simulator]

$ns color 0 Red
$ns color 1 Blue

#trace file
set tf [open ex2.out.tr w]
$ns trace-all $tf

#nam tracefile
set nf [open ex2.out.nam w]
$ns namtrace-all $nf

#log HTTP request file sizes
set sizelog [open sizelog w]

#log congestion window and slow start threshold of main FTP connection
set wndlog [open wndlog w]

# === Initialise random variables ===

#start RNG streams
set rep 1
set rng1 [new RNG]
set rng2 [new RNG]

# for {set i 0} {$i < $rep} {incr i} {
# 	$rng1 next-substream;
#	$rng2 next-substream;
# }

#start time generator
set timegen [new RandomVariable/Exponential]
$timegen use-rng $rng1
$timegen set avg_ 0.05

#start filesize generator
set sizegen [new RandomVariable/Pareto]
$sizegen use-rng $rng2
$sizegen set avg_ 150000
$sizegen set shape_ 1.5

# configure the burst parameters
set starttime1 5.0
set starttime2 10.0
set starttime3 15.0
set fileAmount 40

proc finish {} {
	#finalize trace files
	global ns nf tf sizelog wndlog
	$ns flush-trace
	close $tf
	close $nf

	#also close additional log files
	close $sizelog
	close $wndlog
	
	exec nam ex2.out.nam &
	exit 0
}

# === Connection between LAN and Internet ===
set lanend [$ns node]
set inetend [$ns node]

# === LAN nodes ===
#FTP client
set ftpclient [$ns node]

#Web client
set webclient [$ns node]

# === Nodes in the Internet ===
#FTP server
set ftpserver [$ns node]

#Web server
set webserver [$ns node]

# === Set links ===
#Connect LAN-end node and Internet-end node
$ns duplex-link $lanend $inetend 10Mb 10ms DropTail
$ns queue-limit $lanend $inetend 20
#Connect LAN
$ns duplex-link $ftpclient $lanend 10Mb 10ms DropTail
$ns duplex-link $webclient $lanend 10Mb 10ms DropTail
#Connect the Internet
$ns duplex-link $inetend $ftpserver 10Mb 10ms DropTail
$ns duplex-link $inetend $webserver 10Mb 10ms DropTail

# === Initialise continuous FTP connection ===
set ftpagent [new Agent/TCP]
$ns attach-agent $ftpserver $ftpagent
$ftpagent set window_ 80
$ftpagent set fid_ 0
set ftpsink [new Agent/TCPSink]
$ns attach-agent $ftpclient $ftpsink
$ns connect $ftpagent $ftpsink
set ftp [new Application/FTP]
$ftp attach-agent $ftpagent

# === Initialise HTTP requests ===

# Global counter for the number of HTTP requests
set httpCounter 1


# === Procedure for request bursts as specified in the assignment ===
# parameter: starttime
#	The start time of the first request
# parameter: amount
#	The amount of requests to generate
# effect: Initialise amount TCP connections between the web server
# and web client defined above, with start times starting from
# starttime and increasing from there according to the exponential
# RNG. File sizes are generated from the Pareto RNG. Log the start time
# and file size in the corresponding log file.
proc makeBurst {starttime amount} {
	global ns httpCounter sizegen timegen webclient webserver sizelog
	set next $starttime
	for {set i 0} {$i < $amount} {incr i} {
		set filesize [expr [$sizegen value]]
		# Initialise connection
		set reqAgents($httpCounter) [new Agent/TCP]
		$reqAgents($httpCounter) set fid_ $httpCounter
		$reqAgents($httpCounter) set size_ $filesize
		$ns attach-agent $webserver $reqAgents($httpCounter)
		set reqSinks($httpCounter) [new Agent/TCPSink]
		$ns attach-agent $webclient $reqSinks($httpCounter)
		$ns connect $reqAgents($httpCounter) $reqSinks($httpCounter)
		set requests($httpCounter) [new Application/FTP]
		$requests($httpCounter) attach-agent $reqAgents($httpCounter)
		puts $sizelog "$httpCounter $next $filesize"  
		$ns at $next "$requests($httpCounter) send $filesize"
		set next [expr $next + [$timegen value] ]
		incr httpCounter
	}
}

# === Run the simulation ===

# start the continuous FTP connection
$ns at 0.1 "$ftp start"

# program the bursts
$ns at 5.0 "makeBurst $starttime1 $fileAmount"
$ns at 10.0 "makeBurst $starttime2 $fileAmount"
$ns at 15.0 "makeBurst $starttime3 $fileAmount"

# log the congestion window and slow start threshold of the specified
# TCP source in the window/threshold log
# parameter: tcpSource
#	The identifier (integer) of the TCP source of interest
# parameter: fileHandle
#	The file to write to
proc plotWindow {tcpSource fileHandle} {
	global ns
	set time 0.1
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]
	set ssthresh [$tcpSource set ssthresh_]
	puts $fileHandle "$now $cwnd $ssthresh"
	$ns at [expr $now+$time] "plotWindow $tcpSource $fileHandle"
}

# make sure the congestion window and slow start threshold are logged
$ns at 0.1 "plotWindow $ftpagent $wndlog"

# finish up
$ns at 30.0 "finish"

# here be dragons
$ns run

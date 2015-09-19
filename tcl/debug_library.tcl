package provide debug_library 1.0;

proc sdblib {} {
    source c:/mwi_tools/misc/tcl_lib/debug_library.tcl;
}

proc wvar {variable {stall {}}} {
    wdebug "Variable $variable = [uplevel set $variable]";
    if {$stall != {}} {
	wdebug "Hit return to continue";
	gets stdin;
    }
}

proc wdebug {stringin} {
    if {[info exists ::debug]} {
	puts $stringin;
    }
}

proc list_procs {} {
    foreach name [lsort [info procs]] {echo $name}
}


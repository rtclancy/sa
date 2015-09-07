package require http 2.4
package provide stock_app 1.0;
lappend auto_path c:/mwi_tools/misc/tcl_lib
package require debug_library

set minus_days 1;

set ::sheight [expr 768 * .80]

proc show_stock_commands {} {
    exec cat stock.tcl | grep ^proc;
}


lappend auto_path .

proc remove_duplicates {inlist} {
    set outlist {};
    foreach inlistitem $inlist {
	set compareitem [string tolower $inlistitem];
	if {![regexp $compareitem $outlist]} {lappend outlist $compareitem};
    }
    return $outlist;
}

proc get_xcoord {value} {
    upvar xscale xscale;
    return [expr $value * $xscale];
}

proc get_ycoord {value} {
#    if {[info exists ::debug]} {puts "entering get_ycoord"};
    upvar yscale yscale;
    upvar sheight sheight;
    upvar ymin ymin;
#    if {[info exists ::debug]} {puts "exiting get_ycoord"};
    return [expr $sheight - ($value - $ymin) * $yscale];
}

proc purge_line {stock_list} {
    foreach stock $stock_list {
	set fptrin [open ../data_tmp/$stock.dat r];
	set fptrout [open ../historical_data/$stock.dat w];
	set infile [read $fptrin];
	set tmp [regsub {[^\n]+\n$} $infile {} outfile];
	puts $tmp;
	puts $outfile;
	puts -nonewline $fptrout $outfile;
	close $fptrin;
	close $fptrout;
    }
}
proc parse_quote {stock data} {
    
    regexp {[0-12][0-12]:[^>]+>([^\n]+)} $data tmp date;
    set date [clock format [clock seconds] -format %D];
    regexp {Last:[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp price;
    regexp {Change:[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp change;
    regexp {Change:[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp pct_change;
    regexp {Volume:[^>]+>([^<]+)} $data tmp volume;
    regexp {High:[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp high;
    regexp {Low:[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp low;
    regexp {EPS:[^>]+>[^>]+>([^<]+)} $data tmp naeps;
    regexp {EPS:[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp eps;
    regexp {52wk High:[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp high52;
    regexp {52wk Low:[^>]+>[^>]+>[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp low52;
    regexp {Avg Volume:[^>]+>[^>]+>[^>]+>([^<]+)} $data tmp avgv;
    
    if {![regexp {n/a} $naeps]} {
#	puts "[exec date +%D]*$stock*$price*$change*$pct_change*$high*$low*$eps*$high52*$low52*$volume*$avgv";
	set data  "$date*$stock*$price*$change*$pct_change*$high*$low*$eps*$high52*$low52*$volume*$avgv";
#	puts $fptr "[exec date +%D]*$stock*$price*$change*$pct_change*$high*$low*$eps*$high52*$low52*$volume*$avgv";
    } else {
#	puts "[exec date +%D]*$stock*$price*$change*$pct_change*$high*$low*n/a*$high52*$low52*$volume*$avgv";
	set data "$date*$stock*$price*$change*$pct_change*$high*$low*n/a*$high52*$low52*$volume*$avgv";
#	puts $fptr "[exec date +%D]*$stock*$price*$change*$pct_change*$high*$low*n/a*$high52*$low52*$volume*$avgv";
    }	
    return $data;
}
#    lqd
#    ACTWX 
#    JENSX
#    FDGRX FDEGX FSMKX FSEMX FSTMX
#    FTHRX
#    TWIEX

set sort_order decreasing;


proc get_quotes_old {stock_list} {
    if {[info exists data]} {unset data;}
    foreach stock $stock_list  {
	set last_date [get_info date $stock];
	set todays_date [clock format [clock seconds] -format %D];
	if {[clock format [clock scan $todays_date] -format %A] == "Sunday"} {
	    set todays_date [clock format [expr [clock scan $todays_date] - 3600 * 48] -format %D];
	} elseif {[clock format [clock scan $todays_date] -format %A] == "Saturday"} {
	    set todays_date [clock format [expr [clock scan $todays_date] - 3600 * 24] -format %D];
	}
	if {$last_date == $todays_date} {
	    puts "Quote Already Retrieved!";
	} else {
	    if {![info exists ::debug]} {
		puts "Got here";
		set token [http::geturl \
			       "http://www.marketwatch.com/tools/quotes/quotes.asp?symb=$stock&siteid=mktw&dist=mktwqn"];
		set data [http::data $token];
		set ::data $data;
		#	    puts "Got here";
		set data [parse_quote $stock $data];
	    } else {
		set fptr [open tmp2.html r];
		set stock scmr;
		set data [read $fptr];
		set data [parse_quote $stock $data];
		break;
	    }
	    if {$last_date == [get_info date $stock $data]} {
		puts "Quote Already Retrieved!";
		puts [get_last $stock 1];
	    } else {
		set fptr [open ../data/$stock.dat a];
		puts $data;
		puts $fptr $data;
		close $fptr;
	    }
	}
    }
}


proc get_five_stars {} {
    global url;
    set url {http://research2.fidelity.com/fidelity/research/reports/pdf/getReport.asp?docKey=7015-star0721-77E62F44U6R9NE8IS8MNTTG6D8}
    set token [http::geturl $url];
    set data [http::data $token];
    puts $data;
}
proc tmp_debug {} {
    foreach name [lsort [array names $::token]] {
	if {$name != "body"} {
	    puts "$name = [set [subst $::token]($name)]";
	}
    }
}
proc get_quotes_historical {stock_list} {
    global data current_data gui text_window;
    set success_list {};
    set fail_list {};
    set day [expr [clock format [clock seconds] -format %e]];
    set month [expr [remove_l0s [clock format [clock seconds] -format %m]] - 1];
    set year [expr [clock format [clock seconds] -format %Y]];
    foreach stock $stock_list  {
	gui_puts "Retrieving Historical Data For $stock";
	set attempt 0;
	set success 0;
	if {[file exists ../historical_data/$stock.dat]} {
	    set fptrin [open ../historical_data/$stock.dat r];
	    set current_data [read $fptrin];
	    close $fptrin;
	} else {
	    set current_data {};
	}
	while {[expr ($success == 0) && ($attempt < 5)]} {
	    set token [http::geturl \
			   "http://ichart.finance.yahoo.com/table.csv?s=$stock&amp;d=$month&amp;e=$day&amp;f=$year&amp;g=d&amp;a=8&amp;b=26&amp;c=1960&amp;ignore=.csv"]
#			  -timeout 5000 -binary true -blocksize 262144
#                     	   "http://ichart.finance.yahoo.com/table.csv?s=$stock&amp;d=6&amp;e=14&amp;f=2005&amp;g=d&amp;a=8&amp;b=7&amp;c=1984&amp;ignore=.csv"
	    
	    set data [http::data $token];
	    if {[info exists ::debug]} {
		set ::token $token;
		puts "Body size = [http::size $token]";
		puts "Timeout = [http::status $token]";
#		puts $data;
		regexp {^[^\n]+\n([^\n]+)} $data tmp data2;
		puts $data2;
		puts "New data [llength [split $data \n]]";
		puts "Old data [llength [split $current_data \n]]";
	    }
	    if {[llength [split $data \n]] > [llength [split $current_data \n]]} {
		set success 1;
	    } else {
		incr attempt;
	    }
#	    set success 1;
	    if {$success == 1} {
		set fptrout [open ../historical_data/$stock.dat w];
		puts -nonewline $fptrout $data;
		close $fptrout;
	    } else {
		gui_puts "Failed to download new_data for $stock";
	    }
	}
	if {$success == 0} {
	    gui_puts "##                Gave up on $stock               ##";
	    lappend fail_list $stock;
	} else {
	    gui_puts "**  Successfully downloaded new data for $stock   **";
	    lappend success_list $stock;
	}
    }
    puts "Successfully downloaded quotes for\n $success_list";
    puts "Failed to download quotes for\n $fail_list";
    return $fail_list;
}

proc gui_puts {string_in} {
    global gui text_window;
    if {$gui == 1} {
	$text_window insert end $string_in\n;
	$text_window see end;
    } else {
	puts $string_in
    }
}

proc update_list {stock_list} {
    global minus_days;
    if {[info exists ::debug]} {puts "Entering proc update_list"}; 
    if {![info exists minus_days]} {
	set minus_days 0;
	set date [clock format [clock seconds]];
	if {[regexp Sat $date]} {set minus_days 1};
	if {[regexp Sun $date]} {set minus_days 2};
	if {[info exists ::debug]} {puts "Minus Days = $minus_days"};
    };
    set date [clock format [clock seconds] -format %D];
    set output_list {};
    foreach stock $stock_list {
	if {[info exists ::debug]} {puts $stock}; 
	if {[file exists ../historical_data/$stock.dat]} {
	    if {[expr [clock scan [clock format [clock seconds] -format %D]] - $minus_days * 3600 * 24] != [clock scan [get_info date $stock]]} {
		lappend output_list $stock;
	    }
	} else {
		lappend output_list $stock;
	}
    }
    if {[info exists ::debug]} {puts "Exiting proc update_list"}; 
    return $output_list;
}

proc get_info {field stock {data 0}} {
    global get_last_data;
#    if {[info exists ::debug]} {puts "Entering get_info"};
    if {$data == 0} {
	get_last $stock 2;
	set current_data $get_last_data(0);
	set last_data $get_last_data(1);
	set last_data_list [split $last_data {,}];
	set lclose  [lindex $last_data_list 4]; 
    } else {
	set current_data $data
    }
    set current_data_list [split $current_data {,}];
#    puts $current_data_list;
    set caclose [lindex $current_data_list 6];
    set cclose  [lindex $current_data_list 4]; 
    set split_factor [expr $caclose/$cclose];
    puts $split_factor;

    set cdate   [lindex $current_data_list 0];
    set copen   [expr [lindex $current_data_list 1] * $split_factor];
    set chigh   [expr [lindex $current_data_list 2] * $split_factor];
    set clow    [expr [lindex $current_data_list 3] * $split_factor];
    set cclose  [expr [lindex $current_data_list 4] * $split_factor];
    set cvol    [lindex $current_data_list 5];
#    puts $field;
#	ep* {set field_value $ddate}
#	52h* {set field_value $ddate}
#	52l* {set field_value $ddate}
#	av* {set field_value $ddate}
    switch -glob -- $field {
	da* {set field_value [clock format [clock scan $cdate] -format %D]}
	cl* {set field_value $cclose}
	lc* {set field_value $lclose}
	ch* {set field_value [expr $cclose - $lclose]}
	pc* {set field_value [format %.2f [expr ($cclose - $lclose)/$lclose * 100]] }
	hi* {set field_value $chigh}
	lo* {set field_value $clow}
	op* {set field_value $copen}
	vo* {set field_value $cvol}
	default {set field_value $ddate}
    }

#    if {[info exists ::debug]} {puts "Exiting get_info"};
    return $field_value;
}

proc get_all_fields {stock_list} {
    global data stock_data;
    foreach stock $stock_list {
	set stock_data [get_last $stock 1];
	set stock_data [join "$stock_data [get_info ch $stock]" {,}];
	set stock_data [join "$stock_data [get_info pc $stock]" {,}];
	set stock_data [join "$stock_data [get_info lc $stock]" {,}];
	set stock_data [split $stock_data {,}];
	return $stock_data;
    }
}

#get_price scmr;
#set patt1 {[^*]+[*]+};
#regexp "$patt1$patt1$patt1\(\[^*\]+)" $data tmp price;

proc gui_get_quotes {} {
    global stock_list gui text_window;
    toplevel .catch_output
    wm title .catch_output "Download Status";
    set text_window [text .catch_output.text -height 20 -width 40];
    pack .catch_output.text; 
    $text_window insert end "hello";
    set gui 1;
    set stock_list [get_quotes_historical $stock_list];
    stock_gui2;
#    destroy .catch_output;
    set gui 0;
}


proc gui_get_quotes2 {} {
    global stock_list bs_list;
    get_quotes_historical $stock_list;
}

proc stock_gui {} {
    global stock_list;
    wm title . "Stock Application";
    #index           0     1    2    3    4   5     6      7         8      9         10
#    set field_list "stock date open high low close volume adj_close change pctchange prior_close";
    #index          0     1    10          2    3    4   5     8      9         6      7
    set field_list "stock date prior_close open high low close change pctchange volume adj_close";
    
#    pack propagate . true;
    destroy .top;
    frame .top;
    frame .top.commands;
    button .top.commands.download -text "Download Quotes" -command "gui_get_quotes";
    button .top.commands.refresh -text "Refresh" -command {stock_sort};
    button .top.commands.own_list -text "Own_List" -command "source ../lists/own_list.tcl; set stock_list $own_list;";
    button .top.commands.watch_list -text "Watch_List" -command "source ../lists/watch_list.tcl; set stock_list $watch_list;";
    button .top.commands.five_stars_list -text "Five_Stars_List" -command "source ../lists/five_stars_list.tcl; set stock_list $five_stars_list;";
    button .top.commands.concat_lists -text "Combine Lists" -command "set stock_list [concat $own_list $five_stars_list $watch_list]";
    button .top.commands.get_tech -text "Get Tech" -command "get_tech $stock_list";
    button .top.commands.keep_trying -text "KT" -command "keep_trying";
    
    foreach butt {download refresh own_list watch_list five_stars_list concat_lists get_tech keep_trying} { 
	pack .top.commands.$butt -side left;
    }
    pack .top.commands -side top;
########## setup column labels
#    foreach a {stock close change pctchange high low eps 52h 52l vol avol prior_close} {
#	catch [destroy .column_labels.$a];
#    }
    frame .top.column_labels;
    pack .top.column_labels
    set color beige;
    foreach field $field_list {
	if {$field == "close"} {
	    button .top.column_labels.$field -text $field -command $field\_sort -justify left -width 12 -bg red -bd 0 -relief raised;
    }
	button .top.column_labels.$field -text $field -command $field\_sort -justify left -width 12 -bg $color -bd 0 -relief raised;
	pack .top.column_labels.$field -side left;
	if {$color == "beige"} {set color tan} else {set color beige};
    }
#############

    frame .top.divide1 -height 3 -bg black
    pack .top.divide1 -side top -fill x;


######### setup one row per stock
    foreach stock $stock_list {
#	destroy .top.$stock\_row;
	frame .top.$stock\_row;
	pack .top.$stock\_row -side top;
	set stock_data "$stock [get_all_fields $stock]";
	set i 0;
	
	set change [get_info ch $stock];
	if {$change == "UNCH"} {
	    set change 0.0;
	}
	if {$change < 0} {set fg red} else {set fg black};


	set color beige;
	foreach field $field_list {
	    #puts $field;
	    #puts [lindex $stock_data $i];
	    label .top.$stock\_row.$field -text [lindex $stock_data $i] -anchor e -justify left -width 12 -bg $color\
		-fg $fg;
	    pack .top.$stock\_row.$field -side left;
	    if {$color == "beige"} {set color tan} else {set color beige};
	    #puts $i;
    #index           0     1    10          2    3    4   5     8      9         6      7
#    set field_list "stock date prior_close open high low close change pctchange volume adj_close";
	    switch -exact -- $i {
		0  {set i  1}
		1  {set i  10}
		10 {set i  2}
		2  {set i  3}
		3  {set i  4}
		4  {set i  5}
		5  {set i  8}
		8  {set i  9}
		9  {set i  6}
		6  {set i  7}
		default {set i 0}
	    }
	}
    }
    scrollbar .top.yscroll -command {.top yview} -orient vertical
    pack .top.yscroll -side right;
    pack .top;
}
proc stock_gui2 {} {
    global stock_list first_time;
    wm title . "Stock Application";
    #index           0     1    2    3    4   5     6      7         8      9         10
#    set field_list "stock date open high low close volume adj_close change pctchange prior_close";
    #index          0     1    10          2    3    4   5     8      9         6      7
    set field_list "stock date prior_close open high low close change pctchange volume adj_close";
    
#    pack propagate . true;
    destroy .top;
    frame .top;
    frame .top.commands;
    button .top.commands.download -text "Download Quotes" -command "gui_get_quotes";
    button .top.commands.refresh -text "Refresh" -command "stock_gui2";
    button .top.commands.own_list -text "Own_List" -command {source ../lists/own_list.tcl; set stock_list $own_list;};
    button .top.commands.watch_list -text "Watch_List" -command {source ../lists/watch_list.tcl; set stock_list $watch_list;};
    button .top.commands.five_stars_list -text "Five_Stars_List" -command {source ../lists/five_stars_list.tcl; set stock_list $five_stars_list;};
    button .top.commands.concat_lists -text "Combine Lists" -command {set stock_list [concat $own_list $five_stars_list $watch_list]};
    button .top.commands.get_tech -text "Get Tech" -command {get_tech $stock_list};
    button .top.commands.keep_trying -text "KT" -command "keep_trying";
    
    foreach butt {download refresh own_list watch_list five_stars_list concat_lists get_tech keep_trying} { 
	pack .top.commands.$butt -side left;
    }
    pack .top.commands -side top;
########## setup column labels
#    foreach a {stock close change pctchange high low eps 52h 52l vol avol prior_close} {
#	catch [destroy .column_labels.$a];
#    }
    frame .top.column_labels;
    pack .top.column_labels
    set color beige;
    foreach field $field_list {
	if {$field == "close"} {
	    button .top.column_labels.$field -text $field -command $field\_sort -justify left -width 12 -bg red -bd 0 -relief raised;
	} elseif {$field == "pctchange"} {
	    button .top.column_labels.$field -text $field -command $field\_sort -justify left -width 12 -bg red -bd 0 -relief raised;
	} else {
	    button .top.column_labels.$field -text $field -command $field\_sort -justify left -width 13 -bg $color -bd 0 -relief raised;
	}
	pack .top.column_labels.$field -side left;
	if {$color == "beige"} {set color tan} else {set color beige};
    }
#############

    frame .top.divide1 -height 3 -bg black
    pack .top.divide1 -side top -fill x;

#    frame .top.left_side;
#    pack .top.left_side -side left;
    text .top.text -font {-family {Courier New} -size 8} -width 132 -yscrollcommand {.top.yscroll set};
    pack .top.text -side left;
    ## setup tags
    .top.text tag configure tan_background -background tan
    .top.text tag configure beige_background -background beige
    .top.text tag configure red_foreground -foreground red
    .top.text tag configure black_foreground -foreground black
    


######### setup one row per stock
    if {[info exists stock_list]} {
	foreach stock $stock_list {
	    #	destroy .top.left_side.$stock\_row;
	    set stock_data "$stock [get_all_fields $stock]";
	    set i 0;
	    
	    set change [get_info ch $stock];
	    if {$change == "UNCH"} {
		set change 0.0;
	    }
	    if {$change < 0} {set fg red} else {set fg black};
	    
	    
	    set color beige;
	    set row_text {};
	    foreach field $field_list {
		#puts $field;
		#puts [lindex $stock_data $i];
		#	    label .top.left_side.$stock\_row.$field -text [lindex $stock_data $i] -anchor e -justify left -width 12 -bg $color\
					   -fg $fg;
					   #	    pack .top.left_side.$stock\_row.$field -side left;
					   if {$color == "beige"} {set color tan} else {set color beige};
					   set tmp_string [format %12s [lindex $stock_data $i]];
					   lappend row_text $tmp_string;
					   .top.text insert insert $tmp_string "$color\_background $fg\_foreground";
					   #puts $i;
					   #index           0     1    10          2    3    4   5     8      9         6      7
					   #    set field_list "stock date prior_close open high low close change pctchange volume adj_close";
					   switch -exact -- $i {
					       0  {set i  1}
					       1  {set i  10}
					       10 {set i  2}
					       2  {set i  3}
					       3  {set i  4}
					       4  {set i  5}
					       5  {set i  8}
					       8  {set i  9}
					       9  {set i  6}
					       6  {set i  7}
					       default {set i 0}
					   }
				       }
	    .top.text insert insert "\n";
	}
    }
    scrollbar .top.yscroll -command {.top.text yview} -orient vertical
    pack .top.yscroll -side left -fill y;
    pack .top;
}
proc stock_gui3 {} {
    global stock_list;
    wm title . "Stock Application";
    #index           0     1    2    3    4   5     6      7         8      9         10
#    set field_list "stock date open high low close volume adj_close change pctchange prior_close";
    #index          0     1    10          2    3    4   5     8      9         6      7
    set field_list "stock date prior_close open high low close change pctchange volume adj_close";
    
#    pack propagate . true;
    destroy .top;
    frame .top;
    frame .top.commands;
    button .top.commands.download -text "Download Quotes" -command "gui_get_quotes";
    button .top.commands.refresh -text "Refresh" -command "stock_gui2";
    grid .top.commands.download -side left;
    grid .top.commands.refresh -side left
    grid .top.commands -side top;
########## setup column labels
#    foreach a {stock close change pctchange high low eps 52h 52l vol avol prior_close} {
#	catch [destroy .column_labels.$a];
#    }
    frame .top.column_labels;
    grid .top.column_labels
    set color beige;
    foreach field $field_list {
	button .top.column_labels.$field -text $field -command $field\_sort -justify left -width 13 -bg $color -bd 0 -relief raised;
	grid .top.column_labels.$field -side left;
	if {$color == "beige"} {set color tan} else {set color beige};
    }
#############

    frame .top.divide1 -height 3 -bg black
    grid .top.divide1 -side top -fill x;

#    frame .top.left_side;
#    grid .top.left_side -side left;
    text .top.text -font {-family {Courier New} -size 8} -width 132 -yscrollcommand {.top.yscroll set};
    grid .top.text -side left;
    ## setup tags
    .top.text tag configure tan_background -background tan
    .top.text tag configure beige_background -background beige
    .top.text tag configure red_foreground -foreground red
    .top.text tag configure black_foreground -foreground black
    


######### setup one row per stock
    foreach stock $stock_list {
#	destroy .top.left_side.$stock\_row;
	set stock_data "$stock [get_all_fields $stock]";
	set i 0;
	
	set change [get_info ch $stock];
	if {$change == "UNCH"} {
	    set change 0.0;
	}
	if {$change < 0} {set fg red} else {set fg black};


	set color beige;
	set row_text {};
	foreach field $field_list {
	    #puts $field;
	    #puts [lindex $stock_data $i];
#	    label .top.left_side.$stock\_row.$field -text [lindex $stock_data $i] -anchor e -justify left -width 12 -bg $color\
		-fg $fg;
#	    grid .top.left_side.$stock\_row.$field -side left;
	    if {$color == "beige"} {set color tan} else {set color beige};
		set tmp_string [format %12s [lindex $stock_data $i]];
	    lappend row_text $tmp_string;
		.top.text insert insert $tmp_string "$color\_background $fg\_foreground";
	    #puts $i;
    #index           0     1    10          2    3    4   5     8      9         6      7
#    set field_list "stock date prior_close open high low close change pctchange volume adj_close";
	    switch -exact -- $i {
		0  {set i  1}
		1  {set i  10}
		10 {set i  2}
		2  {set i  3}
		3  {set i  4}
		4  {set i  5}
		5  {set i  8}
		8  {set i  9}
		9  {set i  6}
		6  {set i  7}
		default {set i 0}
	    }
	}
	.top.text insert insert "\n";
    }
    scrollbar .top.yscroll -command {.top.text yview} -orient vertical
    grid .top.yscroll -side left -fill y;
    grid .top;
}

proc pctchange_sort {} {
    global stock_list sort_order;
    set stock_data_list {};
    foreach stock $stock_list {
	set tmp_list {};
	set pct_change [get_info pc $stock];
	if {$pct_change == "UNCH"} {
	    set pct_change 0.0;
	} else {
	    regexp {[^%]+} $pct_change pct_change;
	}
	lappend stock_data_list "$stock $pct_change";
#	lappend stock_data_list $tmp_list;
    }
    #puts $stock_data_list;
    set stock_data_list [lsort -real -$sort_order -index 1 $stock_data_list];
    #puts $stock_data_list;
    set stock_list {};
    foreach list_item $stock_data_list {
	lappend stock_list [lindex $list_item 0];
    }
    stock_gui2;
#    if {$sort_order == "increasing"} {set sort_order decreasing} else {set sort_order increasing};
}
proc eps_sort {} {
    global stock_list sort_order;
    set stock_data_list {};
    foreach stock $stock_list {
	set tmp_list {};
	set eps [get_info ep $stock];
	if {$eps == "n/a"} {
	    set eps -1000;
	} 
	lappend stock_data_list "$stock $eps";
#	lappend stock_data_list $tmp_list;
    }
    puts $stock_data_list;
    set stock_data_list [lsort -real -$sort_order -index 1 $stock_data_list];
    puts $stock_data_list;
    set stock_list {};
    foreach list_item $stock_data_list {
	lappend stock_list [lindex $list_item 0];
    }
    stock_gui2;
#    if {$sort_order == "increasing"} {set sort_order decreasing} else {set sort_order increasing};
}
proc pe_sort {} {
    global stock_list sort_order;
    set stock_data_list {};
    foreach stock $stock_list {
	set tmp_list {};
	set eps [get_info ep $stock];
	set cl [get_info cl $stock];
	if {$eps == "n/a"} {set eps .0000001} elseif {$eps < 0} {set eps [expr .0001 * 1/abs($eps)]}
	set pe [expr int($cl/$eps)];
	lappend stock_data_list "$stock $pe";
#	lappend stock_data_list $tmp_list;
    }
    puts $stock_data_list;
    set stock_data_list [lsort -real -$sort_order -index 1 $stock_data_list];
    puts $stock_data_list;
    set stock_list {};
    foreach list_item $stock_data_list {
	lappend stock_list [lindex $list_item 0];
    }
    stock_gui2;
#    if {$sort_order == "increasing"} {set sort_order decreasing} else {set sort_order increasing};
}

proc change_sort {} {
    global stock_list sort_order;
    set stock_data_list {};
    foreach stock $stock_list {
	set tmp_list {};
	set change [get_info ch $stock];
	if {$change == "UNCH"} {
	    set change 0.0;
	} 
	lappend stock_data_list "$stock $change";
    }
    puts $stock_data_list;
    set stock_data_list [lsort -real -$sort_order -index 1 $stock_data_list];
    puts $stock_data_list;
    set stock_list {};
    foreach list_item $stock_data_list {
	lappend stock_list [lindex $list_item 0];
    }
    stock_gui2;
#    if {$sort_order == "increasing"} {set sort_order decreasing} else {set sort_order increasing};
}

proc date_sort {} {
    global stock_list sort_order;
    set stock_data_list {};
    foreach stock $stock_list {
	set tmp_list {};
	set date [clock scan [get_info date $stock]];
	lappend stock_data_list "$stock $date";
    }
    puts $stock_data_list;
    set stock_data_list [lsort -real -$sort_order -index 1 $stock_data_list];
    puts $stock_data_list;
    set stock_list {};
    foreach list_item $stock_data_list {
	lappend stock_list [lindex $list_item 0];
    }
    stock_gui2;
#    if {$sort_order == "increasing"} {set sort_order decreasing} else {set sort_order increasing};
}

proc stock_sort {} {
    global stock_list;
    set stock_list [lsort -ascii $stock_list];
    stock_gui2;
}

proc stock_sort_alpha {} {
    global stock_list;
    set stock_list [lsort -ascii $stock_list];
}


proc close_sort {} {
    global stock_list sort_order;
    set stock_data_list {};
    foreach stock $stock_list {
	set tmp_list {};
	set close_data [get_info cl $stock];
	lappend stock_data_list "$stock $close_data";
#	lappend stock_data_list $tmp_list;
    }
    puts $stock_data_list;
    set stock_data_list [lsort -real -$sort_order -index 1 $stock_data_list];
    puts $stock_data_list;
    set stock_list {};
    foreach list_item $stock_data_list {
	lappend stock_list [lindex $list_item 0];
    }
    stock_gui2;
#    if {$sort_order == "increasing"} {set sort_order decreasing} else {set sort_order increasing};
}

    
########################################
## retrieve $entries most recent entries of data for stock $stock
## each entry is comma seperated and looks like the following
## Date,      Open ,High ,Low  ,Close,Volume,Adj Close
## 2010-04-21,20.14,20.23,19.87,20.17,172100,20.17 
########################################
proc get_last {stock entries} {
    global get_last_data;
    if {[info exists get_last_data]} {unset get_last_data};
    if {[info exists ::debug]} {puts "Entering get_last"};
    set fptr [open ../historical_data/$stock.dat r];
    set search_pattern {([^\n]+)\n};
    set final_pattern {^[^\n]+\n}; #strip off first line
    set match_list {};
    for {set i 0} {$i < [expr $entries]} {incr i} {
	lappend final_pattern $search_pattern;
	lappend match_list tmp$i;
    }
#    lappend final_pattern {$};
    set final_pattern2 [join $final_pattern {}];
    set data [read $fptr];
#    puts $data;
    set eval_string "regexp \$final_pattern2 \$data tmp $match_list";
    eval $eval_string;
    #	puts [regexp  $final_pattern2 $data tmp [subst $match_list]];
    set i 0;
#    puts $match_list;
    if {[info exists tmp0]} {
	foreach a $match_list {
	    set data [set $a];
	    #	puts $data;
	    set get_last_data($i) [set $a]; 
	    incr i;};
    }
    close $fptr;
    if {[info exists tmp0]} {
	if {[info exists ::debug]} {puts "Exiting get_last, tmp0 defined"};
	return $tmp0
    } else {
	if {[info exists ::debug]} {puts "Exiting get_last, tmp0 undefined"};
	return -1
    };
}

proc calc_mfi2 {stock {n_days 14}} {
    set mf_pos 0;
    set mf_neg 0;
    set first_day [expr $n_days + 1];
    get_last $stock $first_day;
    for {set day 1} {$day < $first_day} {incr day} {
	set day_1 [expr $day - 1];
	#calculate typical price (note get_last_data array is in chrono order)
	set last_price [expr ([get_info hi $stock $get_last_data($day_1)] + \
				  [get_info lo $stock $get_last_data($day_1)] + \
				  [get_info cl $stock $get_last_data($day_1)])/3];
	set current_price [expr ([get_info hi $stock $get_last_data($day)] + \
				     [get_info lo $stock $get_last_data($day)] + \
				     [get_info cl $stock $get_last_data($day)])/3];
	set current_vol [get_info vo $stock $get_last_data($day)];
	set current_vol [join [split $current_vol {,}] {}];
	if {$current_price > $last_price} {
	    set mf_pos [expr $mf_pos + ($current_price * $current_vol)];
	} else {
	    set mf_neg [expr $mf_neg + ($current_price * $current_vol)];
	}
    }
    
#    puts $mf_pos;
#    puts $mf_neg;
    set mfi [expr 100 - (100/(1 + $mf_pos/$mf_neg))];
    return $mfi;
}

proc calc_mfi {stock {n_days 14}} {
    set mf_pos 0;
    set mf_neg 0;
    set first_day [expr $n_days + 1];
    get_all_data $stock;
    for {set day $first_day} {$day > 0} {incr day -1} {
	set next_day [expr $day - 1];
	set current_price [expr ([get_info hi $stock $stock_data($next_day)] + \
				  [get_info lo $stock $stock_data($next_day)] + \
				  [get_info cl $stock $stock_data($next_day)])/3];
	set last_price [expr ([get_info hi $stock $stock_data($day)] + \
				     [get_info lo $stock $stock_data($day)] + \
				     [get_info cl $stock $stock_data($day)])/3];
	set current_vol [get_info vo $stock $stock_data($next_day)];
#	set current_vol [join [split $current_vol {,}] {}];
	if {$current_price > [expr $last_price * 1.00001]} {
	    set mf_pos [expr $mf_pos + ($current_price * $current_vol)];
	} else {
	    set mf_neg [expr $mf_neg + ($current_price * $current_vol)];
	}
	puts "Cp : $current_price";
	puts "Lp : $last_price";
	puts "VOL: $current_vol";
	puts "MF_POS: $mf_pos";
	puts "MF_NEG: $mf_neg";
    }
    
    
    if {$mf_neg == 0} {
	set mfi 0;
    } else {
	set mfi [expr 100 - (100/(1 + $mf_pos/$mf_neg))];
    }
    return $mfi;
}

proc get_all_data {stock} {
    global dbg;
    set fptrin [open ../historical_data/$stock.dat];

    # throw away header line;
    gets $fptrin;

    set i 0;
    while {![eof $fptrin]} {
	gets $fptrin line_in;
	if {[regexp {,} $line_in]} {
	    uplevel "set stock_data($i) $line_in";
	}
	incr i;
    }
    if {[info exists dbg]} {
	for {set i 0} {$i < [uplevel array size stock_data]} {incr i} {
	    puts [uplevel "set stock_data($i)"];
	}
    }
    close $fptrin;
}
    
    
proc print_last {} {
    global get_last_data;
    foreach a [array names get_last_data] {puts "get_last_data($a) $get_last_data($a)"};
}

proc get_tech stock_list {
    global bs_list;
#    set stock_list [remove_duplicates $stock_list];
    set buy_file [open buy_list.txt a];
    set sell_file [open sell_list.txt a];
    puts [format "%10s\t%10s\t%10s" Symbol MFI RSI];
    puts "-------------------------------------------";
    set buy_list {};
    set sell_list {};
    set bs_list {};
    foreach stock $stock_list {
#	puts [format "%10s\t\t%g\t\t%g" $stock [calc_mfi $stock] [c_calc_rsi $stock]];
	set rsi [c_calc_rsi $stock];
	set mfi 0.0;
	if {$rsi < 30} {
	    set mfi [c_calc_mfi $stock];
	} elseif {$rsi > 70} {
	    set mfi [c_calc_mfi $stock];
	}
    	puts -nonewline [format "%10s\t\t%.1f\t\t%.1f" $stock $mfi $rsi];    
	if {$rsi < 30} {puts "\t\#\#\#\#"; lappend bs_list $stock; lappend buy_list "$stock rsi:$rsi\tmfi:$mfi\n;"};
	if {$rsi > 70} {puts "\t****"; lappend bs_list $stock; lappend sell_list "$stock rsi:$rsi\tmfi:$mfi\n"};
	puts -nonewline \n;
	flush stdout;
    }
    set date [clock format [clock seconds] -format %D];
    puts "$date\nBuy List:\n$buy_list";
    puts "$date\nSell List:\n$sell_list";
    puts $buy_file "$date\nBuy List:\n$buy_list";
    puts $sell_file "$date\nSell List:\n$sell_list";
    close $buy_file;
    close $sell_file;
 #   exec email -m plain -r smtp.comcast.net -b -s lists -a buy_list.txt,sell_list.txt -u rtclancy rtclancy@yahoo.com;
    return "$buy_list $sell_list";
    set fptr [open ../list/bs_list.txt a];
    puts $fp
    
}

proc plot_volume {stock {num_days 365} {num_frames 1} {intop .c_ca}} {
    set swidth [expr int (1280 * .9)];
    set sheight [expr $::sheight / $num_frames];
    get_all_data $stock;
    #######################################################################################
    if {![winfo exists $intop]} {toplevel $intop};
    frame $intop.fvol -height $sheight -width $swidth -border 0;
    canvas $intop.fvol.ca -width $swidth -height $sheight -bg white;
    
    #    set num_days 365;
    set xscale [expr $swidth/($num_days.0 + 2)];
    
    ## find max volume  in order to determine y range
    set ymin 0;
    set ymax 0;
    #start at present day and work back
    for {set day 0} {$day < $num_days} {incr day} {
	set day_vol [expr [get_info vol $stock $stock_data($day)]/1000.0];
	if {$day_vol >= $ymax} {set ymax $day_vol};
    }
    set max [expr int(ceil($ymax)) + 1];
    set yrange [expr $ymax - $ymin];
    set yscale [expr $sheight/$yrange];
    if {[info exists ::debug]} {puts "Minimum $ymin"};
    if {[info exists ::debug]} {puts "Maximum $ymax"};

    ## draw horizontal gridlines every 1 units
    
    set toggle 0;
    set grid_incr [expr [get_grid_incr $ymax] * 2];
    for {set gridline $ymin} {$gridline < $ymax} {incr gridline [expr int($grid_incr)]} {
	set toggle [expr ($toggle + 1) % 2];
	set linecoords {};
	lappend linecoords 0;
	lappend linecoords [expr int(($ymax - $gridline) * $yscale)]
	lappend linecoords $swidth;
	lappend linecoords [expr int(($ymax - $gridline) * $yscale)]
	$intop.fvol.ca create line $linecoords -activefill red -activewidth 3;
    }
    
    $intop.fvol.ca create text [expr int(5 * $xscale + $toggle * 25)] [expr int(($yrange - $gridline + $ymin) * $yscale) - 6] -text [format %.0f $gridline];

    for {set i 0} {$i < $num_days} {incr i} { 
	set rmin 0;
	set rmax [expr [get_info vol $stock $stock_data($i)]/1000.0];


	# draw candle
	set coords {};
	lappend coords [expr (($num_days - $i) * $xscale) - 2 ];
	lappend coords [expr ($yrange - ($rmin - $ymin)) * $yscale];
	
	lappend coords [expr (($num_days - $i) * $xscale) + 2];
	lappend coords [expr ($yrange - ($rmax - $ymin)) * $yscale];
	if {[info exists ::debug]} {puts $coords};
	if {[get_info cl $stock $stock_data($i)] >  [get_info cl $stock $stock_data([expr $i + 1])]} {
	    set color green;
	} else {
	    set color red;
	}
	$intop.fvol.ca create rectangle $coords  -fill $color;
    }

    ### draw 50 day sma line
    set raw_coords [c_calc_sma_volume $stock 15];
    set dataset_size [expr [llength $raw_coords]/2];
    set coords {};
    #puts $xscale;
    #puts $yscale;
    #puts $yrange;
    for {set i 0} {$i < $dataset_size - 0} {incr i} { 
	lappend coords [expr ($num_days - [lindex $raw_coords [expr $i * 2]]) * $xscale];
	lappend coords [expr ($yrange - ([lindex $raw_coords [expr $i * 2 + 1]]/1000.0 - $ymin)) * $yscale];
    }
#    puts "hello";
    $intop.fvol.ca create line $coords  -fill blue -width 2;
    
    ## put label
    ### clear out box for text
    set coords {};
    lappend coords 60;
    lappend coords $sheight;
    
    lappend coords 140;
    lappend coords [expr $sheight - 13];
    if {[info exists ::debug]} {puts $coords};
    $intop.fvol.ca create rectangle $coords  -fill beige;
    $intop.fvol.ca create text 62 [expr $sheight - 12] \
	-activefill red\
	-anchor nw\
	-text [format %.2e [lindex $raw_coords end]] \
	-tags stocklabel \
	-font {-family {Courier New} -size 8 -weight bold};
    pack $intop.fvol.ca;
    pack $intop.fvol;
}

proc plot_macd {stock {num_days 365} {num_frames 1} {intop .c_macd}}  {
    get_all_data $stock;
    set last_sample [expr [array size stock_data] - 1];
#    set ema_12 {};
#    set ema_26 {};
#    set ema_9 {};
#    set macd {};
    set i 0;
    set sum 0;
    set macd_sum 0;
    set sf_9 [expr 2/(1 + 9.0)];
    set sf_12 [expr 2/(1 + 12.0)];
    set sf_26 [expr 2/(1 + 26.0)];
    for {set sample $last_sample} {$sample > -1} {incr sample -1} {
	set previous_sample [expr $sample + 1];
       
	if {$i < 26} {set sum [expr $sum + [get_info cl $stock $stock_data($sample)]]}
	
	if {$i == 11} {set ema_12($sample) [expr $sum/12.0]};
	if {$i == 25} {set ema_26($sample)  [expr $sum/26.0]};
	
	if {$i > 11} {set ema_12($sample) [expr $ema_12($previous_sample) + $sf_12 * ([get_info cl $stock $stock_data($sample)] - $ema_12($previous_sample))]}; 
	if {$i > 25} {
	    set ema_26($sample) [expr $ema_26($previous_sample) + $sf_26 * ([get_info cl $stock $stock_data($sample)] - $ema_26($previous_sample))]
	    set macd($sample) [expr $ema_12($sample) - $ema_26($sample)];
	    #puts "Sample $sample, macd = $macd($sample)";
	    #puts "$ema_9($sample),$ema_12($sample),$ema_26($sample)"; 
	    set macd_sum [expr $macd_sum + $macd($sample)];
	    if {$i == 34} {set ema_9($sample) [expr $macd_sum/9.0]};
	    if {$i > 34} {set ema_9($sample) [expr $ema_9($previous_sample) + $sf_9 * ($macd($sample) - $ema_9($previous_sample))]};

	}
	incr i;
    }

    set ymin 100000;
    set ymax -10000;
    for {set day 0} {$day < $num_days} {incr day} {
	if {$macd($day) <= $ymin} {set ymin $macd($day)};
	if {$macd($day) >= $ymax} {set ymax $macd($day)};
	if {$ema_9($day) <= $ymin} {set ymin $ema_9($day)};
	if {$ema_9($day) >= $ymax} {set ymax $ema_9($day)};
    }

    set swidth [expr int (1280 * .9)];
    set sheight [expr $::sheight / $num_frames];

    if {[expr ($ymax < 0.5) && ($ymin > -0.5)]} {
	set ymin [expr int(floor($ymin)) * .5]
	set ymax [expr int(ceil($ymax))];
	if {[info exists ::debug]} {puts "Minimum $ymin"};
	if {[info exists ::debug]} {puts "Maximum $ymax"};
    } else {
	set ymin [expr int(floor($ymin)) ];
	set ymax [expr int(ceil($ymax))  ];
    }
    set yrange [expr $ymax - $ymin];

    set yscale [expr int($sheight/$yrange)];

    if {![winfo exists $intop]} {toplevel $intop};
    frame $intop.fmacd -height $sheight -width $swidth -border 0;

#######################################################################################
    canvas $intop.fmacd.macd -width $swidth -height $sheight -bg white;

#    set num_days 365;
    set xscale [expr $swidth/($num_days.0 + 2)];
#    set yscale [expr $sheight/$yrange.0];
    set yscale [expr $sheight/$yrange];

## draw horizontal gridlines every 10 units
#    if {[expr ($ymax > 1) || ($ymax == 1)]} {set grid_incr 1.0} else {set grid_incr 0.5};
    if {$yrange > 10} {set grid_incr [get_grid_incr [expr $yrange * 2]];} elseif {$yrange > 5} {set grid_incr 1} else {set grid_incr 0.25};
#    set grid_incr [get_grid_incr [expr $yrange * 2] ];
    puts $grid_incr;
    for {set gridline $ymin} {$gridline < $ymax} {set gridline [expr $gridline + $grid_incr]} {
	set linecoords {};
	if {$gridline == "0.0"} {set lwidth 3;set lcolor blue;} else {set lwidth 1;set lcolor black;};
	lappend linecoords [get_xcoord 0];
	lappend linecoords [get_ycoord $gridline];
	lappend linecoords [get_xcoord $num_days];
	lappend linecoords [get_ycoord $gridline];
	$intop.fmacd.macd create line $linecoords -width $lwidth -fill $lcolor -activefill red;
	$intop.fmacd.macd create text [get_xcoord 5] [expr [get_ycoord [expr $gridline]] - 10] -text $gridline;
	if {[info exists ::debug]} {puts "Got Here"};
    }
#    puts gothere;

## draw vertical gridlines every 10 units
    set toggle 0;
    set grid_incr [get_grid_incr $num_days];
    wvar grid_incr stall;
    for {set gridline 20} {$gridline < $num_days} {incr gridline $grid_incr} {
	set linecoords {};
	set toggle [expr ($toggle + 1) % 2];
	lappend linecoords [get_xcoord $gridline];
	lappend linecoords [get_ycoord $ymax];
	lappend linecoords [get_xcoord $gridline]
	lappend linecoords [get_ycoord $ymin];
	$intop.fmacd.macd create line $linecoords
	$intop.fmacd.macd create text [get_xcoord [expr $gridline -5]] [expr [get_ycoord $ymin] - (7 + $toggle * 12)] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
    }

## put label
    $intop.fmacd.macd create text [expr [get_xcoord $num_days] - 20] [expr [get_ycoord $ymax] + 10] -text $stock -tags stocklabel -font 12;

#    foreach a [array names macd] {puts "macd($a) = $macd($a)"};
    set coords {};
    set asize [array size macd];
    #    for {set i 0} {$i < [expr $asize - 260]} {incr i}  
    for {set i 0} {$i < $num_days} {incr i} { 
	lappend coords [get_xcoord [expr $num_days - $i]];  
	lappend coords [get_ycoord $macd($i)];
    }
#    if {[info exists ::debug]} {puts $coords};
    $intop.fmacd.macd create line $coords -tags macdline -fill black -width 5;

#    foreach a [array names macd] {puts "macd($a) = $macd($a)"};
    set coords {};
    set asize [array size macd];
    #    for {set i 0} {$i < [expr $asize - 260]} {incr i}  
    for {set i 0} {$i < $num_days} {incr i} { 
	lappend coords [get_xcoord [expr $num_days - $i]];  
	lappend coords [get_ycoord $ema_9($i)];
    }
#    if {[info exists ::debug]} {puts $coords};
    $intop.fmacd.macd create line $coords -tags ema_9line -fill blue;
 
    pack $intop.fmacd.macd;
    pack $intop.fmacd;
    return $macd(0);
}
proc calc_rsi {stock {nperiods 14}} {
    global dbg;
    get_all_data $stock;
    set last_sample [expr [array size stock_data] - 1];
    
    #compute first RS
    set period_gain 0;
    set period_loss 0;
    for {set sample $last_sample} {$sample > [expr $last_sample - $nperiods]} {incr sample -1} {
	set change [expr [get_info cl $stock $stock_data([expr $sample - 1])] \
			- [get_info cl $stock $stock_data($sample)]];
	if {[info exists dbg]} {puts $change};
	if {$change > 0} {
	    set period_gain [expr $period_gain + $change];
	    if {[info exists dbg]} {puts "$sample $period_gain"};
	} else {
	    set period_loss [expr $period_loss + $change];
	    if {[info exists dbg]} {puts "$sample $period_loss"};
	}
    }
    set period_gain [expr $period_gain/$nperiods.0];
    set period_loss [expr $period_loss/$nperiods.0];
    if {$period_loss != 0} {
	set rsi([expr $sample - 2]) [expr 100.0 - (100.0/(1.0 + $period_gain/abs($period_loss)))];
    } else {
	set rsi([expr $sample - 2])  0;
    }
#    puts "period_gain = $period_gain, period_loss = $period_loss, rsi = $rsi([expr $sample - 2])";
    
    for {set sample $sample} {$sample > 0} {incr sample -1} {
	set change [\
			expr [get_info cl $stock $stock_data([expr $sample - 1])] \
			- [get_info cl $stock $stock_data($sample)]];
	if {[info exists dbg]} {puts $change};
	if {$change > 0} {
	    set period_gain [expr (($period_gain * ($nperiods - 1)) + $change)/$nperiods.0];
	    set period_loss [expr (($period_loss * ($nperiods - 1)) + 0)/$nperiods.0];
	} else {
	    set period_gain [expr (($period_gain * ($nperiods - 1)) + 0)/$nperiods.0];
	    set period_loss [expr (($period_loss * ($nperiods - 1)) + $change)/$nperiods.0];
	}
	if {$period_loss != 0} {
	    set rsi([expr $sample - 1]) [expr 100.0 - (100.0/(1.0 + $period_gain/abs($period_loss)))];
	} else {
	    set rsi([expr $sample - 1])  0;
	}
#	puts "period_gain = $period_gain, period_loss = $period_loss, rsi = $rsi([expr $sample - 1])";
    }
    if {[info exists dbg]} {
	for {set sample $last_sample} {$sample > -1} {incr sample -1} {
	    if {[info exists rsi($sample)]} {
		puts "$sample $rsi($sample)";
	    } else {
		puts "$sample 0";
	    }
	}
    }
    return $rsi(0);
}

proc plot_close {stock {num_frames 1} {intop .c_cl}} {
    set swidth [expr int (1280 * .9)];
    set sheight [expr $::sheight / $num_frames];
    get_all_data $stock;
#######################################################################################
    if {![winfo exist $intop]} {toplevel $intop};
    frame $intop.fcl -height $sheight -width $swidth -border 0;
    canvas $intop.fcl.c -width $swidth -height $sheight -bg white;

    set num_days 365;
    set xscale [expr $swidth/($num_days.0 + 2)];

## find min and max price in order to determine y range
    set ymin 100000;
    set ymax 0;
    #start at present day and work back
    for {set day 0} {$day < 260} {incr day} {
	set day_price [get_info hi $stock $stock_data($day)];
	if {$day_price <= $ymin} {set ymin $day_price};
	if {$day_price >= $ymax} {set ymax $day_price};
    }
    set ymin [expr int(floor($ymin))];
    set ymax [expr int(ceil($ymax)) + 1];
    set yrange [expr $ymax - $ymin];
    set yscale [expr $sheight/$yrange];
    if {[info exists ::debug]} {puts "Minimum $ymin"};
    if {[info exists ::debug]} {puts "Maximum $ymax"};

## draw horizontal gridlines every 1 units
    for {set gridline $ymin} {$gridline < $ymax} {incr gridline} {
	set linecoords {};
	lappend linecoords 0;
	lappend linecoords [expr int(($ymax - $gridline) * $yscale)]
	lappend linecoords $swidth;
	lappend linecoords [expr int(($ymax - $gridline) * $yscale)]
	$intop.fcl.c create line $linecoords
	$intop.fcl.c create text [expr int(5 * $xscale)] [expr int(($yrange - $gridline + $ymin) * $yscale) - 6] -text [expr $gridline];
    }

## draw vertical gridlines every 10 units
    for {set gridline 20} {$gridline < $num_days} {incr gridline 20} {
	set linecoords {};
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords 0;
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords $sheight;
	$intop.fcl.c create line $linecoords
	$intop.fcl.c create text [expr int(($gridline - 4) * $xscale)] [expr $sheight - 14] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
    }

## put label
    $intop.fcl.c create text [expr $swidth - 15 * $xscale] [expr 4 * $yscale] \
	-text "$stock\nCL:\t[get_info cl $stock]" \
	-tags stocklabel -font 12;

    set coords {};
    set asize [array size stock_data];
    for {set i 0} {$i < $num_days} {incr i} { 
 	lappend coords [expr int(($num_days - $i) * $xscale) ]  
 	lappend coords [expr ($yrange - [get_info cl $stock $stock_data($i)] + $ymin) * $yscale];
    }
     if {[info exists ::debug]} {puts $coords};
     $intop.fcl.c create line $coords -tags rsiline -fill black;
 
    pack $intop.fcl.c;
    pack $intop.fcl;
}
proc plot_candles {stock {num_days 365} {num_frames 1} {intop .c_ca}} {
    set swidth [expr int (1280 * .9)];
    set sheight [expr $::sheight / $num_frames];
    get_all_data $stock;
    #######################################################################################
    if {![winfo exists $intop]} {toplevel $intop};
    frame $intop.fca -height $sheight -width $swidth -border 0;
    canvas $intop.fca.ca -width $swidth -height $sheight -bg white;
    
    #    set num_days 365;
    set xscale [expr $swidth/($num_days.0 + 2)];
    
    ## find min and max price in order to determine y range
    set ymin 100000;
    set ymax 0;
    #start at present day and work back
    for {set day 0} {$day < $num_days} {incr day} {
	set day_price [get_info hi $stock $stock_data($day)];
	if {$day_price <= $ymin} {set ymin $day_price};
	if {$day_price >= $ymax} {set ymax $day_price};
	set day_price [get_info lo $stock $stock_data($day)];
	if {$day_price <= $ymin} {set ymin $day_price};
	if {$day_price >= $ymax} {set max $day_price};
    }
    if {$ymax < 5} {
	set ymin [expr int(floor($ymin))];
	set max [expr int(ceil($ymax)) ];
    } else {
	set ymin [expr int(floor($ymin)) -1];
	set max [expr int(ceil($ymax)) + 1];
    }
    set yrange [expr $ymax - $ymin];
    set yscale [expr $sheight/$yrange];
    if {[info exists ::debug]} {puts "Minimum $ymin"};
    if {[info exists ::debug]} {puts "Maximum $ymax"};
    
    ## draw horizontal gridlines 
    set toggle 0;
    set grid_incr [expr [get_grid_incr $yrange] * 1];
    if {[expr ($ymax-$ymin)/$grid_incr > 30]} {set grid_incr [expr $grid_incr * 2]};
    for {set gridline $ymin} {$gridline < $ymax} {incr gridline [expr int($grid_incr)]} {
	set toggle [expr ($toggle + 1) % 2];
	set linecoords {};
	lappend linecoords 0;
	lappend linecoords [expr int(($ymax - $gridline) * $yscale)]
	lappend linecoords $swidth;
	lappend linecoords [expr int(($ymax - $gridline) * $yscale)]
	$intop.fca.ca create line $linecoords -activefill red -activewidth 3;
	$intop.fca.ca create text [expr int(5 * $xscale + $toggle * 25)] [expr int(($yrange - $gridline + $ymin) * $yscale) - 6] -text [expr $gridline];
    }
    
    ## draw vertical gridlines
    set toggle 0;
    set grid_incr [get_grid_incr $num_days];
    wvar grid_incr stall;
    for {set gridline 20} {$gridline < $num_days} {incr gridline $grid_incr} {
	set toggle [expr ($toggle + 1) % 2];
	set linecoords {};
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords 0;
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords $sheight;
	$intop.fca.ca create line $linecoords -fill grey
#	$intop.fca.ca create text [expr int(($gridline - 4) * $xscale)] [expr $sheight - 20 + $toggle * 11] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
	$intop.fca.ca create text [get_xcoord [expr $gridline -5]] [expr [get_ycoord $ymin] - (7 + $toggle * 12)] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
    }
    
    ## draw line of closing prices
    #    $intop.fca.ca create text [expr $swidth - 15 * $xscale] [expr 4 * $yscale] -text $stock -tags stocklabel -font 12;
    
    set asize [array size stock_data];
    for {set i 0} {$i < $num_days} {incr i} { 
	set shigh [get_info hi $stock $stock_data($i)];
	set slow [get_info lo $stock $stock_data($i)];
	set sopen [get_info op $stock $stock_data($i)];
	set sclose [get_info cl $stock $stock_data($i)];	
	set slclose [get_info cl $stock $stock_data([expr $i + 1])];

	if {$sclose > $slclose} {
	    set outlinecolor green;
	} else {
	    set outlinecolor red;
	}
	## determine coordinates and color for candle
	if {$sclose > $sopen} {
	    if {$outlinecolor == "green"} {set fillcolor green;set outlinecolor black} else {set fillcolor white};
	    set rmin $sopen;
	    set rmax $sclose;
	} else {
	    if {$outlinecolor == "red"} {set fillcolor red;set outlinecolor black} else {set fillcolor white};
	    set rmin $sclose;
	    set rmax $sopen;
	}
	    
	# draw candle
	set coords {};
	lappend coords [expr (($num_days - $i) * $xscale) - 2];
	lappend coords [expr ($yrange - ($rmin - $ymin)) * $yscale];
	
	lappend coords [expr (($num_days - $i) * $xscale) + 2];
	lappend coords [expr ($yrange - ($rmax - $ymin)) * $yscale];
	if {[info exists ::debug]} {puts $coords};
	$intop.fca.ca create rectangle $coords  -fill $fillcolor -outline $outlinecolor;
	#draw high to low line
	set coords {};
	lappend coords [expr (($num_days - $i) * $xscale + 0)];
	lappend coords [expr ($yrange - ($shigh - $ymin)) * $yscale];
	
        lappend coords [expr (($num_days - $i) * $xscale + 0)];
	lappend coords [expr ($yrange - ($slow - $ymin)) * $yscale];
	if {[info exists ::debug]} {puts $coords};
	$intop.fca.ca create line $coords  -fill black -width 1;
	
	
    }
    ### draw 50 day sma line
    set raw_coords [c_calc_sma $stock 50];
    set dataset_size [expr [llength $raw_coords]/2];
    set coords {};
#    puts $xscale;
#    puts $yscale;
#    puts $yrange;
    for {set i 0} {$i < $dataset_size - 0} {incr i} { 
	lappend coords [expr ($num_days - [lindex $raw_coords [expr $i * 2]]) * $xscale];
	lappend coords [expr ($yrange - ([lindex $raw_coords [expr $i * 2 + 1]] - $ymin)) * $yscale];
    }
#    puts "hello";
    $intop.fca.ca create line $coords  -fill blue -activefill black -width 2;

    ### draw 200 day sma line
    set raw_coords [c_calc_sma $stock 200];
    set dataset_size [expr [llength $raw_coords]/2];
    set coords {};
#    puts $xscale;
#    puts $yscale;
#    puts $yrange;
    for {set i 0} {$i < $dataset_size - 0} {incr i} { 
	lappend coords [expr ($num_days - [lindex $raw_coords [expr $i * 2]]) * $xscale];
	lappend coords [expr ($yrange - ([lindex $raw_coords [expr $i * 2 + 1]] - $ymin)) * $yscale];
    }
#    puts "hello";
    $intop.fca.ca create line $coords  -fill red -width 2 -activefill black -joinstyle round;
    

    ## put label
    ### clear out box for text
    set coords {};
    lappend coords 60;
    lappend coords $sheight;
    
    lappend coords 150;
    lappend coords [expr $sheight - 100];
    if {[info exists ::debug]} {puts $coords};
    $intop.fca.ca create rectangle $coords  -fill beige;
    global minus_days;
    if {![info exists minus_days]} {set minus_days 0};
    $intop.fca.ca create text 62 [expr $sheight - 98] \
	-activefill red\
	-anchor nw\
	-text "$stock\n[get_info da $stock]\ncl: [get_info cl $stock]\nhi: [get_info hi $stock]\nlo: [get_info lo $stock]\nch: [get_info ch $stock]" \
	-tags stocklabel \
	-font {-family {Courier New} -size 8 -weight bold};
    
    ### added buy/sell history vertical lines 
    ### file format stock.trd date_of_transaction ttype (ttype = bl, bs, sl, ss)
    ### order of data is most recent to least recent
    ### read first entry backtrack to date draw vertical line of appropriate color, read next entry and continue until last
    ### bl = blue line, bs = pink line, sl = black line, ss = red line
    if {[file exists ../trading_history/$stock.dat]} {
	set fin [open ../trading_history/$stock.dat];
	set start_day 0;
	set linenumber 0;
	set datain [gets $fin];
	while {![eof $fin]} {
	    set trade_date [clock scan [lindex $datain 0]];
	    set xvalue [lindex $datain 3];
	    set xshares [lindex $datain 2];
	    set trade_price [expr $xvalue / $xshares ];
	    set ttype [lindex $datain 1];
	    set color black;
	    switch -exact $ttype {
		bl {set color green}
		bs {set color purple}
		sl {set color blue}
		ss {set color red}
	    }
	    for {set i $start_day} {$i < $num_days} {incr i} {     

		set current_date [clock scan [get_info date $stock $stock_data($i)]];
		if {$trade_date == $current_date} {
		    #draw vertical line with appropriate color
		    set linecoords {};
		    lappend linecoords [expr (($num_days - $i) * $xscale) - 2];
		    lappend linecoords 0;
		    lappend linecoords [expr (($num_days - $i) * $xscale) - 2];
		    lappend linecoords $sheight;
		    $intop.fca.ca create line $linecoords -fill $color -width 2;
		    #draw vertical line with appropriate color
		    set linecoords {};
		    lappend linecoords 0;
		    lappend linecoords [expr ($yrange - ($trade_price -$ymin)) * $yscale];
		    lappend linecoords [expr $num_days * $xscale];
		    lappend linecoords [expr ($yrange - ($trade_price -$ymin)) * $yscale];
		    $intop.fca.ca create line $linecoords -fill $color -width 2 -activewidth 3 -activefill black;
		    set linecoords {};
		    lappend linecoords [expr (($num_days - $i) * $xscale) - 20];
		    lappend linecoords [expr ($yrange - ($trade_price -$ymin)) * $yscale];
		    lappend linecoords [expr (($num_days - $i) * $xscale) + 20];
		    lappend linecoords [expr ($yrange - ($trade_price -$ymin)) * $yscale];
		    $intop.fca.ca create line $linecoords -fill black -width 3;
		    set start_day $i;
		    break;
		}
	    }
	    set datain [gets $fin];
	}
    close $fin;
    }
    pack $intop.fca.ca;
    pack $intop.fca;
}	    


proc plot_rsi {stock {num_days 365} {nperiods 14} {num_frames 1} {intop .c_rsi}} {
    global dbg;
    set swidth [expr int (1280 * .9)];
    set sheight [expr $::sheight / $num_frames];
    get_all_data $stock;
    set last_sample [expr [array size stock_data] - 1];

    if {![winfo exists $intop]} {toplevel $intop};
    frame $intop.frsi -height $sheight -width $swidth -border 0;
    
    #compute first RS
    set period_gain 0;
    set period_loss 0;
    for {set sample $last_sample} {$sample > [expr $last_sample - $nperiods]} {incr sample -1} {
	set change [expr [get_info cl $stock $stock_data([expr $sample - 1])] \
			- [get_info cl $stock $stock_data($sample)]];
	if {[info exists dbg]} {puts $change};
	if {$change > 0} {
	    set period_gain [expr $period_gain + $change];
	    if {[info exists dbg]} {puts "$sample $period_gain"};
	} else {
	    set period_loss [expr $period_loss + $change];
	    if {[info exists dbg]} {puts "$sample $period_loss"};
	}
    }
    set period_gain [expr $period_gain/$nperiods.0];
    set period_loss [expr $period_gain/$nperiods.0];
    if {$period_loss != 0} {
	set rsi([expr $sample - 2]) [expr 100.0 - (100.0/(1.0 + $period_gain/abs($period_loss)))];
    } else {
	set rsi([expr $sample - 2])  0;
    }
    
    for {set sample $sample} {$sample > 0} {incr sample -1} {
	set change [\
			expr [get_info cl $stock $stock_data([expr $sample - 1])] \
			- [get_info cl $stock $stock_data($sample)]];
	if {[info exists dbg]} {puts $change};
	if {$change > 0} {
	    set period_gain [expr (($period_gain * ($nperiods - 1)) + $change)/$nperiods.0];
	    set period_loss [expr (($period_loss * ($nperiods - 1)) + 0)/$nperiods.0];
	} else {
	    set period_gain [expr (($period_gain * ($nperiods - 1)) + 0)/$nperiods.0];
	    set period_loss [expr (($period_loss * ($nperiods - 1)) + $change)/$nperiods.0];
	}
	if {$period_loss != 0} {
	    set rsi([expr $sample - 1]) [expr 100.0 - (100.0/(1.0 + $period_gain/abs($period_loss)))];
	} else {
	    set rsi([expr $sample - 1])  0;
	}
    }
    if {[info exists ::debug]} {
	for {set sample $last_sample} {$sample > -1} {incr sample -1} {
	    if {[info exists rsi($sample)]} {
		puts "$sample $rsi($sample)";
	    } else {
		puts "$sample 0";
	    }
	}
    }
#######################################################################################
    canvas $intop.frsi.rsi -width $swidth -height $sheight -bg white;

#    set num_days 365;
    set xscale [expr $swidth/($num_days.0 + 2)];
    set yscale [expr $sheight/120.0];


## draw red rectangle in sell range
    $intop.frsi.rsi create rectangle \
	0             0 \
	$swidth       [expr 20 * $yscale] \
	-fill red3;

## draw purple rectangle near sell range
    $intop.frsi.rsi create rectangle \
	0             [expr 20 * $yscale] \
	$swidth       [expr 30 * $yscale] \
	-fill salmon;

## draw green rectangle in buy range
    $intop.frsi.rsi create rectangle \
	0             [expr 80 * $yscale] \
	$swidth       [expr 100 * $yscale] \
	-fill {darkseagreen};

## draw green rectangle in buy range
    $intop.frsi.rsi create rectangle \
	0             [expr 70 * $yscale] \
	$swidth       [expr 80 * $yscale] \
	-fill darkseagreen1;
	

## draw horizontal gridlines every 10 units
    for {set gridline 10} {$gridline < 100} {incr gridline 10} {
	set linecoords {};
	lappend linecoords 0;
	lappend linecoords [expr int((100 - $gridline) * $yscale)]
	lappend linecoords $swidth;
	lappend linecoords [expr int((100 - $gridline) * $yscale)]
	$intop.frsi.rsi create line $linecoords
	$intop.frsi.rsi create text [expr int(5 * $xscale)] [expr int(($gridline - 2) * $yscale)] -text [expr 100 - $gridline];
    }
    set ymin 0;
## draw vertical gridlines every 10 units
    set toggle 0;
    set grid_incr [get_grid_incr $num_days];
    for {set gridline 20} {$gridline < $num_days} {incr gridline $grid_incr} {
	set linecoords {};
	set toggle [expr ($toggle + 1) % 2];
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords 0;
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords $sheight;
	$intop.frsi.rsi create line $linecoords
#	$intop.frsi.rsi create text [expr int(($gridline - 4) * $xscale)] [expr $sheight - 20 + $toggle * 10] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
	$intop.frsi.rsi create text [get_xcoord [expr $gridline -5]] [expr [get_ycoord $ymin] - (7 + $toggle * 12)] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
    }

## put label
    $intop.frsi.rsi create text [expr $swidth - 15 * $xscale] [expr 4 * $yscale] -text $stock -tags stocklabel -font 12;

#    foreach a [array names rsi] {puts "rsi($a) = $rsi($a)"};
    set coords {};
    set asize [array size rsi];
#    for {set i 0} {$i < [expr $asize - 260]} {incr i}  
    for {set i 0} {$i < $num_days} {incr i} { 
	lappend coords [expr int(($num_days - $i) * $xscale) ]  
	lappend coords [expr int((100 - int($rsi($i))) * $yscale)];
    }
    if {[info exists ::debug]} {puts $coords};
    $intop.frsi.rsi create line $coords -tags rsiline -fill black;
 
    pack $intop.frsi.rsi;
    pack $intop.frsi;
    return $rsi(0);
}

proc email_lists {} {
    exec email -m plain -r smtp.comcast.net -b -s buy_list -a buy_list.txt,sell_list.txt -u rtclancy -i 23961644 rtclancy@yahoo.com;
}

proc keep_trying {{iterations 1} {force_go 0}} {
    global stock_list own_list five_stars_list watch_list minus_days;
    set stock_list [remove_duplicates $stock_list];
    puts "Retrieving data for [llength $stock_list] stocks";
    set stock_list [update_list $stock_list];
    stock_sort_alpha;
    set stock_list_length [llength $stock_list];
    set iteration 0;
    while {$stock_list_length > 0 && $iteration < $iterations} {
	set hour [clock format [clock seconds] -format %H];
	set min  [clock format [clock seconds] -format %M];
	if {$hour > 18 || $minus_days > 0 || $force_go} {
	    if {$min > 30 || $hour > 19 || $minus_days > 0 || $force_go} { 
		catch [set stock_list [get_quotes_historical $stock_list]];
		set stock_list_length [llength $stock_list];
		incr iteration;
		puts "Iteration $iteration";
	    } else {
		puts "Quotes not available yet [clock format [clock seconds] -format %D]";
	    }
	}
	after 10000;
    }
#    if {[llength $stock_list] == 0} 
     if {1} {
	set stock_list [concat $own_list $five_stars_list $watch_list]
	set stock_list [remove_duplicates $stock_list];
	stock_sort_alpha;
	get_tech $stock_list
    } else {
	gui_puts "Not all stock data retrieved. Retrieval failed for the following stocks\n$stock_list";
	return $stock_list;
    }
    gui_puts "Keep trying has completed";
    return 0;
}

proc file_num_lines {fname} {
    set nlines [lindex [file_lcount $fname] 0s];
    return $nlines;
}
set gui 0;
#stock_gui

proc c_calc_rsi {stock} {
#    puts [exec date];
#    puts [lindex [file_lcount ../historical_data/$stock.dat] 0];
    return [exec  ../c_dir/c_calc_rsi.exe [lindex [file_lcount ../historical_data/$stock.dat] 0] ../historical_data/$stock.dat];
#    puts [exec date];
}

proc c_calc_sma {stock ndays} {
#    puts [exec date];
#    puts [lindex [file_lcount ../historical_data/$stock.dat] 0];
    return [exec  ../c_dir/c_calc_sma.exe [lindex [file_lcount ../historical_data/$stock.dat] 0] ../historical_data/$stock.dat $ndays];
#    puts [exec date];
}

proc c_calc_sma_volume {stock ndays} {
#    puts [exec date];
#    puts [lindex [file_lcount ../historical_data/$stock.dat] 0];
    return [exec  ../c_dir/c_calc_sma_volume.exe [lindex [file_lcount ../historical_data/$stock.dat] 0] ../historical_data/$stock.dat $ndays];
#    puts [exec date];
}

proc c_calc_mfi {stock} {
#    puts [exec date];
#    puts [lindex [file_lcount ../historical_data/$stock.dat] 0];
    return [exec  ../c_dir/c_calc_mfi.exe [lindex [file_lcount ../historical_data/$stock.dat] 0] ../historical_data/$stock.dat];
#    puts [exec date];
}

proc t_calc_rsi {stock} {
    puts [exec date];
    puts [lindex [file_lcount ../historical_data/$stock.dat] 0];
    puts [calc_rsi $stock];
    puts [exec date];
}

proc walk_thru {{num_days 270}} {
    global bs_list index;
    if {![info exists index]} {set index 0};
    plot_stock [lindex $bs_list $index] $num_days;
}


proc plot_stock {stock {num_days 60}} {
    global index;
    if {![winfo exists .stocktop]} {
	toplevel .stocktop;
	button .stocktop.button -text next -command "incr index; walk_thru $num_days;"
	button .stocktop.button2 -text previous -command "incr index -1; walk_thru $num_days;"
	pack .stocktop.button;
	pack .stocktop.button2;
    };
    destroy .stocktop.frsi;
    plot_rsi     $stock $num_days 14  3 .stocktop;
    destroy .stocktop.fca;
    plot_candles $stock $num_days     3 .stocktop;
    destroy .stocktop.fvol;
    plot_volume $stock $num_days     12 .stocktop;
    destroy .stocktop.fmacd;
    plot_macd    $stock $num_days     3 .stocktop;
    
}

proc do_all {} {
    global stock_list own_list watch_list five_stars_list;
    source ../lists/own_list.tcl; set stock_list $own_list;
    source ../lists/watch_list.tcl; set stock_list $watch_list;
    source ../lists/five_stars_list.tcl; set stock_list $five_stars_list;
    set stock_list [concat $own_list $five_stars_list $watch_list]
    keep_trying 1;
}

proc parse_5stars {} {
    set fin [open ../lists/five_stars_list.txt r];
    set fout [open ../lists/five_stars_list.tcl a];
    puts $fout "\# [clock format [clock seconds]]";
    puts $fout "lappend five_stars_list \\";
    while {![eof $fin]} {
	gets $fin linein;
	regexp {(^[^ ]+)} $linein tmp symbol;
	puts $symbol;
        puts $fout "$symbol \\";
    }
    puts $fout ";";
    close $fout;
    close $fin;
}

proc clist {} {
    set ::index 0;
    uplevel #0 source ../lists/current_list.tcl
}
proc clist {} {
    uplevel #0 source ../lists/current_list.tcl
    set ::index 0;
    set ::bs_list $::current_list;
    unset ::index;
    walk_thru;    
}

proc current_state {} {
    uplevel #0 source ../lists/current_list.tcl
    set total_long 0;
    set total_short 0;
    foreach stock $::current_list {
	set fin [open ../trading_history/$stock.dat];
	while {![eof $fin]} {
	    set datain [gets $fin];
	    set postype [lindex $datain 1];
	    set numshares [lindex $datain 2];
	    set value [lindex $datain 3];
	    set isopen [lindex $datain 4];
	    if {$isopen == "open"} {
		if {$postype == "bl"} {set total_long [expr $total_long + $value]};
		if {$postype == "ss"} {set total_short [expr $total_short + $value]};
	    }
	}
    }
    set total [expr $total_long + $total_short];
    set item 1;
    foreach stock $::current_list {
	set fin [open ../trading_history/$stock.dat];
	while {![eof $fin]} {
	    set datain [gets $fin];
	    set postype [lindex $datain 1];
	    set numshares [lindex $datain 2];
	    set value [lindex $datain 3];
	    set isopen [lindex $datain 4];
	    if {$isopen == "open"} {
		if {$postype == "bl"} {puts "$item\t$stock\tlong\t[format %.2f [expr 100.0 * $value/$total]] %\t\t+$numshares"};
		if {$postype == "ss"} {puts "$item\t$stock\tshort\t[format %.2f [expr 100.0 * $value/$total]] %\t\t-$numshares"};
		incr item;
	    }
	}
    }


    puts "__________________________";
    puts "Total Long = \t$total_long\t\t[format %.2f [expr 100.0 * $total_long/$total]] % ";
    puts "Total Short = \t$total_short\t\t[format %.2f [expr 100.0 * $total_short/$total]] % ";
    puts "__________________________";
    puts "Total = \t$total";
}     

proc file_lcount {filename} {
    set fin [open $filename r];
    set time1 [clock clicks -milliseconds];
    set linecount -1;
    while {![eof $fin]} {
	gets $fin;
	incr linecount;
    }
    set time2 [clock clicks -milliseconds];
    if {[info exists ::debug]} {
	puts "elapsed time = [expr $time2 - $time1] milliseconds";
    }
    close $fin;
    return $linecount;
}
proc get_grid_incr {max} {
    set grid_incr 1;
    for {set exp 1} {$exp < 10} {incr exp} {
	if {[expr $max > 5e$exp]} {set grid_incr 1e$exp}
    }
    return [expr int($grid_incr)];
}
proc vertical_gridlines {canvas_name xmax xscale sheight ymin} {
    set toggle 0;
    set grid_incr [get_grid_incr $xmax];
    wvar grid_incr stall;
    for {set gridline 20} {$gridline < $xmax} {incr gridline $grid_incr} {
	set toggle [expr ($toggle + 1) % 2];
	set linecoords {};
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords 0;
	lappend linecoords [expr int(($gridline) * $xscale)]
	lappend linecoords $sheight;
	$intop.fca.ca create line $linecoords -fill grey
#	$intop.fca.ca create text [expr int(($gridline - 4) * $xscale)] [expr $sheight - 20 + $toggle * 11] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
	$intop.fca.ca create text [get_xcoord [expr $gridline -5]] [expr [get_ycoord $ymin] - (7 + $toggle * 12)] -text [get_info da $stock $stock_data([expr $num_days - $gridline])];
    }
}

proc remove_l0s {decimal_number} {
    set nlist [split $decimal_number {}];
    set nlist_length [llength $nlist];
    set result {};
    set first_nonzero_found 0;
    for {set i 0} {$i < $nlist_length} {incr i} {
	#puts [lindex $nlist $i] ;
	if {[lindex $nlist $i] || $first_nonzero_found} {
	    lappend result [lindex $nlist $i]
	    set first_nonzero_found 1;
	};
    }
    return [join $result {}];
}

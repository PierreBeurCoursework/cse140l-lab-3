// test bench 2 for Lab 3 part 2 with independent left/straight
// CSE140L   
// expanded version -- try the simpler traffic_tb first if
//  you do not pass this one
// 
import light_package ::*;
module lab3_part2_tb_enum;

bit     clk           ;	                  
logic   reset = 'b1   ;		 	  // should put your design in all-red
bit     e_left_sensor ,		      // e-bound left turn traffic 
	    e_str_sensor  ,	          // e-bound thru traffic 
	    w_left_sensor ,		      // w-bound left turn traffic
	    w_str_sensor  ,           // w-bound thru traffic
	    ns_sensor     ;           // traffic on n-s street
colors  e_left_light  ,           // left arrow e turn onto n
	    e_str_light   ,	          // straight ahead e
		w_left_light  ,           // left arrow w turn onto s
		w_str_light   ,           // straight ahead w
	    ns_light;	              // n-s (no left/thru differentiation)

// your controller goes here
// input ports = logics above, with name changes noted
// output ports = wires above (each 2 bits wide)
traffic_light_controller dut(.e_straight_sensor(e_str_sensor), 
  .w_straight_sensor(w_str_sensor), 
  .e_left_sensor, .w_left_sensor, .ns_sensor, .clk(clk), 
  .reset, .e_str_light, .w_str_light, .e_left_light, .w_left_light, .ns_light);

colors e_l, e_s, w_l, w_s, ns;	  // red, yellow, green for each of 5 directions
assign e_l = e_left_light;		  // just shorthand names for these
assign e_s = e_str_light ;
assign w_l = w_left_light;
assign w_s = w_str_light ;
assign ns  = ns_light    ;

int fl, gl = 4;                      // handle for target file
int test_cnt;                     // lets testbench count number of test scenarios
initial begin
  fl = $fopen("result.txt","w");
  gl = $fopen("result2.txt","w");
  $fdisplay(fl,"t   t   t   t   t    e    e    w    w    n");	   // header for y, g status display
  $fdisplay(fl,"e   e   w   w   n    s    l    s    l    s");
  $fdisplay(fl,"s   l   s   l                             ");

  #20ns reset    = 1'b0;
  #10ns;
// Test E_LEFT to W_STR without more traffic
  test_cnt++                 ;
  e_left_sensor        = 1'b1 ;
  #30ns  w_left_sensor = 1'b1 ; 
  #60ns  e_left_sensor = 1'b0 ;
  #20ns  e_str_sensor  = 1'b1 ;
  #30ns  w_str_sensor  = 1'b1 ; 
  #100ns e_str_sensor  = 1'b0 ;
  #10ns  w_str_sensor  = 1'b0;
  #200ns;

// Now set traffic at NS. Green NS lasts past sensor falling
  test_cnt++                  ;
  ns_sensor           = 1'b1  ;
  #60ns ns_sensor     = 1'b0  ;
  #200ns;

// Check NS again, but hold for more than 5 cycles.  
//   NS should cycle green-yellow-red when side traffic appears
  test_cnt++;
  ns_sensor              = 1'b1;
  #100ns e_left_sensor   = 1'b1;
  #200ns ns_sensor       = 1'b0;
  #20ns  e_left_sensor   = 1'b0;

// All five sensors become 1 at once.  
//  EW_LEFT should come first, then STR, then NS
  test_cnt++;
  e_left_sensor  = 1'b1;
  e_str_sensor   = 1'b1;
  w_left_sensor  = 1'b1;
  w_str_sensor   = 1'b1;
  ns_sensor      = 1'b1;
  #1000ns;
  w_left_sensor  = 1'b0;
  #200ns;
  e_str_sensor   = 1'b0;
  ns_sensor      = 1'b0;
  #40ns;
  w_str_sensor   = 1'b0;
  #20ns;
  e_left_sensor  = 1'b0;

// All
  test_cnt++;
  $fdisplay(fl,"");
  $fdisplay(fl,"count = %d",test_cnt);
  $fclose(fl);
  $fclose(gl);
  $stop;
end                      

always begin
  #5ns clk = 1'b1;	 
  #3ns clk = 1'b0;
// print yellow and green states on transcript
  if(e_str_sensor)
    $fwrite(fl,"es  ");
  else
    $fwrite(fl,"    ");
  if(e_left_sensor)
    $fwrite(fl,"el  ");
  else
    $fwrite(fl,"    ");
  if(w_str_sensor)
    $fwrite(fl,"ws  ");
  else
    $fwrite(fl,"    ");
  if(w_left_sensor)
    $fwrite(fl,"wl  ");
  else
    $fwrite(fl,"    ");
  if(ns_sensor)
    $fwrite(fl,"ns  ");
  else
    $fwrite(fl,"    ");

  case(e_s)
	green:   $fwrite(fl,"esg  ");
	yellow:	 $fwrite(fl,"esy  ");
	default: $fwrite(fl,"     ");
  endcase
  case(e_l)
	green:   $fwrite(fl,"elg  ");
	yellow:	 $fwrite(fl,"ely  ");
	default: $fwrite(fl,"     ");
  endcase
  case(w_s)
	green:   $fwrite(fl,"wsg  ");
	yellow:	 $fwrite(fl,"wsy  ");
	default: $fwrite(fl,"     ");
  endcase
  case(w_l)
	green:   $fwrite(fl,"wlg  ");
	yellow:	 $fwrite(fl,"wly  ");
	default: $fwrite(fl,"     ");
  endcase
  case(ns)
    green:   $fdisplay(fl,"nsg  %t",$time);
	yellow:  $fdisplay(fl,"nsy  %t",$time);
	default: $fdisplay(fl,"     %t",$time);
  endcase
  if(e_left_light && (w_str_light || ns_light)) $fdisplay(fl,"*****error*****");
  if(w_left_light && (e_str_light || ns_light)) $fdisplay(fl,"*****error*****");
  if(w_str_light && ns_light)  				    $fdisplay(fl,"*****error*****");
  if(e_str_light && ns_light)                   $fdisplay(fl,"*****error*****");

/*  case({ew_left_light,ew_str_light,ns_light})
    6'b00_00_00: $display("           %t",$time);
	6'b01_00_00: $display("y          %t",$time);
	6'b10_00_00: $display("g          %t",$time);
	6'b00_01_00: $display("   y       %t",$time);
	6'b00_10_00: $display("   g       %t",$time);
	6'b00_00_01: $display("       y   %t",$time);
	6'b00_00_10: $display("       g   %t",$time);
	default    : $display("***ERROR** %t",$time);
  endcase 	 */
  #2ns;// clk = 1'b0;
end

endmodule

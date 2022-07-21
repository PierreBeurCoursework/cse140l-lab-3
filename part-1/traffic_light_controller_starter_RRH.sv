// traffic light controller
// CSE140L 3-street, 12-state version; EW straights coupled; EW lefts coupled
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// green-to-yellow 5 cycles after own traffic disappears
// 10 max cycles for green if conflicting traffic appears
// starter (shell) -- you need to complete the always_comb logic
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller(
  input clk, reset, ew_str_sensor, ew_left_sensor, ns_sensor,  // traffic sensors, east-west straight, east-west left, north-south 
  output colors ew_str_light, ew_left_light, ns_light);     // traffic lights, east-west straight, east-west left, north-south

// HRR = red-red following YRR; RRH = red-red following RRY;
// ZRR = 2nd cycle yellow, follows YRR, etc.
  typedef enum {GRR, YRR, ZRR, HRR, RGR, RYR, RZR, RHR, RRG, RRY, RRZ, RRH} tlc_states;
  tlc_states    present_state, next_state;
  integer ctr5, next_ctr5,       //  5 sec timeout when my traffic goes away
          ctr10, next_ctr10;     // 10 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
    if(reset) begin
      present_state <= RRH;        // so that EWS has top priority after reset
      ctr5          <= 0;
      ctr10         <= 0;
    end
    else begin
      present_state <= next_state;
      ctr5          <= next_ctr5;
      ctr10         <= next_ctr10;
    end

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
    next_state = HRR;            // default to reset state
    next_ctr5  = 0;
    next_ctr10 = 0;
    case(present_state)
/* ************* Fill in the case statements ************** */
/* suggestion: I used a 5-counter and a 10-counter to time my green states
     if the 10-counter > a particular threshold & conflicting traffic present --> yellow
     else if 5-counter > a particular threshold & my own traffic disappeared --> yellow
     increment 5-counter whenever my own traffic is absent
     increment 10-counter whenever I have a green light
*/
      GRR: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!ew_str_sensor || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (ew_left_sensor || ns_sensor || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? YRR : GRR;
      end
      YRR: begin
        next_ctr5  =   0; // reset counters
        next_ctr10 =   0;
        next_state = ZRR;
      end
      ZRR: begin
        next_state = HRR;
      end
      HRR: begin
             if (ew_left_sensor) next_state = RGR;
        else if (     ns_sensor) next_state = RRG;
        else if ( ew_str_sensor) next_state = GRR;
        else                     next_state = HRR;
      end
      RGR: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!ew_left_sensor || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (ns_sensor || ew_str_sensor || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? RYR : RGR;
      end
      RYR: begin
        next_ctr5  =   0; // reset counters
        next_ctr10 =   0;
        next_state = RZR;
      end
      RZR: begin
        next_state = RHR;
      end
      RHR: begin
             if (     ns_sensor) next_state = RRG;
        else if ( ew_str_sensor) next_state = GRR;
        else if (ew_left_sensor) next_state = RGR;
        else                     next_state = RHR;
      end
      RRG: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!ns_sensor || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (ew_str_sensor || ew_left_sensor || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? RRY : RRG;
      end
      RRY: begin
        next_ctr5  =   0; // reset counters
        next_ctr10 =   0;
        next_state = RRZ;
      end
      RRZ: begin
        next_state = RRH;
      end
      RRH: begin
             if ( ew_str_sensor) next_state = GRR;
        else if (ew_left_sensor) next_state = RGR;
        else if (     ns_sensor) next_state = RRG;
        else                     next_state = RRH;
      end
    endcase
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
  always_comb begin
     ew_str_light = red;                // cover all red plus undefined cases
    ew_left_light = red;
         ns_light = red;
    case(present_state)      // Moore machine
      GRR:      ew_str_light = green;
      YRR,ZRR:  ew_str_light = yellow;  // my dual yellow states -- brute force way to make yellow last 2 cycles
      RGR:     ew_left_light = green;
      RYR,RZR: ew_left_light = yellow;
      RRG:          ns_light = green;
      RRY,RRZ:      ns_light = yellow;
    endcase
  end

endmodule
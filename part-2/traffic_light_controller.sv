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
  input         clk, reset,
                e_left_sensor,  // traffic sensors
                 e_str_sensor,
                w_left_sensor,
                 w_str_sensor,
                    ns_sensor,
  output colors e_left_light ,  // traffic lights
                 e_str_light ,
                w_left_light ,
                 w_str_light ,
                    ns_light );

// HRR = red-red following YRR; RRH = red-red following RRY;
// ZRR = 2nd cycle yellow, follows YRR, etc.
  typedef enum {GRRRR, YRRRR, ZRRRR, HRRRR,
                RGRRR, RYRRR, RZRRR, RHRRR,
                RRGRR, RRYRR, RRZRR, RRHRR,
                RRRGR, RRRYR, RRRZR, RRRHR,
                RRRRG, RRRRY, RRRRZ, RRRRH} tlc_states;
  tlc_states    present_state, next_state;
  integer ctr5,  next_ctr5,      //  5 sec timeout when my traffic goes away
          ctr10, next_ctr10;     // 10 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
    if(reset) begin
      present_state <= RRRRH;      // so that EWS has top priority after reset
      ctr5          <= 0;
      ctr10         <= 0;
    end
    else begin
      present_state <= next_state;
      ctr5          <= next_ctr5;
      ctr10         <= next_ctr10;
    end

logic s_sn, e_sn, w_sn, l_sn, n_sn;

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
    next_state = HRRRR;          // default to reset state
    next_ctr5  = 0;
    next_ctr10 = 0;
    
    s_sn =  e_str_sensor &&  w_str_sensor ;
    e_sn = e_left_sensor &&  e_str_sensor ;
    w_sn = w_left_sensor &&  w_str_sensor ;
    l_sn = e_left_sensor && w_left_sensor ;
    n_sn = ns_sensor;

    case(present_state)
/* ************* Fill in the case statements ************** */
/* suggestion: I used a 5-counter and a 10-counter to time my green states
     if the 10-counter > a particular threshold & conflicting traffic present --> yellow
     else if 5-counter > a particular threshold & my own traffic disappeared --> yellow
     increment 5-counter whenever my own traffic is absent
     increment 10-counter whenever I have a green light
*/
      GRRRR: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!s_sn || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (e_sn || w_sn || l_sn || n_sn || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? YRRRR : GRRRR;
      end
      YRRRR: next_state = ZRRRR;
      ZRRRR: next_state = HRRRR;
      HRRRR: begin
             if (e_sn) next_state = RGRRR;
        else if (w_sn) next_state = RRGRR;
        else if (l_sn) next_state = RRRGR;
        else if (n_sn) next_state = RRRRG;
        else           next_state = HRRRR;
      end
      RGRRR: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!e_sn || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (w_sn || l_sn || n_sn || s_sn || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? RYRRR : RGRRR;
      end
      RYRRR: next_state = RZRRR;
      RZRRR: next_state = RHRRR;
      RHRRR: begin
             if (w_sn) next_state = RRGRR;
        else if (l_sn) next_state = RRRGR;
        else if (n_sn) next_state = RRRRG;
        else if (s_sn) next_state = GRRRR;
        else           next_state = RHRRR;
      end
      RRGRR: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!w_sn || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (l_sn || n_sn || s_sn || e_sn || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? RRYRR : RRGRR;
      end
      RRYRR: next_state = RRZRR;
      RRZRR: next_state = RRHRR;
      RRHRR: begin
             if (l_sn) next_state = RRRGR;
        else if (n_sn) next_state = RRRRG;
        else if (s_sn) next_state = GRRRR;
        else if (e_sn) next_state = RGRRR;
        else           next_state = RRHRR;
      end
      RRRGR: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!l_sn || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (n_sn || s_sn || e_sn || w_sn || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? RRRYR : RRRGR;
      end
      RRRYR: next_state = RRRZR;
      RRRZR: next_state = RRRHR;
      RRRHR: begin
             if (n_sn) next_state = RRRRG;
        else if (s_sn) next_state = GRRRR;
        else if (e_sn) next_state = RGRRR;
        else if (w_sn) next_state = RRGRR;
        else           next_state = RRRHR;
      end
      RRRRG: begin
        // start ctr5 when a gap in traffic is detected
        next_ctr5  = ctr5  + (!n_sn || ctr5 > 0);
        // start ctr10 when cross traffic is detected
        next_ctr10 = ctr10 + (s_sn || e_sn || w_sn || l_sn || ctr10 > 0);
        // go to yellow when either ctr ends
        next_state = (next_ctr5 == 5 || next_ctr10 == 10) ? RRRRY : RRRRG;
      end
      RRRRY: next_state = RRRRZ;
      RRRRZ: next_state = RRRRH;
      RRRRH: begin
             if (s_sn) next_state = GRRRR;
        else if (e_sn) next_state = RGRRR;
        else if (w_sn) next_state = RRGRR;
        else if (l_sn) next_state = RRRGR;
        else           next_state = RRRRH;
      end
    endcase
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
  always_comb begin
    e_left_light = red;                 // cover all red plus undefined cases
     e_str_light = red;
    w_left_light = red;
     w_str_light = red;
        ns_light = red;
    case(present_state)      // Moore machine
      GRRRR: begin
          e_str_light = green;
          w_str_light = green;
        end
      YRRRR,ZRRRR: begin
          e_str_light = yellow;
          w_str_light = yellow;
        end
      RGRRR: begin
          e_left_light = green;
           e_str_light = green;
        end
      RYRRR,RZRRR: begin
          e_left_light = yellow;
           e_str_light = yellow;
        end
      RRGRR: begin
          w_left_light = green;
           w_str_light = green;
        end
      RRYRR,RRZRR: begin
          w_left_light = yellow;
           w_str_light = yellow;
        end
      RRRGR: begin
          e_left_light = green;
          w_left_light = green;
        end
      RRRYR,RRRZR: begin
          e_left_light = yellow;
          w_left_light = yellow;
        end
      RRRRG: begin
          ns_light = green;
        end
      RRRRY,RRRRZ: begin
          ns_light = yellow;
        end
    endcase
  end

endmodule
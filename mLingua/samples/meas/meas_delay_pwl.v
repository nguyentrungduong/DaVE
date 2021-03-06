/****************************************************************

Copyright (c) 2018- Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : meas_delay_pwl.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: It measures the delay from "in1" transition to "in2"
  transition.

* Note       :
  - inputs are in 'pwl' for SVerilog. c.f.) meas_delay.v

* Revision   :
  - 7/26/2016: First release
  - 12/16/2016: Bug fix. The output is updated incorrectly when
    input clock frequencies are different.

****************************************************************/

`timescale `DAVE_TIMEUNIT / `DAVE_TIMEUNIT

///////////
`ifndef AMS // NOT AMS
///////////


module meas_delay_pwl #(
  parameter in1_dir = 1'b1,   // trigger rise(1), fall(0) of in1
  parameter in2_dir = 1'b1,   // trigger rise(1), fall(0) of in2
  parameter real vlth1 = 0.5, // logic threshold of in1 in proportion to vdd
                              // valid only for Verilog-AMS
  parameter real vlth2 = 0.5, // logic threshold of in2 in proportion to vdd
                              // valid only for Verilog-AMS
  parameter real scale = 1    // scale the output by this number
) (
  `input_pwl in1, in2,
  `input_pwl vdd,
  `output_pwl delay
  );

`get_timeunit
PWLMethod pm=new;


reg i_in1, i_in2;
reg triggered=1'b0;
logic in1_d, in2_d;
pwl os1, os2;

pwl_vga uOS1 ( .scale(vlth1), .in(vdd), .out(os1) );
pwl_vga uOS2 ( .scale(vlth2), .in(vdd), .out(os2) );
pwl_slicer_prim uSL1 (.offset(os1), .vin(in1), .out(in1_d));
pwl_slicer_prim uSL2 (.offset(os2), .vin(in2), .out(in2_d));

assign i_in1 = in1_dir? in1_d : ~in1_d;
assign i_in2 = in2_dir? in2_d : ~in2_d;

real ts;

always @(posedge i_in1) 
  if (!triggered) begin
    ts = `get_time;
    triggered = 1'b1;
  end

always @(posedge i_in2) begin
  if (triggered) delay= pm.write((`get_time - ts)*scale, 0.0, 0.0);
  triggered = 1'b0;
end

endmodule


///////////
`else // AMS
///////////


`include "disciplines.vams"

module meas_delay_pwl #(
  parameter in1_dir = 1'b1,   // trigger rise(1), fall(0) of in1
  parameter in2_dir = 1'b1,   // trigger rise(1), fall(0) of in2
  parameter real vlth1 = 0.5, // logic threshold of in1 in proportion to vdd
  parameter real vlth2 = 0.5, // logic threshold of in2 in proportion to vdd
  parameter real scale = 1    // scale the output by this number
) (
  input in1, in2, vdd,
  output delay
  );

electrical in1, in2, vdd, delay;

reg i_in1, i_in2;
reg triggered=1'b0;
real ts;
real r_delay;

always @(cross(V(in1)-V(vdd)*vlth1,+1)) i_in1 = in1_dir? 1'b1:1'b0;
always @(cross(V(in1)-V(vdd)*vlth1,-1)) i_in1 = in1_dir? 1'b0:1'b1;
always @(cross(V(in2)-V(vdd)*vlth2,+1)) i_in2 = in2_dir? 1'b1:1'b0;
always @(cross(V(in2)-V(vdd)*vlth2,-1)) i_in2 = in2_dir? 1'b0:1'b1;


analog begin
  V(delay) <+ scale*r_delay;
end

always @(posedge i_in1) 
  if (!triggered) begin
    ts = $abstime;
    triggered = 1'b1;
  end

always @(posedge i_in2) begin
  if (triggered) r_delay = $abstime - ts;
  triggered = 1'b0;
end

endmodule


///////////
`endif
///////////

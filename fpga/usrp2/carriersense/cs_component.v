`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Trinity College, Virgina Tech
// Engineer: Séamas Mcgettrick (v2) Kevin Anyanwu (V1)
// 
// Create Date:    08:00:15 07/14/2011 
// Design Name: 
// Module Name:    cs_component 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
// 
// Revision: 
// Revision 0.02 - Updates to make sliding window
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module cs_component( 
input clk,
input rst,
input        set_stb_user,
input [7:0]  set_addr_user,
input [31:0] set_data_user,
input [15:0] real_value,
input [15:0] img_value,
input strobe,
input run,
output present_next
);

localparam CS_ENABLE = 66;
localparam CS_THRESHOLD = 67;

wire [3:0] state;
wire enable_cs;
wire [31:0] cs_threshold;

setting_reg #(.my_addr(CS_ENABLE), .width(1), .at_reset(32'd1)) enable_cs_component
     (.clk(clk),.rst(rst),.strobe(set_stb_user),.addr(set_addr_user),
      .in(set_data_user),.out(enable_cs));
		
setting_reg #(.my_addr(CS_THRESHOLD), .width(32),.at_reset(32'd100)) set_cs_threshold
     (.clk(clk),.rst(rst),.strobe(set_stb_user),.addr(set_addr_user),
      .in(set_data_user),.out(cs_threshold));
	
// Magnitude signal
wire [15:0] x_out_mag;
// magnitude ready signal
wire rdy_mag;

// First thing we do is get the magnitude of the signal
cordic_in get_iq_magnitude (
.x_in(real_value), // The Real component
.y_in(img_value), // The Imanginary component of signal
.nd(strobe&run), // new value on input at every strobe signal
.ce(1), //always enabled
.x_out(x_out_mag), // ouput [17 : 0] x_out
.rdy(rdy_mag), // driven high when magnitude of i and q has been calculated. logic high of this signal also signifies i and q registers to output next i and q.
.sclr(rst),
.clk(clk)); // input clk


// Now we instanciate the averaging component	
wire [31:0] average;

average_component  sliding_average (
		//INPUTS
		.x_out_mag(x_out_mag), 
      .data_in_valid(rdy_mag),		
		.clk(clk), 
		.rst(rst),
		.average(average) );
		
		
// Now compare average to Threshold
comparator_component threshold_test(.clk (clk),
												.rst (rst),
												.threshold(cs_threshold),
												.average(average),
												.run_rx0(run),
												.enable(enable_cs),
												.carrier_present(carrier_present)
												);
// assign the carrier present signal to the output		
assign present_next =carrier_present;		


endmodule

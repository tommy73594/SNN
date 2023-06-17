`timescale 1ns/100ps
import SystemVerilogCSP::*;

module data_generator (interface r);
	parameter WIDTH = 8;
	parameter FL = 0;
	logic [WIDTH-1:0] SendValue;
	
	always begin
		SendValue = $random() % (2**WIDTH);
		#FL;
		r.Send(SendValue);
	end
endmodule

module data_bucket (interface r);
	parameter WIDTH = 8;
	parameter BL = 0;
   logic [WIDTH-1:0] ReceiveValue = 0;
	
	always begin
		r.Receive(ReceiveValue);
		#BL;
	end
endmodule


module adder_tb;

  Channel #(.hsProtocol(P4PhaseBD)) intf [6:0] ();
  parameter FL = 2;
  parameter BL = 2;
  parameter WIDTH = 8;
  data_generator  #(.WIDTH(5), .FL(0)) dg1(.r(intf[0])); 
  data_generator  #(.WIDTH(5), .FL(0)) dg2(.r(intf[1])); 
  data_generator  #(.WIDTH(5), .FL(0)) dg3(.r(intf[2])); 
  data_generator  #(.WIDTH(5), .FL(0)) dg4(.r(intf[3])); 
  adder_T #(.WIDTH(8), .FL(FL), .BL(BL)) adder(.PE0_Data(intf[0]), .PE1_Data(intf[1]), .PE2_Data(intf[2]), .Membrane_in_Data(intf[3]), .Membrane_out(intf[5]), .spike_out(intf[6]));

  data_bucket  #(.WIDTH(6), .BL(0)) db1(.r(intf[5])); 
  data_bucket  #(.WIDTH(1), .BL(0)) db2(.r(intf[6]));
  
  
  initial
	#3000 $stop;
  
endmodule

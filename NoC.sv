`timescale 1ns/1fs
import SystemVerilogCSP::*;

module NoC(interface mem_in, mem_out, pe0_in, pe0_out, pe1_in, pe1_out, pe2_in, pe2_out, adder_in, adder_out);
    parameter FL = 2;
    parameter BL = 1;
    parameter WIDTH = 35;
	  parameter WIDTH_ADDR = 3;
    
    Channel #(.WIDTH(WIDTH), .hsProtocol(P4PhaseBD)) intf[58:0] ();

    router #(.WIDTH(WIDTH), .WIDTH_ADDR(WIDTH_ADDR), .MASK(3'b100), .ADDRESS(3'b000), .FL(FL), .BL(BL)) rf1(.P_in(mem_in), .P_out(mem_out), .C1_in(intf[2]), .C1_out(intf[3]), .C2_in(intf[4]), .C2_out(intf[5]));
    router #(.WIDTH(WIDTH), .WIDTH_ADDR(WIDTH_ADDR), .MASK(3'b110), .ADDRESS(3'b000), .FL(FL), .BL(BL)) rf2(.P_in(intf[3]), .P_out(intf[2]), .C1_in(adder_in), .C1_out(adder_out), .C2_in(pe0_in), .C2_out(pe0_out));
    router #(.WIDTH(WIDTH), .WIDTH_ADDR(WIDTH_ADDR), .MASK(3'b110), .ADDRESS(3'b010), .FL(FL), .BL(BL)) rf3(.P_in(intf[5]), .P_out(intf[4]), .C1_in(pe1_in), .C1_out(pe1_out), .C2_in(pe2_in), .C2_out(pe2_out));
endmodule
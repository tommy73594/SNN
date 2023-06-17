`timescale 1ns/1fs
import SystemVerilogCSP::*;

module SNN ();
    parameter WIDTH = 35;


    Channel #(.WIDTH(WIDTH), .hsProtocol(P4PhaseBD)) intf[58:0] ();

    NoC n1(.mem_in(intf[0]), .mem_out(intf[1]), .pe0_in(intf[8]), .pe0_out(intf[9]), .pe1_in(intf[10]), .pe1_out(intf[11]), .pe2_in(intf[12]), .pe2_out(intf[13]), .adder_in(intf[6]), .adder_out(intf[7]));
    memory_wrapper memory_wrapper( .toMemRead(intf[14]), .toMemWrite(intf[15]), .toMemT(intf[16]), .toMemX(intf[17]), .toMemY(intf[18]), .toMemSendData(intf[19]), .fromMemGetData(intf[20]), 
	                                 .toNOC(intf[0]), .fromNOC(intf[1]));
	memory  memory( .read(intf[14]), .write(intf[15]), .T(intf[16]), .x(intf[17]), .y(intf[18]), .data_in(intf[19]), .data_out(intf[20]));
	
    depacketizer_pe #(.PE_ADDR(3'b001)) de_pe0(.in(intf[9]), .ifmap_addr(intf[22]), .ifmap_data(intf[23]), .filter_addr(intf[24]), .filter_data(intf[25]), .start(intf[29]), .pe2_done2(intf[56]));
	pe #(.WIDTH(8), .thisAddr(3'b001)) pe0(.filter_in(intf[25]), .filter_addr(intf[24]), .ifmap_in(intf[23]), .ifmap_addr(intf[22]), .start(intf[29]), .psum_out(intf[26]), .toP_addr(intf[27]), .toP_data(intf[28]), .pe2_done(intf[53]));
	packetizer_pe #(.WIDTH(WIDTH), .PE_ADDR(3'b001), .FL(1), .BL(1)) pe0_packetizer(.ifmap_addr(intf[27]), .ifmap_data(intf[28]), .psum(intf[26]), .toNOC(intf[8]), .pe2_done(intf[53]), .pe2_done2(intf[56]));

	depacketizer_pe #(.PE_ADDR(3'b010)) de_pe1(.in(intf[11]), .ifmap_addr(intf[30]), .ifmap_data(intf[31]), .filter_addr(intf[32]), .filter_data(intf[33]), .start(intf[37]), .pe2_done2(intf[57]));
	pe #(.WIDTH(8), .thisAddr(3'b010)) pe1(.filter_in(intf[33]), .filter_addr(intf[32]), .ifmap_in(intf[31]), .ifmap_addr(intf[30]), .start(intf[37]), .psum_out(intf[34]), .toP_addr(intf[35]), .toP_data(intf[36]), .pe2_done(intf[54]));
	packetizer_pe #(.WIDTH(WIDTH), .PE_ADDR(3'b010), .FL(1), .BL(1)) pe1_packetizer(.ifmap_addr(intf[35]), .ifmap_data(intf[36]), .psum(intf[34]), .toNOC(intf[10]), .pe2_done(intf[54]), .pe2_done2(intf[57]));

	depacketizer_pe #(.PE_ADDR(3'b011)) de_pe2(.in(intf[13]), .ifmap_addr(intf[38]), .ifmap_data(intf[39]), .filter_addr(intf[40]), .filter_data(intf[41]), .start(intf[45]), .pe2_done2(intf[58]));
	pe #(.WIDTH(8), .thisAddr(3'b011)) pe2(.filter_in(intf[41]), .filter_addr(intf[40]), .ifmap_in(intf[39]), .ifmap_addr(intf[38]), .start(intf[45]), .psum_out(intf[42]), .toP_addr(intf[43]), .toP_data(intf[44]), .pe2_done(intf[55]));
	packetizer_pe #(.WIDTH(WIDTH), .PE_ADDR(3'b011), .FL(1), .BL(1)) pe2_packetizer(.ifmap_addr(intf[43]), .ifmap_data(intf[44]), .psum(intf[42]), .toNOC(intf[12]), .pe2_done(intf[55]), .pe2_done2(intf[58]));

    depacketizer_adder de_a1(.fromNoc(intf[7]), .PE0_Data(intf[47]), .PE1_Data(intf[48]), .PE2_Data(intf[49]), .Membrane_in_Data(intf[50]));
    adder_T a1(.PE0_Data(intf[47]), .PE1_Data(intf[48]), .PE2_Data(intf[49]), .Membrane_in_Data(intf[50]), .Membrane_out(intf[51]), .spike_out(intf[52]));
    packetizer_adder adder_pkt(.Membrane_out(intf[51]), .spike_out(intf[52]), .toNoc(intf[6]));


	initial begin
	#50000;
	$stop;
	end
endmodule
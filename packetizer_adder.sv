`timescale 1ns/100ps

import SystemVerilogCSP::*;

module packetizer_adder(interface Membrane_out, spike_out, toNoc);
	parameter FL = 1;
	parameter BL = 1;
	parameter WIDTH_PACKET = 35;
	parameter ADDER_ADDR = 3'b000;
    parameter WIDTH = 8;

	logic [WIDTH_PACKET-1:0] packet;
    logic [WIDTH-1:0] membrane;
    logic spike;
	int iteration = 3;


	always begin
		for (integer i=0; i<iteration; i++) begin
           fork
               Membrane_out.Receive(membrane);
               spike_out.Receive(spike);
           join
           packet[8*i +: 8] = membrane;
           packet[24+i] = spike;
           #FL;
        end
        packet[34:32] = 3'b100; //destination address
        packet[31:29] = 3'b000; //source address
        packet[28:27] = 3'b000; //useless data
        toNoc.Send(packet);
        #BL;
	end
endmodule
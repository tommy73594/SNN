`timescale 1ns/100ps

import SystemVerilogCSP::*;

module depacketizer_adder (interface fromNoc, PE0_Data, PE1_Data, PE2_Data, Membrane_in_Data);
    parameter FL = 1;
    parameter BL = 1;
    parameter WIDTH_PACKET = 35;
    parameter WIDTH = 8;

    logic [WIDTH_PACKET-1:0] packet = 0;
    logic [WIDTH-1:0] data;

    always begin
        fromNoc.Receive(packet);
        #FL;
        // packet from PE0
        if (packet[31:29] == 3'b001) begin
            data = packet[7:0];
            PE0_Data.Send(data);
            //$display("\t\t (addr_des: %b) received data %d from addr %b(PE0).  , time: %d", packet[34:32], packet[7:0], packet[31:29], $realtime);
        end
        // packet from PE1
        if (packet[31:29] == 3'b010) begin
            data = packet[7:0];
            PE1_Data.Send(data);
            //$display("\t\t (addr_des: %b) received data %d from addr %b(PE1).  , time: %d", packet[34:32], packet[7:0], packet[31:29], $realtime);
        end
        // packet from PE2
        if (packet[31:29] == 3'b011) begin 
            data = packet[7:0];
            PE2_Data.Send(data);
            //$display("\t\t (addr_des: %b) received data %d from addr %b(PE2).  , time: %d", packet[34:32], packet[7:0], packet[31:29], $realtime);
        end
        // packet from memory
        if (packet[31:29] == 3'b100) begin
            for(integer i=0; i<3; i++) begin
                data = packet[i*8 +: 8];
                Membrane_in_Data.Send(data);
            end
            //$display("\t\t (addr_des: %b) received data %d, %d, %d from addr %b(MEM).  , time: %d", packet[34:32], packet[23:16], packet[15:8], packet[7:0], packet[31:29], $realtime);
        end
        #BL;
    end
    
endmodule
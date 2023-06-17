`timescale 1ns/100ps

import SystemVerilogCSP::*;

module depacketizer_pe (interface in, ifmap_addr, ifmap_data, filter_addr, filter_data, start, pe2_done2);
    parameter FL = 1;
    parameter BL = 1;
    parameter WIDTH_IFMAP = 1;
    parameter WIDTH_FILTER = 8;
    parameter WIDTH_PACKET = 35;
    parameter ADDR_I = 5;
    parameter ADDR_F = 3;
    parameter PE_ADDR = 3'b000;

    logic [WIDTH_FILTER-1:0] data_filter;
    logic [WIDTH_IFMAP-1:0] data_ifmap;
    logic [ADDR_I-1:0] addr_ifmap = 0;
    logic [ADDR_F-1:0] addr_filter = 0;
    logic [WIDTH_PACKET-1:0] packet = 0;

    int ds = 0; // if t != 1, don't send filter to pe.

    always begin
        in.Receive(packet);
        #FL;
        // packet from the memory contain ifmap + filter
        if (packet[31:29] == 3'b100) begin
            for(integer i=0; i<ADDR_I; i++) begin
                data_ifmap = packet[i];
                fork
                    begin
                        if(i < ADDR_F && ds == 0) begin
                            data_filter = packet[5+8*i +: 8];
                            filter_addr.Send(addr_filter);
                            filter_data.Send(data_filter);
							#BL;
                            addr_filter++;
                        end
                    end
                    begin
                        ifmap_addr.Send(addr_ifmap);
                        ifmap_data.Send(data_ifmap);
						#BL;
                        addr_ifmap++;
                    end
                join
                //$display("\t\t (addr_des: %b) received input [%d, %d, %d, %d, %d] and filter [%d, %d, %d]from addr %b.  , time: %d", packet[34:32], packet[0], packet[1], packet[2], packet[3], packet[4], packet[12:5], packet[20:13], packet[28:21], packet[31:29], $realtime);
            end
            ds = 1;
        end
        // pakcet not from memory only contain the ifmap
        else begin
            // packet from pe2 to indicate the pe2 is done.
            if (PE_ADDR == 3'b010 && packet[31:29] == 3'b011 && packet[7:0] == 8'b11111111) begin 
                pe2_done2.Send(1);
                in.Receive(packet);
            end
            for(integer i=0; i<ADDR_I; i++) begin // Load ifmap
                data_ifmap = packet[i];
                ifmap_addr.Send(addr_ifmap);
                ifmap_data.Send(data_ifmap);
                addr_ifmap++;
                #BL;
            end
            //$display("\t\t (addr_des: %b) received input [%d, %d, %d, %d, %d]from addr %b.  , time: %d", packet[34:32], packet[0], packet[1], packet[2], packet[3], packet[4], packet[31:29], $realtime);
        end
		start.Send(0);
        addr_filter = 0; // reset
        addr_ifmap = 0; // reset
        #BL;
    end
    
endmodule
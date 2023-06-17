`timescale 1ns/1fs
import SystemVerilogCSP::*;

module router_tb;
    parameter FL = 4;
    parameter BL = 6;
    parameter WIDTH = 47;
    parameter WIDTH_ADDR = 3;
    parameter MASK = 3'b110;
    parameter ADDRESS = 3'b000;

    logic [WIDTH-1:0] packet;
    logic [WIDTH_ADDR-1:0] dest_addr, source_addr;
    integer fp;
    
    Channel #(.WIDTH(WIDTH), .hsProtocol(P4PhaseBD)) intf[5:0] ();

    router #(.WIDTH(WIDTH), .WIDTH_ADDR(WIDTH_ADDR), .MASK(MASK), .ADDRESS(ADDRESS), .FL(FL), .BL(BL)) r1(.P_in(intf[0]), .P_out(intf[1]), .C1_in(intf[2]), .C1_out(intf[3]), .C2_in(intf[4]), .C2_out(intf[5]));

    initial begin
        fp = $fopen("router_tb.dump", "w");
        $fdisplay(fp, "------------ROUTER TEST------------");

        $fdisplay(fp, "\nTEST: PARENT TO CHILDREN-1");
        dest_addr = 3'b000;
        source_addr = 3'b100;
        packet = {dest_addr, source_addr, {41{1'b1}}};
        intf[0].Send(packet);
        intf[3].Receive(packet);
        $fdisplay(fp, "mask = %b, address = %b, dest_addr = %b", MASK, ADDRESS, dest_addr);
        $fdisplay(fp, "Parent to Children-1 Sucess!");

        $fdisplay(fp, "\nTEST: PARENT TO CHILDREN-2");
        dest_addr = 3'b001;
        source_addr = 3'b100;
        packet = {dest_addr, source_addr, {41{1'b1}}};
        intf[0].Send(packet);
        intf[5].Receive(packet);
        $fdisplay(fp, "mask = %b, address = %b, dest_addr = %b", MASK, ADDRESS, dest_addr);
        $fdisplay(fp, "Parent to Children-2 Sucess!");

        $fdisplay(fp, "\nTEST: CHILDREN-1 TO PARENT");
        dest_addr = 3'b100;
        source_addr = 3'b000;
        packet = {dest_addr, source_addr, {41{1'b1}}};
        intf[2].Send(packet);
        intf[1].Receive(packet);
        $fdisplay(fp, "mask = %b, address = %b, dest_addr = %b", MASK, ADDRESS, dest_addr);
        $fdisplay(fp, "Children-1 to Parent Sucess!");

        $fdisplay(fp, "\nTEST: CHILDREN-1 TO CHILDREN-2");
        dest_addr = 3'b001;
        source_addr = 3'b000;
        packet = {dest_addr, source_addr, {41{1'b1}}};
        intf[2].Send(packet);
        intf[5].Receive(packet);
        $fdisplay(fp, "mask = %b, address = %b, dest_addr = %b", MASK, ADDRESS, dest_addr);
        $fdisplay(fp, "Children-1 to Children-2 Sucess!");

        $fdisplay(fp, "\nTEST: CHILDREN-2 TO PARENT");
        dest_addr = 3'b100;
        source_addr = 3'b001;
        packet = {dest_addr, source_addr, {41{1'b1}}};
        intf[4].Send(packet);
        intf[1].Receive(packet);
        $fdisplay(fp, "mask = %b, address = %b, dest_addr = %b", MASK, ADDRESS, dest_addr);
        $fdisplay(fp, "Children-2 to Parent Sucess!");

        $fdisplay(fp, "\nTEST: CHILDREN-2 TO CHILDREN-1");
        dest_addr = 3'b000;
        source_addr = 3'b001;
        packet = {dest_addr, source_addr, {41{1'b1}}};
        intf[4].Send(packet);
        intf[3].Receive(packet);
        $fdisplay(fp, "mask = %b, address = %b, dest_addr = %b", MASK, ADDRESS, dest_addr);
        $fdisplay(fp, "Children-2 to Children-1 Sucess!");
	
	    $stop;
    end
endmodule
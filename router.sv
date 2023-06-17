`timescale 1ns/1fs
import SystemVerilogCSP::*;

module routerfunc(interface P_C1, P_C2, C1_P, C1_C2, C2_P, C2_C1, P_in, C1_in, C2_in); // 'To'_'From', 'From'_in
    parameter WIDTH = 47;  // packet width
    parameter WIDTH_ADDR = 3;   // total 5 nodes each has 3-bits address
    parameter MASK = 3'b000;
    parameter ADDRESS = 3'b000;
    parameter FL = 2;   
    parameter BL = 1;
    
    logic [WIDTH-1:0] P_in_packet, C1_in_packet, C2_in_packet; // packet size
    integer i, j;

    //____________PACKET FORMAT____________
    // [46:44] destination address
    // [43:41] source address
    // [40:5]  filter_data * 3 (each 12-bits)
    // [4:0]   input_data * 5  (each 1-bit)

    always begin // Parent to children logic
        P_in.Receive(P_in_packet);
        #FL;
        for(j=0; j<WIDTH_ADDR; j=j+1) begin // 0 to left node, 1 to right node
            if(MASK[WIDTH_ADDR-1-j] == 0) begin
                if(P_in_packet[WIDTH-1-j] == 0) begin
                    C1_P.Send(P_in_packet);
                end
                else begin
                    C2_P.Send(P_in_packet);
                end
                break;
            end
        end
        #BL;
    end

    always begin // Children to Parent/Children logic
        C1_in.Receive(C1_in_packet);
        #FL;
        if((C1_in_packet[WIDTH-1:WIDTH-WIDTH_ADDR] & MASK) == ADDRESS) begin // address & router mask = router address, send to children
            C2_C1.Send(C1_in_packet);
        end
        else begin // address & router mask != router address, send to parent
            P_C1.Send(C1_in_packet);
        end
        #BL;
    end

    always begin // Children to Parent/Children logic
        C2_in.Receive(C2_in_packet);
        #FL;
        if((C2_in_packet[WIDTH-1:WIDTH-WIDTH_ADDR] & MASK) == ADDRESS) begin // address & router mask = router address, send to children
            C1_C2.Send(C2_in_packet);
        end
        else begin // address & router mask != router address, send to parent
            P_C2.Send(C2_in_packet);
        end
        #BL;
    end

endmodule

module router(interface P_in, P_out, C1_in, C1_out, C2_in, C2_out);
    parameter FL = 2;
    parameter BL = 1;
    parameter WIDTH = 47;
    parameter WIDTH_ADDR = 3;
    parameter MASK = 3'b000;
    parameter ADDRESS = 3'b000;

    Channel #(.WIDTH(WIDTH), .hsProtocol(P4PhaseBD)) intf[7:0] ();

    routerfunc #(.WIDTH(WIDTH), .WIDTH_ADDR(WIDTH_ADDR), .MASK(MASK), .ADDRESS(ADDRESS), .FL(FL), .BL(BL)) rf(.P_C1(intf[0]), .P_C2(intf[1]), .C1_P(intf[2]), .C1_C2(intf[3]),
                                                                                                                        .C2_P(intf[4]), .C2_C1(intf[5]), .P_in(P_in), .C1_in(C1_in), .C2_in(C2_in));
    arbiter_merge #(.WIDTH(WIDTH), .FL(FL), .BL(BL)) am0(.A(intf[0]), .B(intf[1]), .W(P_out));
    arbiter_merge #(.WIDTH(WIDTH), .FL(FL), .BL(BL)) am1(.A(intf[2]), .B(intf[3]), .W(C1_out));
    arbiter_merge #(.WIDTH(WIDTH), .FL(FL), .BL(BL)) am2(.A(intf[4]), .B(intf[5]), .W(C2_out));
endmodule

 
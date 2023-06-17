`timescale 1ns/100ps

import SystemVerilogCSP::*;


module ifmap (interface in_data, interface in_addr, interface out_data, interface out_addr, interface done, interface toP_addr, interface toP_data);
    parameter WIDTH = 8;
    parameter DEPTH = 5;
    parameter thisAddr = 3'b000;
    parameter FL = 2;
    parameter BL = 2;

    logic [(WIDTH/2)-1:0] data_ifmap_in, data_ifmap_out;
    logic [DEPTH-1:0] addr_ifmap_in, addr_ifmap_out;
    logic [(WIDTH/2)-1:0] mem [DEPTH-1:0];
    logic changeI = 0;

	int iteration = 0;
	 
    always begin
        if (changeI == 0) begin // determine need to receive ifmap or send ifmap
            fork
                begin
				    if (iteration == 5) begin // After load all ifmap, wait pe done
                        done.Receive(changeI);
                        #FL;
                        iteration = 0;
                    end
					else begin
                        in_addr.Receive(addr_ifmap_in);
                        in_data.Receive(data_ifmap_in);
                        #FL;
                        mem[addr_ifmap_in] = data_ifmap_in;
                        iteration++;
					end
                end
                begin
                    out_addr.Receive(addr_ifmap_out);
                    #FL;
                    data_ifmap_out = mem[addr_ifmap_out];
                    out_data.Send(data_ifmap_out);
                    #BL;
                end
            join_any
        end
        else begin
            for (integer i=0; i<DEPTH; i++) begin
                fork
                    toP_addr.Send(i);
                    toP_data.Send(mem[i]);
					#BL;
                join
            end
			changeI = 0; // reset
        end

    end
    
endmodule

module filter (interface in_data, interface in_addr, interface out_data, interface out_addr);
    parameter WIDTH = 8;
    parameter DEPTH = 3;
  
    parameter FL = 2;
    parameter BL = 2;

    logic [(WIDTH/2)-1:0] data_filter_in, data_filter_out;
    logic [DEPTH-1:0] addr_filter_in, addr_filter_out;
    logic [(WIDTH/2)-1:0] mem [DEPTH-1:0];


    always begin
       fork
           begin
                in_addr.Receive(addr_filter_in);
                in_data.Receive(data_filter_in);
                mem[addr_filter_in] = data_filter_in;
                #FL;
           end
           begin
                out_addr.Receive(addr_filter_out);
                #FL;
                data_filter_out = mem[addr_filter_out];
            	out_data.Send(data_filter_out);
                #BL;
           end
       join_any    
    end
    
endmodule

module multiplier (interface in_data1, interface in_data2, interface out_data);
    parameter WIDTH = 8;
    logic [(WIDTH/2)-1:0] data1, data2;
    logic [WIDTH-1:0] out;
    parameter FL = 2;
    parameter BL = 2;

    always begin
        fork
            in_data1.Receive(data1);
            in_data2.Receive(data2);
        join
        

        out = data1 * data2;
	    #FL;
        out_data.Send(out);
        #BL;
    end

endmodule

module adder (interface a0, interface s, interface b0, interface out_data);
    parameter WIDTH = 8;
    logic [WIDTH-1:0] data1, data3, out;
	 logic [WIDTH-1:0] data2=0;
    logic sel;
    parameter FL = 2;
    parameter BL = 2;

    always begin
        fork
            s.Receive(sel);
            b0.Receive(data3);
	 
        join

        if (sel == 0) begin
	    a0.Receive(data1);
            out = data1 + data3;
        end
        else if (sel == 1) begin
	//    a1.Receive(data2);  // no psum_in
            out = data2 + data3;
        end
	    #FL;
        out_data.Send(out);
        #BL;
    end

endmodule

module split (interface a, interface s, interface o1, interface o2);
    parameter WIDTH = 8;
    logic [WIDTH-1:0] data;
    logic sel;
    parameter FL = 2;
    parameter BL = 2;

    always begin
	fork
      	    a.Receive(data);
            s.Receive(sel);
	join
    #FL;
    if(sel == 0) begin
        o1.Send(data);
	end
    else if(sel == 1) begin
        o2.Send(data);
	end
    #BL;
    end

endmodule

module accumulator (interface a, interface c, interface o);
    parameter WIDTH = 8;
    logic [WIDTH-1:0] data;
    logic clr;
    parameter FL = 2;
    parameter BL = 2;

    int flag_data = 0;

    always begin
	fork
	    begin
            a.Receive(data);
            #FL;
		    o.Send(data);
            #BL;
	    end
	    begin
            c.Receive(clr);
		    #FL;
	    end
	join_any
     
    if(clr == 1) begin
        data = 0;
	    o.Send(0);
        #BL;
    end
    end

endmodule

module control (interface start, done, split_sel, add_sel, filter_addr, ifmap_addr, clear_acc, pe2_done);
    parameter WIDTH = 8;
    parameter FL = 2;
    parameter BL = 2;
    parameter ifmap_length = 5;
    parameter filter_length = 3;
    parameter thisAddr = 3'b000;

    logic st;
    logic [WIDTH-1:0] no_iterations = ifmap_length - filter_length;
	
    int i, j;

    always begin
		start.Receive(st);
        //$display("%m receive start %d", st);
        wait (st == 0);
	    #FL;
        for (i=0; i<=no_iterations; i=i+1) begin
            clear_acc.Send(1);
            for (j=0; j<filter_length; j=j+1) begin
                fork
                    split_sel.Send(0);
                    add_sel.Send(0);
                    filter_addr.Send(j);
                    ifmap_addr.Send(i+j);
                    clear_acc.Send(0);
                join
            end
                
            fork
                split_sel.Send(1);
                add_sel.Send(1);
            join
		    //$display("%d: psum_out send", i+1);
            #BL;
        end
        st=1;
        //$display("%m start send done");
        done.Send(1);
        if(thisAddr == 3'b011) pe2_done.Send(1);
	    #BL;
	    //$display("done send");
    end

endmodule

module pe (interface filter_in, filter_addr, ifmap_in, ifmap_addr, start, psum_out, toP_addr, toP_data, pe2_done);
    parameter WIDTH = 8;
    parameter DEPTH_I = 5;
    parameter ADDR_I = 3; 
    parameter DEPTH_F = 3;
    parameter ADDR_F = 2;
    parameter thisAddr = 3'b000;

    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) intf  [11:0] (); 

    filter f1 (.in_data(filter_in), .in_addr(filter_addr), .out_data(intf[1]), .out_addr(intf[0]));
    ifmap #(.thisAddr(thisAddr)) i1 (.in_data(ifmap_in), .in_addr(ifmap_addr), .out_data(intf[2]), .out_addr(intf[3]), .done(intf[11]), .toP_addr(toP_addr), .toP_data(toP_data));
    multiplier m1 (.in_data1(intf[1]), .in_data2(intf[2]), .out_data(intf[4]));
    adder a1 (.a0(intf[4]), .s(intf[5]), .b0(intf[6]), .out_data(intf[7]));
    split s1 (.a(intf[7]), .s(intf[8]), .o1(intf[9]), .o2(psum_out));
    accumulator ac1 (.a(intf[9]), .c(intf[10]), .o(intf[6]));
    control #(.thisAddr(thisAddr)) c1 (.start(start), .done(intf[11]), .split_sel(intf[8]), .add_sel(intf[5]), .filter_addr(intf[0]), .ifmap_addr(intf[3]), .clear_acc(intf[10]), .pe2_done(pe2_done));

endmodule
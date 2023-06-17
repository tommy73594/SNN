`timescale 1ns/1ps

module data_generator (rReq, rAck, rData1, rData2, rData3, rData4, rst);
    input logic rAck;
    output rReq, rData1, rData2, rData3, rData4, rst;
    parameter WIDTH = 5;
    logic [WIDTH-1:0] SendValue=0;
    logic [WIDTH-1:0] rData1, rData2, rData3, rData4;
    logic rReq, rst;
    
    initial begin
      rReq = 1;
	    rst = 0;
	    #10 rst = 1;
    end

    always
    begin 
    // $display("Start module data_generator and time is %d", $time);	//add a display here to see when this module starts its main loop
        SendValue = $random() % (2**WIDTH);
        rData1 = SendValue + $random() % (2**WIDTH);
        rData2 = SendValue + $random() % (2**WIDTH);
        rData3 = SendValue + $random() % (2**WIDTH);
        rData4 = SendValue + $random() % (2**WIDTH);
        wait(rAck == rReq) rReq = ~rReq;
            
    end


endmodule

//Sample data_bucket module
module data_bucket (lReq, lAck, lData);
  input lReq, lData;
  output logic lAck;
  parameter WIDTH = 8;
  logic [WIDTH-1:0] ReceiveValue = 0;
  logic [WIDTH-1:0] lData;
  
  always
  begin
 
    lAck = 0;
    wait(lReq == 1) ReceiveValue = lData;
    lAck = 1;
    wait(lReq == 0) ReceiveValue = lData;
    lAck = 0;
  end

endmodule

module adder (lReq, lAck, lData1, lData2, lData3, lData4, rReq, rAck, rData, rst);  
    input lReq, lData1, lData2, lData3, lData4, rAck, rst;
    output lAck, rReq, rData;

    int delay = $random % 8 + 1; 
    parameter WIDTH = 5;
    logic [WIDTH-1:0] data1, lData1, data2, lData2, data3, lData3, data4, lData4;
    logic [WIDTH+2:0] rData;
    logic w1, w2;
    

    clickcontrol cc1(.aReq(lReq), .bAck(rAck), .reset(rst), .aAck(lAck), .bReq(rReq), .clk(w2));
    dff #(.ff_width(WIDTH+3)) d1(.clk(w2), .rst(rst), .d(lData1), .q(data1));
    dff #(.ff_width(WIDTH+1)) d2(.clk(w2), .rst(rst), .d(lData2), .q(data2));
    dff #(.ff_width(WIDTH+1)) d3(.clk(w2), .rst(rst), .d(lData3), .q(data3));
    dff #(.ff_width(WIDTH+1)) d4(.clk(w2), .rst(rst), .d(lData4), .q(data4));

    always
    begin
	begin
            #delay;
            rData= data1 + data2 + data3 + data4;
	end
    end
        
endmodule

module clickcontrol (aReq, aAck, bReq, bAck, clk, reset);
    input logic aReq, bAck, reset;
    output logic aAck, bReq, clk;

    parameter tcrtl = 1;
    parameter tcomb = 8;
    parameter ctq = 1;
    parameter ff_width = 1;
    parameter delay = 2;
    logic w1, w2, w3, w4;

    assign #tcomb w1 = aReq;
    assign #tcrtl bReq = w2;
    assign aAck = bReq;

    dff d1(.clk(clk), .rst(reset), .d(~w2), .q(w2));

    and #delay a1(w3, ~w1, aAck, bAck);
    and #delay a2(w4, w1, ~aAck, ~bAck);
    or #delay o1(clk, w3, w4);

endmodule

module dff(clk, rst, d, q);
    parameter clock_to_Q = 3;
    parameter ff_width = 5;

    input clk, rst;
    input [ff_width-1:0] d;
    output reg [ff_width-1:0] q; 

    always @(posedge clk, negedge rst) begin
        #clock_to_Q;
        if (!rst) 
            q <= 0;
        else
            q <= d; 
    end

endmodule

module adder_tb;
     logic [4:0] intf;
     logic [4:0] data1, data2, data3, data4;
     logic [7:0] datao;

     data_generator #(.WIDTH(5)) dg(.rReq(intf[0]), .rAck(intf[1]), .rData1(data1), .rData2(data2), .rData3(data3), .rData4(data4), .rst(intf[2]));
     adder a1(.lReq(intf[0]), .lAck(intf[1]), .lData1(data1), .lData2(data2), .lData3(data3), .lData4(data4), .rReq(intf[3]), .rAck(intf[4]), .rData(datao), .rst(intf[2]));
     data_bucket #(.WIDTH(8)) db(.lReq(intf[3]), .lAck(intf[4]), .lData(datao));

     initial 
	#200 $stop;

 endmodule
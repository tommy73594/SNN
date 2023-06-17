`timescale 1ns/1fs
import SystemVerilogCSP::*;

module packetizer_pe(interface ifmap_addr, ifmap_data, psum, pe2_done, pe2_done2, toNOC);
	parameter FL = 1;
	parameter BL = 1;
	parameter WIDTH = 35;
	parameter PE_ADDR = 3'b001;


	logic [7:0]pe_data;
	logic [WIDTH-1:0] packet;
	logic [2:0]addr;
	logic data, done;
	int i = 0;
	int sc = 0; // sned count, dicide if we need to send ifmap to other pe 


	always begin
		if (i < 3) begin // receive three output from pe and send to adder
			psum.Receive(pe_data);
			#FL;
			packet[34:32]= 3'b000;
			packet[31:29]= PE_ADDR;
			packet[28:8] = 0;
			packet[7:0] = pe_data;
			toNOC.Send(packet);
			i++;
			#BL;
		end
		
		else begin // after receive three output, start send ifmap to other pe
			if (PE_ADDR == 3'b011) begin // if pe2, send packet to pe1 to indicate that pe2 is done.
				pe2_done.Receive(done);
				packet[31:29]= PE_ADDR; //source
				packet[34:32] = 3'b010;
				packet[7:0] = 8'b11111111;
				toNOC.Send(packet);
			end
			else if(PE_ADDR == 3'b010) pe2_done2.Receive(done);	// pe1 receive packet to know pe2 is done
			for (integer j=0; j<5; j++) begin
				ifmap_addr.Receive(addr);
				ifmap_data.Receive(data);
				packet[addr]=data;
			end
			#FL;
			if (sc < 2) begin // prevent to send ifmap when it is alreay finished all calculate
				if (PE_ADDR == 3'b010) begin
					packet[34:32]= 3'b001; //destination
					packet[31:29]= PE_ADDR; //source
					toNOC.Send(packet);
				end
				else if (PE_ADDR == 3'b011) begin;
					packet[34:32] = 3'b010; //destination
					packet[31:29]= PE_ADDR; //source
					toNOC.Send(packet);		
				end
				sc++;
			end
			else sc = 0; // reset
			i = 0;
			#BL;
		end
	end
endmodule
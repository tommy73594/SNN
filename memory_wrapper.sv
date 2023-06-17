`timescale 1ns/1ps
import SystemVerilogCSP::*;

module memory_wrapper(Channel toMemRead, Channel toMemWrite, Channel toMemT,
			Channel toMemX, Channel toMemY, Channel toMemSendData, Channel fromMemGetData, Channel toNOC, Channel fromNOC); 

parameter mem_delay = 15;
parameter simulating_processing_delay = 30;
parameter timesteps = 10;
parameter WIDTH = 8;
  Channel #(.hsProtocol(P4PhaseBD)) intf[9:0] (); 
  int num_filts_x = 3;
  int num_filts_y = 3;
  int ofx = 3;
  int ofy = 3;
  int ifx = 5;
  int ify = 5;
  int ift = 10;
  int i,j,k,t,h;
  int read_filts = 2;
  int read_ifmaps = 1; // write_ofmaps = 1 as well...
  int read_mempots = 0;
  int write_ofmaps = 1;
  int write_mempots = 0;
  logic [WIDTH-1:0] byteval;
  logic spikeval;
  logic [34:0] packet, packet_r, packet_pe2;
  logic [8:0] potential;
  
// Weight stationary design
// TO DO: modify for your dataflow - can read an entire row (or write one) before #mem_delay
// TO DO: decide whether each Send(*)/Receive(*) is correct, or just a placeholder
  initial begin
	packet[31:29] = 3'b100; // source address
    for (int t = 1; t <= timesteps; t++) begin
	$display("%m beginning timestep t = %d at time = %d",t,$time);
		// get the new ifmaps
		for (int i = 0; i < ifx; i++) begin
			for (int j = 0; j < ify; ++j) begin
				// read filter
				if( num_filts_x > i && num_filts_y > j && t == 1) begin
					$display("%m Requesting filter [%d][%d] at time %d",i,j,$time);
					toMemRead.Send(read_filts);
					toMemX.Send(i);
					toMemY.Send(j); 
					fromMemGetData.Receive(byteval);
					$display("%m Received filter[%d][%d] = %d at time %d",i,j,byteval,$time);
					packet[(5+j*8) +: 8] = byteval; 
					packet_pe2[(5+j*8) +: 8] = byteval; // store original filter			
				end

				// TO DO: read old membrane potential (hint: you can't do it here...)
				$display("%m requesting ifm[%d][%d]",i,j);
				// request the input spikes
				toMemRead.Send(read_ifmaps);
				toMemX.Send(i);
				toMemY.Send(j);
				fromMemGetData.Receive(spikeval);
				$display("%m received ifm[%d][%d] = %b",i,j,spikeval);				
				// do processing (delete this line)
				//#simulating_processing_delay;
				packet[0+j] = spikeval;

			end // ify
			if (i == 0) begin 
				packet[34:32] = 3'b001; // destination address pe0 
			end
			if (i == 1) begin
				packet[34:32] = 3'b010; // destination address pe1
			end
			if (i >= 2) begin // send ifmap to pe2 three times
				packet[34:32] = 3'b011; // destination address pe2 
				packet[28:5] = packet_pe2[28:5]; // load original filter value
			end
			#mem_delay;
			toNOC.Send(packet);

			if(i >= 2) begin // wait until send one packet to every pe
				h = i - 2;
				for (int m = 0; m < ofy; m++) begin // start send membrane potentials to adder
					if (t==1) begin // initial setup, do not have any membrane potentials
						packet[m*8 +: 8] = 8'b00000000;
					end
					else begin
						toMemRead.Send(read_mempots);
						toMemX.Send(h);
						toMemY.Send(m);
						fromMemGetData.Receive(potential); 
						packet[m*8 +: 8] = potential;
					end

				end

				packet[34:32] = 3'b000; // destination address adder
				#mem_delay;
				toNOC.Send(packet);

				fromNOC.Receive(packet_r); // receive membrane potentials and spikes from adder
				for (int k = 0; k < ofy; k++) begin	// write back membrane potentials & spikes to memory						
					toMemWrite.Send(write_mempots);
					toMemX.Send(h);
					toMemY.Send(k);
					toMemSendData.Send(packet_r[k*8+:8]);						
					toMemWrite.Send(write_ofmaps);
					toMemX.Send(h);
					toMemY.Send(k);				
					toMemSendData.Send(packet_r[24+k]);
					#1;
				end // ofy
					#mem_delay;	
					#mem_delay;			
			end
		end // ifx
		$display("%m received all ifmaps for timestep t = %d at time = %d",t,$time);
		$display("%m sent all output spikes and stored membrane potentials for timestep t = %d at time = %d",t,$time);
		toMemT.Send(t);
		$display("%m send request to advance to next timestep at time t = %d",$time);
	end // t = timesteps
	$display("%m done");
	#mem_delay; // let memory display comparison of golden vs your outputs
	$stop;
  end
  
  always begin
	#20000;
	$display("%m working still...");
  end
  
endmodule
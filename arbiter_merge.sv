`timescale 1ns/10ps
import SystemVerilogCSP::*;

module arbiter_merge(interface A, interface B, interface W);
  parameter FL = 2;
  parameter BL = 1;
  parameter WIDTH = 8;
  logic [WIDTH-1:0] a_data,b_data, data;


always begin
	wait (A.status != idle || B.status != idle);
	
	if (A.status != idle && B.status != idle) begin
		if ($random%2 == 0) begin
			A.Receive(a_data);
			data = a_data;
			#FL;
			W.Send(data);
			#BL;
		end
		else begin
			B.Receive(b_data);
			data = b_data;
			#FL;
			W.Send(data);
			#BL;
		end
	end
	else if (A.status != idle) begin
		A.Receive(a_data);
		data = a_data;
		#FL;
		W.Send(data);
		#BL;
	end
		
	else if (B.status != idle) begin
		B.Receive(b_data);
		data = b_data;
		#FL;
		W.Send(data);
		#BL;
	end
end

endmodule	
	
		
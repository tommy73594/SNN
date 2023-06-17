`timescale 1ns/100ps

import SystemVerilogCSP::*;


module adder_T(Channel PE0_Data, PE1_Data, PE2_Data, Membrane_in_Data, Membrane_out, spike_out);
    parameter WIDTH = 8;
    parameter THRESHOLD = 64;
    parameter FL = 2;
    parameter BL = 2;

    logic [WIDTH-1:0] pe0_data, pe1_data, pe2_data, membrane_in_data;
    logic [WIDTH-1:0] membrane_out_Data [2:0];
    logic spike_out_Data;

    int i = 0, j = 0, m = 0, n = 0; // count the number of data from different place.
    initial begin
        membrane_out_Data[0] = 0;
        membrane_out_Data[1] = 0;
        membrane_out_Data[2] = 0;
    end

    always begin
        fork
            begin
                if(i<3) begin
                    for (integer k=0; k<3; k++) begin
                        //$display("start pe0_adder Receive");
                        PE0_Data.Receive(pe0_data);
                        //$display("end pe0_adder Receive");
                        #FL;
                        membrane_out_Data[i] = membrane_out_Data[i] + pe0_data;
                        i++;
                    end
                end
                else if(i==3) begin
                    //$display("Receive all data from PE0");
                    i++;
                end
            end
            begin
                if(j<3) begin
                    for (integer k=0; k<3; k++) begin
                        //$display("start pe1_adder Receive");
                        PE1_Data.Receive(pe1_data);
                        //$display("end pe1_adder Receive");
                        #FL;
                        membrane_out_Data[j] = membrane_out_Data[j] + pe1_data;
                        j++;
                    end
                end
                else if(j==3) begin
                    //$display("Receive all data from PE1");
                    j++;
                end
            end
            begin
                if(m<3) begin
                    for (integer k=0; k<3; k++) begin
                        //$display("start pe2_adder Receive");
                        PE2_Data.Receive(pe2_data);
                        //$display("end pe2_adder Receive");
                        #FL;
                        membrane_out_Data[m] = membrane_out_Data[m] + pe2_data;
                        m++;
                    end
                end
                else if(m==3) begin
                    //$display("Receive all data from PE2");
                    m++;
                end
            end
            begin
                if(n<3) begin
                    for (integer k=0; k<3; k++) begin
                        //$display("start mem_adder Receive");
                        Membrane_in_Data.Receive(membrane_in_data);
                        //$display("end mem_adder Receive");
                        #FL;
                        membrane_out_Data[n] = membrane_out_Data[n] + membrane_in_data;
                        n++;
                    end
                end
                else if(n==3) begin
                    //$display("Receive all data from mem");
                    n++;
                end
            end
        join

        if (i==3 && j==3 && m==3 && n==3) begin // receive all data, send three set of membrane and spike
            for(integer k=0; k<3; k++) begin
                if (membrane_out_Data[k] < THRESHOLD) begin
                    Membrane_out.Send(membrane_out_Data[k]);
                    spike_out.Send(0);
                end
                else begin
                    membrane_out_Data[k] = membrane_out_Data[k] - THRESHOLD;
                    Membrane_out.Send(membrane_out_Data[k]);
                    spike_out.Send(1);
                end
                #BL;
            end
            // reset data
            membrane_out_Data[0] = 0;
            membrane_out_Data[1] = 0;
            membrane_out_Data[2] = 0;
            i = 0;
            j = 0;
            m = 0;
            n = 0;
        end
    end
endmodule

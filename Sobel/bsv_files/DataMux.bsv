interface DataMux_IFC;
    method Bit#(8) out(Bool select, Bit#(8) din);
endinterface

module mkDataMux(DataMux_IFC);
    method Bit#(8) out(Bool select, Bit#(8) din);
        return select ? din : 8'b0;
    endmethod
endmodule

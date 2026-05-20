interface AddressMux_IFC;
    method Bit#(17) out(Bit#(17) rd_add, Bit#(17) wr_add, Bool wea);
endinterface

module mkAddressMux(AddressMux_IFC);
    method Bit#(17) out(Bit#(17) rd_add, Bit#(17) wr_add, Bool wea);
        return wea ? wr_add : rd_add;
    endmethod
endmodule

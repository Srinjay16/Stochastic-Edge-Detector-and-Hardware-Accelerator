interface VgaDisplay_IFC;
    method Bit#(1) hsync();
    method Bit#(1) vsync();
    method Bit#(12) rgb(Bit#(8) data_in);
    method Bit#(17) address();
    method Bool frame_done();
endinterface

module mkVgaDisplay(VgaDisplay_IFC);
    Reg#(Bit#(10)) h_count <- mkReg(0);
    Reg#(Bit#(10)) v_count <- mkReg(0);

    rule increment_counters;
        if (h_count == 799) begin
            h_count <= 0;
            v_count <= (v_count == 524) ? 0 : v_count + 1;
        end else h_count <= h_count + 1;
    endrule

    method Bit#(1) hsync = (h_count >= 688 && h_count <= 783) ? 0 : 1;
    method Bit#(1) vsync = (v_count >= 513 && v_count <= 514) ? 0 : 1;
    
    // address = (v/2) * 320 + (h/2)[cite: 9]
    method Bit#(17) address;
        Bit#(17) v_offset = extend(v_count >> 1) * 320;
        Bit#(17) h_offset = extend(h_count >> 1);
        return v_offset + h_offset;
    endmethod
    
    method Bit#(12) rgb(Bit#(8) data_in);
        let color = data_in[3:0];
        return (h_count < 640 && v_count < 480) ? {color, color, color} : 12'b0;
    endmethod

    method Bool frame_done = (v_count == 480);
endmodule

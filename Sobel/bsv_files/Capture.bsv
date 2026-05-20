interface Capture_IFC;
    method Bit#(8)  data_Y();
    method Bit#(17) address();
    method Bool     data_valid();
    method Bool     frame_done();
endinterface

module mkCapture(Clock pclk, Reset rst, Bit#(8) d_in, Bit#(1) vsync, Bit#(1) hsync, Capture_IFC ifc);
    Reg#(Bit#(1))  halfclk <- mkReg(1);
    Reg#(Bit#(8))  luma    <- mkReg(0);
    Reg#(Bit#(17)) addr    <- mkReg(17'h1FFFF); 
    Reg#(Bit#(10)) rows    <- mkReg(0);
    Reg#(Bit#(10)) cols    <- mkReg(0);
    Reg#(Bool)     valid   <- mkReg(False);
    Reg#(Bool)     done    <- mkReg(False);

    rule toggle_halfclk;
        halfclk <= ~halfclk;
    endrule

    rule process_and_check_frame;
        Bit#(17) next_addr = addr;
        Bit#(10) next_rows = rows;
        Bit#(10) next_cols = cols;
        Bool     is_valid  = False;
        Bool     is_done   = False;

        if (vsync == 0 && hsync == 1) begin
            if (halfclk == 1) begin
                if (cols < 320 && rows < 240) begin
                    is_valid = True;
                    luma <= d_in;
                    next_addr = addr + 1;
                    next_cols = cols + 1;
                end else if (cols < 639) begin
                    next_cols = cols + 1;
                end
            end

            if (cols == 639 && halfclk == 0) begin
                next_cols = 0;
                next_rows = rows + 1;
            end
        end

        if (next_rows == 480) begin
            next_rows = 0;
            next_addr = 17'h1FFFF;
            is_done   = True;
        end

        addr  <= next_addr;
        rows  <= next_rows;
        cols  <= next_cols;
        valid <= is_valid;
        done  <= is_done;
    endrule

    method Bit#(8)  data_Y     = luma;
    method Bit#(17) address    = addr;
    method Bool     data_valid = valid;
    method Bool     frame_done = done;
endmodule

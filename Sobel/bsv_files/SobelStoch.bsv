interface SobelStoch_IFC;
    method Bit#(17) address();
    method Bit#(8)  pix_out();
endinterface

module mkSobelStoch(Bit#(8) data_in, Bool video_on, SobelStoch_IFC ifc);
    // ---- State Registers ----
    Reg#(Bit#(10)) col_count <- mkReg(4);
    Reg#(Bit#(10)) row_count <- mkReg(0);
    Reg#(Bit#(2))  state     <- mkReg(0); // 0: Fetch R-1, 1: Fetch R, 2: Fetch R+1/Calc, 3: Increment
    Reg#(Bit#(17)) addr_reg  <- mkReg(0);
    Reg#(Bit#(8))  res_reg   <- mkReg(0);

    // 3x3 Stochastic Window Registers
    Reg#(Bit#(8)) o [3][3];
    for (Integer i=0; i<3; i=i+1) 
        for (Integer j=0; j<3; j=j+1) 
            o[i][j] <- mkReg(0);

    Reg#(Bit#(8)) d_prev <- mkReg(0);
    Reg#(Bit#(8)) d_curr <- mkReg(0);

    // ---- Helper Functions ----
    function Bit#(8) pix_stoch(Bit#(8) pix);
        Bit#(8) res = 0;
        if (pix >= 0)   res[0] = 1;
        if (pix >= 32)  res[1] = 1;
        if (pix >= 64)  res[2] = 1;
        if (pix >= 96)  res[3] = 1;
        if (pix >= 128) res[4] = 1;
        if (pix >= 160) res[5] = 1;h
        if (pix >= 192) res[6] = 1;
        if (pix >= 224) res[7] = 1;
        return res;
    endfunction

    function Bit#(17) get_addr(Bit#(10) c, Int#(11) r_off);
        Int#(11) row_signed = unpack({1'b0, row_count}); 
        Int#(11) target_row = row_signed + r_off;
        Bit#(10) r = truncate(pack(target_row));
        
        // This maps the 640x480 VGA sweep to the 320x240 BRAM indices
        return extend(c >> 1) + 320 * extend(r >> 1);
    endfunction

    // ---- Consolidated Pipeline Rule ----
    // Merging fetch and counter logic to resolve scheduling conflicts (G0010/G0021)
    rule rl_sobel_pipeline (video_on);
        if (state == 0) begin
            // Beat 0: Request row (r-1)
            addr_reg <= get_addr(col_count, -1);
            state <= 1;
        end 
        else if (state == 1) begin
            // Beat 1: Latch row (r-1), Request row (r)
            d_prev <= data_in;
            addr_reg <= get_addr(col_count, 0);
            state <= 2;
        end 
        else if (state == 2) begin
            // Beat 2: Latch row (r), Request row (r+1)
            d_curr <= data_in;
            addr_reg <= get_addr(col_count, 1);
            state <= 3;
        end 
        else if (state == 3) begin
            // Beat 3: Latch row (r+1), Compute Stochastic Sobel, and Increment Counters[cite: 8]
            let s_prev = pix_stoch(d_prev);
            let s_curr = pix_stoch(d_curr);
            let s_next = pix_stoch(data_in);

            // Shift window left and insert new column
            o[0][0] <= o[0][1]; o[0][1] <= o[0][2]; o[0][2] <= s_prev;
            o[1][0] <= o[1][1]; o[1][1] <= o[1][2]; o[1][2] <= s_curr;
            o[2][0] <= o[2][1]; o[2][1] <= o[2][2]; o[2][2] <= s_next;

            // Stochastic XOR Subtractions:
            // ax = p2 ^ p0, bx = p5 ^ p3, cx = p8 ^ p6
            Bit#(8) ax = o[0][0] ^ o[0][2]; 
            Bit#(8) bx = o[1][0] ^ o[1][2]; 
            Bit#(8) cx = o[2][0] ^ o[2][2];
            
            Bit#(8) ay = o[0][0] ^ o[2][0]; 
            Bit#(8) by = o[0][1] ^ o[2][1]; 
            Bit#(8) cy = o[0][2] ^ o[2][2];

            // Deterministic Interleaving (Scaled Addition)
            Bit#(8) m1x = {ax[7],bx[6],ax[5],bx[4],ax[3],bx[2],ax[1],bx[0]};
            Bit#(8) m2x = {cx[7],bx[6],cx[5],bx[4],cx[3],bx[2],cx[1],bx[0]};
            Bit#(8) m1y = {ay[7],by[6],ay[5],by[4],ay[3],by[2],ay[1],by[0]};
            Bit#(8) m2y = {cy[7],by[6],cy[5],by[4],cy[3],by[2],cy[1],by[0]};

            Bit#(8) dx = {m1x[7],m2x[6],m1x[5],m2x[4],m1x[3],m2x[2],m1x[1],m2x[0]};
            Bit#(8) dy = {m1y[7],m2y[6],m1y[5],m2y[4],m1y[3],m2y[2],m1y[1],m2y[0]};

            // Compute Magnitude: |Gx| + |Gy|
            UInt#(8) count = 0;
            for (Integer i = 0; i < 8; i = i + 1) begin
                count = count + extend(unpack(dx[i])) + extend(unpack(dy[i]));
            end
            res_reg <= pack(count * 15); 

            // Increment Counters
            if (col_count == 639) begin
                col_count <= 0;
                row_count <= (row_count == 479) ? 0 : row_count + 1;
            end else begin
                col_count <= col_count + 1;
            end
            
            state <= 0; // Return to start of fetch sequence
        end
    endrule

    method Bit#(17) address = addr_reg;
    method Bit#(8)  pix_out = (row_count >= 1 && row_count <= 478) ? res_reg : 0;
endmodule

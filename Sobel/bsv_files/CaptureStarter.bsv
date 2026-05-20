interface CaptureStarter_IFC;
    method Bool vsync_detected();
    method Bit#(1) capture_reset_out();
endinterface

module mkCaptureStarter(Bit#(1) vsync, Bit#(1) reset, CaptureStarter_IFC ifc);
    Reg#(Bool) detected <- mkReg(False);
    Reg#(Bit#(1)) c_reset <- mkReg(0);

    rule detect_vsync (vsync == 1);
        c_reset <= reset;
        if (reset == 1) detected <= False;
        else detected <= True;
    endrule

    method Bool vsync_detected = detected;
    method Bit#(1) capture_reset_out = c_reset;
endmodule

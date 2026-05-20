interface CameraResetClk_IFC;
    method Bit#(1) camera_reset(Bit#(1) crst);
endinterface

module mkCameraResetClk(CameraResetClk_IFC);
    method Bit#(1) camera_reset(Bit#(1) crst);
        return ~crst;
    endmethod
endmodule

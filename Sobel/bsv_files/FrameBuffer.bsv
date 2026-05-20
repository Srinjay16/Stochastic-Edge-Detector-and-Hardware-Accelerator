import BRAM::*;

interface FrameBuffer_IFC;
    method Action put(Bit#(17) addr, Bit#(8) data, Bool wea);
    method ActionValue#(Bit#(8)) read(); // Changed from Bit#(8) to ActionValue
endinterface

module mkFrameBuffer(FrameBuffer_IFC);
    BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 76800; // 320 * 240 memory size[cite: 6]
    
    // Instantiate a 1-port BRAM server[cite: 6]
    BRAM1Port#(Bit#(17), Bit#(8)) mem <- mkBRAM1Server(cfg);

    // Write/Request method
    method Action put(Bit#(17) addr, Bit#(8) data, Bool wea);
        mem.portA.request.put(BRAMRequest{write: wea, responseOnWrite: False, address: addr, datain: data});
    endmethod

    // Read method (ActionValue because it dequeues the BRAM response)
    method ActionValue#(Bit#(8)) read();
        let response <- mem.portA.response.get();
        return response;
    endmethod
endmodule

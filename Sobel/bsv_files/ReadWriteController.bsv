typedef enum {Start, Writing, ReadyToRead, Reading, ReadyToWrite} State deriving (Bits, Eq);

interface RWController_IFC;
    method Bool write_en();
    method Bool read_en();
    method Bool select();
    method Bit#(3) state_info();
endinterface

module mkReadWriteController(Bool en, Bool writing_done, Bool display_done, Bool video_on, Bool data_valid, RWController_IFC ifc);
    Reg#(State) state <- mkReg(Start);
    Reg#(Bool) r_en <- mkReg(False);
    Reg#(Bool) w_en <- mkReg(False);
    Reg#(Bool) sel <- mkReg(False);

    rule update_fsm;
        case (state)
            Start: if (en) state <= ReadyToWrite;
            Writing: if (writing_done) begin
                        state <= ReadyToRead;
                        w_en <= False;
                     end
            ReadyToRead: if (display_done) begin
                            state <= Reading;
                            r_en <= True;
                            sel <= True;
                         end
            Reading: if (display_done) begin
                        state <= ReadyToWrite;
                        r_en <= False;
                        sel <= False;
                     end
            ReadyToWrite: if (writing_done) begin
                             state <= Writing;
                             w_en <= True;
                          end
        endcase
    endrule

    method Bool write_en = w_en && data_valid;
    method Bool read_en = r_en && video_on;
    method Bool select = sel;
    method Bit#(3) state_info = pack(state);
endmodule

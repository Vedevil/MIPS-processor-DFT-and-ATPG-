// =============================================================================
// mips_easy.v
// Simplified Single-Cycle MIPS Processor
// Technology : 90nm
// Design     : mips_easy
// DFT ports  : scan_en, scan_in, scan_out, test_mode
// =============================================================================

`timescale 1ns/1ps

module mips_easy (
    input  wire        clk,
    input  wire        rst_n,
    // Instruction memory interface (external ROM / IMEM macro)
    output wire [31:0] pc_out,
    input  wire [31:0] instr,
    // --- DFT Scan Ports ---
    input  wire        scan_en,
    input  wire        scan_in,
    output wire        scan_out,
    input  wire        test_mode
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    wire [31:0] pc_current, pc_next, pc_plus4, pc_branch, pc_jump;
    wire [31:0] instr;
    wire [31:0] reg_data1, reg_data2, alu_result, mem_read_data;
    wire [31:0] sign_ext_imm, alu_src_b, write_data;
    wire [4:0]  write_reg;
    wire [3:0]  alu_ctrl;
    wire        zero_flag;
    wire        reg_dst, alu_src, mem_to_reg, reg_write;
    wire        mem_read, mem_write, branch, jump;
    wire        pc_src;

    // -------------------------------------------------------------------------
    // Program Counter register
    // -------------------------------------------------------------------------
    reg [31:0] pc_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_reg <= 32'h0000_0000;
        else        pc_reg <= pc_next;
    end

    assign pc_current = pc_reg;
    assign pc_plus4   = pc_current + 32'd4;
    assign pc_out     = pc_current;   // drive external instruction memory

    // scan_out: placeholder driven low pre-DFT.
    // Genus connect_scan_chains will override this with the last scan FF Q pin.
    assign scan_out = 1'b0;

    // -------------------------------------------------------------------------
    // Control Unit
    // -------------------------------------------------------------------------
    control_unit u_ctrl (
        .opcode    (instr[31:26]),
        .reg_dst   (reg_dst),
        .alu_src   (alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write (reg_write),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .branch    (branch),
        .jump      (jump)
    );

    // -------------------------------------------------------------------------
    // Register File (32 x 32-bit)
    // -------------------------------------------------------------------------
    register_file u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_write (reg_write),
        .rs        (instr[25:21]),
        .rt        (instr[20:16]),
        .rd        (write_reg),
        .write_data(write_data),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    // -------------------------------------------------------------------------
    // Sign Extender
    // -------------------------------------------------------------------------
    assign sign_ext_imm = {{16{instr[15]}}, instr[15:0]};

    // -------------------------------------------------------------------------
    // ALU Control + ALU
    // -------------------------------------------------------------------------
    alu_control u_alu_ctrl (
        .opcode   (instr[31:26]),
        .funct    (instr[5:0]),
        .alu_ctrl (alu_ctrl)
    );

    assign alu_src_b = alu_src ? sign_ext_imm : reg_data2;

    alu u_alu (
        .a       (reg_data1),
        .b       (alu_src_b),
        .alu_ctrl(alu_ctrl),
        .result  (alu_result),
        .zero    (zero_flag)
    );

    // -------------------------------------------------------------------------
    // Data Memory (SRAM - 256 words)
    // -------------------------------------------------------------------------
    data_memory u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .address   (alu_result),
        .write_data(reg_data2),
        .read_data (mem_read_data)
    );

    // -------------------------------------------------------------------------
    // Write-back
    // -------------------------------------------------------------------------
    assign write_data = mem_to_reg ? mem_read_data : alu_result;
    assign write_reg  = reg_dst    ? instr[15:11]  : instr[20:16];

    // -------------------------------------------------------------------------
    // Branch / Jump PC logic
    // -------------------------------------------------------------------------
    assign pc_src    = branch & zero_flag;
    assign pc_branch = pc_plus4 + {sign_ext_imm[29:0], 2'b00};
    assign pc_jump   = {pc_plus4[31:28], instr[25:0], 2'b00};

    assign pc_next = jump   ? pc_jump   :
                     pc_src ? pc_branch :
                              pc_plus4;

endmodule


// =============================================================================
// Control Unit
// =============================================================================
module control_unit (
    input  wire [5:0] opcode,
    output reg        reg_dst,
    output reg        alu_src,
    output reg        mem_to_reg,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        jump
);
    always @(*) begin
        {reg_dst,alu_src,mem_to_reg,reg_write,
         mem_read,mem_write,branch,jump} = 8'b0;
        case (opcode)
            6'h00: begin reg_dst=1; reg_write=1; end                        // R-type
            6'h23: begin alu_src=1; mem_to_reg=1; reg_write=1; mem_read=1; end // LW
            6'h2B: begin alu_src=1; mem_write=1; end                        // SW
            6'h04: begin branch=1; end                                       // BEQ
            6'h08: begin alu_src=1; reg_write=1; end                        // ADDI
            6'h02: begin jump=1; end                                         // J
            6'h03: begin jump=1; reg_write=1; end                           // JAL
        endcase
    end
endmodule


// =============================================================================
// Register File
// Pragma forces Genus to infer flip-flops (not RAM macros) so all 32x32
// registers are scannable by the DFT flow.
// =============================================================================
module register_file (
    input  wire        clk, rst_n, reg_write,
    input  wire [4:0]  rs, rt, rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1, read_data2
);
    // synthesis translate_off
    // pragma attribute regs logic_block
    // synthesis translate_on
    (* keep = "true", ram_style = "registers" *)
    reg [31:0] regs [0:31];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) for (i=0;i<32;i=i+1) regs[i] <= 32'b0;
        else if (reg_write && (rd != 5'b0)) regs[rd] <= write_data;
    end
    assign read_data1 = regs[rs];
    assign read_data2 = regs[rt];
endmodule


// =============================================================================
// ALU Control
// =============================================================================
module alu_control (
    input  wire [5:0] opcode, funct,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (opcode)
            6'h00: case (funct)
                       6'h20: alu_ctrl = 4'b0010; // ADD
                       6'h22: alu_ctrl = 4'b0110; // SUB
                       6'h24: alu_ctrl = 4'b0000; // AND
                       6'h25: alu_ctrl = 4'b0001; // OR
                       6'h2A: alu_ctrl = 4'b0111; // SLT
                       default: alu_ctrl = 4'b1111;
                   endcase
            default: alu_ctrl = 4'b0010; // ADD (LW/SW/ADDI/BEQ)
        endcase
    end
endmodule


// =============================================================================
// ALU
// =============================================================================
module alu (
    input  wire [31:0] a, b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'b0;
        endcase
    end
    assign zero = (result == 32'b0);
endmodule


// =============================================================================
// Data Memory
// Inferred as synchronous SRAM - excluded from scan in Genus script via
// set_dont_scan. Covered by MBIST in a full DFT flow.
// =============================================================================
module data_memory (
    input  wire        clk, mem_read, mem_write,
    input  wire [31:0] address, write_data,
    output reg  [31:0] read_data
);
    (* ram_style = "block" *)
    reg [31:0] mem [0:255];
    always @(posedge clk) begin
        if (mem_write) mem[address[9:2]] <= write_data;
    end
    always @(*) begin
        read_data = mem_read ? mem[address[9:2]] : 32'b0;
    end
endmodule

module MCX(
    input clk, rst);
    
    //Program Counter [4b] Conditional[2 bits] Instruction[4 bits] arg1[12 bits] arg2[12 bits] arg3 [12 bits]
    reg [3:0] PC;
    reg [1:0] cond;
    reg [3:0] inst;
    reg signed [11:0] args [2:0];
    reg signed [10:0] numArgs [2:0];

    //Debug: Breaks out args to be seen by gtkwave
    wire signed [11:0] arg0;
    wire signed [11:0] arg1;
    wire signed [11:0] arg2;

    assign arg0 = args[0];
    assign arg1 = args[1];
    assign arg2 = args[2];

    //registers
    reg signed [10:0] acc;
    reg [3:0] next_inst;
    wire [45:0] line;
    wire signed [10:0] alu_out;

    parameter acc_addr = 12'h801;


    alu ALU1(.inst(inst), .arg1(numArgs[0]), .arg2(numArgs[1]), .acc(acc), .out(alu_out)); 
    prog_mem MEM(.rst(rst), .addr(next_inst), .line(line));

    // Update register args with numeric values
    always @(*) begin
        for(int i=0;i<2;i=i+1) begin
            numArgs[i] = args[i][10:0];
        end
        //TODO: Actually dereference registers
    end

    // Load next instruction
    always @(posedge clk) begin
        PC <= line[45:42];
        cond <= line[41:40];
        inst <= line[39:36];
        args[0] <= line[35:24];
        args[1] <= line[23:12];
        args[2] <= line[11:0];
    end

    // Queue next instruction to be loaded
    always @(*) begin
            if(inst == 4'h2)    // Jump
                next_inst = args[0][3:0];
            else if(PC == 6)
                next_inst = 0;
            else
                next_inst = PC + 1;
    end

    // Update acc register
    always @(posedge clk) begin
        if(inst != 4'h1) acc <= alu_out; // everything except mov instruction handled by alu
        else if(args[1] == acc_addr) acc <= numArgs[0]; // mov instruction
        else acc <= acc;    // unnecessary backup
    end

    // Reset
    always @(posedge rst) begin
            acc <= 0;
            PC <= 15;
            inst <= 0;
    end
endmodule
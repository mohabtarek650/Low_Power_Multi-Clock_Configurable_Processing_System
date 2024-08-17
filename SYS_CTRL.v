module SYS_CTRL 
(
 input      wire                CLK,
 input      wire                RST, 
 input      wire  [15:0]        ALU_OUT , 
 input      wire                ALU_OUT_VLD, 
 input      wire                FIFO_FULL,
 input      wire  [7:0]         RF_RdData, 
 input      wire                RF_RdData_Valid, 
 input      wire  [7:0]         UART_RX_DATA , 
 input      wire                UART_RX_VLD, 
 output     reg   [3:0]         ALU_FUN,
 output     reg                 ALU_EN, 
 output     reg                 CLKG_EN , 
 output     reg   [3:0]         RF_Address, 
 output     reg                 RF_WrEn, 
 output     reg                 RF_RdEn,    
 output     reg   [7:0]         RF_WrData,
 output     reg   [7:0]         UART_TX_DATA,
 output     reg                 UART_TX_VLD,
 output     reg                 CLKDIV_EN
 );

// Gray state encoding with unique values
localparam  [3:0]      IDLE           = 'b0000,
                      WRITE_DATA     = 'b0001,
                      READ_DATA      = 'b0011,
                      ALU_OPERAND_A  = 'b0010,
                      ALU_OPERATION  = 'b0100,
                      WRITE_ADDRESS  = 'b0101,
                      ALU_OPERAND_B  = 'b0110,
                      RdData_Valid   = 'b0111,
                       ALU_OUT_Vld   = 'b1001,
                      ALU_VALID_2    = 'b1010;

// State registers
reg         [3:0]      current_state, next_state;


///////////////////////////////////////////////////////////////////////////////

// State transition for the first state machine
always @ (posedge CLK or negedge RST) begin
  if (!RST) begin
      current_state <= IDLE;
     /*  RF_WrEn<=0;
RF_RdEn<=0;
ALU_EN<=0;
UART_TX_VLD<=0;
CLKG_EN<=0;
CLKDIV_EN<=1;
*/
   end else begin
      current_state <= next_state;
   end
end

///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////

// Next state logic for the first state machine
always @ (*) begin
  case(current_state)
    IDLE: begin
      if(UART_RX_VLD && UART_RX_DATA==8'hAA)
	 next_state=WRITE_ADDRESS;
	 else if(UART_RX_VLD && UART_RX_DATA==8'hBB)
	 next_state=READ_DATA;
	 else if(UART_RX_VLD && UART_RX_DATA==8'hDD)
	 next_state= ALU_OPERATION;
	 else if(UART_RX_VLD && UART_RX_DATA==8'hCC)
	 next_state=ALU_OPERAND_A;
	 else
	 next_state=IDLE;
    end
 
    WRITE_ADDRESS: begin
      if (UART_RX_VLD) begin
        next_state = WRITE_DATA;
      end else begin
        next_state = WRITE_ADDRESS;
      end
    end

    WRITE_DATA: begin
      if (UART_RX_VLD) begin
       
        next_state = IDLE;
      end else begin
        next_state = WRITE_DATA;
      end
    end

    READ_DATA: begin
      if (UART_RX_VLD) begin
       
        next_state = RdData_Valid;
      end else begin
        next_state = READ_DATA;
      end
    end

    ALU_OPERATION: begin
      if (UART_RX_VLD) begin
        
        next_state = ALU_OUT_Vld;
      end else begin
        next_state = ALU_OPERATION;
      end
    end

    ALU_OPERAND_A: begin
      if (UART_RX_VLD) begin
        next_state = ALU_OPERAND_B;
      end else begin
        next_state = ALU_OPERAND_A;
      end
    end

    ALU_OPERAND_B: begin
      if (UART_RX_VLD) begin
       
        next_state = ALU_OPERATION;
      end else begin
        next_state = ALU_OPERAND_B;
      end
    end

RdData_Valid: begin
      if (RF_RdData_Valid && !FIFO_FULL) begin
       
        next_state = IDLE;
      end else begin
        next_state = RdData_Valid;
      end
    end
ALU_OUT_Vld: begin
      if (ALU_OUT_VLD && !FIFO_FULL) begin
       
        next_state = ALU_VALID_2;
      end else begin
        next_state = ALU_OUT_Vld;
      end
    end
    
 ALU_VALID_2: begin
      if (ALU_OUT_VLD && !FIFO_FULL) begin
       
        next_state = IDLE;
      end else begin
        next_state = ALU_VALID_2;
      end
    end
    default: begin
      next_state = IDLE;
    end
  endcase

end

///////////////////////////////////////////////////////////////////////////////
always @ (*) begin

     RF_WrEn=0;
     RF_RdEn=0;
     ALU_EN=0;
     UART_TX_VLD=0;
     CLKG_EN=0;
     CLKDIV_EN=1;
UART_TX_DATA =0;
 ALU_FUN = 0;
 RF_Address = 0;
 RF_WrData = 0;
  case(current_state)
    IDLE: begin
        RF_WrEn=0;
     RF_RdEn=0;
     ALU_EN=0;
     UART_TX_VLD=0;
     CLKG_EN=0;
     CLKDIV_EN=1;
UART_TX_DATA =0;
 ALU_FUN = 0;
 RF_Address = 0;
 RF_WrData = 0;
     
    end

    WRITE_ADDRESS: begin
      
     //   RF_WrEn = 1;
        RF_Address = UART_RX_DATA[3:0];
    end

    WRITE_DATA: begin
     
        RF_WrEn = 1;
        RF_WrData = UART_RX_DATA;
       
    end

    READ_DATA: begin
      
        RF_RdEn = 1;
        RF_Address = UART_RX_DATA[3:0];
    
    end

    ALU_OPERATION: begin
        CLKG_EN = 1;
        ALU_EN = 1;
        ALU_FUN = UART_RX_DATA[3:0];
       
    end

    ALU_OPERAND_A: begin
      
        RF_WrEn = 1;
        RF_Address = 4'd0;
        RF_WrData = UART_RX_DATA;
        
    end

    ALU_OPERAND_B: begin
      
        RF_WrEn = 1;
        RF_Address = 4'd1;
        RF_WrData = UART_RX_DATA;
        RF_WrEn = 0;
        
    end
    RdData_Valid: begin
      if (RF_RdData_Valid && !FIFO_FULL) begin
       
         UART_TX_DATA = RF_RdData;
       UART_TX_VLD = 1;
       
      end else begin
        UART_TX_VLD = 0;
      end
    end
ALU_OUT_Vld: begin
      if (ALU_OUT_VLD && !FIFO_FULL) begin 
       UART_TX_DATA = ALU_OUT[7:0];
        UART_TX_VLD = 1;
       
      end else begin
      UART_TX_VLD = 0;

      end
    end
    
 ALU_VALID_2: begin
      if (ALU_OUT_VLD && !FIFO_FULL) begin
        UART_TX_DATA = ALU_OUT[15:8];
        UART_TX_VLD = 1;
       
      end else begin
         UART_TX_VLD = 0;
         
      end
    end
    default: begin
      
      RF_WrEn=0;
     RF_RdEn=0;
     ALU_EN=0;
     UART_TX_VLD=0;
     CLKG_EN=0;
     CLKDIV_EN=1;
UART_TX_DATA =0;
 ALU_FUN = 0;
 RF_Address = 0;
 RF_WrData = 0;
    end
  endcase
end




endmodule

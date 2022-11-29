-- datapath_aubie.vhd
-- entity reg_file
use work.dlx_types.all;
use work.bv_arithmetic.all;

entity reg_file is
    generic(prop_delay : Time := 5 ns);
    port (
        data_in     :   in dlx_word;
        readnotwrite:   in bit;
        clock       :   in bit;
	data_out    :   out dlx_word;
        reg_number  :   in register_index
    );
end entity reg_file;


architecture behavior of reg_file is
		
		type reg_type is array (0 to 31) of dlx_word;
begin
	reg_file_process: process(readnotwrite, clock, reg_number, data_in) is
	
		variable registers: reg_type;
	begin
		if (clock = '1') then
			if (readnotwrite = '1') then

				data_out <= registers(bv_to_integer(reg_number)) after prop_delay;
			else

				registers(bv_to_integer(reg_number)) := data_in;
	
			end if;
		end if;
	end process reg_file_process;
end architecture behavior;


-- entity alu 
use work.dlx_types.all;
use work.bv_arithmetic.all;

entity alu is
    generic(prop_delay : Time := 5 ns);
    port(
        operand1  :   in dlx_word;
        operand2  :   in dlx_word;
        operation :   in alu_operation_code;
        result    :   out dlx_word;
        error     :   out error_code
    );
end entity alu;

-- alu_operation_code values
-- 0000 unsigned add
-- 0001 signed add
-- 0010 2's compl add
-- 0011 2's compl sub
-- 0100 2's compl mul
-- 0101 2's compl divide
-- 0110 logical and
-- 0111 bitwise and
-- 1000 logical or
-- 1001 bitwise or
-- 1010 logical not 
-- 1011 bitwise not 
-- 1101-1111 output zeros
-- error code
-- 0000 = no error
-- 0001 = overflow
-- 0010 = underflow
-- 0011 = divide by zero

architecture behavior of ALU is
    

begin
    alu_process: process(operand1, operand2, operation) is
          variable temp_result: dlx_word := x"00000000";
          variable logical_true: dlx_word := x"00000001";
          variable logical_false: dlx_word := x"00000000";
          variable overflow_flag_set: boolean;
          variable div_by_zero: boolean;
          variable op1_logical_status: bit; 
          variable op2_logical_status: bit; 

          begin
              error <= "0000"; 
              case(operation) is
                  when "0000" => -- UNSIGNED ADD
                      bv_addu(operand1, operand2, temp_result, overflow_flag_set);
                      if overflow_flag_set then
                          error <= "0001";
                      end if;
                      result <= temp_result;
                  when "0001" => -- UNSIGNED SUBTRACT
                      bv_subu(operand1, operand2, temp_result, overflow_flag_set);
                      if overflow_flag_set then
                          error <= "0010";
                          
                      end if;
                      result <= temp_result;
                  when "0010" => -- TWO'S COMPLEMENT ADD
                      bv_add(operand1, operand2, temp_result, overflow_flag_set);
                      if overflow_flag_set then
                          
                          if (operand1(31) = '0') AND (operand2(31) = '0') then
                              if (temp_result(31) = '1') then
                                  error <= "0001"; 
                              end if;
                          
                          elsif (operand1(31) = '1') AND (operand2(31) = '1') then
                              if (temp_result(31) = '0') then
                                  error <= "0010"; 
                              end if;
                          end if;
                      end if;
                      result <= temp_result;
                  when "0011" => -- TWO'S COMPLEMENT SUBTRACT
                      bv_sub(operand1, operand2, temp_result, overflow_flag_set);
                      if overflow_flag_set then
                          
                          if (operand1(31) = '1') AND (operand2(31) = '0') then
                              if (temp_result(31) = '0') then
                                  error <= "0010"; -- underflow occurred
                              end if;
                          
                          elsif (operand1(31) = '0') AND (operand2(31) = '1') then
                              if (temp_result(31) = '1') then
                                  error <= "0001"; -- overflow occurred
                              end if;
                          end if;
                      end if;
                      result <= temp_result;
                  when "0100" => 
                      bv_mult(operand1, operand2, temp_result, overflow_flag_set);
                      if overflow_flag_set then
                          if (operand1(31) = '1') AND (operand2(31) = '0') then 
                              error <= "0010"; 
                          elsif (operand1(31) = '0') AND (operand2(31) = '1') then 
                              error <= "0010"; 
                          else 
                              error <= "0001"; 
                          end if;
                      end if;
                      result <= temp_result;
                  when "0101" => 
                      bv_div(operand1, operand2, temp_result, div_by_zero, overflow_flag_set);
                      if div_by_zero then
                          error <= "0011"; --
                      elsif overflow_flag_set then
                          error <= "0010"; 
                      end if;
                      result <= temp_result;
                  when "0110" => 
                      op1_logical_status := '0'; 
                      op2_logical_status := '0'; 
                      
                      for i in 31 downto 0 loop
                          
                          if (operand1(i) = '1') then
                              op1_logical_status := '1';
                              exit;
                          end if;
                      end loop;
                      
                      for i in 31 downto 0 loop
                        
                          if (operand2(i) = '1') then
                              op2_logical_status := '1';
                              exit;
                          end if;
                      end loop;
                     
                      if ((op1_logical_status AND op2_logical_status) = '1') then
                          result <= logical_true; 
                      else
                          result <= logical_false; 
                      end if;
                  when "0111" => 
                      for i in 31 downto 0 loop
                          temp_result(i) := operand1(i) AND operand2(i);
                      end loop;
                      result <= temp_result;
                  when "1000" => -- LOGICAL OR
                      op1_logical_status := '0';
                      op2_logical_status := '0'; 
                      
                      for i in 31 downto 0 loop
                          
                          if (operand1(i) = '1') then
                              op1_logical_status := '1';
                              exit;
                          end if;
                      end loop;
                      
                      for i in 31 downto 0 loop
                          
                          if (operand2(i) = '1') then
                              op2_logical_status := '1';
                              exit;
                          end if;
                      end loop;
                      
                      if ((op1_logical_status OR op2_logical_status) = '1') then
                          result <= logical_true; 
                      else
                          result <= logical_false; 
                      end if;
                  when "1001" => 
                      for i in 31 downto 0 loop
                          temp_result(i) := operand1(i) OR operand2(i);
                      end loop;
                      result <= temp_result;
                  when "1010" => 
                      temp_result := logical_true; 
                      for i in 31 downto 0 loop
                          if (NOT operand1(i) = '0') then
                              temp_result := logical_false; 
                              exit;
                          end if;
                      end loop;
                      result <= temp_result;
                  when "1011" => 
                      for i in 31 downto 0 loop
                          temp_result(i) := NOT operand1(i);
                      end loop;
                      result <= temp_result;
                  when "1100" => 
                      temp_result := logical_false;
                      if (operand1 = x"00000000") then
                          temp_result := logical_true;
                      end if;
                      result <= temp_result;
                  when others => 
                      result <= x"00000000";
              end case;
   end process alu_process;
end architecture behavior;

 
use work.dlx_types.all;

entity dlx_register is
    generic(prop_delay : Time := 5 ns);
    port(
        in_val  :   in dlx_word;
        clock   :   in bit;
        out_val :   out dlx_word
    );
end entity dlx_register;


architecture behavior of dlx_register is

begin
	dlx_reg_process: process(in_val, clock) is
	
	begin
		
		if (clock = '1') then
			out_val <= in_val after prop_delay;
		end if;
	end process dlx_reg_process;
end architecture behavior;


use work.dlx_types.all;
use work.bv_arithmetic.all;

entity pcplusone is
	generic(prop_delay: Time := 5 ns);
	port (
        input : in dlx_word;
        clock : in bit;
        output: out dlx_word
    );
end entity pcplusone;

architecture behavior of pcplusone is
begin
    plusone: process(input, clock) is 
        variable newpc: dlx_word;
        variable error: boolean;
    begin
        if clock'event and clock = '1' then
            bv_addu(input,"00000000000000000000000000000001",newpc,error);
            output <= newpc after prop_delay;
        end if;
    end process plusone;
end architecture behavior;



use work.dlx_types.all;

entity mux is
     generic(prop_delay : Time := 5 ns);
     port (
            input_1 : in dlx_word;
            input_0 : in dlx_word;
            which   : in bit;
            output  : out dlx_word
     );
end entity mux;

architecture behavior of mux is
begin
   muxProcess : process(input_1, input_0, which) is
   begin
      if (which = '1') then
         output <= input_1 after prop_delay;
      else
         output <= input_0 after prop_delay;
      end if;
   end process muxProcess;
end architecture behavior;
-- end entity mux

-- entity threeway_mux
use work.dlx_types.all;

entity threeway_mux is
    generic(prop_delay : Time := 5 ns);
    port (
        input_2 : in dlx_word;
        input_1 : in dlx_word;
        input_0 : in dlx_word;
        which   : in threeway_muxcode;
        output  : out dlx_word
    );
end entity threeway_mux;

architecture behavior of threeway_mux is
begin
   muxProcess : process(input_1, input_0, which) is
   begin
      if (which = "10" or which = "11" ) then
         output <= input_2 after prop_delay;
      elsif (which = "01") then
         output <= input_1 after prop_delay;
      else
         output <= input_0 after prop_delay;
      end if;
   end process muxProcess;
end architecture behavior;
-- end entity mux


-- entity memory
use work.dlx_types.all;
use work.bv_arithmetic.all;

entity memory is
    port (
        address       :   in dlx_word;
        readnotwrite  :   in bit;
        data_out      :   out dlx_word;
        data_in       :   in dlx_word;
        clock         :   in bit
    );
end memory;

architecture behavior of memory is

begin  -- behavior

    mem_behav: process(address,clock) is

        type memtype is array (0 to 1024) of dlx_word;
        variable data_memory : memtype;
    begin

        data_memory(0) :=  X"30200000"; 
        data_memory(1) :=  X"00000100"; 
        

        data_memory(2) :=  X"30080000"; 
        data_memory(3) :=  X"00000101";
        

        
        data_memory(4) :=  X"30100000"; 
        data_memory(5) :=  X"00000102";
        

        data_memory(6) :=  "00000000000110000100010000000000"; 

        data_memory(7) :=  "00100000000000001100000000000000"; 
        data_memory(8) :=  x"00000103"; 
        

        
        data_memory(9) :=  "00110001000000000000000000000000"; 
        data_memory(10) := x"00000104"; 
       

        data_memory(11) := "00100010000000001100000000000000"; 
        
        
        data_memory(12) := "00110010001010000000000000000000"; 
        
        data_memory(13) := x"40000000"; 
        data_memory(14) := x"00000105"; 
        
        data_memory(256) := "01010101000000001111111100000000"; 
        data_memory(257) := "10101010000000001111111100000000"; 
        data_memory(258) := "00000000000000000000000000000001"; 
        
        
        data_memory(261) :=  x"00584400"; 
        
        data_memory(262) := x"4101C000"; 
        data_memory(263) := x"0000010B"; 
        
        data_memory(267) := x"00604400"; 
        
        data_memory(268) := x"10000000"; -- NOOP


        if clock = '1' then
          if readnotwrite = '1' then
            
            data_out <= data_memory(bv_to_natural(address)) after 5 ns;
          else
            
            data_memory(bv_to_natural(address)) := data_in;
          end if;
        end if;
  end process mem_behav;
end behavior;
-- end entity memory

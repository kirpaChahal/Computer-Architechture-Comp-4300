use work.bv_arithmetic.all;
use work.dlx_types.all;



entity aubie_controller is
    generic(
        prop_delay    : Time := 5 ns;
        xt_prop_delay : Time := 15 ns -- Extended prop_delay for allowing other signals to propagate first
    ); -- Controller propagation delay
    port(
      ir_control            :   in dlx_word;
      alu_out               :   in dlx_word;
      alu_error             :   in error_code;
      clock                 :   in bit;
      regfilein_mux         :   out threeway_muxcode;
      memaddr_mux           :   out threeway_muxcode;
      addr_mux              :   out bit;
      pc_mux                :   out threeway_muxcode;
      alu_func              :   out alu_operation_code;
      regfile_index         :   out register_index;
      regfile_readnotwrite  :   out bit;
      regfile_clk           :   out bit;
      mem_clk               :   out bit;
      mem_readnotwrite      :   out bit;
      ir_clk                :   out bit;
      imm_clk               :   out bit;
      addr_clk              :   out bit;
      pc_clk                :   out bit;
      op1_clk               :   out bit;
      op2_clk               :   out bit;
      result_clk            :   out bit
    );
end aubie_controller;


architecture behavior of aubie_controller is
begin
    behav: process(clock) is

        type state_type is range 1 to 20; 
        variable next_state: state_type := 1;
	variable current_state: state_type;
        variable opcode: byte;
        variable destination, operand1, operand2 : register_index;
        variable stor_op : alu_operation_code := "0111";
        variable jz_op : alu_operation_code := "1100";
        variable logical_true : dlx_word := x"00000001";
        variable logical_false : dlx_word := x"00000000";

        begin
            if (clock'event and clock = '1') then
                opcode := ir_control(31 downto 24);
                destination := ir_control(23 downto 19);
                operand1 := ir_control(18 downto 14);
                operand2 := ir_control(13 downto 9);

                case (next_state) is
                    when 1 => 
                    
                        memaddr_mux <= "00" after prop_delay; 
                        regfile_clk <= '0' after prop_delay;
                        mem_clk	<= '1' after prop_delay; 
                        mem_readnotwrite <= '1' after prop_delay; 
                        ir_clk <= '1' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay;
                        addr_mux <= '1' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk	<= '0' after prop_delay;
                        op2_clk	<= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;
                        
			next_state := 2;
			current_state := 1;
                    when 2 =>  
                        if opcode(7 downto 4) = "0000" then -- ALU op
                            next_state := 3;
                        elsif opcode = X"20" then  -- STO
                            next_state := 9;
                        elsif opcode = X"30" or opcode = X"31" then -- LD or LDI
                            next_state := 7;
                        elsif opcode = X"22" then -- STOR
                            next_state := 14;
                        elsif opcode = X"32" then -- LDR
                            next_state := 12;
                        elsif opcode = X"40" or opcode = X"41" then -- JMP or JZ
                            next_state := 16;
                        elsif opcode = X"10" then -- NOOP
                            next_state := 19;
                        else -- error
                        end if;
                        current_state := 2;
                    when 3 => 
                        regfile_index <= operand1 after prop_delay; -- The register_index
                        
                        regfile_readnotwrite <= '1' after prop_delay;
                        regfile_clk <= '1' after prop_delay; 
                        mem_clk <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk <= '1' after prop_delay; 
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;
                        next_state := 4;
                        current_state := 3;
                    when 4 => 
                        regfile_index <= operand2 after prop_delay; -- The register_index
                        regfile_readnotwrite <= '1' after prop_delay; 
                        regfile_clk <= '1' after prop_delay; 
                        mem_clk <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '1' after prop_delay; 
                        result_clk <= '0' after prop_delay;
                        next_state := 5;
                        current_state := 4;
                    when 5 => 
                        alu_func <= opcode(3 downto 0) after prop_delay; 
                        regfile_clk <= '0' after prop_delay;
                        mem_clk <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '1' after prop_delay; 
                        next_state := 6;
                        current_state := 5;
                    when 6 => 
                        regfilein_mux <= "00" after prop_delay; 
                        pc_mux <= "00" after prop_delay; 
                        regfile_index <= destination after prop_delay;
                        regfile_readnotwrite <= '0' after prop_delay; 
                        regfile_clk <= '1' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay;
                        pc_clk <= '1' after prop_delay; 
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;
                        next_state := 1;
                        current_state := 6;
                    when 7 => 
                        if (opcode = x"30") then 
                            pc_clk <= '1' after prop_delay;
                            pc_mux <= "00" after prop_delay; 
                            memaddr_mux <= "00" after prop_delay; 
                            addr_mux <= '1' after prop_delay; 
                            regfile_clk <= '0' after prop_delay;
                            mem_clk <= '1' after prop_delay;
                            mem_readnotwrite <= '1' after prop_delay; 
                            ir_clk <= '0' after prop_delay;
                            imm_clk <= '0' after prop_delay;
                            addr_clk <= '1' after prop_delay;
                            op1_clk <= '0' after prop_delay;
                            op2_clk <= '0' after prop_delay;
                            result_clk <= '0' after prop_delay;
                        elsif (opcode = x"31") then -- LDI
                            pc_clk <= '1' after prop_delay;
                            pc_mux <= "00" after prop_delay; 
                            memaddr_mux <= "00" after prop_delay;
                            regfile_clk <= '0' after prop_delay;
                            mem_clk <= '1' after prop_delay;
                            mem_readnotwrite <= '1' after prop_delay;
                            ir_clk <= '0' after prop_delay;
                            imm_clk <= '1' after prop_delay;
                            addr_clk <= '0' after prop_delay;
                            op1_clk <= '0' after prop_delay;
                            op2_clk <= '0' after prop_delay;
                            result_clk <= '0' after prop_delay;
                        end if;
                        next_state := 8;
                        current_state := 7;
                    when 8 => -- LD or LDI (Step2)
                        if (opcode = x"30") then -- LD
                            regfilein_mux <= "01" after prop_delay; 
                            memaddr_mux <= "01" after prop_delay; 
                            regfile_index <= destination after prop_delay;
                            regfile_readnotwrite <= '0' after prop_delay;
                            regfile_clk <= '1' after prop_delay;
                            mem_clk <= '1' after prop_delay;
                            mem_readnotwrite <= '1' after prop_delay;
                            ir_clk <= '0' after prop_delay;
                            imm_clk <= '0' after prop_delay;
                            addr_clk <= '0' after prop_delay; 
                            op1_clk <= '0' after prop_delay;
                            op2_clk <= '0' after prop_delay;
                            result_clk <= '0' after prop_delay;
                            pc_clk <= '0' after prop_delay, '1' after xt_prop_delay; 
                            pc_mux <= "00" after xt_prop_delay;
                           
                        elsif (opcode = x"31") then -- LDI
                        
                            regfilein_mux <= "10" after prop_delay; 
                            regfile_index <= destination after prop_delay;
                            regfile_readnotwrite <= '0' after prop_delay;
                            regfile_clk <= '1' after prop_delay;
                            mem_clk <= '0' after prop_delay;
                            ir_clk <= '0' after prop_delay;
                            imm_clk <= '1' after prop_delay;
                            addr_clk <= '0' after prop_delay;
                            op1_clk <= '0' after prop_delay;
                            op2_clk <= '0' after prop_delay;
                            result_clk <= '0' after prop_delay;
                            pc_clk <= '0' after prop_delay, '1' after xt_prop_delay;
                            pc_mux <= "00" after xt_prop_delay; 

                        end if;
                        next_state := 1;
                        current_state := 8;
                    when 9 => -- STO
                    -- Increment PC.
                        pc_mux <= "00" after prop_delay;
                        pc_clk <= '1' after prop_delay;
                        next_state := 10;
                        current_state := 9;
                    when 10 => 

                        memaddr_mux <= "00" after prop_delay;
                        addr_mux <= '1' after prop_delay; 
                        regfile_clk <= '0' after prop_delay;
                        mem_clk <= '1' after prop_delay; 
                        mem_readnotwrite <= '1' after prop_delay; 
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '1' after prop_delay; 
                        pc_clk <= '0' after prop_delay; 
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;

                        next_state := 11;
                        current_state := 10;
                    when 11 => 

                        memaddr_mux <= "00" after prop_delay;
                        pc_mux <= "01" after prop_delay, "00" after xt_prop_delay;
                        regfile_index <= operand1 after prop_delay;
                        regfile_readnotwrite <= '1' after prop_delay; 
                        regfile_clk <= '1' after prop_delay;
                        mem_clk <= '1' after prop_delay; 
                        mem_readnotwrite <= '0' after prop_delay; 
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay; 
                        pc_clk <= '1' after prop_delay;
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;
                        next_state := 1;
                        current_state := 11;
                    when 12 => 
                        addr_mux <= '0' after prop_delay; 
                        regfile_index <= operand1 after prop_delay;
                        regfile_readnotwrite <= '1' after prop_delay;
                        regfile_clk <= '1' after prop_delay;
                        mem_clk <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '1' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;

                        next_state := 13;
                        current_state := 12;
                    when 13 => 
                        regfilein_mux <= "01" after prop_delay; 
                        memaddr_mux <= "01" after prop_delay; 
                       
                        regfile_index <= destination after prop_delay;
                        regfile_readnotwrite <= '0' after prop_delay;
                        regfile_clk <= '1' after prop_delay;
                        mem_clk <= '1' after prop_delay;
                        mem_readnotwrite <= '1' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay; 
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;
                        pc_clk <= '0' after prop_delay, '1' after xt_prop_delay;
                        pc_mux <= "00" after xt_prop_delay;
                                                next_state := 1;
                        current_state := 13;
                    when 14 => 

                        addr_mux <= '0' after prop_delay;
                        regfile_index <= destination after prop_delay;
                        regfile_readnotwrite <= '1' after prop_delay;
                        regfile_clk <= '1' after prop_delay;
                        mem_clk <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '1' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;

                        next_state := 15;
                        current_state := 14;
                    when 15 => 
                        memaddr_mux <= "00" after prop_delay;
                        pc_mux <= "01" after prop_delay, "00" after xt_prop_delay;
                        alu_func <= stor_op after prop_delay;
                        regfile_index <= operand1 after prop_delay;
                        regfile_readnotwrite <= '1' after prop_delay;
                        regfile_clk <= '1' after prop_delay;
                        mem_clk <= '1' after prop_delay;
                        mem_readnotwrite <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay; 
                        pc_clk <= '1' after prop_delay;
                        op1_clk <= '1' after prop_delay; 
                        op2_clk <= '1' after prop_delay;
                        result_clk <= '1' after prop_delay;

                        next_state := 1;
                        current_state := 15;
                    when 16 => -- JMP or JZ
                        pc_mux <= "00" after prop_delay;
                        pc_clk <= '1' after prop_delay;
                        next_state := 17;
                        current_state := 16;
                    when 17 => -- JMP
                        pc_clk <= '0' after prop_delay;
                        memaddr_mux <= "00" after prop_delay; 
                        addr_mux <= '1' after prop_delay; 
                        regfile_clk <= '0' after prop_delay;
                        mem_clk <= '1' after prop_delay;
                        mem_readnotwrite <= '1' after prop_delay; 
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '1' after prop_delay;
                        op1_clk <= '0' after prop_delay;
                        op2_clk <= '0' after prop_delay;
                        result_clk <= '0' after prop_delay;
                        next_state := 18;
                        if (opcode = x"40") then -- JMP
                            next_state := 18;
                        else 
                            next_state := 20;
                        end if; 
                        current_state := 17;
                    when 18 => 
                        if (opcode = x"40") then -- JMP
                        
                            pc_mux <= "01" after prop_delay;
                            pc_clk <= '1' after prop_delay;
                        end if;
                        if (opcode = x"41") then -- JZ
                        
                            if (alu_out = logical_true) then
                                pc_mux <= "01" after prop_delay;
                                pc_clk <= '1' after prop_delay;
                            else
                                pc_clk <= '1' after prop_delay;
                                pc_mux <= "00" after prop_delay;
                            end if;
                        end if;
                        next_state := 1;
                        current_state := 18;
                    when 19 => -- NOOP
                        pc_mux <= "00" after prop_delay;
                        pc_clk <= '1' after prop_delay;

                        next_state := 1;
                        current_state := 19;
                    when 20 => -- JZ 
                        
                        alu_func <= jz_op after prop_delay;
                        regfile_index <= operand1 after prop_delay;
                        regfile_readnotwrite <= '1' after prop_delay;
                        regfile_clk <= '1' after prop_delay;
                        mem_clk <= '0' after prop_delay;
                        ir_clk <= '0' after prop_delay;
                        imm_clk <= '0' after prop_delay;
                        addr_clk <= '0' after prop_delay;
                        pc_clk <= '0' after prop_delay;
                        op1_clk <= '1' after prop_delay;
                        op2_clk <= '1' after prop_delay;
                        result_clk <= '1' after prop_delay;
                        current_state := 20;
                        next_state := 18;
                    when others => null;
                end case;
            elsif clock'event and clock = '0' then
            -- reset register clocks
                regfile_clk <= '0' after prop_delay;
                mem_clk <= '0' after prop_delay;
                ir_clk <= '0' after prop_delay;
                imm_clk <= '0' after prop_delay;
                addr_clk <= '0' after prop_delay;
                pc_clk <= '0' after prop_delay;
                op1_clk <= '0' after prop_delay;
                op2_clk <= '0' after prop_delay;
                result_clk <= '0' after prop_delay;
            end if;
        end process behav;
end behavior;
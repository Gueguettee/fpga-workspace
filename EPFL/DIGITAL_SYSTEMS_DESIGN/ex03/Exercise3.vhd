process(all) 
begin
    OutxDO <= In0xDI;
    if SelxSI = '1' then 
        OutxDO <= In1xDI; 
    end if;
end process;

process(all) 
begin
    if SelxSI = '1' then 
        OutxDO <= In1xDI; 
    else
        OutxDO <= In0xDI; 
    end if;
end process;

    signal ResxDN,ResxDP:
    unsigned(8-1 downto0); 

begin 

    process(CLKxCI,RSTxRI) 
    begin 
        if(RSTxRI= '1')then 
            ResxDP<=(others=>'0'); 
        elsif(CLKxCI'event and CLKxCI='1') then
            ResxDN <= ResxDP; 
        end if; 
    end process; 

    ResxDN<=std_logic_vector(to_unsigned(AxDI)+to_unsigned(BxDI)) when to_unsigned(CxDI) + to_unsigned(DxDI) > "00000001" else
        std_logic_vector(to_unsigned(AxDI)-to_unsigned(BxDI)-"00000001") when to_unsigned(CxDI) > to_unsigned(DxDI) and to_unsigned(DxDI) /= (others => '0') else 
        std_logic_vector(to_unsigned(AxDI)+1)
        
    
    
    signal ResxDN, ResxDP : unsigned(8-1 downto 0);

begin

    process(CLKxCI)
    begin
        if (RSTxRI = '1') then
            ResxDP <= (others => '0');
        elsif (CLKxCI'event and CLKxCI = '1') then
            ResxDP <= ResxDN;
        end if;
    end process;

    process(Sel0xSI)
    begin
        if Sel0xSI = '1' then
            ResxDN <= AxDI + BxDI;
        elsif Sel1xSI = '1' then
            ResxDN <= AxDI + CxDI;
        else
            ResxDN <= to_unsigned(DxDI) + "00000001";
        end if;
    end process;
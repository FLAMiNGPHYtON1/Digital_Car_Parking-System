library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
entity VLSIProject is
port 
(
  clock,reset_mode: in std_logic;										  -- clock and reset of the car parking system
  Entrance_Sensor, Exit_Sensor: in std_logic; 							  -- Two senors, one at entrance, one at exit
  Password: in std_logic_vector(3 downto 0);							  -- input password 
  Number_Plate: in std_logic_vector(3 downto 0);  						  -- System detects number plate of car to see if it is registered
  BioAuth: in std_logic;									              -- System takes BioAuth input in form of fingerprint/face scan to see if it is registered
  Gate_Control: in std_logic;											  -- System controls functioning of gate motor
  o_Car_Count : out std_logic_vector(2 downto 0)						  -- System outputs total number of cars current parked via LCD display
);
end VLSIProject;

architecture Behavioral of VLSIProject is
-- FSM States
	type FSM_States is (Idle, Car_Exit, Current_Parked_Cars, STOP, Wait_Password, Wrong_Password,  --
								Right_Password, Unregistered_No_Plate, Registered_No_Plate, Wrong_BioAuth, 	-- System States defined
								Right_BioAuth, Gate_Open, Close_Gate );
								
	signal current_state, next_state: FSM_States;	-- Signal which carries transition inputs for state machine
	signal Car_Count: std_logic_vector (2 downto 0);	-- signal which carries value for total number of cars in system
	
begin

	
-- Sequential circuits
process(clock,reset_mode)	-- Process which handles transitioning of states on positive edge of rising clock as well as asynchronous reset of system for intialization

	begin

	 if(reset_mode='0') then
	 
			current_state <= Idle;
	  
	 elsif(rising_edge(clock)) then
	 
			current_state <= next_state;
	  
	 end if;
	 
end process;

process(current_state, Entrance_Sensor, Password, Number_Plate, BioAuth, Exit_Sensor, Car_Count, Gate_Control) -- Process which defines the transition conditions for each state as well as the behaviour of system in each state.

	begin
	
	   
		next_state <= current_state;				 -- To prevent undefined value for next state, we assign value of current state to next state.
		case current_state is 		 
			when Idle =>								-- Behaviour of FSM in idle state
				 if(Entrance_Sensor = '1') then
					next_state <= Current_Parked_Cars;				  
				 else				 
					next_state <= Idle;				  
				 end if;				 
			when Current_Parked_Cars =>			-- Behaviour of FSM in Current_Parked_Cars state			
				if(Car_Count >= "101") then		-- If there are 5 cars in system, system goes to STOP state until there are less than 5 cars in system				 
					next_state <= STOP;					
				else					
					next_state <= Wait_Password;					
				end if;				
			when Wait_Password =>					-- Behaviour of FSM in Wait_Password State	 
				if(Password = "1010") then			-- If password is equal to 1010 then system transitions		
					next_state <= Right_Password;
				else										-- If password is not, then system stays in same state
					next_state <= Wrong_Password;		
				end if;				 	
			when Wrong_Password =>					-- Behaviour of Wrong_Password State			
				if(Password = "1010") then							
					next_state <= Right_Password;				
				else				
					next_state <= Wrong_Password;				
				end if;				  
			when Right_Password =>			 		-- Behaviour of Right_Password State			 
				if(Number_Plate = "1111") or (Number_Plate = "1110") 
				or (Number_Plate = "1101") or (Number_Plate = "1100") 
				or (Number_Plate = "1011") then	-- If Number Plate is equal to 15,14,13,12 or 11, then system transitions					
					next_state <= Registered_No_Plate;				
				else										-- If not system goes to unregistered_no_plate state, where it stays until car leaves			
					next_state <= Unregistered_No_Plate;			
		      end if;			
			when Unregistered_No_Plate =>			-- Behaviour of Unregistered_No_Plate State			
				if(Entrance_Sensor = '1') then					
					next_state <= Unregistered_No_Plate;				
				else			
					next_state <= Idle;					
				end if;			
			when Registered_No_Plate =>			-- Behaviour of Registered_No_Plate State		
				if(BioAuth = '1') then				-- System takes BioAuth input here; if equal to 1, system transitions				
					next_state <= Right_BioAuth;				
				else										-- If not, system goes to Wrong_BioAuth stays, where it stays until car leaves				
					next_state <= Wrong_BioAuth;					
				end if;	
			when Wrong_BioAuth =>					-- Behaviour of Wrong_BioAuth State			
				if(Entrance_Sensor = '1') then					
					next_state <= Wrong_BioAuth;					
				else				
					next_state <= Idle;					
				end if;				
			when Right_BioAuth =>					-- Behavior of Right_BioAuth State				
				if(Gate_Control = '1') then		-- Gate opens as user is verified, then transitions				
					next_state <= Gate_Open;					
				else					
					next_state <= Right_BioAuth;					
				end if;				
			when Gate_Open =>							-- Behavior of Gate_Open state			
				if(Entrance_Sensor = '0') then	-- After car leaves entrance and enters parking lot, system transitions					
					next_state <= Close_Gate;					
				else				
					next_state <= Gate_Open;					
				end if;			
			when Close_Gate =>						-- Behaviour of Close_Gate state			
				if(Gate_Control = '0') then		-- Gate starts closing so system can start to reset										
					next_state <= Idle;					
				else				
					next_state <= Close_Gate;					
				end if;				
			when STOP =>								-- Behaviour of STOP state	
				  if(Exit_Sensor = '0') then		-- Until car leaves, system stays here				  
						next_state <= STOP;						
				  else				  
						next_state <= Car_Exit;		-- when car starts leaving, system transitions						
				  end if;				  
		   when Car_Exit =>							-- Behaviour of Car_Exit state			
				if(Exit_Sensor = '0') then			-- If car has completely left, system goes back to default state, and reduces car count in lot by 1					
					next_state <= Idle;					
				else					
					next_state <= Car_Exit;				
				end if;
			when others => next_state <= Idle;	-- If unrecognized input detected in system, system defaults to Idle state to prevent corruption of FSM							  		  
	end case;		  
end process;

process (clock) 										-- Process that keeps track of number of cars in system at every rising edge

	begin
	
	if(rising_edge(clock)) then
	 
		if (current_state = Close_Gate) and (Gate_Control = '0') then	-- If system detected car has completely entered into parking lot, then car count increased by 1
		
			Car_Count <= Car_Count + "001";
		
		elsif (current_state = STOP) and (Exit_Sensor = '1') then		-- If system detects car has completely left oparking lot, then car count decreased by 1
			
			Car_Count <= Car_Count - "001";
		
		end if;
	  
	 end if;
	 
end process;

o_Car_Count <= Car_Count;											-- Assigning value in Car_Count signal to Car_Count output
		  		 

end Behavioral;

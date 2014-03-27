within BrineProp.SpecificEnthalpies;
function appMolarHeatCapacity_CaCl2_White
//2D-fit Reproduction of measurements of heat capacity of KCl solution
  extends PartialAppMolar_CaCl2_White;
  output Partial_Units.PartialMolarHeatCapacity Cp_app_mol;
protected
  String msg = "";
algorithm
  if outOfRangeMode>0 then
    if not ( (ignoreLimit_h_CaCl2_Tmin or T>=T_min) and T<=T_max) then
      msg :="Temperature is " + String(T-273.15) + "�C, but must be between " +
        String(T_min-273.15) + "�C and " + String(T_max-273.15) + "�C (BrineProp.SpecificEnthalpies.appMolarHeatCapacity_CaCl2_White)";
      if outOfRangeMode==1 then
      print(msg);
      elseif outOfRangeMode==2 then
       assert(true, msg);
      end if;
    end if;
  end if;

  Cp_app_mol:=(mola^b+c)*(k-l*(m-T)^(-1));
//   print("Cp_app_mol_CaCl2= "+String(Cp_app_mol)+"J/kg");
end appMolarHeatCapacity_CaCl2_White;

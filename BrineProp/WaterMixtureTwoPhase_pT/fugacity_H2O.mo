within BrineProp.WaterMixtureTwoPhase_pT;
function fugacity_H2O
//  extends fugacity_pTX;
  input SI.Pressure p;
  input SI.Temp_K T;
  output Real phi=0;
algorithm
  assert(false, "dummy function for compatibility, should not be called");
end fugacity_H2O;

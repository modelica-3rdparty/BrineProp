within BrineProp;
package BrineGas3Gas "Gas mixture of CO2+N2+CH4+H2O"
  extends PartialBrineGas(
    substanceNames={"carbondioxide","nitrogen","methane","water"},
    iCO2=1,
    iN2=2,
    iCH4=3,
    MM_vec = {M_CO2,M_N2,M_CH4,M_H2O},
    nM_vec = {nM_CO2,nM_N2,nM_CH4,nM_H2O});

  extends PartialFlags;

 redeclare model extends BaseProperties
 //Dummy for OM
 end BaseProperties;
/* redeclare record extends ThermodynamicState
 //Dummy for OM
 end ThermodynamicState;
*/
  constant Boolean waterSaturated=false "activates water saturation";

  replaceable function waterSaturatedComposition_pTX
  "calculates the water saturated mass vector for a given Temperature"
  //saturates the mixture with water
    extends Modelica.Icons.Function;
    input SI.Pressure p;
    input SI.Temperature T;
    input SI.MassFraction[nX] X_in "Mass fractions of mixture";
    output SI.MassFraction X[nX] "Mass fractions of mixture";
protected
      SI.Pressure y_H2O=Modelica.Media.Water.IF97_Utilities.BaseIF97.Basic.psat(T)/p;
      Real y[nX] "mole fractions";
  algorithm
    if debugmode then
      print("Running waterSaturatedComposition_pTX("+String(p/1e5)+" bar,"+String(T-273.15)+" degC, X="+Modelica.Math.Matrices.toString(transpose([X_in]))+")");
  //    print("y_H2O"+String(y_H2O)+", X[end]="+String(X_in[end]));
    end if;

    y:= X_in./MM_vec;

    if y_H2O<1 and X_in[end]>0 then
      //print(""+String(y_H2O));
      y:=cat(1,y[1:nX-1]/(sum(y[1:nX-1]))*(1-y_H2O), {y_H2O})
      "gases + fixed water fraction";
    else
      y:=cat(1,fill(0,nX-1), {y_H2O}) "only water vapour";
    end if;
    X:=y.*MM_vec "convert to mass fractions";
    X:=X/sum(X) "normalize";

  end waterSaturatedComposition_pTX;

  redeclare function extends density "water-saturated density from state"

  algorithm
    d := density_pTX(
      p=state.p,
      T=state.T,
      X= if waterSaturated then
        waterSaturatedComposition_pTX(state.p,state.T,state.X)
    else state.X);
  //  else state.X[end - nX + 1:end]);
  //      waterSaturatedComposition_pTX(state.p,state.T,state.X[end - nX+1:end])
  //  assert(lambda>0,"lambda="+String(lambda));
  end density;

  replaceable function extends specificHeatCapacityCp_pTX
    "calculation of specific heat capacities of gas mixture"
    import SG = Modelica.Media.IdealGases.SingleGases;
    import IF97=Modelica.Media.Water.IF97_Utilities;
protected
      SG.H2O.ThermodynamicState state=SG.H2O.ThermodynamicState(p=0,T=T);
      SI.SpecificHeatCapacity cp_CO2=SG.CO2.specificHeatCapacityCp(state);
      SI.SpecificHeatCapacity cp_N2=SG.N2.specificHeatCapacityCp(state);
      SI.SpecificHeatCapacity cp_CH4=SG.CH4.specificHeatCapacityCp(state);
      SI.SpecificHeatCapacity cp_H2O=IF97.cp_pT(min(p,IF97.BaseIF97.Basic.psat(T)-1),T=T)
      "below psat -> gaseous";

      SI.SpecificHeatCapacity cp_vec[:]={cp_CO2,cp_N2,cp_CH4,cp_H2O}; //the two-phase models rely on this order!

  algorithm
    if debugmode then
      print("Running specificHeatCapacityCp_pTX("+String(p/1e5)+" bar,"+String(T-273.15)+" degC, X="+Modelica.Math.Matrices.toString(transpose([X]))+")");
    end if;

    if not ignoreNoCompositionInBrineGas and not min(X)>0 then
      print("No gas composition, assuming water vapour.(BrineProp.BrineGas_3Gas.specificHeatCapacityCp_pTX)");
    end if;

  /*  if waterSaturated then
    cp := cp_vec * waterSaturatedComposition_pTX(p,T,X[end - nX+1:end]);
  else */
  //    cp := cp_vec * X[end - nX+1:end];
    cp := cp_vec * cat(1,X[1:end-1],{if min(X)>0 then X[end] else 1});
      //  end if;

  /*  print("cp_CO2: "+String(cp_vec[1])+" J/kg");
  print("cp_N2: "+String(cp_vec[2])+" J/kg");
  print("cp_CH4: "+String(cp_vec[3])+" J/kg");
  print("cp_H2O: "+String(cp_vec[4])+" J/kg"); */

  end specificHeatCapacityCp_pTX;

  redeclare function extends dynamicViscosity
  "water-saturated  thermal conductivity of water"
  //very little influence of salinity
  algorithm
    eta := dynamicViscosity_pTX(
          p=state.p,
          T=state.T,
          X= if waterSaturated then
        waterSaturatedComposition_pTX(state.p,state.T,state.X)
    else state.X);
  //  else state.X[end - nX + 1:end]);
  //  assert(lambda>0,"lambda="+String(lambda));
  end dynamicViscosity;

  redeclare function extends dynamicViscosity_pTX
  "calculation of gas dynamic Viscosity"
  /*  import NG = Modelica.Media.IdealGases.Common.SingleGasNasa;
  input SI.Pressure p;
  input SI.Temperature T;
  input SI.MassFraction[nX] X "Mass fractions of mixture";
  output SI.DynamicViscosity eta;*/
  algorithm
    eta:=Modelica.Media.Air.MoistAir.dynamicViscosity(
      Modelica.Media.Air.MoistAir.ThermodynamicState(
      p=0,
      T=T,
      X={0,0}));
  end dynamicViscosity_pTX;

  redeclare function extends thermalConductivity
  "water-saturated  thermal conductivity of water"
  //very little influence of salinity
  algorithm
    lambda := thermalConductivity_pTX(
          p=state.p,
          T=state.T,
          X= if waterSaturated then
        waterSaturatedComposition_pTX(state.p,state.T,state.X)
    else state.X);
  //  else state.X[end - nX + 1:end]);
  //  assert(lambda>0,"lambda="+String(lambda));
  if lambda<0 then
    print("lambda = " + String(lambda) + "W/(m.K)");
  end if;

  end thermalConductivity;

  redeclare function extends thermalConductivity_pTX
  "calculation of gas thermal conductivity"
  /*  import NG = Modelica.Media.IdealGases.Common.SingleGasNasa;
  input SI.Pressure p;
  input SI.Temperature T;
  input SI.MassFraction[nX] X "Mass fractions of mixture";
  output SI.DynamicViscosity eta;*/
  algorithm
    lambda:=Modelica.Media.Air.MoistAir.thermalConductivity(
      Modelica.Media.Air.MoistAir.ThermodynamicState(p=0,T=T,X={0,0}));
  end thermalConductivity_pTX;

  redeclare replaceable function specificEnthalpy_pTX
  "calculation of specific enthalpy of gas mixture"
  //  import Modelica.Media.IdealGases.Common.SingleGasNasa;
    import Modelica.Media.IdealGases.SingleGases;
    extends Modelica.Icons.Function;
    input AbsolutePressure p "Pressure";
    input Temperature T "Temperature";
    input MassFraction X[:]=reference_X "Mass fractions";
    output SpecificEnthalpy h "Specific enthalpy";
protected
    SI.SpecificEnthalpy h_H2O_sat=Modelica.Media.Water.IF97_Utilities.BaseIF97.Regions.hv_p(p);
    SI.SpecificEnthalpy h_H2O=max(h_H2O_sat, Modelica.Media.Water.WaterIF97_pT.specificEnthalpy_pT(p,T))
    "to make sure it is gaseous";

    SingleGases.H2O.ThermodynamicState state=SingleGases.H2O.ThermodynamicState(p=0,T=T);
    SI.SpecificEnthalpy h_CO2=SingleGases.CO2.specificEnthalpy(state);
    SI.SpecificEnthalpy h_N2=SingleGases.N2.specificEnthalpy(state);
    SI.SpecificEnthalpy h_CH4=SingleGases.CH4.specificEnthalpy(state);

    SI.SpecificEnthalpy[:] h_vec={h_CO2,h_N2,h_CH4,h_H2O}; //the two-phase models rely on this order!
    SI.MassFraction X_[size(X,1)] "OM workaround for cat";
  algorithm
    X_[1:end-1]:=X[1:end-1] "OM workaround for cat";
    X_[end]:=if min(X)>0 then X[end] else 1 "OM workaround for cat";

    if debugmode then
      print("Running specificEnthalpy_pTX("+String(p/1e5)+" bar,"+String(T-273.15)+" degC, X="+Modelica.Math.Matrices.toString(transpose([X]))+")");
    end if;

    if not min(X)>0 and not ignoreNoCompositionInBrineGas then
      print("No gas composition, assuming water vapour.(BrineProp.BrineGas_3Gas.specificEnthalpy_pTX)");
    end if;

    h := h_vec*X_ "mass weighted average, OM workaround for cat";
  //h := h_vec * cat(1,X[1:end-1], {if min(X)>0 then X[end] else 1}) "Doesn't work in function in OM";

  /*  print("h_CO2: "+String(h_CO2)+" J/kg");
  print("h_N2: "+String(h_N2)+" J/kg");
  print("h_CH4: "+String(h_CH4)+" J/kg");
  print("h_H2O: "+String(h_H2O)+" J/kg");
  print("T: "+String(state.T)+" K");
  */
  end specificEnthalpy_pTX;

  redeclare function extends specificEnthalpy
  "water-saturated specific enthalpy of gas phase"
  algorithm
       h := specificEnthalpy_pTX(
          p=state.p,
          T=state.T,
          X= if waterSaturated then
       waterSaturatedComposition_pTX(state.p,state.T,state.X)
    else state.X);
  //  else state.X[end - nX + 1:end]);

  end specificEnthalpy;

  annotation (Documentation(info="<html>
<p><b>BrineGas_3Gas</b> is a medium package that, based on Brine.PartialBrineGas, defines a brine with 3 gases (CO<sub>2</sub>, N<sub>2</sub>, CH<sub>4</sub>), which are the main gases in the geofluid in Gross Schoenebeck, Germany.</p>
<h4>Usage</h4>
<p>It is based on Modelica.Media, the usage is accordingly:</p>
<p>Create an instance of the Medium (optionally deactivating range checks, for all options see .PartialFlags): </p>
<pre>  package Medium = BrineGas_3Gas(ignoreLimitN2_T=false);</pre>
<p>Create an instance of Medium.Baseproperties: </p>
<pre>  Medium.BaseProperties props;</pre>
<p>Use the BaseProperties model to define the actual brine composition(Xi or X), to define the thermodynamic state and calculate the corresponding properties. </p>
<pre>  props.p = 1e5;
  props.T = 300;
  props.Xi = {1-4, 7e-4, 6e-005} \"CO2, N2, CH4\"
  d = props.d;
</pre>

<p>See <code><a href=\"Modelica://BrineProp.Examples.BrineGas\">BrineProp.Examples.BrineGas</a></code> for more usage examples.</p>
<p>Returns properties for given composition when _pTX functions are called directly.
  Returns properties for given gas composition + saturated water when called via state functions (e.g. density)
</p>  
<p>All calculated values are returned in SI units and are mass based.</p>
<h4>Potential speedup:</h4>
<p>Calculate water saturated composition externally once (instead of separately in each property function) and pass on.</p>
</html>"));
end BrineGas3Gas;

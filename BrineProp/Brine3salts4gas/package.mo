within BrineProp;
package Brine3salts4gas "Two-phase aqueous solution of NaCl, KCl, CaCl2, N2, CO2, CH4"

//TODO: use Fluid limits

  extends SaltDataDuan;
                       // "for the molar masses below"

  extends PartialBrineMultiSaltMultiGasTwoPhase(
    saltNames = {"sodium chloride","potassium chloride","calcium chloride"},
    redeclare package Salt_data = BrineProp.SaltDataDuan,
    saltConstants = {
      saltConstants_NaCl,
      saltConstants_KCl,
      saltConstants_CaCl2},
    MM_salt = {M_NaCl,M_KCl,M_CaCl2},
    nM_salt = {nM_NaCl,nM_KCl,nM_CaCl2},
    final iNaCl=1,
    final iKCl=2,
    final iCaCl2=3,
    iCO2=4,
    iN2=5,
    iCH4=6,
    iH2=7,
    gasNames = {"carbondioxide","nitrogen","methane","hydrogen"},
    final MM_gas = {M_CO2,M_N2,M_CH4,M_H2},
    final nM_gas = {nM_CO2,nM_N2,nM_CH4,nM_H2}); //iGas not final, because reassigned in Brine5salts3gas
    //order of gases must be consistent with Brine3Gas TODO: pass order or copy enthalpy/density/cp here

  redeclare function extends setState_pTX "to avoid check error"
  end setState_pTX;

  redeclare function extends setState_phX "to avoid check error"
  end setState_phX;

  redeclare function extends setState_dTX
  algorithm
    assert(false,"Running dummy setState_dTX. Shouldn't be called.");
    state := setState_pTX(
      1e5,
      T,
      X) ",fluidnames)";
  end setState_dTX;

  redeclare replaceable function extends solubilities_pTX
  "solubility calculation, returns gas concentration in kg/kg H2O"
  algorithm
  //  print("p_gas={"+String(p_gas[1])+", "+String(p_gas[2])+", "+String(p_gas[3])+"} (solubilities_pTX)");
    if debugmode then
        print("Running solubilities_pTX("+String(p/1e5)+" bar,"+String(T-273.15)+" C, ignoreTlimit="+String(ignoreTlimit)+", X="+Modelica.Math.Matrices.toString(transpose([X]))+")");
    end if;
      solu[iCO2-nX_salt] := if X[iCO2]>0 then solubility_CO2_pTX_Duan2006(p,T,X_l,MM_vec,p_gas[iCO2-nX_salt],ignoreTlimit) else -1
    "aus GasData, mol/kg_H2O -> kg_CO2/kg_H2O";
      solu[iN2-nX_salt] :=if X[iN2] > 0 then solubility_N2_pTX_Mao2006(p,T,X_l,MM_vec,p_gas[iN2-nX_salt],ignoreTlimit) else -1
    "aus GasData, mol/kg_H2O -> kg_N2/kg_H2O";
  //    solu[2] := if X[nX_salt+2]>0 then solubility_N2_pTX_Harting(p,T,X_l,MM_vec,p_gas[2]) else -1
      solu[iCH4-nX_salt] := if X[iCH4]>0 then solubility_CH4_pTX_Duan2006(p,T,X_l,MM_vec,p_gas[iCH4-nX_salt],ignoreTlimit) else -1
    "aus GasData, mol/kg_H2O -> kg_CH4/kg_H2O";
      solu[iH2-nX_salt] := if X[iH2]>0 then solubility_H2_pTX_Chabab2020(p,T,X_l,MM_vec,p_gas[iH2-nX_salt],ignoreTlimit) else -1
    "aus GasData, mol/kg_H2O -> kg_CH4/kg_H2O";

  //  print("k={"+String(solu[1]/p_gas[1])+", "+String(solu[2]/p_gas[2])+", "+String(solu[3]/p_gas[3])+"}(solubilities_pTX)");
  //  print("solu={"+String(solu[1])+", "+String(solu[2])+", "+String(solu[3])+"}(solubilities_pTX)");
  //  print(Modelica.Math.Matrices.toString({MM_vec}));
  end solubilities_pTX;

  redeclare function extends density_liq_pTX
protected
    constant Integer[:] liqIndex=cat(1,1:nX_salt,{nX});
    Real X_[:] =  cat(1, X[1:nX_salt], {1-sum(X[1:nX_salt])}); //recalculate water mass fraction when gases are omitted (which they are in the density function)
  algorithm
    d := density_Duan2008_pTX(p,T,X_,MM[liqIndex],
    saltConstants);
  //   print("density_liquid_pTX: "+String(p*1e-5)+" bar,"+String(T)+" K->"+String(d)+"kg/m^3");
  end density_liq_pTX;

  redeclare replaceable function extends density_gas_pTX
  algorithm
    d :=BrineGas4Gas.density_pTX(
      p,
      T,
      X,
      MM);
  //   print("density_liquid_pTX: "+String(p*1e-5)+" bar,"+String(T)+" K->"+String(d)+"kg/m^3");
  end density_gas_pTX;

 redeclare function extends specificEnthalpy_liq_pTX
 // Partial_Units.Molality molalities = massFractionsToMoleFractions(X, MM_vec);
 //  SI.SpecificEnthalpy h_H2O := Modelica.Media.Water.WaterIF97_pT.specificEnthalpy_pT(p, T) "H2O";
 //extends specificEnthalpy_pTX_liq_Francke_cp(MM_vec=MM_salt);
protected
   parameter Integer[:] liqIndex=cat(1,1:nX_salt,{nX});
 algorithm
     h := specificEnthalpy_pTX_liq_Francke_cp(p,T,X[liqIndex],MM_vec[liqIndex],ignoreTlimit=ignoreTlimit);
 //    h := SpecificEnthalpies.specificEnthalpy_pTX_Driesner(p,T,X);
 //  print(String(p*1e-5)+" bar,"+String(T)+" K->"+String(h)+" J/kg (Brine_Duan_Multi_TwoPhase_ngas_3.specificEnthalpy_liq_pTX)");
 end specificEnthalpy_liq_pTX;

 redeclare replaceable function extends specificEnthalpy_gas_pTX

 algorithm
     h :=BrineGas4Gas.specificEnthalpy_pTX(
     p,
     T,
     X);                                           //,MM
 end specificEnthalpy_gas_pTX;

 redeclare function extends dynamicViscosity_liq
protected
   SI.Temperature T_corr;
protected
   parameter Integer[:] liqIndex=cat(1,1:nX_salt,{nX});
 algorithm
  if state.T<273.16 then
     print("T="+String(state.T)+" too low (<0 degC), setting to 0 degC in BrineProp.Brine5salts3gas.dynamicViscosity_liq");
  end if;
  T_corr:= max(273.16,state.T);

  /*eta := Viscosities.dynamicViscosity_Duan_pTX(
    state.p,
    T_corr,
    state.X_l,
    MM_vec,
    Salt_data.saltConstants);*/
    eta := dynamicViscosity_DuanZhang_pTXd(
       state.p,
       T_corr,
       state.X[liqIndex],
       state.d,
       MM_vec[liqIndex],
       saltConstants);
       assert(eta>0,"Error in liquid viscosity calculation.");
 end dynamicViscosity_liq;

 redeclare function extends dynamicViscosity_gas
 algorithm
   eta  :=BrineGas4Gas.dynamicViscosity(BrineGas4Gas.ThermodynamicState(
     state.p,
     state.T,
     state.X_g));
   assert(eta>0,"Error in gas viscosity calculation.");
 end dynamicViscosity_gas;

  redeclare function extends saturationPressures
  algorithm

  //  if gasname =="carbondioxide" then
      p_sat[iCO2-nX_salt] := if X[iCO2]>0 then degassingPressure_CO2_Duan2006(p,T,X,MM_vec) else 0
    "aus GasData TODO: use numeral";
  //  elseif gasname =="nitrogen" then
      p_sat[iN2-nX_salt] :=if X[iN2] > 0 then GasData.degassingPressure_N2_Mao2006(p,T,X,MM_vec) else 0
    "aus GasData";
  //  elseif gasname =="methane" then
      p_sat[iCH4-nX_salt] := if X[iCH4]>0 then degassingPressure_CH4_Duan2006(p,T,X,MM_vec) else 0
    "aus GasData";
      p_sat[iCH4-nX_salt] := if X[iH2]>0 then degassingPressure_H2_Chabab2020(p,T,X,MM_vec) else 0
    "aus GasData";

  //  end if;
    if debugmode then
      print("saturationPressures("+String(p)+","+String(T)+")={"+Modelica.Math.Matrices.toString({p_sat})+"}");
    end if;
  end saturationPressures;

  redeclare function extends thermalConductivity
  "Thermal conductivity of water"
  algorithm
    lambda := Modelica.Media.Water.IF97_Utilities.thermalConductivity(
        state.d,
        state.T,
        state.p,
        state.phase);
  assert(lambda>0,"lambda = " + String(lambda) + "W/(m.K)");
  end thermalConductivity;

  redeclare function extends surfaceTension
  algorithm
     sigma:=Modelica.Media.Water.WaterIF97_pT.surfaceTension(sat)
    "TODO http://www.if.ufrgs.br/~levin/Pdfs.dir/6756.pdf";
  end surfaceTension;

  redeclare function extends specificHeatCapacityCp_liq
  algorithm
      cp:=specificHeatCapacityCp_pTX_liq_Francke(p=state.p,T=state.T,X=state.X,
          MM_vec=MM_salt);
  end specificHeatCapacityCp_liq;

  redeclare function extends specificHeatCapacityCp_gas
  "calculation of gas specific heat capacity"
  import SG = Modelica.Media.IdealGases.SingleGases;
  algorithm
    if state.x>0 then

      cp :=BrineGas4Gas.specificHeatCapacityCp_pTX(
        p=state.p,
        T=state.T,
        X=X_g[end - nX_gas:end]);
    else
      cp:=-1;
    end if;

      annotation (Documentation(info="<html>
                                <p>In the two phase region this function returns the interpolated heat capacity between the
                                liquid and vapour state heat capacities.</p>
                                </html>"));
  end specificHeatCapacityCp_gas;

  annotation (Documentation(info="<html>
<p><b>BrineProp.Brine3salts3gas</b> is a medium package that, based on Brine.BrineProp.PartialBrineMultiSaltMultiGasTwoPhase, defines a brine property model with 3 salts (NaCl, KCl, CaCl<sub>2</sub>) and 3 gases (CO<sub>2</sub>, N<sub>2</sub>, CH<sub>4</sub>), which are the main constituents of the geofluid in Gross Schoenebeck, Germany.</p>
<p>It was used for the calculations documented in this <a href=\"http://nbn-resolving.de/urn:nbn:de:kobv:83-opus4-47126\">PhD thesis</a>.</p>
<h4>Usage</h4>
<p>As it is based on <a href=\"Modelica://Modelica.Media\">Modelica.Media</a>, the usage differs little from the usage of the <a href=\"Modelica://Modelica.Media.Water.WaterIF97_pT\">two-phase water model</a>:</p>
<p>Create an Instance of the Medium (optionally deactivating range checks, for all options see <a href=\"Modelica://BrineProp.PartialFlags\">.PartialFlags</a> ): </p>
<pre> package Medium = Brine_Duan_Multi_TwoPhase_ngas_3;</pre>
<p>Create an Instance of Medium.Baseproperties: </p>
</pre>Medium.BaseProperties props;</pre>
<p>Use the BaseProperties model to define the actual brine composition(Xi or X), to define the thermodynamic state and calculate the corresponding properties. </p>
<pre>
props.p = 1e5;
props.T = 300;
props.Xi = {0.08, 0.004, 0.12, 1-4, 7e-4, 6e-005} &QUOT;NaCl, KCl, CaCl2, CO2, N2, CH4&QUOT;
d = props.d;
</pre>

<p>See <a href=\"Modelica://BrineProp.Examples.BrineProps2phase\">BrineProp.Examples.BrineProps2phase</a> for more usage examples.</p>
<p>All calculated values are returned in SI units and are mass based.</p>

<h4>Specific Enthalpy:</h4>
<p>The enthalpy is calculated as a mass fraction weighted average of the enthalpies of the two phases.</p>
<p align=\"center\">h = x&middot;h_g + (1-x)&middot;h_l</p>

<h4>Specific enthalpy of gas phase:</h4>
<p>Enthalpy of the gas phase is modelled as the enthalpy of an ideal mixture of ideal gases, i.e. it is calculated as the mass weighted average of the individual gas enthalpies including water.</p>
<p align=\"center\">h_g = sum(h&QUOT;<sub>i</sub>&middot;X&QUOT;<sub>i</sub>)</p>

<p> The individual gas enthalpies are calculated using the functions for ideal gases in Modelica.Media.IdealGases.SingleGases.</p>

<h4>Specific enthalpy of liquid phase:</h4>
Enthalpy of the liquid phase is assembled from the enthalpy of a NaCl-solution (Driesner) and the apparent molar enthalpies of the salts multiplied by their respective molalities</span>
<p align=\"center\">h_l = h<sub>Driesner</sub>+sum(H<sub>i<sup>app<sub>&middot;bi)</span></sub></p>


<p>The apparent molar enthalpies of KCl and CaCl2 are calculated from apparent molar heat capacities which are calculated from a 2D fit for data from literature. The contributions of MgCl2 and SrCl2 are neglected, due to their small influence in the GrSbk fluid.</p>
<h4>Density</h4>
<p>
The total density d of the fluid is calculated by combining the densities of both phases (d_g and d_l) according to their volume fractions. The gas phase is assumed to be an Density of the gas phase is assumed to be an ideal mixture of ideal gases.</p>
<p align=\"center\">d = 1/(x/d_g + (1 - x)/d_l)</p>

<h4>Density of the gas phase:</h4>
Gas density is calculated using the ideal gas law.

<h4>Density of liquid phase:</h4>
Density of the liquid phase is calculated by combining the densities of solutions of single salts. The density model by Duan for single salt solutions is adapted for multi-salt solutions, resulting in an approach with apparent molar volumes analogous to the mixing rule for enthalpy.

<h5>Created by</h5>
Henning Francke<br>
Helmholtz Centre Potsdam GFZ German Research Centre for Geosciences<br>
Telegrafenberg, D-14473 Potsdam<br>
Germany<br>
<a href=\"mailto:francke@gfz-potsdam.de\">francke@gfz-potsdam.de</a>
</html>",
 revisions="<html>

</html>"));
end Brine3salts4gas;

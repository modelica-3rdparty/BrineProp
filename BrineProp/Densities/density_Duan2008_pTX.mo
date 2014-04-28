within BrineProp.Densities;
function density_Duan2008_pTX "Brine density"
  input SI.Pressure p;
  input SI.Temp_K T;
  input SI.MassFraction X[:] "mass fractions m_NaCl/m_Sol";
  input SI.MolarMass MM_vec[:] "molar masses of components";

  output SI.Density d;
protected
  final constant Real b=1.2;
  final constant Real U[:]={3.4279E2,-5.0866E-3,9.4690E-7,-2.0525,3.1159E3,-1.8289E2,
      -8.0325E3,4.2142E6,2.1417};
             //dielectric constant D of pure water according to Bradley and Pitzer (1979)
  final constant Real N_0(final unit="1/mol") = Modelica.Constants.N_A
    "Avogadro constant in [1/mol]";
//  e := 1.60217733E-19 [C] "elementary charge in Coulomb";
  final constant Real e=1.60217733E-19*10*299792458
    "elementary charge in [esu]";
//k := 1.3806505E-23 "Boltzmann constant in [J/K]";
  final constant Real k=1.3806505E-16 "Boltzmann constant in [erg/K]";
  final constant Real R=Modelica.Constants.R "Gas constant [J/mol*K]";
/*  constant Integer nX_salt =  size(X,1) 
    "TODO: diese Zeile und alle Verweise au nX_salt entfernen";*/
  constant Integer nX_salt=5;
  SI.MassFraction w_salt "kg_salt/kg_brine";
//  SI.Temp_C T_C = SI.Conversions.to_degC(T);
  Pressure_bar p_bar=SI.Conversions.to_bar(p);
  Pressure_MPa p_MPa=p*1e-6;
  Real v;
 // Modelica.Media.Water.WaterIF97_base.ThermodynamicState state_H2O;
//  Molality m[nX_salt] "molality (mol_salt/kg_sol)";
  Real I;
  Real I_mr;
  SI.Density rho_sol_r;
  SI.Density rho_H2O;
  SI.Density rho_H2O_plus;
  SI.Density rho_H2O_minus;
  Real p_plus_bar;
  Real p_minus_bar;
  Real D_plus;
  Real D_minus;
  Real A_Phi_plus;
  Real A_Phi_minus;
  Real B_v;
  Real C_v;
  Real V_m_r;
  Real Bb;
  Real Cc;
  Real D_1000;
  Real D;

  Real A_Phi;
  Real dp;
  Real dA_Phi;
  Real A_v;
  Real V_o_Phi;
  Real V_Phi[nX_salt];
  Real h;
  Real h_mr;

  Real M_salt[nX_salt];
  Real m_r;
  Real z_plus;
  Real z_minus;
  Real v_plus;
  Real v_minus;
  Real[23] c;

//  SI.Density[nX_salt] rho;
  BrineProp.SaltData_Duan.SaltConstants salt;
  constant Molality[:] m=massFractionsToMolalities(X, MM_vec);
  SI.Pressure p_sat=Modelica.Media.Water.IF97_Utilities.BaseIF97.Basic.psat(T);
  String msg;
algorithm
  if debugmode then
      print("Running density_Duan2008_pTX("+String(p/1e5)+" bar,"+String(T-273.15)+" �C, X="+Modelica.Math.Matrices.toString(transpose([X]))+")");
  end if;

  //Density of pure water
/*  state_H2O := Modelica.Media.Water.WaterIF97_base.setState_pTX(p, T, fill(0,0));
  rho_H2O := Modelica.Media.Water.WaterIF97_base.density(state_H2O) * 1e-3 "kg/m�->kg/dm�";*/
//  rho_H2O := Modelica.Media.Water.WaterIF97_base.density(Modelica.Media.Water.WaterIF97_base.setState_pTX(p, T, fill(0,0))) * 1e-3 "kg/m�->kg/dm�";

//  assert(Modelica.Media.Water.WaterIF97_base.saturationPressure(T)<p,"T="+String(T-273.15)+"�C is above evaporation temperature at p="+String(p/1e5)+" bar!");
/*  if (Modelica.Media.Water.WaterIF97_base.saturationPressure(T)>p) then
    d:=-1 "if above evaporation temperature";
    print("above evaporation temperature!");
    return;
  end if;*/

//  rho_H2O := Modelica.Media.Water.WaterIF97_base.density_pT(p, T) * 1e-3
//  SI.Density rho2= max(Modelica.Media.Water.WaterIF97_base.density_pT(p,T),Modelica.Media.Water.IF97_Utilities.BaseIF97.Regions.rhol_T(T));
  rho_H2O := Modelica.Media.Water.WaterIF97_base.density_pT(max(p, p_sat + 1), T)*1e-3
    "kg/m�->kg/dm�";
//   print("rho_H2O=" +String(rho_H2O)+" kg/dm�");

  //for pure water skip the whole calculation and return water density
  if max(X[1:nX_salt]) <= 1e-12 then
    d := rho_H2O*1000;
    return;
  end if;
  for i in 1:nX_salt loop
  //    print(salt.name+": "+String(X[i]));
    if not X[i] > 0 then
      M_salt[i] := 1;
    else
      salt :=BrineProp.SaltData_Duan.saltConstants[i];

      if not (m[i] >= 0 and m[i] <= salt.mola_max_rho) then
        msg:="Molality of " + salt.name + " is " + String(m[i]) +
          ", but must be between 0 and " + String(salt.mola_max_rho) +
          " mol/kg (BrineProp.Densities.density_Duan2008_pTX)";
      end if;
      if not (ignoreLimitSalt_p[i] or (p >= salt.p_min_rho and p <= salt.p_max_rho)) then
        msg:="Pressure is " + String(p_bar) + " bar, but for " + salt.name +
          " must be between " + String(salt.p_min_rho*1e-5) + " bar and " +
          String(salt.p_max_rho*1e-5) +
          " bar (Brine.Salt_Data_Duan.density_Duan2008_pTX())";
      end if;
      if not (ignoreLimitSalt_T[i] or (T >= salt.T_min_rho and T <= salt.T_max_rho)) then
        msg:="Temperature is " + String(SI.Conversions.to_degC(T)) +
          "�C, but for " + salt.name + " must be between " + String(
          SI.Conversions.to_degC(salt.T_min_rho)) + "�C and " + String(
          SI.Conversions.to_degC(salt.T_max_rho)) +
          "�C (Brine.Salt_Data_Duan.density_Duan2008_pTX())";
      end if;
      if msg<>"" then
        if outOfRangeMode==1 then
          print(msg);
        elseif outOfRangeMode==2 then
          assert(false,msg);
        /*assert(m[i] >= 0 and m[i] <= salt.mola_max_rho, "Molality of "+salt.name+" is "+String(m[i]) + ", but must be between 0 and "+ String(salt.mola_max_rho) + " mol/kg");
          assert(ignoreLimitSalt_T[i] or (T >= salt.T_min_rho and T <= salt.T_max_rho), "Temperature is "+String(SI.Conversions.to_degC(T)) + "�C, but for " + salt.name + " must be between " + String(SI.Conversions.to_degC(salt.T_min_rho)) + "�C and " + String(SI.Conversions.to_degC(salt.T_max_rho)) + "�C");
          assert(ignoreLimitSalt_p[i] or (p >= salt.p_min_rho and p <= salt.p_max_rho), "Pressure is " + String(p_bar) + " bar, but for "+salt.name + " must be between " + String(salt.p_min_rho*1e-5) + " bar and " + String(salt.p_max_rho*1e-5) + " bar");
        */
        end if;
      end if;

      M_salt[i] := salt.M_salt*1000 "in g/mol";
      m_r := salt.m_r;
      z_plus := salt.z_plus;
      z_minus := salt.z_minus;
      v_plus := salt.v_plus;
      v_minus := salt.v_minus;
      c := salt.C;

      v := v_plus + v_minus;

      //Conversion to mass and mol fraction
    //        w_salt := (m*M_salt*Convert('g';'kg'))/(1+m*M_salt*Convert('g';'kg'));
  //    w_salt := X[i];
   //   m[i] := w_salt/(M_salt[i]*1e-3*(1 - w_salt)) "moles per kg H2O - Only valid for one salt";
    //  x_salt := (m*M_H2O *Convert('g';'kg'))/(1+m*M_H2O *Convert('g';'kg'));

    //---------------------------------------------------

      //Equation 3: Ionic strength
      I := 1/2*(m[i]*v_plus*z_plus^2 + m[i]*v_minus*z_minus^2);
      I_mr := 1/2*(m_r*v_plus*z_plus^2 + m_r*v_minus*z_minus^2);

      //Equation 4:
      h := Modelica.Math.log10(1 + b*I^(0.5))/(2*b);
      h_mr := Modelica.Math.log10(1 + b*I_mr^(0.5))/(2*b);

    //---------------------------------------------------
    // equations using empirically fitted coefficients
    //---------------------------------------------------

      //Equation 10: solution volume at reference molality
      V_m_r := c[01] + c[02]*T + c[03]*T^2 + c[04]*T^3 + p_MPa*(c[05] + c[06]*T +
        c[07]*T^2 + c[08]*T^3);

      //Check: solution density at reference molality
      rho_sol_r := (1000 + m_r*M_salt[i])/V_m_r;

      //Equation 11: second virial coefficient. depends on temperature and pressure
      B_v := c[09]/(T - 227) + c[10] + c[11]*T + c[12]*T^2 + c[13]/(647 - T) + p_MPa*(c[14]/(
        T - 227) + c[15] + c[16]*T + c[17]*T^2 + c[18]/(647 - T));

      //Equation 12: third virial coefficient. depends on temperature
      C_v := c[19]/(T - 227) + c[20] + c[21]*T + c[22]*T^2 + c[23]/(647 - T);

    //---------------------------------------------------
    // Appendix A: Debye-H�ckel limiting law slopes"
    //---------------------------------------------------

      Bb := U[07] + U[08]/T + U[09]*T;
      Cc := U[04] + U[05]/(U[06] + T);
      D_1000 := U[01]*exp(U[02]*T + U[03]*T^2);
      D := D_1000 + Cc*log((Bb + p_bar)/(Bb + 1000));

      //DH-slope for osmotic coefficient according to Bradley and Pitzer (1979)
      A_Phi := 1/3*((2*Modelica.Constants.pi*N_0*rho_H2O)/1000)^(1/2)*(e^2/(D*k*T))^(3/2);

      //numeric differentiation per dp
      dp := 1E-3*p_bar;
      p_plus_bar := p_bar + dp "/2";
      p_minus_bar := p_bar "- dp/2";
      D_plus := D_1000 + Cc*log((Bb + p_plus_bar)/(Bb + 1000));
      D_minus := D_1000 + Cc*log((Bb + p_minus_bar)/(Bb + 1000));

//      rho_H2O_plus := Modelica.Media.Water.WaterIF97_base.density_pT(p_plus_bar*1e5, T) * 1e-3
      rho_H2O_plus := Modelica.Media.Water.WaterIF97_base.density_pT(max(p_plus_bar*1e5, p_sat + 1), T)*
        1e-3 "kg/m�->kg/dm�";

      rho_H2O_minus := rho_H2O
        "Modelica.Media.Water.WaterIF97_base.density_pT(p_minus_bar*1e5, T) * 1e-3 kg/m�->kg/dm�";
      A_Phi_plus := 1/3*(2*Modelica.Constants.pi*N_0*rho_H2O_plus/1000)^(1/2)*(
        e^2/(D_plus*k*T))^(3/2);
      A_Phi_minus := 1/3*(2*Modelica.Constants.pi*N_0*rho_H2O_minus/1000)^(1/2)*
        (e^2/(D_minus*k*T))^(3/2);
      dA_Phi := (A_Phi_plus - A_Phi_minus);

      //DH-slope for apparent molar volume according to Rogers and Pitzer (1982)
      A_v := 23*(-4*R*T*dA_Phi/dp) "where does the 23 come from??";

    //---------------------------------------------------
    // Solution 1: using V_o_Phi and V_Phi
    //---------------------------------------------------

    //Equation 13: apparent molar Volume at infinite dilution in cm�/mol
      V_o_Phi := (V_m_r/m_r - 1000/(m_r*rho_H2O) - v*abs(z_plus*z_minus)*A_v*h_mr - 2*v_plus*
        v_minus*R*T*(B_v*m_r + v_plus*z_plus*C_v*m_r^2));

                    //Equation 2: apparent molar Volume in cm^3/mol
      V_Phi[i] := V_o_Phi + v*abs(z_plus*z_minus)*A_v*h + 2*v_plus*v_minus*m[i]*R*T*(
        B_v + v_plus*z_plus*m[i]*C_v);

                    //Equation 1: density of the solution
//      rho[i] := ((1000 + m[i]*M_salt[i])*rho_H2O)/(1000 + m[i]*V_Phi[i]*rho_H2O)*1000;

    //---------------------------------------------------
    // Solution 2: using V_m
    //---------------------------------------------------

                    /*
                    //Equation 8: solution volume
                    //V_m = m*( V_m_r/m_r + 1000/rho_H2O *(1/m - 1/m_r) +              v*abs(z_plus*z_minus) * A_v*(h-h_mr) + 2*v_plus*v_minus*R*T_K* (B_v*(m-m_r) + v_plus*z_plus*C_v*(m^2-m_r^2)) )
                    V_m =     V_m_r*m/m_r + 1000/rho_H2O - (1000*m)/(rho_H2O*m_r) + m*(v*abs(z_plus*z_minus) * A_v*(h-h_mr) + 2*v_plus*v_minus*R*T_K* (B_v*(m-m_r) + v_plus*z_plus*C_v*(m^2-m_r^2)) )
    
                    //density of the solution
                    Density_Duan = (1000 + m*M_salt)/V_m
                    */
    end if;
  end for;
//  d := m[1:nX_salt]*rho/(1-X[end]) "mass fraction weighted linear mixture (matrix multiplication)";
//   d := m[1:nX_salt]*rho/(sum(m[1:nX_salt])) "molality weighted linear mixture (matrix multiplication)";

// d := ((1 + m[1:end-1]*MM_vec[1:end-1])*1000*rho_H2O)/(1000 + m[1:nX_salt]*V_Phi*rho_H2O)*1000     "Mixing rule frei nach Duan";
  d :=  1/(X[end]/(rho_H2O*1000) + X[1:nX_salt]*( V_Phi/1e6 ./ (M_salt/1000)))
    "Mixing rule Laliberte&Cooper2004 equ. 5&6";

//  print("m: "+String((1000 + m[1:nX_salt]*M_salt)*rho_H2O)+"="+ String(1/X[end]));

  annotation (Documentation(info="<html>
<p><h4><font color=\"#008000\">density calculation of an aqueous salt solution</font></h4></p>
<p><br/>according&nbsp;to&nbsp;Shide&nbsp;Mao&nbsp;and&nbsp;Zhenhao&nbsp;Duan&nbsp;(2008)&nbsp;0-300&deg;C;&nbsp;0.1-100MPa;&nbsp;0-6&nbsp;mol/kg</p>
<p><code><font style=\"color: #006400; \">&nbsp;&nbsp;<a href=\"http://dx.doi.org/10.1016/j.jct.2008.03.005\">http://dx.doi.org/10.1016/j.jct.2008.03.005</a></font></code></p>
<p><code><font style=\"color: #006400; \">&nbsp;&nbsp;<a href=\"http://www.geochem-model.org/wp-content/uploads/2009/09/55-JCT_40_1046.pdf\">http://www.geochem-model.org/wp-content/uploads/2009/09/55-JCT_40_1046.pdf</a></font></code></p>
<p><br/><h4><font color=\"#008000\">Known issues:</font></h4></p>
<p>Brine&nbsp;has&nbsp;the&nbsp;same&nbsp;evaporation&nbsp;temperature&nbsp;as&nbsp;pure&nbsp;water,&nbsp;only&nbsp;different&nbsp;saturation pressure</p>
</html>"));
end density_Duan2008_pTX;
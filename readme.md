BrineProp
=========
BrineProp is a modelica package that calculates the thermodynamic properties of a specified brine, i.e. an aqueous solution of salts and gases, with a potential gas phase, including degassing/evaporation and solution/condensation.

An Excel version is available in the download section. Its VBA code can also be found in `/VBA`.

Compatibility
-------------
* Works in Dymola 2014 FD01 with MSL 3.2
* Works in Dymola 2014 FD01 with MSL 3.2.1
* Works via FMU in OpenModelica
* Works via FMU in JModelica

Installation
------------
Download, unzip and open BrineProp/package.mo

For use with MSL 3.2.1 you need to load the MSL 3.2.1 first via File>Libraries>MSL, then open package, 
after conversion make changes marked with "MSL 3.2.1" in PartialMixtureTwoPhaseMedium to get rid of warnings. After the changes the lib will not work in MSL 3.2).

Getting started
------
Run models from `BrineProp/Examples`.

Documentation
-------------
* in the package (info annotation)
* in PhD thesis *[Thermo-hydraulic model of the two-phase flow in the brine circuit of a geothermal power plant](http://nbn-resolving.de/urn:nbn:de:kobv:83-opus4-47126)*

## Development and contribution
Feedback/contributions welcome to francke@gfz-potsdam.de or as  pull request.

## License
Licensed by Henning Francke under the [Modelica License 2](https://www.modelica.org/licenses/ModelicaLicense2) or newer
Copyright © 2009-2014 Helmholtz Centre Potsdam, GFZ German Research Centre for Geosciences.
This Modelica package is free software and the use is completely at your own risk;  
it can be redistributed and/or modified under the terms of the [Modelica License 2](https://www.modelica.org/licenses/ModelicaLicense2) or newer.  
For license conditions (including the disclaimer of warranty) visit [https://www.modelica.org/licenses/](https://www.modelica.org/licenses).

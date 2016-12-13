This package implements and reproduces results form 
"Learning spectral descriptors for deformable shape correspondence"

- The package was tested on matlab 8.0 on WINDOWS (contains MEX files for 36 & 64 bit). should also work on later version of matlab 7.x
- The function "GetParams_LSD" contains (among others) the paths & wild-cards for where the training & testing data is located
- First run "RunPreCalc" with the latter paths set to data of your choice. This will create: down-sample shapes --> LBO evecs --> initial geometric vectors
- Reproduce results - if you use the "TOSCA" dataset (& optionally also "SCAPE") run "RunFullBench"

- Less stable parts of the code:
	- for spectral matching run "test_SpectralMatching" script in "scripts" folder
	- data for the partiality test is created using the "create_partial_shapes" script in "scripts" folder

for questions & complaints please refer to the author by mail (in the personal website)
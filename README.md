# Solution Notes for 'Minimal utilitarian benchmarks for NDCs yield equity, climate, and development advantages.'

This code provides the ability to replicate all modeling runs in the paper Budolfson et al. 2018 “Minimal utilitarian benchmarks for NDCs yield equity, climate, and development advantages.”  This code also would permit a user familiar with Mimi to implement further modeling runs under alternative assumptions, by changing our code. 
## Software prerequisites
We use Mimi, within the Julia environment with the following packages:  
-	Mimi.jl
-	DataFrames.jl
-	CSV.jl
-	NLopt.jl
> This software is all available for free download.  To download Mimi, for example, go to Julia and type the command Pkg.add(“Mimi.jl”)
- Our software:
Our paper implements model runs under two scenarios: utilitarianism and cost-minimization.  We have a Julia file for each of these: “Results_Utilitarian.jl” and “Results_CostMin.jl” Running these will produce the csv files which contain our output.  We produced our final figures from these csv files by using Stata’s graphics features. 
## Modifications to RICE 2010:
Our model is built upon Nordhaus’ RICE 2010 model.  We made several slight modifications:
1.	Population numbers are fixed to match updated data from the UN World Population Prospects.
2.	Savings rates have been changed to 0.258, a fixed value. This is done in the parameters.jl file. (We commented out the reading in of savings rates and instead have put in a 60x12 matrix of 0.258).
3.	The social rate of time preference (ρ) is changed to .008. You can see this in the Results_Utilitarian.jl file, for example, using 'setparameter()' function.
> (We have implemented the first two of these changes directly in the data file RICE_2010_base_000.xlsm ).
## Code to Optimize: 
- *Optimization routines:*  To find the optima, use these files.  We use Optimize_UtilitarianRICE.jl Optimize_CostMinRICE.jl to maximize welfare in RICE. These choose a policy to maximize the objective function, which is equation 1 in the supplemental materials.
- *Model:* Rice2010_Utilitarian.jl: takes components and compiles them into a Mimi model. Rice2010_CostMin.jl: Does the same for the cost-min version.  RunBAU.jl runs RICE with no climate policy (Business as Usual.)
- *Components Folder:* Defines each component. See Mimi codes on GitHub for tutorial on this way of compiling IAMs.  
- *Data:* Parameters_Utilitarian.jl: Reads in the data file to the parameters of the Mimi Model Parameters_CostMin.jl: does the same for the one price version. (The data file is RICE_2010_base_000.xlsm ).
- *File structure:*  The RICE worksheet must be in a separate folder labelled 'data' at the same folder level as the “src” file with the code within it.  Helpers.jl: defines functions that go in and read out data from excel into Mimi format; keep this in the src folder.


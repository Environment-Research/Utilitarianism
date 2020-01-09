# Solution Notes for 'Minimal utilitarian benchmarks for NDCs yield equity, climate, and development advantages.'

This code provides the ability to replicate all modeling runs in the paper Budolfson et al. 2018 “Minimal utilitarian benchmarks for NDCs yield equity, climate, and development advantages.”  This code also would permit a user familiar with Mimi to implement further modeling runs under alternative assumptions, by changing our code.

## Software prerequisites

The code is run in the open source programming language [Julia](https://julialang.org/). You can download Julia from https://julialang.org/downloads/. That page also as instructions on how to install Julia on your system. This code was developed using Julia 1.3.1.

## Executing the replication code

To run the replication for this paper, execute the following command at your command prompt in the folder that contains the replication code from this repository:

```
$> julia src/run_analysis.jl
```

or alternatively start Julia, and execute the following command in the Julia REPL (but replace `<LOCAL PATH TO REPLICATION FOLDER>` with the path of the folder with this replication code):

```julia
julia> include("<LOCAL PATH TO REPLICATION FOLDER>/src/run_analysis.jl")
```

## Code structure

Our paper implements model runs under two scenarios: utilitarianism and cost-minimization.  We have a Julia file that runs each of these simultaneously: `run_analysis.jl`. Running this produces csv files which contain our output.  We produced our final figures from these csv files by using Stata’s graphics features. It is easy to amend the ethical parameters of our model (ρ, η) at the top of that file to produce the alternative runs in the Supplementary Information section of the paper. To change other parameters or the structure of the RICE model, it would be necessary to edit the 'create_rice.jl' file or individual underlying components. 

The folders on this page should be downloaded in their entirety. The code is set-up to look within specific sub-folders to call routines; failing to downloading one these may prevent the program from running successfully.

## Modifications to RICE 2010:

Our model is built upon Nordhaus’ RICE 2010 model.  We made several slight modifications:
1. Population numbers are updated to match the UN World Population Prospects. Data included in the 'data' folder here. 
2. Savings rates have been changed to 0.258, a fixed value. This is done in the 'create_rice.jl' file.
3. The social rate of time preference (ρ) is changed to .008. 
4. We don't use Negishi weights for our solution. 

To replicate the original RICE solution:
1. Edit ρ, η back to 0.015 and 1.5, respectively.
2. Go into the 'create_rice.jl' file and comment out the lines manually setting the savings parameter as well as the population parameters.

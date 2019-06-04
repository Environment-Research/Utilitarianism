#See Optimize_UtilitarianRICE.jl for a description of what is happening in here. 
# The only difference here is that I am optimizing over Carbon Prices instead so it can just be read in as a one-dim time series vector

using NLopt
using DataFrames
using Mimi
function optimizeIAM_costmin(m::Mimi.Model)

	##Define inner function that feeds in carbon prics and runs RICE deterministically spitting out total welfare given these prices

	function RICE2010Prices(model::Mimi.Model, GlobalCPRICE::Array{Float64,1})
		CpriceMat = zeros(60,12)
			for j = 1:12
				CpriceMat[2:60,j] = GlobalCPRICE
			end
		CpriceMat = convert(Array{Float64}, CpriceMat)
		setparameter(model, :emissions, :CPRICE, CpriceMat)
		run(model)
		return(model[:welfare, :UTILITY])
	end
 
InitGuess = 50*ones(59)
println("Made Initial Guess")
###Need bounds for optimization routine
	Lowbound = zeros(59)
	Upbound = ones(59)
	 for j = 1:59
	 	Upbound[j] = 2000  #arbitrary upper bound
	 end

opt = Opt(:LN_SBPLX, 59)
lower_bounds!(opt, Lowbound)
upper_bounds!(opt, Upbound)
ftol_rel!(opt, 1e-15)
maxtime!(opt, 600)
max_objective!(opt, (x,grad)-> RICE2010Prices(m,x))  #calls on the inner function above as the objective while searching over prices


##Run optimization

(Welfare, minx, ret) = optimize(opt, InitGuess)

##Now define the carbon price as the solution above (minx) and run the model for output.
CpriceMat = zeros(60,12)
			for j = 1:12
				CpriceMat[2:60,j] = minx
			end
		CpriceMat = convert(Array{Float64}, CpriceMat)
		setparameter(m, :emissions, :CPRICE, CpriceMat)
		run(m)
		return(m)
end

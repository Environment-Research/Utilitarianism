using NLopt
using DataFrames
using Mimi

#This function optimizes Mimi-RICE (with variable prices) using a built in global solver.

function optimizeIAM_Utilitarian(m::Mimi.Model)

#Start by defining the function we'd like to optimize, Im calling RICE2010Welfare, appropriately.
#Here I will define the vector Julia will need to solve over, which I first translate into a 60x12 matrix to feed in as a parameter to Mimi. 
#The trick is that this is a variable, but in our "guess until we find the solution" we want Mimi to treat it as a parameter and 
#the outer "solver" to guess values of it until its found the best combination of parameters.

	function RICE2010Welfare(model::Mimi.Model, TotMIU::Array{Float64,1})
		MIUmatrix = zeros(60,12) 
			for j = 1:12
				MIUmatrix[2:60,j] = TotMIU[(j-1)*59+1:j*59] #imposes 0 MIU in year 2005.
			end
		MIUArray = convert(Array{Float64}, MIUmatrix) #this the data structure Mimi likes
		setparameter(model, :emissions, :MIU, MIUArray)
		run(model)
		return(model[:welfare, :UTILITY])
	end
 
MIU_Matrix_guess = .25*ones(60,12)
	for j = 2:24
		MIU_Matrix_guess[j:1]= .25
	end	

	for j = 25:60
		MIU_Matrix_guess[j,:] = 1
	end

MIU_Array_guess = Array(Float64,708) #the solver needs these fed in as an Array. So they're put in 'long' form here, then put back in RICE2010Welfare
	for j = 1:12
		MIU_Array_guess[(j-1)*59+1:j*59] = MIU_Matrix_guess[2:60,j]
	end

###Need bounds for optimization routine
	Upbound = ones(708)
	Lowbound = zeros(708)

#see NLopt documentation on GitHub for directions on how to run solver.
opt = Opt(:LN_SBPLX, 708)
ftol_rel!(opt, 1e-10)
lower_bounds!(opt, Lowbound)
upper_bounds!(opt, Upbound)
maxtime!(opt, 600)
max_objective!(opt, (x,grad)-> RICE2010Welfare(m,x))


#Now for output

(Welfare, minx, ret) = optimize(opt, MIU_Array_guess)

OptMIUs = zeros(60,12)
	for j=1:12
		OptMIUs[2:60,j] = minx[(j-1)*59+1:j*59]
	end

#Now that I have the optimized MIU, rerun to spit out entire optimized model
		MIUArray = convert(Array{Float64}, OptMIUs)
		setparameter(m, :emissions, :MIU, MIUArray)
		run(m)
		return(m)
end

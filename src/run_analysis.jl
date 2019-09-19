########################################################################################################
# This file runs a number of model analyses from Budolfson et al. (2019) given user-specified settings.
########################################################################################################

# Load required Julia packages.
using NLopt

# Load required files.
include("create_rice.jl")
include("helper_functions.jl")

#------------------------------------------------------------------------------------------------------
# Model Parameters To Modify.
#------------------------------------------------------------------------------------------------------

# Pure rate of time preference.
ρ = 0.008

# Elasticity of marginal utility of consumption.
η = 1.5

# Should the model be run with a social welfare function that uses Negish weights (true = remove Negishi weights).
# *Note: if using Negishi weights, the model uses the default RICE settings of η=1.5 and ρ=1.5%.
remove_negishi = true


#------------------------------------------------------------------------------------------------------
# Settings For Model Versions To Run.
#------------------------------------------------------------------------------------------------------

# Run an optiization with RICE using global carbon prices?
rice_cost_minimization = true

# Run an optization with RICE using regional carbon prices?
rice_utilitarianism = true


#------------------------------------------------------------------------------------------------------
# Optimization Parameters to Modify.
#------------------------------------------------------------------------------------------------------

# Name of folder for this set of model runs to store your results in (a folder will be created with this name).
results_folder = "My Results"

# Number of model periods to optimize over (after which model assumes full decarbonization).
n_opt_periods = 30

# Optimization algorithm (the type should be a Symbol, e.g. :LN_SBPLX). See options at http://ab-initio.mit.edu/wiki/index.php/NLopt_Algorithms
optimization_algorithm = :LN_SBPLX

# Maximum time in seconds to run (in case optimization does not converge).
stop_time = 1000

# Relative tolerance criteria for convergence (will stop if |Δf| / |f| < tolerance from one iteration to the next.)
tolerance = 1e-14


#------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------
# Run Everything and Save Key Results (*no need to modify code below this line).
#------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------
println("Starting Analysis.")

# Load and run an instance of RICE just to extract the backstop prices (needed for multiple analyses).
backstop_rice = create_rice()
run(backstop_rice)
backstop_prices = backstop_rice[:emissions, :pbacktime] .* 1000


#------------------------------------------------------------------------------------------------------
# Run RICE Cost-Minimization Optimization.
#------------------------------------------------------------------------------------------------------

if rice_cost_minimization == true

	# Optimize model.
	opt_output_rice_cost_min, opt_mitigation_rice_cost_min, opt_tax_rice_cost_min, opt_model_rice_cost_min = optimize_rice(optimization_algorithm, n_opt_periods, stop_time, tolerance, backstop_prices, run_utilitarianism=false, ρ=ρ, η=η, remove_negishi=remove_negishi)

	# Create folder to store some key results.
	output_directory = joinpath(@__DIR__, "../", "results", results_folder, "rice_cost_minimization")
	mkpath(output_directory)

	# Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
	save(joinpath(output_directory, "CO2 Mitigation.csv"), DataFrame(opt_mitigation_rice_cost_min))
	save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(global_carbon_tax=opt_tax_rice_cost_min))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temperature=opt_model_rice_cost_min[:climatedynamics, :TATM]))
    save(joinpath(output_directory, "Per Capita Consumption.csv"), DataFrame(opt_model_rice_cost_min[:neteconomy, :CPC]))

end


#------------------------------------------------------------------------------------------------------
# Run RICE Utilitarian Optimization.
#------------------------------------------------------------------------------------------------------

if rice_utilitarianism == true

	# Optimize model.
	opt_output_rice_utilitarian, opt_mitigation_rice_utilitarian, opt_tax_rice_utilitarian, opt_model_rice_utilitarian = optimize_rice(optimization_algorithm, n_opt_periods, stop_time, tolerance, backstop_prices, run_utilitarianism=true, ρ=ρ, η=η, remove_negishi=remove_negishi)

	# Create folder to store some key results.
	output_directory = joinpath(@__DIR__, "../", "results", results_folder, "rice_utilitarian")
	mkpath(output_directory)

	# Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
	save(joinpath(output_directory, "CO2 Mitigation.csv"), DataFrame(opt_mitigation_rice_utilitarian))
	save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(opt_tax_rice_utilitarian))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temperature=opt_model_rice_utilitarian[:climatedynamics, :TATM]))
    save(joinpath(output_directory, "Per Capita Consumption.csv"), DataFrame(opt_model_rice_utilitarian[:neteconomy, :CPC]))

end

println("Analysis complete.")

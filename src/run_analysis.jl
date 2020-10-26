########################################################################################################
# This file runs a number of model analyses from Budolfson et al. (2019) given user-specified settings.
########################################################################################################

# Activate the project for the paper and make sure all packages we need
# are installed.
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()

# Load required Julia packages.
using NLopt
using CSV

# Load required files.
include("create_rice.jl")
include("create_fund.jl")
include("helper_functions.jl")

#------------------------------------------------------------------------------------------------------
# Model Parameters To Modify.
#------------------------------------------------------------------------------------------------------

# Pure rate of time preference.
ρ = 0.015

# Elasticity of marginal utility of consumption.
η = 1.5

# Should the RICE model be run with a social welfare function that uses Negish weights (true = remove Negishi weights).
# *Note: if using Negishi weights, the model uses the default RICE settings of η=1.5 and ρ=1.5%.
remove_negishi = true

#------------------------------------------------------------------------------------------------------
# Choices For Model Versions To Run.
#------------------------------------------------------------------------------------------------------

# Run an optiization with RICE using global carbon prices?
rice_cost_minimization = true

# Run an optization with RICE using regional carbon prices?
rice_utilitarian = true

# Run an optiization with RICE using global carbon prices?
fund_cost_minimization = false

# Run an optization with RICE using regional carbon prices?
fund_utilitarian = false

#------------------------------------------------------------------------------------------------------
# Optimization Settings to Modify.
#------------------------------------------------------------------------------------------------------

# Name of folder to save this set of model runs in (a folder will be created with this name).
results_folder = "My Results"

# Number of model periods to optimize over for RICE (after which model assumes full decarbonization).
# NOTE: FUND does not have a backstop price and optimizes from 2010-2200 by default, and then assumes a constant carbon tax.
n_opt_periods = 30

# Optimization algorithm (the type should be a Symbol, e.g. :LN_SBPLX). See options at http://ab-initio.mit.edu/wiki/index.php/NLopt_Algorithms
optimization_algorithm = :LN_SBPLX

# Maximum time in seconds to run each model (NOTE: FUND takes much longer to optimize than RICE).
stop_time_rice = 500
stop_time_fund = 40

# Relative tolerance criteria for convergence (will stop if |Δf| / |f| < tolerance from one iteration to the next.)
tolerance_rice = 1e-10
tolerance_fund = 1e-10


#------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------
# Run Everything and Save Key Results (*no need to modify code below this line).
#------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------
println("Starting Analysis.")
println()

# Load and run an instance of RICE just to extract the backstop prices (needed for multiple analyses).
backstop_rice = create_rice(ρ, η, remove_negishi)
run(backstop_rice)
backstop_prices = backstop_rice[:emissions, :pbacktime] .* 1000
output_directory = joinpath(@__DIR__, "../", "results", results_folder, "rice_BAU")
mkpath(output_directory)
save(joinpath(output_directory, "Emissions.csv"), DataFrame(backstop_rice[:emissions, :EIND]))
save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(backstop_rice[:neteconomy, :CPC]))
save(joinpath(output_directory, "Population.csv"), DataFrame(backstop_rice[:welfare, :pop]))
LandUse = CSV.read(joinpath(@__DIR__, "../", "data", "RICELandUse.csv"))
save(joinpath(output_directory, "LandUse.csv"), LandUse)


#------------------------------------------------------------------------------------------------------
# Run RICE Cost-minimization Optimization.
#------------------------------------------------------------------------------------------------------
if rice_cost_minimization == true

    println("Starting RICE cost-minimization optimization...")

    # Optimize model.
    opt_output_rice_cost_minimization, opt_emissions_rice_cost_minimization, opt_mitigation_rice_cost_minimization, opt_tax_rice_cost_minimization, opt_model_rice_cost_minimization, convergence_rice_cost_minimization = optimize_rice(optimization_algorithm, n_opt_periods, stop_time_rice, tolerance_rice, backstop_prices, run_utilitarian=false, ρ=ρ, η=η, remove_negishi=remove_negishi)

    # Create folder to store some key results.
    output_directory = joinpath(@__DIR__, "../", "results", results_folder, "rice_costmin")
    mkpath(output_directory)

    # Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
    save(joinpath(output_directory, "Emissions.csv"), DataFrame(opt_emissions_rice_cost_minimization))
    save(joinpath(output_directory, "MitigationRate.csv"), DataFrame(opt_mitigation_rice_cost_minimization))
    save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(global_carbon_tax=opt_tax_rice_cost_minimization))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temp=opt_model_rice_cost_minimization[:climatedynamics, :TATM]))
    save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(opt_model_rice_cost_minimization[:neteconomy, :CPC]))
    save(joinpath(output_directory, "GDP.csv"), DataFrame(opt_model_rice_cost_minimization[:neteconomy, :YNET]))

    println("Optimization convergence result: ", convergence_rice_cost_minimization)
    println("RICE cost-minimization optimization complete.")
    println()
end


#------------------------------------------------------------------------------------------------------
# Run RICE Utilitarian Optimization.
#------------------------------------------------------------------------------------------------------
if rice_utilitarian == true

    println("Starting RICE utilitarian optimization...")

    # Optimize model.
    opt_output_rice_utilitarian, opt_emissions_rice_utilitarian, opt_mitigation_rice_utilitarian, opt_tax_rice_utilitarian, opt_model_rice_utilitarian, convergence_rice_utilitarian = optimize_rice(optimization_algorithm, n_opt_periods, stop_time_rice, tolerance_rice, backstop_prices, run_utilitarian=true, ρ=ρ, η=η, remove_negishi=remove_negishi)

    # Create folder to store some key results.
    output_directory = joinpath(@__DIR__, "../", "results", results_folder, "rice_utilitarian")
    mkpath(output_directory)

    # Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
    save(joinpath(output_directory, "MitigationRate.csv"), DataFrame(opt_mitigation_rice_utilitarian))
    save(joinpath(output_directory, "Emissions.csv"), DataFrame(opt_emissions_rice_utilitarian))
    save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(opt_tax_rice_utilitarian))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temp=opt_model_rice_utilitarian[:climatedynamics, :TATM]))
    save(joinpath(output_directory, "GDP.csv"), DataFrame(opt_model_rice_utilitarian[:neteconomy, :YNET]))
    save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(opt_model_rice_utilitarian[:neteconomy, :CPC]))

    println("Optimization convergence result: ", convergence_rice_utilitarian)
    println("RICE utilitarian optimization complete.")
    println()
end


#------------------------------------------------------------------------------------------------------
# Run FUND Cost-minimization Optimization.
#------------------------------------------------------------------------------------------------------
if fund_cost_minimization == true

    println("Starting FUND cost-minimization optimization...")

    # Optimize model.
    opt_output_fund_cost_minimization, opt_mitigation_fund_cost_minimization, opt_tax_fund_cost_minimization, opt_model_fund_cost_minimization, convergence_fund_cost_minimization = optimize_fund(optimization_algorithm, 20, stop_time_fund, tolerance_fund, run_utilitarian=false, ρ=ρ, η=η, welfare_year=2010, end_year=2300)

    # Create folder to store some key results.
    output_directory = joinpath(@__DIR__, "../", "results", results_folder, "fund_costmin")
    mkpath(output_directory)

    # Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
    save(joinpath(output_directory, "MitigationRate.csv"), DataFrame(opt_mitigation_fund_cost_minimization))
    # Just save one column of global tax array (each column is identical for all regions).
    save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(global_carbon_tax=opt_tax_fund_cost_minimization[:,1]))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temperature=opt_model_fund_cost_minimization[:climatedynamics, :temp]))
    save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(opt_model_fund_cost_minimization[:fund_welfare, :cpc]))

    println("Optimization convergence result: ", convergence_fund_cost_minimization)
    println("FUND cost_minimization optimization complete.")
    println()
end


#------------------------------------------------------------------------------------------------------
# Run FUND Utilitarian Optimization.
#------------------------------------------------------------------------------------------------------
if fund_utilitarian == true

    println("Starting FUND utilitarian optimization...")

    # Optimize model.
    opt_output_fund_utilitarian, opt_mitigation_fund_utilitarian, opt_tax_fund_utilitarian, opt_model_fund_utilitarian, convergence_fund_utilitarian = optimize_fund(optimization_algorithm, 20, stop_time_fund, tolerance_fund, run_utilitarian=true, ρ=ρ, η=η, welfare_year=2010, end_year=2300)

    # Create folder to store some key results.
    output_directory = joinpath(@__DIR__, "../", "results", results_folder, "fund_utilitarian")
    mkpath(output_directory)

    # Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
    save(joinpath(output_directory, "MitigationRate.csv"), DataFrame(opt_mitigation_fund_utilitarian))
    save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(opt_tax_fund_utilitarian))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temperature=opt_model_fund_utilitarian[:climatedynamics, :temp]))
    save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(opt_model_fund_utilitarian[:fund_welfare, :cpc]))

    println("Optimization convergence result: ", convergence_fund_utilitarian)
    println("FUND utilitiarian optimization complete.")
    println()
end

println("Analysis Complete.")

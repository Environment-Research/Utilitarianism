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
ρ = 0.008

# Elasticity of marginal utility of consumption.
η = 1.5

# Should the RICE model be run with a social welfare function that uses Negish weights (true = remove Negishi weights).
# *Note: if using Negishi weights, the model uses the default RICE settings of η=1.5 and ρ=1.5%.
remove_negishi = true

#------------------------------------------------------------------------------------------------------
# Choices For Model Versions To Run.
#------------------------------------------------------------------------------------------------------

# Run an optiization with RICE using global carbon prices?
rice_uniform = true

# Run an optization with RICE using regional carbon prices?
rice_utilitarian = true

# Run an optiization with RICE using global carbon prices?
fund_uniform = true

# Run an optization with RICE using regional carbon prices?
fund_utilitarian = true

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
stop_time_rice = 60
stop_time_fund = 60

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
# Run RICE Uniform Price Optimization.
#------------------------------------------------------------------------------------------------------
if rice_uniform == true

    println("Starting RICE uniform price optimization...")

    # Optimize model.
    opt_output_rice_uniform, opt_emissions_rice_uniform, opt_mitigation_rice_uniform, opt_tax_rice_uniform, opt_model_rice_uniform, convergence_rice_uniform = optimize_rice(optimization_algorithm, n_opt_periods, stop_time_rice, tolerance_rice, backstop_prices, run_utilitarian=false, ρ=ρ, η=η, remove_negishi=remove_negishi)

    # Create folder to store some key results.
    output_directory = joinpath(@__DIR__, "../", "results", results_folder, "rice_uniform")
    mkpath(output_directory)

    # Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
    save(joinpath(output_directory, "Emissions.csv"), DataFrame(opt_emissions_rice_uniform))
    save(joinpath(output_directory, "MitigationRate.csv"), DataFrame(opt_mitigation_rice_uniform))
    save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(global_carbon_tax=opt_tax_rice_uniform))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temp=opt_model_rice_uniform[:climatedynamics, :TATM]))
    save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(opt_model_rice_uniform[:neteconomy, :CPC]))
    save(joinpath(output_directory, "GDP.csv"), DataFrame(opt_model_rice_uniform[:neteconomy, :YNET]))

    println("Optimization convergence result: ", convergence_rice_uniform)
    println("RICE uniform price optimization complete.")
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
# Run FUND Uniform Price Optimization.
#------------------------------------------------------------------------------------------------------
if fund_uniform == true

    println("Starting FUND uniform price optimization...")

    # Optimize model.
    opt_output_fund_uniform, opt_mitigation_fund_uniform, opt_tax_fund_uniform, opt_model_fund_uniform, convergence_fund_uniform = optimize_fund(optimization_algorithm, 20, stop_time_fund, tolerance_fund, run_utilitarian=false, ρ=ρ, η=η, welfare_year=2010, end_year=2300)

    # Create folder to store some key results.
    output_directory = joinpath(@__DIR__, "../", "results", results_folder, "fund_uniform")
    mkpath(output_directory)

    # Save optimal CO₂ mitigation, carbon tax, per capita consumption, and global temperature anomaly.
    save(joinpath(output_directory, "MitigationRate.csv"), DataFrame(opt_mitigation_fund_uniform))
    # Just save one column of global tax array (each column is identical for all regions).
    save(joinpath(output_directory, "Carbon Tax.csv"), DataFrame(global_carbon_tax=opt_tax_fund_uniform[:,1]))
    save(joinpath(output_directory, "Temperature.csv"), DataFrame(temperature=opt_model_fund_uniform[:climatedynamics, :temp]))
    save(joinpath(output_directory, "PerCapitaConsumption.csv"), DataFrame(opt_model_fund_uniform[:fund_welfare, :cpc]))

    println("Optimization convergence result: ", convergence_fund_uniform)
    println("FUND uniform price optimization complete.")
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

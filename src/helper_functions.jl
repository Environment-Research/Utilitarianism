# #----------------------------------------------------------------------------------------------------------------------
# #----------------------------------------------------------------------------------------------------------------------
# This file contains functions and other snippets of code that are used in various calculations.
# #----------------------------------------------------------------------------------------------------------------------
# #----------------------------------------------------------------------------------------------------------------------


#######################################################################################################################
# CALCULATE REGIONAL CO₂ MITIGATION.
########################################################################################################################
# Description: This function calculates regional CO₂ mitigation levels as a function of a global carbon tax. It
#              uses the RICE2010 backstop price values and assumes a carbon tax of $0 in period 1.  If the number of
#              tax values is less than the total number of model time periods, the function assumes full decarbonization
#              (e.g. the tax = the backstop price) for all future periods without a specified tax.
#
# Function Arguments:
#
#       optimal_tax:    A vector of global carbon tax values to be optimized.
#       backstop_price: The regional backstop prices from RICE2010 (units must be in $1000s)
#       theta2:         The exponent on the abatement cost function (defaults to RICE2010 value).
#
# Function Output:
#
#       mitigation:     Regional mitigation rates resulting from the global carbon tax.
#----------------------------------------------------------------------------------------------------------------------

function mitigation_from_tax(optimal_tax::Array{Float64,1}, backstop_prices::Array{Float64,2}, theta2::Float64)

    # Initialize full tax vector with $0 tax in period 1 and maximum of the backstop price across all regions for remaining periods.
    full_tax = [0.0; maximum(backstop_prices, dims=2)[2:end]]

    # Set the periods being optimized to the optimized tax value (assuming full decarbonization for periods after optimization time frame).
    full_tax[2:(length(optimal_tax)+1)] = optimal_tax

    # Calculate regional mitigation rates from the full tax vector.
    mitigation = min.((max.(((full_tax ./ backstop_prices) .^ (1 / (theta2 - 1.0))), 0.0)), 1.0)

    return mitigation
end



#######################################################################################################################
# CREATE RICE OBJECTIVE FUNCTION.
########################################################################################################################
# Description: This function creates an objective function and an instance of RICE with user-specified parameter settings.
#              The objective function will take in a vector of global carbon tax values (cost-minimization) or regional
#              CO₂ mitigation rates (utilitarian) and returns the total economic welfare generated by that specifc
#              climate policy.
#
# Function Arguments:
#
#       run_utilitarian: A true/false indicator for whether or not to run the utilitarian optimization (true = run utilitarian).
#       ρ:                  Pure rate of time preference.
#       η:                  Elasticity of marginal utility of consumption.
#       backstop_prices:    The regional backstop prices from RICE2010 (units must be in dollars).
#       remove_negishi:     A true/false indicator for whether RICE should use a social welfare function with Negishi weights (true = remove Negishi weights).
#                           *Note: if using Negishi weights, RICE's discounting parameters default to η=1.5 and ρ=1.5%.
#
# Function Output:
#
#       rice_objective:     The objective function specific to user model settings.
#       m:                  An instance of RICE2010 consistent with user model settings.
#----------------------------------------------------------------------------------------------------------------------

function construct_rice_objective(run_utilitarian::Bool, ρ::Float64, η::Float64, backstop_prices::Array{Float64,2}, remove_negishi::Bool)

    # Get an instance of RICE given user settings.
    m = create_rice(ρ, η, remove_negishi)

    #--------------------------------------------------------------------------------------------------------
    # Create either a (i) cost-minimization or (ii) utilitarian objective function for this instance of RICE.
    #--------------------------------------------------------------------------------------------------------
    rice_objective = if run_utilitarian == false

        #---------------------------------------
        # Cost-minimzation price objective function.
        #---------------------------------------
        function(optimal_global_tax::Array{Float64,1})
            # Set the regional mitigation rates to the value implied by the global optimal carbon tax and return total welfare.
            update_param!(m, :MIU, mitigation_from_tax(optimal_global_tax, backstop_prices, 2.8))
            run(m)
            return m[:welfare, :UTILITY]
        end

    else

        #---------------------------------------
        # Utilitarian objective function.
        #---------------------------------------
        function(optimal_mitigation_vector::Array{Float64,1})
            # Number of periods with optimized rates (optimization program requires a vector).
            n_opt_periods = Int(length(optimal_mitigation_vector) / 12)
            # NOTE: for convenience, this objective directly optimizes the regional mitigation rates.
            # Initialze a regional mitigation array, assuming first period = 0% mitigation and periods after optimization achieve full decarbonization.
            optimal_regional_mitigation = vcat(zeros(1,12), ones(59,12))
            optimal_regional_mitigation[2:(n_opt_periods + 1), :] = reshape(optimal_mitigation_vector, (n_opt_periods, 12))
            # Set the optimal regional mitigation rates and return total welfare.
            update_param!(m, :MIU, optimal_regional_mitigation)
            run(m)
            return m[:welfare, :UTILITY]
        end

    end

    # Return the newly created objective function and the specific instance of RICE.
    return rice_objective, m
end



#######################################################################################################################
# OPTIMIZE RICE.
########################################################################################################################
# Description: This function takes an objective function (given user-supplied model settings), and optimizes it for the
#              cost-minimization (global carbon taxes) or utilitarian (regional carbon taxes) approach to find the
#              policy that maximizes global economic welfare. Note that the utilitarian objective function optimizes
#              on the decarbonization fraction (for more efficient code) and then calculates the corresponding regional
#              carbon tax values.
#
# Function Arguments:
#
#       optimization_algorithm:  The optimization algorithm to use from the NLopt package.
#       n_opt_periods:           The number of model time periods to optimize over.
#       stop_time:               The length of time (in seconds) for the optimization to run in case things do not converge.
#       tolerance:               Relative tolerance criteria for convergence (will stop if |Δf| / |f| < tolerance from one iteration to the next.)
#       backstop_price:          The regional backstop prices from RICE2010 (units must be in dollars).
#       run_utilitarian:      A true/false indicator for whether or not to run the utilitarian optimization (true = run utilitarian).
#       ρ:                       Pure rate of time preference.
#       η:                       Elasticity of marginal utility of consumption.
#       remove_negishi:          A true/false indicator for whether RICE should use a social welfare function with Negishi weights (true = remove Negishi weights).
#
# Function Output
#
#       optimized_policy_vector: The vector of optimized policy values returned by the optimization algorithm.
#       optimal_emissions:       Optimal emissions for all time periods.
#       optimal_mitigation:      Optimal mitigation rates for all time periods (2005-2595) resulting form the optimization.
#       optimal_tax:             The optimal tax for all periods and regions used to run the model.
#       opt_model:               An instance of RICE (with user-defined settings) set with the optimal CO₂ mitigation policy.
#       convergence_result:      Indicator for whether or not the optimization converged.
#----------------------------------------------------------------------------------------------------------------------


function optimize_rice(optimization_algorithm::Symbol, n_opt_periods::Int, stop_time::Int, tolerance::Float64, backstop_prices::Array{Float64,2}; run_utilitarian::Bool=true, ρ::Float64=0.008, η::Float64=1.5, remove_negishi::Bool=true)

    # -------------------------------------------------------------
    # Create objective function and values needed for optimization.
    #--------------------------------------------------------------

    # Create objective function and instance of RICE, given user settings.
    objective_function, optimal_model = construct_rice_objective(run_utilitarian, ρ, η, backstop_prices, remove_negishi)

    # Set objective function, upper bound, and number of optimzation objectives (will differ between cost-minimization and utilitarian approaches).
    if run_utilitarian == false
        # Number of objectives is equal to time periods being optimized.
        n_objectives = n_opt_periods
        # Upper bound is maximum of backstop price, across all regions.
        upper_bound = maximum(backstop_prices, dims=2)[2:(n_objectives+1)]
    else
        # Number of objectives is equal to time periods being optimizer × 12 regions.
        n_objectives = n_opt_periods * 12
        # Upper bound is 1.0 because we are optimizing the decarbonization rate (1 = full mitigation).
        upper_bound = ones(n_objectives)
    end

    # Create lower bound.
    lower_bound = zeros(n_objectives)

    # Create initial condition for algorithm (set at 50% of upper bound).
    starting_point = upper_bound/2

    # -------------------------------------------------------
    # Create an NLopt optimization object and optimize model.
    #--------------------------------------------------------
    opt = Opt(optimization_algorithm, n_objectives)

    # Set the bounds.
    lower_bounds!(opt, lower_bound)
    upper_bounds!(opt, upper_bound)

    # Assign the objective function to maximize.
    max_objective!(opt, (x, grad) -> objective_function(x))

    # Set termination time.
    maxtime!(opt, stop_time)

    # Set optimizatoin tolerance (will stop if |Δf| / |f| < tolerance from one iteration to the next).
    ftol_rel!(opt, tolerance)

    # Optimize model.
    maximum_objective_value, optimized_policy_vector, convergence_result = optimize(opt, starting_point)

    # Create optimal decarbonization rates for all time periods (approach to do so will differ between cost-minimization and utilitarian).
    if run_utilitarian == false
        optimal_mitigation = mitigation_from_tax(optimized_policy_vector, backstop_prices, 2.8)
    else
        optimal_mitigation = vcat(zeros(1,12), ones(59,12))
        optimal_mitigation[2:(n_opt_periods+1), :] = reshape(optimized_policy_vector, (n_opt_periods, 12))
    end

    # Run user-specified version of RICE with optimal mitigation policy.
    update_param!(optimal_model, :MIU, optimal_mitigation)
    run(optimal_model)

    # Create optimal tax rates for all time periods (approach to do so will differ between cost-minimization and utilitarian).
    if run_utilitarian == false
        optimal_tax = [0.0; maximum(backstop_prices, dims=2)[2:end]]
        optimal_tax[2:(length(optimized_policy_vector)+1)] = optimized_policy_vector
    else
        optimal_tax = optimal_model[:emissions, :CPRICE]
    end

    # Create optimal industiral emissions for all time periods.
    optimal_emissions = optimal_model[:emissions, :EIND]

    # Return results of optimization, optimal emissions, optimal mitigation rates, optimal taxes, and RICE run with optimal mitigation policies.
    return optimized_policy_vector, optimal_emissions, optimal_mitigation, optimal_tax, optimal_model, convergence_result
end



#######################################################################################################################
# LINEAR INTERPOLATION FUNCTION
########################################################################################################################
# Description: This function will carry out a linear interpolation between optimal tax rates for a given time spread to
#              produce a series of annual carbon tax values.
#
# Function Arguments:
#
#       years_with_data: Years along the model time horizon with optimized tax values (will interpolate between these).
#       data:            The data points to be interpolated between (in this case a vector of tax values).
#       spacing:         The number of years between each tax value.
#
# Function Output:
#
#       results:         A vector of interpolated values based on the original input data.
#----------------------------------------------------------------------------------------------------------------------

function interpolate(years_with_data::Array{Int,1}, data::Array{Float64,1}, spacing::Int)
    # Create a vector of the annual years to interpolate across.
    annual_years = collect(years_with_data[1]:years_with_data[end])
    # Create a vector for results and set last value (for convenience).
    results = zeros(length(annual_years))
    results[end] = data[end]
    # Loop through, linearly interpolating between each set of periods with data.
    for index in 1:(length(years_with_data)-1)
        for t = (spacing*(index-1)+1):(spacing*index)
            results[t] = (annual_years[t] - years_with_data[index])/spacing * data[index+1] + (years_with_data[index+1]-annual_years[t])/spacing*data[index]
        end
    end
    # Return interpolated results.
    return results
end



#######################################################################################################################
# CALCULATE INDEX FOR A GIVEN FUND YEAR
########################################################################################################################
# Description: Just for convenience, this function gives the index for a given year within the FUND model time horizon.
#
# Function Arguments:
#
#       index_year: The year to get an index for.
#
# Function Output:
#
#        output:    An index for the supplied year (within the time frame 1950 - final year).
#----------------------------------------------------------------------------------------------------------------------

function fund_year_index(index_year::Int)
    return index_year - 1950 + 1
end



#######################################################################################################################
# CREATE AN ANNUAL GLOBAL CARBON TAX ARRAY
########################################################################################################################
# Description: This function will take a vector of carbon tax values and create a linear interpolation across the extent
#              of the FUND model time horizon. It assumes an optimized tax value every 10 years from 2010-2200 (with linear
#              interpolation between). After 2200, the tax rate stays constant until 2300. The function will replicate
#              this vector for each FUND region so they all face the same carbon tax.
#
# Function Arguments:
#
#       tax:               A vector of tax values.
#       welfare_year:      The year to start calculating how a climate policy affects total welfare (FUND has a historic spin up period).
#       end_year:          The last year to run FUND.
#
# Function Output:
#
#       global_tax_vector: An interpolated tax vector for all time periods, replicated 16 times for each FUND region.
#----------------------------------------------------------------------------------------------------------------------

function create_global_tax_fund(tax::Array{Float64,1}, welfare_year::Int, end_year::Int)
    # Initialize global tax vector for entire length of FUND time horizon.
    global_tax_vector = zeros(length(1950:end_year))
    # Linearly interpolate between values from 2010-2200 (i.e. 20 tax values).
    global_tax_vector[fund_year_index(welfare_year):fund_year_index(2200)] = interpolate(collect(welfare_year:10:2200), tax[1:20], 10)
    # Assume tax rate remains constant after 2200.
    global_tax_vector[fund_year_index(2201):end] .= global_tax_vector[fund_year_index(2200)]
    # Repeat vector 16 times for each region.
    return repeat(global_tax_vector, outer=[1, 16])
end



#######################################################################################################################
# CREATE AN ANNUAL REGIONAL CARBON TAX ARRAY
########################################################################################################################
# Description: This function will take a vector of carbon tax values specific to each FUND region, and create a linear
#              interpolation across the extent of the FUND model time horizon. For each region, it assumes an optimized
#              tax value every 10 years from 2010-2200 (with linear interpolation between). After 2200, the tax rate stays
#              constant until 2300. The function will return an array, where each column is a unique regional tax series.
#
# Function Arguments:
#
#       tax:                 A vector of tax values for all regions.
#       welfare_year:        The year to start calculating how a climate policy affects total welfare (FUND has a historic spin up period).
#       end_year:            The last year to run FUND.
#
# Function Output:
#
#       regional_tax_matrix: A matrix of interpolated tax values for all time periods, with each column representing a FUND region.
#----------------------------------------------------------------------------------------------------------------------

function create_regional_tax_fund(tax::Array{Float64,1}, welfare_year::Int, end_year::Int)
    # Initialize regional tax array for entire length of FUND time horizon.
    regional_tax_matrix = zeros(length(1950:end_year), 16)
    # Reshape optimal tax vector to be a matrix (just makes indexing easier). Each row = a decade's tax value, each column = a region.
    opt_tax = reshape(tax, (20,16))

    # Loop through and create annual tax values for each region.
    for r = 1:16
        regional_tax_matrix[fund_year_index(welfare_year):fund_year_index(2200), r] = interpolate(collect(welfare_year:10:2200), opt_tax[1:20,r], 10)
        # Set all values after 2200 to a constant tax value.
        regional_tax_matrix[fund_year_index(2201):end, r] .= regional_tax_matrix[fund_year_index(2200), r]
    end

    return regional_tax_matrix
end



#######################################################################################################################
# CREATE REGIONAL CO₂ MITIGATION RATES GIVEN A CARBON TAX
########################################################################################################################
# Description: This function will take an instance of FUND run with an optimal carbon tax policy and return the resulting
#              CO₂ mitigation rates for each region. Note that a carbon tax in FUND has both a temporary and permanent
#              effect on emission reductions. The mitigation rates calculated here represent the percentage difference in
#              emissions for a given year relative to baseline case with no carbon tax or climate policy.
#
# Function Arguments:
#
#       optimal_model:    An instance of Mimi-FUND that has been run with an optimal carbon tax policy.
#       end_year:         The last year to run FUND.
#
# Function Output:
#
#       mitigation_rates: An array of CO₂ emission reduction rates caused by the carbon tax for each FUND region.
#----------------------------------------------------------------------------------------------------------------------

function regional_mitigation(optimal_model::Model, end_year::Int)

    # Get baseline version of FUND with no carbon tax but same parameter settings as optimal model.
    base_model = deepcopy(optimal_model)
    update_param!(base_model, :currtax, zeros(length(1950:end_year), 16))
    run(base_model)

    # Initialze an array to store regional mitigation rates.
    mitigation_rates = zeros(length(1950:end_year), 16)

    # Loop through each region and calculate mitigation relative to base case with no policy.
    # Note, first FUND period (1950) is a 'missing' value, so skip that.
    for r = 1:16
        mitigation_rates[2:end,r] = (base_model[:emissions, :emissionwithforestry][2:end,r] .- optimal_model[:emissions, :emissionwithforestry][2:end,r]) ./ base_model[:emissions, :emissionwithforestry][2:end,r]
    end

    return mitigation_rates
end



#######################################################################################################################
# CREATE FUND OBJECTIVE FUNCTION.
########################################################################################################################
# Description: This function creates an objective function and an instance of FUND with user-specified parameter settings.
#              The objective function will take in a vector of global or regional (utilitarian)
#              carbon tax values and returns the total economic welfare generated by that specifc climate policy.
#
# Function Arguments:
#
#       run_utilitarian: A true/false indicator for whether or not to run the utilitarian optimization (true = run utilitarian).
#       ρ:                  Pure rate of time preference.
#       η:                  Elasticity of marginal utility of consumption.
#       welfare_year:       The year to start calculating how a climate policy affects total welfare (FUND has a historic spin up period).
#       end_year:           The last year to run FUND.
#
# Function Output:
#
#       fund_objective:     The objective function specific to user model settings.
#       m:                  An instance of FUND consistent with user model settings.
#----------------------------------------------------------------------------------------------------------------------


function construct_fund_objective(run_utilitarian::Bool, ρ::Float64, η::Float64, welfare_year::Int, end_year::Int)

    # Get an instance of FUND given user settings.
    m = create_fund(ρ, η, welfare_year)

    #--------------------------------------------------------------------------------------------------------
    # Create either a (i) cost-minimization price or (ii) utilitarian objective function for this instance of FUND.
    #--------------------------------------------------------------------------------------------------------
    fund_objective = if run_utilitarian == false

        #---------------------------------------
        # Cost-minimization Price objective function.
        #---------------------------------------
        function(optimal_global_tax::Array{Float64,1})
            # Apply a global carbon tax to each reagion, run the model, and return total welfare.
            update_param!(m, :currtax, create_global_tax_fund(optimal_global_tax, welfare_year, end_year))
            run(m)
            return m[:fund_welfare, :UTILITY][end]
        end

    else

        #---------------------------------------
        # Utilitarian objective function.
        #---------------------------------------
        function regional_tax_fund_objective(regional_tax_vector::Array{Float64,1})
            # Create an array of unique optimal tax paths for each FUND region
            update_param!(m, :currtax, create_regional_tax_fund(regional_tax_vector, welfare_year, end_year))
            run(m)
            return m[:fund_welfare, :UTILITY][end]
        end
    end

    # Return the newly created objective function and the specific instance of RICE.
    return fund_objective, m
end



#######################################################################################################################
# OPTIMIZE FUND.
########################################################################################################################
# Description: This function takes an objective function (given user-supplied model settings), and optimizes it for the
#              cost-minimization (global carbon taxes) or utilitarian (regional carbon taxes) approach to find the
#              policy that maximizes global economic welfare.
#
# Function Arguments:
#
#       optimization_algorithm:  The optimization algorithm to use from the NLopt package.
#       n_opt_periods:           The number of model time periods to optimize over.
#       stop_time:               The length of time (in seconds) for the optimization to run in case things do not converge.
#       tolerance:               Relative tolerance criteria for convergence (will stop if |Δf| / |f| < tolerance from one iteration to the next.)
#       run_utilitarian:      A true/false indicator for whether or not to run the utilitarian optimization (true = run utilitarian).
#       ρ:                       Pure rate of time preference.
#       η:                       Elasticity of marginal utility of consumption.
#       welfare_year:            The year to start calculating how a climate policy affects total welfare (FUND has a historic spin up period).
#       end_year:                The last year to run FUND.
#
# Function Output
#
#       optimized_policy_vector: The vector of optimized policy values returned by the optimization algorithm.
#       optimal_mitigation:      Optimal mitigation rates for all time periods (2005-2595) resulting form the optimization.
#       optimal_tax:             The optimal tax for all periods and regions used to run the model.
#       opt_model:               An instance of FUND (with user-defined settings) set with the optimal CO₂ mitigation policy.
#       convergence_result:      Indicator for whether or not the optimization converged.
#----------------------------------------------------------------------------------------------------------------------

function optimize_fund(optimization_algorithm::Symbol, n_opt_periods::Int, stop_time::Int, tolerance::Float64; run_utilitarian::Bool=true, ρ::Float64=0.008, η::Float64=1.5, welfare_year::Int=2010, end_year::Int=2300)

    # -------------------------------------------------------------
    # Create objective function and values needed for optimization.
    #--------------------------------------------------------------

    # Create objective function and instance of FUND, given user settings.
    objective_function, optimal_model = construct_fund_objective(run_utilitarian, ρ, η, welfare_year, end_year)

    # Set number of optimzation objectives (will differ between cost-minimization and utilitarian approaches).
    if run_utilitarian == false
        # Number of objectives is equal to the number of tax values (one for every 10 years) being optimized.
        n_objectives = n_opt_periods
    else
        # Number of objectives is equal to number of tax values being optimized × 16 regions.
        n_objectives = n_opt_periods * 16
    end

    # Create lower and upper bounds (assume tax cannot go above $5000/ton CO₂).
    lower_bound = zeros(n_objectives)
    upper_bound = ones(n_objectives) .* 5000.0

    # Create initial condition for algorithm (start tax at $50 for all time periods and regions).
    starting_point = ones(n_objectives) .* 50.0

    # -------------------------------------------------------
    # Create an NLopt optimization object and optimize model.
    #--------------------------------------------------------
    opt = Opt(optimization_algorithm, n_objectives)

    # Set the bounds.
    lower_bounds!(opt, lower_bound)
    upper_bounds!(opt, upper_bound)

    # Assign the objective function to maximize.
    max_objective!(opt, (x, grad) -> objective_function(x))

    # Set termination time.
    maxtime!(opt, stop_time)

    # Set optimizatoin tolerance (will stop if |Δf| / |f| < tolerance from one iteration to the next).
    ftol_rel!(opt, tolerance)

    # Optimize model.
    maximum_objective_value, optimized_policy_vector, convergence_result = optimize(opt, starting_point)

    # Calculate the full tax series for all time periods and regions (approach to do so will differ between cost-minimization and utilitarian).
    if run_utilitarian == false
        optimal_tax = create_global_tax_fund(optimized_policy_vector, welfare_year, end_year)
    else
        optimal_tax = create_regional_tax_fund(optimized_policy_vector, welfare_year, end_year)
    end

    # Run user-specified version of FUND with optimal carbon tax.
    update_param!(optimal_model, :currtax, optimal_tax)
    run(optimal_model)

    # Create optimal regional decarbonization rates for all time periods resulting from the carbon tax.
    optimal_mitigation = regional_mitigation(optimal_model, end_year)

    # Return results of optimization, optimal mitigation rates, optimal taxes, and FUND run with optimal mitigation policies.
    return optimized_policy_vector, optimal_mitigation, optimal_tax, optimal_model, convergence_result
end

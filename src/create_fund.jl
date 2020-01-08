#-------------------------------------------------------------------------------
# This function creates an instance of Mimi-FUND, given user specifications.
#-------------------------------------------------------------------------------

# Load packages.
using Mimi
using DataFrames
using CSVFiles
using MimiFUND

# Load necessary model and data files.
include(joinpath("new_components", "updated_welfare_fund.jl"))


# Create a function to construct an updated version of FUND.
function create_fund(ρ::Float64, η::Float64, welfare_year::Int)

    # ---------------------------------------------
    # Create MimiRICE2010 model and set parameters.
    # ---------------------------------------------

    # Load base version of Mimi-FUND and set time horizon to 1950-2300.
    m = MimiFUND.get_model()
    set_dimension!(m, :time, collect(1950:2300))

    # Add in new welfare component.
    add_comp!(m, fund_welfare, after = :impactaggregation)

    # Set parameters.
    set_param!(m, :fund_welfare, :ρ, ρ)
    set_param!(m, :fund_welfare, :η, η)
    set_param!(m, :fund_welfare, :welfare_year, welfare_year)

    # Create component connections.
    connect_param!(m, :fund_welfare, :pop, :population, :population)
    connect_param!(m, :fund_welfare, :c, :socioeconomic, :consumption)

    # Return user-specified model.
    return m
end



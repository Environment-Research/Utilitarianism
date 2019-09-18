#-------------------------------------------------------------------------------
# This function creates an instance of MimiRICE2010, given user specifications.
#-------------------------------------------------------------------------------

# Load packages.
using Mimi
using DataFrames
using CSVFiles
using MimiRICE2010

# Load necessary model and data files.
include("new_components/updated_welfare.jl")
un_population = DataFrame(load(joinpath(@__DIR__, "..", "data", "UN_population_rice_regions.csv"), skiplines_begin=3))


# Create a function to construct an updated version of RICE2010.
function create_rice(; ρ::Float64=0.008, η::Float64=1.5, remove_negishi::Bool=true)

    # ---------------------------------------------
    # Create MimiRICE2010 model and set parameters.
    # ---------------------------------------------

    # Load base version of MimiRICE2010.
    m = MimiRICE2010.get_model()

    # Set savings rate to 25.8% for all regions and time periods.
    set_param!(m, :neteconomy, :S, ones(60,12) .* 0.258)

    # Set population to updated UN projctions.
    set_param!(m, :grosseconomy, :l, un_population)
    set_param!(m, :neteconomy, 	 :l, un_population)
    set_param!(m, :welfare,      :l, un_population)

    # Replace welfare component if switching off Negishi weights and then set necessary parameters.
    if remove_negishi == true

	   	delete!(m, :welfare)
    	add_comp!(m, updated_welfare)

    	set_param!(m, :updated_welfare, :ρ, ρ)
    	set_param!(m, :updated_welfare, :η, η)
    	set_param!(m, :updated_welfare, :pop, un_population)

    	connect_param!(m, :updated_welfare, :cpc, :neteconomy, :CPC)
    end

    # Return user-specified model.
    return m
end

#-------------------------------------------------------------------------------
# This function creates an instance of MimiRICE2010, given user specifications.
#-------------------------------------------------------------------------------

# Load packages.
using Mimi
using DataFrames
using CSVFiles
using MimiRICE2010

include("new_components/updated_welfare_rice.jl")

# Load necessary model and data files.
un_population = DataFrame(load(joinpath(@__DIR__, "..", "data", "UN_population_rice_regions.csv"), skiplines_begin=3))


# Create a function to construct an updated version of RICE2010.
function create_rice(ρ::Float64, η::Float64, remove_negishi::Bool)

    # ---------------------------------------------
    # Create MimiRICE2010 model and set parameters.
    # ---------------------------------------------

    # Load base version of MimiRICE2010.
    m = MimiRICE2010.get_model()
    #include(joinpath(@__DIR__, "..", "src", "new_components\\Emissions_SlowDown_rice.jl"))
    #include(joinpath(@__DIR__, "..", "src", "new_components\\CatastrophicDamages.jl"))
    #replace_comp!(m, emissions, :emissions, reconnect=true) #unblock this for political feasibility run; need to lower initial guess in cost-min run
    #replace_comp!(m, damages, :damages, reconnect=true)  #unblock this for catastrophic damages output

    # Set savings rate to 25.8% for all regions and time periods.
    update_param!(m, :S, ones(60,12) .* 0.258)

    # Set population to updated UN projctions.
    update_param!(m, :l, convert(Matrix, un_population))

    # Replace welfare component if switching off Negishi weights and then set necessary parameters.
    if remove_negishi == true
        # We cannot use `reconnect` here because the new welfare component does not have all the same
        # parameters as the old one
        replace!(m, :welfare=>welfare, reconnect=false)

        # Set the welfare function parameters
        set_param!(m, :welfare, :ρ, ρ)
        set_param!(m, :welfare, :η, η)

        # Connect the population parameter in the new component to the existing
        # population model level parameter
        connect_param!(m, :welfare, :pop, :l)

        # Connect the welfare component with the net economy component
        connect_param!(m, :welfare, :cpc, :neteconomy, :CPC)
    end

    # Return user-specified model.
    return m
end

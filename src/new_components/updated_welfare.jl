# -----------------------------------------------
# Total Welfare
# -----------------------------------------------

@defcomp welfare begin

    regions  = Index()                         # 12 regions in RICE2010.

    ρ       = Parameter()                      # Pure rate of time preference.
    η       = Parameter()                      # Elasticity of marginal utility of consumption.
    pop     = Parameter(index=[time, regions]) # Regional population levels (millions of people).
    cpc     = Parameter(index=[time, regions]) # Per capita consumption levels ($1000s).

    UTILITY = Variable()                       # Total economic welfare over model time horizon (using the same name as the default RICE welfare component).


    function run_timestep(p, v, d, t)

        # Calculate total welfare for each period. Note, if η = 1, the social welfare function becomes log(x).
        if is_first(t)
            if p.η == 1.0
                v.UTILITY = sum(log(p.cpc[t,:]) .* p.pop[t,:]) / (1.0 + p.ρ)^(10*(t.t - 1))
            else
                v.UTILITY = sum((p.cpc[t,:] .^ (1.0 - p.η)) ./ (1.0 - p.η) .* p.pop[t,:]) / (1.0 + p.ρ)^(10*(t.t - 1))
            end
        else
            if p.η == 1.0
                v.UTILITY = v.UTILITY + sum(log(p.cpc[t,:]) .* p.pop[t,:]) / (1.0 + p.ρ)^(10*(t.t - 1))
            else
                v.UTILITY = v.UTILITY + sum((p.cpc[t,:] .^ (1.0 - p.η)) ./ (1.0 - p.η) .* p.pop[t,:]) / (1.0 + p.ρ)^(10*(t.t - 1))
            end
        end
    end
end

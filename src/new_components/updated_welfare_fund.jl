# -----------------------------------------------
# Total Welfare
# -----------------------------------------------

@defcomp fund_welfare begin

    regions  = Index()                                   # 16 regions in FUND.

    ρ                 = Parameter()                      # Pure rate of time preference.
    η                 = Parameter()                      # Elasticity of marginal utility of consumption.
    welfare_year::Int = Parameter()                      # First year to begin counting total discounted welfare over time.
    pop               = Parameter(index=[time, regions]) # Regional population levels (millions of people).
    c                 = Parameter(index=[time, regions]) # Regional total consumption levels ($).

    UTILITY           = Variable(index=[time])           # Total economic welfare over model time horizon (using the same name as the default RICE welfare component).
    cpc               = Variable(index=[time, regions])  # Per capita consumption levels ($).


    function run_timestep(p, v, d, t)

        # Calculate regional per capita consumption levels.
        for r in d.regions
            v.cpc[t,r] = p.c[t,r] / p.pop[t,r] / 1000000.0
        end

        # Calculate total welfare for each period. If η = 1, the social welfare function becomes log(x).
        # Note: FUND starts a spin-up period in 1950 to initialize the model, so should not track welfare in early periods.
        if gettime(t) < p.welfare_year
            v.UTILITY[t] = 0.0
        else
            # Calculate total welfare over time.
            if p.η == 1.0
                v.UTILITY[t] = v.UTILITY[t-1] + sum(log.(v.cpc[t,:]) .* p.pop[t,:]) / (1.0 + p.ρ)^(gettime(t) - p.welfare_year)
            else
                v.UTILITY[t] = v.UTILITY[t-1] + sum((v.cpc[t,:] .^ (1.0 - p.η)) ./ (1.0 - p.η) .* p.pop[t,:]) / (1.0 + p.ρ)^(gettime(t) - p.welfare_year)
            end
        end
    end
end

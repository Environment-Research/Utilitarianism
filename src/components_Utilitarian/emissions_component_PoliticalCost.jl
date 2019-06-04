using Mimi

@defcomp emissions begin
    regions = Index()

    #Here I include the Carbon Price as a parameter that falls out once you know the MIU you want (which the solver picks)
    # It seems easier this way since I can bound the choices of MIU between 0 and 1. 

    E = Variable(index=[time]) # Total CO2 emissions (GtCO2 per year)
    EIND = Variable(index=[time, regions]) # Industrial emissions (GtCO2 per year)
    CCA = Variable(index=[time]) # Cumulative indiustrial emissions
    ABATECOST = Variable(index=[time, regions]) # Cost of emissions reductions  (trillions 2005 USD per year)
    MCABATE = Variable(index=[time, regions]) # Marginal cost of abatement (2005$ per ton CO2)
    CPRICE = Variable(index=[time, regions]) # Carbon price (2005$ per ton of CO2)

    sigma = Parameter(index=[time, regions]) # CO2-equivalent-emissions output ratio
    YGROSS = Parameter(index=[time, regions]) # Gross world product GROSS of abatement and damages (trillions 2005 USD per year)
    etree = Parameter(index=[time]) # Emissions from deforestation
    cost1 = Parameter(index=[time, regions]) # Adjusted cost for backstop
    expcost2 = Parameter(index=[regions]) # Exponent of control cost function
    partfract = Parameter(index=[time, regions]) # Fraction of emissions in control regime; set to 1 in all relevant runs
    pbacktime = Parameter(index=[time, regions]) # Backstop price
    MIU = Parameter(index=[time, regions]) # Emission control rate GHGs
end

function run_timestep(state::emissions, t::Int)
    v, p, d = getvpd(state)

    #Define function for EIND
    for r in d.regions
        v.EIND[t,r] = p.sigma[t,r] * p.YGROSS[t,r] * (1-p.MIU[t,r])
    end

    #Define function for E
    v.E[t] = sum(v.EIND[t,:]) + p.etree[t]

   #Define function for CCA
    if t==1
        v.CCA[t] = sum(v.EIND[t,:]) * 10.
    else
        v.CCA[t] =  v.CCA[t-1] + (sum(v.EIND[t,:]) * 10.)
    end

    #Define function for ABATECOST
    for r in d.regions
        if t>2
        v.ABATECOST[t,r] = p.YGROSS[t,r] * p.cost1[t,r] * (p.MIU[t,r]^p.expcost2[r] + 70*(p.MIU[t,r] - p.MIU[t-1,r])^4)
        else
        v.ABATECOST[t,r] = p.YGROSS[t,r] * p.cost1[t,r] * (p.MIU[t,r]^p.expcost2[r] + 70*(p.MIU[t,r] - 0)^4)
        end
    end

    #Define function for MCABATE
    for r in d.regions
        v.MCABATE[t,r] = p.pbacktime[t,r] * p.MIU[t,r]^(p.expcost2[r] - 1)
    end

    #Define function for CPRICE
    for r in d.regions
        v.CPRICE[t,r] = p.pbacktime[t,r] * 1000 * p.MIU[t,r]^(p.expcost2[r] - 1) 
    end

end

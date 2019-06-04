using Mimi

@defcomp emissions begin
    regions = Index()

    E = Variable(index=[time]) # Total CO2 emissions (GtCO2 per year)
    EIND = Variable(index=[time, regions]) # Industrial emissions (GtCO2 per year)
    CCA = Variable(index=[time]) # Cumulative indiustrial emissions
    ABATECOST = Variable(index=[time, regions]) # Cost of emissions reductions  (trillions 2005 USD per year)
    MCABATE = Variable(index=[time, regions]) # Marginal cost of abatement (2005$ per ton CO2)
    MIU = Variable(index=[time, regions]) # Emission control rate GHGs

    sigma = Parameter(index=[time, regions]) # CO2-equivalent-emissions output ratio
    YGROSS = Parameter(index=[time, regions]) # Gross world product GROSS of abatement and damages (trillions 2005 USD per year)
    etree = Parameter(index=[time]) # Emissions from deforestation
    cost1 = Parameter(index=[time, regions]) # Adjusted cost for backstop
    expcost2 = Parameter(index=[regions]) # Exponent of control cost function
    partfract = Parameter(index=[time, regions]) # Fraction of emissions in control regime
    pbacktime = Parameter(index=[time, regions]) # Backstop price
    CPRICE = Parameter(index=[time, regions]) # Carbon price (2005$ per ton of CO2)
end

function run_timestep(state::emissions, t::Int)
    v, p, d = getvpd(state)

    #Define function for MIU (backed out directly from knowing CPRICE)
    # Need 2 fixes:
    # First if the backstop price falls to zero I manually set that emissions are zero
    # Second the model needs to know reduction cannot go above 1. (RICE doesnt allow negative emissions)
    # Dont need analogous condition for MIU going below zero since there is an inada condition on emissions control rates (thats why it breaks when backstop goes to zero, but its costless to marginally control emissions)
    for r in d.regions
        if p.pbacktime[t,r]>0
        v.MIU[t,r] = (p.CPRICE[t,r]/p.pbacktime[t,r]/1000)^(1/(p.expcost2[r] - 1))
        else 
        v.MIU[t,r] = 1
        end
        if v.MIU[t,r]>1
            v.MIU[t,r]=1
        end
    end

    #Define function for EIND
    for r in d.regions
        v.EIND[t,r] = p.sigma[t,r] * p.YGROSS[t,r] * (1-v.MIU[t,r])
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
        v.ABATECOST[t,r] = p.YGROSS[t,r] * p.cost1[t,r] * (v.MIU[t,r]^p.expcost2[r] + 70*(v.MIU[t,r] - v.MIU[t-1,r])^4)
        else
        v.ABATECOST[t,r] = p.YGROSS[t,r] * p.cost1[t,r] * (v.MIU[t,r]^p.expcost2[r] + 70*(v.MIU[t,r] - 0)^4)
        end
    end

    #Define function for MCABATE
    for r in d.regions
        v.MCABATE[t,r] = p.pbacktime[t,r] * v.MIU[t,r]^(p.expcost2[r] - 1)
    end

end

using DataFrames

include("Optimize_UtilitarianRICE.jl")

include("RICE2010_Utilitarian.jl")

IAM = getrice_Utilitarian(Negishi=false)  #getRICE has a code built in that will determine whether to apply Negishi weights

rho = .001
discount = ones(60,12)
     for i = 2:60
        discount[i,:] = discount[i-1,:]/((1+rho)^10)
     end
eta = 2.3
setparameter(IAM, :welfare, :elasmu, eta*ones(12))
setparameter(IAM, :welfare, :rr, discount)

solution = optimizeIAM_Utilitarian(IAM)


##EVERYTHING BELOW HERE IS JUST MAKING A NICE DATAFRAME FOR OUTPUT

t = collect(2005:10:2595)
temp = ones(length(t),1) #need to remake GlobalTemp because dataframes doesnt like 1-dimension
for j = 1:length(t)
		temp[j] = solution[:climatedynamics, :TATM][j]
end

IndustrialEmissions = DataFrame(solution[:emissions, :EIND])  #Emissions not including land use change
GlobalTemp = DataFrame(temp)
Population = DataFrame(solution[:welfare, :l])
CarbonTax = DataFrame(solution[:emissions, :CPRICE])
NetOutput = DataFrame(solution[:neteconomy, :YNET])  #This is net of climate damages
PerCapitaC = DataFrame(solution[:welfare, :CPC])

Data = (IndustrialEmissions, GlobalTemp, Population, CarbonTax, NetOutput, PerCapitaC)

for d in Data
	d[:Year] = t
end

for yr in (2005,2595)
   IndustrialEmissions = IndustrialEmissions[IndustrialEmissions[:Year].!=yr,:] #In GtCO2 
   GlobalTemp = GlobalTemp[GlobalTemp[:Year].!=yr,:] #Celcius Above Pre-Industrial
   Population = Population[Population[:Year].!=yr,:] #Millions
   CarbonTax = CarbonTax[CarbonTax[:Year].!=yr,:] # USD (2005)
   NetOutput = NetOutput[NetOutput[:Year].!=yr,:] # Trillions USD (2005)
   PerCapitaC = PerCapitaC[PerCapitaC[:Year].!=yr,:] # Thousands USD (2005)
end

oldvars = (:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9, :x10, :x11, :x12)
regvars = (:USA, :EU, :Japan, :Russia, :Eurasia, :China, :India, :MidEast, :Africa, :LatAm, :OHI, :OthAsia)

for d in (IndustrialEmissions, Population, CarbonTax, NetOutput, PerCapitaC)
		for (generic, region) in zip(oldvars, regvars)
				rename!(d, generic, region)
		end
end
		rename!(GlobalTemp, :x1, :GlobalTemp)

#this section is annoying, Julia wont seem to overwrite dataframes in a loop
IndustrialEmissions = stack(IndustrialEmissions, 1:12)
Population = stack(Population, 1:12)
CarbonTax = stack(CarbonTax, 1:12)
NetOutput = stack(NetOutput, 1:12)
PerCapitaC = stack(PerCapitaC, 1:12)

variable = (:Emissions, :Pop, :CarbonTax, :NetOutput, :PerCapitaC)

for (d, var) in zip((IndustrialEmissions, Population, CarbonTax, NetOutput, PerCapitaC), variable)
rename!(d, :variable, :Region)
rename!(d, :value, var)
end

Emissions = DataFrame(Region = IndustrialEmissions[:Region], Year = IndustrialEmissions[:Year], Emissions_Industrial=IndustrialEmissions[:Emissions])
Output = join(Emissions, Population, on=[:Region, :Year])
Output = join(Output, CarbonTax, on=[:Region, :Year])
Output = join(Output, NetOutput, on=[:Region, :Year])
Output = join(Output, PerCapitaC, on=[:Region, :Year])
Output = join(Output, GlobalTemp, on=[:Year])

#writetable("Results\\Smooth_Utilitarian.csv", Output)

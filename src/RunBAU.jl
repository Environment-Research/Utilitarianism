using DataFrames

include("src\\rice2010.jl")

IAM = getrice(Negishi=false)  #getRICE has a code built in that will determine whether to apply Negishi weights

run(IAM)

Output =  DataFrame(IAM[:emissions, :EIND])
writetable("results/BAU.csv", Output)

NonCO2 = DataFrame([IAM[:emissions, :E] IAM[:radiativeforcing, :FORC] IAM[:radiativeforcing, :forcoth]])
writetable("results/NonCO2.csv", NonCO2)

CPCBAU = DataFrame(IAM[:welfare, :CPC])
writetable("results/CPCBAU.csv", CPCBAU)
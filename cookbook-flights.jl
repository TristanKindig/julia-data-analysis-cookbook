## Load libraries

using Pkg
Pkg.add(["CSV", "DataFrames", "Dates", "GLM",
        "InvertedIndices", "Lazy", "Statistics",
        "StatsBase", "StatsModels", "VegaDatasets",
        "VegaLite"])
Pkg.update()
using CSV, DataFrames, Dates, GLM, InvertedIndices,
        Lazy, Statistics, StatsBase, StatsModels,
        VegaDatasets, VegaLite

## Load data files

project_path = "/Users/tristankindig/Google Drive/Data science/practice/julia_cookbook/"

airlines_df = CSV.read(string(project_path, "data/airlines.csv"), missingstrings = ["NA"])
flights_df = CSV.read(string(project_path, "data/flights.txt"), missingstrings = ["NA"], delim = '|')
planes_df = CSV.read(string(project_path, "data/planes.csv"), missingstrings = ["NA"])
weather_df = CSV.read(string(project_path, "data/weather.txt"), missingstrings = ["NA"], delim = '\t')

##

rename!(flights_df) do x lowercase(string(x)) end
rename!(airlines_df, :carrier => :carrier_code, :name => :carrier_name)

names(flights_df)

describe(flights_df)

##

flights_df[!, :full_sched_dep_time] = DateTime.(flights_df[:, :year],
    flights_df[:, :month], flights_df[:, :day], flights_df[:, :sched_dep_time] .÷ 100,
    flights_df[:, :sched_dep_time] .% 100, floor.(Int, zeros(336776)))

##

flights_df[ismissing.(flights_df[:, :dep_time]), :]

flights_df[!, 9:20]

by(flights_df, :carrier, n = :carrier => length)

df2 = by(dropmissing(flights_df, :air_time),
    :carrier,
    :air_time => mean)



mean_air_times_df = by(dropmissing(flights_df, :air_time),
    :carrier,
    :air_time => mean)

sort(mean_air_times_df, :air_time_mean)

flights_df[:, Not(:day)]

flights_df[:, All(:month, :)]

countmap(flights_df[:, :carrier])

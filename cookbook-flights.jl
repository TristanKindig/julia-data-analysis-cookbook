## Load libraries

using Pkg
Pkg.add(["CSV", "DataFrames", "Dates", "GLM", "InvertedIndices", "Lazy",
    "Plots", "Statistics", "StatsBase", "StatsModels", "TableView",
    "VegaDatasets", "VegaLite"])
Pkg.update()
using CSV, DataFrames, Dates, GLM, InvertedIndices, Lazy, Plots,
    Statistics, StatsBase, StatsModels, TableView, VegaDatasets, VegaLite

## Custom functions

function create_full_sched_time(df, type)
  return DateTime.(flights_df[:, :year],
      flights_df[:, :month], flights_df[:, :day], flights_df[:, type] .÷ 100,
      flights_df[:, type] .% 100, floor.(Int, zeros(size(flights_df, 1))))
end

function create_full_actual_time(df, type)
  temp = Array{Union{Missing, DateTime}, 1}(undef, size(df, 1))
  for i in 1:size(df, 1)
    if ismissing(df[i, type])
      temp[i] = missing
    else
      temp[i] = DateTime(df[i, :year], df[i, :month], df[i, :day], df[i, type] ÷ 100, df[i, type] % 100, 0)
    end
  end
  return temp
end

function pct_miss(col)
  missing_count = length(col[ismissing.(col)])
  return round(missing_count / length(col), digits = 2)
end

function hist_table(col, bins_range)
  return stack(DataFrame(countmap(cut(col, bins_range))), All())
end

function parse_date_missing(col)
  temp = Array{Union{Date, Missing}}(undef, length(col))
  for i in 1:length(col)
    if ismissing(col[i])
      temp[i] = missing
    else
      temp[i] = Date(col[i])
    end
  end
  return temp
end

## Load and clean data

project_path = joinpath("/", "Users", "tristankindig", "Google Drive",
    "Data Science", "projects_code", "julia-data-analysis-cookbook")

airlines_df = CSV.read(joinpath(project_path, "data", "airlines.csv"), missingstrings = ["NA"])
flights_df = CSV.read(joinpath(project_path, "data", "flights.txt"), missingstrings = ["NA"], delim = '|')
planes_df = CSV.read(joinpath(project_path, "data", "planes.csv"), missingstrings = ["NA", ""])
weather_df = CSV.read(joinpath(project_path, "data", "weather.txt"), missingstrings = ["NA"], delim = '\t')

rename!(flights_df) do x lowercase(string(x)) end

flights_df[:, :flight_num] = string.(flights_df[:, :flight])

flights_df.full_sched_dep_time = create_full_sched_time(flights_df, :sched_dep_time)
flights_df.full_sched_arr_time = create_full_sched_time(flights_df, :sched_arr_time)
flights_df.full_actual_dep_time = create_full_actual_time(flights_df, :dep_time)
flights_df.full_actual_arr_time = create_full_actual_time(flights_df, :arr_time)

select!(flights_df, Not([:year, :month, :day, :sched_dep_time, :dep_time,
    :sched_arr_time, :arr_time, :hour, :minute, :time_hour, :dep_delay,
    :arr_delay, :flight]))
rename!(flights_df, :tailnum => :tail_num, :carrier => :carrier_code,
    :air_time => :air_time_mins, :distance => :distance_crow_miles,
    :full_sched_dep_time => :sched_dep_time,
    :full_actual_dep_time => :actual_dep_time, :full_sched_arr_time => :sched_arr_time,
    :full_actual_arr_time => :actual_arr_time)
select!(flights_df, :carrier_code, :tail_num, :flight_num, :origin, :dest,
    :sched_dep_time, :actual_dep_time, :sched_arr_time, :actual_arr_time,
    :air_time_mins, :distance_crow_miles)

for obs in eachrow(flights_df)
  if (obs.sched_arr_time < obs.sched_dep_time)
    obs.sched_arr_time = obs.sched_arr_time + Day(1)
    if !ismissing(obs.actual_arr_time)
      obs.actual_arr_time = obs.actual_arr_time + Day(1)
    end
  end
end

rename!(airlines_df, :carrier => :carrier_code, :name => :carrier_name)

rename!(planes_df, :tailnum => :tail_num)
planes_df.year_new = parse_date_missing(planes_df.year)
select!(planes_df, Not(:year))
rename!(planes_df, :year_new => :year)

## Get percentage missings

showtable(aggregate(flights_df, pct_miss))

## Check to see if there are any observations with sched arr before dep times
# and missing actual dep times

flights_df[(flights_df.sched_arr_time .< flights_df.sched_dep_time) .&
    (ismissing.(flights_df.actual_dep_time)), [:actual_dep_time, :actual_arr_time]]

## Get the names of flights_df columns

names(flights_df)

## Describe flights_df

showtable(describe(flights_df))

## Check distribution of flight durations without histogram

hist_table(
    flights_df[.!ismissing.(flights_df.air_time_mins), :air_time_mins],
    range(0, stop = 700, step = 50)
)

## Check distribution of flight durations with histogram

flights_df |> @vlplot(
  :bar,
  x = {
    :air_time_mins,
    bin = {step = 50}},
  y = "count()",
  width = 500,
  height = 500)

## Were there any flights from NYC to NYC

flights_df[in.(flights_df.dest, Ref(["EWR", "JFK", "LGA"])), :]

## All combinations of origin/dest and just sort by n

df = by(flights_df, [:origin, :dest], n = :origin => length)
sort(df, :n, rev = true)

## All combinations of origin/dest and sort by origin then sort by n within origin

df = by(flights_df, [:origin, :dest], n = :origin => length)
sort(df, (order(:origin), order(:n, rev = true)))

## Group flights by week and plot

df = copy(flights_df)
df.week = Date.(fill(2013, size(df, 1))) .+ Week.(df.sched_dep_time)
df |> @vlplot(
  :line,
  x = :week,
  y = "count()",
  width = 500,
  height = 500
)

## Group flights by month and stack by origin

df = copy(flights_df)
df.month = Date.(fill(2013, size(df, 1))) .+ Month.(df.sched_dep_time)
df |> @vlplot(
  :area,
  x = :month,
  y = {"count()", stack = :normalize},
  color = :origin,
  width = 500,
  height = 500
)

## Stack bar chart of carrier by month

df = copy(flights_df)
df.month = Date.(fill(2013, size(df, 1))) .+ Month.(df.sched_dep_time)
df |> @vlplot(
  :bar,
  x = :month,
  y = "count()",
  color = :carrier_code,
  width = 500,
  height = 500
)

## Did any planes fly the same route more than once on the same day

df = copy(flights_df)
df.day = Date.(df.sched_dep_time)
df = by(df, [:tail_num, :flight_num, :day], n = :tail_num => length)
df[1 .< df.n, :]

## Do multiple carriers have planes with the same tailnum

df = by(flights_df, [:carrier_code, :tail_num], n = :carrier_code => length)
df = by(df, :tail_num, n = :tail_num => length)
repeated_tail_nums = df[1 .< df.n, :tail_num]
repeated_tail_nums = repeated_tail_nums[.!ismissing.(repeated_tail_nums)]

df = by(flights_df, [:carrier_code, :tail_num], n = :carrier_code => length)
dropmissing!(df)
sort(df[in.(df.tail_num, Ref(repeated_tail_nums)), :], :tail_num)

## What is the average flights/year for a plane

size(flights_df, 1) / length(unique(flights_df.tail_num))

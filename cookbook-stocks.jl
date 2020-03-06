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

## Create custom functions

function month_map(str)
   if str == "Jan"
       1
   elseif str == "Feb"
       2
   elseif str == "Mar"
       3
   elseif str == "Apr"
       4
   elseif str == "May"
       5
   elseif str == "Jun"
       6
   elseif str == "Jul"
       7
   elseif str == "Aug"
       8
   elseif str == "Sep"
       9
   elseif str == "Oct"
       10
   elseif str == "Nov"
       11
   elseif str == "Dec"
       12
   end
end

## Load and clean data

# load data
stocks_df = DataFrame(dataset("stocks"))

# get data in wide format
stocks_df = unstack(stocks_df, :symbol, :price)

# create correct date field
stocks_df[:, :new_date] = Date.(
    parse.(Int, getindex.(split.(stocks_df.date), 3)),
    month_map.(getindex.(split.(stocks_df.date), 1)),
    parse.(Int, getindex.(split.(stocks_df.date), 2))
)
select!(stocks_df, Not(:date))

# reorganize things
rename!(stocks_df, :new_date => :date)
rename!(stocks_df) do x lowercase(string(x)) end
select!(stocks_df, :date, :)
sort!(stocks_df, :date)

## Plot stocks over time

df = stack(stocks_df, Not(:date))
df = rename(df, :variable => :company, :value => :price)
df |>
@vlplot(mark = :line,
    x = :date,
    y = :price,
    color = :company,
    height = 500,
    width = 500,
    title = "Stock price over time"
)

## Plot only rows we have full data for

df = dropmissing(stocks_df)
df = stack(df, Not(:date))
df |>
@vlplot(
    mark = :line,
    x = {
        :date,
        axis = {format = "%Y"}
    },
    y = :value,
    color = :variable,
    height = 500,
    width = 500,
    title = "Stock price over time (only complete cases)")

## Get average price of one column

mean(skipmissing(stocks_df.aapl))

## Get average prices of each column

df = select(stocks_df, Not(:date))
aggregate(df, mean ∘ skipmissing)

## Get average prices of each column by year

df = copy(stocks_df)
df.year = Date.(year.(df.date))
df = select(df, Not(:date))
aggregate(df, :year, mean ∘ skipmissing)

## Get average prices of one column by year

df = copy(stocks_df)
df[:, :year] = Date.(year.(df.date))
by(df, :year, aapl_price_mean = :aapl => mean ∘ skipmissing)

## What if MSFT and IBM joined forces

df = copy(stocks_df)
df.msft_ibm = df.msft .+ df.ibm

## Get all observations such that 20 < msft

df = copy(stocks_df)
df[20 .< df.msft, [:date, :msft]]

## Get all observations such that 20 < msft and 30 < aapl < 40

df = copy(stocks_df)
df[(20 .< df.msft) .& (30 .< df.aapl .< 40), [:date, :aapl, :msft]]

## Get average prices of Google vs not-Google by year

function check_is_goog(str)
    if (str == "goog")
        "goog"
    else
        "not goog"
    end
end

df = stack(stocks_df, Not(:date))
df = rename(df, :variable => :company, :value => :price)
df.company_str = string.(df.company)
df.is_goog = check_is_goog.(df.company_str)
df.year = Date.(year.(df.date))
df = select(df, Not([:company, :company_str, :date]))
df = by(df, [:is_goog, :year], price_mean = :price => mean ∘ skipmissing)
df = sort(df, [:year, :is_goog])

## Plot stocks over time where price is averaged yearly

df = stack(stocks_df, Not(:date))
df = rename(df, :variable => :company, :value => :price)
df[:, :year] = Date.(year.(df.date))
df = by(df, [:year, :company], price_mean = :price => mean)
df |>
@vlplot(
    mark = {
        :line,
        point = true
    },
    x = :year,
    y = :price_mean,
    color = :company,
    height = 500,
    width = 500,
    title = "Stock price over time, averaged yearly"
)



## Randomly practicing select regex

select(stocks_df, Not(r"A"))
# move stuff to beginning
select(stocks_df, r"A", :)
# move stuff to end
select(stocks_df, All(Not(r"A"), :))

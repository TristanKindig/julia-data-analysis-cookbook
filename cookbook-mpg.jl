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

## Load and clean data

project_path = joinpath("/", "Users", "tristankindig", "Google Drive",
    "Data Science", "projects_code", "julia-data-analysis-cookbook")

mpg_df = CSV.read(joinpath(project_path, "data", "mpg.csv"), missingstrings = ["NA"])
mpg_df.year = Date.(mpg_df.year)

## Get all compact and subcompact observations

mpg_df[in.(mpg_df.class, Ref(["compact", "subcompact"])), :]

## Get all unique values of class

unique(mpg_df.class)

## Get counts of all unique values of class

countmap(mpg_df.class)

## Get mean by year and class

by(mpg_df, [:class, :year], hwy_mean = :hwy => mean ∘ skipmissing)

## Get counts of all combinations of class and year

by(mpg_df, [:class, :year], n = :class => length)

## Get scatterplot of highway mpg vs engine displacement

mpg_df |>
@vlplot(
    :circle,
    x = :displ,
    y = :hwy,
    width = 500,
    height = 500
)

## Get scatterplot of highway mpg vs engine displacement by fuel type

mpg_df |>
@vlplot(
    :circle,
    x = :displ,
    y = :hwy,
    color = :fl,
    width = 500,
    height = 500
)

## Get scatter plot by year as ordinal

mpg_df |>
@vlplot(
    :circle,
    x = :hwy,
    y = :cty,
    color = "cyl:o",
    width = 400,
    height = 400
)

## Get bar chart of class counts

mpg_df |> @vlplot(
    :bar,
    x = :class,
    y = "count()",
    height = 500,
    width = 500
)

## Get bar chart of class counts, stacked by year

mpg_df |> @vlplot(
    :bar,
    x = :class,
    y = "count()",
    color = "year:o",
    height = 500,
    width = 500
)

## Get bar chart of class counts, stacked by year and normalized

mpg_df |> @vlplot(
    :bar,
    x = :class,
    y = {"count()", stack = :normalize},
    color = "year:o",
    height = 500,
    width = 500
)

## A basic linear fit

mpg_lin_mod = fit(LinearModel, @formula(hwy ~ displ), mpg_df)
f(x) = coef(mpg_lin_mod)[1] + coef(mpg_lin_mod)[2] * x
DataFrame(A = 0:20, B = f.(0:20)) |>
@vlplot(:line, x = :A, y = :B)

## Faceted plots of hwy vs displ by year

mpg_df |>
@vlplot(
    :circle,
    x = :displ,
    y = :hwy,
    column = :cyl,
    width = 150,
    height = 150
)

## Histogram of highway mpg

mpg_df |>
@vlplot(:bar, x = {:hwy, bin = true}, y = "count()", width = 400, height = 400)

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

mpg_df = CSV.read("/Users/tristankindig/Google Drive/Data science/practice/julia_cookbook/data/mpg.csv", missingstrings = ["NA"])

##

mpg_df[!, :year] = Date.(mpg_df[:, :year])

##

mpg_lin_mod = fit(LinearModel, @formula(hwy ~ displ), mpg_df)
f(x) = coef(mpg_lin_mod)[1] + coef(mpg_lin_mod)[2] * x
plot(f, 2, 20)

mpg_df |>
@vlplot(
    :point,
    x = :displ,
    y = :hwy,
    color = :class,
    width = 400,
    height = 400
)

mpg_df |>
@vlplot(
    :point,
    x = :displ,
    y = :hwy,
    column = :cyl,
    width = 200,
    height = 200
)

mpg_df |>
@vlplot(
    :point,
    x = :hwy,
    y = :cty,
    color = :displ,
    width = 400,
    height = 400
)

##

mpg_df |>
@vlplot(
    :point,
    x = :hwy,
    y = :cty,
    color = "cyl:o",
    width = 400,
    height = 400
)

##

mpg_df |>
@vlplot(:bar, x = :class, y = "count()", width = 400, height = 400)

##

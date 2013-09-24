immutable Poisson <: DiscreteUnivariateDistribution
    lambda::Float64
    function Poisson(l::Real)
    	l > zero(l) || error("lambda must be positive")
        new(float64(l))
    end
    Poisson() = new(1.0)
end

insupport(::Poisson, x::Real) = isinteger(x) && zero(x) <= x
insupport(::Type{Poisson}, x::Real) = isinteger(x) && zero(x) <= x

isupperbounded(::Union(Poisson, Type{Poisson})) = false
islowerbounded(::Union(Poisson, Type{Poisson})) = true
isbounded(::Union(Poisson, Type{Poisson})) = false

min(::Union(Poisson, Type{Poisson})) = 0
max(::Union(Poisson, Type{Poisson})) = Inf



mean(d::Poisson) = d.lambda
mode(d::Poisson) = ifloor(d.lambda)
modes(d::Poisson) = [mode(d)]

var(d::Poisson) = d.lambda
skewness(d::Poisson) = 1.0 / sqrt(d.lambda)
kurtosis(d::Poisson) = 1.0 / d.lambda

function entropy(d::Poisson)
    λ = d.lambda
    if λ < 50.0
        s = 0.0
        for k in 1:100
            s += λ^k * lgamma(k + 1.0) / gamma(k + 1.0)
        end
        return λ * (1.0 - log(λ)) + exp(-λ) * s
    else
        return 0.5 * log(2 * pi * e * λ) -
               (1 / (12 * λ)) -
               (1 / (24 * λ * λ)) -
               (19 / (360 * λ * λ * λ))
    end
end


function pdf(d::Poisson, x::Real)
    if !insupport(d,x)
        return 0.0
    end
    if x == 0
        return exp(-d.lambda)
    end
    rcomp(x, d.lambda)/x
end

# Based on:
#   Catherine Loader (2000) "Fast and accurate computation of binomial probabilities"
#   available from:
#     http://projects.scipy.org/scipy/raw-attachment/ticket/620/loader2000Fast.pdf
# Uses slightly different forms instead of D0 function
function logpdf(d::Poisson, x::Real)
    if !insupport(d,x)
        return -Inf
    end
    if x == 0
        return -d.lambda
    end
    x*logmxp1(d.lambda/x)-lstirling(x)-0.5*(log2π+log(x))
end


cdf(d::Poisson, x::Real) = x<0 ? 0.0 : gratio(floor(x)+1.0, d.lambda)[2]
ccdf(d::Poisson, x::Real) = x<0 ? 1.0 : gratio(floor(x)+1.0, d.lambda)[1]


function mgf(d::Poisson, t::Real)
    l = d.lambda
    return exp(l * (exp(t) - 1.0))
end

function cf(d::Poisson, t::Real)
    l = d.lambda
    return exp(l * (exp(im * t) - 1.0))
end



# model fitting

immutable PoissonStats <: SufficientStats
    sx::Float64   # (weighted) sum of x
    tw::Float64   # total sample weight
end

suffstats(::Type{Poisson}, x::Array) = PoissonStats(float64(sum(x)), float64(length(x)))

function suffstats(::Type{Poisson}, x::Array, w::Array{Float64})
    n = length(x)
    n == length(w) || throw(ArgumentError("Inconsistent array lengths."))
    sx = 0.
    tw = 0.
    for i = 1 : n
        @inbounds wi = w[i]
        @inbounds sx += x[i] * wi
        tw += wi
    end
    PoissonStats(sx, tw)
end

fit_mle(::Type{Poisson}, ss::PoissonStats) = Poisson(ss.sx / ss.tw)


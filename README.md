# RationalRoots

[![Build Status](https://travis-ci.org/Jutho/RationalRoots.jl.svg?branch=master)](https://travis-ci.org/Jutho/RationalRoots.jl)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Coverage Status](https://coveralls.io/repos/Jutho/RationalRoots.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/Jutho/RationalRoots.jl?branch=master)
[![codecov.io](http://codecov.io/github/Jutho/RationalRoots.jl/coverage.svg?branch=master)](http://codecov.io/github/Jutho/RationalRoots.jl?branch=master)

This package provides a data type `RationalRoot{T<:Integer}` to exactly represent the (positive or negative) square root of a rational number of type `Rational{T}`.

## Basic usage

`RationalRoot`s can be created from any other real number type by using constructors or `convert`; if the input is not an integer or rational (i.e. a floating point number), the function `rationalize` from Julia Base is used to first approximate it by a rational number.

```julia
julia> RationalRoot(-2.5)
-√(25//4)

julia> convert(RationalRoot{Int16}, 7//2)
+√(49//4)

julia> RationalRoot{BigInt}(2)
+√(4//1)
```

Another way of creating a `RationalRoot` is using the `signedroot` function, which maps
a real number `x` to `sign(x)*sqrt(abs(x)) = x/sqrt(abs(x))`. If `x` is an `Integer` or
`Rational`, the result is represented as a `RationalRoot` type. For a floating point number,
`signedroot` will return a floating point number. A `RationalRoot` output can be forced by using `signedroot(<:RationalRoot, x)`, in which case `rationalize` is to rationalize the result.

```julia
julia> signedroot(3)
+√(3//1)

julia> signedroot(-4.0)
-2.0

julia> signedroot(RationalRoot, 5.2)
+√(26//5)

julia> signedroot(RationalRoot{Int8}, 8)
+√(8//1)
```

There is also the inverse function `signedsquare`, which maps a number `x` to `sign(x)*x^2 = x*abs(x)`.

```julia
julia> signedsquare(1.5)
2.25

julia> signedsquare(-2//3)
-4//9

julia> signedsquare(RationalRoot{BigInt}(1.5))
9//4

julia> typeof(ans)
Rational{BigInt}
```

The type `RationalRoot` will be maintained under multiplication and division with itself or with number of type `Integer` and `Rational`. Addition and subtraction require that the type is converted to a floating point number.

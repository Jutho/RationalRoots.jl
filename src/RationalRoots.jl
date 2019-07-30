module RationalRoots

export
    # Abstract types
    RationalRoot,

    # Functions
    signedroot,
    signedsquare

const IntOrRational{T} = Union{T,Rational{T}} where T<:Integer

"""
    RationalRoot{T} where {T<:Integer} <: AbstractIrrational

Type for representing the positive or negative square root of a positive `Rational{T}`.
"""
struct RationalRoot{T<:Integer} <: AbstractIrrational
    signedsquare::Rational{T}
    # Inner constructor that is only used to define signedroot(::Type{RationalRoot{T}}, x)
    RationalRoot{T}(::Val{:inner}, signedsquare) where T<:Integer = new(signedsquare)
end
RationalRoot{T}(x::Real) where T<:Integer = signedroot(RationalRoot{T}, signedsquare(x))
RationalRoot{T}(x::RationalRoot{T}) where T<:Integer = x

"""
    signedroot([R<:RationalRoot,] x)

Return `sign(x)*sqrt(abs(x)) == x/sqrt(abs(x))`. If the first argument is not present, this value is given as a floating point number if `x isa AbstractFloat`, and as a `RationalRoot` if `x isa Union{Integer,Rational}`. With the first argument present, the return type is specified as `RationalRoot` or a specific `RationalRoot{T}`, and for floating point numbers `x` the result will first be rationalized by `Base.rationalize{T}`.

# Examples

```jldoctest
julia> signedroot(3)
+√(3//1)

julia> signedroot(-4.0)
-2.0

julia> signedroot(RationalRoot, 5.2)
+√(26//5)

julia> signedroot(RationalRoot{Int8}, 8)
+√(8//1)
```
"""
signedroot(x::Real) = sign(x)*sqrt(abs(x))
signedroot(x::IntOrRational{T}) where {T<:Integer} = signedroot(RationalRoot{T}, x)
signedroot(::Type{RationalRoot}, x) = signedroot(RationalRoot, rationalize(x))
signedroot(::Type{RationalRoot}, x::T) where T<:Integer = signedroot(RationalRoot{T}, x)
signedroot(::Type{RationalRoot}, x::Rational{T}) where T<:Integer =
    signedroot(RationalRoot{T}, x)
signedroot(::Type{RationalRoot{T}}, x::AbstractFloat) where T<:Integer =
    signedroot(RationalRoot{T}, rationalize(T, x))
signedroot(::Type{RationalRoot{T}}, x) where T<:Integer = RationalRoot{T}(Val{:inner}(), x)

"""
    signedsquare(x)

Return `sign(x)*x*x = x*abs(x)`. If `x` is a `RationalRoot`, return an appropriate rational type.

```jldoctest
julia> signedsquare(-2)
-4

julia> signedsquare(4.0)
16.0

julia> signedsquare(-RationalRoot{Int}(3//2))
-9//4
```
"""
signedsquare(x) = x*abs(x)
signedsquare(x::RationalRoot) = x.signedsquare

Base.promote_rule(::Type{RationalRoot{T1}}, ::Type{T2}) where
    {T1<:Integer, T2<:Integer} = RationalRoot{promote_type(T1, T2)}
Base.promote_rule(::Type{RationalRoot{T1}}, ::Type{Rational{T2}}) where
    {T1<:Integer, T2<:Integer} = RationalRoot{promote_type(T1, T2)}
Base.promote_rule(::Type{RationalRoot{T1}}, ::Type{RationalRoot{T2}}) where
    {T1<:Integer, T2<:Integer} = RationalRoot{promote_type(T1, T2)}

RationalRoot(x::RationalRoot) = x
RationalRoot(x::Number) = signedroot(RationalRoot, signedsquare(x))

function Base.convert(T::Type{<:AbstractFloat}, x::RationalRoot)
    s = _convert(T, signedsquare(x))
    s < zero(s) ? -sqrt(-s) : sqrt(s)
end
function _convert(T::Type{<:Union{Float32,Float64}}, x::Rational{BigInt})
    n, d = numerator(x), denominator(x)
    if typemin(Int) <= n <= typemax(Int) && typemin(Int) <= d <= typemax(Int)
        # fast path, don't go via BigFloat
        convert(T, convert(Int, n)//convert(Int, d))
    else
        convert(T, x)
    end
end
_convert(T, x) = convert(T, x)

function Base.convert(T::Type{<:Integer}, x::RationalRoot)
    s = convert(Rational{T}, signedsquare(x))
    if denominator(s) == one(T)
        a = findsignedroot(numerator(s))
        if a !== nothing
            return a
        end
    end
    throw(InexactError(nameof(T), T, x))
end
function Base.convert(T::Type{<:Rational}, x::RationalRoot)
    s = convert(T, signedsquare(x))
    a = findsignedroot(s)
    if a !== nothing
        return a
    else
        throw(InexactError(nameof(T), T, x))
    end
end

Base.AbstractFloat(x::RationalRoot) = convert(AbstractFloat, x)
Base.Float32(x::RationalRoot) = convert(Float32, x)
Base.Float64(x::RationalRoot) = convert(Float64, x)
Base.BigFloat(x::RationalRoot) = convert(BigFloat, x)

function Base.hash(a::RationalRoot, h::UInt)
    s = signedsquare(a)
    x = findsignedroot(s)
    if x !== nothing
        return hash(x, h)
    else
        return hash(s, hash(s, h)) # something arbitrary
    end
end

for op in (:<, :≤, :(==))
    @eval Base.$op(x::RationalRoot, y::RationalRoot) = $op(signedsquare(x), signedsquare(y))
    @eval Base.$op(x::RationalRoot, y::Real) = $op(signedsquare(x), signedsquare(y))
    @eval Base.$op(x::Real, y::RationalRoot) = $op(signedsquare(x), signedsquare(y))
end

Base.:+(x::RationalRoot) = signedroot(+signedsquare(x))
Base.:-(x::RationalRoot) = signedroot(-signedsquare(x))
for op in (:*, :/, :\, ://)
    @eval Base.$op(x::RationalRoot, y::RationalRoot) =
        signedroot($op(signedsquare(x), signedsquare(y)))
    @eval Base.$op(x::RationalRoot, y::IntOrRational) =
        signedroot($op(signedsquare(x), signedsquare(y)))
    @eval Base.$op(x::IntOrRational, y::RationalRoot) =
        signedroot($op(signedsquare(x), signedsquare(y)))
end

Base.inv(x::RationalRoot) = signedroot(inv(signedsquare(x)))

Base.one(::Type{RationalRoot{T}}) where T<:Integer = signedroot(one(T))
Base.zero(::Type{RationalRoot{T}}) where T<:Integer = signedroot(zero(T))
Base.isone(x::RationalRoot) = isone(signedsquare(x))
Base.iszero(x::RationalRoot) = iszero(signedsquare(x))

Base.sign(x::RationalRoot) = sign(signedsquare(x))*one(x)

Base.big(x::RationalRoot) = convert(RationalRoot{BigInt}, x)

Base.widen(::Type{RationalRoot{T}}) where T<:Integer = RationalRoot{widen(T)}

Base.typemax(::Type{RationalRoot{T}}) where T<:Integer = signedroot(typemax(Rational{T}))
Base.typemin(::Type{RationalRoot{T}}) where T<:Integer = signedroot(typemin(Rational{T}))

function Base.show(io::IO, x::RationalRoot)
    signedsquare(x) < 0 ? print(io, "-√(") : print(io, "+√(")
    show(io, abs(signedsquare(x)))
    print(io, ")")
end

function findsignedroot(x::Integer)
    n = abs(x)
    k = isqrt(n)
    if k*k == n
        return sign(x)*k
    else
        return nothing
    end
end
function findsignedroot(x::Rational)
    n = findsignedroot(numerator(x))
    d = findsignedroot(denominator(x))
    if n === nothing || d === nothing
        return nothing
    else
        return n//d
    end
end

function Base.isinteger(x::RationalRoot)
    s = signedsquare(x)
    return isone(denominator(s)) && findsignedroot(numerator(s)) !== nothing
end

end

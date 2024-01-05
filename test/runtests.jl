using RationalRoots, Test, Aqua

bitstypes = (Int8, Int16, Int32, Int64, Int128)
inttypes = (bitstypes..., BigInt)
@testset "Constructor" begin
    r = rand(Float64)
    x = RationalRoot{Int}(Val{:inner}(), -3 // 5)
    for T in bitstypes
        @test (@inferred RationalRoot{T}(1)).signedsquare === Rational{T}(1)
        @test (@inferred RationalRoot{T}(-1)).signedsquare === Rational{T}(-1)
        @test (@inferred RationalRoot{T}(2)).signedsquare === Rational{T}(4)
        @test (@inferred RationalRoot{T}(-2)).signedsquare === Rational{T}(-4)
        @test (@inferred RationalRoot{T}(1 // 2)).signedsquare === Rational{T}(1 // 4)
        @test (@inferred RationalRoot{T}(-1 // 2)).signedsquare === Rational{T}(-1 // 4)
        @test (@inferred RationalRoot{T}(r)).signedsquare ===
              rationalize(T, signedsquare(r))
        @test (@inferred RationalRoot{T}(x)).signedsquare === Rational{T}(x.signedsquare)

        y = RationalRoot{T}(Val{:inner}(), 0.4)
        @test RationalRoot(y) === y
    end
    T = BigInt
    s = (@inferred RationalRoot{T}(1)).signedsquare
    @test s == convert(Rational{T}, 1) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(-1)).signedsquare
    @test s == convert(Rational{T}, -1) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(2)).signedsquare
    @test s == convert(Rational{T}, 4) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(-2)).signedsquare
    @test s == convert(Rational{T}, -4) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(1 // 2)).signedsquare
    @test s == convert(Rational{T}, 1 // 4) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(-1 // 2)).signedsquare
    @test s == convert(Rational{T}, -1 // 4) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(r)).signedsquare
    @test s == rationalize(T, signedsquare(r)) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(x)).signedsquare
    @test s == x.signedsquare && typeof(s) == Rational{T}

    y = RationalRoot{T}(Val{:inner}(), 0.4)
    @test RationalRoot(y) === y

    for T in (Float32, Float64, BigFloat)
        @test (@inferred RationalRoot(T(-1 // 4))).signedsquare === -1 // 16
    end

    for T in inttypes
        @test typeof(@inferred Rational(one(T))) == Rational{T}
    end
end

@testset "signedroot and signedsquare" begin
    for T in bitstypes
        @test (@inferred signedsquare(T(2))) === T(4)
        @test (@inferred signedroot(T(4))) === RationalRoot{T}(2)
        @test (@inferred signedsquare(Rational{T}(-2 // 3))) === Rational{T}(-4 // 9)
        @test (@inferred signedroot(Rational{T}(-4 // 9))) === RationalRoot{T}(-2 // 3)
    end
    @test (@inferred signedsquare(2.5)) === 6.25
    @test (@inferred signedroot(6.25)) === 2.5
    @test (@inferred signedroot(RationalRoot, 6.25)).signedsquare ===
          Rational{Int}(625 // 100)
    @test (@inferred signedsquare(-1.5f0)) === -2.25f0
    @test (@inferred signedroot(RationalRoot, -1.5f0)).signedsquare ===
          Rational{Int}(-15 // 10)
    @test (@inferred signedsquare(1 / big(3))) ≈ 1 / big(9)
end

@testset "algebra" begin
    for T in bitstypes
        a = -rand(T(1):T(5)) // rand(T(1):T(5))
        b = rand(T(1):T(5)) // rand(T(1):T(5))

        for op in (+, -, inv)
            @test (@inferred op(signedroot(a))) === signedroot(op(a))
        end

        for op in (*, /, \, //)
            @test (@inferred op(signedroot(a), signedroot(b))) === signedroot(op(a, b))
            @test (@inferred op(signedroot(a), b)) === signedroot(op(a, signedsquare(b)))
            @test (@inferred op(a, signedroot(b))) === signedroot(op(signedsquare(a), b))
        end

        @test (@inferred sign(signedroot(a))) === sign(a) * one(RationalRoot{T})

        x = signedroot(a)
        @test one(x) * x === x
        @test zero(x) === zero(typeof(x))
        @test one(x) === one(typeof(x))
        @test isone(one(x))
        @test !iszero(one(x))
        @test iszero(zero(x))
        @test !isone(zero(x))
        @test zero(x) * x === zero(x)
        @test x^2 === abs(a)
    end
end

@testset "conversion and promotion" begin
    for T in inttypes
        x = signedroot(T(1) // T(3))
        for T2 in inttypes
            @test promote_type(RationalRoot{T}, T2) == RationalRoot{promote_type(T, T2)}
            @test promote_type(RationalRoot{T}, Rational{T2}) ==
                  RationalRoot{promote_type(T, T2)}

            @test typeof(x * one(T2)) == RationalRoot{promote_type(T, T2)}
            @test typeof(x * one(Rational{T2})) == RationalRoot{promote_type(T, T2)}

            @test typeof(x + one(T2)) == Float64
            @test typeof(x - one(Rational{T2})) == Float64
        end
        for T2 in (Float32, Float64, BigFloat)
            @test promote_type(RationalRoot{T}, T2) == T2

            @test typeof(x + one(T2)) == T2
            @test typeof(x - one(T2)) == T2
            @test typeof(x * one(T2)) == T2
            @test typeof(x / one(T2)) == T2
        end
    end

    for T in inttypes
        @test isinteger(signedroot(T(-4)))
        @test !isinteger(signedroot(T(3)))
        @test signedroot(RationalRoot, T(4)) == 2
        @test signedroot(RationalRoot{T}, 4) == 2
        @test signedroot(RationalRoot{T}, -4 // 9) == -2 // 3

        h = rand(UInt)
        @test hash(signedroot(RationalRoot{T}, 4), h) == hash(2, h)
        @test hash(signedroot(RationalRoot{T}, -4 // 9), h) == hash(-2 // 3, h)
        @test hash(signedroot(1 // 3)) != hash(sqrt(1 / 3))

        @test typemax(RationalRoot{T}) == typemax(Rational{T})
        @test typemin(RationalRoot{T}) == typemin(Rational{T})
    end
    for T in (Float32, Float64, BigFloat)
        @test signedroot(RationalRoot, T(4.0)) == T(2.0)
        @test signedroot(RationalRoot, T(2.0)) ≈ sqrt(T(2.0))
        @test signedroot(RationalRoot, T(2.0)) != sqrt(T(2.0))
        @test signedroot(RationalRoot{BigInt}, one(T) / T(4.0)) == one(T) / T(2.0)
        @test signedroot(RationalRoot{BigInt}, -one(T) / T(3.0)) ≈ -sqrt(one(T) / T(3.0))
        @test signedroot(RationalRoot{BigInt}, one(T) / T(3.0)) != sqrt(one(T) / T(3.0))
    end

    for T in bitstypes
        @test convert(T, signedroot(4)) === T(2)
        @test convert(T, signedroot(T(4))) === T(2)
        @test_throws InexactError convert(T, signedroot(3))

        @test convert(Rational{T}, signedroot(4 // 9)) === Rational{T}(2 // 3)
        @test_throws InexactError convert(Rational{T}, signedroot(3 // 2))

        for T2 in (Float32, Float64, BigFloat)
            @test T2(signedroot(T(-2))) ≈ -sqrt(T2(T(2)))
        end
    end
    T = BigInt
    a = big(typemax(Int64))^2
    b = a + 1
    @test convert(T, signedroot(a)) == typemax(Int64)
    @test convert(Rational{T}, signedroot(a) // b) == typemax(Int64) // b
    for T in (Float32, Float64, BigFloat)
        @test T(signedroot(a) // b) ≈ T(typemax(Int64) / b)
    end

    x = big(signedroot(-4 // 9))
    @test x == -2 // 3 && typeof(signedsquare(x)) == Rational{BigInt}

    for T in (Int8, Int16, Int32, Int64)
        T2 = widen(T)
        @test widen(RationalRoot{T}) == RationalRoot{T2}
        @test widen(signedroot(T(3) // T(5))) === signedroot(T2(3) // T2(5))
    end
end

@testset "comparison" begin
    for T in inttypes
        @test RationalRoot{T}(3 // 4) <= 3 // 4
        @test RationalRoot{T}(3 // 4) <= 3 / 4
        @test 3 // 4 <= RationalRoot{T}(3 // 4)
        @test 3 / 4 <= RationalRoot{T}(3 // 4)
        @test 2 // 5 <= RationalRoot{T}(3 // 4) <= 4 // 5
        @test 4 // 5 >= RationalRoot{T}(3 // 4) >= 2 // 5
        @test 0 <= RationalRoot{T}(3 // 5) <= 1
        @test 1 >= RationalRoot{T}(3 // 5) >= 0
        @test 2 // 5 < RationalRoot{T}(3 // 5) < 4 // 5
        @test 4 // 5 > RationalRoot{T}(3 // 5) > 2 // 5
        @test 0 < RationalRoot{T}(3 // 5) < 1
        @test 1 > RationalRoot{T}(3 // 5) > 0
        @test -Inf < RationalRoot{T}(3 // 5) < Inf
        @test typemin(RationalRoot{T}) < RationalRoot{T}(3 // 5) < typemax(RationalRoot{T})
        @test typemin(Rational{T}) < RationalRoot{T}(3 // 5) < typemax(Rational{T})
        if isbitstype(T)
            @test typemin(T) < RationalRoot{T}(3 // 5) < typemax(T)
        end
    end
end

@testset "show" begin
    @test sprint(show, signedroot(+1 // 3)) == "+√(1//3)"
    @test sprint(show, signedroot(-2 // 5)) == "-√(2//5)"
end

@testset "Aqua" begin
    Aqua.test_all(RationalRoots)
end

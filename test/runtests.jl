using RationalRoots, Test

bitstypes  = (Int8, Int16, Int32, Int64, Int128)
inttypes = (bitstypes..., BigInt)
@testset "Constructor" begin
    r = rand(Float64)
    for T in bitstypes
        @test (@inferred RationalRoot{T}(1)).signedsquare === Rational{T}(1)
        @test (@inferred RationalRoot{T}(-1)).signedsquare === Rational{T}(-1)
        @test (@inferred RationalRoot{T}(2)).signedsquare === Rational{T}(4)
        @test (@inferred RationalRoot{T}(-2)).signedsquare === Rational{T}(-4)
        @test (@inferred RationalRoot{T}(1//2)).signedsquare === Rational{T}(1//4)
        @test (@inferred RationalRoot{T}(-1//2)).signedsquare === Rational{T}(-1//4)
        @test (@inferred RationalRoot{T}(r)).signedsquare ===
                                                rationalize(T, signedsquare(r))
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
    s = (@inferred RationalRoot{T}(1//2)).signedsquare
    @test s == convert(Rational{T}, 1//4) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(-1//2)).signedsquare
    @test s == convert(Rational{T}, -1//4) && typeof(s) == Rational{T}
    s = (@inferred RationalRoot{T}(r)).signedsquare
    @test s == rationalize(T, signedsquare(r)) && typeof(s) == Rational{T}

    for T in inttypes
        @test typeof(@inferred Rational(one(T))) == Rational{T}
    end
end

@testset "signedroot and signedsquare" begin
    for T in bitstypes
        @test (@inferred signedsquare(T(2))) === T(4)
        @test (@inferred signedroot(T(4))) === RationalRoot{T}(2)
        @test (@inferred signedsquare(Rational{T}(-2//3))) === Rational{T}(-4//9)
        @test (@inferred signedroot(Rational{T}(-4//9))) === RationalRoot{T}(-2//3)
    end
    @test (@inferred signedsquare(2.5)) === 6.25
    @test (@inferred signedroot(6.25)) === 2.5
    @test (@inferred signedroot(RationalRoot, 6.25)).signedsquare ===
        Rational{Int}(625//100)
    @test (@inferred signedsquare(-1.5f0)) === -2.25f0
    @test (@inferred signedroot(RationalRoot, -1.5f0)).signedsquare ===
        Rational{Int}(-15//10)
    @test (@inferred signedsquare(1/big(3))) ≈ 1/big(9)
end

@testset "algebra" begin
    for T in bitstypes
        a = rand(-T(5):T(5)) // rand(T(1):T(5))
        b = rand(-T(5):T(5)) // rand(T(1):T(5))

        for op in (+, -, inv)
            @test (@inferred op(signedroot(a))) === signedroot(op(a))
        end

        for op in (*, /, \, //)
            @test (@inferred op(signedroot(a),signedroot(b))) === signedroot(op(a,b))
            @test (@inferred op(signedroot(a),b)) === signedroot(op(a,signedsquare(b)))
            @test (@inferred op(a,signedroot(b))) === signedroot(op(signedsquare(a),b))
        end
    end
end

@testset "conversion and promotion" begin
    for T in inttypes
        @test isinteger(signedroot(T(-4)))
        @test !isinteger(signedroot(T(3)))
        @test signedroot(RationalRoot, T(4)) == 2
        @test signedroot(RationalRoot{T}, 4) == 2
        @test signedroot(RationalRoot{T}, -4//9) == -2//3

        h = rand(UInt)
        @test hash(signedroot(RationalRoot{T}, 4), h) == hash(2, h)
        @test hash(signedroot(RationalRoot{T}, -4//9), h) == hash(-2//3, h)
    end
    for T in (Float32, Float64, BigFloat)
        @test signedroot(RationalRoot, T(4.0)) == T(2.0)
        @test signedroot(RationalRoot, T(2.0)) ≈ sqrt(T(2.0))
        @test signedroot(RationalRoot, T(2.0)) != sqrt(T(2.0))
        @test signedroot(RationalRoot{BigInt}, one(T)/T(4.0)) == one(T)/T(2.0)
        @test signedroot(RationalRoot{BigInt}, -one(T)/T(3.0)) ≈ -sqrt(one(T)/T(3.0))
        @test signedroot(RationalRoot{BigInt}, one(T)/T(3.0)) != sqrt(one(T)/T(3.0))
    end

    for T in bitstypes
        @test convert(T, signedroot(4)) === T(2)
        @test convert(T, signedroot(T(4))) === T(2)
        @test_throws InexactError convert(T, signedroot(3))

        @test convert(Rational{T}, signedroot(4//9)) === Rational{T}(2//3)
        @test_throws InexactError convert(Rational{T}, signedroot(3//2))
    end

end

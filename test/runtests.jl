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
        a = rand(-T(8):T(8)) // rand(-T(8):T(8))
        b = rand(-T(8):T(8)) // rand(-T(8):T(8))
        @test (@inferred -signedroot(a)) === signedroot(-a)
        @test (@inferred inv(signedroot(a))) === signedroot(inv(a))
        @test (@inferred signedroot(a)*signedroot(b)) === signedroot(a*b)
        @test (@inferred signedroot(a)/signedroot(b)) === signedroot(a/b)
        @test (@inferred signedroot(a)\signedroot(b)) === signedroot(a\b)
        @test (@inferred signedroot(a)//signedroot(b)) === signedroot(a//b)
    end
end

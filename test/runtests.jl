module InboundsArraysTests

using InboundsArrays
using Test

using LinearAlgebra
using SparseArrays

# Import packages for extensions if possible
try
    using CairoMakie
catch
end
try
    using FFTW
catch
end
try
    using HDF5
catch
end
try
    using LsqFit
catch
end
try
    using MPI
catch
end
try
    using NCDatasets
catch
end
try
    using NaNMath
catch
end
try
    import StatsBase
catch
end

function isequal(args...)
    return isapprox(args...; rtol=0.0, atol=0.0)
end

function isclose(args...)
    return isapprox(args...; rtol=1.0e-14, atol=0.0)
end

function runtests()

    @testset "InboundsArrays" verbose=true begin
        @testset "InboundsVector" begin
            @test InboundsVector{Float64}(undef, 2) isa InboundsVector{Float64, Vector{Float64}}
            @test InboundsVector{Union{Float64, Missing}}(missing, 2) isa InboundsVector{Union{Float64, Missing}, Vector{Union{Float64, Missing}}}
            @test InboundsVector{Float64, Vector{Float64}}(undef, 2) isa InboundsVector{Float64, Vector{Float64}}
            @test InboundsVector{Union{Float64, Missing}, Vector{Union{Float64, Missing}}}(missing, 2) isa InboundsVector{Union{Float64, Missing}, Vector{Union{Float64, Missing}}}

            a = InboundsVector([1.0, 2.0, 3.0, 4.0])
            b = InboundsVector([5.0, 6.0, 7.0, 8.0])

            @test size(a) == (4,)
            @test length(a) == 4
            @test ndims(a) == 1
            @test eltype(a) == Float64
            @test a[2] == 2.0
            a[2] = 42.0
            @test a[2] == 42.0
            a[2] = 2.0

            for i ∈ 1:length(a)
                a[i] += b[i]
            end

            @test isequal(a, [6.0, 8.0, 10.0, 12.0])

            c = a .+ b
            @test c isa InboundsVector
            @test isequal(c, [11.0, 14.0, 17.0, 20.0])

            c .= a .* b
            @test c isa InboundsVector
            @test isequal(c, [30.0, 48.0, 70.0, 96.0])

            d = similar(a)
            @test d isa InboundsVector{Float64, Vector{Float64}}
            @test size(d) == (4,)

            d = similar(a, Int64)
            @test d isa InboundsVector{Int64, Vector{Int64}}
            @test size(d) == (4,)

            d = similar(a, (3, 5))
            @test d isa InboundsArray{Float64, 2, Array{Float64, 2}}
            @test size(d) == (3, 5)

            d = similar(a, Int64, (3, 5))
            @test d isa InboundsArray{Int64, 2, Array{Int64, 2}}
            @test size(d) == (3, 5)

            @test axes(a) == (1:4,)

            @test !isa(get_noninbounds(a), AbstractInboundsArray)
            @test !isa(get_noninbounds(zeros(3)), AbstractInboundsArray)

            @test a[1:3] isa InboundsVector{Float64, Vector{Float64}}

            a .= [6.0, 8.0, 10.0, 12.0]
            @test reverse(a) isa InboundsVector{Float64, Vector{Float64}}
            @test isequal(reverse(a), [12.0, 10.0, 8.0, 6.0])
            reverse!(a)
            @test a isa InboundsVector{Float64, Vector{Float64}}
            @test isequal(a, [12.0, 10.0, 8.0, 6.0])

            a .= [6.0, 8.0, 10.0, 12.0]
            b = push!(a, 14.0)
            @test a isa InboundsVector{Float64, Vector{Float64}}
            @test b isa InboundsVector{Float64, Vector{Float64}}
            @test isequal(a, [6.0, 8.0, 10.0, 12.0, 14.0])
            @test isequal(b, a)
            b = pop!(a)
            @test a isa InboundsVector{Float64, Vector{Float64}}
            @test isequal(a, [6.0, 8.0, 10.0, 12.0])
            @test b isa Float64
            @test b == 14.0

            a = InboundsVector([1.0, 2.0, 3.0, 4.0])
            b = InboundsVector([5.0, 6.0, 7.0, 8.0])
            c = vcat(a, b)
            @test c isa InboundsVector{Float64, Vector{Float64}}
            @test isequal(c, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])

            a = InboundsVector([1.0, 2.0, 3.0, 4.0])
            b = InboundsVector([5.0, 6.0, 7.0, 8.0])
            c = hcat(a, b)
            @test c isa InboundsMatrix{Float64, Matrix{Float64}}
            @test isequal(c, [1.0 5.0; 2.0 6.0; 3.0 7.0; 4.0 8.0])

            a = InboundsVector([1.0, 2.0, 3.0, 4.0])
            b = InboundsVector([5.0, 6.0, 7.0, 8.0])
            c = hvcat(1, a, b)
            @test c isa InboundsMatrix{Float64, Matrix{Float64}}
            @test isequal(c, [1.0; 2.0; 3.0; 4.0; 5.0; 6.0; 7.0; 8.0])

            a = InboundsVector([1.0, 2.0, 3.0, 4.0])
            r1 = repeat(a, 2)
            @test r1 isa InboundsVector{Float64, Vector{Float64}}
            @test isequal(r1, [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0])
            r1 = repeat(a, 2, 2)
            @test r1 isa InboundsMatrix{Float64, Matrix{Float64}}
            @test isequal(r1, [1.0 1.0; 2.0 2.0; 3.0 3.0; 4.0 4.0; 1.0 1.0; 2.0 2.0; 3.0 3.0; 4.0 4.0])

            a .= [1.0, 2.0, 3.0, 4.0]
            @test sum(a) == 10.0
            @test sum(a[1:3]) == 6.0
            @test sum(@view a[1:3]) == 6.0
            @test sum(a[1:0]) == 0.0
            @test sum(@view a[1:0]) == 0.0
            @test prod(a) == 24.0
            @test prod(a[1:3]) == 6.0
            @test prod(@view a[1:3]) == 6.0
            @test prod(a[1:0]) == 1.0
            @test prod(@view a[1:0]) == 1.0
            @test maximum(a) == 4.0
            @test maximum(a[1:3]) == 3.0
            @test maximum(@view a[1:3]) == 3.0
            @test minimum(a) == 1.0
            @test minimum(a[1:3]) == 1.0
            @test minimum(@view a[1:3]) == 1.0
            @test extrema(a) == (1.0, 4.0)
            @test extrema(a[1:3]) == (1.0, 3.0)
            @test extrema(@view a[1:3]) == (1.0, 3.0)
            b = InboundsVector([true, true, true, false])
            @test all(b) === false
            @test all(b[1:3]) === true
            @test all(@view b[1:3]) === true
            @test all(b[1:0]) === true
            @test all(@view b[1:0]) === true
            @test any(b) === true
            @test any(b[1:3]) === true
            @test any(@view b[1:3]) === true
            @test any(b[1:0]) === false
            @test any(@view b[1:0]) === false
            @test searchsorted(a, 2.0) == [2]
            @test searchsortedfirst(a, 2.0) == 2
            @test searchsortedlast(a, 2.0) == 2
            @test findfirst(InboundsArray([false, true, false, true])) == 2
            @test findfirst((x) -> x > 1.5, a) == 2
            @test findlast(InboundsArray([false, true, false, true])) == 4
            @test findlast((x) -> x > 1.5, a) == 4
            @test findnext(InboundsArray([false, true, false, true]), 3) == 4
            @test findnext((x) -> x > 1.5, a, 3) == 3
            @test findprev(InboundsArray([false, true, false, true]), 3) == 2
            @test findprev((x) -> x > 1.5, a, 3) == 3
        end

        @testset "InboundsMatrix" begin
            @test InboundsMatrix{Float64}(undef, 2, 3) isa InboundsMatrix{Float64, Matrix{Float64}}
            @test InboundsMatrix{Union{Float64, Missing}}(missing, 2, 3) isa InboundsMatrix{Union{Float64, Missing}, Matrix{Union{Float64, Missing}}}
            @test InboundsMatrix{Float64, Matrix{Float64}}(undef, 2, 3) isa InboundsMatrix{Float64, Matrix{Float64}}
            @test InboundsMatrix{Union{Float64, Missing}, Matrix{Union{Float64, Missing}}}(missing, 2, 3) isa InboundsMatrix{Union{Float64, Missing}, Matrix{Union{Float64, Missing}}}

            a = InboundsMatrix([1.0 2.0; 3.0 4.0])
            b = InboundsMatrix([5.0 6.0; 7.0 8.0])

            @test size(a) == (2, 2)
            @test length(a) == 4
            @test ndims(a) == 2
            @test eltype(a) == Float64
            @test a[1, 2] == 2.0
            a[1, 2] = 42.0
            @test a[1, 2] == 42.0
            a[1, 2] = 2.0

            for i ∈ 1:length(a)
                a[i] += b[i]
            end

            @test isequal(a, [6.0 8.0; 10.0 12.0])

            a .= [1.0 2.0; 3.0 4.0]

            for i ∈ 1:size(a, 2), j ∈ 1:size(a, 1)
                a[j, i] += b[j, i]
            end

            @test isequal(a, [6.0 8.0; 10.0 12.0])

            c = a .+ b
            @test c isa InboundsMatrix
            @test isequal(c, [11.0 14.0; 17.0 20.0])

            c .= a .* b
            @test c isa InboundsMatrix
            @test isequal(c, [30.0 48.0; 70.0 96.0])

            e = InboundsMatrix([1.0 2.0 3.0; 4.0 5.0 6.0])
            f = InboundsVector([10.0, 20.0])
            g = e .+ f
            @test g isa InboundsMatrix{Float64, Matrix{Float64}}
            @test size(g) == (2, 3)
            @test isequal(g, [11.0 12.0 13.0; 24.0 25.0 26.0])

            d = similar(a)
            @test d isa InboundsMatrix{Float64, Matrix{Float64}}
            @test size(d) == (2, 2)

            d = similar(a, Int64)
            @test d isa InboundsMatrix{Int64, Matrix{Int64}}
            @test size(d) == (2, 2)

            d = similar(a, (3, 5, 6))
            @test d isa InboundsArray{Float64, 3, Array{Float64, 3}}
            @test size(d) == (3, 5, 6)

            d = similar(a, Int64, (3, 5, 6))
            @test d isa InboundsArray{Int64, 3, Array{Int64, 3}}
            @test size(d) == (3, 5, 6)

            @test axes(a) == (1:2, 1:2)

            @test !isa(get_noninbounds(a), AbstractInboundsArray)
            @test !isa(get_noninbounds(zeros(3, 3)), AbstractInboundsArray)

            @test a[1:1, :] isa InboundsMatrix{Float64, Matrix{Float64}}
            @test a[:, 1:1] isa InboundsMatrix{Float64, Matrix{Float64}}

            a .= [1.0 2.0; 3.0 4.0]
            @test sum(a) == 10.0
            ia = inv(a)
            @test ia isa InboundsMatrix{Float64}
            @test isclose(ia, [4.0 -2.0; -3.0 1.0] ./ (-2.0))
            ta = transpose(a)
            @test ta isa InboundsMatrix{Float64}
            @test isequal(ta, [1.0 3.0; 2.0 4.0])
            ca = InboundsArray([(1.0 + 2.0im) (3.0 + 4.0im); (5.0 + 6.0im) (7.0 + 8.0im)])
            aca = adjoint(ca)
            @test aca isa InboundsMatrix{ComplexF64}
            @test isequal(aca, [(1.0 - 2.0im) (5.0 - 6.0im); (3.0 - 4.0im) (7.0 - 8.0im)])
        end

        @testset "InboundsArray" begin
            # Test constructors
            @test InboundsArray{Float64}(undef) isa InboundsArray{Float64, 0, Array{Float64, 0}}
            @test InboundsArray{Float64}(undef, 2) isa InboundsArray{Float64, 1, Array{Float64, 1}}
            @test InboundsArray{Float64}(undef, 2, 3) isa InboundsArray{Float64, 2, Array{Float64, 2}}
            @test InboundsArray{Union{Float64, Missing}}(missing) isa InboundsArray{Union{Float64, Missing}, 0, Array{Union{Float64, Missing}, 0}}
            @test InboundsArray{Union{Float64, Missing}}(missing, 2) isa InboundsArray{Union{Float64, Missing}, 1, Array{Union{Float64, Missing}, 1}}
            @test InboundsArray{Union{Float64, Missing}}(missing, 2, 3) isa InboundsArray{Union{Float64, Missing}, 2, Array{Union{Float64, Missing}, 2}}
            @test InboundsArray{Float64, 0}(undef) isa InboundsArray{Float64, 0, Array{Float64, 0}}
            @test InboundsArray{Float64, 1}(undef, 2) isa InboundsArray{Float64, 1, Array{Float64, 1}}
            @test InboundsArray{Float64, 2}(undef, 2, 3) isa InboundsArray{Float64, 2, Array{Float64, 2}}
            @test InboundsArray{Union{Float64, Missing}, 0}(missing) isa InboundsArray{Union{Float64, Missing}, 0, Array{Union{Float64, Missing}, 0}}
            @test InboundsArray{Union{Float64, Missing}, 1}(missing, 2) isa InboundsArray{Union{Float64, Missing}, 1, Array{Union{Float64, Missing}, 1}}
            @test InboundsArray{Union{Float64, Missing}, 2}(missing, 2, 3) isa InboundsArray{Union{Float64, Missing}, 2, Array{Union{Float64, Missing}, 2}}
            @test InboundsArray{Float64, 0, Array{Float64, 0}}(undef) isa InboundsArray{Float64, 0, Array{Float64, 0}}
            @test InboundsArray{Float64, 1, Array{Float64, 1}}(undef, 2) isa InboundsArray{Float64, 1, Array{Float64, 1}}
            @test InboundsArray{Float64, 2, Array{Float64, 2}}(undef, 2, 3) isa InboundsArray{Float64, 2, Array{Float64, 2}}
            @test InboundsArray{Union{Float64, Missing}, 0, Array{Union{Float64, Missing}, 0}}(missing) isa InboundsArray{Union{Float64, Missing}, 0, Array{Union{Float64, Missing}, 0}}
            @test InboundsArray{Union{Float64, Missing}, 1, Array{Union{Float64, Missing}, 1}}(missing, 2) isa InboundsArray{Union{Float64, Missing}, 1, Array{Union{Float64, Missing}, 1}}
            @test InboundsArray{Union{Float64, Missing}, 2, Array{Union{Float64, Missing}, 2}}(missing, 2, 3) isa InboundsArray{Union{Float64, Missing}, 2, Array{Union{Float64, Missing}, 2}}

            a = InboundsArray([1.0 2.0; 3.0 4.0;;; 1.0 2.0; 3.0 4.0])
            b = InboundsArray([5.0 6.0; 7.0 8.0;;; 5.0 6.0; 7.0 8.0])

            @test size(a) == (2, 2, 2)
            @test length(a) == 8
            @test ndims(a) == 3
            @test eltype(a) == Float64
            @test a[1, 2, 1] == 2.0
            a[1, 2, 1] = 42.0
            @test a[1, 2, 1] == 42.0
            a[1, 2, 1] = 2.0

            @test [1, 2, 3][InboundsArray([1, 2])] isa Vector{Int64}
            @test [1, 2, 3][InboundsArray([1, 2])] == [1, 2]
            @test [1, 2, 3][InboundsArray([1 2; 3 1])] isa Matrix{Int64}
            @test [1, 2, 3][InboundsArray([1 2; 3 1])] == [1 2; 3 1]
            @test InboundsArray([1, 2, 3])[InboundsArray([1, 2])] isa InboundsVector{Int64, Vector{Int64}}
            @test isequal(InboundsArray([1, 2, 3])[InboundsArray([1, 2])], [1, 2])
            @test InboundsArray([1, 2, 3])[InboundsArray([1 2; 3 1])] isa InboundsMatrix{Int64, Matrix{Int64}}
            @test isequal(InboundsArray([1, 2, 3])[InboundsArray([1 2; 3 1])], [1 2; 3 1])

            for i ∈ 1:length(a)
                a[i] += b[i]
            end

            @test isequal(a, [6.0 8.0; 10.0 12.0;;; 6.0 8.0; 10.0 12.0])

            a .= [1.0 2.0; 3.0 4.0;;; 1.0 2.0; 3.0 4.0]

            for i ∈ 1:size(a, 3), j ∈ 1:size(a, 2), k ∈ 1:size(a, 1)
                a[k, j, i] += b[k, j, i]
            end

            @test isequal(a, [6.0 8.0; 10.0 12.0;;; 6.0 8.0; 10.0 12.0])

            c = a .+ b
            @test c isa InboundsArray
            @test isequal(c, [11.0 14.0; 17.0 20.0;;; 11.0 14.0; 17.0 20.0])

            c .= a .* b
            @test c isa InboundsArray
            @test isequal(c, [30.0 48.0; 70.0 96.0;;; 30.0 48.0; 70.0 96.0])

            c = a .+ 2
            @test c isa InboundsArray
            @test isequal(c, [8.0 10.0; 12.0 14.0;;; 8.0 10.0; 12.0 14.0])

            c .= 0.0
            @. c = a + 2
            @test c isa InboundsArray
            @test isequal(c, [8.0 10.0; 12.0 14.0;;; 8.0 10.0; 12.0 14.0])

            c .= 0.0
            @. c[:, 1, 1] = a[:, 1, 1] + 2
            @test c isa InboundsArray
            @test isequal(c, [8.0 0.0; 12.0 0.0;;; 0.0 0.0; 0.0 0.0])

            d = similar(a)
            @test d isa InboundsArray{Float64, 3, Array{Float64, 3}}
            @test size(d) == (2, 2, 2)

            d = similar(a, Int64)
            @test d isa InboundsArray{Int64, 3, Array{Int64, 3}}
            @test size(d) == (2, 2, 2)

            d = similar(a, (3, 5))
            @test d isa InboundsArray{Float64, 2, Array{Float64, 2}}
            @test size(d) == (3, 5)

            d = similar(a, Int64, (3, 5))
            @test d isa InboundsArray{Int64, 2, Array{Int64, 2}}
            @test size(d) == (3, 5)

            @test axes(a) == (1:2, 1:2, 1:2)

            r = reshape(a, 4, 2)
            @test r isa InboundsArray
            @test size(r) == (4, 2)
            @test isequal(r, [6.0 6.0; 10.0 10.0; 8.0 8.0; 12.0 12.0])
            v = vec(a)
            @test v isa InboundsVector
            @test size(v) == (8,)
            @test isequal(v, [6.0, 10.0, 8.0, 12.0, 6.0, 10.0, 8.0, 12.0])
            s = selectdim(a, 3, 1)
            @test s isa InboundsArray
            @test size(s) == (2, 2)
            @test isequal(s, [6.0 8.0; 10.0 12.0])

            @test !isa(get_noninbounds(a), AbstractInboundsArray)
            @test !isa(get_noninbounds(zeros(3, 3, 3)), AbstractInboundsArray)

            @test a[1:1, :, :] isa InboundsArray{Float64, 3, Array{Float64, 3}}
            @test a[:, 1:1, :] isa InboundsArray{Float64, 3, Array{Float64, 3}}
            @test a[:, :, 1:1] isa InboundsArray{Float64, 3, Array{Float64, 3}}

            a .= [1.0 2.0; 3.0 4.0;;; 1.0 2.0; 3.0 4.0]
            @test sum(a) == 20.0
        end

        @testset "LinearAlgebra interface" begin
            A = InboundsArray([1.0 2.0; 3.0 4.0])
            B = InboundsArray([5.0 6.0; 7.0 8.0])
            C = InboundsArray([9.0 10.0; 11.0 12.0])
            x = InboundsArray([5.0, 7.0])
            y = InboundsArray([6.0, 8.0])

            mul!(y, A, x)
            @test isequal(y, [19.0, 43.0])
            @test y isa InboundsVector

            z = A * x
            @test isequal(z, [19.0, 43.0])
            @test z isa InboundsVector

            y .= [6.0, 8.0]
            mul!(y, A, x, 2.0, 3.0)
            @test isequal(y, [56.0, 110.0])
            @test y isa InboundsVector

            mul!(C, A, B)
            @test isequal(C, [19.0 22.0; 43.0 50.0])
            @test C isa InboundsMatrix

            D = A * B
            @test isequal(D, [19.0 22.0; 43.0 50.0])
            @test D isa InboundsMatrix

            C .= [9.0 10.0; 11.0 12.0]
            mul!(C, A, B, 2.0, 3.0)
            @test isequal(C, [65.0 74.0; 119.0 136.0])
            @test C isa InboundsMatrix

            Ax = InboundsArray([19.0, 43.0])
            Alu = lu(A)
            ldiv!(y, Alu, Ax)
            @test isclose(y, x)
            @test y isa InboundsVector

            z = Alu \ Ax
            @test isclose(z, x)
            @test z isa InboundsVector

            z = A \ Ax
            @test isclose(z, x)
            @test z isa InboundsVector

            AB = InboundsArray([19.0 22.0; 43.0 50.0])
            ldiv!(C, Alu, AB)
            @test isclose(C, B)
            @test C isa InboundsMatrix

            D = Alu \ AB
            @test isclose(D, B)
            @test D isa InboundsMatrix

            D = A \ AB
            @test isclose(D, B)
            @test D isa InboundsMatrix
        end

        @testset "SparseArrays interface" begin
            A = InboundsArray([1.0 2.0; 3.0 4.0])
            B = InboundsArray([5.0 6.0; 7.0 8.0])
            C = InboundsArray([9.0 10.0; 11.0 12.0])
            x = InboundsArray([5.0, 7.0])
            y = InboundsArray([6.0, 8.0])

            sA = sparse(A)
            @test isequal(A, sA)
            @test sA isa InboundsSparseMatrixCSC

            sB = sparse(A)
            @test isequal(A, sB)
            @test sB isa InboundsSparseMatrixCSC

            sC = sparse(InboundsVector([1, 2, 1, 2]), InboundsVector([1, 1, 2, 2]), vec(A))
            @test isequal(A, sC)
            @test sC isa InboundsSparseMatrixCSC

            mul!(y, sA, x)
            @test isequal(y, [19.0, 43.0])
            @test y isa InboundsVector

            z = sA * x
            @test isequal(z, [19.0, 43.0])
            @test z isa InboundsVector

            y .= [6.0, 8.0]
            mul!(y, sA, x, 2.0, 3.0)
            @test isequal(y, [56.0, 110.0])
            @test y isa InboundsVector

            mul!(C, sA, B)
            @test isequal(C, [19.0 22.0; 43.0 50.0])
            @test C isa InboundsMatrix

            D = sA * B
            @test isequal(D, [19.0 22.0; 43.0 50.0])
            @test D isa InboundsMatrix

            C .= [9.0 10.0; 11.0 12.0]
            mul!(C, sA, B, 2.0, 3.0)
            @test isequal(C, [65.0 74.0; 119.0 136.0])
            @test C isa InboundsMatrix

            Ax = InboundsArray([19.0, 43.0])
            sAlu = lu(sA)
            ldiv!(y, sAlu, Ax)
            @test isclose(y, x)
            @test y isa InboundsVector

            z = sAlu \ Ax
            @test isclose(z, x)
            @test z isa InboundsVector

            z = sA \ Ax
            @test isclose(z, x)
            @test z isa InboundsVector

            AB = InboundsArray([19.0 22.0; 43.0 50.0])
            ldiv!(C, sAlu, AB)
            @test isclose(C, B)
            @test C isa InboundsMatrix

            D = sAlu \ AB
            @test isclose(D, B)
            @test D isa InboundsMatrix

            D = sA \ AB
            @test isclose(D, B)
            @test D isa InboundsMatrix

            sB = sparse(B)
            sC = sparse(C)
            sx = sparse(x)
            sy = sparse(y)

            mul!(sy, sA, sx)
            @test isequal(sy, [19.0, 43.0])
            @test sy isa InboundsSparseVector

            z = sA * sx
            @test isequal(z, [19.0, 43.0])
            @test z isa InboundsSparseVector

            sy .= [6.0, 8.0]
            mul!(sy, sA, sx, 2.0, 3.0)
            @test isequal(sy, [56.0, 110.0])
            @test sy isa InboundsSparseVector

            mul!(sC, sA, sB)
            @test isequal(sC, [19.0 22.0; 43.0 50.0])
            @test sC isa InboundsSparseMatrixCSC

            D = sA * sB
            @test isequal(D, [19.0 22.0; 43.0 50.0])
            @test D isa InboundsSparseMatrixCSC

            sC .= [9.0 10.0; 11.0 12.0]
            mul!(sC, sA, sB, 2.0, 3.0)
            @test isequal(sC, [65.0 74.0; 119.0 136.0])
            @test sC isa InboundsSparseMatrixCSC
        end

        @testset "SparseMatricesCSR interface" begin
            A = InboundsArray([1.0 2.0; 3.0 4.0])
            B = InboundsArray([5.0 6.0; 7.0 8.0])
            C = InboundsArray([9.0 10.0; 11.0 12.0])
            x = InboundsArray([5.0, 7.0])
            y = InboundsArray([6.0, 8.0])

            sA = convert(InboundsSparseMatrixCSR{1, Float64, Int64}, A)
            @test isequal(A, sA)
            @test sA isa InboundsSparseMatrixCSR

            mul!(y, sA, x)
            @test isequal(y, [19.0, 43.0])
            @test y isa InboundsVector

            z = sA * x
            @test isequal(z, [19.0, 43.0])
            @test z isa InboundsVector

            y .= [6.0, 8.0]
            mul!(y, sA, x, 2.0, 3.0)
            @test isequal(y, [56.0, 110.0])
            @test y isa InboundsVector

            mul!(C, sA, B)
            @test isequal(C, [19.0 22.0; 43.0 50.0])
            @test C isa InboundsMatrix

            D = sA * B
            @test isequal(D, [19.0 22.0; 43.0 50.0])
            @test D isa InboundsMatrix

            C .= [9.0 10.0; 11.0 12.0]
            mul!(C, sA, B, 2.0, 3.0)
            @test isequal(C, [65.0 74.0; 119.0 136.0])
            @test C isa InboundsMatrix

            Ax = InboundsArray([19.0, 43.0])
            sAlu = lu(sA)
            ldiv!(y, sAlu, Ax)
            @test isclose(y, x)
            @test y isa InboundsVector

            z = sAlu \ Ax
            @test isclose(z, x)
            @test z isa InboundsVector

            z = sA \ Ax
            @test isclose(z, x)
            @test z isa InboundsVector

            AB = InboundsArray([19.0 22.0; 43.0 50.0])
            ldiv!(C, sAlu, AB)
            @test isclose(C, B)
            @test C isa InboundsMatrix

            D = sAlu \ AB
            @test isclose(D, B)
            @test D isa InboundsMatrix

            D = sA \ AB
            @test isclose(D, B)
            @test D isa InboundsMatrix

            sB = convert(InboundsSparseMatrixCSR{1, Float64, Int64}, B)
            sC = convert(InboundsSparseMatrixCSR{1, Float64, Int64}, C)
            sx = sparse(x)
            sy = sparse(y)

            mul!(sy, sA, sx)
            @test isequal(sy, [19.0, 43.0])
            @test sy isa InboundsSparseVector

            z = sA * sx
            @test isequal(z, [19.0, 43.0])
            @test z isa InboundsSparseVector

            sy .= [6.0, 8.0]
            mul!(sy, sA, sx, 2.0, 3.0)
            @test isequal(sy, [56.0, 110.0])
            @test sy isa InboundsSparseVector

            mul!(sC, sA, sB)
            @test isequal(sC, [19.0 22.0; 43.0 50.0])
            @test sC isa InboundsSparseMatrixCSR

            D = sA * sB
            @test isequal(D, [19.0 22.0; 43.0 50.0])
            # For some reason a SparseMatrixCSR multiplied by SparseMatrixCSR returns a
            # Matrix, so we do the same with the Inbounds versions, and so D should be a
            # Matrix.
            @test sA.parent * sB.parent isa Matrix
            @test D isa Matrix

            sC .= [9.0 10.0; 11.0 12.0]
            mul!(sC, sA, sB, 2.0, 3.0)
            @test isequal(sC, [65.0 74.0; 119.0 136.0])
            @test sC isa InboundsSparseMatrixCSR
        end

        if @isdefined FFTW
            @testset "FFTWExt" begin
                a = InboundsArray(ones(Complex{Float64}, 8))

                forward_transform = plan_fft!(a, flags=FFTW.ESTIMATE)
                backward_transform = plan_ifft!(a, flags=FFTW.ESTIMATE)

                @. a = sin(2.0 * π * (0.0:7.0) / 8)
                a_fft = forward_transform * copy(a)
                @test a_fft isa InboundsVector
                a_reconstructed = backward_transform * a_fft
                @test a_reconstructed isa InboundsVector
                @test isclose(a_reconstructed, a)

                b = InboundsArray(ones(8))
                r2r = FFTW.plan_r2r!(b, FFTW.REDFT00)

                @. b = cos(π * (0.0:7.0) / 7)
                b_fft = r2r * copy(b)
                @test b_fft isa InboundsVector
                @test isclose(b_fft, [0.0, 7.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
            end
        end

        if @isdefined HDF5
            @testset "HDF5Ext" begin
                v = InboundsArray(ones(3))
                m = InboundsArray(ones(3, 4))
                a = InboundsArray(ones(3, 4, 5))

                testdir = tempname()
                mkpath(testdir)

                filename = joinpath(testdir, "test.h5")

                f = h5open(filename, "cw")
                f["v"] = v
                @test isequal(f["v"][:], ones(3))
                f["m"] = m
                @test isequal(f["m"][:, :], ones(3, 4))
                f["a"] = a
                @test isequal(f["a"][:, :, :], ones(3, 4, 5))

                v_io = create_dataset(f, "v2", Float64, (3,))
                v_io = v
                @test isequal(v_io[:], ones(3))
                m_io = create_dataset(f, "m2", Float64, (3, 4))
                m_io = m
                @test isequal(m_io[:, :], ones(3, 4))
                a_io = create_dataset(f, "a2", Float64, (3, 4, 5))
                a_io = a
                @test isequal(a_io[:, :, :], ones(3, 4, 5))

                v_io = create_dataset(f, "v3", Float64, (3,))
                v_io[1:3] = @view v[1:3]
                @test isequal(v_io[:], ones(3))
                m_io = create_dataset(f, "m3", Float64, (3, 4))
                m_io[1:3, 1:4] = @view m[1:3, 1:4]
                @test isequal(m_io[:, :], ones(3, 4))
                a_io = create_dataset(f, "a3", Float64, (3, 4, 5))
                a_io[1:3, 1:4, 1:5] = @view a[1:3, 1:4, 1:5]
                @test isequal(a_io[:, :, :], ones(3, 4, 5))

                v_io = create_dataset(f, "v4", Float64, (3, 2))
                v_io[:, 1] = v
                v_io[:, 2] = v
                @test isequal(v_io[:, :], ones(3, 2))
                m_io = create_dataset(f, "m4", Float64, (3, 4, 2))
                m_io[:, :, 1] = m
                m_io[:, :, 2] = m
                @test isequal(m_io[:, :, :], ones(3, 4, 2))
                a_io = create_dataset(f, "a4", Float64, (3, 4, 5, 2))
                a_io[:, :, :, 1] = a
                a_io[:, :, :, 2] = a
                @test isequal(a_io[:, :, :, :], ones(3, 4, 5, 2))

                close(f)
            end
        end

        if @isdefined NCDatasets
            @testset "NCDatasetsExt" begin
                v = InboundsArray(ones(3))
                m = InboundsArray(ones(3, 4))
                a = InboundsArray(ones(3, 4, 5))

                testdir = tempname()
                mkpath(testdir)

                filename = joinpath(testdir, "test.h5")

                f = NCDataset(filename, "c")
                defDim(f, "x", 3)
                defDim(f, "y", 4)
                defDim(f, "z", 5)
                defDim(f, "t", 2)

                v_io = defVar(f, "v2", Float64, ("x",))
                v_io = v
                @test isequal(v_io[:], ones(3))
                m_io = defVar(f, "m2", Float64, ("x", "y"))
                m_io = m
                @test isequal(m_io[:, :], ones(3, 4))
                a_io = defVar(f, "a2", Float64, ("x", "y", "z"))
                a_io = a
                @test isequal(a_io[:, :, :], ones(3, 4, 5))

                v_io = defVar(f, "v3", Float64, ("x",))
                v_io[1:3] = @view v[1:3]
                @test isequal(v_io[:], ones(3))
                m_io = defVar(f, "m3", Float64, ("x", "y"))
                m_io[1:3, 1:4] = @view m[1:3, 1:4]
                @test isequal(m_io[:, :], ones(3, 4))
                a_io = defVar(f, "a3", Float64, ("x", "y", "z"))
                a_io[1:3, 1:4, 1:5] = @view a[1:3, 1:4, 1:5]
                @test isequal(a_io[:, :, :], ones(3, 4, 5))

                v_io = defVar(f, "v4", Float64, ("x", "t"))
                v_io[:, 1] = v
                v_io[:, 2] = v
                @test isequal(v_io[:, :], ones(3, 2))
                m_io = defVar(f, "m4", Float64, ("x", "y", "t"))
                m_io[:, :, 1] = m
                m_io[:, :, 2] = m
                @test isequal(m_io[:, :, :], ones(3, 4, 2))
                a_io = defVar(f, "a4", Float64, ("x", "y", "z", "t"))
                a_io[:, :, :, 1] = a
                a_io[:, :, :, 2] = a
                @test isequal(a_io[:, :, :, :], ones(3, 4, 5, 2))

                close(f)
            end
        end

        if @isdefined LsqFit
            @testset "LsqFitExt" begin
                # Based on the example in the curve_fit() docstring, and LsqFit.jl
                # tutorial
                model(x, p) = @. p[1]*exp(-x*p[2])
                function j_m(t,p)
                    J = Array{Float64}(undef, length(t),length(p))
                    J[:,1] = exp.(p[2] .* t)       #df/dp[1]
                    J[:,2] = t .* p[1] .* J[:,1]   #df/dp[2]
                    J
                end
                xdata = InboundsArray(range(0, stop=10, length=20))
                ydata = model(xdata, [1.0 2.0]) .+ 0.01.*range(0, stop=1, length=length(xdata))
                p0 = InboundsArray([0.5, 0.5])
                wt = InboundsArray(fill(0.5, 20,20))
                for i ∈ 1:20
                    wt[i,i] = 1.0
                end

                @test curve_fit(model, xdata, ydata, p0) isa Any
                @test curve_fit(model, xdata, ydata, wt, p0) isa Any
                @test curve_fit(model, j_m, xdata, ydata, p0) isa Any
                @test curve_fit(model, j_m, xdata, ydata, wt, p0) isa Any
            end
        end

        if @isdefined CairoMakie
            @testset "MakieExt" begin
                a = InboundsArray([1.0, 2.0, 3.0])

                fig, ax, l = lines(a)
                @test fig isa Figure
            end
        end

        if @isdefined MPI
            @testset "MPIExt" begin
                a = InboundsArray(ones(3, 4, 5))
                b = similar(a)

                MPI.Init()

                MPI.Allgather!(a, b, MPI.COMM_WORLD)
                @test isequal(b, ones(3, 4, 5))

                b .= 0.0
                vb = MPI.VBuffer(b, [3 * 4 * 5])
                MPI.Allgatherv!(a, vb, MPI.COMM_WORLD)
                @test isequal(b, ones(3, 4, 5))

                b .= 0.0
                vb = MPI.VBuffer(b, InboundsVector([3 * 4 * 5]))
                MPI.Allgatherv!(a, vb, MPI.COMM_WORLD)
                @test isequal(b, ones(3, 4, 5))

                b .= 0.0
                MPI.Bcast!(a, 0, MPI.COMM_WORLD)
                @test isequal(a, ones(3, 4, 5))
            end
        end

        if @isdefined NaNMath
            nanmathext = Base.get_extension(InboundsArrays, :NaNMathExt)
            @testset "NaNMathExt" begin
                a = InboundsArray([1.0, 2.0, 3.0])

                for funcname ∈ nanmathext.oneargfuncs
                    result = eval(:(NaNMath.$funcname($a)))
                    @test result isa Union{Number, Tuple, AbstractInboundsArray}
                end
            end
        end

        if @isdefined StatsBase
            statsbaseext = Base.get_extension(InboundsArrays, :StatsBaseExt)
            @testset "StatsBaseExt" begin
                a = InboundsArray([1.0, 2.0, 3.0])
                b = InboundsArray([4.0, 5.0, 6.0])
                c = InboundsArray([7.0, 8.0, 9.0])
                d = InboundsArray([10.0, 11.0, 12.0])
                mat = InboundsArray([1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0])
                identitymat = InboundsArray([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])
                ints = InboundsArray([1, 2, 3])

                for funcname ∈ statsbaseext.oneargfuncs
                    a .= InboundsArray([1.0, 2.0, 3.0])
                    b .= InboundsArray([4.0, 5.0, 6.0])
                    c .= InboundsArray([7.0, 8.0, 9.0])
                    d .= InboundsArray([10.0, 11.0, 12.0])
                    mat .= InboundsArray([1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0])
                    identitymat .= InboundsArray([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])
                    ints .= InboundsArray([1, 2, 3])
                    arg1 = a
                    args = ()
                    if funcname ∈ (:corkendall, :corspearman, :cov2cor)
                        arg1 = mat
                    elseif funcname ∈ (:cronbachalpha,)
                        arg1 = identitymat
                    elseif funcname ∈ (:counts, :proportions)
                        arg1 = ints
                    elseif funcname ∈ (:countties, :insertion_sort!, :merge_sort!, :zscore!)
                        args = (1, 2)
                    elseif funcname ∈ (:cumulant, :histrange, :moment, :renyientropy)
                        args = (1,)
                    elseif funcname ∈ (:eweights,)
                        args = (1:4, 0.5)
                    elseif funcname ∈ (:quantile, :quantile!)
                        args = ((0.5,),)
                    elseif funcname ∈ (:wmedian,)
                        args = (StatsBase.Weights([0.4, 0.5, 0.6]),)
                    elseif funcname ∈ (:wquantile,)
                        args = (StatsBase.Weights([0.4, 0.5, 0.6]), 0.5)
                    elseif funcname ∈ (:wsum,)
                        args = (StatsBase.Weights([0.4, 0.5, 0.6]), :)
                    end
                    result = eval(:(StatsBase.$funcname($arg1, $args...)))
                    @test result isa Union{Number, Tuple, Dict, AbstractInboundsArray, StatsBase.CronbachAlpha, StatsBase.ECDF, StatsBase.SummaryStats, Base.Generator}
                end

                for funcname ∈ statsbaseext.twoargfuncs
                    a .= InboundsArray([1.0, 2.0, 3.0])
                    b .= InboundsArray([4.0, 5.0, 6.0])
                    c .= InboundsArray([7.0, 8.0, 9.0])
                    d .= InboundsArray([10.0, 11.0, 12.0])
                    mat .= InboundsArray([1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0])
                    identitymat .= InboundsArray([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])
                    ints .= InboundsArray([1, 2, 3])
                    arg1 = a
                    arg2 = b
                    args = ()
                    if funcname ∈ (:addcounts!,)
                        arg2 = ints
                        args = (1:2,)
                    elseif funcname ∈ (:autocor, :autocov)
                        arg2 = ints .- 1
                    elseif funcname ∈ (:cor2cov, :cor2cov!, :cov2cor)
                        arg1 = mat
                    elseif funcname ∈ (:counts, :proportions)
                        arg1 = ints
                        arg2 = copy(ints)
                    elseif funcname ∈ (:demean_col!,)
                        arg2 = mat
                        args = (1, true)
                    elseif funcname ∈ (:indicatormat,)
                        arg2 = a
                    elseif funcname ∈ (:inverse_rle,)
                        arg2 = ints
                    elseif funcname ∈ (:pacf,)
                        arg2 = InboundsArray([0, 1])
                    elseif funcname ∈ (:psnr, :wquantile)
                        args = (1.0,)
                    elseif funcname ∈ (:quantile!,)
                        arg2 = b ./ c
                    elseif funcname ∈ (:var!,)
                        args = (StatsBase.Weights([0.4, 0.5, 0.6]), 1)
                    elseif funcname ∈ (:zscore!,)
                        args = (1.0, 2.0)
                    end
                    result = eval(:(StatsBase.$funcname($arg1, $arg2, $args...)))
                    @test result isa Union{Number, Tuple, Dict, AbstractInboundsArray}
                end

                for funcname ∈ statsbaseext.threeargfuncs
                    a .= InboundsArray([1.0, 2.0, 3.0])
                    b .= InboundsArray([4.0, 5.0, 6.0])
                    c .= InboundsArray([7.0, 8.0, 9.0])
                    d .= InboundsArray([10.0, 11.0, 12.0])
                    mat .= InboundsArray([1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0])
                    identitymat .= InboundsArray([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])
                    ints .= InboundsArray([1, 2, 3])
                    arg1 = a
                    arg2 = b
                    arg3 = c
                    args = ()
                    if funcname ∈ (:addcounts!,)
                        arg1 = mat
                        arg2 = ints
                        arg3 = copy(ints)
                        args = ((1:2, 1:2),)
                    elseif funcname ∈ (:autocor!, :autocov!, :crosscor, :crosscov)
                        arg3 = ints .- 1
                    elseif funcname ∈ (:corkendall!,)
                        arg3 = ints
                    elseif funcname ∈ (:pacf!,)
                        arg1 = mat
                        arg2 = copy(mat)
                        arg3 = InboundsArray(ones(Int64, 3))
                    elseif funcname ∈ (:pacf_regress!, :pacf_yulewalker!)
                        arg1 = mat
                        arg2 = copy(mat)
                        arg3 = InboundsArray(zeros(Int64, 3))
                        args = (1,)
                    elseif funcname ∈ (:quantile!,)
                        arg3 = c ./ d
                    elseif funcname ∈ (:wsum!,)
                        args = (1,)
                    end
                    result = eval(:(StatsBase.$funcname($arg1, $arg2, $arg3, $args...)))
                    @test result isa Union{Nothing, Number, Tuple, AbstractInboundsArray}
                end

                for funcname ∈ statsbaseext.fourargfuncs
                    a .= InboundsArray([1.0, 2.0, 3.0])
                    b .= InboundsArray([4.0, 5.0, 6.0])
                    c .= InboundsArray([7.0, 8.0, 9.0])
                    d .= InboundsArray([10.0, 11.0, 12.0])
                    mat .= InboundsArray([1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0])
                    identitymat .= InboundsArray([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])
                    ints .= InboundsArray([1, 2, 3])
                    arg1 = a
                    arg2 = b
                    arg3 = c
                    arg4 = d
                    args = ()
                    if funcname ∈ (:crosscor!, :crosscov!)
                        arg4 = ints .- 1
                    end
                    result = eval(:(StatsBase.$funcname($arg1, $arg2, $arg3, $arg4, $args...)))
                    @test result isa Union{Number, Tuple, AbstractInboundsArray}
                end
            end
        end
    end
end

end # module InboundsArraysTests

using .InboundsArraysTests
InboundsArraysTests.runtests()

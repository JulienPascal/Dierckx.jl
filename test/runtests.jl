#!/usr/bin/env julia
using Dierckx
using Compat
using Base.Test

# Answers 'ans' are from scipy.interpolate,
# generated with genanswers.py script.

# -----------------------------------------------------------------------------
# Spline1D

x = [1., 2., 3.]
y = [0., 2., 4.]
spl = Spline1D(x, y; k=1, s=length(x))

yi = evaluate(spl, [1.0, 1.5, 2.0])
@test yi ≈ [0.0, 1.0, 2.0]
@test evaluate(spl, 1.5) ≈ 1.0
@test get_knots(spl) ≈ [1., 3.]
@test get_coeffs(spl) ≈ [0., 4.]
@test isapprox(get_residual(spl), 0.0, atol=1.e-30)

@test spl([1.0, 1.5, 2.0]) ≈ [0.0, 1.0, 2.0]
@test spl(1.5) ≈ 1.0

# test that a copy is returned by get_knots()
knots = get_knots(spl)
knots[1] = 1000.
@test get_knots(spl) ≈ [1., 3.]

# test ported from scipy.interpolate testing this bug:
# http://mail.scipy.org/pipermail/scipy-dev/2008-March/008507.html
x = [-1., -0.65016502, -0.58856235, -0.26903553, -0.17370892,
     -0.10011001, 0., 0.10011001, 0.17370892, 0.26903553, 0.58856235,
     0.65016502, 1.]
y = [1.,0.62928599, 0.5797223, 0.39965815, 0.36322694, 0.3508061,
     0.35214793, 0.3508061, 0.36322694, 0.39965815, 0.5797223,
     0.62928599, 1.]
w = [1.00000000e+12, 6.88875973e+02, 4.89314737e+02, 4.26864807e+02,
     6.07746770e+02, 4.51341444e+02, 3.17480210e+02, 4.51341444e+02,
     6.07746770e+02, 4.26864807e+02, 4.89314737e+02, 6.88875973e+02,
     1.00000000e+12]
spl = Spline1D(x, y; w=w, s=@compat(Float64(length(x))))
desired = [0.35100374, 0.51715855, 0.87789547, 0.98719344]
actual = evaluate(spl, [0.1, 0.5, 0.9, 0.99])
@test isapprox(actual, desired, atol=5e-4)

# tests for out-of-range
x = [0.0:4.0;]
y = x.^3

xp = linspace(-8.0, 13.0, 100)
xp_zeros = Float64[(0. <= xi <= 4.) ? xi : 0.0 for xi in xp]
xp_clip = Float64[(0. <= xi <= 4.) ? xi : (xi<0.0)? 0.0 : 4. for xi in xp]

spl = Spline1D(x, y)
t = get_knots(spl)[2: end-1]  # knots, excluding those at endpoints
spl2 = Spline1D(x, y, t)

@test evaluate(spl, xp) ≈ xp_clip.^3
@test evaluate(spl2, xp) ≈ xp_clip.^3

# test other bc's
spl = Spline1D(x, y; bc="extrapolate")
@test evaluate(spl, xp) ≈ xp.^3
spl = Spline1D(x, y; bc="zero")
@test evaluate(spl, xp) ≈ xp_zeros.^3
spl = Spline1D(x, y; bc="error")
@test_throws ErrorException evaluate(spl, xp)

# test unknown bc
@test_throws ErrorException Spline1D(x, y; bc="unknown")

# test derivative
x = linspace(0, 1, 70)
y = x.^3
spl = Spline1D(x, y)
xt = [0.3, 0.4, 0.5]
@test derivative(spl, xt) ≈ 3xt.^2

# test integral
x = linspace(0, 10, 70)
y = x.^2
spl = Spline1D(x, y)
@test integrate(spl, 1.0, 5.0) ≈ 5.^3/3 - 1/3

# test roots
x = linspace(0, 10, 70)
y = (x-4).^2-1
spl = Spline1D(x, y)
@test roots(spl) ≈ [3, 5]


# -----------------------------------------------------------------------------
# Spline2D

# test linear
x = [1., 1., 1., 2., 2., 2., 3., 3., 3.]
y = [1., 2., 3., 1., 2., 3., 1., 2., 3.]
z = [0., 0., 0., 2., 2., 2., 4., 4., 4.]
spl = Spline2D(x, y, z; kx=1, ky=1, s=length(x))
tx, ty = get_knots(spl)
@test tx ≈ [1., 3.]
@test ty ≈ [1., 3.]
@test isapprox(get_residual(spl), 0.0, atol=1e-16)
@test evaluate(spl, 2.0, 1.5) ≈ 2.0
@test evalgrid(spl, [1.,1.5,2.], [1.,1.5]) ≈ [0. 0.; 1. 1.; 2. 2.]

# test 1-d grid arrays
@test evalgrid(spl, [2.0], [1.5])[1, 1] ≈ 2.0

# In this setting, lwrk2 is too small in the default run.
x = linspace(-2, 2, 80)
y = linspace(-2, 2, 80)
z = x .+ y
spl = Spline2D(x, y, z; s=length(x))
@test evaluate(spl, 1.0, 1.0) ≈ 2.0

# In this setting lwrk2 is too small multiple times!
# Eventually an error about s being too small is thrown.
srand(0)
x = rand(100)
y = rand(100)
z = @compat sin.(x) .* sin.(y)
@test_throws ErrorException Spline2D(x, y, z; kx=1, ky=1, s=0.0)

# test grid input creation
x = [0.5, 2., 3., 4., 5.5, 8.]
y = [0.5, 2., 3., 4.]
z = [1. 2. 1. 2.;  # shape is (nx, ny)
     1. 2. 1. 2.;
     1. 2. 3. 2.;
     1. 2. 2. 2.;
     1. 2. 1. 2.;
     1. 2. 3. 1.]
spl = Spline2D(x, y, z)

# element-wise output
xi = [1., 1.5, 2.3, 4.5, 3.3, 3.2, 3.]
yi = [1., 2.3, 5.3, 0.5, 3.3, 1.2, 3.]
ans = [2.94429906542,
       1.25537598131,
       2.00063588785,
       1.0,
       2.93952664,
       1.06482509358,
       3.0]
zi = evaluate(spl, xi, yi)
@test zi ≈ ans

zi = spl(xi, yi)
@test zi ≈ ans

# grid output
xi = [1., 1.5, 2.3, 4.5]
yi = [1., 2.3, 5.3]
ans = [2.94429906542  1.16946130841  1.99831775701;
       2.80393858478  1.25537598131  1.99873831776;
       1.67143209613  1.94853338542  2.00063588785;
       1.89392523364  1.8126946729  2.01042056075]
zi = evalgrid(spl, xi, yi)
@test zi ≈ ans

# -----------------------------------------------------------------------------
# Test 2-d integration

f_test = [] #initialize an empyt list to store the functions to test

# Functions to test
function test2d_1(x::Float64, y::Float64)
  1 - x^2 -y^2
end

function test2d_2(x::Float64, y::Float64)
  cos(x) + sin(y)
end

function test2d_3(x::Float64, y::Float64)
  x*exp(x-y)
end

f_test = [test2d_1, test2d_2, test2d_3]

# Store the domains of integration 
range_2d_integration = [(0, 1, 0, 1); (0, pi, 0, pi); (0, 1, 0, 1)] 
# i.e. integrate on [0, 1]*[0,1] for test2d_1
#      integrate on [0, pi]*[0,pi] for test2d_2
#      integrate on [0, 1]*[0,1] for test2d_3

# True value of the integrals
true_value = collect([1/3; 2*pi; (e-1)/e])

K = 50 # define the number of points on the grids
approximate_value = [] # initialize an empty list in which approximate values are stored
approximation_error = [] # absolute value difference between the true and the approximate value

m = 1 #iterator
# Evaluate integrals and compare with true values
for (x_lower_bound, x_upper_bound, y_lower_bound, y_upper_bound) in range_2d_integration 

  # define grids for x and y dimensions:
  xgrid = collect(linspace(x_lower_bound, x_upper_bound,K))
  ygrid = collect(linspace(y_lower_bound, y_upper_bound,K))

  fxygrid = zeros(K,K) #initialization

  for i=1:K
    for j=1:K
        fxygrid[i,j] = f_test[m](xgrid[i], ygrid[j])
    end
  end

  spl = Spline2D(xgrid, ygrid, fxygrid)

  # 2-d spline integration:
  push!(approximate_value, integrate(spl, x_lower_bound, x_upper_bound, y_lower_bound, y_upper_bound))
  
  push!(approximation_error, abs(approximate_value[m] - true_value[m]))

  m+=1
end

# tolerance level for tests
tol = 1.e-6
# test equality
@test isapprox(approximation_error[1], 0., atol=tol)
@test isapprox(approximation_error[2], 0., atol=tol)
@test isapprox(approximation_error[3], 0., atol=tol)

println("All tests passed.")

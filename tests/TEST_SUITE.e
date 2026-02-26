note
    description: "Simple Test Suite for Autograd"

class
    TEST_SUITE

inherit
    DOUBLE_MATH
        export {NONE} all end

create
    make

feature -- Initialization

    make
        local
            l_env: ET_ENV
        do
        	power_test
            print ("Configuring Environment...%N")
            create l_env
            l_env.append_to_path ("spec\openblas\bin")

            print ("Running Tests...%N")
            test_sanity_check
            test_more_ops
            test_torch_use_cases
            test_blas
            test_safe_tensors
            print ("All Tests Passed!%N")
        end


	power_test
	    local
            d: REAL_64
        do
            d := -2.0
            print ("(-2.0) ^ 3.0 = " + d.power (3.0).out + "%N")
            print ("(-2.0) ^ 1.5 = " + d.power (1.5).out + "%N")
        end

feature -- Tests

	test_torch_use_cases
		local
			t: ET_TORCH_USE_CASES
		do
			create t
            t.from_existing_data
            t.changing_tensor_dimensions
            t.restructuring_tensor_dimensions
            t.combining_tensors
            t.accessing_elements
            t.slicing_tensors
            t.arithmetic_operations
            t.broadcasting_tensors
            t.logic_and_comparisons
            t.statistics
            t.matmul_operations
		end

	test_blas
		local
			t: ET_TEST_BLAS
		do
			create t.default_create
			t.on_prepare
			t.test_sgemm_square
			t.test_sgemm_rectangular
		end

	test_safe_tensors
		local
			t: ET_TEST_SAFE_TENSORS
		do
			create t.default_create
			-- t.on_prepare -- only if needed
			t.test_safetensors_mmap_load
		end

    test_sanity_check
        local
            a, b, c, d, e, f, L: ET_VALUE
            tol: REAL_64
        do
            print ("  [TEST] Sanity Check... ")
            tol := 1.0e-6
            create a.make (2.0)
            create b.make (-3.0)
            create c.make (10.0)
            create f.make (-2.0)

            -- e = a * b
            -- d = e + c
            -- L = d * f
            e := a * b
            d := e + c
            L := d * f

            L.backward

            -- L = ((a * b) + c) * f
            -- dL/da = dL/de * de/da = f * b = -2 * -3 = 6
            assert_approx (a.grad, 6.0, tol, "a.grad should be 6.0")
            assert_approx (b.grad, -4.0, tol, "b.grad should be -4.0") -- f * a = -2 * 2 = -4

            print ("OK%N")
        end

    test_more_ops
        local
            x: ET_VALUE
            z: ET_VALUE
            tol: REAL_64
        do
            print ("  [TEST] More Ops (ReLU, Pow)... ")
            tol := 1.0e-6
            create x.make (-4.0)

            -- z = 2 * x + 2 + x
            -- z = 3x + 2 -> dz/dx = 3
            z := x * create {ET_VALUE}.make(2.0) + create {ET_VALUE}.make(2.0) + x
            z.backward

            assert_approx (x.grad, 3.0, tol, "x.grad should be 3.0")

            -- ReLU
            create x.make (2.0)
            z := x.relu
            z.backward
            assert_approx (x.grad, 1.0, tol, "relu(2) grad should be 1")

            create x.make (-2.0)
            z := x.relu
            z.backward
            assert_approx (x.grad, 0.0, tol, "relu(-2) grad should be 0")

            print ("OK%N")
        end

    assert_approx (actual, expected, tol: REAL_64; msg: STRING)
        do
            if (actual - expected).abs > tol then
                print ("%NFAIL: " + msg + " Expected " + expected.out + " but got " + actual.out + "%N")
                {EXCEPTIONS}.raise ("Assertion Failed")
            end
        end

end

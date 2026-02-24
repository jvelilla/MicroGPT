note
	description: "Tests for ET_BLAS class."

class
	ET_TEST_BLAS

inherit
	EQA_TEST_SET
		redefine
			on_prepare
		end

feature -- Initialization

	on_prepare
			-- Called before each test.
		local
			l_env: ET_ENV
		do
--			create l_env
--			-- When running from EIFGENs\tests\W_code, we traverse up 3 levels to project root.
--			l_env.append_to_path ("C:\home\Learn\agentsAi\Eiffel\MicroGPT\spec\openblas\bin")
		end

feature -- Tests

	test_sgemm_square
		local
			A, B, C: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			tol: REAL_64
			val: REAL_32
			i: INTEGER
		do
			print ("  [TEST] ET_BLAS S-GEMM Square (128x128)... ")
			tol := 1.0e-3 -- Float32 precision tolerance

			-- From PyTorch baseline:
			-- A, B are randn initialized with seed 42. Because we don't have exactly the same
			-- random generator, we will inject a known deterministic pattern to test exact value,
			-- OR we just test the shape and logic. Let's do a uniform known pattern.
			create A.make_ones (<<128, 128>>)
			create B.make_ones (<<128, 128>>)

			-- For Ones: C = A * B -> every element of C should be 128.0
			C := A.matmul (B)

			assert ("Shape is 128x128", C.shape[1] = 128 and C.shape[2] = 128)

			val := C.item (<<1, 1>>).item
			assert_approx_32 (val, 128.0, tol, "C[1,1]")
			val := C.item (<<128, 128>>).item
			assert_approx_32 (val, 128.0, tol, "C[128,128]")

			print ("OK%N")
		end

	test_sgemm_rectangular
		local
			A, B, C: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			tol: REAL_64
			val: REAL_32
		do
			print ("  [TEST] ET_BLAS S-GEMM Rectangular (64x128 @ 128x32)... ")
			tol := 1.0e-3

			create A.make_ones (<<64, 128>>)
			create B.make_ones (<<128, 32>>)

			-- For Ones: C = A * B -> every element of C should be 128.0
			C := A.matmul (B)

			assert ("Shape is 64x32", C.shape[1] = 64 and C.shape[2] = 32)

			val := C.item (<<1, 1>>).item
			assert_approx_32 (val, 128.0, tol, "C[1,1]")
			val := C.item (<<64, 32>>).item
			assert_approx_32 (val, 128.0, tol, "C[64,32]")

			print ("OK%N")
		end

	assert_approx_32 (actual: REAL_32; expected: REAL_64; tol: REAL_64; msg: STRING)
		do
			assert (msg + " Expected " + expected.out + " but got " + actual.out, (actual.to_double - expected).abs <= tol)
		end

end

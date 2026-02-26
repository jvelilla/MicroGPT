note
	description: "Tests for TENSOR class."

class
	ET_TEST_TENSOR

inherit
	EQA_TEST_SET
		redefine
			on_prepare
		select
			default_create
		end
	DOUBLE_MATH
		rename
			default_create as dm_default_create
		end

feature -- Initialization

	on_prepare
			-- Called before each test.
		local
			l_env: ET_ENV
		do
			create l_env
			-- When running from EIFGENs\tests\W_code, we traverse up 3 levels to project root.
			l_env.append_to_path ("..\..\..\spec\openblas\bin")
		end

feature -- Tests

	test_tensor_creation
		local
			t: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			shape: ARRAY [INTEGER]
			indices: ARRAY [INTEGER]
			val: REAL_32
			tol: REAL_64
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
		do
			print ("  [TEST] Tensor Creation... ")
			tol := 1.0e-6
			shape := <<2, 3>>
			create t.make_zeros (shape)

			-- Check shape
			assert ("Correct shape", t.shape [1] = 2 and t.shape [2] = 3)

			-- Check zeros
			indices := <<1, 1>>
			val := t.item (indices).item
			assert_approx_32 (val, 0.0, tol, "t[1,1] should be 0.0")

			-- Check put/get
			l_elem.set_item ({REAL_32} 5.5)
			t.put (l_elem, indices)
			val := t.item (indices).item
			assert_approx_32 (val, 5.5, tol, "t[1,1] should be 5.5")

			print ("OK%N")
		end

	test_tensor_matmul
		local
			A, B, C: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			shape_A, shape_B: ARRAY [INTEGER]
			tol: REAL_64
			v: REAL_32
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
		do
			print ("  [TEST] Tensor Matmul... ")
			tol := 1.0e-6

			-- A (2x2) Identity
			shape_A := <<2, 2>>
			create A.make_zeros (shape_A)
			l_elem.set_item ({REAL_32} 1.0) ; A.put (l_elem, <<1, 1>>)
			l_elem.set_item ({REAL_32} 0.0) ; A.put (l_elem, <<1, 2>>)
			l_elem.set_item ({REAL_32} 0.0) ; A.put (l_elem, <<2, 1>>)
			l_elem.set_item ({REAL_32} 1.0) ; A.put (l_elem, <<2, 2>>)

			-- B (2x2) = [[1, 2], [3, 4]]
			shape_B := <<2, 2>>
			create B.make_zeros (shape_B)
			l_elem.set_item ({REAL_32} 1.0) ; B.put (l_elem, <<1, 1>>)
			l_elem.set_item ({REAL_32} 2.0) ; B.put (l_elem, <<1, 2>>)
			l_elem.set_item ({REAL_32} 3.0) ; B.put (l_elem, <<2, 1>>)
			l_elem.set_item ({REAL_32} 4.0) ; B.put (l_elem, <<2, 2>>)

			-- C = A * B = I * B = B
			C := A.matmul (B)

			v := C.item (<<1, 1>>).item
			assert_approx_32 (v, 1.0, tol, "C[1,1]")
			v := C.item (<<1, 2>>).item
			assert_approx_32 (v, 2.0, tol, "C[1,2]")
			v := C.item (<<2, 1>>).item
			assert_approx_32 (v, 3.0, tol, "C[2,1]")
			v := C.item (<<2, 2>>).item
			assert_approx_32 (v, 4.0, tol, "C[2,2]")

			print ("OK%N")
		end

	test_tensor_transpose
		local
			a, at: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			shape: ARRAY [INTEGER]
			tol: REAL_64
			v: REAL_32
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
		do
			print ("  [TEST] Tensor Transpose... ")
			tol := 1.0e-6

			-- A (2x3)
			-- [[1, 2, 3],
			--  [4, 5, 6]]
			shape := <<2, 3>>
			create a.make_zeros (shape)
			l_elem.set_item ({REAL_32} 1.0) ; a.put (l_elem, <<1, 1>>)
			l_elem.set_item ({REAL_32} 2.0) ; a.put (l_elem, <<1, 2>>)
			l_elem.set_item ({REAL_32} 3.0) ; a.put (l_elem, <<1, 3>>)
			l_elem.set_item ({REAL_32} 4.0) ; a.put (l_elem, <<2, 1>>)
			l_elem.set_item ({REAL_32} 5.0) ; a.put (l_elem, <<2, 2>>)
			l_elem.set_item ({REAL_32} 6.0) ; a.put (l_elem, <<2, 3>>)

			at := a.transpose (1, 2)

			-- at (3x2)
			-- [[1, 4],
			--  [2, 5],
			--  [3, 6]]

			assert ("Correct transposed shape", at.shape [1] = 3 and At.shape [2] = 2)

			v := at.item (<<1, 1>>).item -- A[1,1] = 1
			assert_approx_32 (v, 1.0, tol, "At[1,1]")

			v := at.item (<<1, 2>>).item -- A[2,1] = 4
			assert_approx_32 (v, 4.0, tol, "At[1,2]")

			v := at.item (<<3, 2>>).item -- A[2,3] = 6
			assert_approx_32 (v, 6.0, tol, "At[3,2]")

			print ("OK%N")
		end

	test_tensor_broadcast_matmul
		local
			A, B, C: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			shape_A, shape_B: ARRAY [INTEGER]
			tol: REAL_64
			v: REAL_32
		do
			print ("  [TEST] Tensor Batch Matmul... ")
			tol := 1.0e-5
			
			-- Batch dim 2
			-- A: (2, 2, 2)
			shape_A := <<2, 2, 2>>
			create A.make_ones (shape_A)
			
			-- B: (2, 2, 2)
			shape_B := <<2, 2, 2>>
			create B.make_ones (shape_B)
			
			-- C = A * B -> (2, 2, 2)
			-- Each slice is ones(2,2) * ones(2,2) = full(2,2, val=2)
			C := A.matmul (B)
			
			assert ("Correct shape", C.shape.count = 3 and C.shape[1] = 2)
			
			v := C.item (<<1, 1, 1>>).item
			assert_approx_32 (v, 2.0, tol, "C[1,1,1] should be 2.0")
			v := C.item (<<2, 2, 2>>).item
			assert_approx_32 (v, 2.0, tol, "C[2,2,2] should be 2.0")
			
			print ("OK%N")
		end

	test_tensor_element_wise
		local
			A, B, C: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			tol: REAL_64
			v: REAL_32
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
		do
			print ("  [TEST] Tensor Element-wise (Broadcast)... ")
			tol := 1.0e-5
			
			-- A: (2, 3)
			-- [[1, 1, 1],
			--  [2, 2, 2]]
			create A.make_zeros (<<2, 3>>)
			l_elem.set_item ({REAL_32} 1.0) ; A.put (l_elem, <<1, 1>>)
			l_elem.set_item ({REAL_32} 1.0) ; A.put (l_elem, <<1, 2>>)
			l_elem.set_item ({REAL_32} 1.0) ; A.put (l_elem, <<1, 3>>)
			l_elem.set_item ({REAL_32} 2.0) ; A.put (l_elem, <<2, 1>>)
			l_elem.set_item ({REAL_32} 2.0) ; A.put (l_elem, <<2, 2>>)
			l_elem.set_item ({REAL_32} 2.0) ; A.put (l_elem, <<2, 3>>)
			
			-- B: (1, 3) -> Broadcasts to (2, 3)
			-- [[10, 20, 30]]
			create B.make_zeros (<<1, 3>>)
			l_elem.set_item ({REAL_32} 10.0) ; B.put (l_elem, <<1, 1>>)
			l_elem.set_item ({REAL_32} 20.0) ; B.put (l_elem, <<1, 2>>)
			l_elem.set_item ({REAL_32} 30.0) ; B.put (l_elem, <<1, 3>>)
			
			-- C = A + B
			-- [[11, 21, 31],
			--  [12, 22, 32]]
			C := A + B
			
			assert ("Correct shape", C.shape[1] = 2 and C.shape[2] = 3)
			
			v := C.item (<<1, 1>>).item
			assert_approx_32 (v, 11.0, tol, "C[1,1]")
			v := C.item (<<2, 3>>).item
			assert_approx_32 (v, 32.0, tol, "C[2,3]")
			
			print ("OK%N")
		end
	
	test_tensor_reductions
		local
			A: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			S, M, Mx: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			Am: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
			tol: REAL_64
			idx: INTEGER
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
		do
			print ("  [TEST] Tensor Reductions... ")
			tol := 1.0e-5
			
			-- A: (2, 3)
			-- [[1, 2, 3],
			--  [4, 5, 6]]
			create A.make_zeros (<<2, 3>>)
			l_elem.set_item ({REAL_32} 1.0) ; A.put (l_elem, <<1, 1>>)
			l_elem.set_item ({REAL_32} 2.0) ; A.put (l_elem, <<1, 2>>)
			l_elem.set_item ({REAL_32} 3.0) ; A.put (l_elem, <<1, 3>>)
			l_elem.set_item ({REAL_32} 4.0) ; A.put (l_elem, <<2, 1>>)
			l_elem.set_item ({REAL_32} 5.0) ; A.put (l_elem, <<2, 2>>)
			l_elem.set_item ({REAL_32} 6.0) ; A.put (l_elem, <<2, 3>>)
			
			-- Sum dim 1 -> (1, 3) or (3,) depending on keep_dim
			-- [[5, 7, 9]]
			S := A.sum (1, True)
			assert ("Sum shape", S.shape[1] = 1 and S.shape[2] = 3)
			assert_approx_32 (S.item (<<1, 1>>).item, 5.0, tol, "Sum[1]")
			assert_approx_32 (S.item (<<1, 3>>).item, 9.0, tol, "Sum[3]")
			
			-- Mean dim 2 -> (2, 1)
			-- [[2], [5]]
			M := A.mean_dim (2, True)
			assert ("Mean shape", M.shape[1] = 2 and M.shape[2] = 1)
			assert_approx_32 (M.item (<<2, 1>>).item, 5.0, tol, "Mean[2]")
			
			-- Max dim 2 -> (2, 1)
			-- [[3], [6]]
			Mx := A.max (2, True)
			assert_approx_32 (Mx.item (<<1, 1>>).item, 3.0, tol, "Max[1]")
			
			-- Argmax dim 2 -> (2, 1)
			-- [[3], [3]] (Indices are 1-based: 3rd element is max)
			Am := A.argmax (2, True)
			idx := Am.item (<<1, 1>>).item
			assert ("Argmax[1]", idx = 3)
			idx := Am.item (<<2, 1>>).item
			assert ("Argmax[2]", idx = 3)
			
			print ("OK%N")
		end

	test_tensor_autograd
		local
			x, y, z: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			tol: REAL_64
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
		do
			print ("  [TEST] Tensor Autograd... ")
			tol := 1.0e-5
			
			-- Simple addition/multiplication autograd
			l_elem.set_item ({REAL_32} 2.0)
			create x.make_full (<<1>>, l_elem)
			x.set_requires_grad (True)
			
			l_elem.set_item ({REAL_32} 3.0)
			create y.make_full (<<1>>, l_elem)
			y.set_requires_grad (True)
			
			-- z = x * y + y
			-- dz/dx = y = 3.0
			-- dz/dy = x + 1 = 2.0 + 1 = 3.0
			z := x * y + y
			z.backward
			
			if attached x.grad as g_x then
				assert_approx_32 (g_x.item (<<1>>).item, 3.0, tol, "dz/dx should be 3.0")
			else
				assert ("x.grad is not null", False)
			end
			
			if attached y.grad as g_y then
				assert_approx_32 (g_y.item (<<1>>).item, 3.0, tol, "dz/dy should be 3.0")
			else
				assert ("y.grad is not null", False)
			end
			
			print ("OK%N")
		end

	test_attention_autograd
		local
			q, k, v, att, att_probs, l_out, loss: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			tol: REAL_64
			l_elem: ET_NUMERIC_ELEMENT [REAL_32]
			t_scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			b, t, c: INTEGER
			causal_mask: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			t1, t2: INTEGER
			scalar_shape: ARRAY [INTEGER]
		do
			print ("  [TEST] Attention Autograd... ")
			tol := 1.0e-4
			
			b := 2
			t := 3
			c := 4
			
			create q.make_ones (<<b, t, c>>)
			create k.make_ones (<<b, t, c>>)
			create v.make_ones (<<b, t, c>>)
			
			q.set_requires_grad (True)
			k.set_requires_grad (True)
			v.set_requires_grad (True)
			
			att := q.matmul (k.transpose (2, 3))
			
			create scalar_shape.make_empty
			create l_elem
			l_elem.set_item ((1.0 / c.to_double.power (0.5)).truncated_to_real)
			create t_scale.make_full (scalar_shape, l_elem)
			att := att * t_scale
			
			create causal_mask.make_zeros (<<t, t>>)
			create l_elem
			l_elem.set_item ({REAL_32} -1.0e9)
			
			from t1 := 1 until t1 > t loop
				from t2 := t1 + 1 until t2 > t loop
					causal_mask.put (l_elem, <<t1, t2>>)
					t2 := t2 + 1
				end
				t1 := t1 + 1
			end
			
			att := att + causal_mask
			
			att_probs := att.exp_val
			att_probs := att_probs / att_probs.sum (3, True)
			
			l_out := att_probs.matmul (v)
			
			loss := l_out.sum (1, False).sum (1, False).sum (1, False)
			loss.backward
			
			if attached q.grad as g_q then
				print ("%N[DEBUG] q grad mean: " + g_q.mean.item_scalar.item.out + "%N")
				assert_approx_32 (g_q.mean.item_scalar.item, 0.0, 1.0, "q grad mean")
			end
			
			if attached v.grad as g_v then
				print ("[DEBUG] v grad mean: " + g_v.mean.item_scalar.item.out + "%N")
				assert_approx_32 (g_v.mean.item_scalar.item, 1.0, 1.0e-3, "v grad mean")
			end
			
			if attached k.grad as g_k then
				print ("[DEBUG] k grad mean: " + g_k.mean.item_scalar.item.out + "%N")
			end
			
			print ("OK%N")
		end

	assert_approx_32 (actual: REAL_32; expected: REAL_64; tol: REAL_64; msg: STRING)
		do
			assert (msg + " Expected " + expected.out + " but got " + actual.out, (actual.to_double - expected).abs <= tol)
		end

end

note
	description: "N-dimensional Tensor backed by MANAGED_POINTER."

class
	ET_TENSOR [G -> ET_TENSOR_ELEMENT]

inherit
	ANY
		redefine
			out
		end

create
	make_zeros,
	make_ones,
	make_full,
	make_randn,
	make_from_iterable,
	make_from_integer_array,
	make_from_real_64_array,
	make_from_pointer

feature {NONE} -- Initialization

	numeric: ET_TENSOR_NUMERIC [G]
			-- Lazy initialization of the type-specific strategy.
		local
			l_res: detachable ET_TENSOR_NUMERIC [G]
		do
			if attached internal_numeric as n then
				Result := n
			else
				if ({G}).type_id = ({ET_NUMERIC_ELEMENT [REAL_32]}).type_id then
					check attached {ET_TENSOR_NUMERIC [G]} (create {ET_TENSOR_NUMERIC_REAL_32}) as n then l_res := n end
				elseif ({G}).type_id = ({ET_NUMERIC_ELEMENT [REAL_64]}).type_id then
					check attached {ET_TENSOR_NUMERIC [G]} (create {ET_TENSOR_NUMERIC_REAL_64}) as n then l_res := n end
				elseif ({G}).type_id = ({ET_NUMERIC_ELEMENT [INTEGER_32]}).type_id then
					check attached {ET_TENSOR_NUMERIC [G]} (create {ET_TENSOR_NUMERIC_INTEGER_32}) as n then l_res := n end
				elseif ({G}).type_id = ({ET_NUMERIC_ELEMENT [INTEGER_64]}).type_id then
					check attached {ET_TENSOR_NUMERIC [G]} (create {ET_TENSOR_NUMERIC_INTEGER_64}) as n then l_res := n end
				elseif ({G}).type_id = ({ET_BOOLEAN_ELEMENT}).type_id then
					check attached {ET_TENSOR_NUMERIC [G]} (create {ET_TENSOR_NUMERIC_BOOLEAN}) as n then l_res := n end
				else
					check not_supported: False then end
				end
				check attached l_res as r then
					Result := r
					internal_numeric := r
				end
			end
		end

	internal_numeric: detachable ET_TENSOR_NUMERIC [G]


	make_zeros (a_shape: ARRAY [INTEGER])
			-- Create a tensor of zeros with `a_shape`.
		require
			supported_type: True
		do
			make_full (a_shape, numeric.zero_value)
		ensure
			shape_set: shape ~ a_shape
		end

	make_ones (a_shape: ARRAY [INTEGER])
			-- Create a tensor of ones with `a_shape`.
		require
			supported_type: True
		do
			make_full (a_shape, numeric.one_value)
		ensure
			shape_set: shape ~ a_shape
		end

	make_full (a_shape: ARRAY [INTEGER]; a_value: ANY)
			-- Create a tensor filled with `a_value` with `a_shape`.
		require
			supported_type: True
			valid_value: attached {G} a_value
		local
			l_count: INTEGER
			l_size: INTEGER
			
			i: INTEGER
			l_offset: INTEGER
			l_g_value: G
		do
			
			shape := a_shape.deep_twin
			calc_strides
			l_count := numel
			l_size := l_count * numeric.element_size

			create data.make (l_size)
			offset := 0
			
			create prev.make (0)
			op_code := Op_none

			check attached {G} a_value as v then
				l_g_value := v
			end

			from i := 0 until i >= l_count loop
				l_offset := i * numeric.element_size
				-- We use raw pointer put because we are initializing contiguous memory
				numeric.put (data, l_offset, l_g_value)
				i := i + 1
			end
		ensure
			shape_set: shape ~ a_shape
		end

	make_randn (a_shape: ARRAY [INTEGER])
			-- Create a tensor with random numbers from a normal distribution with `a_shape`.
		require
			valid_shape: not a_shape.is_empty
			supported_type: True
			is_float: ({G}).type_id = ({ET_NUMERIC_ELEMENT [REAL_32]}).type_id or ({G}).type_id = ({ET_NUMERIC_ELEMENT [REAL_64]}).type_id
		local
			l_count: INTEGER
			l_size: INTEGER
			
			i: INTEGER
			l_offset: INTEGER
			l_random: RANDOM
			l_seed: INTEGER
			l_u1, l_u2, l_z0: REAL_64
			l_time: TIME
		do
			
			shape := a_shape.deep_twin
			calc_strides
			l_count := numel
			l_size := l_count * numeric.element_size

			create data.make (l_size)
			offset := 0
			
			create prev.make (0)
			op_code := Op_none

            create l_time.make_now
            l_seed := l_time.compact_time
            create l_random.set_seed (l_seed)

			from i := 0 until i >= l_count loop
				-- Box-Muller transform
				l_random.forth
				l_u1 := l_random.double_item
				l_random.forth
				l_u2 := l_random.double_item

				-- Avoid log(0)
				if l_u1 <= 0.0 then l_u1 := 0.0000001 end

				l_z0 := {DOUBLE_MATH}.sqrt (-2.0 * {DOUBLE_MATH}.log (l_u1)) * {DOUBLE_MATH}.cosine (2.0 * {DOUBLE_MATH}.Pi * l_u2)

				l_offset := i * numeric.element_size

				numeric.put (data, l_offset, numeric.from_real_64 (l_z0))

				i := i + 1
			end
		ensure
			shape_set: shape ~ a_shape
		end

	make_from_iterable (a_data: ITERABLE [G])
			-- Create a 1D tensor from an iterable.
		require
			supported_type: True
		local
			l_count: INTEGER
			l_size: INTEGER
			
			i: INTEGER
			l_offset: INTEGER
		do
			

			-- Count elements
			l_count := 0
			across a_data as ic loop
				l_count := l_count + 1
			end

			shape := <<l_count>>

			calc_strides
			l_size := l_count * numeric.element_size

			create data.make (l_size)
			offset := 0
			
			create prev.make (0)
			op_code := Op_none

			i := 0
			across a_data as ic loop
				if i < l_count then
					l_offset := i * numeric.element_size
					numeric.put (data, l_offset, ic)
					i := i + 1
				end
			end
		ensure
			shape_set: numel = size(dim)
		end

	make_from_integer_array (a_data: ARRAY [INTEGER])
			-- Create a 1D tensor from an array of integers, converting via `from_integer`.
		local
			l_count, i, l_offset: INTEGER
		do
			l_count := a_data.count
			shape := <<l_count>>
			calc_strides
			create data.make (l_count * numeric.element_size)
			offset := 0
			create prev.make (0)
			op_code := Op_none
			from i := a_data.lower until i > a_data.upper loop
				l_offset := (i - a_data.lower) * numeric.element_size
				numeric.put (data, l_offset, numeric.from_integer (a_data [i]))
				i := i + 1
			end
		end

	make_from_real_64_array (a_data: ARRAY [REAL_64])
			-- Create a 1D tensor from an array of REAL_64 values, converting via `from_real_64`.
		local
			l_count, i, l_offset: INTEGER
		do
			l_count := a_data.count
			shape := <<l_count>>
			calc_strides
			create data.make (l_count * numeric.element_size)
			offset := 0
			create prev.make (0)
			op_code := Op_none
			from i := a_data.lower until i > a_data.upper loop
				l_offset := (i - a_data.lower) * numeric.element_size
				numeric.put (data, l_offset, numeric.from_real_64 (a_data [i]))
				i := i + 1
			end
		end

	make_from_pointer (a_data: MANAGED_POINTER; a_offset: INTEGER; a_shape: ARRAY [INTEGER]; a_strides: ARRAY [INTEGER])
			-- Create a tensor view from existing pointer.
		do
			data := a_data
			offset := a_offset
			shape := a_shape.deep_twin
			strides := a_strides.deep_twin
			
			create prev.make (0)
			op_code := Op_none
		end

feature -- Access

	data: MANAGED_POINTER
	offset: INTEGER
	shape: ARRAY [INTEGER]
	strides: ARRAY [INTEGER]

feature -- Autograd Properties

	requires_grad: BOOLEAN
	grad: detachable ET_TENSOR [G]
	prev: ARRAYED_LIST [ET_TENSOR [G]]
	op_code: INTEGER
	backward_fn: detachable PROCEDURE [TUPLE]
	visited: BOOLEAN

feature -- Constants

    Op_none: INTEGER = 0
    Op_add: INTEGER = 1
    Op_mul: INTEGER = 2
    Op_pow: INTEGER = 3
    Op_relu: INTEGER = 4
    Op_tanh: INTEGER = 5
    Op_exp: INTEGER = 6
    Op_log: INTEGER = 7

feature -- Attributes

	dim: INTEGER
			-- Number of dimensions (e.g. 2 for a matrix).
		do
			if shape.is_empty then
				Result := 0 -- Or 1 for scalar? PyTorch scalar is dim 0.
			else
				Result := shape.count
			end
		end

	size (a_dim: INTEGER): INTEGER
			-- Size of the tensor along dimension `a_dim` (1-based index).
		require
			valid_dim: a_dim >= 1 and a_dim <= dim
		do
			Result := shape [a_dim]
		end

	is_contiguous: BOOLEAN
			-- Is the tensor contiguous in memory?
		local
			i: INTEGER
			acc: INTEGER
			
		do
			
			acc := numeric.element_size
			Result := True
			from i := shape.count until i < 1 loop
				if strides [i] /= acc then
					Result := False
					i := 0 -- break
				else
					acc := acc * shape [i]
					i := i - 1
				end
			end
		end

	item (indices: ARRAY [INTEGER]): G
			-- Get element at `indices`.
		require
			valid_indices: indices.count = shape.count
		local
			l_offset: INTEGER
			
			
		do
			l_offset := offset + calculate_offset (indices)
			
			

			Result := numeric.read (data, l_offset)
		end

	item_scalar: G
			-- Extracts the value from a single-element tensor as a standard scalar.
			-- Equivalent to `.item()` in PyTorch.
		require
			is_scalar: numel = 1
		local
			l_indices: ARRAY [INTEGER]
		do
			create l_indices.make_filled (1, 1, shape.count)
			Result := item (l_indices)
		end

feature -- Autograd Element Change

	set_requires_grad (b: BOOLEAN)
			-- Set whether this tensor should compute gradients.
		do
			requires_grad := b
		end

	set_grad (g: ET_TENSOR [G])
			-- Explicitly set the gradient tensor.
		do
			grad := g
		end

	set_visited (b: BOOLEAN)
			-- Used during topological sort.
		do
			visited := b
		end

	set_prev (a_prev: ARRAYED_LIST [ET_TENSOR [G]])
			-- Set children tensors for backprop tracking.
		do
			prev := a_prev
		end

	set_op_code (op: INTEGER)
		do
			op_code := op
		end

	set_backward_fn (fn: PROCEDURE [TUPLE])
		do
			backward_fn := fn
		end

feature -- Element Change

	put (v: G; indices: ARRAY [INTEGER])
			-- Put `v` at `indices`.
		require
			valid_indices: indices.count = shape.count
		local
			l_offset: INTEGER
			
			
		do
			l_offset := offset + calculate_offset (indices)
			
			

			numeric.put (data, l_offset, v)
		end

feature -- Autograd Topology

	backward
			-- Compute gradients for the entire tensor graph via backpropagation.
		require
			valid_shape: numel = 1 -- Can only start backward from a scalar tensor
		local
			topo: ARRAYED_LIST [ET_TENSOR [G]]
			i: INTEGER
			
			l_one_tensor: ET_TENSOR [G]
		do
			create topo.make (100) -- Heuristic size

			build_topo (Current, topo)

			-- gradient = 1.0 for the scalar leaf
			
			create l_one_tensor.make_full (shape, numeric.one_value)
			set_grad (l_one_tensor)

			-- Apply backward in reverse topological order
			from
				i := topo.count
			until
				i < 1
			loop
				if attached topo [i].backward_fn as bf then
					bf.call ([])
				end
				-- Reset visited for next pass
				topo [i].set_visited (False)
				i := i - 1
			end
		end

	build_topo (v: ET_TENSOR [G]; topo: ARRAYED_LIST [ET_TENSOR [G]])
		do
			if not v.visited then
				v.set_visited (True)
				if not v.prev.is_empty then
					across v.prev as child loop
						build_topo (child, topo)
					end
				end
				topo.extend (v)
			end
		end

	accumulate_grad (a_grad: ET_TENSOR [G])
			-- Accumulate gradients.
			-- grad = grad + a_grad
		local
			l_new_grad: ET_TENSOR [G]
		do
			if attached grad as g then
				l_new_grad := g + a_grad
				set_grad (l_new_grad)
			else
				set_grad (a_grad)
			end
		end

 feature -- Operations

	broadcast_to (a_new_shape: ARRAY [INTEGER]): ET_TENSOR [G]
			-- Broadcast tensor to `a_new_shape`.
		local
			l_new_strides: ARRAY [INTEGER]
			l_new_shape: ARRAY [INTEGER]
			i, j: INTEGER
			offset_adjust: INTEGER
		do
			create l_new_shape.make_from_array (a_new_shape)
			create l_new_strides.make_filled (0, 1, a_new_shape.count)

			-- Logic: Align dimensions from the right.
			-- If dim is 1 in self, stride is 0 in result (broadcast).
			-- If dim is missing in self, stride is 0 (broadcast).

			offset_adjust := a_new_shape.count - shape.count

			from i := a_new_shape.count until i < 1 loop
				j := i - offset_adjust
				if j >= 1 then
					-- Mapping to existing dimension
					if shape [j] = a_new_shape [i] then
						l_new_strides [i] := strides [j]
					elseif shape [j] = 1 then
						-- Broadcast: stride becomes 0
						l_new_strides [i] := 0
					else
						-- Error: Incompatible shape
						check compatible: False end
					end
				else
					-- New dimension added on left (broadcast)
					l_new_strides [i] := 0
				end
				i := i - 1
			end

			create Result.make_from_pointer (data, offset, l_new_shape, l_new_strides)
		ensure
			same_data: Result.data = data
		end

	expand_as (other: ET_TENSOR [G]): ET_TENSOR [G]
			-- Broadcast self to match `other` shape.
		do
			Result := broadcast_to (other.shape)
		end

feature -- Logical Operations

	greater alias ">" (v: G): ET_TENSOR [ET_BOOLEAN_ELEMENT]
			-- Element-wise greater than scalar. Returns True or False.
		local
			l_res: ET_TENSOR [ET_BOOLEAN_ELEMENT]
			l_indices: ARRAY [INTEGER]
		do
			create l_res.make_zeros (shape)
			create l_indices.make_filled (1, 1, shape.count)
			recursive_apply_logical_scalar (1, l_indices, l_res, Current, v, agent (x, y: G): BOOLEAN do Result := x > y end)
			Result := l_res
		end

	less_equal alias "<=" (v: G): ET_TENSOR [ET_BOOLEAN_ELEMENT]
			-- Element-wise less or equal scalar. Returns True or False.
		local
			l_res: ET_TENSOR [ET_BOOLEAN_ELEMENT]
			l_indices: ARRAY [INTEGER]
		do
			create l_res.make_zeros (shape)
			create l_indices.make_filled (1, 1, shape.count)
			recursive_apply_logical_scalar (1, l_indices, l_res, Current, v, agent (x, y: G): BOOLEAN do Result := x <= y end)
			Result := l_res
		end

	equal_tensor alias "|==" (v: G): ET_TENSOR [ET_BOOLEAN_ELEMENT]
			-- Element-wise equal to scalar. Returns True or False.
		local
			l_res: ET_TENSOR [ET_BOOLEAN_ELEMENT]
			l_indices: ARRAY [INTEGER]
		do
			create l_res.make_zeros (shape)
			create l_indices.make_filled (1, 1, shape.count)
			recursive_apply_logical_scalar (1, l_indices, l_res, Current, v, agent (x, y: G): BOOLEAN do Result := x ~ y end)
			Result := l_res
		end

	logical_and alias "&" (other: ET_TENSOR [G]): ET_TENSOR [ET_BOOLEAN_ELEMENT]
			-- Element-wise logical AND. Returns True or False.
		local
			l_a, l_b: ET_TENSOR [G]
			l_res: ET_TENSOR [ET_BOOLEAN_ELEMENT]
			l_res_shape: ARRAY [INTEGER]
		do
			l_res_shape := calculate_broadcast_shape (shape, other.shape)
			l_a := broadcast_to (l_res_shape)
			l_b := other.broadcast_to (l_res_shape)

			create l_res.make_zeros (l_res_shape)
			internal_logical_op_tensor (l_a, l_b, l_res, agent logical_and_eval)
			Result := l_res
		end

	logical_or alias "|" (other: ET_TENSOR [G]): ET_TENSOR [ET_BOOLEAN_ELEMENT]
			-- Element-wise logical OR. Returns True or False.
		local
			l_a, l_b: ET_TENSOR [G]
			l_res: ET_TENSOR [ET_BOOLEAN_ELEMENT]
			l_res_shape: ARRAY [INTEGER]
		do
			l_res_shape := calculate_broadcast_shape (shape, other.shape)
			l_a := broadcast_to (l_res_shape)
			l_b := other.broadcast_to (l_res_shape)

			create l_res.make_zeros (l_res_shape)
			internal_logical_op_tensor (l_a, l_b, l_res, agent logical_or_eval)
			Result := l_res
		end

feature {NONE} -- Logical Helpers

	recursive_apply_logical_scalar (a_dim: INTEGER; indices: ARRAY [INTEGER]; res: ET_TENSOR [ET_BOOLEAN_ELEMENT]; src: ET_TENSOR [G]; v: G; op: FUNCTION [G, G, BOOLEAN])
		local
			i: INTEGER
			l_b: ET_BOOLEAN_ELEMENT
		do
			if a_dim > src.shape.count then
				if op.item ([src.item (indices), v]) then
					l_b.set_item (True)
					res.put (l_b, indices)
				else
					l_b.set_item (False)
					res.put (l_b, indices)
				end
			else
				from i := 1 until i > src.shape [a_dim] loop
					indices [a_dim] := i
					recursive_apply_logical_scalar (a_dim + 1, indices, res, src, v, op)
					i := i + 1
				end
			end
		end

	internal_logical_op_tensor (a, b: ET_TENSOR [G]; res: ET_TENSOR [ET_BOOLEAN_ELEMENT]; op: FUNCTION [G, G, BOOLEAN])
		local
			indices: ARRAY [INTEGER]
		do
			create indices.make_filled (1, 1, res.shape.count)
			recursive_apply_logical (1, indices, a, b, res, op)
		end

	recursive_apply_logical (a_dim: INTEGER; indices: ARRAY [INTEGER]; a, b: ET_TENSOR [G]; res: ET_TENSOR [ET_BOOLEAN_ELEMENT]; op: FUNCTION [G, G, BOOLEAN])
		local
			i: INTEGER
			l_b: ET_BOOLEAN_ELEMENT
		do
			if a_dim > res.shape.count then
				if op.item ([a.item (indices), b.item (indices)]) then
					l_b.set_item (True)
					res.put (l_b, indices)
				else
					l_b.set_item (False)
					res.put (l_b, indices)
				end
			else
				from i := 1 until i > res.shape [a_dim] loop
					indices [a_dim] := i
					recursive_apply_logical (a_dim + 1, indices, a, b, res, op)
					i := i + 1
				end
			end
		end

	logical_and_eval (x, y: G): BOOLEAN
		local
			
			l_zero: ANY
		do
			
			l_zero := numeric.zero_value
			Result := (x /~ l_zero) and (y /~ l_zero)
		end

	logical_or_eval (x, y: G): BOOLEAN
		local
			
			l_zero: ANY
		do
			
			l_zero := numeric.zero_value
			Result := (x /~ l_zero) or (y /~ l_zero)
		end

feature -- Non-linear Operations

	relu: ET_TENSOR [G]
			-- Element-wise Rectified Linear Unit.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			do
			
			create l_res.make_zeros (shape)
			internal_op_tensor (Current, Current, l_res, agent relu_eval)

			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_relu (l_res, Current))
			end
			Result := l_res
		end

feature {ET_TENSOR} -- Relu Eval Helper
	relu_eval (x, y: G): G
		local
			
			l_zero: ANY
		do
			
			l_zero := numeric.zero_value
			if attached {G} l_zero as z then
				if x > z then
					Result := x
				else
					Result := z
				end
			else
				Result := x -- Fallback
			end
		end

	tanh: ET_TENSOR [G]
			-- Element-wise Hyperbolic Tangent.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			i, l_count: INTEGER
			l_offset: INTEGER
			l_val, l_t, l_e2x: REAL_64
			l_math: DOUBLE_MATH
		do
			create l_res.make_zeros (shape)
			
			create l_math
			l_count := numel

			from i := 0 until i >= l_count loop
				l_offset := offset + i * numeric.element_size
				if attached {REAL_64} numeric.read (data, l_offset) as val64 then l_val := val64 else l_val := 0.0 end

				if l_val > 20.0 then
					l_t := 1.0
				elseif l_val < -20.0 then
					l_t := -1.0
				else
					l_e2x := l_math.exp (2.0 * l_val)
					l_t := (l_e2x - 1.0) / (l_e2x + 1.0)
				end

				numeric.put (l_res.data, i * numeric.element_size, numeric.from_real_64 (l_t))
				i := i + 1
			end

			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_tanh (l_res, Current))
			end

			Result := l_res
		end

	gelu: ET_TENSOR [G]
			-- Gaussian Error Linear Unit approximation.
		local
			v_k, v_half, v_one, v_coef: ET_TENSOR [G]
			term1, term2, term3: ET_TENSOR [G]
			
			l_scalar_shape: ARRAY [INTEGER]
		do
			
			create l_scalar_shape.make_empty
			create v_k.make_full (l_scalar_shape, numeric.from_real_64 (0.7978845608))
			create v_half.make_full (l_scalar_shape, numeric.from_real_64 (0.5))
			create v_one.make_full (l_scalar_shape, numeric.from_real_64 (1.0))
			create v_coef.make_full (l_scalar_shape, numeric.from_real_64 (0.044715))

			term1 := power (3.0)
			term2 := Current + (term1 * v_coef)
			term3 := (term2 * v_k).tanh

			Result := Current * v_half * (v_one + term3)
		end

	exp_val: ET_TENSOR [G]
			-- Element-wise exponential.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			i, l_count: INTEGER
			l_val, l_t: REAL_64
			l_math: DOUBLE_MATH
		do
			create l_res.make_zeros (shape)
			
			create l_math
			l_count := numel

			from i := 0 until i >= l_count loop
				if attached {REAL_64} numeric.read (data, offset + i * 4) as v64 then l_val := v64 elseif attached {REAL_32} numeric.read (data, offset + i * 4) as v32 then l_val := v32.to_double elseif attached {INTEGER_32} numeric.read (data, offset + i * 4) as i32 then l_val := i32.to_double elseif attached {INTEGER_64} numeric.read (data, offset + i * 4) as i64 then l_val := i64.to_double else l_val := 0.0 end

				l_t := l_math.exp (l_val)

				numeric.put (l_res.data, i * numeric.element_size, numeric.from_real_64 (l_t))
				i := i + 1
			end

			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_exp (l_res, Current))
			end

			Result := l_res
		end

	log_val: ET_TENSOR [G]
			-- Element-wise natural logarithm.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			i, l_count: INTEGER
			l_val, l_t: REAL_64
			l_math: DOUBLE_MATH
		do
			create l_res.make_zeros (shape)
			
			create l_math
			l_count := numel

			from i := 0 until i >= l_count loop
				if attached {REAL_64} numeric.read (data, offset + i * 4) as v64 then l_val := v64 elseif attached {REAL_32} numeric.read (data, offset + i * 4) as v32 then l_val := v32.to_double elseif attached {INTEGER_32} numeric.read (data, offset + i * 4) as i32 then l_val := i32.to_double elseif attached {INTEGER_64} numeric.read (data, offset + i * 4) as i64 then l_val := i64.to_double else l_val := 0.0 end

				l_t := l_math.log (l_val)

				numeric.put (l_res.data, i * numeric.element_size, numeric.from_real_64 (l_t))
				i := i + 1
			end

			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_log (l_res, Current))
			end

			Result := l_res
		end

	power alias "^" (p_val: REAL_64): ET_TENSOR [G]
			-- Element-wise power.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			i, l_count: INTEGER
			l_val, l_t: REAL_64
		do
			create l_res.make_zeros (shape)
			
			l_count := numel

			from i := 0 until i >= l_count loop
				if attached {REAL_64} numeric.read (data, offset + i * 4) as v64 then l_val := v64 elseif attached {REAL_32} numeric.read (data, offset + i * 4) as v32 then l_val := v32.to_double elseif attached {INTEGER_32} numeric.read (data, offset + i * 4) as i32 then l_val := i32.to_double elseif attached {INTEGER_64} numeric.read (data, offset + i * 4) as i64 then l_val := i64.to_double else l_val := 0.0 end

				l_t := l_val.power (p_val)

				numeric.put (l_res.data, i * numeric.element_size, numeric.from_real_64 (l_t))
				i := i + 1
			end

			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				-- We need to pass the exponent value to the backward fn, Eiffel agents support open args
				l_res.set_backward_fn (agent backward_pow (l_res, Current, p_val))
			end

			Result := l_res
		end

feature {NONE} -- Element-wise Autograd Helpers

	backward_relu (res, a: ET_TENSOR [G])
		local
			l_mask: ET_TENSOR [ET_BOOLEAN_ELEMENT]
			l_mask_g: ET_TENSOR [G]
			
			l_zero: G
			i, l_count: INTEGER
		do
			if attached res.grad as g then
				if a.requires_grad then
					-- Create mask where a > 0
					
					if attached {G} numeric.zero_value as z then
						l_zero := z
						l_mask := a > l_zero

						-- Convert bool mask back to float mask for multiplication
						create l_mask_g.make_zeros (a.shape)
						l_count := a.numel
						from i := 0 until i >= l_count loop
							if numeric.read (l_mask.data, i * numeric.element_size) /~ numeric.zero_value then
								numeric.put (l_mask_g.data, i * numeric.element_size, numeric.from_real_64 (1.0))
							end
							i := i + 1
						end

						a.accumulate_grad (g * l_mask_g)
					end
				end
			end
		end

	backward_tanh (res, a: ET_TENSOR [G])
		local
			l_one: ET_TENSOR [G]
			
		do
			if attached res.grad as g then
				if a.requires_grad then
					
					if attached {G} numeric.from_real_64 (1.0) as one_val then
						create l_one.make_full (res.shape, one_val)
						-- d(tanh(x)) = 1 - tanh(x)^2
						a.accumulate_grad (g * (l_one - (res * res)))
					end
				end
			end
		end

	backward_exp (res, a: ET_TENSOR [G])
		do
			if attached res.grad as g then
				if a.requires_grad then
					-- d(e^x) = e^x
					-- Since res = e^x, we just do g * res
					a.accumulate_grad (g * res)
				end
			end
		end

	backward_log (res, a: ET_TENSOR [G])
		local
			l_one: ET_TENSOR [G]
			
		do
			if attached res.grad as g then
				if a.requires_grad then
					-- d(log(x)) = 1/x
					
					if attached {G} numeric.from_real_64 (1.0) as one_val then
						create l_one.make_full (a.shape, one_val)
						a.accumulate_grad (g * (l_one / a))
					end
				end
			end
		end

	backward_pow (res, a: ET_TENSOR [G]; p_val: REAL_64)
		local
			l_p: ET_TENSOR [G]
			
		do
			if attached res.grad as g then
				if a.requires_grad then
					
					if attached {G} numeric.from_real_64 (p_val) as p_g then
						create l_p.make_full (a.shape, p_g)
						a.accumulate_grad (g * (l_p * a.power (p_val - 1.0)))
					end
				end
			end
		end

feature -- Arithmetic Operations

	plus alias "+" (other: ET_TENSOR [G]): ET_TENSOR [G]
		local
			l_a, l_b: ET_TENSOR [G]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_res_shape: ARRAY [INTEGER]
			do
			l_res_shape := calculate_broadcast_shape (shape, other.shape)
			l_a := broadcast_to (l_res_shape)
			l_b := other.broadcast_to (l_res_shape)

			create l_res.make_zeros (l_res_shape)
			internal_op_tensor (l_a, l_b, l_res, agent numeric.add_elements)

			-- Autograd
			if requires_grad or other.requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (2)
				l_children.extend (Current)
				l_children.extend (other)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_add (l_res, Current, other))
			end

			Result := l_res
		end

	minus alias "-" (other: ET_TENSOR [G]): ET_TENSOR [G]
		local
			l_a, l_b: ET_TENSOR [G]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_res_shape: ARRAY [INTEGER]
			do
			l_res_shape := calculate_broadcast_shape (shape, other.shape)
			l_a := broadcast_to (l_res_shape)
			l_b := other.broadcast_to (l_res_shape)

			create l_res.make_zeros (l_res_shape)
			internal_op_tensor (l_a, l_b, l_res, agent numeric.sub_elements)

			-- Autograd
			if requires_grad or other.requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (2)
				l_children.extend (Current)
				l_children.extend (other)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_sub (l_res, Current, other))
			end

			Result := l_res
		end

	product alias "*" (other: ET_TENSOR [G]): ET_TENSOR [G]
		local
			l_a, l_b: ET_TENSOR [G]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_res_shape: ARRAY [INTEGER]
			do
			l_res_shape := calculate_broadcast_shape (shape, other.shape)
			l_a := broadcast_to (l_res_shape)
			l_b := other.broadcast_to (l_res_shape)

			create l_res.make_zeros (l_res_shape)
			internal_op_tensor (l_a, l_b, l_res, agent numeric.mul_elements)

			-- Autograd
			if requires_grad or other.requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (2)
				l_children.extend (Current)
				l_children.extend (other)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_mul (l_res, Current, other))
			end

			Result := l_res
		end

	quotient alias "/" (other: ET_TENSOR [G]): ET_TENSOR [G]
		local
			l_a, l_b: ET_TENSOR [G]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_res_shape: ARRAY [INTEGER]
			do
			l_res_shape := calculate_broadcast_shape (shape, other.shape)
			l_a := broadcast_to (l_res_shape)
			l_b := other.broadcast_to (l_res_shape)

			create l_res.make_zeros (l_res_shape)
			internal_op_tensor (l_a, l_b, l_res, agent numeric.div_elements)

			-- Autograd
			if requires_grad or other.requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (2)
				l_children.extend (Current)
				l_children.extend (other)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_div (l_res, Current, other))
			end

			Result := l_res
		end

feature {ANY} -- Arithmetic Autograd Helpers

	backward_add (res, a, b: ET_TENSOR [G])
		do
			if attached res.grad as g then
				if a.requires_grad then
					a.accumulate_grad (unbroadcast (g, a.shape))
				end
				if b.requires_grad then
					b.accumulate_grad (unbroadcast (g, b.shape))
				end
			end
		end

	backward_sub (res, a, b: ET_TENSOR [G])
		do
			if attached res.grad as g then
				if a.requires_grad then
					a.accumulate_grad (unbroadcast (g, a.shape))
				end
				if b.requires_grad then
					b.accumulate_grad (unbroadcast (g_negated (g), b.shape))
				end
			end
		end

	backward_mul (res, a, b: ET_TENSOR [G])
		do
			if attached res.grad as g then
				if a.requires_grad then
					a.accumulate_grad (unbroadcast (g * b, a.shape))
				end
				if b.requires_grad then
					b.accumulate_grad (unbroadcast (g * a, b.shape))
				end
			end
		end

	backward_div (res, a, b: ET_TENSOR [G])
		do
			-- c = a / b
			-- da = dc / b
			-- db = -dc * a / (b^2)
			if attached res.grad as dc then
				if a.requires_grad then
					a.accumulate_grad (unbroadcast (dc / b, a.shape))
				end
				if b.requires_grad then
					b.accumulate_grad (unbroadcast (g_negated (dc) * a / (b * b), b.shape))
				end
			end
		end

	g_negated (t: ET_TENSOR [G]): ET_TENSOR [G]
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			
		do
			
			if attached {G} numeric.from_integer (-1) as l_minus_one then
				create l_res.make_full (t.shape, l_minus_one)
				Result := t * l_res
			else
				Result := t -- Unlikely fallback
			end
		end

	unbroadcast (g_in: ET_TENSOR [G]; target_shape: ARRAY [INTEGER]): ET_TENSOR [G]
			-- Reverse the effect of broadcasting by summing over expanded dimensions.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			i, l_offset, dim_idx: INTEGER
			do
			l_res := g_in
			l_offset := g_in.shape.count - target_shape.count

			-- 1. Sum away any prepended dimensions
			from i := 1 until i > l_offset loop
				l_res := l_res.sum (1, False)
				i := i + 1
			end

			-- 2. Sum away dimensions that were broadcasted from 1 to N
			from i := 1 until i > target_shape.count loop
				dim_idx := i
				if target_shape [i] = 1 and l_res.shape [dim_idx] > 1 then
					l_res := l_res.sum (dim_idx, True)
				end
				i := i + 1
			end

			Result := l_res
		end

	calculate_broadcast_shape (s1, s2: ARRAY [INTEGER]): ARRAY [INTEGER]
			-- Compute the broadcasting shape of two shapes according to PyTorch/NumPy semantics.
		local
			k, max_dim: INTEGER
			dim1, dim2: INTEGER
		do
			max_dim := s1.count.max (s2.count)
			if max_dim = 0 then
				create Result.make_empty
			else
				create Result.make_filled (0, 1, max_dim)
				from k := 0 until k >= max_dim loop
					if s1.count - k >= 1 then
						dim1 := s1 [s1.count - k]
					else
						dim1 := 1
					end

					if s2.count - k >= 1 then
						dim2 := s2 [s2.count - k]
					else
						dim2 := 1
					end

					if dim1 = dim2 then
						Result [max_dim - k] := dim1
					elseif dim1 = 1 then
						Result [max_dim - k] := dim2
					elseif dim2 = 1 then
						Result [max_dim - k] := dim1
					else
						check compatible: False end
					end
					k := k + 1
				end
			end
		end

	cat (tensors: ARRAY [ET_TENSOR [G]]; a_dim: INTEGER): ET_TENSOR [G]
			-- Concatenates the given sequence of `tensors` along the given dimension `a_dim`.
			-- All tensors must either have the same shape (except in the concatenating dimension)
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
			has_tensors: not tensors.is_empty
		local
			l_new_shape: ARRAY [INTEGER]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			i, j: INTEGER
			l_total_size_at_dim: INTEGER
			t: ET_TENSOR [G]
			l_indices: ARRAY [INTEGER]
			l_target_indices: ARRAY [INTEGER]
			l_offset_at_dim: INTEGER
		do
			l_new_shape := shape.deep_twin
			l_total_size_at_dim := 0

			-- Validate and compute new shape
			from i := 1 until i > tensors.count loop
				t := tensors [i]
				check valid_shape: t.shape.count = shape.count end
				from j := 1 until j > shape.count loop
					if j /= a_dim then
						check same_dim_size: t.shape [j] = shape [j] end
					end
					j := j + 1
				end
				l_total_size_at_dim := l_total_size_at_dim + t.shape [a_dim]
				i := i + 1
			end

			l_new_shape [a_dim] := l_total_size_at_dim
			create l_res.make_zeros (l_new_shape)

			-- Copy data
			l_offset_at_dim := 0
			from i := 1 until i > tensors.count loop
				t := tensors [i]

				create l_indices.make_filled (1, 1, shape.count)
				create l_target_indices.make_filled (1, 1, shape.count)

				recursive_cat_copy (1, l_indices, l_target_indices, t, l_res, a_dim, l_offset_at_dim)

				l_offset_at_dim := l_offset_at_dim + t.shape [a_dim]
				i := i + 1
			end

			Result := l_res
		end

feature {NONE} -- Concatenation Helpers

	recursive_cat_copy (dim_idx: INTEGER; indices: ARRAY [INTEGER]; target_indices: ARRAY [INTEGER]; src, dest: ET_TENSOR [G]; concat_dim: INTEGER; offset_at_dim: INTEGER)
		local
			i: INTEGER
		do
			if dim_idx > src.shape.count then
				dest.put (src.item (indices), target_indices)
			else
				from i := 1 until i > src.shape [dim_idx] loop
					indices [dim_idx] := i
					if dim_idx = concat_dim then
						target_indices [dim_idx] := i + offset_at_dim
					else
						target_indices [dim_idx] := i
					end
					recursive_cat_copy (dim_idx + 1, indices, target_indices, src, dest, concat_dim, offset_at_dim)
					i := i + 1
				end
			end
		end

feature -- Reductions

	sum (a_dim: INTEGER; keep_dim: BOOLEAN): ET_TENSOR [G]
			-- Sum reduction over `dim`.
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
		local
			l_new_shape: ARRAY [INTEGER]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			do
			l_new_shape := calculate_reduction_shape (a_dim, keep_dim)
			create l_res.make_zeros (l_new_shape)

			recursive_reduce_fill (1, create {ARRAY [INTEGER]}.make_empty, l_res, a_dim, agent (acc, v: G): G do Result := acc + v end, False)

			-- Autograd
			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_sum (l_res, Current))
			end

			Result := l_res
		end

	mean_dim (a_dim: INTEGER; keep_dim: BOOLEAN): ET_TENSOR [G]
			-- Mean reduction over `a_dim`.
		local
			l_sum: ET_TENSOR [G]
			l_divisor: G
			
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			do
			l_sum := sum (a_dim, keep_dim)
			

			-- Create divisor
			if attached {G} numeric.from_integer (shape [a_dim]) as l_g_dim then
				l_divisor := l_g_dim
				-- Element-wise divide l_sum by divisor
				-- We can use internal_op_tensor if we treat divisor as 0-d tensor or just broadcast/map
				-- Or create a tensor of same shape filled with divisor
				-- Simpler: just loop over result and divide.

				-- Let's use `make_full` then div?
				-- Or custom map.
				-- Let's assume arithmetic is supported on G.
				-- Since we have `quotient` defined, we can do:
				-- l_res := l_sum / (tensor_filled_with_divisor)
				-- This uses our broadcasting.
				l_res := l_sum / (create {ET_TENSOR [G]}.make_full (create {ARRAY[INTEGER]}.make_filled(1, 1, 1), l_divisor))
			else
				check conversion_supported: False end
				l_res := l_sum -- Fail safe
			end

			Result := l_res
		end

	mean: ET_TENSOR [G]
			-- Calculate the mean of all elements in the tensor.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_count: INTEGER
			
			i: INTEGER
			l_offset: INTEGER
			l_sum, l_val, l_mean: REAL_64
			do
			l_count := numel
			
			from i := 0 until i >= l_count loop
				l_offset := offset + i * numeric.element_size
				l_val := numeric.to_real_64 (numeric.read (data, l_offset))
				l_sum := l_sum + l_val
				i := i + 1
			end
			l_mean := l_sum / l_count.to_double

			create l_res.make_zeros (create {ARRAY [INTEGER]}.make_empty)
			if attached {G} numeric.from_real_64 (l_mean) as l_g_mean then
				l_res.put (l_g_mean, create {ARRAY [INTEGER]}.make_empty)
			end

			-- Autograd
			if requires_grad then
				l_res.set_requires_grad (True)
				create l_children.make (1)
				l_children.extend (Current)
				l_res.set_prev (l_children)
				l_res.set_backward_fn (agent backward_mean_all (l_res, Current))
			end

			Result := l_res
		end

feature {NONE} -- Reduction Autograd Helpers

	backward_sum (res, a: ET_TENSOR [G])
		do
			if attached res.grad as g then
				if a.requires_grad then
					-- The gradient of sum just broadcasts the output grad backward
					a.accumulate_grad (g.broadcast_to (a.shape))
				end
			end
		end

	backward_mean_all (res, a: ET_TENSOR [G])
		local
			
			n: INTEGER
			factor: G
			weighted_grad: ET_TENSOR [G]
		do
			if attached res.grad as g then
				if a.requires_grad then
					-- da = dn / N  where dn is broadcasted
					n := a.numel
					
					if attached {G} numeric.from_real_64 (1.0 / n.to_double) as f then
						factor := f
						-- res.grad is scalar, broadcast to size A and scale	
						create weighted_grad.make_full (a.shape, factor)
						a.accumulate_grad (g.broadcast_to (a.shape) * weighted_grad)
					end
				end
			end
		end

feature -- Extra Properties

	std: ET_TENSOR [G]
			-- Calculate the standard deviation of all elements in the tensor.
		local
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_count: INTEGER
			
			i: INTEGER
			l_offset: INTEGER
			l_sum, l_sum_sq, l_val, l_mean, l_variance: REAL_64
			l_math: DOUBLE_MATH
		do
			create l_math
			l_count := numel
			
			from i := 0 until i >= l_count loop
				l_offset := offset + i * numeric.element_size
				l_val := numeric.to_real_64 (numeric.read (data, l_offset))
				l_sum := l_sum + l_val
				l_sum_sq := l_sum_sq + l_val * l_val
				i := i + 1
			end
			l_mean := l_sum / l_count.to_double
			-- Bessel's correction: divide by (n-1) to match PyTorch std() default (sample std dev)
			if l_count > 1 then
				l_variance := (l_sum_sq - l_count.to_double * l_mean * l_mean) / (l_count - 1).to_double
			else
				l_variance := 0.0
			end
			if l_variance < 0.0 then l_variance := 0.0 end -- precision guard

			create l_res.make_zeros (create {ARRAY [INTEGER]}.make_empty)
			if attached {G} numeric.from_real_64 (l_math.sqrt (l_variance)) as l_g_std then
				l_res.put (l_g_std, create {ARRAY [INTEGER]}.make_empty)
			end
			Result := l_res
		end

	max (a_dim: INTEGER; keep_dim: BOOLEAN): ET_TENSOR [G]
			-- Max reduction over `dim`.
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
		local
			l_new_shape: ARRAY [INTEGER]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
		do
			l_new_shape := calculate_reduction_shape (a_dim, keep_dim)
			-- Init with very small number? Or first element?
			-- Better: Init with first element of the reduction dim, then iterate.
			-- Or, use a flag in reduce to take first.

			-- For now, let's init with 0 (works for ReLU output), but problematic for negatives.
			-- Correct way: use first item.
			-- Simplified: Initialize with a value from user or extremely small.
			-- Let's use a custom reduce that handles init.
			create l_res.make_zeros (l_new_shape)

			recursive_reduce_fill (1, create {ARRAY [INTEGER]}.make_empty, l_res, a_dim, agent (acc, v: G): G
				do
					if acc > v then Result := acc else Result := v end
				end, True) -- True for 'init_with_first'
			Result := l_res
		end

	argmax (a_dim: INTEGER; keep_dim: BOOLEAN): ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
			-- Argmax reduction over `dim`.
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
		local
			l_new_shape: ARRAY [INTEGER]
			l_res: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
		do
			l_new_shape := calculate_reduction_shape (a_dim, keep_dim)
			create l_res.make_zeros (l_new_shape)

			-- Generic argmax is hard because G is numeric, result is INTEGER.
			-- Our recursive_reduce logic acumulates G.
			-- We need a specific implementation for argmax.
			recursive_argmax_fill (1, create {ARRAY [INTEGER]}.make_empty, l_res, a_dim)

			Result := l_res
		end

feature {NONE} -- Reduction Helpers

	calculate_reduction_shape (a_dim: INTEGER; keep_dim: BOOLEAN): ARRAY [INTEGER]
		local
			i: INTEGER
		do
			create Result.make_empty
			from i := 1 until i > shape.count loop
				if i /= a_dim then
					Result.force (shape [i], Result.count + 1)
				elseif keep_dim then
					Result.force (1, Result.count + 1)
				end
				i := i + 1
			end
			if Result.is_empty then
				Result.force (1, 1) -- scalar
			end
		end

	recursive_reduce_fill (dim_idx: INTEGER; indices: ARRAY [INTEGER]; res: ET_TENSOR [G]; reduce_dim: INTEGER; op: FUNCTION [G, G, G]; init_from_first: BOOLEAN)
			-- Iterate over `res` and compute reduction from `Current`.
		local
			i, k: INTEGER
			l_source_indices: ARRAY [INTEGER]
			l_acc: G
			l_val: G
			l_indices_copy: ARRAY [INTEGER]
		do
			if dim_idx > res.shape.count then
				-- We are at a single element in `res`.
				-- `indices` points to the location in `res`.
				-- We need to reconstruct the full key for `Current` (except reduce_dim).
				-- And iterate over `reduce_dim`.

				-- RECONSTRUCT Indices:
				-- We have `indices` of length N (or N-1 if !keep_dim).
				-- We map them back to source dims.
				create l_source_indices.make_filled (1, 1, shape.count)

				k := 1
				from i := 1 until i > shape.count loop
					if i = reduce_dim then
						-- this is the reduction loop dim
						-- If keep_dim is True, indices has the same rank as shape, so we must advance k
						if indices.count = shape.count then
							k := k + 1
						end
					else
						l_source_indices [i] := indices [k]
						k := k + 1
					end
					i := i + 1
				end

				-- Now loop over reduce_dim
				from i := 1 until i > shape [reduce_dim] loop
					l_source_indices [reduce_dim] := i
					l_val := item (l_source_indices)

					if i = 1 then
						if init_from_first then
							l_acc := l_val
						else
							-- assume acc initialized in res (likely 0)
							-- so accumulate on top of 0
							l_acc := op.item ([res.item(indices), l_val])
						end
					else
						l_acc := op.item ([l_acc, l_val])
					end
					i := i + 1
				end
				res.put (l_acc, indices)
			else
				from i := 1 until i > res.shape [dim_idx] loop
					l_indices_copy := indices.deep_twin
					l_indices_copy.force (i, l_indices_copy.count + 1)
					recursive_reduce_fill (dim_idx + 1, l_indices_copy, res, reduce_dim, op, init_from_first)
					i := i + 1
				end
			end
		end

	recursive_argmax_fill (dim_idx: INTEGER; indices: ARRAY [INTEGER]; res: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]; reduce_dim: INTEGER)
		local
			i, k: INTEGER
			l_source_indices: ARRAY [INTEGER]
			l_max_val: G
			l_val: G
			l_max_idx: INTEGER
			l_indices_copy: ARRAY [INTEGER]
			l_res_val: ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			if dim_idx > res.shape.count then
				-- Reconstruct indices
				create l_source_indices.make_filled (1, 1, shape.count)
				k := 1
				from i := 1 until i > shape.count loop
					if i = reduce_dim then
						if indices.count = shape.count then
							k := k + 1
						end
					else
						l_source_indices [i] := indices [k]
						k := k + 1
					end
					i := i + 1
				end

				l_max_idx := 1
				-- Loop
				from i := 1 until i > shape [reduce_dim] loop
					l_source_indices [reduce_dim] := i
					l_val := item (l_source_indices)

					if i = 1 then
						l_max_val := l_val
						l_max_idx := 1 -- 1-based index (PyTorch uses 0-based? Eiffel usually 1-based, let's stick to 1-based for now)
					else
						if l_val > l_max_val then
							l_max_val := l_val
							l_max_idx := i
						end
					end
					i := i + 1
				end
				-- res is TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
				l_res_val.set_item (l_max_idx)
				res.put (l_res_val, indices)
			else
				from i := 1 until i > res.shape [dim_idx] loop
					l_indices_copy := indices.deep_twin
					l_indices_copy.force (i, l_indices_copy.count + 1)
					recursive_argmax_fill (dim_idx + 1, l_indices_copy, res, reduce_dim)
					i := i + 1
				end
			end
		end

feature -- Matrix Operations

	matmul (other: ET_TENSOR [G]): ET_TENSOR [G]
			-- Matrix multiplication with broadcasting, or dot product for 1D tensors.
			-- Supports: (n) x (n)      -> ()      1D dot product
			-- Supports: (n,m) x (m,)   -> (n,)   matrix-vector product
			-- Supports: (...,n,m) x (...,m,p) -> (...,n,p)  batched matmul with broadcast
		require
			valid_operands: shape.count >= 1 and other.shape.count >= 1
			compatible_inner:
				-- 1D dot: (n) x (n)
				(shape.count = 1 and other.shape.count = 1 implies shape [1] = other.shape [1])
				or else
				-- Matrix-vector: (n,m) x (m,)
				(shape.count >= 2 and other.shape.count = 1 implies shape [shape.count] = other.shape [1])
				or else
				-- General matmul: (...,n,m) x (...,m,p)
				(shape.count >= 2 and other.shape.count >= 2 implies shape [shape.count] = other.shape [other.shape.count - 1])
		local
			l_new_shape: ARRAY [INTEGER]
			l_res: ET_TENSOR [G]
			l_children: ARRAYED_LIST [ET_TENSOR [G]]
			l_dot: G
			i, j: INTEGER
			l_idx_a, l_idx_b: ARRAY [INTEGER]
		do
			if shape.count = 1 and other.shape.count = 1 then
				-- ── Case 1: 1D dot product (n,) x (n,) → scalar ()
				create l_idx_a.make_filled (1, 1, 1)
				from i := 1 until i > shape [1] loop
					l_idx_a [1] := i
					if i = 1 then
						l_dot := item (l_idx_a) * other.item (l_idx_a)
					else
						l_dot := l_dot + (item (l_idx_a) * other.item (l_idx_a))
					end
					i := i + 1
				end
				create l_new_shape.make_empty
				create l_res.make_zeros (l_new_shape)
				l_res.put (l_dot, create {ARRAY [INTEGER]}.make_empty)

				if requires_grad or other.requires_grad then
					l_res.set_requires_grad (True)
					create l_children.make (2)
					l_children.extend (Current)
					l_children.extend (other)
					l_res.set_prev (l_children)
					l_res.set_backward_fn (agent backward_dot (l_res, Current, other))
				end
				Result := l_res

			elseif shape.count >= 2 and other.shape.count = 1 then
				-- ── Case 2: Matrix-vector product (...,n,m) x (m,) → (...,n,)
				-- Result shape: all but last dim of self
				l_new_shape := shape.deep_twin
				l_new_shape.remove_tail (1)          -- drop last dim (m)
				create l_res.make_zeros (l_new_shape)
				perform_matvec (create {ARRAY [INTEGER]}.make_empty, l_res, other)

				if requires_grad or other.requires_grad then
					l_res.set_requires_grad (True)
					create l_children.make (2)
					l_children.extend (Current)
					l_children.extend (other)
					l_res.set_prev (l_children)
					l_res.set_backward_fn (agent backward_matmul (l_res, Current, other))
				end
				Result := l_res

			else
				-- ── Case 3: General batched matmul (...,n,m) x (...,m,p) → (...,n,p)
				-- Strategy: broadcast batch dims, recurse down to 2D slices.
				create l_new_shape.make_from_array (calculate_matmul_shape (shape, other.shape))
				create l_res.make_zeros (l_new_shape)
				recursive_matmul (1, create {ARRAY [INTEGER]}.make_empty, l_res, other, shape.count - 2, other.shape.count - 2)

				if requires_grad or other.requires_grad then
					l_res.set_requires_grad (True)
					create l_children.make (2)
					l_children.extend (Current)
					l_children.extend (other)
					l_res.set_prev (l_children)
					l_res.set_backward_fn (agent backward_matmul (l_res, Current, other))
				end
				Result := l_res
			end
		end

feature {NONE} -- Matrix Autograd Helpers

	backward_dot (res, a, b: ET_TENSOR [G])
		do
			-- 1D dot product: a . b
			-- da = b * dc
			-- db = a * dc
			if attached res.grad as dc then
				if a.requires_grad then
					-- dc is a scalar tensor (size empty []) - broadcast to 'a' shape
					a.accumulate_grad (b * dc)
				end
				if b.requires_grad then
					b.accumulate_grad (a * dc)
				end
			end
		end

	backward_matmul (res, a, b: ET_TENSOR [G])
		local
			g_unbroadcast_a, g_unbroadcast_b: ET_TENSOR [G]
		do
			-- C = A @ B
			-- dA = dC @ B^T
			-- dB = A^T @ dC
			if attached res.grad as dC then
				if a.requires_grad then
					-- For batched sizes, we unbroadcast gradient down to the original shape
					g_unbroadcast_a := unbroadcast (dC.matmul (b.transpose (b.shape.count - 1, b.shape.count)), a.shape)
					a.accumulate_grad (g_unbroadcast_a)
				end
				if b.requires_grad then
					g_unbroadcast_b := unbroadcast (a.transpose (a.shape.count - 1, a.shape.count).matmul (dC), b.shape)
					b.accumulate_grad (g_unbroadcast_b)
				end
			end
		end

	calculate_matmul_shape (s1, s2: ARRAY [INTEGER]): ARRAY [INTEGER]
			-- Compute the output shape for s1 @ s2.
			-- s1: (..., n, m)   s2: (..., m, p)  or  s2: (m,) for matvec.
			-- Returns: (..., n, p)  or  (..., n,) for matvec.
		local
			d1, d2: INTEGER
			rem1, rem2: INTEGER
			i: INTEGER
			l_max: INTEGER
			val1, val2: INTEGER
			l_result_dim: INTEGER
		do
			d1 := s1.count
			d2 := s2.count

			if d2 = 1 then
				-- ── Matvec: (..., n, m) x (m,) → (..., n,)
				-- Result has all dims of s1 except the last one
				l_result_dim := d1 - 1
				if l_result_dim < 0 then l_result_dim := 0 end -- Scalar result if d1=1
				create Result.make_filled (1, 1, l_result_dim)
				from i := 1 until i > l_result_dim loop
					Result [i] := s1 [i]
					i := i + 1
				end
				if l_result_dim = 0 then
					create Result.make_empty -- Scalar result
				end
			else
				-- ── General case: (..., n, m) x (..., m, p) → (..., n, p)
				rem1 := d1 - 2
				rem2 := d2 - 2
				l_max := rem1.max (rem2)
				if l_max < 0 then l_max := 0 end

				create Result.make_filled (1, 1, l_max + 2)

				-- Broadcast batch dims (right-aligned)
				from i := 1 until i > l_max loop
					if rem1 - l_max + i >= 1 then val1 := s1 [rem1 - l_max + i] else val1 := 1 end
					if rem2 - l_max + i >= 1 then val2 := s2 [rem2 - l_max + i] else val2 := 1 end
					Result [i] := val1.max (val2)
					i := i + 1
				end

				-- n (rows of A) and p (cols of B)
				Result [l_max + 1] := if d1 >= 2 then s1 [d1 - 1] else 1 end  -- n
				Result [l_max + 2] := if d2 >= 2 then s2 [d2]     else 1 end  -- p
			end
		end

	recursive_matmul (a_dim: INTEGER; indices: ARRAY [INTEGER]; res: ET_TENSOR [G]; other: ET_TENSOR [G]; batch_dims1, batch_dims2: INTEGER)
		local
			i: INTEGER
			l_indices_copy: ARRAY [INTEGER]
		do
			if a_dim > res.shape.count - 2 then
				-- Base case: 2D matmul
				-- We need to extract the 2D slices at `indices`
				-- How to get slice? `narrow`?
				-- Since we don't have a multi-dim slicer, we assume `item` can be used
				-- but `matmul` expects TENSOR inputs.
				-- We need a way to get a TENSOR view of the inner matrix.
				-- `narrow` works one dim at a time.

				-- Workaround: Calculate offset manually and create a 2D view?
				-- Or just iterate loops here for the last 2 dimensions.

				perform_2d_matmul (indices, res, other)
			else
				from i := 1 until i > res.shape [a_dim] loop
					l_indices_copy := indices.deep_twin
					l_indices_copy.force (i, l_indices_copy.count + 1)
					recursive_matmul (a_dim + 1, l_indices_copy, res, other, batch_dims1, batch_dims2)
					i := i + 1
				end
			end
		end

	perform_2d_matmul (batch_indices: ARRAY [INTEGER]; res: ET_TENSOR [G]; other: ET_TENSOR [G])
			-- Compute a single 2D matrix multiply for the batch slice identified by `batch_indices`.
			-- res.shape: [..., n, p]   self.shape: [..., n, m]   other.shape: [..., m, p]
		local
			i, j, k: INTEGER
			l_rows, l_cols, l_common: INTEGER
			l_sum: G
			l_full_idx_res: ARRAY [INTEGER]
		do
			-- shape: [..., n, p]  (last two dims)
			l_rows   := res.shape [res.shape.count - 1]  -- n
			l_cols   := res.shape [res.shape.count]       -- p
			l_common := shape [shape.count]               -- m (inner dim of self)

			from i := 1 until i > l_rows loop
				from j := 1 until j > l_cols loop
					check attached {G} numeric.zero_value as l_zero then
						l_sum := l_zero
					end
					from k := 1 until k > l_common loop
						-- A[batch, i, k] * B[batch, k, j]  (with broadcasting on batch dims)
						l_sum := l_sum + get_broadcast_item (batch_indices, i, k, True, other)
									 * get_broadcast_item (batch_indices, k, j, False, other)
						k := k + 1
					end
					l_full_idx_res := batch_indices.deep_twin
					l_full_idx_res.force (i, l_full_idx_res.count + 1)
					l_full_idx_res.force (j, l_full_idx_res.count + 1)
					res.put (l_sum, l_full_idx_res)
					j := j + 1
				end
				i := i + 1
			end
		end

	perform_matvec (batch_indices: ARRAY [INTEGER]; res: ET_TENSOR [G]; vec: ET_TENSOR [G])
			-- Compute matrix-vector product for (...,n,m) x (m,) → (...,n,)
			-- `batch_indices` covers only the outer batch dims of `res`.
		local
			i, k: INTEGER
			l_rows, l_common: INTEGER
			l_sum: G
			l_idx_a, l_idx_v, l_full_idx_res: ARRAY [INTEGER]
		do
			if batch_indices.count < res.shape.count - 1 then
				-- Recurse over next batch dim
				l_rows := res.shape [batch_indices.count + 1]
				from i := 1 until i > l_rows loop
					l_full_idx_res := batch_indices.deep_twin
					l_full_idx_res.force (i, l_full_idx_res.count + 1)
					perform_matvec (l_full_idx_res, res, vec)
					i := i + 1
				end
			else
				-- Base: batch_indices covers all batch dims of res; now compute the vector for each row i
				l_rows   := shape [shape.count - 1]    -- n
				l_common := shape [shape.count]         -- m
				create l_idx_v.make_filled (1, 1, 1)
				from i := 1 until i > l_rows loop
					check attached {G} numeric.zero_value as l_zero then
						l_sum := l_zero
					end
					create l_idx_a.make_from_array (batch_indices)
					l_idx_a.force (i, l_idx_a.count + 1)
					l_idx_a.force (1, l_idx_a.count + 1) -- Placeholder for k
					from k := 1 until k > l_common loop
						l_idx_a [l_idx_a.count] := k
						l_idx_v [1] := k
						l_sum := l_sum + item (l_idx_a) * vec.item (l_idx_v)
						k := k + 1
					end
					l_full_idx_res := batch_indices.deep_twin
					l_full_idx_res.force (i, l_full_idx_res.count + 1)
					res.put (l_sum, l_full_idx_res)
					i := i + 1
				end
			end
		end

	get_broadcast_item (batch_indices: ARRAY [INTEGER]; r, c: INTEGER; is_a: BOOLEAN; other: ET_TENSOR [G]): G
			-- Get element [batch..., r, c] from self (is_a=True) or other (is_a=False),
			-- applying batch broadcasting: if a batch dim of the source tensor is 1,
			-- always use index 1 regardless of what `batch_indices` says.
		local
			l_target_shape: ARRAY [INTEGER]
			l_full_indices: ARRAY [INTEGER]
			i: INTEGER
			l_target_dim_count: INTEGER
			l_batch_offset_diff: INTEGER
			l_result_batch_idx: INTEGER
		do
			if is_a then
				l_target_shape := shape
				l_target_dim_count := shape.count
			else
				l_target_shape := other.shape
				l_target_dim_count := other.shape.count
			end

			create l_full_indices.make_filled (1, 1, l_target_dim_count)

			-- Map result batch_indices (right-aligned) onto the source tensor batch dims.
			-- l_batch_offset_diff can be negative when the result has more batch dims than source;
			-- in that case the source has a "virtual" leading dim of 1 (broadcast), so we use 1.
			l_batch_offset_diff := batch_indices.count - (l_target_dim_count - 2)

			from i := 1 until i > (l_target_dim_count - 2) loop
				-- Which result batch index corresponds to source batch dim i?
				l_result_batch_idx := i + l_batch_offset_diff
				if l_result_batch_idx >= 1 and l_result_batch_idx <= batch_indices.count then
					-- Broadcast: if source dim is 1, clamp to 1
					if l_target_shape [i] = 1 then
						l_full_indices [i] := 1
					else
						l_full_indices [i] := batch_indices [l_result_batch_idx]
					end
				else
					-- Source has fewer batch dims than result: treat as size-1 (broadcast)
					l_full_indices [i] := 1
				end
				i := i + 1
			end

			-- Fill the last 2 (matrix) dimensions
			if l_target_dim_count >= 2 then
				l_full_indices [l_target_dim_count - 1] := r
				l_full_indices [l_target_dim_count]     := c
			elseif l_target_dim_count = 1 then
				l_full_indices [1] := c  -- treat 1D case
			end

			if is_a then
				Result := item (l_full_indices)
			else
				Result := other.item (l_full_indices)
			end
		end

feature -- View Operations

	transpose (dim1, dim2: INTEGER): ET_TENSOR [G]
			-- Return a view of the tensor with dimensions `dim1` and `dim2` swapped.
		require
			valid_dim1: dim1 >= 1 and dim1 <= shape.count
			valid_dim2: dim2 >= 1 and dim2 <= shape.count
		local
			l_new_shape: ARRAY [INTEGER]
			l_new_strides: ARRAY [INTEGER]
		do
			l_new_shape := shape.deep_twin
			l_new_strides := strides.deep_twin

			l_new_shape [dim1] := shape [dim2]
			l_new_shape [dim2] := shape [dim1]

			l_new_strides [dim1] := strides [dim2]
			l_new_strides [dim2] := strides [dim1]

			create Result.make_from_pointer (data, offset, l_new_shape, l_new_strides)
		ensure
			same_data: Result.data = data
		end

	slice (a_dim: INTEGER; index: INTEGER): ET_TENSOR [G]
			-- Return a view of the sub-tensor at `index` along dimension `a_dim`.
			-- If `index` is negative, it counts from the end (-1 is the last element).
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
			valid_index: (index >= 1 and index <= shape [a_dim]) or else (index < 0 and index.abs <= shape [a_dim])
		local
			l_actual_idx: INTEGER
		do
			if index < 0 then
				l_actual_idx := shape [a_dim] + index + 1
			else
				l_actual_idx := index
			end
			Result := narrow (a_dim, l_actual_idx, 1).squeeze (a_dim)
		end

	slice_range (a_dim: INTEGER; start_index: INTEGER; end_index: INTEGER): ET_TENSOR [G]
			-- Return a view representing a slice from `start_index` to `end_index` (inclusive).
			-- Indices can be negative (counting from the end).
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
		do
			Result := slice_step (a_dim, start_index, end_index, 1)
		end

	slice_step (a_dim: INTEGER; start_index: INTEGER; end_index: INTEGER; step: INTEGER): ET_TENSOR [G]
			-- Return a view representing a slice from `start_index` to `end_index` with `step` along `a_dim`.
			-- Indices can be negative (counting from the end).
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
			valid_step: step /= 0
		local
			l_start, l_end: INTEGER
			l_length: INTEGER
			l_new_shape: ARRAY [INTEGER]
			l_new_strides: ARRAY [INTEGER]
			l_new_offset: INTEGER
		do
			if start_index < 0 then
				l_start := shape [a_dim] + start_index + 1
			else
				l_start := start_index
			end

			if end_index < 0 then
				l_end := shape [a_dim] + end_index + 1
			else
				l_end := end_index
			end

			if step > 0 then
				if l_end < l_start then l_length := 0 else l_length := (l_end - l_start) // step + 1 end
			else
				if l_start < l_end then l_length := 0 else l_length := (l_start - l_end) // (-step) + 1 end
			end

			l_new_shape := shape.deep_twin
			l_new_shape [a_dim] := l_length

			l_new_strides := strides.deep_twin
			l_new_strides [a_dim] := strides [a_dim] * step

			l_new_offset := offset + (l_start - 1) * strides [a_dim]

			create Result.make_from_pointer (data, l_new_offset, l_new_shape, l_new_strides)
		end

feature -- Implementation

	view (a_new_shape: ARRAY [INTEGER]): ET_TENSOR [G]
			-- Return a new view with `a_new_shape`. Must be contiguous.
		require
			contiguous: is_contiguous
			compatible_size: (create {ET_TENSOR [G]}.make_zeros (a_new_shape)).numel = numel
		do
			create Result.make_from_pointer (data, offset, a_new_shape.deep_twin, (create {ET_TENSOR [G]}.make_zeros (a_new_shape)).strides)
		ensure
			same_data: Result.data = data
		end

	reshape (a_new_shape: ARRAY [INTEGER]): ET_TENSOR [G]
			-- Return a tensor with `a_new_shape`. Copies if not contiguous.
		require
			compatible_size: (create {ET_TENSOR [G]}.make_zeros (a_new_shape)).numel = numel
		do
			if is_contiguous then
				Result := view (a_new_shape)
			else
				-- Copy data to new contiguous tensor
				create Result.make_zeros (a_new_shape)
				copy_to_contiguous (Result.data)
			end
		end

	narrow (a_dim: INTEGER; start_index: INTEGER; length: INTEGER): ET_TENSOR [G]
			-- Return a view that acts as a slice along `dim`.
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
			valid_start: start_index >= 1
			valid_length: length >= 1
			in_bounds: start_index + length - 1 <= shape [a_dim]
		local
			l_new_shape: ARRAY [INTEGER]
			l_new_offset: INTEGER
		do
			l_new_shape := shape.deep_twin
			l_new_shape [a_dim] := length

			l_new_offset := offset + (start_index - 1) * strides [a_dim]

			create Result.make_from_pointer (data, l_new_offset, l_new_shape, strides.deep_twin)
		ensure
			same_data: Result.data = data
		end

	squeeze (a_dim: INTEGER): ET_TENSOR [G]
			-- Remove dimension `dim` if it is size 1.
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count
			is_singleton: shape [a_dim] = 1
		local
			l_new_shape: ARRAY [INTEGER]
			l_new_strides: ARRAY [INTEGER]
			i: INTEGER
		do
			create l_new_shape.make_empty
			create l_new_strides.make_empty

			from i := 1 until i > shape.count loop
				if i /= a_dim then
					l_new_shape.force (shape [i], l_new_shape.count + 1)
					l_new_strides.force (strides [i], l_new_strides.count + 1)
				end
				i := i + 1
			end

			create Result.make_from_pointer (data, offset, l_new_shape, l_new_strides)
		ensure
			same_data: Result.data = data
		end

	unsqueeze (a_dim: INTEGER): ET_TENSOR [G]
			-- Insert a dimension of size 1 at `a_dim`.
		require
			valid_dim: a_dim >= 1 and a_dim <= shape.count + 1
		local
			l_new_shape: ARRAY [INTEGER]
			l_new_strides: ARRAY [INTEGER]
			i: INTEGER
		do
			-- Array insert_at is not standard?
			-- Let's manual copy
			create l_new_shape.make_filled (0, 1, shape.count + 1)
			create l_new_strides.make_filled (0, 1, shape.count + 1)

			from i := 1 until i > shape.count + 1 loop
				if i < a_dim then
					l_new_shape [i] := shape [i]
					l_new_strides [i] := strides [i]
				elseif i = a_dim then
					l_new_shape [i] := 1
					-- Stride for size 1 can be anything, let's use the stride of the *next* logical element would be safe
					if i < shape.count + 1 then
						l_new_strides [i] := strides [i]
					else
						l_new_strides [i] := 1 -- End
					end
				else
					l_new_shape [i] := shape [i - 1]
					l_new_strides [i] := strides [i - 1]
				end
				i := i + 1
			end

			create Result.make_from_pointer (data, offset, l_new_shape, l_new_strides)
		ensure
			same_data: Result.data = data
		end

	calc_strides
			-- Calculate standard contiguous strides based on shape.
		local
			i: INTEGER
			acc: INTEGER
			
		do
			create strides.make_filled (0, 1, shape.count)
			

			acc := numeric.element_size

			from i := shape.count until i < 1 loop
				strides [i] := acc
				acc := acc * shape [i]
				i := i - 1
			end
		end

	numel: INTEGER
			-- Total number of elements.
		local
			i: INTEGER
		do
			Result := 1
			from i := 1 until i > shape.count loop
				Result := Result * shape [i]
				i := i + 1
			end
		end

	calculate_offset (indices: ARRAY [INTEGER]): INTEGER
			-- Byte offset for indices.
		local
			i: INTEGER
		do
			Result := 0
			from i := 1 until i > indices.count loop
				Result := Result + (indices [i] - 1) * strides [i]
				i := i + 1
			end
		end

	internal_op_tensor (a, b, res: ET_TENSOR [G]; op: FUNCTION [G, G, G])
			-- Helper for element-wise operations.
			-- Naive recursion for N-dim.
		local
			indices: ARRAY [INTEGER]
		do
			create indices.make_filled (1, 1, res.shape.count)
			recursive_apply (1, indices, a, b, res, op)
		end

	recursive_apply (a_dim: INTEGER; indices: ARRAY [INTEGER]; a, b, res: ET_TENSOR [G]; op: FUNCTION [G, G, G])
		local
			i: INTEGER
		do
			if a_dim > res.shape.count then
				res.put (op.item ([a.item (indices), b.item (indices)]), indices)
			else
				from i := 1 until i > res.shape [a_dim] loop
					indices [a_dim] := i
					recursive_apply (a_dim + 1, indices, a, b, res, op)
					i := i + 1
				end
			end
		end

	copy_to_contiguous (a_ptr: MANAGED_POINTER)
			-- Copy self to contiguous pointer.
		local
			l_indices: ARRAY [INTEGER]
			
			l_dummy: INTEGER
		do
			
			create l_indices.make_filled (1, 1, shape.count)
			l_dummy := recursive_copy_to_ptr (1, l_indices, 0, a_ptr)
		end

	recursive_copy_to_ptr (a_dim: INTEGER; indices: ARRAY [INTEGER]; a_linear_offset: INTEGER; a_ptr: MANAGED_POINTER): INTEGER
			-- Returns new linear offset
		local
			i: INTEGER
			l_current_offset: INTEGER
			l_val: G
		do
			l_current_offset := a_linear_offset
			if a_dim > shape.count then
				l_val := item (indices)

				if ({G}).type_id = ({REAL_32}).type_id then
					if attached {REAL_32} l_val as r32 then
						numeric.put (a_ptr, l_current_offset, numeric.from_real_64(r32.to_double))
					end
				elseif ({G}).type_id = ({REAL_64}).type_id then
					if attached {REAL_64} l_val as r64 then
						numeric.put (a_ptr, l_current_offset, numeric.from_real_64(r64))
					end
				elseif ({G}).type_id = ({INTEGER_32}).type_id then
					if attached {INTEGER_32} l_val as i32 then
						numeric.put (a_ptr, l_current_offset, numeric.from_integer(i32))
					end
				elseif ({G}).type_id = ({INTEGER_64}).type_id then
					if attached {INTEGER_64} l_val as i64 then
						numeric.put (a_ptr, l_current_offset, numeric.from_integer(i64.to_integer_32))
					end
				end

				l_current_offset := l_current_offset + numeric.element_size
			else
				from i := 1 until i > shape [a_dim] loop
					indices [a_dim] := i
					l_current_offset := recursive_copy_to_ptr (a_dim + 1, indices, l_current_offset, a_ptr)
					i := i + 1
				end
			end
			Result := l_current_offset
		end

feature -- Output

	out: STRING
		local
			l_any: ANY
		do
			Result := "tensor("
			if shape.is_empty then
				l_any := item_scalar
				Result.append (l_any.out)
			else
				Result.append (recursive_to_string (1, create {ARRAY [INTEGER]}.make_empty))
			end
			Result.append (")")
		end

    show_shape: STRING
            -- String representation of the tensor's shape.
        local
            i: INTEGER
        do
            create Result.make_empty
            Result.append ("[")
            from i := 1 until i > shape.count loop
                Result.append (shape [i].out)
                if i < shape.count then
                    Result.append (", ")
                end
                i := i + 1
            end
            Result.append ("]")
        end

feature {NONE} -- Output Helper

	recursive_to_string (dim_idx: INTEGER; indices: ARRAY [INTEGER]): STRING
		local
			i: INTEGER
			l_indices_copy: ARRAY [INTEGER]
			l_val: G
			l_any: ANY
		do
			create Result.make_empty

			if dim_idx > shape.count then
				-- Leaf: Data item
				l_val := item (indices)
				l_any := l_val
				if ({G}).type_id = ({REAL_32}).type_id or ({G}).type_id = ({REAL_64}).type_id then
					-- Simple formatting for floats to avoid excessive precision if whole number
					-- Result.append (l_val.out)
					-- Actually standard out is fine for now.
					Result.append (l_any.out)
				else
					Result.append (l_any.out)
				end
			else
				Result.append ("[")
				from i := 1 until i > shape [dim_idx] loop
					l_indices_copy := indices.deep_twin
					l_indices_copy.force (i, l_indices_copy.count + 1)

					Result.append (recursive_to_string (dim_idx + 1, l_indices_copy))

					if i < shape [dim_idx] then
						Result.append (", ")
					end
					i := i + 1
				end
				Result.append ("]")
			end
		end

end

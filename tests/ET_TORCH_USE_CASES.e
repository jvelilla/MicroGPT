note
    description: "PyTorch Use Cases implemented in Eiffel."

class
    ET_TORCH_USE_CASES

feature -- Tests

    from_existing_data
            -- 1.1 From Existing Data Structures
        local
            x: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_data: ARRAY [INTEGER]
        do
            print ("%N[1.1] From Existing Data Structures ( List -> Tensor)%N")

            -- x = torch.tensor([1, 2, 3])
            l_data := <<1, 2, 3>>
            create x.make_from_integer_array (l_data)

            print ("FROM ITERABLE: " + x.out + "%N")
            print ("TENSOR DIM: " + x.dim.out + "%N")
            print ("TENSOR SIZE(1): " + x.size(1).out + "%N")
            print ("TENSOR NUMEL: " + x.numel.out + "%N")
        end

    with_predefined_values
            -- 1.2 With Predefined Values
        local
            zeros: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            ones: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            rand: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
        do
            print ("%NWith Predefined Values (Zeros)%N")

            -- zeros = torch.zeros(2, 3)
            create zeros.make_zeros (<<2, 3>>)

            print ("TENSOR WITH ZEROS:%N%N" + zeros.out + "%N")
 			print ("TENSOR DIM: " + zeros.dim.out + "%N")
 			print ("TENSOR NUMEL: " + zeros.numel.out + "%N")


			print ("%NWith Predefined Values (Ones)%N")

 			create ones.make_ones (<<2, 3>>)

            print ("TENSOR WITH ONES:%N" + ones.out + "%N")
 			print ("TENSOR DIM: " + ones.dim.out + "%N")
 			print ("TENSOR NUMEL: " + ones.numel.out + "%N")


 			print ("%NWith Predefined Values (RandN)%N")

 			create rand.make_randn (<<2, 3>>)

            print ("TENSOR WITH ONES:%N" + rand.out + "%N")
 			print ("TENSOR DIM: " + rand.dim.out + "%N")
 			print ("TENSOR NUMEL: " + rand.numel.out + "%N")


        end

    checking_tensor_dimensions
            -- 2.1 Checking a Tensor's Dimensions
        local
            x: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_data: ARRAY [INTEGER]
        do
            print ("%N[2.1] Checking a Tensor's Dimensions%N")

            -- A 2D tensor
            -- x = torch.tensor([[1, 2, 3],
            --                   [4, 5, 6]])
            l_data := <<1, 2, 3, 4, 5, 6>>
            create x.make_from_integer_array (l_data)
            x := x.reshape (<<2, 3>>)

            print ("ORIGINAL TENSOR:%N%N")
            print (x.out + "%N")
            print ("%NTENSOR SHAPE: " + x.show_shape + "%N")
        end

    changing_tensor_dimensions
            -- 2.2 Changing a Tensor's Dimensions
        local
            x, l_expanded, local_squeezed: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_data: ARRAY [INTEGER]
        do
            print ("%N[2.2] Changing a Tensor's Dimensions%N")

            -- A 2D tensor
            -- x = torch.tensor([[1, 2, 3],
            --                   [4, 5, 6]])
            l_data := <<1, 2, 3, 4, 5, 6>>
            create x.make_from_integer_array (l_data)
            x := x.reshape (<<2, 3>>)

            print ("ORIGINAL TENSOR:%N%N")
            print (x.out + "%N")

            print ("%NTENSOR SHAPE: " + x.show_shape + "%N")
            print ("---------------------------------------------%N")

            -- Add dimension
            l_expanded := x.unsqueeze (1) -- Add dimension at index 1 (1-based index in Eiffel, equivalent to 0 in PyTorch)

            print ("%NTENSOR WITH ADDED DIMENSION AT INDEX 1:%N%N")
            print (l_expanded.out + "%N")

            print ("%NTENSOR SHAPE: " + l_expanded.show_shape + "%N")

            print ("---------------------------------------------%N")

            -- Remove dimension
            -- In PyTorch `squeeze` removes all dims of size 1 if no dim is specified
            -- TENSOR.squeeze currently takes an explicit dim, so we pass 1 to remove the added dimension
            local_squeezed := l_expanded.squeeze (1)

            print ("%NTENSOR WITH DIMENSION REMOVED:%N%N")
            print (local_squeezed.out + "%N")

            print ("%NTENSOR SHAPE: " + local_squeezed.show_shape + "%N")
        end

    restructuring_tensor_dimensions
            -- 2.3 Restructuring
        local
            x, reshaped, transposed: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_data: ARRAY [INTEGER]
        do
            print ("%N[2.3] Restructuring%N")

            -- A 2D tensor
            -- x = torch.tensor([[1, 2, 3],
            --                   [4, 5, 6]])
            l_data := <<1, 2, 3, 4, 5, 6>>
            create x.make_from_integer_array (l_data)
            x := x.reshape (<<2, 3>>)

            print ("ORIGINAL TENSOR:%N%N")
            print (x.out + "%N")
            print ("%NTENSOR SHAPE: " + x.show_shape + "%N")
            print ("---------------------------------------------%N")

            -- Reshape
            reshaped := x.reshape (<<3, 2>>)

            print ("%NAFTER PERFORMING reshape(3, 2):%N%N")
            print (reshaped.out + "%N")
            print ("%NTENSOR SHAPE: " + reshaped.show_shape + "%N")

            print ("---------------------------------------------%N")
            
            -- Transpose
            transposed := x.transpose (1, 2)

            print ("%NAFTER PERFORMING transpose(1, 2):%N%N")
            print (transposed.out + "%N")
            print ("%NTENSOR SHAPE: " + transposed.show_shape + "%N")
        end

    combining_tensors
            -- 2.4 Combining Tensors
        local
            tensor_a, tensor_b, concatenated_tensors: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
        do
            print ("%N[2.4] Combining Tensors%N")
            
            -- x = torch.tensor([[1, 2], [3, 4]])
            create tensor_a.make_from_integer_array (<<1, 2, 3, 4>>)
            tensor_a := tensor_a.reshape (<<2, 2>>)

            -- y = torch.tensor([[5, 6], [7, 8]])
            create tensor_b.make_from_integer_array (<<5, 6, 7, 8>>)
            tensor_b := tensor_b.reshape (<<2, 2>>)
            
            print ("TENSOR A:%N%N" + tensor_a.out + "%N")
            print ("%NTENSOR B:%N%N" + tensor_b.out + "%N")
            print ("---------------------------------------------%N")
            
            -- Concatenate along columns (dim=2 in Eiffel, 1-based index)
            concatenated_tensors := tensor_a.cat (<<tensor_a, tensor_b>>, 2)
            
            print ("%NCONCATENATED TENSOR (dim=2):%N%N")
            print (concatenated_tensors.out + "%N")
            print ("%NTENSOR SHAPE: " + concatenated_tensors.show_shape + "%N")
        end

    accessing_elements
            -- 3.1 Accessing Elements
        local
            x, second_row, last_row, single_element_tensor: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            value: INTEGER
            l_data: ARRAY [INTEGER]
        do
            print ("%N[3.1] Accessing Elements%N")

            -- Create a 3x4 tensor
            l_data := <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12>>
            create x.make_from_integer_array (l_data)
            x := x.reshape (<<3, 4>>)
            
            print ("ORIGINAL TENSOR:%N%N")
            print (x.out + "%N")
            print ("-------------------------------------------------------%N")

            -- Get a single element at row 1, column 2 (0-based in PyTorch -> 1-based in Eiffel: row 2, col 3)
            -- Slicing dimension 1 (row 2) then dimension 1 again (col 3 of the remaining 1D tensor)
            single_element_tensor := x.slice (1, 2).slice (1, 3)
            
            print ("%NINDEXING SINGLE ELEMENT AT [1, 2]: " + single_element_tensor.out + "%N")
            print ("-------------------------------------------------------%N")

            -- Get the entire second row (index 1 in PyTorch -> index 2 in Eiffel)
            second_row := x.slice (1, 2)

            print ("%NINDEXING ENTIRE ROW [1]: " + second_row.out + "%N")
            print ("-------------------------------------------------------%N")

            -- Last row
            last_row := x.slice (1, -1)

            print ("%NINDEXING ENTIRE LAST ROW ([-1]): " + last_row.out + " %N")
            print ("-------------------------------------------------------%N")
            
            print ("%NSINGLE-ELEMENT TENSOR: " + single_element_tensor.out + "%N")
            print ("---------------------------------------------%N")
            
            -- Extract the value from a single-element tensor as a standard Eiffel number
            value := single_element_tensor.item_scalar.item
            
            print ("%N.item_scalar() NUMBER EXTRACTED: " + value.out + "%N")
            print ("TYPE: INTEGER%N")
        end

    slicing_tensors
            -- 3.2 Slicing Tensors
        local
            x, first_two_rows, third_column, every_other_col, last_col, combined: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_data: ARRAY [INTEGER]
        do
            print ("%N[3.2] Slicing Tensors%N")

            -- Create a 3x4 tensor
            l_data := <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12>>
            create x.make_from_integer_array (l_data)
            x := x.reshape (<<3, 4>>)
            
            print ("ORIGINAL TENSOR:%N%N")
            print (x.out + "%N")
            print ("-------------------------------------------------------%N")

            -- Get the first two rows (PyTorch: x[0:2] -> Eiffel: row 1 to 2)
            first_two_rows := x.slice_range (1, 1, 2)

            print ("%NSLICING FIRST TWO ROWS ([0:2]):%N%N")
            print (first_two_rows.out + "%N")
            print ("-------------------------------------------------------%N")

            -- Get the third column of all rows (PyTorch: x[:, 2] -> Eiffel: col 3)
            third_column := x.slice (2, 3)

            print ("%NSLICING THIRD COLUMN ([:, 2]): tensor(" + third_column.out + ")%N")
            print ("-------------------------------------------------------%N")

            -- Every other column (PyTorch: x[:, ::2] -> Eiffel: cols step 2)
            every_other_col := x.slice_step (2, 1, -1, 2)

            print ("%NEVERY OTHER COLUMN ([:, ::2]):%N%N")
            print (every_other_col.out + "%N")
            print ("-------------------------------------------------------%N")

            -- Last column (PyTorch: x[:, -1] -> Eiffel: col -1)
            last_col := x.slice (2, -1)

            print ("%NLAST COLUMN ([:, -1]): tensor(" + last_col.out + ") %N")
            print ("-------------------------------------------------------%N")

            -- Combining slicing and indexing (First two rows, last two columns)
            combined := x.slice_range(1, 1, 2).slice_range(2, 3, -1)

            print ("%NFIRST TWO ROWS, LAST TWO COLS ([0:2, 2:]):%N%N")
            print (combined.out + " %N")
        end

    arithmetic_operations
            -- 4.1 Arithmetic
        local
            a, b, element_add, element_mul: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
        do
            print ("%N[4.1] Arithmetic%N")

            -- a = torch.tensor([1, 2, 3])
            create a.make_from_integer_array (<<1, 2, 3>>)
            a := a.reshape (<<3>>)

            -- b = torch.tensor([4, 5, 6])
            create b.make_from_integer_array (<<4, 5, 6>>)
            b := b.reshape (<<3>>)

            print ("TENSOR A: " + a.out + "%N")
            print ("TENSOR B: " + b.out + "%N")
            print ("------------------------------------------------------------%N")

            -- Element-wise addition
            element_add := a + b

            print ("%NAFTER PERFORMING ELEMENT-WISE ADDITION: " + element_add.out + " %N%N")

            print ("TENSOR A: " + a.out + "%N")
            print ("TENSOR B: " + b.out + "%N")
            print ("-----------------------------------------------------------------%N")

            -- Element-wise multiplication
            element_mul := a * b

            print ("%NAFTER PERFORMING ELEMENT-WISE MULTIPLICATION: " + element_mul.out + " %N%N")

            print ("TENSOR A: " + a.out + "%N")
            print ("TENSOR B: " + b.out + "%N")
            print ("-----------------------------------------------------------------%N")

            -- Dot product
            element_mul := a.matmul (b)

            print ("%NAFTER PERFORMING DOT PRODUCT: " + element_mul.out + " %N")
        end

    broadcasting_tensors
            -- 4.2 Broadcasting
        local
            a, b, c: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
        do
            print ("%N[4.2] Broadcasting%N")

            -- a = torch.tensor([1, 2, 3])
            create a.make_from_integer_array (<<1, 2, 3>>)
            a := a.reshape (<<3>>)

            -- b = torch.tensor([[1], [2], [3]])
            create b.make_from_integer_array (<<1, 2, 3>>)
            b := b.reshape (<<3, 1>>)
            
            print ("TENSOR A: " + a.out + "%N")
            print ("SHAPE: " + a.show_shape + "%N")
            print ("%NTENSOR B%N%N" + b.out + "%N")
            print ("%NSHAPE: " + b.show_shape + "%N")
            print ("-----------------------------------------------------------------%N")

            -- Apply broadcasting
            c := a + b

            print ("%NTENSOR C:%N%N" + c.out + "%N")
            print ("%NSHAPE: " + c.show_shape + " %N")
        end

    logic_and_comparisons
            -- 4.2 Logic & Comparisons
        local
            temperatures: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            is_hot, is_cool, is_35_degrees: ET_TENSOR [ET_BOOLEAN_ELEMENT]
            is_morning, is_raining: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            morning_and_raining, morning_or_raining: ET_TENSOR [ET_BOOLEAN_ELEMENT]
            l_scalar: ET_NUMERIC_ELEMENT [INTEGER_32]
        do
            print ("%N[4.2] Logic & Comparisons%N")

            -- temperatures = torch.tensor([20, 35, 19, 35, 42])
            create temperatures.make_from_integer_array (<<20, 35, 19, 35, 42>>)
            temperatures := temperatures.reshape (<<5>>)

            print ("TEMPERATURES: " + temperatures.out + "%N")
            print ("--------------------------------------------------%N")

            -- Use '>' (greater than) to find temperatures above 30
            l_scalar.set_item (30)
            is_hot := temperatures > l_scalar

            -- Use '<=' (less than or equal to) to find temperatures 20 or below
            l_scalar.set_item (20)
            is_cool := temperatures <= l_scalar

            -- Use '|==' (equal to) to find temperatures exactly equal to 35
            l_scalar.set_item (35)
            is_35_degrees := temperatures |== l_scalar

            print ("%NHOT (> 30 DEGREES): " + is_hot.out + "%N")
            print ("COOL (<= 20 DEGREES): " + is_cool.out + "%N")
            print ("EXACTLY 35 DEGREES: " + is_35_degrees.out + " %N")

            print ("--------------------------------------------------%N")
            
            print ("%N### Logical Operators (&, |)%N%N")

            -- Use '&' (AND) to find when it's both morning and raining
            -- Both are 1 (True) or 0 (False)
            create is_morning.make_from_integer_array (<<1, 0, 0, 1>>)
            is_morning := is_morning.reshape (<<4>>)
            
            create is_raining.make_from_integer_array (<<0, 0, 1, 1>>)
            is_raining := is_raining.reshape (<<4>>)

            print ("IS MORNING: " + is_morning.out + "%N")
            print ("IS RAINING: " + is_raining.out + "%N")
            print ("--------------------------------------------------%N")

            morning_and_raining := is_morning & is_raining
            morning_or_raining := is_morning | is_raining

            print ("%NMORNING & (AND) RAINING: " + morning_and_raining.out + "%N")
            print ("MORNING | (OR) RAINING: " + morning_or_raining.out + "%N")
        end

    statistics
            -- 4.3 Statistics
        local
            data: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            data_mean, data_std: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            l_float_data: ARRAY [REAL_64]
        do
            print ("%N[4.3] Statistics%N")

            -- data = torch.tensor([10.0, 20.0, 30.0, 40.0, 50.0])
            l_float_data := <<10.0, 20.0, 30.0, 40.0, 50.0>>
            create data.make_from_real_64_array (l_float_data)
            data := data.reshape (<<5>>)

            print ("DATA: " + data.out + "%N")
            print ("---------------------------------------------%N")

            -- Calculate the mean
            data_mean := data.mean

            print ("%NCALCULATED MEAN: " + data_mean.out + " %N%N")

            print ("DATA: " + data.out + "%N")
            print ("---------------------------------------------%N")

            -- Calculate the standard deviation
            data_std := data.std

            print ("%NCALCULATED STD: " + data_std.out + " %N")
        end

    matmul_operations
            -- 5.1 Matrix Operations (extended matmul cases)
        local
            A, B, C: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            v, mv_result: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            bA, bB, bC: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            At, AtB: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
        do
            print ("%N[5.1] Matrix Operations%N")

            -- ── 2D x 2D: (2,3) @ (3,2) → (2,2)
            -- A = [[1,2,3],[4,5,6]]
            create A.make_from_integer_array (<<1, 2, 3, 4, 5, 6>>)
            A := A.reshape (<<2, 3>>)
            -- B = [[7,8],[9,10],[11,12]]
            create B.make_from_integer_array (<<7, 8, 9, 10, 11, 12>>)
            B := B.reshape (<<3, 2>>)
            C := A.matmul (B)
            print ("A @ B  (2,3)x(3,2) -> (2,2):%N" + C.out + "%N")
            print ("SHAPE: " + C.show_shape + "%N")
            print ("---------------------------------------------%N")

            -- ── Matrix-vector: (2,3) @ (3,) → (2,)
            -- v = [1, 0, 0]   → result is first column of A
            create v.make_from_integer_array (<<1, 0, 0>>)
            mv_result := A.matmul (v)
            print ("A @ v  (2,3)x(3,) -> (2,):%N" + mv_result.out + "%N")
            print ("SHAPE: " + mv_result.show_shape + "%N")
            print ("---------------------------------------------%N")

            -- ── Batched: (2,2,3) @ (2,3,2) → (2,2,2)
            create bA.make_ones (<<2, 2, 3>>)
            create bB.make_ones (<<2, 3, 2>>)
            bC := bA.matmul (bB)
            -- each 2x3 @ 3x2 of ones => 2x2 matrix of 3s
            print ("bA @ bB  (2,2,3)x(2,3,2) -> (2,2,2):%N" + bC.out + "%N")
            print ("SHAPE: " + bC.show_shape + "%N")
            print ("---------------------------------------------%N")

            -- ── Broadcast batch: (1,2,3) @ (2,3,2) → (2,2,2)
            create bA.make_ones (<<1, 2, 3>>)
            bC := bA.matmul (bB)
            print ("bA @ bB  (1,2,3)x(2,3,2) -> (2,2,2) [broadcast]:%N" + bC.out + "%N")
            print ("SHAPE: " + bC.show_shape + "%N")
            print ("---------------------------------------------%N")

            -- ── Transposed (strided) operand: A^T @ A
            -- A (2,3), A^T (3,2) → (3,3)
            At := A.transpose (1, 2)
            AtB := At.matmul (A)
            print ("A^T @ A  (3,2)x(2,3) -> (3,3):%N" + AtB.out + "%N")
            print ("SHAPE: " + AtB.show_shape + "%N")
        end

end

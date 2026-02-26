note
	description: "Tests for ET_SAFE_TENSORS_LOADER and ET_MEMORY_MAP classes."

class
	ET_TEST_SAFE_TENSORS

inherit
	EQA_TEST_SET

feature -- Tests

	test_safetensors_mmap_load
		local
			loader: ET_SAFE_TENSORS_LOADER
			file: RAW_FILE
			t: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
			path: PATH
			header: STRING_8
			header_size: INTEGER_64
			tol: REAL_64
			val: REAL_32
			mp: MANAGED_POINTER
		do
			print ("  [TEST] Safetensors MMAP Zero-Copy Load... ")
			tol := 1.0e-5

			-- 1. Create a dummy .safetensors file with a JSON header
			create path.make_from_string ("test_mmap_dummy.safetensors")
			create file.make_with_path (path)
			if file.exists then
				file.delete
			end
			file.open_write

			-- Header JSON describing a tensor "test_weight" of shape [2, 2]
			header := "[
				{
					"test_weight": {
						"dtype": "F32",
						"shape": [2, 2],
						"data_offsets": [0, 16]
					},
					"__metadata__": {
						"format": "pt"
					}
				}
			]"
			-- Pad string with spaces so its length is a multiple of 8 (Safetensors spec)
			from until header.count \\ 8 = 0 loop
				header.append_character (' ')
			end

			header_size := header.count.to_integer_64
			file.put_integer_64 (header_size)
			file.put_string (header)

			-- 2. Write 4 REAL_32 values directly (16 bytes total)
			create mp.make (16)
			mp.put_real_32_le ({REAL_32} 1.5, 0)
			mp.put_real_32_le ({REAL_32} 2.5, 4)
			mp.put_real_32_le ({REAL_32} 3.5, 8)
			mp.put_real_32_le ({REAL_32} 4.5, 12)
			
			file.put_managed_pointer (mp, 0, 16)
			file.close

			-- 3. Use Loader to map and load
			create loader.make
			t := loader.load_tensor (path, "test_weight")

			assert ("Tensor successfully loaded", t /= Void)
			if attached t then
				assert ("Shape is 2x2", t.shape[1] = 2 and t.shape[2] = 2)

				val := t.item (<<1, 1>>).item
				assert_approx_32 (val, 1.5, tol, "t[1,1] = 1.5")
				
				val := t.item (<<1, 2>>).item
				assert_approx_32 (val, 2.5, tol, "t[1,2] = 2.5")
				
				val := t.item (<<2, 1>>).item
				assert_approx_32 (val, 3.5, tol, "t[2,1] = 3.5")
				
				val := t.item (<<2, 2>>).item
				assert_approx_32 (val, 4.5, tol, "t[2,2] = 4.5")
			end

			print ("OK%N")
			
			-- Clean up
			file.delete
		end

	assert_approx_32 (actual: REAL_32; expected: REAL_64; tol: REAL_64; msg: STRING)
		do
			assert (msg + " Expected " + expected.out + " but got " + actual.out, (actual.to_double - expected).abs <= tol)
		end

end

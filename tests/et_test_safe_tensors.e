note
    description: "Tests for SAFE_TENSORS_LOADER."

class
    ET_TEST_SAFE_TENSORS

inherit
    EQA_TEST_SET
        redefine
            on_clean
        end

feature -- Initialization

    on_clean
        local
            f: RAW_FILE
        do
            create f.make_with_name ("test_model.safetensors")
            if f.exists then
                f.delete
            end
        end

feature -- Tests

    test_safetensors_loading
        local
            loader: ET_SAFE_TENSORS_LOADER
            t: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            f: RAW_FILE
            header_json: STRING
            header_size: INTEGER_64
            dummy_data: MANAGED_POINTER
            path: PATH
        do
            print ("%N[TEST] SafeTensors Loading... ")

            -- 1. Create a dummy safetensors file
            -- Header: {"test_tensor": {"dtype": "F32", "shape": [2, 2], "data_offsets": [0, 16]}}
            -- Length: 85 bytes
            header_json := "{%"test_tensor%": {%"dtype%": %"F32%", %"shape%": [2, 2], %"data_offsets%": [0, 16]}}"

            header_size := header_json.count.to_integer_64

            create f.make_with_name ("test_model.safetensors")
            f.open_write
            f.put_integer_64 (header_size)
            f.put_string (header_json)

            -- Write dummy data (1.0, 2.0, 3.0, 4.0)
            create dummy_data.make (16)
            dummy_data.put_real_32_le (1.0, 0)
            dummy_data.put_real_32_le (2.0, 4)
            dummy_data.put_real_32_le (3.0, 8)
            dummy_data.put_real_32_le (4.0, 12)
            f.put_managed_pointer (dummy_data, 0, 16)
            f.close

            -- 2. Load it
            create path.make_from_string ("test_model.safetensors")
            create loader.make
            t := loader.load_tensor (path, "test_tensor")

            -- 3. Verify
            assert ("Tensor loaded", t /= Void)
            if attached t as tensor then
                assert ("Shape dim 1 is 2", tensor.shape [1] = 2)
                assert ("Shape dim 2 is 2", tensor.shape [2] = 2)

                -- Check values with tolerance
                assert ("Value at 1,1 is 1.0", (tensor.item (<<1, 1>>).item - 1.0).abs < 1.0e-6)
                assert ("Value at 1,2 is 2.0", (tensor.item (<<1, 2>>).item - 2.0).abs < 1.0e-6)
                assert ("Value at 2,1 is 3.0", (tensor.item (<<2, 1>>).item - 3.0).abs < 1.0e-6)
                assert ("Value at 2,2 is 4.0", (tensor.item (<<2, 2>>).item - 4.0).abs < 1.0e-6)
            end

            print ("OK%N")
        end

end

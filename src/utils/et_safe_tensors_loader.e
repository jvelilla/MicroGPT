note
    description: "Loader for Safetensors format (Zero-Copy using MANAGED_POINTER)."

class
    ET_SAFE_TENSORS_LOADER

create
    make

feature -- Initialization

    make
        do
        end

feature -- Access

    load_tensor (a_path: PATH; key: READABLE_STRING_GENERAL): detachable ET_TENSOR [REAL_32]
            -- Load a tensor by key from the safetensors file.
        local
            file: RAW_FILE
            header_size: INTEGER_64
            header_json: STRING
            
            data_offset: INTEGER
            tensor_data_start: INTEGER
            
            parser: JSON_PARSER
        do
            create file.make_with_path (a_path)
            if file.exists then
                file.open_read

                if file.count > 8 then
                    file.read_integer_64
                    header_size := file.last_integer_64
                    
                    if header_size > 0 then
                        -- Read header
                        file.read_stream (header_size.to_integer_32)
                        header_json := file.last_string
                        
                        -- Parse JSON header
                        create parser.make_with_string (header_json)
                        parser.parse_content
                        
                        if parser.is_valid and then attached {JSON_OBJECT} parser.parsed_json_value as j_obj then
                             if attached {JSON_OBJECT} j_obj.item (key) as info then
                                 -- Calculate absolute offset
                                 data_offset := 8 + header_size.to_integer_32
                                 
                                 if attached {JSON_ARRAY} info.item ("data_offsets") as j_offsets and then j_offsets.count >= 2 and then
                                    attached {JSON_NUMBER} j_offsets.i_th (1) as start_off and then
                                    attached {JSON_NUMBER} j_offsets.i_th (2) as end_off 
                                 then
                                     tensor_data_start := data_offset + start_off.integer_64_item.to_integer_32
                                     
                                     if attached {JSON_ARRAY} info.item ("shape") as j_shape then
                                         file.go (tensor_data_start)
                                         -- Create Tensor directly from file read
                                         Result := create_tensor_from_file (file, json_array_to_integer_array (j_shape), (end_off.integer_64_item - start_off.integer_64_item).to_integer_32)
                                     end
                                 end
                             end
                        end
                    end
                end
                
                file.close
            end
        end

feature {NONE} -- Implementation

    create_tensor_from_file (f: RAW_FILE; shape: ARRAY [INTEGER]; byte_len: INTEGER): ET_TENSOR [REAL_32]
        local
            mp: MANAGED_POINTER
        do
            create mp.make (byte_len)
            f.read_to_managed_pointer (mp, 0, byte_len)
            create Result.make_from_pointer (mp, 0, shape, default_strides (shape))
        end

    default_strides (shape: ARRAY [INTEGER]): ARRAY [INTEGER]
        local
            i, acc: INTEGER
        do
            create Result.make_filled (0, 1, shape.count)
            acc := 4 -- F32
            from i := shape.count until i < 1 loop
                Result [i] := acc
                acc := acc * shape [i]
                i := i - 1
            end
        end

    json_array_to_integer_array (j_array: JSON_ARRAY): ARRAY [INTEGER]
        local
            i: INTEGER
        do
            create Result.make_filled (0, 1, j_array.count)
            from i := 1 until i > j_array.count loop
                if attached {JSON_NUMBER} j_array.i_th (i) as j_num then
                    Result [i] := j_num.integer_64_item.to_integer_32
                end
                i := i + 1
            end
        end

end

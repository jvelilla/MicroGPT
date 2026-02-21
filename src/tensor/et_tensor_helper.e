note
	description: "Helper for TENSOR to handle type-specific operations and pointer arithmetic."

class
	ET_TENSOR_HELPER

feature -- Access

	element_size (a_type_id: INTEGER): INTEGER
			-- Size in bytes for the given type ID.
		do
			if a_type_id = ({REAL_32}).type_id then
				Result := 4
			elseif a_type_id = ({REAL_64}).type_id then
				Result := 8
			elseif a_type_id = ({INTEGER_32}).type_id then
				Result := 4
			elseif a_type_id = ({INTEGER_64}).type_id then
				Result := 8
			else
				-- Fallback or error
				Result := 0
			end
		end

	is_supported_type (a_type_id: INTEGER): BOOLEAN
			-- Is the type supported by TENSOR?
		do
			Result := a_type_id = ({REAL_32}).type_id or else
					  a_type_id = ({REAL_64}).type_id or else
					  a_type_id = ({INTEGER_32}).type_id or else
					  a_type_id = ({INTEGER_64}).type_id
		end

	zero_value (a_type_id: INTEGER): ANY
			-- Return zero value for the given type.
		do
			if a_type_id = ({REAL_32}).type_id then
				Result := {REAL_32} 0.0
			elseif a_type_id = ({REAL_64}).type_id then
				Result := {REAL_64} 0.0
			elseif a_type_id = ({INTEGER_32}).type_id then
				Result := {INTEGER_32} 0
			elseif a_type_id = ({INTEGER_64}).type_id then
				Result := {INTEGER_64} 0
			else
				Result := 0 -- check this
			end
		end

	one_value (a_type_id: INTEGER): ANY
			-- Return zero value for the given type.
		do
			if a_type_id = ({REAL_32}).type_id then
				Result := {REAL_32} 1.0
			elseif a_type_id = ({REAL_64}).type_id then
				Result := {REAL_64} 1.0
			elseif a_type_id = ({INTEGER_32}).type_id then
				Result := {INTEGER_32} 1
			elseif a_type_id = ({INTEGER_64}).type_id then
				Result := {INTEGER_64} 1
			else
				Result := 1 -- check this
			end
		end

	from_integer (v: INTEGER; a_type_id: INTEGER): ANY
			-- Convert integer `v` to type `a_type_id`.
		do
			if a_type_id = ({REAL_32}).type_id then
				Result := v.to_real
			elseif a_type_id = ({REAL_64}).type_id then
				Result := v.to_double
			elseif a_type_id = ({INTEGER_32}).type_id then
				Result := v.to_integer_32
			elseif a_type_id = ({INTEGER_64}).type_id then
				Result := v.to_integer_64
			else
				Result := v
			end
		end

	from_real_64 (v: REAL_64; a_type_id: INTEGER): ANY
			-- Convert REAL_64 `v` to type `a_type_id`.
		do
			if a_type_id = ({REAL_32}).type_id then
				Result := v.truncated_to_real
			elseif a_type_id = ({REAL_64}).type_id then
				Result := v
			elseif a_type_id = ({INTEGER_32}).type_id then
				Result := v.truncated_to_integer
			elseif a_type_id = ({INTEGER_64}).type_id then
				Result := v.truncated_to_integer_64
			else
				Result := v
			end
		end

feature -- Pointer Operations

	put_real_32 (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: REAL_32)
		do
			a_ptr.put_real_32 (v, a_offset)
		end

	read_real_32 (a_ptr: MANAGED_POINTER; a_offset: INTEGER): REAL_32
		do
			Result := a_ptr.read_real_32 (a_offset)
		end

	put_real_64 (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: REAL_64)
		do
			a_ptr.put_real_64 (v, a_offset)
		end

	read_real_64 (a_ptr: MANAGED_POINTER; a_offset: INTEGER): REAL_64
		do
			Result := a_ptr.read_real_64 (a_offset)
		end

	put_integer_32 (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: INTEGER_32)
		do
			a_ptr.put_integer_32 (v, a_offset)
		end

	read_integer_32 (a_ptr: MANAGED_POINTER; a_offset: INTEGER): INTEGER_32
		do
			Result := a_ptr.read_integer_32 (a_offset)
		end

	put_integer_64 (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: INTEGER_64)
		do
			a_ptr.put_integer_64 (v, a_offset)
		end

	read_integer_64 (a_ptr: MANAGED_POINTER; a_offset: INTEGER): INTEGER_64
		do
			Result := a_ptr.read_integer_64 (a_offset)
		end

end

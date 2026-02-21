note
	description: "Deferred strategy for type-specific tensor operations."

deferred class
	ET_TENSOR_NUMERIC [G -> ET_TENSOR_ELEMENT]

feature -- Access

	element_size: INTEGER
			-- Size in bytes for the type.
		deferred
		end

	zero_value: G
			-- Return zero value for the type.
		deferred
		end

	one_value: G
			-- Return one value for the type.
		deferred
		end

feature -- Conversion

	from_integer (v: INTEGER): G
			-- Convert integer `v` to type G.
		deferred
		end

	from_real_64 (v: REAL_64): G
			-- Convert REAL_64 `v` to type G.
		deferred
		end

	to_real_64 (v: G): REAL_64
			-- Convert `v` to REAL_64 for math operations.
		deferred
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: G)
			-- Put value at pointer with offset.
		deferred
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): G
			-- Read value from pointer at offset.
		deferred
		end

feature -- Operations

	add_elements (x, y: G): G
		deferred
		end

	sub_elements (x, y: G): G
		deferred
		end

	mul_elements (x, y: G): G
		deferred
		end

	div_elements (x, y: G): G
		deferred
		end

end

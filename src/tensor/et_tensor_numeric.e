note
	description: "Deferred strategy for type-specific tensor operations."

deferred class
	ET_TENSOR_NUMERIC [G -> {NUMERIC, COMPARABLE}]

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

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: G)
			-- Put value at pointer with offset.
		deferred
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): G
			-- Read value from pointer at offset.
		deferred
		end

end

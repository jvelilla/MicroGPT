note
	description: "Cross-platform memory-mapped file wrapper."

class
	ET_MEMORY_MAP

create
	make_with_path

feature {NONE} -- Initialization

	make_with_path (a_path: PATH)
			-- Map the file read-only.
		local
			l_c_path: C_STRING
			l_size_ptr: MANAGED_POINTER
			l_str_path: STRING_8
		do
			l_str_path := a_path.utf_8_name
			create l_c_path.make (l_str_path)
			create l_size_ptr.make (8) -- 8 bytes for size_t (64-bit on win64/linux64)
			path := a_path
			item := c_et_mmap_file_ro (l_c_path.item, l_size_ptr.item)
			if item /= default_pointer then
				is_mapped := True
				count := l_size_ptr.read_integer_64 (0)
			else
				is_mapped := False
				count := 0
			end
		end

feature -- Access

	path: PATH
	item: POINTER
	count: INTEGER_64
	is_mapped: BOOLEAN

feature -- Cleanup

	unmap
			-- Unmap the view.
		do
			if is_mapped and then item /= default_pointer then
				c_et_munmap (item, count)
				item := default_pointer
				is_mapped := False
			end
		end

feature {NONE} -- Externals

	c_et_mmap_file_ro (a_path: POINTER; a_out_size: POINTER): POINTER
		external
			"C inline use <et_mmap.h>"
		alias
			"[
				return et_mmap_file_ro((const char*)$a_path, (size_t*)$a_out_size);
			]"
		end

	c_et_munmap (a_ptr: POINTER; a_size: INTEGER_64)
		external
			"C inline use <et_mmap.h>"
		alias
			"[
				et_munmap($a_ptr, (size_t)$a_size);
			]"
		end

end

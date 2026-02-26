note
	description: "Utility for modifying environment variables programmatically."

class
	ET_ENV

feature -- Access

	put_env (a_key: READABLE_STRING_GENERAL; a_value: READABLE_STRING_GENERAL)
			-- Set an environment variable formatted as "KEY=VALUE".
		local
			l_c_str: C_STRING
			l_env_str: STRING_8
			l_res: INTEGER
		do
			l_env_str := a_key.to_string_8 + "=" + a_value.to_string_8
			create l_c_str.make (l_env_str)
			l_res := c_putenv (l_c_str.item)
		end

	append_to_path (a_dir: READABLE_STRING_GENERAL)
			-- Append a directory to the PATH environment variable.
		local
			l_exec: EXECUTION_ENVIRONMENT
			l_current_path: STRING_32
		do
			create l_exec
			if attached l_exec.item ("PATH") as p then
				l_current_path := p.to_string_32
			else
				l_current_path := ""
			end
			
			-- Only append if it's not already there (simple check)
			if not l_current_path.has_substring (a_dir.to_string_32) then
				if not l_current_path.is_empty then
					-- Windows uses ';', Unix uses ':'
					if {PLATFORM}.is_windows then
						l_current_path.append_character (';')
					else
						l_current_path.append_character (':')
					end
				end
				l_current_path.append_string_general (a_dir)
				put_env ("PATH", l_current_path)
			end
		end

feature {NONE} -- Externals

	c_putenv (a_str: POINTER): INTEGER
		external
			"C inline use <stdlib.h>"
		alias
			"[
			#ifdef _WIN32
				return _putenv((const char*)$a_str);
			#else
				return putenv((char*)$a_str);
			#endif
			]"
		end

end

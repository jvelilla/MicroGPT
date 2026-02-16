note
    description: "Configuration and Argument Parsing for MicroGPT"

class
    MICROGPT_CONFIG

create
    make, make_from_args

feature -- Initialization

    make
            -- Set default values.
        do
            -- Defaults matching the reference
            n_embd := 16
            n_head := 4
            n_layer := 1
            block_size := 16
            dropout := 0.0
            learning_rate := 0.01
            max_iters := 1000
            batch_size := 1
            input_file := "input.txt"
            mode := "train" -- train, test, interactive
            seed := 42
        end

    make_from_args
            -- Parse command line arguments.
        local
            args: ARGUMENTS_32
            i: INTEGER
            arg, val: STRING_32
        do
            make
            create args
            
            from i := 1 until i > args.argument_count loop
                arg := args.argument (i)
                if arg.is_equal ("-interactive") then
                    mode := "interactive"
                elseif arg.is_equal ("-test") then
                    mode := "test"
                elseif arg.starts_with ("-") and i < args.argument_count then
                    val := args.argument (i + 1)
                    if is_option (arg) then 
                        process_arg (arg, val)
                        i := i + 1 -- Skip value
                    end
                end
                i := i + 1
            end
        end

    is_option (key: STRING_32): BOOLEAN
            -- Is 'key' an option that takes a value?
        do
            Result := key.is_equal ("-n_embd") or
                      key.is_equal ("-n_head") or
                      key.is_equal ("-n_layer") or
                      key.is_equal ("-block_size") or
                      key.is_equal ("-steps") or
                      key.is_equal ("-lr") or
                      key.is_equal ("-seed") or
                      key.is_equal ("-input") or
                      key.is_equal ("-mode")
        end

    process_arg (key, val: STRING_32)
        do
            if key.is_equal ("-n_embd") and val.is_integer then
                n_embd := val.to_integer
            elseif key.is_equal ("-n_head") and val.is_integer then
                n_head := val.to_integer
            elseif key.is_equal ("-n_layer") and val.is_integer then
                n_layer := val.to_integer
            elseif key.is_equal ("-block_size") and val.is_integer then
                block_size := val.to_integer
            elseif key.is_equal ("-steps") and val.is_integer then
                max_iters := val.to_integer
            elseif key.is_equal ("-lr") and val.is_double then
                learning_rate := val.to_double
            elseif key.is_equal ("-seed") and val.is_integer then
                seed := val.to_integer
            elseif key.is_equal ("-input") then
                input_file := val.to_string_8
            elseif key.is_equal ("-mode") then
                mode := val.to_string_8
            end
        end

feature -- Access

    n_embd: INTEGER
    n_head: INTEGER
    n_layer: INTEGER
    block_size: INTEGER
    dropout: REAL_64
    learning_rate: REAL_64
    max_iters: INTEGER
    batch_size: INTEGER
    input_file: STRING
    mode: STRING
    seed: INTEGER

end

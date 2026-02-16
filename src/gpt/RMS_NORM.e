note
    description: "RMS Norm (Parameter-less)"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    RMS_NORM

inherit
    MODULE
        redefine
            parameters
        end
    DOUBLE_MATH
        export
            {NONE} all
        end

create
    make

feature -- Initialization

    make (ndim: INTEGER)
            -- Initialize RMS Norm with dimension `ndim`.
        do
            dim := ndim
            epsilon := 1.0e-5
        end

feature -- Access

    dim: INTEGER
    epsilon: REAL_64

    parameters: LIST [VALUE]
            -- Empty parameters (no learnable affine parameters in microgpt ref).
        do
            create {LINKED_LIST [VALUE]} Result.make
        end

feature -- Operation

    forward (x: LIST [VALUE]): LIST [VALUE]
            -- Normalize input `x`.
        require
            valid_input: x.count = dim
        local
            ms, scale: VALUE
            x_arr: ARRAYED_LIST [VALUE]
            out_list: LINKED_LIST [VALUE]
            i: INTEGER
            val: VALUE
        do
            create x_arr.make_from_iterable (x)
            create out_list.make
            
            -- Calculate Mean Square
            ms := create {VALUE}.make (0.0)
            across x as v loop
                ms := ms + (v ^ 2.0)
            end
            ms := ms * create {VALUE}.make (1.0 / dim)
            
            -- Calculate scale = (ms + eps) ^ -0.5
            scale := (ms + create {VALUE}.make (epsilon)) ^ -0.5
            
            -- Normalize: y = x * scale
            from i := 1 until i > dim loop
                val := x_arr [i] * scale
                out_list.extend (val)
                i := i + 1
            end
            
            Result := out_list
        ensure
            output_size_matches: Result.count = dim
        end

end

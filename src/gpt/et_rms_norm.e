note
    description: "RMS Norm (Parameter-less)"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_RMS_NORM

inherit
    ET_MODULE
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

    parameters: LIST [ET_VALUE]
            -- Empty parameters (no learnable affine parameters in microgpt ref).
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
        end

feature -- Operation

    forward (x: LIST [ET_VALUE]): LIST [ET_VALUE]
            -- Normalize input `x`.
        require
            valid_input: x.count = dim
        local
            ms, scale: ET_VALUE
            x_arr: ARRAYED_LIST [ET_VALUE]
            out_list: LINKED_LIST [ET_VALUE]
            i: INTEGER
            val: ET_VALUE
        do
            create x_arr.make_from_iterable (x)
            create out_list.make
            
            -- Calculate Mean Square
            ms := create {ET_VALUE}.make (0.0)
            across x as v loop
                ms := ms + (v ^ 2.0)
            end
            ms := ms * create {ET_VALUE}.make (1.0 / dim)
            
            -- Calculate scale = (ms + eps) ^ -0.5
            scale := (ms + create {ET_VALUE}.make (epsilon)) ^ -0.5
            
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

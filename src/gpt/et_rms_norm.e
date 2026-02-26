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

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            -- Empty parameters (no learnable affine parameters in microgpt ref).
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} Result.make
        end

feature -- Operation

    forward (x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            -- Normalize input `x` across the last dimension.
        require
            valid_input: x.shape [x.shape.count] = dim
        local
            ms, scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            numeric_helper: ET_TENSOR_NUMERIC_REAL_64
            scalar_shape: ARRAY [INTEGER]
            t_eps, t_dim: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            create numeric_helper
            create scalar_shape.make_empty

            -- Mean Square: ms = (x^2).mean(dim)
            ms := (x * x).sum (x.shape.count, False)
            debug
	            io.put_string_32 ({STRING_32} "        [DEBUG] ln ms after sum mean: " + ms.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            create t_dim.make_full (scalar_shape, numeric_helper.from_real_64 (dim.to_double))
            ms := ms / t_dim
            debug
	            io.put_string_32 ({STRING_32} "        [DEBUG] ln ms after div mean: " + ms.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- add eps
            create t_eps.make_full (scalar_shape, numeric_helper.from_real_64 (epsilon))
            ms := ms + t_eps

            -- scale = ms ^ -0.5
            scale := ms ^ -0.5
            debug
	            io.put_string_32 ({STRING_32} "        [DEBUG] ln scale after pow mean: " + scale.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- Unsqueeze to match shape for broadcasting back over the features dimension
            scale := scale.unsqueeze (scale.shape.count + 1)

            -- Normalize: y = x * scale
            Result := x * scale
            debug
	            io.put_string_32 ({STRING_32} "        [DEBUG] ln Result mean: " + Result.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end
        ensure
            same_shape: Result.shape ~ x.shape
        end

end

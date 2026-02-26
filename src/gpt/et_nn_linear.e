note
    description: "Linear Layer: y = xA^T + b"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_NN_LINEAR

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (inc, outc: INTEGER; bias: BOOLEAN)
            -- Initialize linear layer.
            -- `inc`: input channels.
            -- `outc`: output channels.
            -- `bias`: whether to include bias term.
        local
            t_scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            numeric_helper: ET_TENSOR_NUMERIC_REAL_32
        do
            create numeric_helper
            
            -- PyTorch Linear uses weight shape [out_features, in_features]
            create weight.make_randn (<<outc, inc>>)
            create t_scale.make_full (<<1>>, numeric_helper.from_real_64 (0.08))
            weight := weight * t_scale
            weight.set_requires_grad (True)
            
            if bias then
                create b.make_zeros (<<outc>>)
                if attached b as bias_vec then
                    bias_vec.set_requires_grad (True)
                end
            end
            
            in_channels := inc
            out_channels := outc
        end

feature -- Access

    weight: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
    b: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
    in_channels, out_channels: INTEGER

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]
            -- Learnable parameters (weights + optional bias).
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]} Result.make
            Result.extend (weight)
            if attached b as bias_vec then
                Result.extend (bias_vec)
            end
        end

feature -- Operation

    forward (x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            -- Apply linear transformation to `x`.
            -- `x` shape: [..., in_channels]
        require
            input_size: x.shape [x.shape.count] = in_channels
        do
            -- y = x @ W^T + b
            Result := x.matmul (weight.transpose (1, 2))
            
            if attached b as bias_vec then
                Result := Result + bias_vec
            end
        ensure
            output_matches_out_channels: Result.shape [Result.shape.count] = out_channels
        end

invariant
    weights_sized: weight.shape [1] = out_channels and weight.shape [2] = in_channels

end

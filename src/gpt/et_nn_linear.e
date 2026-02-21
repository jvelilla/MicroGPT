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
            rng: RANDOM
            i: INTEGER
            u1, u2, z0: REAL_64
        do
            rng := shared_rng
            
            create {LINKED_LIST [ET_VALUE]} weight.make
            
            from i := 1 until i > inc * outc loop
                rng.forth
                u1 := rng.double_item
                rng.forth
                u2 := rng.double_item
                
                -- Box-Muller transform
                z0 := {DOUBLE_MATH}.sqrt (-2.0 * {DOUBLE_MATH}.log (u1)) * {DOUBLE_MATH}.cosine (2.0 * {DOUBLE_MATH}.pi * u2)
                
                weight.extend (create {ET_VALUE}.make (z0 * 0.08)) -- Gaussian(0, 0.08)
                i := i + 1
            end
            
            if bias then
                create {LINKED_LIST [ET_VALUE]} b.make
                from i := 1 until i > outc loop
                    b.extend (create {ET_VALUE}.make (0.0))
                    i := i + 1
                end
            end
            
            in_channels := inc
            out_channels := outc
        end

    feature {NONE} -- Internals

    shared_rng: RANDOM
        once
            create Result.make
            Result.set_seed (42) 
        end

feature -- Access

    weight: LIST [ET_VALUE]
    b: detachable LIST [ET_VALUE]
    in_channels, out_channels: INTEGER

    parameters: LIST [ET_VALUE]
            -- Learnable parameters (weights + optional bias).
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
            Result.append (weight)
            if attached b as bias_vec then
                Result.append (bias_vec)
            end
        end

feature -- Operation

    forward (x: LIST [ET_VALUE]): LIST [ET_VALUE]
            -- Apply linear transformation to `x`.
        require
            input_size: x.count = in_channels
        local
            y: LINKED_LIST [ET_VALUE]
            i, j: INTEGER
            sum: ET_VALUE
            x_arr: ARRAYED_LIST [ET_VALUE]
            w_arr: ARRAYED_LIST [ET_VALUE]
            b_arr: ARRAYED_LIST [ET_VALUE]
        do
            create y.make
            create x_arr.make_from_iterable (x)
            create w_arr.make_from_iterable (weight)
            
            if attached b as bias_vec then
                create b_arr.make_from_iterable (bias_vec)
            end
            
            from j := 0 until j >= out_channels loop
                sum := create {ET_VALUE}.make (0.0)
                if attached b_arr as ba then
                    sum := ba [j + 1]
                end
                
                from i := 0 until i >= in_channels loop
                    sum := sum + (x_arr [i + 1] * w_arr [j * in_channels + i + 1])
                    i := i + 1
                end
                
                y.extend (sum)
                j := j + 1
            end
            
            Result := y
        ensure
            output_matches_out_channels: Result.count = out_channels
        end

invariant
    weights_sized: weight.count = in_channels * out_channels
    bias_sized: attached b as bias implies bias.count = out_channels

end

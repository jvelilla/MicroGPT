note
    description: "Transformer Block"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_BLOCK

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (n_embd, n_head, block_size: INTEGER; dropout: REAL_64)
            -- Initialize with `n_embd` scale, `n_head` heads, `block_size` context.
        do
            create ln1.make (n_embd)
            create attn.make (n_embd, n_head, block_size, dropout)
            create ln2.make (n_embd)
            create mlp.make (n_embd, dropout)
        end

feature -- Access

    ln1, ln2: ET_RMS_NORM
    attn: ET_MULTI_HEAD_ATTENTION
    mlp: ET_GPT_MLP

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]
            -- Learnable parameters.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]} Result.make
            Result.append (ln1.parameters)
            Result.append (attn.parameters)
            Result.append (ln2.parameters)
            Result.append (mlp.parameters)
        end

    init_cache (max_len: INTEGER)
        do
            attn.init_cache (max_len)
        end

    reset_cache
        do
            attn.reset_cache
        end

feature -- Operation

    forward (x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            -- Apply block transformation: x + attn(ln1(x)) + mlp(ln2(x)).
        local
            x_norm, attn_out: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            x_res: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            x_norm2, mlp_out: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
        do
            -- x = x + attn(ln1(x))
            x_norm := ln1.forward (x)
            debug
	            io.put_string_32 ({STRING_32} "      [DEBUG] block ln1 out mean: " + x_norm.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            attn_out := attn.forward (x_norm)
            debug
	            io.put_string_32 ({STRING_32} "      [DEBUG] block attn out mean: " + attn_out.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            x_res := x + attn_out
            debug
	            io.put_string_32 ({STRING_32} "      [DEBUG] block res1 mean: " + x_res.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- x = x + mlp(ln2(x))
            x_norm2 := ln2.forward (x_res)
            debug
	            io.put_string_32 ({STRING_32} "      [DEBUG] block ln2 out mean: " + x_norm2.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            mlp_out := mlp.forward (x_norm2)
            debug
	            io.put_string_32 ({STRING_32} "      [DEBUG] block mlp out mean: " + mlp_out.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            Result := x_res + mlp_out
        ensure
            shape_preserved: Result.shape ~ x.shape
        end

end

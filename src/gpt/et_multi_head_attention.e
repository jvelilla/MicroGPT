note
    description: "Multi-Head Attention"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_MULTI_HEAD_ATTENTION

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (a_n_embd, a_n_head, a_block_size: INTEGER; a_dropout: REAL_64)
            -- Initialize MHA with separate Q, K, V, O projections (matching Python reference).
            -- `a_n_embd`: embedding dimension.
            -- `a_n_head`: number of heads.
            -- `a_block_size`: max sequence length (for causal mask).
            -- `a_dropout`: dropout probability (unused in microgpt ref).
        do
            n_embd := a_n_embd
            n_head := a_n_head
            block_size := a_block_size
            dropout_p := a_dropout
            head_size := n_embd // n_head

            -- Separate projections matching Python: attn_wq, attn_wk, attn_wv, attn_wo
            create attn_wq.make (n_embd, n_embd, False)
            create attn_wk.make (n_embd, n_embd, False)
            create attn_wv.make (n_embd, n_embd, False)
            create attn_wo.make (n_embd, n_embd, False)
        end

feature -- Access

    attn_wq: ET_NN_LINEAR  -- Query projection
    attn_wk: ET_NN_LINEAR  -- Key projection
    attn_wv: ET_NN_LINEAR  -- Value projection
    attn_wo: ET_NN_LINEAR  -- Output projection

    n_embd, n_head, head_size, block_size: INTEGER
    dropout_p: REAL_64

    -- KV Cache
    k_cache: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    v_cache: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    cache_pos: INTEGER

    init_cache (max_seq_len: INTEGER)
            -- Initialize KV cache for inference.
        local
            shape: ARRAY [INTEGER]
        do
            -- Shape: [1, max_seq_len, n_head, head_size]
            shape := <<1, max_seq_len, n_head, head_size>>

            create k_cache.make_zeros (shape)
            create v_cache.make_zeros (shape)
            cache_pos := 0
        end

    reset_cache
            -- Reset cache position.
        do
            cache_pos := 0
        end

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            -- Learnable parameters.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} Result.make
            Result.append (attn_wq.parameters)
            Result.append (attn_wk.parameters)
            Result.append (attn_wv.parameters)
            Result.append (attn_wo.parameters)
        end

feature -- Operation

    forward (x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            -- Apply attention mechanism with separate Q/K/V projections.
            -- `x`: input sequence [B, T, C] or [T, C].
            -- Returns: [B, T, C].
        local
            B, T, C, T_context: INTEGER
            q, k, v: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            q_view, k_view, v_view: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            q_h, k_h, v_h: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            att_scores, att_probs, att_exp, att_sum: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            out_h, out_h_t, out_flat: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            scale: REAL_64
            math_helper: DOUBLE_MATH
            numeric_helper: ET_TENSOR_NUMERIC_REAL_64
            scalar_shape: ARRAY [INTEGER]
            t_scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            k_h_t: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            causal_mask: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            t1, t2: INTEGER
            l_elem: ET_NUMERIC_ELEMENT [REAL_64]
            k_full, v_full: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            att_max_dim: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            if x.shape.count = 3 then
                B := x.shape [1]
                T := x.shape [2]
            else
                B := 1
                T := x.shape [1]
            end
            C := n_embd

            -- 1. Separate Q, K, V projections (matching Python reference)
            q := attn_wq.forward (x)
            k := attn_wk.forward (x)
            v := attn_wv.forward (x)

            -- View to [B, T, n_head, head_size]
            q_view := q.reshape (<<B, T, n_head, head_size>>)
            k_view := k.reshape (<<B, T, n_head, head_size>>)
            v_view := v.reshape (<<B, T, n_head, head_size>>)

            -- KV Cache Logic
            if attached k_cache as kc and attached v_cache as vc then
                kc.slice_range (2, cache_pos + 1, cache_pos + T).copy_from (k_view)
                vc.slice_range (2, cache_pos + 1, cache_pos + T).copy_from (v_view)

                k_full := kc.slice_range (2, 1, cache_pos + T)
                v_full := vc.slice_range (2, 1, cache_pos + T)

                k_view := k_full
                v_view := v_full

                T_context := cache_pos + T
            else
                T_context := T
            end

            -- 3. Process Heads
            -- Transpose to [B, n_head, T, head_size]
            q_h := q_view.transpose (2, 3)
            k_h := k_view.transpose (2, 3)
            v_h := v_view.transpose (2, 3)

            -- Attention Scores: q_h @ k_h^T
            -- k_h^T is [B, n_head, head_size, T_context]
            k_h_t := k_h.transpose (3, 4)
            att_scores := q_h.matmul (k_h_t)

            -- Scale
            create math_helper
            create numeric_helper
            create scalar_shape.make_empty
            scale := 1.0 / math_helper.sqrt (head_size.to_double)
            create t_scale.make_full (scalar_shape, numeric_helper.from_real_64 (scale))
            att_scores := att_scores * t_scale

            -- Causal mask
            create causal_mask.make_zeros (<<T, T_context>>)
            create l_elem
            l_elem.set_item ({REAL_64} -1.0e9)

            from t1 := 1 until t1 > T loop
                from t2 := cache_pos + t1 + 1 until t2 > T_context loop
                    causal_mask.put (l_elem, <<t1, t2>>)
                    t2 := t2 + 1
                end
                t1 := t1 + 1
            end

            att_scores := att_scores + causal_mask

            -- Softmax
            create att_max_dim.make_zeros (att_scores.shape)
            att_max_dim := att_scores.max_dim (att_scores.shape.count, True)
            att_scores := att_scores - att_max_dim
            att_exp := att_scores.exp_val
            att_sum := att_exp.sum (att_exp.shape.count, True)
            att_probs := att_exp / att_sum

            -- Output Context
            -- [B, n_head, T, head_size]
            out_h := att_probs.matmul (v_h)

            -- Transpose back to [B, T, n_head, head_size]
            out_h_t := out_h.transpose (2, 3)

            -- Flatten heads: [B, T, n_embd]
            out_flat := out_h_t.contiguous.reshape (<<B, T, C>>)

            -- Final Projection (attn_wo)
            Result := attn_wo.forward (out_flat)

            if x.shape.count = 2 then
                Result := Result.reshape (<<T, C>>)
            end

            if attached k_cache then
                cache_pos := cache_pos + T
            end
        ensure
            output_sequence_length: Result.shape [2] = x.shape [2] or Result.shape [1] = x.shape [1]
        end

invariant
    valid_heads: n_embd \\ n_head = 0

end

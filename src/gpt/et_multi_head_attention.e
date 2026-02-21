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
            -- Initialize MHA.
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
            
            create c_attn.make (n_embd, 3 * n_embd, True) -- Key, Query, Value projections combined
            create c_proj.make (n_embd, n_embd, True)
        end

feature -- Access

    c_attn: ET_NN_LINEAR
    c_proj: ET_NN_LINEAR
    
    n_embd, n_head, head_size, block_size: INTEGER
    dropout_p: REAL_64

    -- KV Cache
    -- Note: We use TENSOR [REAL_32] instead of REAL_64 for memory efficiency.
    -- The cache grows linearly with sequence length, so halving the memory usage is significant.
    -- Most deep learning inference uses float32 or lower precision.
    k_cache: detachable ET_TENSOR [REAL_32]
    v_cache: detachable ET_TENSOR [REAL_32]
    cache_pos: INTEGER
    
    init_cache (max_seq_len: INTEGER)
            -- Initialize KV cache for inference.
        local
            shape: ARRAY [INTEGER]
        do
            -- Shape: [n_head, max_seq_len, head_size]
            shape := <<n_head, max_seq_len, head_size>>
            
            create k_cache.make_zeros (shape)
            create v_cache.make_zeros (shape)
            cache_pos := 0
        end

    reset_cache
            -- Reset cache position.
        do
            cache_pos := 0
        end

    parameters: LIST [ET_VALUE]
            -- Learnable parameters.
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
            Result.append (c_attn.parameters)
            Result.append (c_proj.parameters)
        end

feature -- Operation

    forward (x: LIST [LIST [ET_VALUE]]): LIST [LIST [ET_VALUE]]
            -- Apply attention mechanism.
            -- `x`: input sequence (T, C).
            -- Returns: (T, C).
        require
            input_sequence_exists: not x.is_empty
            input_embedding_dim: across x as item all item.count = n_embd end
        local
            T, C: INTEGER

            
            qkv_flat: LIST [LIST [ET_VALUE]]
            out_flat: LINKED_LIST [LIST [ET_VALUE]]
            
            res_heads: ARRAY [LIST [LIST [ET_VALUE]]] -- heads -> T -> head_size
            
            h_idx: INTEGER
        do
            T := x.count
            C := n_embd
            
            -- 1. Project
            create {LINKED_LIST [LIST [ET_VALUE]]} qkv_flat.make
            across x as t_step loop
                qkv_flat.extend (c_attn.forward (t_step)) -- (3*C)
            end
            
            -- 2. Process Heads
            create res_heads.make_filled (create {LINKED_LIST [LIST [ET_VALUE]]}.make, 1, n_head)
            
            from h_idx := 1 until h_idx > n_head loop
                res_heads [h_idx] := compute_head (qkv_flat, h_idx, T)
                h_idx := h_idx + 1
            end
            
            -- 4. Concat and 5. Project
            create out_flat.make
            -- For each time step t
            -- Concat head outputs
            -- Then linear project
            
            out_flat := combine_heads (res_heads, T)
            
            -- Final Projection
            create {LINKED_LIST [LIST [ET_VALUE]]} Result.make
            across out_flat as t_step loop
                Result.extend (c_proj.forward (t_step))
            end
            
            if attached k_cache then
                cache_pos := cache_pos + T
            end
        ensure
            output_sequence_length: Result.count = x.count
        end


feature {NONE} -- Internal



    compute_head (qkv: LIST [LIST [ET_VALUE]]; h_idx, T_len: INTEGER): LIST [LIST [ET_VALUE]]
            -- Flattened logic for efficient head computation.
            -- Returns (T, head_size) for a single head.
        local
            q_h, k_h, v_h: ARRAYED_LIST [ARRAYED_LIST [ET_VALUE]] -- (T, head_size)
            att_scores: ARRAY2 [ET_VALUE] -- (T, T)
            att_out: LINKED_LIST [LIST [ET_VALUE]] -- (T, head_size)
            
            t1, t2, i: INTEGER
            scale: REAL_64
            score: ET_VALUE
            exp_sum: ET_VALUE
            softmax_row: ARRAYED_LIST [ET_VALUE]
            
            qkv_arr: ARRAYED_LIST [LIST [ET_VALUE]]
            item_arr: ARRAYED_LIST [ET_VALUE]
            
            row_out: LINKED_LIST [ET_VALUE]
            val: ET_VALUE
            inv_sum: ET_VALUE
            
            -- Cache locals
            l_k_cache, l_v_cache: ET_TENSOR [REAL_32]
            idx_k, idx_v: ARRAY [INTEGER]
            cached_val: REAL_32
            
            cache_len: INTEGER
            seq_len_total: INTEGER -- T_len + cache_pos
            k_seq, v_seq: ARRAYED_LIST [ARRAYED_LIST [ET_VALUE]]
        do
            create qkv_arr.make_from_iterable (qkv)
            
            create q_h.make (T_len)
            create k_h.make (T_len)
            create v_h.make (T_len)
            
            -- Extract Q, K, V for this head
            from t1 := 1 until t1 > T_len loop
                create item_arr.make_from_iterable (qkv_arr [t1]) 
                q_h.extend (slice (item_arr, (h_idx-1)*head_size + 1, h_idx*head_size))
                k_h.extend (slice (item_arr, n_embd + (h_idx-1)*head_size + 1, n_embd + h_idx*head_size))
                v_h.extend (slice (item_arr, 2*n_embd + (h_idx-1)*head_size + 1, 2*n_embd + h_idx*head_size))
                t1 := t1 + 1
            end
            
            if attached k_cache as kc and attached v_cache as vc then
                -- KV Cache Logic
                l_k_cache := kc
                l_v_cache := vc
                
                -- 1. Update Cache
                from t1 := 1 until t1 > T_len loop
                    from i := 1 until i > head_size loop
                        -- Store k
                        val := k_h [t1] [i]
                        l_k_cache.put ({REAL_32} 0.0 + val.data.truncated_to_real, <<h_idx, cache_pos + t1, i>>)
                        
                        -- Store v
                        val := v_h [t1] [i]
                        l_v_cache.put ({REAL_32} 0.0 + val.data.truncated_to_real, <<h_idx, cache_pos + t1, i>>)
                        
                        i := i + 1
                    end
                    t1 := t1 + 1
                end
                
                -- 2. Build Full K, V Sequence from Cache (up to cache_pos + T_len)
                cache_len := cache_pos + T_len
                create k_seq.make (cache_len)
                create v_seq.make (cache_len)
                
                from t1 := 1 until t1 > cache_len loop
                    create {ARRAYED_LIST [ET_VALUE]} item_arr.make (head_size)
                    from i := 1 until i > head_size loop
                       cached_val := l_k_cache.item (<<h_idx, t1, i>>)
                       item_arr.extend (create {ET_VALUE}.make (cached_val.to_double))
                       i := i + 1
                    end
                    k_seq.extend (item_arr)
                    
                    create {ARRAYED_LIST [ET_VALUE]} item_arr.make (head_size)
                    from i := 1 until i > head_size loop
                       cached_val := l_v_cache.item (<<h_idx, t1, i>>)
                       item_arr.extend (create {ET_VALUE}.make (cached_val.to_double))
                       i := i + 1
                    end
                    v_seq.extend (item_arr)
                    
                    t1 := t1 + 1
                end
                
                -- Update position globally? No, `compute_head` assumes `cache_pos` is handled outside or shared.
                -- `cache_pos` is class attribute. `compute_head` is called multiple times (once per head).
                -- We CANNOT increment `cache_pos` here, otherwise it increments N times.
                -- We should use `cache_pos` as start index.
                
                -- Swap k_h, v_h with full sequence
                k_h := k_seq
                v_h := v_seq
                
                -- Q is still q_h (usually current step)
                
                -- T_len for attention map becomes `q_h.count` x `k_h.count`
                
            else
                -- Legacy logic: K, V come from input
                -- Nothing to do, k_h and v_h are already set
                cache_len := 0 -- dummy
            end
            
            -- Attention Scores
            scale := 1.0 / {DOUBLE_MATH}.sqrt (head_size)
            -- Matrix size: Q_len x K_len
            -- Regular: T x T
            -- Cached:  T x (Total_Steps) where Total_Steps = Cache_Pos + T
            
            create att_scores.make_filled (create {ET_VALUE}.make (0.0), q_h.count, k_h.count)
            
            from t1 := 1 until t1 > q_h.count loop
                from t2 := 1 until t2 > k_h.count loop 
                    -- Causal Mask
                    -- Standard: `t2 <= t1`
                    -- Cached: `t2` is absolute time. `t1` is relative to current window start `cache_pos`.
                    -- Absolute time of Query `t1`: `cache_pos + t1`
                    -- Absolute time of Key `t2`: `t2`
                    -- Constraint: `t2 <= cache_pos + t1`
                    
                    if attached k_cache then
                         if t2 <= cache_pos + t1 then
                            score := dot_product (q_h [t1], k_h [t2]) * create {ET_VALUE}.make (scale)
                            att_scores.put (score, t1, t2)
                        else
                             att_scores.put (create {ET_VALUE}.make (-1.0e9), t1, t2)
                        end
                    else
                        if t2 <= t1 then
                            score := dot_product (q_h [t1], k_h [t2]) * create {ET_VALUE}.make (scale)
                            att_scores.put (score, t1, t2)
                        else
                             att_scores.put (create {ET_VALUE}.make (-1.0e9), t1, t2)
                        end
                    end

                    t2 := t2 + 1
                end
                t1 := t1 + 1
            end
            
            -- Softmax
            create att_out.make
            from t1 := 1 until t1 > q_h.count loop
                -- 1. Exponentials and Sum
                create softmax_row.make (k_h.count)
                exp_sum := create {ET_VALUE}.make (0.0)
                
                from t2 := 1 until t2 > k_h.count loop
                    val := att_scores.item (t1, t2).exp_val
                    softmax_row.extend (val)
                    exp_sum := exp_sum + val
                    t2 := t2 + 1
                end
                
                -- 2. Normalize and Weighted Sum
                create row_out.make
                
                -- Optimization: compute inverse sum once per row
                inv_sum := exp_sum.power (-1.0)
                
                from i := 1 until i > head_size loop
                    -- print ("Inner i: " + i.out + "%N") 
                    val := create {ET_VALUE}.make (0.0)
                    from t2 := 1 until t2 > k_h.count loop 
                        -- v_h has length k_h.count
                        val := val + ((softmax_row [t2] * inv_sum) * v_h [t2] [i])
                        t2 := t2 + 1
                    end
                    row_out.extend (val)
                    i := i + 1
                end
                att_out.extend (row_out)
                
                t1 := t1 + 1
            end
            
            Result := att_out
        end
        
    combine_heads (heads: ARRAY [LIST [LIST [ET_VALUE]]]; T_len: INTEGER): LINKED_LIST [LIST [ET_VALUE]]
        local
            out_list: LINKED_LIST [LIST [ET_VALUE]]
            row: LINKED_LIST [ET_VALUE]
            t_idx: INTEGER
            h: INTEGER
            heads_arr: ARRAY [ARRAYED_LIST [LIST [ET_VALUE]]]
            curr_head: ARRAYED_LIST [ET_VALUE]
        do
            create out_list.make
            create heads_arr.make_filled (create {ARRAYED_LIST [LIST [ET_VALUE]]}.make (0), 1, n_head)
            from h := 1 until h > n_head loop
                heads_arr [h] := create {ARRAYED_LIST [LIST [ET_VALUE]]}.make_from_iterable (heads [h])
                h := h + 1
            end
            
            from t_idx := 1 until t_idx > T_len loop
                create row.make
                from h := 1 until h > n_head loop
                    create curr_head.make_from_iterable (heads_arr [h] [t_idx])
                    across curr_head as v loop
                        row.extend (v)
                    end
                    h := h + 1
                end
                out_list.extend (row)
                t_idx := t_idx + 1
            end
            Result := out_list
        end
        
    slice (list: ARRAYED_LIST [ET_VALUE]; start_idx, end_idx: INTEGER): ARRAYED_LIST [ET_VALUE]
        local
            res: ARRAYED_LIST [ET_VALUE]
            i: INTEGER
        do
            create res.make (end_idx - start_idx + 1)
            from i := start_idx until i > end_idx loop
                res.extend (list [i])
                i := i + 1
            end
            Result := res
        end
        
    dot_product (v1, v2: ARRAYED_LIST [ET_VALUE]): ET_VALUE
        local
            sum: ET_VALUE
            i: INTEGER
        do
            sum := create {ET_VALUE}.make (0.0)
            from i := 1 until i > v1.count loop
                sum := sum + (v1 [i] * v2 [i])
                i := i + 1
            end
            Result := sum
        end

invariant
    valid_heads: n_embd \\ n_head = 0

end

note
    description: "Multi-Head Attention"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    MULTI_HEAD_ATTENTION

inherit
    MODULE
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

    c_attn: NN_LINEAR
    c_proj: NN_LINEAR
    
    n_embd, n_head, head_size, block_size: INTEGER
    dropout_p: REAL_64

    parameters: LIST [VALUE]
            -- Learnable parameters.
        do
            create {LINKED_LIST [VALUE]} Result.make
            Result.append (c_attn.parameters)
            Result.append (c_proj.parameters)
        end

feature -- Operation

    forward (x: LIST [LIST [VALUE]]): LIST [LIST [VALUE]]
            -- Apply attention mechanism.
            -- `x`: input sequence (T, C).
            -- Returns: (T, C).
        require
            input_sequence_exists: not x.is_empty
            input_embedding_dim: across x as item all item.count = n_embd end
        local
            T, C: INTEGER

            
            qkv_flat: LIST [LIST [VALUE]]
            out_flat: LINKED_LIST [LIST [VALUE]]
            
            res_heads: ARRAY [LIST [LIST [VALUE]]] -- heads -> T -> head_size
            
            h_idx: INTEGER
        do
            T := x.count
            C := n_embd
            
            -- 1. Project
            create {LINKED_LIST [LIST [VALUE]]} qkv_flat.make
            across x as t_step loop
                qkv_flat.extend (c_attn.forward (t_step)) -- (3*C)
            end
            
            -- 2. Process Heads
            create res_heads.make_filled (create {LINKED_LIST [LIST [VALUE]]}.make, 1, n_head)
            
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
            create {LINKED_LIST [LIST [VALUE]]} Result.make
            across out_flat as t_step loop
                Result.extend (c_proj.forward (t_step))
            end
        ensure
            output_sequence_length: Result.count = x.count
        end


feature {NONE} -- Internal

    compute_head (qkv: LIST [LIST [VALUE]]; h_idx, T_len: INTEGER): LIST [LIST [VALUE]]
            -- Flattened logic for efficient head computation.
            -- Returns (T, head_size) for a single head.
        local
            q_h, k_h, v_h: ARRAYED_LIST [ARRAYED_LIST [VALUE]] -- (T, head_size)
            att_scores: ARRAY2 [VALUE] -- (T, T)
            att_out: LINKED_LIST [LIST [VALUE]] -- (T, head_size)
            
            t1, t2, i: INTEGER
            scale: REAL_64
            score: VALUE
            exp_sum: VALUE
            softmax_row: ARRAYED_LIST [VALUE]
            
            qkv_arr: ARRAYED_LIST [LIST [VALUE]]
            item_arr: ARRAYED_LIST [VALUE]
            
            row_out: LINKED_LIST [VALUE]
            val: VALUE
            inv_sum: VALUE
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
            
            -- Attention Scores
            scale := 1.0 / {DOUBLE_MATH}.sqrt (head_size)
            create att_scores.make_filled (create {VALUE}.make (0.0), T_len, T_len)
            
            from t1 := 1 until t1 > T_len loop
                from t2 := 1 until t2 > T_len loop 
                    if t2 <= t1 then
                        score := dot_product (q_h [t1], k_h [t2]) * create {VALUE}.make (scale)
                        att_scores.put (score, t1, t2)
                    else
                         att_scores.put (create {VALUE}.make (-1.0e9), t1, t2)
                    end
                    t2 := t2 + 1
                end
                t1 := t1 + 1
            end
            
            -- Softmax
            create att_out.make
            from t1 := 1 until t1 > T_len loop
                -- 1. Exponentials and Sum
                create softmax_row.make (T_len)
                exp_sum := create {VALUE}.make (0.0)
                
                from t2 := 1 until t2 > T_len loop
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
                    val := create {VALUE}.make (0.0)
                    from t2 := 1 until t2 > T_len loop 
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
        
    combine_heads (heads: ARRAY [LIST [LIST [VALUE]]]; T_len: INTEGER): LINKED_LIST [LIST [VALUE]]
        local
            out_list: LINKED_LIST [LIST [VALUE]]
            row: LINKED_LIST [VALUE]
            t_idx: INTEGER
            h: INTEGER
            heads_arr: ARRAY [ARRAYED_LIST [LIST [VALUE]]]
            curr_head: ARRAYED_LIST [VALUE]
        do
            create out_list.make
            create heads_arr.make_filled (create {ARRAYED_LIST [LIST [VALUE]]}.make (0), 1, n_head)
            from h := 1 until h > n_head loop
                heads_arr [h] := create {ARRAYED_LIST [LIST [VALUE]]}.make_from_iterable (heads [h])
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
        
    slice (list: ARRAYED_LIST [VALUE]; start_idx, end_idx: INTEGER): ARRAYED_LIST [VALUE]
        local
            res: ARRAYED_LIST [VALUE]
            i: INTEGER
        do
            create res.make (end_idx - start_idx + 1)
            from i := start_idx until i > end_idx loop
                res.extend (list [i])
                i := i + 1
            end
            Result := res
        end
        
    dot_product (v1, v2: ARRAYED_LIST [VALUE]): VALUE
        local
            sum: VALUE
            i: INTEGER
        do
            sum := create {VALUE}.make (0.0)
            from i := 1 until i > v1.count loop
                sum := sum + (v1 [i] * v2 [i])
                i := i + 1
            end
            Result := sum
        end

invariant
    valid_heads: n_embd \\ n_head = 0

end

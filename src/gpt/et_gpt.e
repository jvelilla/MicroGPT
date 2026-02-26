note
    description: "GPT Language Model"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_GPT

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

    make (vocab_size, n_embd, n_head, n_layer, block_size: INTEGER; dropout: REAL_64)
            -- Initialize with `vocab_size`, `n_embd` embedding dimension, `n_head` heads,
            -- `n_layer` layers, `block_size` context length and `dropout` rate.
        local
            i: INTEGER
        do
            create token_embedding_table.make (vocab_size, n_embd) -- wte
            create position_embedding_table.make (block_size, n_embd) -- wpe

            create {LINKED_LIST [ET_BLOCK]} blocks.make
            from i := 1 until i > n_layer loop
                blocks.extend (create {ET_BLOCK}.make (n_embd, n_head, block_size, dropout))
                i := i + 1
            end

            create ln_f.make (n_embd)
            create lm_head.make (n_embd, vocab_size, False) -- bias=False usually

            max_seq_len := block_size

            create rng.make
            rng.set_seed (42)
        end

feature -- Access

    token_embedding_table: ET_EMBEDDING
    position_embedding_table: ET_EMBEDDING
    blocks: LIST [ET_BLOCK]
    ln_f: ET_RMS_NORM
    lm_head: ET_NN_LINEAR

    max_seq_len: INTEGER
    rng: RANDOM

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]
            -- All learnable parameters of the model.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]} Result.make
            Result.append (token_embedding_table.parameters)
            Result.append (position_embedding_table.parameters)
            across blocks as b loop
                Result.append (b.parameters)
            end
            Result.append (ln_f.parameters)
            Result.append (lm_head.parameters)
        end

    init_cache (max_len: INTEGER)
        do
            across blocks as b loop
                b.init_cache (max_len)
            end
        end

    reset_cache
        do
            across blocks as b loop
                b.reset_cache
            end
        end

feature -- Operation

    forward (idx: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]; targets: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]): ARRAY [detachable ANY]
            -- Forward pass of the model.
            -- `idx`: input tokens [B, T] or [T].
            -- `targets`: optional target tokens for loss calculation.
            -- Returns <<logits, loss>>.
        require
            targets_match_input: attached targets implies targets.shape ~ idx.shape
        local
            t, b, i, j: INTEGER
            tok_emb: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            pos_emb: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            pos: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_elem: ET_NUMERIC_ELEMENT [INTEGER_32]
            start_pos: INTEGER
            logits_out: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]

            -- Loss locals
            log_sum_exp, log_probs: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            one_hot: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            v_elem: ET_NUMERIC_ELEMENT [REAL_32]
            numeric_i32: ET_TENSOR_NUMERIC_INTEGER_32
            target_t: INTEGER
            t_scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            numeric_r32: ET_TENSOR_NUMERIC_REAL_32
            scalar_shape: ARRAY [INTEGER]
            loss_val: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]

            -- Stable Softmax locals
            max_scalar: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            logits_stable: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
        do
            if idx.shape.count = 2 then
                b := idx.shape [1]
                t := idx.shape [2]
            else
                b := 1
                t := idx.shape [1]
            end

            -- 1. Tok emb
            tok_emb := token_embedding_table.forward (idx)
            debug
	            io.put_string_32 ({STRING_32} "    [DEBUG] tok_emb mean: " + tok_emb.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- 2. Pos emb
            debug
	            io.put_string_32 ({STRING_32} "    [GPT] Token embeddings applied. Generating pos embs...%N")
            end
            if attached {ET_BLOCK} blocks.first as first_blk then
                start_pos := first_blk.attn.cache_pos
            else
                start_pos := 0
            end

            create pos.make_zeros (idx.shape)
            create l_elem

            if idx.shape.count = 2 then
                from j := 1 until j > b loop
                    from i := 1 until i > t loop
                        l_elem.set_item (start_pos + i)
                        pos.put (l_elem, <<j, i>>)
                        i := i + 1
                    end
                    j := j + 1
                end
            else
                from i := 1 until i > t loop
                    l_elem.set_item (start_pos + i)
                    pos.put (l_elem, <<i>>)
                    i := i + 1
                end
            end

            pos_emb := position_embedding_table.forward (pos)
            debug
	            io.put_string_32 ({STRING_32} "    [DEBUG] pos_emb mean: " + pos_emb.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")

	            io.put_string_32 ({STRING_32} "    [GPT] Adding tok and pos embs...%N")
	            io.put_string_32 ({STRING_32} "    [GPT] tok_emb shape: " + tok_emb.show_shape + {STRING_32} "%N")
	            io.put_string_32 ({STRING_32} "    [GPT] pos_emb shape: " + pos_emb.show_shape + {STRING_32} "%N")
            end
            -- x = tok_emb + pos_emb
            x := tok_emb + pos_emb
            debug
	            io.put_string_32 ({STRING_32} "    [DEBUG] x after embeddings sum mean: " + x.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- 3. Blocks
            debug
	            io.put_string_32 ({STRING_32} "    [GPT] Running transformer blocks...%N")
            end
            across blocks as blk loop
                x := blk.forward (x)
            end
            debug
	            io.put_string_32 ({STRING_32} "    [DEBUG] x after transformer blocks mean: " + x.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- 4. Final Layer Norm
            debug
	            io.put_string_32 ({STRING_32} "    [GPT] Running final layer norm...%N")
            end
            x := ln_f.forward (x)
            debug
	            io.put_string_32 ({STRING_32} "    [DEBUG] x after final ln_f mean: " + x.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
            end

            -- 5. LM Head (logits)
            debug
	            io.put_string_32 ({STRING_32} "    [GPT] Computing logits...%N")
            end
            logits_out := lm_head.forward (x)

            -- 6. Loss (Cross Entropy)
            debug
	            io.put_string_32 ({STRING_32} "    [GPT] Checking for targets to compute loss...%N")
            end
            if attached targets as tgt then
                debug
	                io.put_string_32 ({STRING_32} "    [GPT] Targets found. Computing cross entropy loss...%N")
	                io.put_string_32 ({STRING_32} "    [GPT] logits_out shape: " + logits_out.show_shape + {STRING_32} "%N")

	                io.put_string_32 ({STRING_32} "    [GPT] Computing exp_val (stable)...%N")
	                -- Find dimension max value to prevent overflow properly
	                io.put_string_32 ({STRING_32} "    [DEBUG] logits_out mean: " + logits_out.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
                end
                max_scalar := logits_out.max (logits_out.shape.count, True)
                debug
	                io.put_string_32 ({STRING_32} "    [DEBUG] max_scalar mean: " + max_scalar.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
                end

                logits_stable := logits_out - max_scalar
                debug
	                io.put_string_32 ({STRING_32} "    [DEBUG] logits_stable mean: " + logits_stable.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
                end

                -- Stable: log_probs = logits_stable - log_sum_exp(logits_stable)
                log_sum_exp := logits_stable.exp_val.sum (logits_out.shape.count, False).log_val
                debug
	                io.put_string_32 ({STRING_32} "    [DEBUG] log_sum_exp mean: " + log_sum_exp.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
                end
                log_probs := logits_stable - log_sum_exp.unsqueeze (log_sum_exp.shape.count + 1)

                -- Construct one-hot target tensor
                create one_hot.make_zeros (logits_out.shape)
                one_hot.set_requires_grad (False)

                debug
	                io.put_string_32 ({STRING_32} "    [GPT] one_hot allocated. shape: " + one_hot.show_shape + {STRING_32} " numel: " + one_hot.numel.out.to_string_32 + {STRING_32} "%N")
                end

                create v_elem
                v_elem.set_item ({REAL_32} 1.0)
                create numeric_i32

                if idx.shape.count = 2 then
                    from j := 1 until j > b loop
                        from i := 1 until i > t loop
                            target_t := numeric_i32.read (tgt.data, tgt.offset + ((j - 1) * t + (i - 1)) * 4).item
                            -- Targets are already 1-based, so use target_t directly
                            one_hot.put (v_elem, <<j, i, target_t>>)
                            i := i + 1
                        end
                        j := j + 1
                    end
                else
                    from i := 1 until i > t loop
                        target_t := numeric_i32.read (tgt.data, tgt.offset + (i - 1) * 4).item
                        one_hot.put (v_elem, <<i, target_t>>)
                        i := i + 1
                    end
                end

                -- Multiply log_probs by one_hot to extract relevant probabilities
                -- Sum across all dimensions, multiply by -1 / (B*T)
                create numeric_r32
                create scalar_shape.make_empty
                create t_scale.make_full (scalar_shape, numeric_r32.from_real_64 (-1.0 / (b * t).to_double))

                -- We have to sum all dims. We can do it sequentially:
                debug
	                io.put_string_32 ({STRING_32} "    [GPT] Summing dimension losses...%N")
	                io.put_string_32 ({STRING_32} "    [GPT] log_probs shape: " + log_probs.show_shape + {STRING_32} "%N")
	                io.put_string_32 ({STRING_32} "    [GPT] one_hot shape: " + one_hot.show_shape + {STRING_32} "%N")
                end
                loss_val := log_probs * one_hot
                from i := loss_val.shape.count until i < 1 loop
                    loss_val := loss_val.sum (1, False)
                    i := i - 1
                end

                loss_val := loss_val * t_scale

                debug
	                io.put_string_32 ({STRING_32} "    [GPT] Forward pass completed successfully.%N")
                end
                create {ARRAY [detachable ANY]} Result.make_empty
                Result.force (logits_out, 1)
                Result.force (loss_val, 2)
            else
                create {ARRAY [detachable ANY]} Result.make_empty
                Result.force (logits_out, 1)
                Result.force (Void, 2)
            end
        end

    generate (idx: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]; max_new_tokens: INTEGER; temperature: REAL_64; stop_token: INTEGER): ARRAYED_LIST [INTEGER]
            -- Generate new tokens given a context `idx`.
            -- `max_new_tokens`: maximum tokens to generate.
            -- `temperature`: sampling temperature (higher = more random).
            -- `stop_token`: token ID to stop generation (e.g., BOS).
        require
            positive_new_tokens: max_new_tokens > 0
            positive_temperature: temperature > 0.0
        local
            curr_idx: ARRAYED_LIST [INTEGER]
            i_step: INTEGER
            output_arr: ARRAY [detachable ANY]
            logits_tensor: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
            next_token: INTEGER
            numeric_i32: ET_TENSOR_NUMERIC_INTEGER_32
            t_input: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            elem_i32: ET_NUMERIC_ELEMENT [INTEGER_32]
            cond_list: ARRAYED_LIST [INTEGER]
            start_crop: INTEGER
            k: INTEGER
        do
            create curr_idx.make (idx.numel + max_new_tokens)
            create numeric_i32
            -- Copy from tensor to arrayed list
            from i_step := 0 until i_step >= idx.numel loop
                curr_idx.extend (numeric_i32.read (idx.data, idx.offset + i_step * 4).item)
                i_step := i_step + 1
            end

            from i_step := 1 until i_step > max_new_tokens loop
                create cond_list.make_from_iterable (curr_idx)
                if cond_list.count > max_seq_len then
                    start_crop := cond_list.count - max_seq_len + 1
                    cond_list := slice_int (cond_list, start_crop, cond_list.count)
                end

                create t_input.make_zeros (<<cond_list.count>>)
                create elem_i32
                from k := 1 until k > cond_list.count loop
                    elem_i32.set_item (cond_list [k])
                    t_input.put (elem_i32, <<k>>)
                    k := k + 1
                end

                reset_cache
                output_arr := forward (t_input, Void)
                if attached {ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]} output_arr [1] as l_logits then
                    logits_tensor := l_logits
                else
                    create logits_tensor.make_zeros (<<1, 1>>)
                end

                next_token := sample_token (logits_tensor, temperature)

                if next_token = stop_token then
                    i_step := max_new_tokens + 1 -- break
                else
                    curr_idx.extend (next_token)
                    i_step := i_step + 1
                end
            end

            Result := curr_idx
        end

    sample_token (logits: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]; temperature: REAL_64): INTEGER
        local
            vocab_probs: ARRAYED_LIST [REAL_64]
            sum_exp: REAL_64
            k, last_idx, v_size: INTEGER
            logit_val: REAL_64
            r, acc, l_max_val: REAL_64
            numeric_r32: ET_TENSOR_NUMERIC_REAL_32
            data_offset: INTEGER
        do
            -- Logits shape is [B, T, V] or [T, V]. We want the last time step.
            v_size := logits.shape [logits.shape.count]
            create vocab_probs.make (v_size)
            sum_exp := 0.0
            create numeric_r32

            -- Advance to last time step
            if logits.shape.count = 3 then
                -- [B, T, V]
                last_idx := (logits.shape [1] * logits.shape [2] - 1) * v_size
            else
                -- [T, V]
                last_idx := (logits.shape [1] - 1) * v_size
            end

            -- Find max logit to prevent overflow
            l_max_val := -1.0e9
            from k := 0 until k >= v_size loop
                data_offset := logits.offset + (last_idx + k) * 4
                logit_val := numeric_r32.read (logits.data, data_offset).item.to_double / temperature
                if logit_val > l_max_val then
                    l_max_val := logit_val
                end
                k := k + 1
            end

            from k := 0 until k >= v_size loop
                data_offset := logits.offset + (last_idx + k) * 4
                logit_val := numeric_r32.read (logits.data, data_offset).item.to_double / temperature
                sum_exp := sum_exp + exp (logit_val - l_max_val)
                k := k + 1
            end

            from k := 0 until k >= v_size loop
                data_offset := logits.offset + (last_idx + k) * 4
                logit_val := numeric_r32.read (logits.data, data_offset).item.to_double / temperature
                vocab_probs.extend (exp (logit_val - l_max_val) / sum_exp)
                k := k + 1
            end

            rng.forth
            r := rng.double_item
            acc := 0.0
            -- Result initialized to 1-based token index
            Result := 1

            from k := 1 until k > vocab_probs.count loop
                acc := acc + vocab_probs [k]
                if r < acc then
                    Result := k
                    k := vocab_probs.count + 1 -- break
                else
                    k := k + 1
                end
            end
        end

feature {NONE} -- Utils

    slice_int (list: ARRAYED_LIST [INTEGER]; start_idx, end_idx: INTEGER): ARRAYED_LIST [INTEGER]
        local
            res: ARRAYED_LIST [INTEGER]
            i: INTEGER
        do
            create res.make (end_idx - start_idx + 1)
            from i := start_idx until i > end_idx loop
                res.extend (list [i])
                i := i + 1
            end
            Result := res
        end

end

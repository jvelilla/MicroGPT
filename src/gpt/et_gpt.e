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

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            -- All learnable parameters of the model.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} Result.make
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
            tok_emb: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            pos_emb: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            pos: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            l_elem: ET_NUMERIC_ELEMENT [INTEGER_32]
            start_pos: INTEGER
            logits_out: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]

            -- Loss locals
            loss_val: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
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
                        l_elem.set_item (start_pos + i - 1)
                        pos.put (l_elem, <<j, i>>)
                        i := i + 1
                    end
                    j := j + 1
                end
            else
                from i := 1 until i > t loop
                    l_elem.set_item (start_pos + i - 1)
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

            -- Initial RMSNorm after embedding sum (matching Python: x = rmsnorm(x) at line 112)
            x := ln_f.forward (x)
            debug
	            io.put_string_32 ({STRING_32} "    [DEBUG] x after initial rmsnorm mean: " + x.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
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

            -- Note: No final layer norm before lm_head (matching Python reference)

            -- 5. LM Head (logits)
            debug
	            io.put_string_32 ({STRING_32} "    [GPT] Computing logits...%N")
            end
            logits_out := lm_head.forward (x)

            -- 6. Fused Cross-Entropy Loss (PyTorch-style)
            if attached targets as tgt then
                loss_val := fused_cross_entropy_loss (logits_out, tgt, b, t)
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
            -- Uses incremental KV-cache: process context once, then one token at a time.
        require
            positive_new_tokens: max_new_tokens > 0
            positive_temperature: temperature > 0.0
        local
            curr_idx: ARRAYED_LIST [INTEGER]
            i_step: INTEGER
            output_arr: ARRAY [detachable ANY]
            logits_tensor: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            next_token: INTEGER
            numeric_i32: ET_TENSOR_NUMERIC_INTEGER_32
            t_input: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            elem_i32: ET_NUMERIC_ELEMENT [INTEGER_32]
            k: INTEGER
        do
            -- Disable gradient computation for inference (like torch.no_grad())
            {ET_TORCH}.no_grad

            create curr_idx.make (idx.numel + max_new_tokens)
            create numeric_i32

            -- Copy initial context from tensor to list
            from i_step := 0 until i_step >= idx.numel loop
                curr_idx.extend (numeric_i32.read (idx.data, idx.offset + i_step * 4).item)
                i_step := i_step + 1
            end

            -- Initialize and reset KV cache for incremental generation
            init_cache (max_seq_len)
            reset_cache

            -- 1. Process the initial context as a batch to populate KV cache
            create t_input.make_zeros (<<curr_idx.count>>)
            create elem_i32
            from k := 1 until k > curr_idx.count loop
                elem_i32.set_item (curr_idx [k])
                t_input.put (elem_i32, <<k>>)
                k := k + 1
            end
            output_arr := forward (t_input, Void)
            if attached {ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]} output_arr [1] as l_logits then
                logits_tensor := l_logits
            else
                create logits_tensor.make_zeros (<<1, 1>>)
            end
            next_token := sample_token (logits_tensor, temperature)

            if next_token = stop_token then
                Result := curr_idx
            else
                curr_idx.extend (next_token)

                -- 2. Generate remaining tokens one at a time (KV cache retains history)
                from i_step := 2 until i_step > max_new_tokens loop
                    create t_input.make_zeros (<<1>>)
                    elem_i32.set_item (curr_idx.last)
                    t_input.put (elem_i32, <<1>>)

                    output_arr := forward (t_input, Void)
                    if attached {ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]} output_arr [1] as l_logits then
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

            -- Re-enable gradient computation for training
            {ET_TORCH}.enable_grad
        end

    sample_token (logits: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]; temperature: REAL_64): INTEGER
        local
            vocab_probs: ARRAYED_LIST [REAL_64]
            sum_exp: REAL_64
            k, last_idx, v_size: INTEGER
            logit_val: REAL_64
            r, acc, l_max_val: REAL_64
            numeric_r32: ET_TENSOR_NUMERIC_REAL_64
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
                data_offset := logits.offset + (last_idx + k) * 8
                logit_val := numeric_r32.read (logits.data, data_offset).item / temperature
                if logit_val > l_max_val then
                    l_max_val := logit_val
                end
                k := k + 1
            end

            from k := 0 until k >= v_size loop
                data_offset := logits.offset + (last_idx + k) * 8
                logit_val := numeric_r32.read (logits.data, data_offset).item / temperature
                sum_exp := sum_exp + exp (logit_val - l_max_val)
                k := k + 1
            end

            from k := 0 until k >= v_size loop
                data_offset := logits.offset + (last_idx + k) * 8
                logit_val := numeric_r32.read (logits.data, data_offset).item / temperature
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

feature {NONE} -- Fused Cross-Entropy Loss (PyTorch-style)

    fused_cross_entropy_loss (logits: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]; tgt: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]; a_b, a_t: INTEGER): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            -- Compute cross-entropy loss with fused backward.
            -- Instead of building an autograd chain through max/exp/sum/log,
            -- we compute softmax manually and set a direct backward:
            --   grad_logits = (softmax(logits) - one_hot) / (B*T)
        local
            numeric_r64: ET_TENSOR_NUMERIC_REAL_64
            numeric_i32: ET_TENSOR_NUMERIC_INTEGER_32
            v_size, pos, k, target_t: INTEGER
            max_val, sum_exp, logit_val, prob_val, log_prob_target: REAL_64
            loss_sum, scale: REAL_64
            data_offset, tgt_offset: INTEGER
            grad_tensor: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            grad_elem: ET_NUMERIC_ELEMENT [REAL_64]
            l_children: ARRAYED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            scalar_shape: ARRAY [INTEGER]
        do
            create numeric_r64
            create numeric_i32
            create scalar_shape.make_empty
            v_size := logits.shape [logits.shape.count]
            scale := 1.0 / (a_b * a_t).to_double
            loss_sum := 0.0

            -- Create gradient tensor (same shape as logits)
            create grad_tensor.make_zeros (logits.shape)

            -- For each position, compute softmax, extract target log-prob, store gradient
            from pos := 0 until pos >= a_b * a_t loop
                -- Read target token for this position
                target_t := numeric_i32.read (tgt.data, tgt.offset + pos * 4).item

                -- 1. Find max logit for this position (numerical stability)
                max_val := -1.0e30
                from k := 0 until k >= v_size loop
                    data_offset := logits.offset + (pos * v_size + k) * 8
                    logit_val := numeric_r64.read (logits.data, data_offset).item
                    if logit_val > max_val then
                        max_val := logit_val
                    end
                    k := k + 1
                end

                -- 2. Compute sum of exp(logit - max) for this position
                sum_exp := 0.0
                from k := 0 until k >= v_size loop
                    data_offset := logits.offset + (pos * v_size + k) * 8
                    logit_val := numeric_r64.read (logits.data, data_offset).item
                    sum_exp := sum_exp + exp (logit_val - max_val)
                    k := k + 1
                end

                -- 3. Compute softmax probs and store gradient = (prob - one_hot) * scale
                from k := 0 until k >= v_size loop
                    data_offset := logits.offset + (pos * v_size + k) * 8
                    logit_val := numeric_r64.read (logits.data, data_offset).item
                    prob_val := exp (logit_val - max_val) / sum_exp

                    -- Gradient: (softmax_prob - one_hot_indicator) * scale
                    create grad_elem
                    if k + 1 = target_t then
                        -- Target position: grad = (prob - 1) / (B*T)
                        grad_elem.set_item ((prob_val - 1.0) * scale)
                        -- Accumulate loss: -log(prob_target)
                        if prob_val > 1.0e-30 then
                            loss_sum := loss_sum - log (prob_val) * scale
                        else
                            loss_sum := loss_sum + 30.0 * scale -- clamp log(~0)
                        end
                    else
                        -- Non-target: grad = prob / (B*T)
                        grad_elem.set_item (prob_val * scale)
                    end
                    -- Store gradient in grad_tensor
                    data_offset := grad_tensor.offset + (pos * v_size + k) * 8
                    numeric_r64.put (grad_tensor.data, data_offset, grad_elem)

                    k := k + 1
                end

                pos := pos + 1
            end

            -- Create scalar loss tensor
            create Result.make_zeros (scalar_shape)
            create grad_elem
            grad_elem.set_item (loss_sum)
            Result.put (grad_elem, scalar_shape)

            -- Wire up autograd: loss.backward() will push grad_tensor to logits
            Result.set_requires_grad (True)
            logits.set_requires_grad (True)
            create l_children.make (1)
            l_children.extend (logits)
            Result.set_prev (l_children)
            Result.set_backward_fn (agent backward_fused_ce (Result, logits, grad_tensor))
        end

    backward_fused_ce (loss_t, logits, pre_grad: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]])
            -- Fused CE backward: directly assign pre-computed gradient to logits.
            -- grad_logits = (softmax - one_hot) / (B*T), already stored in pre_grad.
        do
            if attached loss_t.grad then
                logits.accumulate_grad (pre_grad)
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

note
    description: "GPT Language Model"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    GPT

inherit
    MODULE
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
            
            create {LINKED_LIST [BLOCK]} blocks.make
            from i := 1 until i > n_layer loop
                blocks.extend (create {BLOCK}.make (n_embd, n_head, block_size, dropout))
                i := i + 1
            end
            
            create ln_f.make (n_embd)
            create lm_head.make (n_embd, vocab_size, False) -- bias=False usually
            
            max_seq_len := block_size
            
            create rng.make
            rng.set_seed (42)
        end

feature -- Access

    token_embedding_table: EMBEDDING
    position_embedding_table: EMBEDDING
    blocks: LIST [BLOCK]
    ln_f: RMS_NORM
    lm_head: NN_LINEAR
    
    max_seq_len: INTEGER
    rng: RANDOM

    parameters: LIST [VALUE]
            -- All learnable parameters of the model.
        do
            create {LINKED_LIST [VALUE]} Result.make
            Result.append (token_embedding_table.parameters)
            Result.append (position_embedding_table.parameters)
            across blocks as b loop
                Result.append (b.parameters)
            end
            Result.append (ln_f.parameters)
            Result.append (lm_head.parameters)
        end

feature -- Operation

    forward (idx: ARRAY [INTEGER]; targets: detachable ARRAY [INTEGER]): TUPLE [logits: LIST [LIST [VALUE]]; loss: detachable VALUE]
            -- Forward pass of the model.
            -- `idx`: input tokens (batch_size=1, time_steps).
            -- `targets`: optional target tokens for loss calculation.
            -- Returns logits and optional loss.
        require
            input_length_limit: idx.count <= max_seq_len
            -- input_tokens_valid: across idx as t all t >= 1 end -- Too expensive to iterate in contract?
            targets_match_input: attached targets implies targets.count = idx.count
        local
            t: INTEGER
            tok_emb: LIST [LIST [VALUE]]
            pos_emb: LIST [LIST [VALUE]]
            x: LINKED_LIST [LIST [VALUE]] -- (T, C)
            i, j: INTEGER
            row_t, row_p: ARRAYED_LIST [VALUE]
            row_sum: LINKED_LIST [VALUE]
            
            curr_x: LIST [LIST [VALUE]]
            

            final_norm_x: LIST [LIST [VALUE]]
            logits_out: LIST [LIST [VALUE]]
            
            loss_val: VALUE
            target_t: INTEGER
            logits_t: LIST [VALUE]
            reshaped_logits: ARRAYED_LIST [VALUE]
            sum_val, log_sum: VALUE
            
            logits_arr: ARRAYED_LIST [LIST [VALUE]]
        do
            t := idx.count
            -- require valid_len: t <= max_seq_len
            
            -- 1. Embeddings
            create {LINKED_LIST [LIST [VALUE]]} tok_emb.make
            across idx as id loop
                tok_emb.extend (token_embedding_table.forward (id))
            end
            
            create {LINKED_LIST [LIST [VALUE]]} pos_emb.make
            from i := 1 until i > t loop
                pos_emb.extend (position_embedding_table.forward (i)) -- pos 1..T
                i := i + 1
            end
            
            -- x = tok_emb + pos_emb
            create x.make
            from i := 1 until i > t loop
                create row_t.make_from_iterable (tok_emb.i_th (i))
                create row_p.make_from_iterable (pos_emb.i_th (i))
                create row_sum.make
                from j := 1 until j > row_t.count loop
                    row_sum.extend (row_t [j] + row_p [j])
                    j := j + 1
                end
                x.extend (row_sum)
                i := i + 1
            end
            
            -- 2. Blocks
            curr_x := x
            across blocks as blk loop
                curr_x := blk.forward (curr_x)
            end
            
            -- 3. Final Layer Norm
            create {LINKED_LIST [LIST [VALUE]]} final_norm_x.make
            across curr_x as row_x loop
                final_norm_x.extend (ln_f.forward (row_x))
            end
            
            -- 4. LM Head (logits)
            create {LINKED_LIST [LIST [VALUE]]} logits_out.make
            across final_norm_x as row_x loop
                logits_out.extend (lm_head.forward (row_x))
            end
            
            -- 5. Loss (Cross Entropy)
            if attached targets as tgt then
                loss_val := create {VALUE}.make (0.0)
                create logits_arr.make_from_iterable (logits_out)
                
                from i := 1 until i > t loop
                   target_t := tgt [i]
                   logits_t := logits_arr [i]
                   create reshaped_logits.make_from_iterable (logits_t)
                   
                   -- log(sum(exp(x)))
                   sum_val := create {VALUE}.make (0.0)
                   across reshaped_logits as l loop
                       sum_val := sum_val + l.exp_val
                   end
                   log_sum := sum_val.log_val
                   
                   -- loss += -logits[target] + logsumexp
                   loss_val := loss_val + (reshaped_logits [target_t].negated + log_sum)
                   
                   i := i + 1
                end
                
                loss_val := loss_val * create {VALUE}.make (1.0 / t)
                
                Result := [logits_out, loss_val]
            else
                Result := [logits_out, Void]
            end
        end
        
    generate (idx: ARRAY [INTEGER]; max_new_tokens: INTEGER; temperature: REAL_64; stop_token: INTEGER): ARRAYED_LIST [INTEGER]
            -- Generate new tokens given a context `idx`.
            -- `max_new_tokens`: maximum tokens to generate.
            -- `temperature`: sampling temperature (higher = more random).
            -- `stop_token`: token ID to stop generation (e.g., BOS).
        require
            valid_context: not idx.is_empty
            positive_new_tokens: max_new_tokens > 0
            positive_temperature: temperature > 0.0
        local
            curr_idx: ARRAYED_LIST [INTEGER]
            i_step: INTEGER
            last_logits: LIST [VALUE]
            output_tuple: TUPLE [logits: LIST [LIST [VALUE]]; loss: detachable VALUE]
            next_token: INTEGER
            vocab_probs: ARRAYED_LIST [REAL_64]
            sum_exp, r, acc: REAL_64
            
            last_logits_arr: ARRAYED_LIST [VALUE]
            

            k: INTEGER
            cond_idx: ARRAY [INTEGER]
            cond_list: ARRAYED_LIST [INTEGER]
            
            start_crop: INTEGER
            logit_val: REAL_64
        do
            create curr_idx.make_from_array (idx)
            
            from i_step := 1 until i_step > max_new_tokens loop
                -- Crop context if needed to max_seq_len
                create cond_list.make_from_iterable (curr_idx)
                if cond_list.count > max_seq_len then
                    start_crop := cond_list.count - max_seq_len + 1
                    cond_list := slice_int (cond_list, start_crop, cond_list.count)
                end
                
                cond_idx := cond_list.to_array
                
                -- forward
                output_tuple := forward (cond_idx, Void)
                
                -- get last time step logits
                last_logits := output_tuple.logits.last
                create last_logits_arr.make_from_iterable (last_logits)
                
                -- Softmax to get probs with temperature
                create vocab_probs.make (last_logits.count)
                sum_exp := 0.0
                
                from k := 1 until k > last_logits.count loop
                    logit_val := last_logits_arr [k].data / temperature
                    sum_exp := sum_exp + exp (logit_val)
                    k := k + 1
                end
                
                from k := 1 until k > last_logits.count loop
                    logit_val := last_logits_arr [k].data / temperature
                    vocab_probs.extend (exp (logit_val) / sum_exp)
                    k := k + 1
                end
                
                -- Sample
                rng.forth
                r := rng.double_item
                acc := 0.0
                next_token := 1 -- Default
                from k := 1 until k > vocab_probs.count loop
                    acc := acc + vocab_probs [k]
                    if r < acc then
                        next_token := k
                        k := vocab_probs.count + 1 -- break
                    else
                        k := k + 1
                    end
                end
                
                if next_token = stop_token then
                    i_step := max_new_tokens + 1 -- break
                else
                    curr_idx.extend (next_token)
                    i_step := i_step + 1
                end
            end
            
            Result := curr_idx
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

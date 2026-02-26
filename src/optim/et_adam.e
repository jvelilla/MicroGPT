note
    description: "Adam Optimizer"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_ADAM

create
    make

feature -- Initialization

    make (a_params: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]; a_lr, a_beta1, a_beta2, a_eps: REAL_64)
            -- Initialize with parameters and hyperparameters.
            -- `a_params`: list of parameters to optimize.
            -- `a_lr`: learning rate.
            -- `a_beta1`: exponential decay rate for first moment estimates.
            -- `a_beta2`: exponential decay rate for second moment estimates.
            -- `a_eps`: term added to denominator to prevent division by zero.
        local
            zero_t: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            params := a_params
            lr := a_lr
            beta1 := a_beta1
            beta2 := a_beta2
            eps := a_eps

            -- Initialize moment buffers
            create {ARRAYED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} m.make (params.count)
            create {ARRAYED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} v.make (params.count)

            across params as p loop
                create zero_t.make_zeros (p.shape)
                m.extend (zero_t)
                create zero_t.make_zeros (p.shape)
                v.extend (zero_t)
            end

            t := 0

            -- Pre-cache scalar tensors (avoid re-allocating every step)
            create numeric_helper
            create scalar_shape.make_empty
            create t_beta1.make_full (scalar_shape, numeric_helper.from_real_64 (beta1))
            create t_beta2.make_full (scalar_shape, numeric_helper.from_real_64 (beta2))
            create t_1_minus_beta1.make_full (scalar_shape, numeric_helper.from_real_64 (1.0 - beta1))
            create t_1_minus_beta2.make_full (scalar_shape, numeric_helper.from_real_64 (1.0 - beta2))
            create t_eps.make_full (scalar_shape, numeric_helper.from_real_64 (eps))
            create t_lr.make_full (scalar_shape, numeric_helper.from_real_64 (lr))
        end

feature -- Access

    params: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
    lr, beta1, beta2, eps: REAL_64
    m, v: ARRAYED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
    t: INTEGER

feature -- Operations

    set_lr (a_new_lr: REAL_64)
            -- Set a new learning rate for the optimizer.
        do
            lr := a_new_lr
            -- Update the cached LR tensor
            t_lr := create {ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]}.make_full (scalar_shape, numeric_helper.from_real_64 (lr))
        end

    step
            -- Perform a single optimization step.
            -- Updates parameters based on computed gradients.
        require
            params_not_empty: not params.is_empty
        local
            i: INTEGER
            p, grad: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            m_hat, v_hat: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            params_arr: ARRAYED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            t_bias_corr1, t_bias_corr2: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            m_i, v_i, p_new, p_update, zero_t: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            t := t + 1
            create params_arr.make_from_iterable (params)

            -- Bias correction factors (change every step, so compute here)
            create t_bias_corr1.make_full (scalar_shape, numeric_helper.from_real_64 (1.0 - (beta1 ^ t.to_double)))
            create t_bias_corr2.make_full (scalar_shape, numeric_helper.from_real_64 (1.0 - (beta2 ^ t.to_double)))

            from i := 1 until i > params_arr.count loop
                p := params_arr [i]

                if attached p.grad as g then
                    grad := g
                    m_i := m [i]
                    v_i := v [i]

                    -- Update moments
                    m [i] := (m_i * t_beta1) + (grad * t_1_minus_beta1)
                    v [i] := (v_i * t_beta2) + ((grad * grad) * t_1_minus_beta2)

                    m_i := m [i]
                    v_i := v [i]

                    -- Bias correction
                    m_hat := m_i / t_bias_corr1
                    v_hat := v_i / t_bias_corr2

                    -- Update parameter
                    p_update := (t_lr * m_hat) / ((v_hat ^ 0.5) + t_eps)
                    p_new := p - p_update

                    p.copy_from (p_new)

                    -- Zero grad (Karpathy does p.grad = 0 here)
                    create zero_t.make_zeros (p.shape)
                    p.set_grad (zero_t)
                end

                i := i + 1
            end
        end

    zero_grad
            -- Zero gradients of all parameters.
        local
            zero_t: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            across params as p loop
                create zero_t.make_zeros (p.shape)
                p.set_grad (zero_t)
            end
        end

feature {NONE} -- Cached scalar tensors (avoid re-allocation every step)

    numeric_helper: ET_TENSOR_NUMERIC_REAL_64
    scalar_shape: ARRAY [INTEGER]
    t_lr: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    t_beta1: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    t_beta2: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    t_1_minus_beta1: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    t_1_minus_beta2: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    t_eps: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]

end

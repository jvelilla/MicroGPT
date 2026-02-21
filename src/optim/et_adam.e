note
    description: "Adam Optimizer"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_ADAM

create
    make

feature -- Initialization

    make (a_params: LIST [ET_VALUE]; a_lr, a_beta1, a_beta2, a_eps: REAL_64)
            -- Initialize with parameters and hyperparameters.
            -- `a_params`: list of parameters to optimize.
            -- `a_lr`: learning rate.
            -- `a_beta1`: exponential decay rate for first moment estimates.
            -- `a_beta2`: exponential decay rate for second moment estimates.
            -- `a_eps`: term added to denominator to prevent division by zero.
        local

            i: INTEGER
        do
            params := a_params
            lr := a_lr
            beta1 := a_beta1
            beta2 := a_beta2
            eps := a_eps
            
            -- Initialize moment buffers
            create {ARRAYED_LIST [REAL_64]} m.make (params.count)
            create {ARRAYED_LIST [REAL_64]} v.make (params.count)
            
            from i := 1 until i > params.count loop
                m.extend (0.0)
                v.extend (0.0)
                i := i + 1
            end
            
            t := 0
        end

feature -- Access

    params: LIST [ET_VALUE]
    lr, beta1, beta2, eps: REAL_64
    m, v: ARRAYED_LIST [REAL_64]
    t: INTEGER

feature -- Operations

    step
            -- Perform a single optimization step.
            -- Updates parameters based on computed gradients.
        require
            params_not_empty: not params.is_empty
        local
            i: INTEGER
            p: ET_VALUE
            grad: REAL_64
            m_hat, v_hat: REAL_64

            params_arr: ARRAYED_LIST [ET_VALUE]
        do
            t := t + 1
            create params_arr.make_from_iterable (params)
            
            from i := 1 until i > params_arr.count loop
                p := params_arr [i]
                grad := p.grad
                
                -- Update moments
                m [i] := beta1 * m [i] + (1.0 - beta1) * grad
                v [i] := beta2 * v [i] + (1.0 - beta2) * (grad * grad)
                
                -- Bias correction
                m_hat := m [i] / (1.0 - beta1 ^ t)
                v_hat := v [i] / (1.0 - beta2 ^ t)
                
                -- Update parameter
                p.data := p.data - lr * m_hat / ({DOUBLE_MATH}.sqrt (v_hat) + eps)
                
                -- Zero grad (PyTorch style often clears later, but Karpathy does `p.grad = 0` here)
                p.grad := 0.0
                
                i := i + 1
            end
        end
        
    zero_grad
            -- Zero gradients of all parameters.
        do
            across params as p loop
                p.grad := 0.0
            end
        end

end

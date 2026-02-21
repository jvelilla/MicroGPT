note
    description: "Autograd Engine Node"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_VALUE

inherit
    ANY
        redefine
            out
        end
    DOUBLE_MATH
        export
            {NONE} all
        undefine
            out
        end

create
    make, make_with_children

feature -- Constants

    Op_none: INTEGER = 0
    Op_add: INTEGER = 1
    Op_mul: INTEGER = 2
    Op_pow: INTEGER = 3
    Op_relu: INTEGER = 4
    Op_tanh: INTEGER = 5
    Op_exp: INTEGER = 6
    Op_log: INTEGER = 7

feature -- Initialization

    make (a_data: REAL_64)
            -- Create a value with `a_data` and no children.
        do
            data := a_data
            grad := 0.0
            create prev.make (0)
            op_code := Op_none
        ensure
            data_set: data = a_data
            grad_zero: grad = 0.0
            no_children: prev.is_empty
        end

    make_with_children (a_data: REAL_64; a_children: ARRAYED_LIST [ET_VALUE]; a_op_code: INTEGER)
            -- Create a value with `a_data`, `a_children` and operation `a_op_code`.
        do
            data := a_data
            grad := 0.0
            prev := a_children
            op_code := a_op_code
        ensure
            data_set: data = a_data
        end

feature -- Access

    data: REAL_64 assign set_data
    grad: REAL_64 assign set_grad
    prev: ARRAYED_LIST [ET_VALUE]
    op_code: INTEGER
    
    -- Store extra param for Power op
    param: REAL_64
    
    visited: BOOLEAN

feature -- Element Change
    
    set_visited (b: BOOLEAN)
            -- Mark as visited.
        do
            visited := b
        end
    
    set_data (a_data: REAL_64)
            -- Set data value.
        do
            data := a_data
        end

    set_grad (a_grad: REAL_64)
            -- Set gradient value.
        do
            grad := a_grad
        end
        
    add_grad (a_amount: REAL_64)
            -- Accumulate gradient.
        do
            grad := grad + a_amount
        end
        
    set_param (p: REAL_64)
            -- Set operation parameter (e.g. power exponent).
        do
            param := p
        end

feature -- Operations

    plus alias "+" (other: ET_VALUE): ET_VALUE
            -- Addition: Current + `other`.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
        do
            create l_children.make (2)
            l_children.extend (Current)
            l_children.extend (other)
            
            create Result.make_with_children (data + other.data, l_children, Op_add)
        ensure
            has_children: Result.prev.count = 2
            op_set: Result.op_code = Op_add
        end

    times alias "*" (other: ET_VALUE): ET_VALUE
            -- Multiplication: Current * `other`.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
        do
            create l_children.make (2)
            l_children.extend (Current)
            l_children.extend (other)
            
            create Result.make_with_children (data * other.data, l_children, Op_mul)
        ensure
            has_children: Result.prev.count = 2
            op_set: Result.op_code = Op_mul
        end

    power alias "^" (other: REAL_64): ET_VALUE
            -- Power: Current ^ `other`.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
        do
            create l_children.make (1)
            l_children.extend (Current)
            
            create Result.make_with_children (data.power (other), l_children, Op_pow)
            Result.set_param (other)
        ensure
            has_children: Result.prev.count = 1
            op_set: Result.op_code = Op_pow
        end

    relu: ET_VALUE
            -- ReLU activation.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
            d: REAL_64
        do
            if data < 0.0 then
                d := 0.0
            else
                d := data
            end
            
            create l_children.make (1)
            l_children.extend (Current)
            
            create Result.make_with_children (d, l_children, Op_relu)
        ensure
            has_children: Result.prev.count = 1
            op_set: Result.op_code = Op_relu
        end
        
    log_val: ET_VALUE
            -- Natural logarithm.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
        do
            create l_children.make (1)
            l_children.extend (Current)
            
            create Result.make_with_children (log (data), l_children, Op_log)
        ensure
            has_children: Result.prev.count = 1
            op_set: Result.op_code = Op_log
        end
        
    exp_val: ET_VALUE
            -- Exponential.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
            d: REAL_64
        do
            d := exp (data)
            create l_children.make (1)
            l_children.extend (Current)
            
            create Result.make_with_children (d, l_children, Op_exp)
        ensure
            has_children: Result.prev.count = 1
            op_set: Result.op_code = Op_exp
        end

    tanh: ET_VALUE
            -- Hyperbolic tangent.
        local
            l_children: ARRAYED_LIST [ET_VALUE]
            t: REAL_64
            e2x: REAL_64
            d: REAL_64
        do
            -- Inline tanh logic
            d := data
            if d > 20.0 then
                t := 1.0
            elseif d < -20.0 then
                t := -1.0
            else
                e2x := exp (2.0 * d)
                t := (e2x - 1.0) / (e2x + 1.0)
            end
            
            create l_children.make (1)
            l_children.extend (Current)
            
            create Result.make_with_children (t, l_children, Op_tanh)
        ensure
            has_children: Result.prev.count = 1
            op_set: Result.op_code = Op_tanh
        end

    gelu: ET_VALUE
            -- Gaussian Error Linear Unit approximation.
        local

            v_k, v_half, v_one, v_coef: ET_VALUE
            term1, term2, term3: ET_VALUE
        do
            -- 0.5 * x * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3)))
            -- Constants creation should be optimized but keeping simple for now
            
            create v_k.make (0.7978845608) -- sqrt(2/pi)
            create v_half.make (0.5)
            create v_one.make (1.0)
            create v_coef.make (0.044715)
            
            term1 := Current ^ 3.0
            term2 := (Current + (term1 * v_coef))
            term3 := (term2 * v_k).tanh
            
            Result := Current * v_half * (v_one + term3)
        ensure
            has_children: Result.prev.count >= 1
            -- Op_code will be the last operation (add or mul), so hard to test exact code without exposing intermidiate
        end
        
    negated alias "-": ET_VALUE
            -- Negation.
        do
            Result := Current * create {ET_VALUE}.make (-1.0)
        end
        
    minus alias "-" (other: ET_VALUE): ET_VALUE
            -- Subtraction.
        do
            Result := Current + (other.negated)
        end

feature -- Autograd

    backward_step
            -- Apply chain rule for this node operation.
        local
            a, b: ET_VALUE
            t: REAL_64
            p: REAL_64
        do
            if op_code = Op_add then
                -- c = a + b
                if prev.count >= 2 then
                    a := prev [1]
                    b := prev [2]
                    a.add_grad (grad)
                    b.add_grad (grad)
                end
            elseif op_code = Op_mul then
                -- c = a * b
                if prev.count >= 2 then
                    a := prev [1]
                    b := prev [2]
                    a.add_grad (b.data * grad)
                    b.add_grad (a.data * grad)
                end
            elseif op_code = Op_pow then
                -- c = a ^ p
                if prev.count >= 1 then
                    a := prev [1]
                    p := param
                    a.add_grad ((p * a.data.power (p - 1.0)) * grad)
                end
            elseif op_code = Op_relu then
                -- c = relu(a)
                if prev.count >= 1 then
                    a := prev [1]
                    if data > 0.0 then
                        a.add_grad (grad)
                    end
                end
            elseif op_code = Op_tanh then
                -- c = tanh(a)
                if prev.count >= 1 then
                    a := prev [1]
                    t := data 
                    a.add_grad ((1.0 - t * t) * grad)
                end
            elseif op_code = Op_exp then
                -- c = exp(a)
                if prev.count >= 1 then
                    a := prev [1]
                    a.add_grad (data * grad)
                end
            elseif op_code = Op_log then
                -- c = log(a)
                if prev.count >= 1 then
                    a := prev [1]
                    a.add_grad ((1.0 / a.data) * grad)
                end
            end
        end

    backward
            -- Compute gradients for the entire graph via backpropagation.
        local
            topo: ARRAYED_LIST [ET_VALUE]
            i: INTEGER
        do
            create topo.make (100) -- Heuristic size
            
            build_topo (Current, topo)
            
            grad := 1.0
            
            -- Apply backward in reverse topological order
            from
                i := topo.count
            until
                i < 1
            loop
                topo [i].backward_step
                -- Reset visited for next pass
                topo [i].set_visited (False)
                i := i - 1
            end
        end

    build_topo (v: ET_VALUE; topo: ARRAYED_LIST [ET_VALUE])
        do
            if not v.visited then
                v.set_visited (True)
                if not v.prev.is_empty then
                    across v.prev as child loop
                        build_topo (child, topo)
                    end
                end
                topo.extend (v)
            end
        end

feature -- Output

    out: STRING
        do
            Result := "Value(data=" + data.out + ", grad=" + grad.out + ")"
        end

invariant
    grad_not_nan: not grad.is_nan
    data_not_nan: not data.is_nan

end

note
    description: "[
        Shared configuration for the ET_TORCH tensor framework.
        Provides a process-wide `grad_enabled` flag (matching PyTorch's torch.no_grad()).

        All features are instance-free and can be called as:
            {ET_TORCH}.no_grad
            {ET_TORCH}.enable_grad
            {ET_TORCH}.is_grad_enabled
        No inheritance needed.
    ]"

class
    ET_TORCH

feature -- Gradient Mode (instance-free)

    grad_enabled: CELL [BOOLEAN]
          
        do  
            create Result.put (True)
        ensure
            class
        end

    no_grad
            -- Disable gradient computation (for inference).
            -- Equivalent to PyTorch's `torch.no_grad()`.
            -- Usage: {ET_TORCH}.no_grad
        do
            grad_enabled.put (False)
        ensure
            class
        end

    enable_grad
            -- Re-enable gradient computation (for training).
            -- Usage: {ET_TORCH}.enable_grad
        do
            grad_enabled.put (True)
        ensure
            class
        end

    is_grad_enabled: BOOLEAN
            -- Is gradient computation currently enabled?
            -- Usage: {ET_TORCH}.is_grad_enabled
        do
            Result := grad_enabled.item
        ensure
            class
        end

end

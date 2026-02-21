# Eiffel MicroGPT

A pure Eiffel port of Andrej Karpathy's [microgpt.py](https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95) and inspired by [AutoGrad-Engine](https://github.com/milanm/AutoGrad-Engine).

This project implements a tiny GPT language model and a high-performance Tensor library with an Autograd engine from scratch in Eiffel. It is designed for educational purposes to understand the internal mechanics of Transformers, Backpropagation, and Tensor operations.

## 🚀 What is this?
This is a minimalist implementation of the algorithm behind models like ChatGPT, built with Eiffel's "Design by Contract" (DbC) principles. It includes:
- **ET_TENSOR Library**: A robust multidimensional array library supporting broadcasting, strided views, and vectorized operations.
- **Autograd Engine**: Automatic differentiation supporting both scalar (legacy) and tensor-based gradients.
- **Transformer**: A full GPT implementation (Embeddings, Multi-head Attention, Feed-forward, LayerNorm).
- **Training Loop**: A simple loop to train the model on text data (e.g., a list of names).

## 📂 Project Structure
| File/Directory | Responsibility |
|---|---|
| `src/tensor/ET_TENSOR.e` | **Tensor Engine**: Multidimensional arrays with broadcasting and strided storage. |
| `src/autograd/ET_VALUE.e` | **Autograd Engine**: Automatic gradient tracking and backpropagation logic. |
| `src/gpt/ET_GPT.e` | **GPT Model**: The main Transformer architecture. |
| `src/optim/ET_ADAM.e` | **Optimizer**: Adam optimization algorithm implementation. |
| `app/APPLICATION.e` | **Entry Point**: CLI wrapper for the Trainer. |
| `tests/` | **Test Suite**: Eiffel AutoTest sets for verification. |

## 🧠 ET_TENSOR Library
The project features a custom Tensor library designed to mirror PyTorch's functionality while leveraging Eiffel's type safety and contracts.

- **Dynamic Broadcasting**: Implicitly expand dimensions for arithmetic operations.
- **Efficient Views**: `view`, `reshape`, `transpose`, and `narrow` create lightweight views without copying data.
- **Polymorphic Storage**: Generic support for `REAL_64`, `INTEGER_32`, etc., using a specialized numeric hierarchy.
- **Design by Contract**: Every operation is guarded by strict preconditions (e.g., shape compatibility) and postconditions, ensuring mathematical correctness.

## 🛠 Quick Start

### Prerequisites
- [EiffelStudio](https://www.eiffel.com/) (Version 25.12 recommended)

### Build and Run

1.  Open `microgpt.ecf` in EiffelStudio.
2.  Compile the desired target (`app` or `tests`).

#### Running the Application

**Step 1: Train the Model**
You must train the model first to create a checkpoint (`model.ckpt`).

```bash
# Default parameters (1000 steps)
.\EIFGENs\app\F_code\microgpt.exe

# Custom parameters
.\EIFGENs\app\F_code\microgpt.exe -n_embd 32 -steps 2000 -lr 0.001
```

**Step 2: Interactive Mode**
Once trained, run in interactive mode to chat with the model.
The model automatically loads `model.ckpt` if found.

```bash
.\EIFGENs\app\F_code\microgpt.exe -interactive
```

**Available Flags:**
- `-n_embd <int>`: Embedding dimension (default: 16)
- `-n_head <int>`: Number of attention heads (default: 4)
- `-n_layer <int>`: Number of layers (default: 1)
- `-block_size <int>`: Max context length (default: 16)
- `-steps <int>`: Number of training steps (default: 1000)
- `-lr <double>`: Learning rate (default: 0.01)
- `-input <path>`: Path to training data (default: "input.txt")
- `-mode <string>`: "train" or "interactive"

#### Running Tests
To verify the implementation (gradients, shapes, math correctness):
```bash
ec -config microgpt.ecf -target tests -run
```
See `tests/ET_TORCH_USE_CASES.e` for examples of PyTorch-parity tests.

### Expected Output
The application will start training on the provided `input.txt`.
```text
MicroGPT in Eiffel
num docs: ...
Vocab size: ...
Model created. Parameters: ...
step 1 / 1000 | loss 3.321
...
step 1000 / 1000 | loss 2.154

--- inference (new, hallucinated names) ---
sample 1: ...
```

## 🔬 How it Works
1.  **Forward Pass**: Input data flows through the graph of `ET_TENSOR` or `ET_VALUE` objects. Each operation records its children to build a computational graph.
2.  **Loss Calculation**: Cross-entropy loss is computed on the predictions.
3.  **Backward Pass**: Gradients are propagated backwards from the loss to all parameters using the chain rule.
4.  **Update**: Adam optimizer adjusts parameters to minimize the loss.



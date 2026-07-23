import torch
from tensordict import TensorDict

# Create dummy TensorDict with multi-dim batch_size
td = TensorDict({"a": torch.randn(2, 3, 4)}, batch_size=(2, 3))
print(f"TensorDict batch_size: {td.batch_size}")
print(f"TensorDict batch_size[0]: {td.batch_size[0]}")

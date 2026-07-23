import torch
import numpy as np
from tensordict import TensorDict

td = TensorDict({"a": torch.randn(2, 3, 4)}, batch_size=(2, 3))
print(f"td.batch_size: {td.batch_size}")
nt = {"b": np.random.randn(2, 3, 5)}
batch_size = td.batch_size
print(f"batch_size: {batch_size}")
print(f"len(batch_size): {len(batch_size)}")

for k, v in nt.items():
    print(f"v.shape: {v.shape}")
    print(f"v.shape[:len(batch_size)]: {v.shape[:len(batch_size)]}")
    print(f"batch_size: {batch_size}")
    if v.shape[:len(batch_size)] != batch_size:
        print("Mismatch!")
    else:
        print("Match!")

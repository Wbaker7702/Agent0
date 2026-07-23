import torch
from verl.protocol import DataProto

obs = torch.randn(100, 10)
act = torch.randn(100, 10, 3)

data = DataProto.from_dict(
    tensors={
        "obs": obs,
        "act": act},
    num_batch_dims=2)
print("Should not have reached here for `num_batch_dims=2` because act's batch dims is 100, 10 but obs's batch dims is 100, 10! ... Wait!")
print(f"obs shape: {obs.shape}")
print(f"act shape: {act.shape}")
print(f"obs batch dims: {obs.shape[:2]}")
print(f"act batch dims: {act.shape[:2]}")

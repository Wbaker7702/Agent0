import torch
import numpy as np
from tensordict import TensorDict

# Need to check which protocol file actually gets used or just import both
import sys
sys.path.append("Agent0/curriculum_train")
from verl.protocol import DataProto as DataProtoCurriculum

sys.path.remove("Agent0/curriculum_train")
sys.path.append("Agent0/executor_train/verl")
from verl.protocol import DataProto as DataProtoExecutor

def test_lift_restriction(DataProtoClass):
    # Try with num_batch_dims > 1
    batch = TensorDict({"a": torch.randn(2, 3, 4)}, batch_size=(2, 3))
    non_tensor_batch = {"b": np.random.randn(2, 3, 5)}

    try:
        dp = DataProtoClass(batch=batch, non_tensor_batch=non_tensor_batch)
        print("Success!")
    except AssertionError as e:
        print(f"Failed with assertion: {e}")

print("Curriculum train:")
test_lift_restriction(DataProtoCurriculum)
print("Executor train:")
test_lift_restriction(DataProtoExecutor)
